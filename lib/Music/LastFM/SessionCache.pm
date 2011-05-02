package Music::LastFM::SessionCache;

use Moose;
use Music::LastFM::Types qw(Str Options);
with 'Music::LastFM::Role::Logger';

has config => (
    isa     => 'Music::LastFM::Config',
    is      => 'ro',
    lazy    => 1,
    default => sub {
        Music::LastFM::Config->instance();
    }
);

sub set {
    my ($self,$k,$v) = @_;
    $self->config->set_option($k => $v, 'sessions');
}

sub get{
    my ($self,$k) = @_;
    $self->config->get_option($k, 'sessions');
}

sub has_value {
    my ($self,$k) = @_;
    $self->config->has_option($k, 'sessions');
}

no Moose;
1;
