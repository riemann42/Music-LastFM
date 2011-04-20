package Music::LastFM::Object::Artist;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
use Music::LastFM::Types qw(Image ArtistStats Wiki Artists Tags Users UUID Str Bool Int);
extends qw(Music::LastFM::Object);
use namespace::autoclean;

has 'name' => ( is => 'rw', isa => Str, required => 1, identity => 'artist' );
has 'mbid' => (
    is        => 'rw',
    isa       => UUID,
    coerce    => 1,
    identity  => 'mbid',
    apimethod => 'artist.getInfo'
);
has 'url' => ( 
    is => 'rw', 
    isa => Str,
    apimethod => 'artist.getInfo'
);
has 'image' => ( 
    is => 'rw', 
    isa => Image, 
    coerce => 1,
    apimethod => 'artist.getInfo'
);
has 'streamable' => ( 
    is => 'rw', 
    isa => Bool, 
    apimethod => 'artist.getInfo' 
);
has 'userplaycount' => ( 
    is => 'rw', 
    isa => Int, 
    api => 'playcount'
);
has 'stats' => ( 
    is => 'rw', 
    isa => ArtistStats, 
    apimethod => 'artist.getInfo' 
);
has 'bio' => ( 
    is => 'rw', 
    isa => Wiki, 
    apimethod => 'artist.getInfo' 
);
has 'similar' => (
    is        => 'rw',
    isa       => Artists,
    coerce    => 1,
    apimethod => 'artist.getInfo'
);
has 'similar_extended' => (
    is        => 'rw',
    isa       => Artists,
    coerce    => 1,
    apimethod => 'artist.getSimilar',
    api => 'similarartists',
);
has 'tags' => ( 
    is => 'rw', 
    isa => Tags, 
    coerce => 1, 
    apimethod => 'artist.getInfo' 
);
has 'toptags' => ( 
    is => 'rw', 
    isa => Tags, 
    coerce => 1, 
    apimethod => 'artist.getTopTags' ,
    api => 'toptags'
);
has 'topfans' => ( 
    is => 'rw',
    isa => Users, 
    coerce => 1, 
    apimethod => 'artist.getTopFans' 
);
has 'albums' => ( 
    is => 'rw',
    isa => Users, 
    coerce => 1, 
    apimethod => 'artist.getTopAlbums',
    api => 'topalbums'
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

sub stringify {
    my $self = shift;
    return $self->name();
}

__PACKAGE__->meta->make_immutable;
1;

