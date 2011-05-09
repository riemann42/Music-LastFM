package Music::LastFM::Response;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');
use 5.008_000;  # I don't even want to try making 5.6 work right now.
use Moose;
use Music::LastFM::Types qw(Options Method Methods Metas Meta);
use MooseX::Types::Moose qw(Bool Str Int HashRef);
use Moose::Util::TypeConstraints;
use Module::Load;
use JSON;
use Readonly;
use namespace::autoclean;


use Music::LastFM::Meta::EasyAcc;
with 'Music::LastFM::Role::Logger';

# keep my privates private.
{
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    Readonly my $ATTR_KEY => q{@attr};
    ## use critic

    has method        => ( is => 'ro', isa => Method, required => 1, );
    has json          => ( is => 'ro', isa => Str,);
    has is_success    => ( is => 'ro', isa => Bool,);
    has error_message => ( is => 'ro', isa => Str,);
    has error         => ( is => 'ro', isa => Int,);
    has can_retry     => ( is => 'ro', isa => Bool,);
    has attr_response => ( is => 'ro', isa => HashRef,);
    has agent         => ( is => 'ro',
        weak_ref  => 1,
        lazy      => 1,
        predicate => 'has_agent',
        default   => sub { Music::LastFM::Agent->instance },
    );
    has object        => ( is => 'ro', isa => 'Music::LastFM::Object',
        predicate => 'has_object',
        clearer   => 'clear_object',
    );
    has data        => (is => 'ro');

    # TODO : Clean up this hack!!!
    my %available_objects = (
        'album'  => 'Music::LastFM::Object::Album',
        'artist' => 'Music::LastFM::Object::Artist',
        'tag'    => 'Music::LastFM::Object::Tag',
        'track'  => 'Music::LastFM::Object::Track',
        'user'   => 'Music::LastFM::Object::User',
        'event'  => 'Music::LastFM::Object::Event',
        'venue'  => 'Music::LastFM::Object::Venue',
    );


    has expect => (
        is      => 'rw',
        isa     => Metas,
        coerce  => 1,
        lazy    => 1,
        default => sub { 
            # Blah.  This seems wrong.
            for (values %available_objects) { load $_ }
            return \%available_objects 
        },
    );

    sub BUILD {
        my $self = shift;
        $self->_set_data($self->_data); 
    }

    sub _data {
        my $self = shift;
        my $data = decode_json( $self->json );
        if ( exists $data->{error} ) {
            $self->_set_is_success(0);
            $self->_set_error( $data->{error} );
            $self->_set_error_message( $data->{message} );
            $self->die( $self->error_message,
                        'Music::LastFM::Exception::APIError',
                        error_code => $data->{error},
                        response_object => $self,
                        );
            return;
        }
        elsif ($data) {
            $self->_set_is_success(1);
            my $return_value = $self->_parse($data);
            if ($self->has_object) {
                # TODO Add sanity check from attr_response here!
                $self->_merge_data($self->object,$return_value);
                $self->clear_object;   # Clearing object so we don't repeat this.
            }
            return $self->method->ignore_top 
                ? $return_value->{ ( keys %{$return_value} )[0] }
                : $return_value;
        }
        return;
    }

    sub _make_array_of_objects {
        my ($self,$node_key,$node_value) = @_;
        return [ map {
            ref($_) eq 'HASH' ? $self->_make_object($node_key => $_, 0)
                              : $_
                     } @{$node_value}
               ];
    }

    sub _parse_array {
        my ($self,$node_value) = @_;
        return [ map {
            ref($_) eq 'HASH' ? $self->_parse($_)
                              : $_
                     } @{$node_value}
               ];
    }

    sub _isita {
        my $object = shift;
        my $meta   = shift;

        # TODO:  Look for a way to avoid calling $meta->{package}
        my $type = Moose::Util::TypeConstraints::create_class_type_constraint(
            $meta->{package} );
        return $type->check($object);
    }


    sub _make_object {
        my ($self,$key,$data,$useobj) = @_;

        my $meta = $self->expect->{$key};

        if ((! $data->{name}) && ($data->{$key})) {
            $data->{name} = $data->{$key};
        }

        if ((! $data->{name}) && ($data->{id})) {
            $data->{name} = $data->{id};
        }

        if (! $data->{name} ) {
            $self->die( 'Name argument missing',
                        'Music::LastFM::Exception::ParseError',
                        response_object => $self,
                        );
            return;
        }

        my $object;
        if ( ($useobj) &&  ( $self->has_object ) && ( _isita( $self->object, $meta ) ) ) {
            $object = $self->object;
            $self->clear_object;
        }
        else {
            $object =
                $meta->new_object( name => $data->{name}, agent => $self->agent );
        }
        return $self->_merge_data($object,$data);
    }


    sub _merge_data {
        my $self= shift;
        my $object = shift;
        my $data = shift;
        my $meta = $object->meta;
        for my $attr ( $meta->get_all_attributes ) {
            my $m = $attr->has_api ? $attr->api : $attr->name;
            if ( $data->{$m} ) { $attr->set_value( $object, $data->{$m} ); }
        }
        return $object;
    }

    sub _parse {
        my $self = shift;
        my $data_ref = shift;
        my $return_value  = {};
        if ( $data_ref->{$ATTR_KEY} ) {
            $self->_set_attr_response($data_ref->{$ATTR_KEY});
        }
        while ( my ( $node_key, $node_value ) = each %{$data_ref} ) {
            next if ( $node_key eq $ATTR_KEY );      # we already took care of this.
            my ($is_hash,$is_array,$is_expected) =   # improve readability of ternary below
                (ref $node_value eq 'HASH',
                 ref $node_value eq 'ARRAY',
                 exists $self->expect->{$node_key},);

            $return_value->{$node_key} =
                # Test  Value
                  $node_key eq 'nowplaying'   ?       # quick hack, TODO fix
                        $node_value
                : $is_array && $is_expected  ?
                        $self->_make_array_of_objects($node_key,$node_value)
                : $is_array                  ?
                        $self->_parse_array($node_value)
                : $is_hash  && $is_expected  ?
                        $self->_make_object($node_key, $node_value,1)
                : $is_hash                   ?
                        $self->_parse($node_value)
                :       $node_value;
        }
        return $return_value;
    }
}

#__PACKAGE__->meta->make_immutable();
1;

__END__

=head1 NAME

Music::LastFM::Response - [One line description of module's purpose here]

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

=item agent has_agent 

Default: Generated Automatically



=item attr_response has_attr_response 



=item can_retry has_can_retry 



=item data has_data 



=item error has_error 



=item error_message has_error_message 



=item expect set_expect has_expect 

Default: Generated Automatically



=item is_success has_is_success 



=item json has_json 



=item logger info critical debug warning 



=item method has_method REQUIRED



=item object has_object clear_object 



=head2 Methods

=item BUILD

=item die

=item meta

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


