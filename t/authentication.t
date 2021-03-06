use warnings; use strict; use Carp;
use Test::More;
use IO::Interactive qw(is_interactive);

use lib ('inc/');
use Test::LWP::Recorder; 

use English qw( -no_match_vars ) ;


BEGIN {
    use_ok( 'Music::LastFM' );
}

sub sleep_print {
    for (1..5) {
        print STDERR "."; sleep 1;
    }
}

my $ua = Test::LWP::Recorder->new({
    record => $ENV{LWP_RECORD},
    cache_dir => 't/LWPCache', 
    filter_params => [qw(api_key api_secret sk)],
});

my $lfm = Music::LastFM->new(config_filename => 'tmp/options.conf');
$lfm->agent->set_lwp_ua($ua);
$lfm->agent->lwp_ua->agent(   'Music-LastFM/' 
                            . $Music::LastFM::VERSION
                            . $lfm->agent->lwp_ua->_agent() );
$lfm->no_cache();


my $username = 'mflm-test';
my $sessionkey;


my $token_ref = $lfm->agent->gettoken;

ok($token_ref, 'Token request ok');

if ($token_ref) {
    ok( ! ref $token_ref->{token}, 'Right type of token object returned');
    ok(length($token_ref->{token}) > 10, 'Token is longer than 10 characters'); 

    SKIP: {
        if (! is_interactive) {
            skip "Only try a real logon if run interactivly.", 4;
        }
        skip( 'Write Test Not Enabled',4 ) if (! $ENV{WRITE_TESTING});
        note ("Please visit " . $token_ref->{url});
        note ("I will wait for you.");

        my $session;

        AUTH: while(1) {
            sleep_print;
            eval { $session = $lfm->agent->getsession($token_ref->{token}) };
            if (! $EVAL_ERROR) {
                last AUTH;
            }
            my $object = $EVAL_ERROR;
            note($object);
            if (ok (Music::LastFM::Exception::APIError->caught($object), 'We got a LFM API error')) {
                note ("LastFM error code: ". $object->error_code);
                if(ok ($object->error_code == 14, 'Correct error code returned')) {
                    next AUTH;
                }
            }
            last AUTH;
        }
        if ($session) {
            ok(ref $session eq 'HASH', 'Session is a hash ref');
            ok($session->{name} && $session->{key}, 'Have a username and session key');
            note('Got session key for user ' . $session->{name} . ' - '. $session->{key});
            $username = $session->{name};
            $sessionkey = $session->{key};
            
        }
    }
}




done_testing();

