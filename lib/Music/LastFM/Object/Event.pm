package Music::LastFM::Object::Event;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
use Music::LastFM::Types qw(Str Image);
extends qw(Music::LastFM::Object);
use namespace::autoclean;
has 'url' => ( 
    is => 'rw', 
    isa => Str,
#    apimethod => 'artist.getInfo'
);
has 'image' => ( 
    is => 'rw', 
    isa => Image, 
    coerce => 1,
#    apimethod => 'artist.getInfo'
);

__PACKAGE__->meta->make_immutable;
1;
