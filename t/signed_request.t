use strict;
use warnings;

use Test::More tests => 4; 


BEGIN {
    use_ok( 'Music::LastFM' );
}

my $lfm = Music::LastFM->new(config_filename => 'tmp/options.conf');

my $username = $lfm->config->get_option('username');

SKIP: {

    if (! $lfm->session_cache->has_value($username)) {
        skip "Skipping signed request, as no session key for $username is available";
    }
    my $user = $lfm->new_user(name => $username);
    ok(defined $user, "User is defined");
    ok($user->isa('Music::LastFM::Object::User'), "User is an object");
    note("Shouting to mlfm-test");
    ok($user->shout(message => "Testing mlfm signed request at " . localtime), "Sending test shout to $username");

}


done_testing();

