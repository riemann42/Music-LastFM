package Music::LastFM::Config;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use MooseX::Singleton;
use Music::LastFM::Meta::EasyAcc;
use Music::LastFM::Types qw(HashRef Bool Str);
use Config::Std;

use namespace::autoclean;


has _option_ref => (
    is        => 'ro',
    reader    => '_option_ref',
#    isa       => HashRef,
    default   => sub{{}},
);

has _loaded => (
    is        => 'ro',
    reader    => '_loaded',
    isa       => Bool,
    default   => 0,
);

has filename => (
    is        => 'ro',
    required  => 1,
    isa       => Str,
    predicate => '_has_filename',
);


sub _load_config {
    my $self = shift;
    if (! $self->_loaded()) {
        my %config = (
           '' => {
                api_key => q{},
                api_secret => q{},
            },
            sessions => {},
        );
        if ( -e $self->filename ) {
            read_config $self->filename => %config;
        }
        $self->_set__option_ref(\%config);
        $self->_set__loaded(1);
    }
    return;
}

sub _write_config {
    my $self = shift;
    $self->_load_config();
    my $config_ref = $self->_option_ref; 
    write_config ($config_ref => $self->filename);
    return;
}

sub set_option {
    my $self = shift;
    my $option = shift;
    my $value = shift;
    my $category = shift || q{};
    $self->_load_config();
    unless ( exists $self->_option_ref->{$category}) {
        $self->_option_ref->{$category} = {};
    }
    $self->_option_ref->{$category}->{$option} = $value;
    $self->_write_config();
    return;
}

sub get_option {
    my $self = shift;
    my $option = shift;
    my $category = shift || q{};
    $self->_load_config();
    my $config_ref=$self->_option_ref;
    unless ( exists $config_ref->{$category}) {
        Music::LastFM::Exception->throw("Attempt to get option from non-existant section: $category");
    }
    return $self->_option_ref->{$category}->{$option};
}

sub has_option {
    my $self = shift;
    my $option = shift;
    my $category = shift || q{};
    $self->_load_config();
    my $config_ref=$self->_option_ref;
    unless ( exists $config_ref->{$category}) {
        Music::LastFM::Exception->throw("Attempt to get option from non-existant section: $category");
    }
    return exists $self->_option_ref->{$category}->{$option};
}


__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Music::LastFM::Config - Basic wrapper for Config::Std.

=head1 VERSION

This document describes Music::LastFM version 0.0.3

=head1 SYNOPSIS

See L<Music::LastFM>
  
=head1 DESCRIPTION

Support module for L<Music::LastFM>.  This provides the methods required for a
config object.  If you wish to create your own config package, just make sure
it has the methods listed below and use it when creating a L<Music::LastFM>
object.

=head1 METHODS

=head2 Constructor

=over

=item new( filename => $file )

Create a new object.  Filename is required.

=back

=head2 Attributes

=over

=item filename

The filename of the configuration file. This attribute is required when
creating a new object, and can't be changed after the fact. 

=back

=head2 Methods

=over

=item get_option($option, $category)

Get an option from config file.  $category is optional, if unset will get it
from the opening section.

This will die if $category does not exist.

=item has_option($option, $category)

Determine if an $option is set in a config file.  $category is optional, if 
unset will get it from the opening section.

This will die if $category does not exist.

=item set_option($option, $value, $category)

Set an option.  Like other methods, $category is optional.

This will not create a category, but will die if it does not exist.

=back

=head1 DIAGNOSTICS

=over

=item Attempt to get option from non-existant section: category

This error is returned if you tried to use a bad category.

=back

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


