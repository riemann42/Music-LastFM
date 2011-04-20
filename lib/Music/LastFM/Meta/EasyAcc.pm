package Music::LastFM::Meta::EasyAcc;
use Moose;
use Moose::Exporter;

our $VERSION = '0.03';

Moose::Exporter->setup_import_methods(
    class_metaroles => {
        attribute => [ 'Music::LastFM::Meta::EasyAcc::Role::Attribute'],

    },
    role_metaroles => {
        applied_attribute => [ 'Music::LastFM::Meta::EasyAcc::Role::Attribute'],
    },
);
