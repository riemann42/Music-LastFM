package Music::LastFM::Agent;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');

use MooseX::Singleton;
use Music::LastFM::Meta::EasyAcc;

use Music::LastFM::Types
    qw(UserAgent HashRef ArrayRef Str Int Options Method Meta Metas Cache Num);
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
        $self->die( q{A username must be provided for authenticated queries. }
                . q{You can set the username attribute, or pass it as an option}
                . q{to the query paramater} );
    }
    if ( !$self->has_session_cache ) {
        $self->die(
            q{Can't authorize a request without a session_cache object});
    }
    if ( $self->get_sk($username) ) {
        $params->{sk} = $self->get_sk($username);
    }
    else {
        $self->die(
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
        $self->die(
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
        $self->die(
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
            $self->warning(
                qq{Can't save this session, because no session cache defined.\n}
                    . q{Please re-read the Music::LastFM Documentation"} );
        }
        $self->set_sk( $username => $session_key );
        return $resp->data;
    }
    else {
        $self->die('Failed to get session key for unknown reason');
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
        $self->info(qq{Performing query $url?$query_string});
    }
    else {
        $lwp_request = HTTP::Request->new( 'POST', $url );
        $lwp_request->content_type(
            'application/x-www-form-urlencoded; charset="UTF-8"');
        $lwp_request->content($query_string);
        $self->info(qq{Performing POST query $url - $query_string});
    }
    if ( !$lwp_request ) {
        $self->die('Could not create an xml query request object');
    }
    return $lwp_request;
}

sub limit_request_rate {
    my $self = shift;
    if ( $self->{last_req_time} ) {
        while ( Time::HiRes::tv_interval( $self->{last_req_time} )
            < $self->rate_limit ) {
            Time::HiRes::nanosleep($NANOSLEEP_TIME);
        }
    }
    $self->{last_req_time} = [ Time::HiRes::gettimeofday() ];
    return;
}

sub _perform_query {
    my ( $self, $params_ref, $query_string ) = @_;

    my $lwp_request =
        $self->_build_request( $params_ref->{method}, $query_string );
    my $lwp_resp = $self->lwp_ua->request($lwp_request);

    $self->debug( q{Response to query is: }
            . $lwp_resp->content
            . q{ and success is }
            . $lwp_resp->status_line );

    if ( !$lwp_resp->is_success ) {
        $self->die(
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
        $self->debug("Recovered from cache: $query_string");
        $content = $self->cache_get( $self->_key($query_string) );
    }
    if ( !$content ) {
        $self->limit_request_rate();
        $content = $self->_perform_query( \%params, $query_string );
        if ( $params{cache_time} ) {
            $self->debug("Saving to cache: $query_string");
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

    use Music::LastFM;
  
=head1 DESCRIPTION

Support module for Music::LastFM.

=head1 METHODS

=head2 Constructor

=over

=item new

=head2 Attributes

=head2 Methods

=head1 DIAGNOSTICS

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
