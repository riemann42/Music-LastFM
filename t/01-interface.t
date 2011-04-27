use warnings; use strict; use Carp;
use Test::More;

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

done_testing();

