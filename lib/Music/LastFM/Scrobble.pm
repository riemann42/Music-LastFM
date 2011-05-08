package Music::LastFM::Scrobble;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');
use Moose;
use MooseX::Singleton;
use MooseX::Params::Validate;
use Data::Dumper;
use Music::LastFM::Meta::EasyAcc;
#use Moose::Util::TypeConstraints;
use namespace::autoclean;
use English '-no_match_vars';

with 'Music::LastFM::Role::Logger';
use Music::LastFM::Types qw(
    ArrayRef    Track       Tracks 
    DateTime    Int         Str 
    HashRef     Dict        Bool
    CurrentPlay
);

has queue => ( is => 'ro', );

has 'agent' => (
    is        => 'rw',
    isa       => 'Music::LastFM::Agent',
    weak_ref  => 1,
    lazy      => 1,
    default   => sub { Music::LastFM::Agent->instance }
);

has 'current' => (
    is        => 'ro',
    isa       => CurrentPlay,
    clearer   => '_clear_current',
);


has 'waituntil' => (
    is        => 'ro',
    isa       => Int,
);

{
    my ($x,$y) = (0,0);
    sub next_fibonacci {
           (! $x ) ? ( $x = 1 ) 
        :  (! $y ) ? ( $y = 1 ) 
        :            (($x,$y) = ($y, $x+$y));
        return $y || $x;
    }
    sub reset_fibonacci {
        ($x,$y) = (0,0);
    }
}

sub _set_fields {
    my $self = shift;
    my (%options) = validated_hash(
        \@_,
        timestamp => {
            isa      => DateTime,
            coerce   => 1,
            optional => 1,
        },
        track => {
            isa    => Track,
            coerce => 1,
        },
        batchnum => {
            isa      => Int,
            optional => 1,
        },
        req => {
            isa      => HashRef,
            optional => 1,
            }

    );
    my $suffix = q{};
    if ( defined $options{batchnum} ) {
        $suffix = '[' . $options{batchnum} . ']';
    }
    my $req = $options{req} || {};
    $req->{ 'track' . $suffix }  = $options{track}->name;
    $req->{ 'artist' . $suffix } = $options{track}->artist->name;
    foreach my $m (qw(album mbid duration)) {
        my $p = 'has_' . $m;
        if ( $options{track}->$p ) {
            $req->{ $m . $suffix } = $options{track}->$m . q{};
        }
    }
    if ( defined $options{timestamp} ) {
        $req->{timestamp} = $options{timestamp}->epoch;
    }

    # TODO :  Add other fields.
    return $req;
}

sub now_playing {
    my $self = shift;
    my (%options) = validated_hash(
        \@_,
        track => {
            isa    => Track,
            coerce => 1,
        },
    );
    my $req = $self->_set_fields( track => $options{track} );

    my ( $response, @more ) = $self->agent->query(
        method  => 'track.updateNowPlaying',
        options => $req
    );
    $self->debug( Dumper( $response->data ) );
    return $response->is_success;
}

sub scrobble {
    my $self = shift;
    my (%options) = validated_hash(
        \@_,
        tracks => {
            isa    => Tracks,
            coerce => 1,
        }
    );
    foreach ( @{ $options{tracks} } ) {
        $self->queue->add_tracks(
            $self->_set_fields(
                track     => $_,
                timestamp => $_->last_played
            )
        );
    }
}

sub add_track {
    my $self = shift;
    my (%options) = validated_hash(
        \@_,
        track => {
            isa    => Track,
            coerce => 1,
        },
        timestamp => {
            isa     => DateTime,
            optional => 1
        }
    );
    my $req = $self->_set_fields(
        track     => $options{track},
        timestamp => $options{timestamp} || $options{track}->last_played
    );
    use Data::Dumper;
    $self->debug("added track: ", Dumper($req));
    $self->warning("scrobbling: ", $options{track}->name); 
    $self->queue->add_tracks($req);
}

sub process_scrobble_queue {
    my $self  = shift;
    if ($self->has_waituntil) {
        return unless (time > $self->has_waituntil);
    }
    my $queue = $self->queue->next_tracks(50);
    my %req;
    my $batch_num = 0;

    for my $track ( @{$queue} ) {
        while ( my ( $field, $value ) = each %{$track} ) {
            $req{ $field . '[' . $batch_num . ']' } = $value;
        }
        $batch_num++;
    }

    if ($batch_num) {
        my $response;
        eval {
            $response = $self->agent->query(
                method  => 'track.scrobble',
                options => \%req
            );
        };
        if ($EVAL_ERROR) { 
            $self->warning($EVAL_ERROR); 
            if (    ( Music::LastFM::Exception::APIError->caught($EVAL_ERROR))
                 && ( $EVAL_ERROR->can_retry ) ) {
                 my $wait_time = next_fibonacci();
                 $self->warning("Error is retryable. Will try again after $wait_time seconds");
                 $self->_set_waituntil(time + $wait_time);
            }
            else {
                $EVAL_ERROR_>rethrow();
            }
        }
        $self->debug( Dumper( $response->data ) );
        if ( $response->is_success ) {
            reset_fibonacci();
            $self->queue->remove_tracks($batch_num);
        }
    }
    return;
}

sub _reset_current {
    my ($self, $track, $now) = @_;
    $self->_set_current({
        track => $track,
        running_time => 0,
        last_update => $now,
        play_start => $now,
        current_time => 0,
        required_time => (($track->has_duration) && ($track->duration > 30)) ?
                                int($track->duration / 2) : 240
    });
    $self->warning("now playing: ", $track->name); 
    $self->now_playing( track => $track );
}

sub _compare_to_current {
    my $self = shift;
    my $track = shift;
    return 0 if (! $self->has_current);
    if ($track->has_id && $self->current->{track}->has_id) {
        return ($self->current->{track}->id eq $track->id)
    }
    else {
        return (    ($self->current->{track}->artist->name eq $track->artist->name)
                 && ($self->current->{track}->name eq $track->name)); 
    }
}


sub monitor_playback {
    my $self = shift;
    my (%options) = validated_hash(
        \@_,
        track => {
            isa    => Track,
            coerce => 1,
            optional => 1,
        },
        play_status => {
            isa     => Str,
        },
        current_time => {
            isa     => Int,
            optional => 1,
        }
    );
    
    my $now = Music::LastFM::Types->new_datetime(time); 

    if (($options{track}) && (! $self->has_current )) {
        $self->_reset_current($options{track}, $now);
    }
    if (   (! ($options{play_status} eq 'stop')) 
        && ($self->_compare_to_current($options{track})) ) {

        my $played_time = $options{current_time} - $self->current->{current_time};

        my $time_since_update =
            $now->subtract_datetime_absolute($self->current->{last_update})->delta_seconds;
        my ($skipped_back, $realistic_playtime) =
            (($played_time <= -1 * $self->current->{required_time}),  
            (($played_time > 0) && ($played_time <= $time_since_update + 5))); 

        if ($skipped_back) {
            $self->warning("skipped back by $played_time seconds");
            $self->add_track( track => $self->current->{track},
                              timestamp => $self->current->{play_start});
            $self->_reset_current($options{track}, $now);
        }
        elsif ($realistic_playtime) {
            $self->current->{running_time} += $played_time;
        }

        $self->current->{last_update} = $now;
        $self->current->{current_time} = $options{current_time};

    }
    elsif ($self->has_current) {
        if ($self->current->{running_time} > $self->current->{required_time}) {
            $self->add_track( track => $self->current->{track},
                              timestamp => $self->current->{play_start});
        }
        if ($options{track}) {
            $self->_reset_current($options{track}, $now);
        }
        else {
            $self->_clear_current();
        }
    }
    $self->process_scrobble_queue();
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Music::LastFM::Scrobble - [One line description of module's purpose here]

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

=head2 Methods

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
