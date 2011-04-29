package Music::LastFM::Meta::EasyAcc::Role::Attribute;
use Moose::Role;
before _process_options => sub {
    my ($class, $name,$options) = @_;

    # This is based on MooseX::FollowPBP::Role::Attribute .. loosely.
    if ( ( exists $options->{is} ) && ( $options->{is} ne 'bare' ) ) {
        # Everything gets a predicate
        if ( ! exists $options->{predicate} ) {
            my $has = ( $name =~ s/^_// ) ?  '_has_'
                                          :  'has_';
            $options->{predicate} = $has . $name;
        }
        # Everything gets a reader (SemiAffordable style... 
        #   objects have things, you don't get things!)
        if ( ! exists $options->{reader}  ) {
            $options->{reader} = $name;
        }
        # And finally, everything, even ro, get a writer.
        # TODO : create a writer that checks who you are, making it truly private.
        if ( ! exists $options->{writer} ) {
            my $set = (( $name =~ s/^_// ) || ($options->{is} eq 'ro')) ?  '_set_'
                                                                        :  'set_';
            $options->{writer} = $set . $name;
        }
        delete $options->{is};
    }
};

1;

