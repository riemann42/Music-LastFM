use warnings; use strict; use Carp;
use Test::More;

use English qw( -no_match_vars ) ;
use Data::Dumper;


BEGIN {
    use_ok( 'Music::LastFM' );
}

my $lfm = Music::LastFM->new(config_filename => 't/options.conf');
my $config = Music::LastFM::Config->instance();
print STDERR Dumper($config->_option_ref);






done_testing();

