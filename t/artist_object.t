use warnings; use strict; use Carp;
use Test::More;

use English qw( -no_match_vars ) ;


BEGIN {
    use_ok( 'Music::LastFM' );
}

# Replace all this with a simple config file!
my $options = Config::Options->new({
   optionfile => [ 'options.conf', 't/options.conf' ], 
});
$options->fromfile_perl();

my $lfm = Music::LastFM->new(%{$options}); 

my $artist = $lfm->new_artist(name => 'Sarah Slean');
is ($artist->mbid(), 'CA6FB0DE-336F-4BD9-ADF1-CE8EEBAA7FE1', 'MBID For Sarah Slean');

ok ($artist->playcount  > 1, 'Artist has a playcount');
ok ($artist->listeners  > 1, 'Artist has listeners');
ok ($artist eq 'Sarah Slean', 'Artist Overload works');
ok (ref $artist->toptags  eq 'ARRAY', 'artist toptags returns an array ref');
if (ref $artist->toptags  eq 'ARRAY') {
    ok ($artist->toptags->[0]->isa('Music::LastFM::Object::Tag'), 'artist toptags returns an array of tags');
}
ok (ref $artist->topfans  eq 'ARRAY', 'artist topfans returns an array ref');
if (ref $artist->topfans  eq 'ARRAY') {
    ok ($artist->topfans->[0]->isa('Music::LastFM::Object::User'), 'artist topfans returns an array of users');
}
ok (ref $artist->bio  eq 'HASH', 'artist bio is a hashref');
if (ref $artist->bio  eq 'HASH') {
    ok (exists $artist->bio->{content}, 'artist bio has content');
}
eval { my $badartist = $lfm->new_artist(name => 'There should not be an artist with this name'); $badartist->mbid(); };
my $object = $EVAL_ERROR;
ok (Music::LastFM::Exception::APIError->caught($object), 'Bad artist produced error');
ok ($object->error_code == 6, 'Correct error code returned');
ok (!  $object->is_fatal, 'Error is not fatal');





done_testing();

