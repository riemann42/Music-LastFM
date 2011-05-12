use strict;
use warnings;

use Test::More tests => 3;                     
use Pod::Snippets;
use Config::Std;

my $module = 'lib/Music/LastFM.pm';
if ( -e 'blib') {
    $module = 'b'.$module;
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

 # Create a new lfm object
 # 293     my $lfm = Music::LastFM->new(
 # 294         api_key => "MY_API_KEY_PROVIDED_BY_LASTFM",
 # 295         api_secret => "MY_API_SECRET_ABLE_TO_SIGN_REQUEST",
 # 296         username => "iAmCool",
 # 297     );
 # 298
 # 299     # This will return a Music::LastFM::Response object
 # 300     my $response = $lfm->query(method  => 'artist.getInfo',
 # 301                                option
$code =~ s/my \$lfm [^;]+;//mxs;

$code =~ s/MY_API_KEY_PROVIDED_BY_LASTFM/$config{''}->{api_key}/;
$code =~ s/MY_API_SECRET_ABLE_TO_SIGN_REQUEST/$config{''}->{api_secret}/;
$code =~ s/iAmCool/$config{''}->{username}/;

$code =~ s/^ \s* print .* $//xmsg;

my $response = eval $code; warn $@ if $@;

ok(! $@, "code compiled and ran ok");
ok(@{$response->{artists}} > 1, "Response array is larger than 1");
ok($response->{artists}->[0]->isa('Music::LastFM::Object::Artist'), "Response is an artist object");

my $lfm = $response->{lfm};



