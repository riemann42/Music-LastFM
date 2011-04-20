#!/usr/bin/perl 
use warnings; use strict; use Carp;
use version; our $VERSION = qv('0.0.3');

use Music::LastFM;
use Data::Dumper;

my $options = Config::Options->new({
        username => "riemann42",
        session_cache      => $ENV{HOME} . "/.music-lastfm-sessions",
        scrobble_queue     => $ENV{HOME} . "/.music-lastfm-queue",
        logfile            => undef,
        cache_time => 18000,
        optionfile         => [
            "/etc/music-lastfm.conf",
            $ENV{HOME} . "/.music-lastfm.conf"
        ],
        api_key    => undef,
        api_secret => undef,
        url     => 'http://ws.audioscrobbler.com/2.0/'
});

$options->fromfile_perl();

my $lfm = Music::LastFM->new(%{$options}); 

#my $resp =  $lfm->query(method => "artist.getInfo", options => { artist => "Sarah Slean"}); 

#print Dumper($resp->data->mbid);


my $artist = $lfm->artist(name => 'Sarah Slean');
print "$artist: ", $artist->mbid(), "\n";



