package Music::LastFM::Object::Album;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
use Music::LastFM::Types qw(
    Image   Artist      Wiki    Tags    Tracks 
    UUID    DateTime    Str     Int     Bool 
    Shouts
);
use Music::LastFM::Meta::LastFM;
extends qw(Music::LastFM::Object);

use namespace::autoclean;

has '+name' => ( 
    identity => 'album' 
);

has 'artist' => ( 
    is => 'rw', 
    isa => Artist, 
    identity => 'artist', 
    coerce => 1,
    required => 1,
);

has '+url' => ( 
    apimethod => 'album.getInfo'
);

has '+image' => ( 
    apimethod => 'album.getInfo'
);

has 'mbid' => (
    is        => 'rw',
    isa       => UUID,
    coerce    => 1,
    identity  => 'mbid',
    apimethod => 'album.getInfo'
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

has 'shouts' => (
    is => 'ro',
    isa => Shouts,
    coerce => 1,
    apimethod => 'album.getShouts'
);

sub add_tags    { shift->_add_tags(   method => 'album.addTags',   @_ ); }
sub share       { shift->_share(      method => 'album.share',     @_ ); }


1;

