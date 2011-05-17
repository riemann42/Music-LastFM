use Test::More tests => 1;

BEGIN {
use_ok( 'Music::LastFM' );
}

if (! -d q{tmp}) { mkdir q{tmp} }
diag( "Testing Music::LastFM $Music::LastFM::VERSION" );
