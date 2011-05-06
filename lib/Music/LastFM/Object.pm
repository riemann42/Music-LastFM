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


sub query_attribute {
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

sub _api_builder {
    goto &query_attribute;
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

