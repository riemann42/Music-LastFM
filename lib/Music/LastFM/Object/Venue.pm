package Music::LastFM::Object::Venue;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
use Music::LastFM::Types qw(Str);
extends qw(Music::LastFM::Object);
use namespace::autoclean;

__PACKAGE__->meta->make_immutable;
1;
