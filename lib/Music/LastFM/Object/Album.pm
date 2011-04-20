package Music::LastFM::Object::Album;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
use Music::LastFM::Types qw(Image Artist Wiki Tags  Tracks UUID DateTime Str Int Bool);
use Music::LastFM::Meta::LastFM;
extends qw(Music::LastFM::Object);

use namespace::autoclean;

has 'name' => ( 
    is => 'rw', 
    isa => Str, 
    required => 1,
    identity => 'album' 
);

has 'mbid' => (
    is        => 'rw',
    isa       => UUID,
    coerce    => 1,
    identity  => 'mbid',
    apimethod => 'album.getInfo'
);

has 'url' => ( 
    is => 'rw', 
    isa => Str,
    apimethod => 'album.getInfo'
);

has 'url' => ( 
    is => 'rw', 
    isa => Str,
    apimethod => 'album.getInfo'
);
has 'image' => ( 
    is => 'rw', 
    isa => Image, 
    coerce => 1,
    apimethod => 'album.getInfo'
);

has 'artist' => ( 
    is => 'rw', 
    isa => Artist, 
    identity => 'artist', 
    coerce => 1
);

has 'streamable' => ( 
    is => 'rw', 
    isa => Bool, 
    apimethod => 'album.getInfo' 
);

has 'releasedate' => (
    is        => 'rw',
    isa       => DateTime,
    coerce    => 1,
    apimethod => 'album.getInfo'
);

has 'wiki' => ( 
    is => 'rw', 
    isa => Wiki, 
    apimethod => 'album.getInfo' 
);

has 'listeners' => ( 
    is => 'rw', 
    isa => Int, 
    apimethod => 'album.getInfo' 
);

has 'playcount' => ( 
    is => 'rw', 
    isa => Int, 
    apimethod => 'album.getInfo' 
);

has 'userplaycount' => (
    is => 'rw',
    isa => Int 
);

has 'tracks' => ( 
    is => 'rw', 
    isa => Tracks, 
    coerce => 1, 
    apimethod => 'album.getInfo' 
);

has 'toptags' => ( 
    is => 'rw', 
    isa => Tags, 
    coerce => 1, 
    apimethod => 'album.getTopTags' 
);


1;

