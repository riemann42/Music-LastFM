package Music::LastFM::Role::Logger;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');
use Moose::Role;
use Music::LastFM::Types qw(Logger);

has logger => (
    is => "ro",
    isa => Logger,
    lazy =>1,
    default => sub { Music::LastFM::Logger->instance },
    handles => {
        debug => 'debug',
        info => 'info',
        warning=> 'warning',
        critical => 'critical'
    }
        
);

    
1;

