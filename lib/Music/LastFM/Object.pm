package Music::LastFM::Object;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');
use Moose;

use Music::LastFM::Types qw(Image HashRef ArrayRef Str Int);
use Music::LastFM::Meta::LastFM;

has 'name' => ( is => 'rw', isa => Str, required => 1);
with 'Music::LastFM::Role::Overload';

has 'agent' => (
    is        => 'rw',
    weak_ref  => 1,
    lazy      => 1,
    predicate => 'has_agent',
    default   => sub { Music::LastFM::Agent->instance }
);

__PACKAGE__->meta->make_immutable();
no Moose;
1;

