package Music::LastFM::Meta::Attribute::Trait::API;
use Moose::Role;
use Music::LastFM::Types qw(Method);
use MooseX::Types::Moose qw(Str Bool);

has 'apimethod' => (
    isa       => Method,
    coerce    => 1,
    predicate => 'has_apimethod',
    reader    => 'apimethod',
    writer    => 'set_apimethod',
);

has 'identity' => (
    isa       => Str,
    predicate => 'has_identity',
    reader    => 'identity',
    writer    => 'set_identity',
);

has 'api' => (
    isa       => Str,
    predicate => 'has_api',
    reader    => 'api',
    writer    => 'set_api',
);

before _process_options => sub {
    my $class   = shift;
    my $name    = shift;
    my $options = shift;

    if ( $options->{apimethod} ) {
        $options->{default} =
            sub { my $self = shift; 
                  return $self->_api_builder($name) };
        $options->{lazy}   = 1;
    }
};

package Moose::Meta::Attribute::Custom::Trait::LastFM;
sub register_implementation {'Music::LastFM::Meta::Attribute::Trait::API'}



1;

