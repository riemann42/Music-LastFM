use strict;
use warnings;

use Test::More tests => 3;                     
use Pod::Snippets;
use Config::Std;
use lib qw(inc);
use Test::LWP::Recorder;

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

my $ua = Test::LWP::Recorder->new({
    record => $ENV{LWP_RECORD},
    cache_dir => 't/LWPCache', 
    filter_params => [qw(api_key api_secret sk)],
});

my $lwpcode = <<'ENDOFCODE';
$lfm->agent->set_lwp_ua($ua); $lfm->no_cache();
ENDOFCODE

$code =~ s/# This will return a Music::LastFM::Response object/$lwpcode/;
$code =~ s/MY_API_KEY_PROVIDED_BY_LASTFM/$config{''}->{api_key}/;
$code =~ s/MY_API_SECRET_ABLE_TO_SIGN_REQUEST/$config{''}->{api_secret}/;
$code =~ s/iAmCool/$config{''}->{username}/;

$code =~ s/^ \s* print [^\n]* $//xmsg;

my $response = eval $code; warn $@ if $@;

ok(! $@, "code compiled and ran ok");
ok(@{$response->{artists}} > 1, "Response array is larger than 1");
ok($response->{artists}->[0]->isa('Music::LastFM::Object::Artist'), "Response is an artist object");

my $lfm = $response->{lfm};



