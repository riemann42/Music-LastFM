package Music::LastFM::Response;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.3');
use Moose;
use Music::LastFM::Types qw(Options Method Methods Metas Meta);
use MooseX::Types::Moose qw(Bool Str Int HashRef);
use Moose::Util::TypeConstraints;
use JSON;

use Music::LastFM::Meta::LastFM;

has method => ( is => 'rw', isa => Method, required => 1 );
has json => ( is => 'rw', isa => Str );
has success       => ( is => 'rw', isa      => Bool );
has error_message => ( is => 'rw', isa      => Str );
has error         => ( is => 'rw', isa      => Int );
has retry         => ( is => 'rw', isa      => Bool );
has attr          =>  ( is => 'rw', isa   => HashRef);
has 'agent'        => (
    is        => 'rw',
    weak_ref  => 1,
    lazy      => 1,
    predicate => 'has_agent',
    default   => sub { Music::LastFM::Agent->instance }
);


use Music::LastFM::Object::Artist;
use Music::LastFM::Object::Tag;
use Music::LastFM::Object::Album;
use Music::LastFM::Object::Track;
use Music::LastFM::Object::User;
use Music::LastFM::Object::Event;
use Music::LastFM::Object::Venue;

has expect => (
    is      => 'rw',
    isa     => Metas,
    coerce  => 1,
    lazy    => 1,
    default => sub {
        {   'album'  => 'Music::LastFM::Object::Album',
            'artist' => 'Music::LastFM::Object::Artist',
            'tag'    => 'Music::LastFM::Object::Tag',
            'track'  => 'Music::LastFM::Object::Track',
            'user'   => 'Music::LastFM::Object::User',
            'event'  => 'Music::LastFM::Object::Event',
            'venue'  => 'Music::LastFM::Object::Venue',
        };
    }
);

has object =>
    ( is => 'rw', predicate => 'has_object', clearer => 'clear_object' );

sub _data {
    my $self = shift;
    return decode_json( $self->json );
}

sub data {
    my $self = shift;
    my $data = $self->_data;
    if ( exists $data->{error} ) {
        $self->success(0);
        $self->error( $data->{error} );
        $self->error_message( $data->{message} );
        Carp::cluck( "Received error: " . $self->error_message );
        return;
    }
    else {
        my $ret = $self->_parse($data);
        if ($self->has_object) {
            # TODO Add sanity check from attr here!
            $self->_merge_data($self->object,$ret);
            $self->clear_object;
        }
        if ( $self->method->ignoretop ) {
            return $ret->{ ( keys %{$ret} )[0] };
        }
        else {
            return $ret;
        }
    }
}

sub _parse {
    my $self = shift;
    my $data = shift;
    my $ret  = {};
    if ( $data->{'@attr'} ) {
        $self->set_attr($data->{'@attr'});
    }
    while ( my ( $k, $v ) = each %{$data} ) {
        if ( $k eq '@attr' ) {
            next;
        }
        elsif ( exists $self->expect->{$k} ) {
            if ( ref $v eq 'ARRAY' ) {
                my @nv = ();
                foreach my $sv ( @{$v} ) {
                    if ( ref($sv) eq 'HASH' ) {
                        push @nv,
                            $self->_make_object( $k, $sv,0 );
                    }
                    else {
                        push @nv, $sv;
                    }
                }
                $v = \@nv;
            }
            else {
                $v = $self->_make_object( $k, $v,1 );
            }
        }
        elsif ( ref($v) eq 'HASH' ) {
            $v = $self->_parse($v);
        }
        elsif ( ref($v) eq 'ARRAY' ) {
            my @nv = ();
            foreach my $sv ( @{$v} ) {
                if ( ref($sv) eq 'HASH' ) {
                    push @nv, $self->_parse($sv);
                }
                else {
                    push @nv, $sv;
                }
            }
            $v = \@nv;
        }
        $ret->{$k} = $v;
    }
    return $ret;
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
    my $self = shift;
    my $key = shift;
    my $data = shift;
    my $useobj = shift;
    my $meta = $self->expect->{$key};
    if ((! $data->{name}) && ($data->{$key})) { 
        $data->{name} = $data->{$key};
    }
    unless ( $data->{name} ) {
        Carp::cluck "No name key in hash passed to _make_object";
        return undef;
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
    foreach my $attr ( $meta->get_all_attributes ) {
        my $m = $attr->has_api ? $attr->api : $attr->name;
        if ( $data->{$m} ) { $attr->set_value( $object, $data->{$m} ); }
    }
    return $object;
}

1;

