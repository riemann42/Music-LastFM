package Music::LastFM::Types;
use base 'MooseX::Types::Combine';
__PACKAGE__->provide_types_from(qw/
    MooseX::Types::Moose
    MooseX::Types::UUID
    MooseX::Types::URI
    MooseX::Types::LWP::UserAgent
    Music::LastFM::Types::LastFM
    Music::LastFM::Types::Method
    Music::LastFM::Types::Country
/);
    
1;


