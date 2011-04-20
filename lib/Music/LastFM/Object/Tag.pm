package Music::LastFM::Object::Tag;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
use Music::LastFM::Types qw(Wiki Str Int Bool Image);
extends qw(Music::LastFM::Object);
use namespace::autoclean;

has 'url' => ( 
    is => 'rw', 
    isa => Str,
    apimethod => 'tag.getInfo'
);
has 'image' => ( 
    is => 'rw', 
    isa => Image, 
    coerce => 1,
    apimethod => 'tag.getInfo'
);
has 'reach'      => ( is => 'rw', isa => Int );
has 'taggings'   => ( is => 'rw', isa => Int );
has 'count'      => ( is => 'rw', isa => Int );
has 'streamable' => ( is => 'rw', isa => Bool );
has 'wiki'       => ( is => 'rw', isa => Wiki );

__PACKAGE__->meta->make_immutable;
1;
