package Music::LastFM::Object::Artist;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
use Music::LastFM::Types qw(
    Image   ArtistStats Wiki    Artists 
    Tags    Users       UUID    Str 
    Bool    Int         Shouts
);

extends qw(Music::LastFM::Object);
use namespace::autoclean;

has '+name'  => ( identity  => 'artist' );
has '+url'   => ( apimethod => 'artist.getInfo' );
has '+image' => ( apimethod => 'artist.getInfo' );

has 'mbid' => (
    is        => 'ro',
    isa       => UUID,
    coerce    => 1,
    identity  => 'mbid',
    apimethod => 'artist.getInfo'
);
has 'streamable' => (
    is        => 'ro',
    isa       => Bool,
    apimethod => 'artist.getInfo'
);
has 'userplaycount' => (
    is  => 'ro',
    isa => Int,
    api => 'playcount'
);
has 'stats' => (
    is        => 'ro',
    isa       => ArtistStats,
    apimethod => 'artist.getInfo'
);
has 'bio' => (
    is        => 'ro',
    isa       => Wiki,
    apimethod => 'artist.getInfo'
);
has 'similar' => (
    is        => 'ro',
    isa       => Artists,
    coerce    => 1,
    apimethod => 'artist.getInfo'
);
has 'similar_extended' => (
    is        => 'ro',
    isa       => Artists,
    coerce    => 1,
    apimethod => 'artist.getSimilar',
    api       => 'similarartists',
);
has 'tags' => (
    is        => 'ro',
    isa       => Tags,
    coerce    => 1,
    apimethod => 'artist.getTags'
);
has 'toptags' => (
    is        => 'ro',
    isa       => Tags,
    coerce    => 1,
    apimethod => 'artist.getTopTags',
    api       => 'toptags'
);
has 'topfans' => (
    is        => 'ro',
    isa       => Users,
    coerce    => 1,
    apimethod => 'artist.getTopFans'
);
has 'albums' => (
    is        => 'ro',
    isa       => Users,
    coerce    => 1,
    apimethod => 'artist.getTopAlbums',
    api       => 'topalbums'
);
has 'shouts' => (
    is => 'ro',
    isa => Shouts,
    coerce => 1,
    apimethod => 'artist.getShouts'
);

sub playcount {
    my $self = shift;
    $self->stats();    # Grab if needed
    return $self->has_stats ? $self->stats->{playcount} : undef;
}

sub listeners {
    my $self = shift;
    $self->stats();    # Grab if needed
    return $self->has_stats ? $self->stats->{listeners} : undef;
}

sub add_tags    { shift->_add_tags(   method => 'artist.addTags',   @_ ); }
sub share       { shift->_share(      method => 'artist.share',     @_ ); }

__PACKAGE__->meta->make_immutable;
1;

