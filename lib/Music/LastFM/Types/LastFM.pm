package Music::LastFM::Types::LastFM;
use warnings;
use strict;
use Carp;

use MooseX::Types -declare => [
    qw( Options Method Methods Meta Metas Image ArtistStats Wiki
        Artist Artists Tag Tags User Users Event Events Album Albums 
        Venue Venues Track Tracks Gender Logger Cache)
];

use MooseX::Types::Moose qw(HashRef ArrayRef Str Int);
use MooseX::Types::Structured qw(Dict Tuple);

### Config::Options Hash
use Config::Options;
class_type Options, { class => 'Config::Options' };
coerce Options, from HashRef, via {
    my $opt = Config::Options->new($_);
    if ( $opt->options('optionfile') ) {
        $opt->fromfile_perl();
    }
    return $opt;
};

### Type Coercions for each of the Object types
for my $attr (qw(Artist Album User Tag Event Venue Track)) {
    my $type = __PACKAGE__.'::'. $attr;
    my $class = 'Music::LastFM::Object::'.$attr;
    my $atype = __PACKAGE__.'::'.$attr.'s';
    my $api = lc($attr);

    class_type $type, { class => $class };
    coerce $type, from Str, via {
        $class->new( name => $_ );
    };
    subtype $atype, as ArrayRef [$type];
    coerce $atype, from ArrayRef, via {
        [ map { $class->new( %{$_} ) } @{$_} ];
    };
    coerce $atype, from Dict [ $api => ArrayRef ], via {
        my $h = $_->{$api};
        return [ map { $class->new( %{$_} ) } @{$h} ];
    };

}

### Image Structure
subtype Image, as HashRef [Str];
coerce Image, from ArrayRef [ Dict [ '#text' => Str, size => Str ] ], via {
    my $h = $_;
    return { map { $_->{'size'} => $_->{'#text'} } @{$h} };
};

### ArtistStats Structure
subtype ArtistStats, as Dict [ 'listeners' => Int, 'playcount' => Int ];

### Wiki Structure
subtype Wiki,
    as Dict [ 'published' => Str, 'summary' => Str, 'content' => Str ];

### Moose::Meta::Class objects
class_type Meta, { class => 'Moose::Meta::Class' };
coerce Meta, from Str, via { Class::MOP::Class->initialize($_) };
subtype Metas, as HashRef [Meta];
coerce Metas, from HashRef, via {
    my $h = $_;
    return {
        map { $_ => Class::MOP::Class->initialize( $h->{$_} ) }
            keys %{$h}
    };
};

### Gender object
subtype Gender, as Str, where {m/[mf]/};
coerce Gender, from Str, via { lc( substr( $_, 0, 1 ) ) };


### Goose
duck_type Logger, [ qw(debug info warning critical) ];
duck_type Cache, [qw(get set)]; 






1;
