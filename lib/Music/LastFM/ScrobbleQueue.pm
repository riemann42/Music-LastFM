package Music::LastFM::ScrobbleQueue;

use strict;
use warnings;

use Moose;
use Music::LastFM::Types qw(Str  Bool);
with 'Music::LastFM::Role::Logger';

use File::Queue;
use JSON;
use namespace::autoclean;

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

__PACKAGE__->meta->make_immutable();
1;
__END__

=head1 NAME

Music::LastFM::ScrobbleQueue - [One line description of module's purpose here]

=head1 VERSION

This document describes Music::LastFM version 0.0.3

=head1 SYNOPSIS

    use Music::LastFM;
  
=head1 DESCRIPTION

Support module for Music::LastFM.

=head1 METHODS

=head2 Constructor

=over

=item new

=head2 Attributes

=item



=item



=item filename REQUIRED



=item logger info critical debug warning 



=head2 Methods

=item add_tracks

=item die

=item meta

=item next_tracks

=item remove_tracks

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

See L<Music::LastFM>.

=head1 DEPENDENCIES

See L<Music::LastFM>.

=head1 INCOMPATIBILITIES

See L<Music::LastFM>.

=head1 BUGS AND LIMITATIONS

See L<Music::LastFM>.

=head1 AUTHOR

Edward Allen  C<< <ealleniii_at_cpan_dot_org> >>

=head1 LICENSE

Copyright (c) 2011, Edward Allen C<< <ealleniii_at_cpan_dot_org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


