package Music::LastFM::Meta::LastFM::Role::Class;
use Moose::Role;

around add_attribute => sub {
    my $orig = shift;
    my $self = shift;
    my $attr = $self->$orig(@_);
    if ( ($attr) && ( $attr->has_apimethod ) ) {
        $self->add_method(
            $attr->name,
            sub {
                my $self = shift;
                if ( !$attr->has_value($self) ) {
                    $self->_api_builder($attr);
                }
                return $attr->get_value($self);
            }
        );
    }
    return $attr;
};

1;
