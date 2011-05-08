package Music::LastFM::Scrobble;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');
use Moose;
use MooseX::Singleton;
use Music::LastFM::Types qw(
    ArrayRef    Track       Tracks 
    DateTime    Int         Str 
    HashRef     Dict        Bool
    CurrentPlay
);
use MooseX::Params::Validate;
use Data::Dumper;
use Music::LastFM::Meta::EasyAcc;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

with 'Music::LastFM::Role::Logger';

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
        # TODO : Add more sanity checks to make sure scrobbles went a-ok.
        if ($@) { $self->warning($@) }
        $self->debug( Dumper( $response->data ) );
        if ( $response->is_success ) {
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
    
    my $now = find_type_constraint(DateTime)->coerce( time );

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
