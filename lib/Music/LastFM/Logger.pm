package Music::LastFM::Logger;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');
use MooseX::Singleton;
use Music::LastFM::Types qw(Logger);

has logger => (
    is => "ro",
    isa => Logger,
    required => 1,
    handles => {
        debug => 'debug',
        info => 'info',
        warning=> 'warning',
        critical => 'critical'
    }
);

1;
