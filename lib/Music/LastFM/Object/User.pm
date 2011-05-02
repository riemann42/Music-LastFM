package Music::LastFM::Object::User;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
extends qw(Music::LastFM::Object);
use Music::LastFM::Types qw(DateTime Gender Country Bool Str Int Image);
use namespace::autoclean;


has '+name' => ( 
    identity  => 'user' 
);
has 'url' => (
    is        => 'rw',
    isa       => Str,
    apimethod => 'user.getInfo'
);
has 'image' => (
    is        => 'rw',
    isa       => Image,
    coerce    => 1,
    apimethod => 'user.getInfo'
);
has 'realname' => (
    is        => 'rw',
    isa       => Str,
    apimethod => 'user.getInfo',
);

has 'id' => (
    is        => 'rw',
    isa       => Int,
    apimethod => 'user.getInfo',
);
has 'age' => (
    is        => 'rw',
    isa       => Int,
    apimethod => 'user.getInfo',
);
has 'subscriber' => (
    is        => 'rw',
    isa       => Bool,
    apimethod => 'user.getInfo',
);
has 'playcount' => (
    is        => 'rw',
    isa       => Int,
    apimethod => 'user.getInfo',
);
has 'gender' => (
    is        => 'rw',
    isa       => Gender,
    coerce    => 1,
    apimethod => 'user.getInfo',
);
has 'playlists' => (
    is        => 'rw',
    isa       => Int,
    apimethod => 'user.getInfo',
);
has 'country' => (
    is        => 'rw',
    isa       => Country,
    coerce    => 1,
    apimethod => 'user.getInfo',
);
has 'registered' => (
    is        => 'rw',
    isa       => DateTime,
    coerce    => 1,
    apimethod => 'user.getInfo',
);

sub shout { shift->_shout( method => 'user.shout', @_) }


__PACKAGE__->meta->make_immutable;
1;
