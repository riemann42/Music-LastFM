use strict;
use warnings;

use Test::More tests => 3;                     
use Pod::Snippets;
use Config::Std;

my $module = 'lib/Music/LastFM.pm';
if ( -e 'blib') {
    $module = 'blib/'.$module;
}
my $snip = Pod::Snippets->load($module, -markup => 'test');

my $code = $snip->named('synopsis')->as_code();

my %config = (
    '' => {
        api_key => q{},
        api_secret => q{},
    },
    sessions => {},
);

read_config 'tmp/options.conf' => %config;

$code =~ s/my \$lfm [^;]+;//mxs;

$code =~ s/MY_API_KEY_PROVIDED_BY_LASTFM/$config{''}->{api_key}/;
$code =~ s/MY_API_SECRET_ABLE_TO_SIGN_REQUEST/$config{''}->{api_secret}/;
$code =~ s/iAmCool/$config{''}->{username}/;

$code =~ s/^ \s* print [^\n]* $//xmsg;


warn $code;

my $response = eval $code; warn $@ if $@;

ok(! $@, "code compiled and ran ok");
ok(@{$response->{artists}} > 1, "Response array is larger than 1");
ok($response->{artists}->[0]->isa('Music::LastFM::Object::Artist'), "Response is an artist object");

my $lfm = $response->{lfm};



