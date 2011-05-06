package Music::LastFM::Object::Artist;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
use Music::LastFM::Types qw(
    Image   ArtistStats Wiki    Artists 
    Tags    Users       UUID    Str 
    Bool    Int         Shouts  Events
    Images
);

extends qw(Music::LastFM::Object);
use namespace::autoclean;

has '+name'  => ( identity  => 'artist'         );
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
has 'user_playcount' => (
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
has 'events' => (
    is       => 'ro',
    isa      => Events,
    coerce => 1,
    apimethod => 'artist.getEvents'
);
#has 'past_events' => (
#    is       => 'ro',
#    isa      => Events,  # TODO : Fix coercion
#    coerce => 1,
#    apimethod => 'artist.getPastEvents'
#);
has 'images' => (
    is       => 'ro',
    isa      => Images,
    coerce => 1,
    apimethod => 'artist.getImages'
);


sub user_tags {
    shift->_api_query( method => 'artist.getTags',
                       response_type => Tags,
                       @_);
};


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

augment check => sub {
    my $self = shift;
    return $self->playcount();
};

sub add_tags    { shift->_add_tags(   method => 'artist.addTags',   @_ ); }
sub share       { shift->_share(      method => 'artist.share',     @_ ); }
sub remove_tag  { shift->_remove_tag( method => 'artist.removeTag', @_ ); }
sub shout       { shift->_shout(      method => 'artist.shout',     @_) }

__PACKAGE__->meta->make_immutable;
1;

