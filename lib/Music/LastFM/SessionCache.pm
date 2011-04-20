package Music::LastFM::SessionCache;

use Moose;
use MooseX::Types::Moose qw(Str);

has filename => (
    isa=> Str,
    is => 'ro',
    required => 1
);

has '_sessioncache' => (
    reader => '_sessioncache',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $s =  Config::Options->new( { optionfile => $self->filename } );
        $s->fromfile_perl();
        unless ( $s->{sessions} ) {$s->{sessions}->{sessions} = {}; }
        return $s;
    }
);

sub set {
    my $self = shift;
    my ($k,$v) = @_;
    $self->_sessioncache->{sessions}->{$k} = $v;
    $self->_sessioncache->tofile_perl();
}

sub get{
    my $self = shift;
    my ($k) = @_;
    return $self->_sessioncache->{sessions}->{$k}
}

sub has_value {
    my $self = shift;
    my ($k) = @_;
    return ((exists $self->_sessioncache->{sessions}->{$k}) &&  (defined $self->_sessioncache->{sessions}->{$k}));
}

no Moose;
1;
