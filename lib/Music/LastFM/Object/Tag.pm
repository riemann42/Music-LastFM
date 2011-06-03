package Music::LastFM::Object::Tag;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
use Music::LastFM::Types qw(Wiki Str Int Bool Image);
extends qw(Music::LastFM::Object);
use namespace::autoclean;

has 'url' => ( 
    traits   => [qw(LastFM)],
    is => 'rw', 
    isa => Str,
    apimethod => 'tag.getInfo'
);
has 'image' => ( 
    traits   => [qw(LastFM)],
    is => 'rw', 
    isa => Image, 
    coerce => 1,
    apimethod => 'tag.getInfo'
);
has 'reach'      => ( 
    traits   => [qw(LastFM)],
is => 'rw', isa => Int );
has 'taggings'   => ( 
    traits   => [qw(LastFM)],
is => 'rw', isa => Int );
has 'count'      => ( 
    traits   => [qw(LastFM)],
is => 'rw', isa => Int );
has 'streamable' => (
    traits   => [qw(LastFM)],
is => 'rw', isa => Bool );
has 'wiki'       => ( 
    traits   => [qw(LastFM)],
is => 'rw', isa => Wiki );

__PACKAGE__->meta->make_immutable;
1;
