package Music::LastFM::Meta::EasyAcc::Role::Attribute;
use Moose::Role;
before _process_options => sub {
    my $class   = shift;
    my $name    = shift;
    my $options = shift;

    # This is based on MooseX::FollowPBP::Role::Attribute
   if ( ( exists $options->{is} ) && ( $options->{is} ne 'bare' ) ) {
        if ( !exists $options->{predicate} ) {
            my $has;
            if ( $name =~ s/^_// ) {
                $has = '_has_';
            }
            else {
                $has = 'has_';
            }
            $options->{predicate} = $has . $name;
        }
        if ( !( exists $options->{reader} ) ) {
            $options->{reader} = $name;
        }
        if ( !exists $options->{writer} ) {
            my $set;
            if ( $name =~ s/^_// ) {
                $set = '_set_';
            }
            else {
                $set = 'set_';
            }
            if ( $options->{is} eq 'rw' ) {
                $options->{writer} = $set . $name;
            }
        }
        delete $options->{is};
    }
};

1;

