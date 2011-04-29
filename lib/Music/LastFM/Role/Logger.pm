package Music::LastFM::Role::Logger;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');
use Moose::Role;
use Music::LastFM::Types qw(Logger);
use Music::LastFM::Exception;

has logger => (
    is => "ro",
    isa => Logger,
    lazy =>1,
    default => sub { Music::LastFM::Logger->instance },
    predicate => '_has_logger',
    handles => {
        debug => 'debug',
        info => 'info',
        warning=> 'warning',
        critical => 'critical'
    }
        
);

sub die {
    my $self = shift;
    my ($message,$exception_object,@fields) = @_;
    if ($self->_has_logger) {
        $self->critical($message);
    }
    if (! defined $exception_object) {
        $exception_object = 'Music::LastFM::Exception';
    }
    $exception_object->throw(message => $message,@fields,);
}

    
1;

