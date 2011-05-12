package Music::LastFM::Agent;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');

use MooseX::Singleton;
use Music::LastFM::Meta::EasyAcc;

use Music::LastFM::Types
    qw(UserAgent HashRef ArrayRef Str Int Method Meta Metas Cache Num);
use MooseX::Params::Validate;
use Digest::MD5;
use Time::HiRes;
use Encode;

use Music::LastFM::Response;
use Music::LastFM::Method;

with 'Music::LastFM::Role::Logger';

use namespace::autoclean;
use Readonly;

Readonly my $NANOSLEEP_TIME => 100;

has url => (
    is      => 'rw',
    isa     => Str,
    default => 'http://ws.audioscrobbler.com/2.0/',
);
has api_key => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);
has api_secret => (
    is  => 'rw',
    isa => Str,
);
has lwp_ua => (
    is      => 'rw',
    isa     => UserAgent,
    lazy    => 1,
    builder => '_build_lwp_ua',
);
has cache_time => (
    is      => 'rw',
    isa     => Int,
    default => 604_800,    # One week per LastFM API terms.
);
has cache => (
    is      => 'rw',
    isa     => Cache,
    handles => {
        cache_get => 'get',
        cache_set => 'set',
    },
    clearer => 'no_cache',
);
has session_cache => (
    is      => 'rw',
    isa     => Cache,
    handles => {
        get_sk => 'get',
        set_sk => 'set',
    },
);

has username => (
    is  => 'rw',
    isa => Str,
);

sub has_sk {
    goto &get_sk;
}
has rate_limit => (
    is      => 'rw',
    isa     => Num,
    default => .2,     # Rule is 5 requests per second, averaged over 5 mins.
                       # Rather than having it work fast and then crawl, we
                       # just set this to .2.
);

sub _build_lwp_ua {
    my $self   = shift;
    my $lwp_ua = LWP::UserAgent->new();
    $lwp_ua->agent(
        'Music-LastFM/' . $Music::LastFM::VERSION . $lwp_ua->_agent() );
    return $lwp_ua;
}

sub auth {
    my $self     = shift;
    my $params   = shift;
    my $username = shift || ( $self->has_username ? $self->username : undef );
    if ( !$username ) {
        $self->_die( q{A username must be provided for authenticated queries. }
                . q{You can set the username attribute, or pass it as an option}
                . q{to the query paramater} );
    }
    if ( !$self->has_session_cache ) {
        $self->_die(
            q{Can't authorize a request without a session_cache object});
    }
    if ( $self->get_sk($username) ) {
        $params->{sk} = $self->get_sk($username);
    }
    else {
        $self->_die(
            qq{No session key stored for $username.\n}
                . qq{Please make sure you have run gettoken AND getsession for this user.\n}
                . q{See AUTHENTICATION in the Music::LastFM POD.},
            'Music::LastFM::Exception::AuthenticationError'
        );
    }
    return;
}

sub _key {
    my $self   = shift;
    my $string = shift;
    return Digest::MD5::md5_hex($string);
}

sub sign {
    my $self       = shift;
    my $params_ref = shift;
    if ( !$self->has_api_secret ) {
        $self->_die(
            q{api_secret needs to be provided to sign requests such as this one.}
        );
    }
    $params_ref->{api_key} = $self->api_key;
    my $string_to_digest = join q{},
        map { $_ . $params_ref->{$_} } sort keys %{$params_ref};
    $string_to_digest .= $self->api_secret;
    $params_ref->{api_sig} = Digest::MD5::md5_hex($string_to_digest);
    return;
}

sub gettoken {
    my $self = shift;
    my $resp = $self->query(
        method     => 'auth.getToken',
        cache_time => 0,
    );
    if ( $resp->is_success ) {
        return {
            token => $resp->data->{token},
            url   => 'http://www.last.fm/api/auth/?api_key='
                . $self->api_key
                . '&token='
                . $resp->data->{token}
        };
    }
    else {
        $self->_die(
            'Failed to get an authentication token for unknown reason');
    }
    return;
}

sub getsession {
    my $self  = shift;
    my $token = shift;

    my $resp = $self->query(
        method     => 'auth.getSession',
        cache_time => 0,
        options    => { token => $token },
    );
    if ( $resp->is_success ) {
        my ( $username, $session_key ) =
            ( $resp->data->{name}, $resp->data->{key} );
        if ( !$self->has_session_cache ) {
            $self->_warning(
                qq{Can't save this session, because no session cache defined.\n}
                    . q{Please re-read the Music::LastFM Documentation"} );
        }
        $self->set_sk( $username => $session_key );
        return $resp->data;
    }
    else {
        $self->_die('Failed to get session key for unknown reason');
    }
    return;
}

sub _urlencode {
    my $value = shift;
    my $return_value =
        encode( 'utf-8', $value );    # Convert to 8 bit characters
    $return_value =~ s{
        ([^a-zA-Z0-9_\.])                         # Everything but a few characters
    }
    {
        '%' . uc(sprintf("%2.2x",ord($1)));       # Is changed to %XX  where XX
                                                  # is the hex of the 8 bit value
    }egxsm;
    return $return_value;
}

sub _query_pair {
    my ( $key, $value ) = @_;
    return join q{=}, $key, _urlencode($value);

}

sub _build_query {
    my ( $self, $params_ref ) = @_;

    #$params_ref->{options}->{format} = 'json';
    my %query_hash = %{ $params_ref->{options} };
    $query_hash{method}  = $params_ref->{method}->name;
    $query_hash{api_key} = $self->api_key;

    if (   ( $params_ref->{method}->auth_required )
        && ( !$params_ref->{sk} ) ) {
        $self->auth( \%query_hash, $params_ref->{username} );
    }
    if ( $params_ref->{method}->sign_required ) {
        $self->sign( \%query_hash );
    }
    $query_hash{format} = 'json';
    my $query_string = q{};
    $query_string = join q{&}, map { _query_pair( $_, $query_hash{$_} ) }
        sort keys %query_hash;
    return $query_string;
}

sub _build_request {
    my ( $self, $lastfm_method, $query_string ) = @_;
    my $url = $self->url();
    my $lwp_request;
    if ( $lastfm_method->http_method eq 'GET' ) {
        $lwp_request = HTTP::Request->new( 'GET', "$url?$query_string" );
        $self->_info(qq{Performing query $url?$query_string});
    }
    else {
        $lwp_request = HTTP::Request->new( 'POST', $url );
        $lwp_request->content_type(
            'application/x-www-form-urlencoded; charset="UTF-8"');
        $lwp_request->content($query_string);
        $self->_info(qq{Performing POST query $url - $query_string});
    }
    if ( !$lwp_request ) {
        $self->_die('Could not create an xml query request object');
    }
    return $lwp_request;
}

{

    my $last_req_time;

    sub _limit_request_rate {
        my $self = shift;
        if ( $last_req_time ) {
            while ( Time::HiRes::tv_interval( $last_req_time )
                < $self->rate_limit ) {
                Time::HiRes::nanosleep($NANOSLEEP_TIME);
            }
        }
        $last_req_time = [ Time::HiRes::gettimeofday() ];
        return;
    }


}

sub _perform_query {
    my ( $self, $params_ref, $query_string ) = @_;

    my $lwp_request =
        $self->_build_request( $params_ref->{method}, $query_string );
    my $lwp_resp = $self->lwp_ua->request($lwp_request);

    $self->_debug( q{Response to query is: }
            . $lwp_resp->content
            . q{ and success is }
            . $lwp_resp->status_line );

    if ( !$lwp_resp->is_success ) {
        $self->_die(
            'Response to query failed: ' . $lwp_resp->status_line,
            undef,    # Fix me
            $lwp_resp
        );
        return;
    }

    return $lwp_resp->content;
}

sub query {
    my ( $self, @opts ) = @_;
    my $options_default = {};

    my (%params) = validated_hash(
        \@opts,
        method  =>    { isa => Method,  coerce  => 1 },
        options =>    { isa => HashRef, default => $options_default, },
        cache_time => { isa => Int,     default => $self->cache_time },
        object =>     { isa => 'Music::LastFM::Object', optional => 1 },
        username  =>  { isa => Str, default => $self->username, },
    );

    $params{method}->set_agent($self);

    my $query_string = $self->_build_query( \%params );
    if (   ( !$params{method}->http_method eq 'GET' )
        || ( $params{method}->auth_required)
        || ( !$self->has_cache ) ) {
        $params{cache_time} = 0;
    }
    my $content = q{};
    if ( $params{cache_time} ) {
        $self->_debug("Recovered from cache: $query_string");
        $content = $self->cache_get( $self->_key($query_string) );
    }
    if ( !$content ) {
        $self->_limit_request_rate();
        $content = $self->_perform_query( \%params, $query_string );
        if ( $params{cache_time} ) {
            $self->_debug("Saving to cache: $query_string");
            $self->cache_set( $self->_key($query_string),
                $content, $params{cache_time} );
        }
    }
    return Music::LastFM::Response->new(
        method => $params{method},
        json   => $content,
        agent  => $self,
        exists $params{object} ? ( object => $params{object} ) 
                               : (),
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Music::LastFM::Agent - [One line description of module's purpose here]

=head1 VERSION

This document describes Music::LastFM version 0.0.3

=head1 SYNOPSIS

See L<Music::LastFM>.
  
=head1 DESCRIPTION

This is the main module for querying LastFM servers.  The easiest way to
create this is using L<Music::LastFM>.

This module is a Singleton using MooseX::Singleton.  To initialize the module,
use Music::LastFM::Agent->initialize(%options).  After this, an instance can
be acquired using Music::LastFM::Agent->instance.

=head1 METHODS

=head2 Initiators

=over

=item instance() 

Takes no options.  Returns an instance of Music::LastFM::Agent.  Be sure to
initialize it forst.

=item initialize(api_key => 1234 api_secret => qq{well kept})

Initialize the singleton.  Can use the following attributes.

=head2 Attributes

=over

=item api_key set_api_key has_api_key

B<REQUIRED> 
B<Type>: Str

This must be set when creating the object.  This is the api_key given to you
by LastFM.  Please don't borrow someone else's key!

=item api_secret set_api_secret has_api_secret 

This is the super-secret key provided for you by LastFM.  Only use it if you
need to perform authenticated requests.

=item cache set_cache has_cache no_cache cache_set cache_get 

B<Type>: Cache::Cache

This is actually ducktyped, and requres an object with get and set methods. A
cache is required by the LastFM T&Cs, so be sure to set this.

=item cache_time set_cache_time has_cache_time 

B<Default>: 604800
B<Type>: Int

The number of seconds to cache by default.  Note that this is used when
calling the set method on the cache, so it may be ignored if the caching
object chooses to.  The default is the recomended default from LastFM.

=item lwp_ua set_lwp_ua has_lwp_ua 

B<Default>: LWP::UserAgent->new();
B<Type>: LWP::UserAgent

This is the user agent.  If you want to create your own, or want to do
somthing tricky, set this.

=item rate_limit set_rate_limit has_rate_limit 

B<Default>: 0.2
B<Type>: None

LastFM says you can only make 5 request per second aggregated over a 5 minute
period.  This makes sure that happens.

Now, in theory a much more complicated system, which allowed, say, 1500
requests as fast as you want and then shut you down until 5 minutes passed,
could be used.  I think, however, this is a little nicer and more in keeping
with the spirit of the rules.  If you know you will never ever ever make that
many requests in 5 minutes, set this to 0.  However, i have created programs
that would do this unintentionally (a severe bug).  This saves your api key
from getting disabled.

=item session_cache set_session_cache has_session_cache get_sk set_sk 

B<Type>: Ducktyped.  Requries get and set methods.

This is used in authentication to determine how to store the session keys.
Storing the session key is important, because it is good for life.  So also
keeping it secure is important.  The default for L<Music::LastFM> is B<NOT>
secure, so don't use it for serious work.  

=item url set_url has_url 

B<Default>: http://ws.audioscrobbler.com/2.0/
B<Type>: URI

Set to LastFM API web page.

=item username set_username has_username 

B<Type>: Str

If set, this is the user used for authenticated requests by default.  In a web
page based system, you almost certainly do not want to set this. 

=back

=head2 Methods

=over

=item auth( $params_ref, $username)

Add session key to requests if needed.

=item getsession( $token )

Grabs a session key and stuffs it in the Session Key Cache if it is available.
Croaks if it is not, so you will want to wrap this in an eval.

=item gettoken

Grabs a new token. Returns the url to direct users to go to.  Until the user
goes to this url the getsession method will fail.

=item has_sk($username)

Returns true iff the username is in the session cache.

=item query( method => $method, options => {}, cache_time => 180, object =>
$object);

Performs query and returns a L<Music::LastFM::Response> object on success.
Croaks on failure.  You either want to wrap this, or the function that calls
this in an eval!  

=item sign($params_ref)

Add a signature to the request string.

=back

=head1 DIAGNOSTICS

Will always croak on error.

=head1 CONFIGURATION AND ENVIRONMENT

See L<Music::LastFM>.

=head1 DEPENDENCIES

See L<Music::LastFM>.

=head1 INCOMPATIBILITIES

See L<Music::LastFM>.

=head1 BUGS AND LIMITATIONS

See L<Music::LastFM>.

=head1 AUTHOR

Edward Allen  C<< <ealleniii_at_cpan_dot_org> >>

=head1 LICENSE

Copyright (c) 2011, Edward Allen C<< <ealleniii_at_cpan_dot_org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


