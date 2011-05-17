package Module::Build::LastFM;
use strict;
use warnings;
use Carp;

use base qw(Module::Build);

use Config::Std {
    read_config  => q{dc_read_config},
    write_config => q{dc_write_config}
};

sub ACTION_record_test {
    my $self = shift;
    $ENV{LWP_RECORD} = 1;
    $self->dispatch('test');
    $ENV{LWP_RECORD} = 0;
}

sub ACTION_authen_test {
    my $self = shift;
    $ENV{WRITE_TESTING} = 1;
    $ENV{LWP_RECORD}    = 1;
    require 't/authentication.t';
}

sub _config_file {
    return 'tmp/options.conf';
}

sub _read_config {
    my $self = shift;
    if ( !-d q{tmp} ) { mkdir q{tmp} }
    my %c = (
        '' => {
            api_key    => q{fa90720dd2bb73f48469d949454bff87},
            api_secret => q{MY LITTLE SECRET},
            username   => 'mlfm_test',
        },
        sessions => {},
    );
    dc_read_config( $self->_config_file => %c );
    return \%c;
}

sub _write_config {
    my $self       = shift;
    my $config_ref = shift;
    dc_write_config( $config_ref => $self->_config_file );
    return;
}

sub ACTION_apikey {
    my $self   = shift;
    my $config = $self->_read_config();

    $config->{q{}}->{api_key} =
        $self->prompt( q{Please enter your LastFM api key},
        $config->{q{}}->{'api_key'} );
    $config->{q{}}->{api_secret} = $self->prompt(
        q{Please enter your LastFM api secret},
        $config->{q{}}->{'api_secret'}
    );
    $config->{q{}}->{username} =
        $self->prompt( q{Please enter a LastFM username },
        $config->{q{}}->{'username'} );

    $self->_write_config($config);
}

sub ACTION_test {
    my $self = shift;
    $self->dispatch('apikey');
    $self->SUPER::ACTION_test(@_);

}

1;
__END__

=head1 ACTIONS

=over

=item record_test

Perform all test in record mode, saving the results.

=item authen_test

Perform a test authentication and grab a session key.  Be sure to run
apikey action to setup testing for your api key.

=item apikey

This will configure tmp/options.conf to use your apikey, rather than mine.

=back

