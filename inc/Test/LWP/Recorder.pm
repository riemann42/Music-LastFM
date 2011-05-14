package Test::LWP::Recorder;

use strict;
use warnings;
use Carp;
use version; our $VERSION = qv('0.0.3');

use base qw(LWP::UserAgent);
use Digest::MD5 qw(md5_hex);
use File::Slurp;
use File::Spec;
use List::Util qw(reduce);
use HTTP::Status qw(:constants);

sub new {
    my $class    = shift;
    my %defaults = (
        record        => 0,
        cache_dir     => 't/LWPCache',
        filter_params => [],
        filter_header => [qw(Client-Peer Expires Client-Date Cache-Control)],
    );
    my $params = shift || {};
    my $self = $class->SUPER::new(@_);
    $self->{_test_options} = { %defaults, %{$params} };
    return $self;
}

sub _filter_param {
    my ( $self, $key, $value ) = @_;
    my %filter = map { $_ => 1 } @{ $self->{_test_options}->{filter_params} };
    return join q{=}, $key, $filter{$key} ? q{} : $value;
}

sub _filter_all_params {
    my $self         = shift;
    my $param_string = shift;
    my %query =
        map { ( split qr{ = }xms )[ 0, 1 ] }
        split qr{ \& }xms, $param_string;
    return reduce { $a . $self->_filter_param( $b, $query{$b} ) }
    sort keys %query;
}

sub _get_cache_key {
    my ( $self, $request ) = @_;
    my $params = $request->uri->query() || q{};

    # TODO : Test if it is URL Encoded before blindly assuming.
    if ( $request->content ) {
        $params .= ($params) ? q{&} : q{};
        $params .= $request->content;
    }

    my $key =
          $request->method . q{ }
        . lc( $request->uri->host )
        . $request->uri->path . q{?}
        . $self->_filter_all_params($params);

    #warn "Key is $key";
    return File::Spec->catfile( $self->{_test_options}->{cache_dir},
        md5_hex($key) );
}

sub _filter_headers {
    my ( $self, $response ) = @_;
    foreach ( @{ $self->{_test_options}->{filter_header} } ) {
        $response->remove_header($_);
    }
    return;
}

sub request {
    my ( $self, @original_args ) = @_;
    my $request = $original_args[0];

    my $key = $self->_get_cache_key($request);

    if ( $self->{_test_options}->{record} ) {
        my $response = $self->SUPER::request(@original_args);

        my $cache_response = $response->clone;
        $self->_filter_headers($cache_response);
        $self->_set_cache( $key, $cache_response );

        return $response;
    }

    if ( $self->_has_cache($key) ) {
        return $self->_get_cache($key);
    }
    else {
        carp q{Page requested that wasn't recorded: }
            . $request->URI->as_string;
        return HTTP::Response->new(HTTP_NOT_FOUND);
    }
}

sub _set_cache {
    my ( $self, $key, $response ) = @_;
    write_file( $key, $response->as_string );
    return;
}

sub _has_cache {
    my ( $self, $key ) = @_;
    return ( -f $key );
}

sub _get_cache {
    my ( $self, $key ) = @_;
    my $file = read_file($key);
    return HTTP::Response->parse($file);
}

1;
