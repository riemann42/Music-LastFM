package Music::LastFM::Meta::LastFM;
use Moose;
use Moose::Exporter;

our $VERSION = '0.03';


Moose::Exporter->setup_import_methods(
    class_metaroles => {
        attribute => [
            'Music::LastFM::Meta::LastFM::Role::Attribute',
            'Music::LastFM::Meta::EasyAcc::Role::Attribute',
        ],
        class => ['Music::LastFM::Meta::LastFM::Role::Class'],
        
    },
    role_metaroles => {
        applied_attribute => [
            'Music::LastFM::Meta::LastFM::Role::Attribute',
            'Music::LastFM::Meta::EasyAcc::Role::Attribute',
        ],
    },
    base_class_roles => ['Music::LastFM::Meta::LastFM::Role::Object']
);
