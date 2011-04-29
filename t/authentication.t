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


my $token_ref = $lfm->agent->gettoken;

ok($token_ref, 'Token request ok');

if ($token_ref) {
    ok( ! ref $token_ref->{token}, 'Right type of token object returned');
    ok(length($token_ref->{token}) > 10, 'Token is longer than 10 characters'); 
}



done_testing();

