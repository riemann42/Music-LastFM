use warnings;
use strict;
use Carp;
use Test::More tests => 29;

use English qw( -no_match_vars );

BEGIN {
    use_ok('Music::LastFM');
}


sub maybe_ok {
    my ( $condition, $should_fail, $details ) = @_;
    my $re_condition = $condition;
    if ($should_fail) {
        $re_condition = !$condition;
        $details .= " -- SHOULD FAIL";
    }
    ok( $re_condition, $details );
}

my $lfm = Music::LastFM->new( config_filename => 't/options.conf' );

my %expected_results = (
    'Sarah Slean' => {
        mbid        => 'CA6FB0DE-336F-4BD9-ADF1-CE8EEBAA7FE1',
        listeners   => "150000",
        playcount   => "1500000",
        toptags     => 1,
        topfans     => 1,
        bio         => 1,
        should_fail => 0
    },
    'There should be no artist with this name' =>
        { should_fail => 6, listeners => 1 },
    'There should be no artist with this nameo' =>
        { should_fail => 6, playcount => 1 },
    'Charlotte Martin' => {
        mbid      => '757ffb3e-aab4-4635-a1f8-9a33f42fc3da',
        url       => 'http://www.last.fm/music/Charlotte+Martin',
        listeners => 168849,
        playcount => 1748248,
        toptags     => 1,
        topfans     => 1,
        bio         => 1,
        should_fail => 0
    }
);
use Data::Dumper;

while ( my ( $artist_name, $expected ) = each %expected_results ) {
    my $artist = $lfm->new_artist( name => $artist_name );
    my $should_fail = $expected->{should_fail} || 0;
    eval {
        ok( $artist eq $artist_name, qq{Artist Overload for $artist_name works} );

        if ( exists $expected->{mbid} ) {
            maybe_ok( lc($artist->mbid()) eq lc($expected->{mbid}),
                $should_fail, qq{MBID for $artist_name is $expected->{mbid}} );
        }
        if ( exists $expected->{listeners} ) {
            maybe_ok(
                $artist->listeners >= $expected->{listeners},
                $should_fail,
                qq{Listener count >= $expected->{listeners} for $artist_name}
            );
        }
        if ( exists $expected->{playcount} ) {
            maybe_ok(
                $artist->playcount >= $expected->{playcount},
                $should_fail,
                qq{Playcount count >= $expected->{playcount} for $artist_name}
            );
        }
        if ( exists $expected->{url} ) {

        }

        if ( $expected->{toptags} ) {
            maybe_ok( ref $artist->toptags eq 'ARRAY',
                $should_fail, 'artist toptags returns an array ref' );
            if ( ref $artist->toptags eq 'ARRAY' ) {
                maybe_ok(
                    $artist->toptags->[0]->isa('Music::LastFM::Object::Tag'),
                    $should_fail, 'artist toptags returns an array of tags'
                );
            }
        }
        if ( $expected->{topfans} ) {
            maybe_ok( ref $artist->topfans eq 'ARRAY',
                $should_fail, 'artist topfans returns an array ref' );
            if ( ref $artist->topfans eq 'ARRAY' ) {
                maybe_ok(
                    $artist->topfans->[0]->isa('Music::LastFM::Object::User'),
                    $should_fail, 'artist topfans returns an array of users'
                );
            }
        }
        if ( $expected->{bio} ) {
            maybe_ok( ref $artist->bio eq 'HASH',
                $should_fail, 'artist bio is a hashref' );
            if ( ref $artist->bio eq 'HASH' ) {
                maybe_ok( exists $artist->bio->{content},
                    $should_fail, 'artist bio has content' );
            }
        }
    };
    if ($should_fail) {
        my $object = $EVAL_ERROR;
        ok( Music::LastFM::Exception::APIError->caught($object),
            qq{Bad artist $artist_name produced error} );
        ok( $object->error_code == $should_fail, '...Correct error code returned' );
        ok( !$object->is_fatal,           '...Error is not fatal' );
    }

}

done_testing();

