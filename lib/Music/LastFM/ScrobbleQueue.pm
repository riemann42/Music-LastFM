package Music::LastFM::ScrobbleQueue;

use strict;
use warnings;

use Moose;
use Music::LastFM::Types qw(Str  Bool);
with 'Music::LastFM::Role::Logger';

use File::Queue;
use JSON;

has _file_object => (
    is      => 'ro',
    isa     => 'File::Queue',
    lazy    => 1,
    builder => '_file_object_builder',
);

has _loaded => (
    is        => 'ro',
    reader    => '_loaded',
    isa       => Bool,
    default   => 0,
);

has filename => (
    is        => 'ro',
    required  => 1,
    isa       => Str,
);


sub _file_object_builder {
    my $self = shift;
    $self->warning("Creating queue object of file" . $self->filename);
    return  File::Queue->new(File => $self->filename);
}

sub _freeze {
    my $self = shift;
    my $scalar = shift;
    return encode_json($scalar);
}


sub _thaw {
    my $self = shift;
    my $json = shift;
    return decode_json($json);
}


sub add_tracks { 
    my $self = shift;
    foreach my $track (@_)  {
        $self->_file_object->enq($self->_freeze($track));
    }
}

sub next_tracks {
    my $self = shift;
    my $num_tracks = shift;
    my $next_track = $self->_file_object->peek($num_tracks);
    return [ map { $self->_thaw($_) } @{$next_track}];
}

sub remove_tracks {
    my $self = shift;
    my $num_tracks = shift;
    my $removed = 0;
    TRACK:
    for (1..$num_tracks) {
        if($self->_file_object->deq()) {
            $removed++;
        }
        else {
            last TRACK;
        }
    }
    return $removed;
}

1;
