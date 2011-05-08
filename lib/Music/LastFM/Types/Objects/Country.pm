package Music::LastFM::Types::Objects::Country;

# This is taken in whole from MORIYA Masaki (守屋 雅樹)'s example for
# MooseX::Types::Locale::Country.  Please see this module for more information!

use Moose;
use MooseX::Aliases;
use MooseX::Types::Locale::Country qw(
    Alpha2Country
    Alpha3Country
    NumericCountry
    CountryName
);

use Data::Util qw(:check);
use Locale::Country;

use namespace::clean -except => 'meta';

use overload '""' => 'stringify';

has 'alpha2' => (
    traits => [
        qw(
            Aliased
            )
    ],
    is         => 'rw',
    isa        => Alpha2Country,
    init_arg   => '_alpha2',
    alias      => 'code',
    coerce     => 1,
    lazy_build => 1,
    writer     => '_set_alpha2',
    trigger    => sub {
        $_[0]->clear_alpha3;
        $_[0]->clear_numeric;
        $_[0]->clear_name;
    },
);

has 'alpha3' => (
    is         => 'rw',
    isa        => Alpha3Country,
    init_arg   => '_alpha3',
    coerce     => 1,
    lazy_build => 1,
    writer     => '_set_alpha3',
    trigger    => sub {
        $_[0]->clear_alpha2;
        $_[0]->clear_numeric;
        $_[0]->clear_name;
    },
);

has 'numeric' => (
    is         => 'rw',
    isa        => NumericCountry,
    init_arg   => '_numeric',
    coerce     => 0,                # you cannot coerce numeric
    lazy_build => 1,
    writer     => '_set_numeric',
    trigger    => sub {
        $_[0]->clear_alpha2;
        $_[0]->clear_alpha3;
        $_[0]->clear_name;
    },
);

has 'name' => (
    is         => 'rw',
    isa        => CountryName,
    init_arg   => '_name',
    coerce     => 1,
    lazy_build => 1,
    writer     => '_set_name',
    trigger    => sub {
        $_[0]->clear_alpha2;
        $_[0]->clear_alpha3;
        $_[0]->clear_numeric;
    },
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    if ( @_ == 1 && !ref $_[0] ) {

        if ( is_integer( $_[0] ) ) {
            return $class->$orig( _numeric => $_[0] );
        }
        else {
            my $length = length $_[0];
            return $class->$orig(
                (     $length == 2 ? '_alpha2'
                    : $length == 3 ? '_alpha3'
                    : '_name'
                ) => $_[0]
            );
        }
    }
    else {
        return $class->$orig(@_);
    }
};

sub _build_alpha2 {
    $_[0]->has_alpha3
        ? country_code2code( $_[0]->alpha3, LOCALE_CODE_ALPHA_3,
        LOCALE_CODE_ALPHA_2 )
        : $_[0]->has_numeric
        ? country_code2code( $_[0]->numeric, LOCALE_CODE_NUMERIC,
        LOCALE_CODE_ALPHA_2 )
        : country2code( $_[0]->name, LOCALE_CODE_ALPHA_2 );
}

sub _build_alpha3 {
    $_[0]->has_alpha2
        ? country_code2code( $_[0]->alpha2, LOCALE_CODE_ALPHA_2,
        LOCALE_CODE_ALPHA_3 )
        : $_[0]->has_numeric
        ? country_code2code( $_[0]->numeric, LOCALE_CODE_NUMERIC,
        LOCALE_CODE_ALPHA_3 )
        : country2code( $_[0]->name, LOCALE_CODE_ALPHA_3 );
}

sub _build_numeric {
    $_[0]->has_alpha2
        ? country_code2code( $_[0]->alpha2, LOCALE_CODE_ALPHA_2,
        LOCALE_CODE_NUMERIC )
        : $_[0]->has_alpha3
        ? country_code2code( $_[0]->alpha3, LOCALE_CODE_ALPHA_3,
        LOCALE_CODE_NUMERIC )
        : country2code( $_[0]->name, LOCALE_CODE_NUMERIC );
}

sub _build_name {
    $_[0]->has_alpha2 ? code2country( $_[0]->alpha2, LOCALE_CODE_ALPHA_2 )
        : $_[0]->has_alpha3
        ? code2country( $_[0]->alpha3,  LOCALE_CODE_ALPHA_3 )
        : code2country( $_[0]->numeric, LOCALE_CODE_NUMERIC );
}

sub set {
    my ( $self, $argument ) = @_;

    confess('Cannot set country because: argument is not defined')
        unless defined $argument;
    confess('Cannot set country because: argument is not string')
        unless is_string($argument);

    if ( is_integer($argument) ) {
        $self->_set_numeric($argument);
    }
    else {
        my $length = length $argument;
              $length == 2 ? $self->_set_alpha2($argument)
            : $length == 3 ? $self->_set_alpha3($argument)
            :                $self->_set_name($argument);
    }

    return $self;
}

alias has_code    => 'has_alpha2';
alias clear_code  => 'clear_alpha2';
alias _build_code => '_build_alpha2';
alias _set_code   => '_set_alpha2';

sub stringify {
    my $self = shift;
    return $self->name;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Music::LastFM::Types::Object::Country - [One line description of module's purpose here]

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
