package Music::LastFM::Scrobble;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');
use Moose;
use MooseX::Singleton;
use Music::LastFM::Types qw(ArrayRef Track DateTime);
use MooseX::Params::Validate;
use Data::Dumper;

with 'Music::LastFM::Role::Logger';

has queue => (
    is => 'ro',
    isa => ArrayRef,
    default => sub{[]};
);

has 'agent' => (
    is        => 'rw',
    isa       => 'Music::LastFM::Agent',
    weak_ref  => 1,
    lazy      => 1,
    predicate => 'has_agent',
    default   => sub { Music::LastFM::Agent->instance }
);

sub _set_fields {
    my $self = shift;
    my ( %options ) = validated_hash(
        \@_,
        timestamp => {
            isa => DateTime,
            coerce => 1,
            optional => 1,
        },
        track => {
            isa => Track,
            coerce => 1,
        },
        batchnum => {
            isa => Int,
            optional => 1,
        },
        req => {
            isa => HashRef,
            optional => 1,
        }

    );
    my $suffix = q{};
    if (defined $options{batchnum}) {
        $suffix = '['.$options{batchnum}.']';
    }
    my $req = $options{req} || {};
    $req->{'track'.$suffix} = $options{track}->{title};
    $req->{'artist'.$suffix} = $options{track}->{artist};
    foreach my $m (qw(album mbid duration)) {
        my $p = 'has_'.$m;
        if ($options{track}->$p) {
            $req->{$m.$suffix} = $options{track}->$m;
        }
    }
    if (defined $options{timestamp}) {
        $req->{timestamp} = $options{timestamp}->epoch;
    }
    # TODO :  Add other fields.
    return $req;
}

sub now_playing {
    my $self = shift;
    my ( %options ) = validated_hash(
        \@_,
        track   => {
            isa => Track,
            coerce => 1,
        },
    );
    my $req = $self->_set_fields(track => $options{track});

    my ( $response,@more ) = $self->_mas->query(method => 'track.updateNowPlaying', options => $req );
    $self->debug(Dumper($response->data));
    return $response->success;
}


# NOT DONE.  Quit in middle

sub do_scrobble {
    my $self = shift;
    my ( %options ) = validated_hash(
        \@_,
        timestamp => {
            isa => DateTime,
            coerce => 1,
        },
        tracks => {
            isa => Tracks,
            coerce => 1,
        }
    );
    my %req;
    foreach (@{$options{track}}) {
        $self->_set_fields(track => $_, 
        my %req = (
            track => $options{track}->{title},
            artist => $options{track}->{artist}
        );
        foreach my $m (qw(album mbid duration)) {
            my $p = 'has_'.$m;
            if ($options{track}->$p) {
                $req{$m} = $options{track}->$m;
            }
        }
        # TODO :  Add other fields.
        
        
    }


    my ( $response,@more ) = $self->_mas->query(method => 'track.updateNowPlaying', options => \%req );
    $self->debug(Dumper($response->data));
    return $response->success;

}


__PACKAGE__->meta->make_immutable;
1;

