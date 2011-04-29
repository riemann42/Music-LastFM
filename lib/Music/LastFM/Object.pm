package Music::LastFM::Object;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');
use Moose;

use Music::LastFM::Types qw(Image HashRef ArrayRef Str Int);
use Music::LastFM::Meta::LastFM;

has 'name' => ( is => 'rw', isa => Str, required => 1);
with 'Music::LastFM::Role::Overload';

has 'agent' => (
    is        => 'rw',
    weak_ref  => 1,
    lazy      => 1,
    predicate => 'has_agent',
    default   => sub { Music::LastFM::Agent->instance }
);

sub _api_builder {
    my $self = shift;
    my $attr = shift;
    if (! ref $attr) {
        $attr = $self->meta->find_attribute_by_name($attr);
    }
    if ($self->has_agent) {
        $attr->apimethod->set_agent($self->agent);
    }
    $attr->apimethod->execute(
        object => $self, 
        options => $self->_find_identity,);
    if ($attr->has_value($self)) {
        return $attr->get_value($self);
    }
    return;
}

sub _find_identity {
    my $self = shift;
    my %identity = ();
    foreach my $attr ($self->meta->get_all_attributes) {
        if (($attr->has_value($self)) && ($attr->has_identity)) {
            my $val =  $attr->get_value($self);
            if ((ref $val) && ($val->can('name'))) {
                $val = $val->name;
            }
            $identity{$attr->identity} = $val;
        }
    }
    return \%identity;
}

__PACKAGE__->meta->make_immutable();
no Moose;
1;

