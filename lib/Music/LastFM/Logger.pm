package Music::LastFM::Logger;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');
use MooseX::Singleton;
use Music::LastFM::Types;
use namespace::autoclean;

has logger => (
    is => "ro",
#    isa => 'Music::LastFM::Types::Logger',
    required => 1,
    handles => {
        debug => 'debug',
        info => 'info',
        warning=> 'warning',
        critical => 'critical'
    }
);

__PACKAGE__->meta->make_immutable;
1;
