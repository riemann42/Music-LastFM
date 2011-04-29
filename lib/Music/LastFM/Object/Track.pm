package Music::LastFM::Object::Track;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
use Music::LastFM::Types qw(Str Image DateTime);
extends qw(Music::LastFM::Object);
use namespace::autoclean;

has 'url' => ( 
    is => 'rw', 
    isa => Str,
    apimethod => 'track.getInfo'
);
has 'image' => ( 
    is => 'rw', 
    isa => Image, 
    coerce => 1,
    apimethod => 'track.getInfo'
);
has 'last_played' => (
    is => 'rw',
    isa => DateTime,
    coerce => 1,
);
__PACKAGE__->meta->make_immutable;
1;
