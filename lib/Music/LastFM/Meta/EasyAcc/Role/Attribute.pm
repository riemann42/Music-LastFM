package Music::LastFM::Meta::EasyAcc::Role::Attribute;
use Moose::Role;
before _process_options => sub {
    my ($class, $name,$options) = @_;

    # This is based on MooseX::FollowPBP::Role::Attribute .. loosely.
    if ( ( exists $options->{is} ) && ( $options->{is} ne 'bare' ) ) {
        # Everything gets a predicate
        if ( ! exists $options->{predicate} ) {
            my $has = ( $name =~ m{^_} ) ?  '_has_'
                                          :  'has_';
            $options->{predicate} = $has . $name;
        }
        # Everything gets a reader (SemiAffordable style... 
        #   objects have things, you don't get things!)
        if (( ! exists $options->{reader}  ) || (! $options->{reader})) {
            $options->{reader} = $name;
        }
        # And finally, everything, even ro, get a writer.
        # TODO : create a writer that checks who you are, making it truly private.
        if ( ! exists $options->{writer} ) {
            my $set = (( $name =~ m{^_} ) || ($options->{is} eq 'ro')) ?  '_set_'
                                                                        :  'set_';
            $options->{writer} = $set . $name;
        }
        delete $options->{is};
    }
};

1;

__END__

=head1 NAME

[ModuleName] - [One line description of module's purpose here]

=head1 VERSION

This document describes Music::LastFM version 0.0.3

=head1 SYNOPSIS

    use Music::LastFM;
  
=head1 DESCRIPTION

Support module for Music::LastFM.

=head1 METHODS

=head2 Constructor

=over

=item new

=head2 Attributes

=head2 Methods

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

See L<Music::LastFM>.

=head1 DEPENDENCIES

See L<Music::LastFM>.

=head1 INCOMPATIBILITIES

See L<Music::LastFM>.

=head1 BUGS AND LIMITATIONS

See L<Music::LastFM>.

=head1 AUTHOR

Edward Allen  C<< <ealleniii_at_cpan_dot_org> >>

=head1 LICENSE

Copyright (c) 2011, Edward Allen C<< <ealleniii_at_cpan_dot_org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
