use strict;
use warnings;
use Carp;

#use Test::More;

use English qw( -no_match_vars );

use Music::LastFM;

my $username = 'riemann42';
my $lfm = Music::LastFM->new( config_filename => 'tmp/options.conf' );

my $user = $lfm->new_user(name => $username);  # Create a new empty user object

# Check to see if user exists.  Failure to do this could result in an
# exception at a point you aren't prepared for it.  This call can still
# provide an exception (e.g. in the case of network error, or a bad api
# key), so eval it may still be appropriate.

if (! $user->check) {
    croak "$username is not a valid user";
}
else {
# Print top artists for $username
    print qq{Top artists for ${username}:\n};
    my $top_artists = $user->top_artists(options => { limit => 200 });
    foreach my $artist (@{$top_artists}) {
        print $artist->attr->{rank}, ". ", $artist->name, " - ",
        $artist->user_playcount, "\n";
    }
}


