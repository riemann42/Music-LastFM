package Music::LastFM::Agent;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use MooseX::Singleton;
use Music::LastFM::Meta::EasyAcc;

use Music::LastFM::Types qw(UserAgent HashRef ArrayRef Str Int Options Method Meta Metas Cache);
use MooseX::Params::Validate;
use Digest::MD5;
use Time::HiRes;
use Encode;

use Music::LastFM::Response;
use Music::LastFM::Method;

with 'Music::LastFM::Role::Logger';

use namespace::autoclean;

has url => (
    is       => 'rw',
    isa      => Str,
    required => 1,
    default  => 'http://ws.audioscrobbler.com/2.0/'
);
has username   => ( 
    is => 'rw', 
    isa => Str, 
    required => 1 
);
has api_key    => ( 
    is => 'rw', 
    isa => Str, 
    required => 1 
);
has api_secret => ( 
    is => 'rw', 
    isa => Str, 
    required => 1 
);
has ua => (
    is      => 'rw',
    isa     => UserAgent,
    lazy    => 1,
    default => sub {
        my $ua = LWP::UserAgent->new();
        $ua->agent( 'scrobbler-helper/1.0 ' . $ua->_agent() );
        return $ua;
    }
);
has cache_time => (
    is => 'rw', 
    isa => Int, 
    default => 3600
);
has cache => ( 
    is =>'rw', 
    isa => Cache,
    handles => {
        cache_get => 'get',
        cache_set => 'set',
    },
    clearer =>'no_cache',
    documentation => 'This object is used to cache JSON responses from the LastFM Web Service. Defaults to Cache::Filecache, using the cache_time attribute to determine amount of time to cache objects.  This can be cleared with no_cache, or disabled by setting cache_time to 0.'
);
has sessioncache => ( 
    is =>'rw', 
    isa => Cache,
    handles => {
        get_sk => 'get',
        set_sk => 'set',
    }
);

sub makequery {
    my $self  = shift;
    my %query = @_;
    $query{api_key} = $self->api_key;
    my $q = "";
    foreach my $k ( sort keys %query ) {
        my $v = $query{$k};
        if ($q) { $q .= "&" }
        $q .= $k . "=" . URLEncode($v);
    }
    return $q;
}

sub auth {
    my $self     = shift;
    my $params   = shift;
    my $username = shift;
    if ( ! $self->has_sessioncache) {
        Carp::Confess("Can't authorize a request without a sessioncache object");
    }
    if ( $self->get_sk($username)) {
        $params->{sk} = $self->get_sk($username);
    }
    else {
        confess "No session key for $username";
    }
}

sub key {
    my $self = shift;
    my $params = shift;
    my $s = '';
    foreach my $key ( sort keys %{$params} ) {
        $s .= $key . $params->{$key};
    }
    return Digest::MD5::md5_hex($s);
}

sub sign {
    my $self   = shift;
    my $params = shift;
    $params->{api_key} = $self->api_key;
    my $s = '';
    foreach my $key ( sort keys %{$params} ) {
        $s .= $key . $params->{$key};
    }
    $s .= $self->api_secret;
    $params->{api_sig} = Digest::MD5::md5_hex($s);
    return $params;
}

sub gettoken {
    my $self = shift;
    my ($data) = $self->query(
        method     => "auth.getToken",
        cache_time => 0,
    );
    if ( $data->{status} eq 'ok' ) {
        return
              'http://www.last.fm/api/auth/?api_key='
            . $self->mta->options->{api_key}
            . '&token='
            . $data->{token};
    }
}

sub getsession {
    my $self  = shift;
    my $token = shift;

    my $resp = $self->query(
        method     => "auth.getSession",
        cache_time => 0,
        options => { token => $token },
    );
    if ($resp->success) {
        my ($k,$v) = ($resp->data->{name}, $resp->data->{key});
        if ( ! $self->has_sessioncache) {
            Carp::Cluck("Can't save this token, because no session cache defined. ");
            $self->set_sk($k,$v)
        }
        return $k
    }
    return;
}

sub URLEncode($) {
    my $theURL = encode( "utf-8", $_[0] );
    $theURL =~ s/([^a-zA-Z0-9_\.])/'%' . uc(sprintf("%2.2x",ord($1)));/eg;
    return $theURL;
}

sub find_method {
    my $self = shift;
    my $name = shift;
    foreach ( @{ $self->methods } ) {
        if ( lc( $_->name ) eq lc($name) ) {
            return $_;
        }
    }
    return;
}

sub query {
    my $self = shift;
    my ( %options ) = validated_hash(
        \@_,
        method  => { isa => Method, coerce => 1 },
        options => {
            isa      => HashRef,
            optional => 1,
            default  => sub { {} }
        },
        object => { optional => 1 },
        cache_time => { isa => Int, optional => 1, default => $self->cache_time },
        #       session => { isa => Session },
    );

    $options{options}->{format} = 'json';
    my %query = %{ $options{options} };
    $query{method} = $options{method}->name;

    if (( $options{method}->authrequired ) && (! $options{sk})) {
        $self->auth( \%query, $options{username} );
    }
    if ( $options{method}->signrequired ) {
        $self->sign( \%query );
    }
    my $q  = $self->makequery(%query);
    my $qs = "";
    if ($q) { $qs = '?' . $q; }

    my $url     = $self->url;
    my $content = "";
    if (($options{method} eq 'GET') && ($self->has_cache) && ($options{cache_time})) {
         $self->debug("Recovered from cache ". $url . $qs );
         $content = $self->cache_get($self->key(\%query));
    }
    unless ($content) {
        # TODO : Add Optional Rate Limiter
        # Make sure we are not making more than 1 request a second.
        #if ( $self->{last_req_time} ) {
        #    while ( Time::HiRes::tv_interval( $self->{last_req_time} ) < 1 ) {
        #        Time::HiRes::nanosleep(100);
        #    }
        #}
        #$self->{last_req_time} = [ Time::HiRes::gettimeofday() ];

        my $req;
        if ( $options{method}->method eq 'GET' ) {
            $req = new HTTP::Request( 'GET', $url . $qs );
            $self->info("Performing query ". $url . $qs );
        }
        else {
            $req = HTTP::Request->new( 'POST', $url );
            $req->content_type(
                'application/x-www-form-urlencoded; charset="UTF-8"');
            $req->content($q);
            $self->info("Performing POST query ". $url. " - ". $q );
        }
        unless ($req) {
            confess 'Could not create an xml query request object';
        }
        my $resp = $self->ua->request($req);

        $self->debug(
            "Response to xml query is: ".
            $resp->content. " and success is ".
            $resp->status_line
        );
        unless ( $resp->is_success ) {
            $self->warning("Response to query failed: ",
                $resp->status_line );
            return undef;
        }
        $content = $resp->content;
        if (($self->has_cache) && ($options{cache_time})) {
             $self->cache_set($self->key(\%query), $content, $options{cache_time});
        }
    }
    my %opts =
        ( method => $options{method}, json => $content, agent => $self );
    if ( exists $options{object} ) {
        $opts{object} = $options{object};
    }
    return Music::LastFM::Response->new(%opts);
}

sub status {
    my $self = shift;
    print STDERR @_, "\n";
}
__PACKAGE__->meta->make_immutable;
1;

