package Music::LastFM::Types::LastFM;
use Carp;

use Moose::Util::TypeConstraints;
use MooseX::Types -declare => [
    qw( Method      Methods     Meta        Metas
        Image       ArtistStats Wiki        Artist      Artists
        Tag         Tags        User        Users       Event
        Events      Album       Albums      Venue       Venues
        Track       Tracks      Gender      Logger      Cache
        SmArrayRef  Shout       Shouts      FullImage   Images
        DateTime    CurrentPlay UserAgent

        )
];
use MooseX::Types::Moose qw(HashRef ArrayRef Str Int Num);
use MooseX::Types::DateTimeX;
use MooseX::Types::Structured qw(Dict Tuple);

### Type Coercions for each of the Object types
for my $attr (qw(Artist Album User Tag Event Venue Track)) {
    my $type  = __PACKAGE__ . '::' . $attr;
    my $class = 'Music::LastFM::Object::' . $attr;
    my $atype = __PACKAGE__ . '::' . $attr . 's';
    my $api   = lc($attr);

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
    coerce $atype, from HashRef, via {
        if (exists $_->{$api}) {
            return [ $_->{$api} ];
        }
        else {
            return [];
        }
    };
}

### Image Structure
subtype Image, as HashRef [Str];
coerce Image, from ArrayRef [ Dict [ '#text' => Str, size => Str ] ], via {
    my $h = $_;
    return { map { $_->{'size'} => $_->{'#text'} } @{$h} };
};
coerce Image, from ArrayRef [ 
    Dict [ 
        '#text' => Str, 
        name => Str, 
        width => Int, 
        height => Int 
    ] ], via {
    my $h = $_;
    return { map { $_->{'name'} => $_->{'#text'} } @{$h} };
};


# TODO : Make owner work when owner is not a user.

subtype FullImage, as Dict[
    title => Str,
    url => Str,
    dateadded => DateTime,
    format => Str,
#    owner => User,
    urls => Image,
    votes => Dict [
        thumbsup => Int,
        thumbsdown => Int,
    ],
];

coerce FullImage, from HashRef, via {
    return {
        title => $_->{title},
        url => $_->{url},
        dateadded => find_type_constraint(DateTime)->coerce( $_->{dateadded} ),
        format  => $_->{format},
 #       owner => find_type_constraint(User)->coerce( $_->{owner}->{name} ),
        urls => find_type_constraint(Image)->coerce( $_->{sizes}->{size} ),
        votes => $_->{votes}
    }
};

subtype Images, as ArrayRef[FullImage];
coerce Images, from Dict[ image => ArrayRef[HashRef]], via {
    my $h = $_->{image};
    my $fimage = find_type_constraint(FullImage);
    return [ map { $fimage->coerce($_) } @{$h} ];
};



### Shout Structure
subtype Shout, as Dict [
    'body'   => Str,
    'author' => User,
    'date'   => DateTime,
];
coerce Shout, from HashRef [Str], via {
    return {
        body   => $_->{body},
        author => find_type_constraint(User)->coerce( $_->{author} ),
        date   => find_type_constraint(DateTime)->coerce( $_->{date} ),
    };
};
subtype Shouts, as ArrayRef[Shout];

coerce Shouts, from ArrayRef, via {
    my $h = $_;
    my $shout = find_type_constraint(Shout);
    return [ map { $shout->coerce($_) } @{$h} ];
};

coerce Shouts, from Dict[ 'shout' => ArrayRef ], via {
    my $h = $_->{shout};
    my $shout = find_type_constraint(Shout);
    return [ map { $shout->coerce($_) } @{$h} ];
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
subtype Gender, as Str, where {m/[mf]/xms};
coerce Gender, from Str, via { lc( substr( $_, 0, 1 ) ) };

### Goose
duck_type Logger, [qw(debug info warning critical)];
duck_type Cache,  [qw(get set)];

### SmArrayRef for lastfm requests
subtype SmArrayRef, as ArrayRef,
    where { ( scalar @{$_} <= 10 ) && ( scalar @{$_} >= 1 ) };

class_type DateTime, { class => 'DateTime' };
coerce DateTime, from Dict[ '#text' => Str, 'unixtime' => Int ], via {
    find_type_constraint('MooseX::Types::DateTimeX::DateTime')->coerce( $_->{unixtime} ),
};
coerce DateTime, from Str, via {
    find_type_constraint('MooseX::Types::DateTimeX::DateTime')->coerce( $_ ),
};
coerce DateTime, from Int, via {
    find_type_constraint('MooseX::Types::DateTimeX::DateTime')->coerce( $_ ),
};


subtype CurrentPlay, as Dict [
    track   => Track,
    last_update => DateTime,
    play_start  => DateTime,
    running_time    => Int,
    required_time   => Num,
    current_time    => Int,
];


class_type UserAgent, { class => 'LWP::UserAgent' };

1;
__END__

=head1 NAME

Music::LastFM::Types::LastFM - [One line description of module's purpose here]

=head1 VERSION

This document describes Music::LastFM version 0.0.3

=head1 SYNOPSIS

    use Music::LastFM;
  
=head1 DESCRIPTION

Support module for Music::LastFM.

=head1 METHODS

=head2 Constructor

=over

=item new

=head2 Attributes

=head2 Methods

=head1 DIAGNOSTICS

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
