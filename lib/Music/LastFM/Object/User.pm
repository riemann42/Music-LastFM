package Music::LastFM::Object::User;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
extends qw(Music::LastFM::Object);
use Music::LastFM::Types qw(
    DateTime    Gender      Country     Bool 
    Str         Int         Image       Artists
    Albums      Tracks      Tags
);
use namespace::autoclean;


has '+name' => ( 
    identity  => 'user' 
);
has 'url' => (
    is        => 'ro',
    isa       => Str,
    apimethod => 'user.getInfo'
);
has 'image' => (
    is        => 'ro',
    isa       => Image,
    coerce    => 1,
    apimethod => 'user.getInfo'
);
has 'realname' => (
    is        => 'ro',
    isa       => Str,
    apimethod => 'user.getInfo',
);

has 'id' => (
    is        => 'ro',
    isa       => Int,
    apimethod => 'user.getInfo',
);
has 'age' => (
    is        => 'ro',
    isa       => Int,
    apimethod => 'user.getInfo',
);
has 'subscriber' => (
    is        => 'ro',
    isa       => Bool,
    apimethod => 'user.getInfo',
);
has 'playcount' => (
    is        => 'ro',
    isa       => Int,
    apimethod => 'user.getInfo',
);
has 'gender' => (
    is        => 'ro',
    isa       => Gender,
    coerce    => 1,
    apimethod => 'user.getInfo',
);
has 'playlists' => (
    is        => 'ro',
    isa       => Int,
    apimethod => 'user.getInfo',
);
has 'country' => (
    is        => 'ro',
    isa       => Country,
    coerce    => 1,
    apimethod => 'user.getInfo',
);
has 'registered' => (
    is        => 'ro',
    isa       => DateTime,
    coerce    => 1,
    apimethod => 'user.getInfo',
);

sub top_artists {
    shift->_api_query( method => 'user.getTopArtists',
                       response_type => Artists,
                       @_);
}

sub top_albums {
    shift->_api_query( method => 'user.getTopAlbums',
                       response_type => Albums,
                       @_);
}

sub top_tracks {
    shift->_api_query( method => 'user.getTopTracks',
                       response_type => Tracks,
                       @_);
}

sub top_tags {
    shift->_api_query( method => 'user.getTopTags',
                       response_type => Tracks,
                       @_);
}


sub recent_tracks {
    shift->_api_query( method => 'user.getRecentTracks',
                       response_type => Tracks,
                       @_);
}

sub shout { shift->_shout( method => 'user.shout', @_) }

augment 'check' => sub {
    my $self = shift;
    return $self->id();
};

__PACKAGE__->meta->make_immutable;
1;
