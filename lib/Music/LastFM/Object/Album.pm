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
    identity => 'album' ,
    traits   => [qw(LastFM)],
);

has 'artist' => ( 
    is => 'rw', 
    isa => Artist, 
    identity => 'artist', 
    coerce => 1,
    required => 1,
    traits   => [qw(LastFM)],
);

has '+url' => ( 
    traits   => [qw(LastFM)],
    apimethod => 'album.getInfo'
);

has '+image' => ( 
    traits   => [qw(LastFM)],
    apimethod => 'album.getInfo'
);

has 'mbid' => (
    traits   => [qw(LastFM)],
    is        => 'rw',
    isa       => UUID,
    coerce    => 1,
    identity  => 'mbid',
    apimethod => 'album.getInfo'
);

has 'streamable' => ( 
    traits   => [qw(LastFM)],
    is => 'rw', 
    isa => Bool, 
    apimethod => 'album.getInfo' 
);

has 'releasedate' => (
    traits   => [qw(LastFM)],
    is        => 'rw',
    isa       => DateTime,
    coerce    => 1,
    apimethod => 'album.getInfo'
);

has 'wiki' => ( 
    traits   => [qw(LastFM)],
    is => 'rw', 
    isa => Wiki, 
    apimethod => 'album.getInfo' 
);

has 'listeners' => ( 
    traits   => [qw(LastFM)],
    is => 'rw', 
    isa => Int, 
    apimethod => 'album.getInfo' 
);

has 'playcount' => ( 
    traits   => [qw(LastFM)],
    is => 'rw', 
    isa => Int, 
    apimethod => 'album.getInfo' 
);

has 'userplaycount' => (
    traits   => [qw(LastFM)],
    is => 'rw',
    isa => Int 
);

has 'tracks' => ( 
    traits   => [qw(LastFM)],
    is => 'rw', 
    isa => Tracks, 
    coerce => 1, 
    apimethod => 'album.getInfo' 
);

has 'toptags' => ( 
    traits   => [qw(LastFM)],
    is => 'rw', 
    isa => Tags, 
    coerce => 1, 
    apimethod => 'album.getTopTags' 
);

has 'shouts' => (
    traits   => [qw(LastFM)],
    is => 'ro',
    isa => Shouts,
    coerce => 1,
    apimethod => 'album.getShouts'
);

sub add_tags    { shift->_add_tags(   method => 'album.addTags',   @_ ); }
sub remove_tag  { shift->_remove_tag( method => 'album.removeTag', @_ ); }
sub share       { shift->_share(      method => 'album.share',     @_ ); }


1;

