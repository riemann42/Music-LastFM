package Music::LastFM::Config;
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use MooseX::Singleton;
use Music::LastFM::Meta::EasyAcc;
use Music::LastFM::Types qw(HashRef Bool Str);
use Config::Std;


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


1;
