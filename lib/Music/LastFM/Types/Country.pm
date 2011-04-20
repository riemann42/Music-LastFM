package Music::LastFM::Types::Country;
use warnings;
use strict;
use Carp;

use MooseX::Types -declare => [ qw( Country )];
use MooseX::Types::Moose qw(Str );
use Music::LastFM::Types::Objects::Country;

### Country object.
class_type Country, { class => 'Music::LastFM::Types::Objects::Country' };
coerce Country,
    from Str,
    via { Music::LastFM::Types::Objects::Country->new($_) };

1;

