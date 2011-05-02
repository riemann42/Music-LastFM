package Music::LastFM::Object::Track;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
use namespace::autoclean;

use Music::LastFM::Types qw(
    Str     Image   DateTime    Int
    Wiki    UUID    Album       Artist
    Tags    Users   Tracks
);

extends qw(Music::LastFM::Object);

has '+name' => ( identity => 'track' );

has 'artist' => (
    is       => 'rw',
    isa      => Artist,
    identity => 'artist',
    coerce   => 1,
    required => 1,
);

has '+url'   => ( apimethod => 'track.getInfo' );
has '+image' => ( apimethod => 'track.getInfo' );

has 'last_played' => (
    is     => 'rw',
    isa    => DateTime,
    coerce => 1,
);

has 'id' => (
    is        => 'rw',
    isa       => Int,
    apimethod => 'track.getInfo',
);

has 'mbid' => (
    is        => 'rw',
    isa       => UUID,
    apimethod => 'track.getInfo',
);

has 'duration' => (
    is        => 'rw',
    isa       => Int,
    apimethod => 'track.getInfo',
);

has 'listeners' => (
    is        => 'rw',
    isa       => Int,
    apimethod => 'track.getInfo',
);

has 'playcount' => (
    is        => 'rw',
    isa       => Int,
    apimethod => 'track.getInfo',
);

has 'album' => (
    is        => 'rw',
    isa       => Album,
    apimethod => 'track.getInfo',
);

has 'tags' => (
    is        => 'rw',
    isa       => Tags,
    coerce    => 1,
    apimethod => 'track.getTags',
);

has 'toptags' => (
    is        => 'rw',
    isa       => Tags,
    coerce    => 1,
    apimethod => 'track.getTopTags',
);

has 'topfans' => (
    is        => 'rw',
    isa       => Users,
    coerce    => 1,
    apimethod => 'track.getTopFans',
);

has 'wiki' => (
    is        => 'rw',
    isa       => Wiki,
    apimethod => 'track.getInfo',
);

has 'similar' => (
    is        => 'rw',
    isa       => Tracks,
    apimethod => 'track.getSimilar',
);

sub add_tags    { shift->_add_tags(   method => 'track.addTags',   @_ ); }
sub remove_tag  { shift->_remove_tag( method => 'track.removeTag', @_ ); }
sub share       { shift->_share(      method => 'track.share',     @_ ); }
sub ban         { shift->_api_action( method => 'track.ban',       @_ ); }
sub love        { shift->_api_action( method => 'track.love',      @_ ); }
sub unban       { shift->_api_action( method => 'track.unban',     @_ ); }
sub unlove      { shift->_api_action( method => 'track.unlove',    @_ ); }

__PACKAGE__->meta->make_immutable;
1;
