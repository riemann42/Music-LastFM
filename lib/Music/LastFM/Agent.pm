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
    is       => 'rw',
    isa      => Str,
    required => 1,
    default  => 'http://ws.audioscrobbler.com/2.0/',
);
has username => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);
has api_key => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);
has api_secret => (
    is       => 'rw',
    isa      => Str,
    required => 1,
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
    default => 3600,
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
has rate_limit => (
    is      => 'rw',
    isa     => Num,
    default => .5,
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
    my $username = shift;
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
            $self->set_sk( $username, $session_key );
        }
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
    my ( $self, $options_ref ) = @_;
    $options_ref->{options}->{format} = 'json';
    my %query_hash = %{ $options_ref->{options} };
    $query_hash{method} = $options_ref->{method}->name;

    if (   ( $options_ref->{method}->auth_required )
        && ( !$options_ref->{sk} ) ) {
        $self->auth( \%query_hash, $options_ref->{username} );
    }
    if ( $options_ref->{method}->sign_required ) {
        $self->sign( \%query_hash );
    }
    $query_hash{api_key} = $self->api_key;
    my $query_string = q{};
    $query_string = join q{&}, map { _query_pair( $_, $query_hash{$_} ) }
        sort keys %query_hash;
    return $query_string;
}

sub _build_request {
    my ( $self, $lastfm_method, $query_string ) = @_;
    my $url = $self->url();
    my $lwp_request;
    if ( $lastfm_method eq 'GET' ) {
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

sub query {
    my ( $self, @opts ) = @_;
    my $options_default = {};
    my (%options) = validated_hash(
        \@opts,
        method  => { isa => Method, coerce => 1 },
        options => {
            isa     => HashRef,
            default => $options_default,
        },
        object => { optional => 1 },
        cache_time =>
            { isa => Int, optional => 1, default => $self->cache_time },

        #       session => { isa => Session },
    );
    $options{method}->set_agent($self);
    my $query_string = $self->_build_query( \%options );

    my $content = q{};
    if (   ( $options{method} eq 'GET' )
        && ( $self->has_cache )
        && ( $options{cache_time} ) ) {
        $self->debug("Recovered from cache $query_string");
        $content = $self->cache_get( $self->key($query_string) );
    }

    if ( !$content ) {
        $self->limit_request_rate();

        my $lwp_request =
            $self->_build_request( $options{method}, $query_string );
        my $lwp_resp = $self->lwp_ua->request($lwp_request);

        $self->debug( '"Response to query is: '
                    . $lwp_resp->content
                    . ' and success is '
                    . $lwp_resp->status_line );
        if ( !$lwp_resp->is_success ) {
            $self->die( 'Response to query failed: ',
                $lwp_resp->status_line );
            return;
        }
        $content = $lwp_resp->content;
        if ( ( $self->has_cache ) && ( $options{cache_time} ) ) {
            $self->cache_set( $self->_key($query_string),
                $content, $options{cache_time} );
        }
    }
    my %response_options = (
        method => $options{method},
        json   => $content,
        agent  => $self,
    );
    if ( exists $options{object} ) {
        $response_options{object} = $options{object};
    }
    return Music::LastFM::Response->new(%response_options);
}

__PACKAGE__->meta->make_immutable;
1;

