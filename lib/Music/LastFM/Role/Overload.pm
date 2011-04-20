package Music::LastFM::Role::Overload;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');
use MooseX::Role::WithOverloading;

use overload '""'      => \&stringify, fallback => 1;

requires(qw(name));
sub stringify { shift->name() }

no Moose;
1;

