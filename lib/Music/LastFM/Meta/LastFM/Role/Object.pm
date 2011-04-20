package Music::LastFM::Meta::LastFM::Role::Object;
use Moose::Role;

sub _api_builder {
    my $self = shift;
    my $attr = shift;
    unless (ref $attr) {
        $attr = $self->meta->find_attribute_by_name($attr);
    }
    $attr->apimethod->execute(object => $self, options => $self->_find_identity);
    if ($attr->has_value($self)) {
        return $attr->get_value($self);
    }
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

1;
