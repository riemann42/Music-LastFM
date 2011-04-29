package Music::LastFM::Method;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');
use Moose;
use Music::LastFM::Meta::EasyAcc;
use MooseX::Types::Moose qw(Str Bool ArrayRef HashRef);
use Music::LastFM::Types::LastFM qw(Metas);

has 'name' => ( is => 'rw', isa => Str, required => 1 );

has 'sign_required' =>
    ( is => 'rw', isa => Bool, lazy => 1, builder => '_build_sign', );

sub _build_sign { my $self = shift; return $self->auth_required; }

has 'auth_required' => ( is => 'ro', isa => Bool, default => 0, );
has 'method'       => ( is => 'ro', isa => Str,  default => 'GET', );
has 'expect'       => ( is => 'ro', isa => Metas, );
has 'ignore_top'    => ( is => 'ro', isa => Bool, default => 1, );
has 'agent'        => (
    is        => 'rw',
    weak_ref  => 1,
    lazy      => 1,
    predicate => 'has_agent',
    default   => sub { Music::LastFM::Agent->instance }
);
has 'options' => ( is => 'ro', isa => HashRef, default => sub { {} } );

sub execute {
    my $self    = shift;
    my %options = @_;
    my $resp    = $self->agent->query(
        method  => $self,
        options => $self->options,
        %options
    );
    $resp->data();
}

__PACKAGE__->meta->make_immutable;
1;
