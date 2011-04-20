package Music::LastFM::Object::User;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use Moose;
extends qw(Music::LastFM::Object);
use Music::LastFM::Types qw(DateTime Gender Country Bool Str Int Image);
use namespace::autoclean;

has 'url' => ( 
    is => 'rw', 
    isa => Str,
    apimethod => 'user.getInfo'
);
has 'image' => ( 
    is => 'rw', 
    isa => Image, 
    coerce => 1,
    apimethod => 'user.getInfo'
);
has 'realname'   => ( is => 'rw', isa => Str );
has 'id'         => ( is => 'rw', isa => Int );
has 'age'        => ( is => 'rw', isa => Int );
has 'subscriber' => ( is => 'rw', isa => Bool );
has 'playcount'  => ( is => 'rw', isa => Int );
has 'gender'     => ( is => 'rw', isa => Gender, coerce => 1 );
has 'playlists'  => ( is => 'rw', isa => Int );
has 'country'    => ( is => 'rw', isa => Country, coerce => 1 );
has 'registered' => ( is => 'rw', isa => DateTime, coerce => 1 );

__PACKAGE__->meta->make_immutable;
1;
