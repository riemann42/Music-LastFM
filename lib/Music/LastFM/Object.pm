package Music::LastFM::Object;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');
use Moose;
use English qw( -no_match_vars );

use Moose::Util::TypeConstraints;
use Music::LastFM::Types qw(Image HashRef SmArrayRef Str Int Method Bool Event);
use Music::LastFM::Meta::LastFM;
use MooseX::Params::Validate;

has 'name' => (
    is       => 'rw',
    isa      => Str,
    required => 1
);

with 'Music::LastFM::Role::Overload';

has 'agent' => (
    is        => 'rw',
    weak_ref  => 1,
    lazy      => 1,
    predicate => 'has_agent',
    default   => sub { Music::LastFM::Agent->instance }
);

has 'url' => (
    is  => 'rw',
    isa => Str,
);

has 'image' => (
    is     => 'rw',
    isa    => Image,
    coerce => 1,
);

has 'attr' => (
    is     => 'ro',
    isa    => HashRef,
    api    => '@attr',
);

sub check {
    my $self = shift;
    my $ret = 0;
    eval {
        $ret = inner(@_);
    };
    if ($EVAL_ERROR) {
        if (   (Music::LastFM::Exception::APIError->caught($EVAL_ERROR))
            && ($EVAL_ERROR->error_code == 6) ) {
            return 0;
        }
        elsif ( Music::LastFM::Exception->caught($EVAL_ERROR)) {
            $EVAL_ERROR->show_trace(1);
        }
    }
    else { 
        return $ret;
    }
};



sub _api_builder {
    my $self = shift;
    my $attr = shift;
    my $options = shift || {};
    if ( !ref $attr ) {
        $attr = $self->meta->find_attribute_by_name($attr);
    }
    if ( $self->has_agent ) {
        $attr->apimethod->set_agent( $self->agent );
    }
    $attr->apimethod->execute(
        object  => $self,
        options => {%{$options}, %{$self->_find_identity}},
    );
    if ( $attr->has_value($self) ) {
        return $attr->get_value($self);
    }
    return;
}

sub _find_identity {
    my $self     = shift;
    my %identity = ();
    foreach my $attr ( $self->meta->get_all_attributes ) {
        if ( ( $attr->has_value($self) ) && ( $attr->has_identity ) ) {
            my $val = $attr->get_value($self);
            if ( ( ref $val ) && ( $val->can('name') ) ) {
                $val = $val->name;
            }
            $identity{ $attr->identity } = $val;
        }
    }
    return \%identity;
}

sub _validate_input {
    my ( $self, $opts_ref, @opts ) = @_;
    my $options_default = {};

    my (%params) = validated_hash(
        $opts_ref,
        method  => { isa => Method, coerce => 1 },
        options => {
            isa     => HashRef,
            default => $options_default,
        },
        username => { optional => 1 },
        cache_time => { isa => Int,     optional => 1 },
        @opts,
    );
    $params{options} =
        { %{ $params{options} }, %{ $self->_find_identity() } };
    return \%params;
}

sub _api_action {
    my ( $self, @opts ) = @_;
    my $params_ref = $self->_validate_input( \@opts );
    my $resp       = $self->agent->query( %{$params_ref} );
    return $resp->is_success();
}

sub _api_query {
    my ( $self, @opts ) = @_;
    my $params_ref = $self->_validate_input( \@opts,
        response_type                => {  },
        MX_PARAMS_VALIDATE_CACHE_KEY => '_query_api'
    );
    my $type = find_type_constraint($params_ref->{response_type});
    delete $params_ref->{response_type};
    my $resp       = $self->agent->query( %{$params_ref} );
    if ($resp->is_success()) {
        return $type->coerce($resp->data);
    }
    return undef;
}
sub _add_tags {
    my ( $self, @opts ) = @_;
    my $params_ref = $self->_validate_input(
        \@opts,
        tags => { isa => SmArrayRef },
        MX_PARAMS_VALIDATE_CACHE_KEY => '_add_tags'  # Ugly, but needed.
    );
    $params_ref->{options}->{tags} = join( ",", @{ $params_ref->{tags} } );
    delete $params_ref->{tags};
    $self->_api_action( %{$params_ref} );
}

sub _remove_tag {
        my ( $self, @opts ) = @_;
        my $params_ref = $self->_validate_input(
            \@opts,
            tag                          => { isa => Str },
            MX_PARAMS_VALIDATE_CACHE_KEY => '_remove_tag'
        );
        $params_ref->{options}->{tag} = $params_ref->{tag};
        delete $params_ref->{tag};
        $self->_api_action( %{$params_ref} );
}

sub _shout {
        my ( $self, @opts ) = @_;
        my $params = $self->_validate_input( \@opts,
            message                      => { isa => Str },
            MX_PARAMS_VALIDATE_CACHE_KEY => '_shout' );
        $params->{options}->{message} = $params->{message};
        delete $params->{message};
        return $self->_api_action( %{$params} );
}

sub _share {
        my ( $self, @opts ) = @_;
        my $params = $self->_validate_input( \@opts,
            public                       => { isa => Bool, optional => 1 },
            message                      => { isa => Str,  optional => 1 },
            recipient                    => { isa => SmArrayRef },
            MX_PARAMS_VALIDATE_CACHE_KEY => '_share'
        );
        $params->{options}->{message} = $params->{message};
        delete $params->{message};
        return $self->_api_action( %{$params} );
}


__PACKAGE__->meta->make_immutable();
no Moose;
1;

__END__

=head1 NAME

Music::LastFM::Object - Base Class for Data Objects.

=head1 VERSION

This document describes Music::LastFM version 0.0.3

=head1 SYNOPSIS

    use Music::LastFM;

    my $lfm = Music::LastFM->new();

    my $artist = $lfm->new_artist(name => 'Irradiated Chicken');
  
=head1 DESCRIPTION

Support module for Music::LastFM.  This is the base class for objects created
by Music::LastFM::Response.  You should never need to create one of these.
Usually the subclasses of this would be created using a L<Music::LastFM>
object.


=head1 MOOSE Meta Class Extentions

This class is extended with Music::LastFM::Meta::LastFM.  This adds several
attributes to the attribute class:  

=over

=item apimethod  (String)

This is the name of an apimethod capable of suppling a value for the
attribute.  Please note that this method will set any values that it is
capable of setting, not just the attribute called.

=item api  (String)

The name of the field in the response that sets a value for this attribute.

=item identity (String)

If set, the value is passed in an option automatically for api calls.

=head1 METHODS

=head2 Constructor

=over

=item new( name => $name )

Create a new object.  Any attributes can be set when creating object.

=back

=head2 Attributes

=over

=item agent set_agent has_agent 

A Music::LastFM::Agent object.  Defaults to Music::LastFM::Agent singleton.

=item attr has_attr 

The stuff in the attr block of the response.

=item image set_image has_image 

A hashref describing the image associated with this object.  Hashref is of the
form:

{  size  => url }

Size is generated by LastFM, but is usually one of (small, medium, large,
extralarge, mega).

=item name set_name has_name

Required attribute.  Name of the object.

=item url set_url has_url 

URL at LastFM for object.

=back

=head2 Methods

=over

=item check

Extremley usefull.  Makes sure the object exists on LastFM's servers.  

If you access an unset attribute, M:LF may try to query LastFM's servers to
get the answer.  If they return an error, because, say, there is no band named
Irradiated Chicken, then your program will croak.

Check is wrapped in an eval internally.  If it's croaks, it is a bug.

=item stringify

Used to convert object to a string.  Defaults to returning the name attribute.

=back

=head2 Internal Methods

These methods are used by subclasses.

=over

=item  _api_query ( response_type => $type, Music::LastFM::Agent Query Options )

Performs a query and coerces response to indicated Moose type.  Automatically
adds identity elements (usually name) to query.  Any remaining options are
also added to the query options parameter.  For example, M:L:O:U performs:

    sub top_artists {
        shift->_api_query( method => 'user.getTopArtists',
                        response_type => Artists,
                        @_);
    }

And a user will call it with

    my $top_500 = $me->top_artists( limit => 500);

=item _api_action( Music::LastFM::Agent Query Options )

Performs a query.  Automatically adds identity attributes to options paramter.

The following are extensions of this method:

=item _add_tags(method => 'artist.addTags',  tags => [qw(Happy Rockin)]  )

=item _remove_tag(method => 'artist.removeTag', tag => 'Sad')

=item _shout(method => 'artist.shout', message => 'They make me cry.')

=item _share(method => 'artist.share', message => 'This will make your day', public => 0,  recipient => 'Moody');

=back

=head1 DIAGNOSTICS

See L<Music::LastFM>.

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


