use warnings; use strict; use Carp;
use Test::More tests => 1;

use English qw( -no_match_vars ) ;

use Music::LastFM;

my $lfm = Music::LastFM->new(config_filename => 'tmp/options.conf');
my $config = Music::LastFM::Config->instance();

ok($config->get_option('api_key'), 'Config has api key');

done_testing();

