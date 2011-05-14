use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );
use Test::More;
use lib ('inc/');

use Test::LWP::Recorder; 

my $ua = Test::LWP::Recorder->new({
    record => $ENV{LWP_RECORD},
    cache_dir => 't/LWPCache', 
    filter_params => [qw(api_key api_secret sk)],
});


my %expected_results = (
    'Sarah Slean' => {
        mbid        => 'CA6FB0DE-336F-4BD9-ADF1-CE8EEBAA7FE1',
        listeners   => "150000",
        playcount   => "1500000",
        toptags     => 1,
        topfans     => 1,
        bio         => 1,
        events      => 1,
        past_events => 1,
        images      => 1,
        should_fail => 0,
        addtag      => 1,
        tag         => 'Canada'
    },
    'There should be no artist with this name'  => { should_fail => 6 },
    'There should be no artist with this nameo' => { should_fail => 6 },
    'Charlotte Martin'                          => {
        mbid        => '757FFB3E-AAB4-4635-A1F8-9A33F42FC3DA',
        url         => 'http://www.last.fm/music/Charlotte+Martin',
        listeners   => 168849,
        playcount   => 1748248,
        toptags     => 1,
        topfans     => 1,
        bio         => 1,
        should_fail => 0
    }
);

plan tests => 23 * ( scalar keys %expected_results ) + 1;

use_ok('Music::LastFM');

sub check_list_value {
    my ( $should_fail, $artist, $method, $valuetype ) = @_;
    ok( ref $artist->$method eq 'ARRAY',
        qq{artist $method returns an array ref}
    );
    ok( $artist->$method->[0]->isa($valuetype),
        qq{artist $method returns an array of tags}
    );
}
my $username = 'mlfm-test';
my $lfm = Music::LastFM->new( config_filename => 'tmp/options.conf' );
$lfm->agent->set_lwp_ua($ua);
$lfm->agent->lwp_ua->agent(   'Music-LastFM/' 
                            . $Music::LastFM::VERSION
                            . $lfm->agent->lwp_ua->_agent() );
$lfm->no_cache();

while ( my ( $artist_name, $expected ) = each %expected_results ) {
    my $artist = $lfm->new_artist( name => $artist_name );
    my $should_fail = $expected->{should_fail} || 0;
    ok( ( $artist->check xor $should_fail ), "Check for artist existance" );

    ok( $artist eq $artist_name, qq{Artist Overload for $artist_name works} );

    SKIP:
    {
        skip( 'Failure test only', 3 ) if ( !$should_fail );
        eval { my $mbid = $artist->mbid; };
        my $object = $EVAL_ERROR;
        ok( Music::LastFM::Exception::APIError->caught($object),
            qq{Bad artist $artist_name produced error}
        );
        ok( $object->error_code == $should_fail,
            '...Correct error code returned'
        );
        ok( !$object->is_fatal, '...Error is not fatal' );
    }

    SKIP:
    {
        skip( 'Not Requested', 1 ) if ( !$expected->{mbid} );
        ok( lc( $artist->mbid() ) eq lc( $expected->{mbid} ),
            qq{MBID for $artist_name is $expected->{mbid}}
        );
    }

    SKIP:
    {
        skip( 'Not Requested', 1 ) if ( !$expected->{listeners} );
        ok( $artist->listeners >= $expected->{listeners},
            qq{Listener count >= $expected->{listeners} for $artist_name} );
    }

    SKIP:
    {
        skip( 'Not Requested', 1 ) if ( !$expected->{playcount} );
        ok( $artist->playcount >= $expected->{playcount},
            qq{Playcount count >= $expected->{playcount} for $artist_name} );
    }

    SKIP:
    {
        skip( 'Not Requested', 1 ) if ( !$expected->{url} );
        ok( $artist->url eq $expected->{url},
            qq{url matches for $artist_name}
        );
    }

    SKIP:
    {
        skip( 'Not Requested', 2 ) if ( !$expected->{events} );
        check_list_value( $should_fail, $artist, 'events',
            'Music::LastFM::Object::Event' );
    }

    SKIP:
    {
        skip( 'Not Requested', 2 ) if ( !$expected->{toptags} );
        check_list_value( $should_fail, $artist, 'toptags',
            'Music::LastFM::Object::Tag' );
    }

    SKIP:
    {
        skip( 'Not Requested', 2 ) if ( !$expected->{topfans} );
        check_list_value( $should_fail, $artist, 'topfans',
            'Music::LastFM::Object::User' );
    }

    SKIP:
    {
        skip( 'Not Requested', 2 ) if ( !$expected->{images} );
        ok( ref $artist->images eq 'ARRAY',
            'artist image list is an arrayref'
        );

        ok( exists $artist->images->[0]->{url},
            'artist first image has url' );
    }

    SKIP:
    {
        skip( 'Not Requested', 2 ) if ( !$expected->{bio} );

        ok( ref $artist->bio eq 'HASH', 'artist bio is a hashref' );

        ok( exists $artist->bio->{content}, 'artist bio has content' );
    }

    SKIP:
    {
        skip( 'Write Test Not Enabled',4 ) if (! $ENV{WRITE_TESTING});
        skip( 'Not Requested', 4 ) if ( !$expected->{addtag} );
        skip( 'No session key', 4 )
            if ( !( $lfm->agent->has_sk($username) ) );
        ok( $artist->add_tags( tags => [ $expected->{tag} ] ), "Added tag" );
        my $ok =
            grep { lc( $_->name() ) eq lc( $expected->{tag} ) }
            @{ $artist->user_tags };
        ok( $ok, "Found tag in tag list" );
        ok( $artist->remove_tag( tag => $expected->{tag} ), "Removed tag" );
        $ok =
            grep { lc( $_->name() ) eq lc( $expected->{tag} ) }
            @{ $artist->user_tags };
        ok( !$ok, "did not find tag in tag list" );
    }
}

done_testing();

