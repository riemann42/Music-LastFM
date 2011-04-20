package Music::LastFM::Types::Method;
use warnings;
use strict;
use Carp;

use MooseX::Types -declare => [ qw( Method Methods )];

use MooseX::Types::Moose qw(HashRef ArrayRef Str );

### Music::LastFM::Method
class_type Method, { class => 'Music::LastFM::Method' };
coerce Method, from HashRef, via { 'Music::LastFM::Method'->new( %{$_} ) };

use Music::LastFM::Method;

our %METHODS = (
    "album.addTags" =>
        { name => "album.addTags", authrequired => 1, method => 'POST' },
    "album.getBuylinks" => { name => "album.getBuylinks" },
    "album.getInfo"     => { name => "album.getInfo", },
    "album.getShouts"   => { name => "album.getShouts" },
    "album.getTags" =>
        { name => "album.getTags", signrequired => 1, authrequired => 1, },
    "album.getTopTags" => { name => "album.getTopTags", },
    "album.removeTag" =>
        { name => "album.removeTag", authrequired => 1, method => 'POST' },
    "album.search" => { name => "album.search", },
    "album.share" =>
        { name => "album.share", authrequired => 1, method => 'POST' },
    "artist.addTags" =>
        { name => "artist.addTags", authrequired => 1, method => 'POST' },
    "artist.getCorrection" => { name => "artist.getCorrection" },
    "artist.getEvents"     => { name => "artist.getEvents", },
    "artist.getImages"     => { name => "artist.getImages" },
    "artist.getInfo"       => { name => "artist.getInfo", },
    "artist.getPastEvents" => { name => "artist.getPastEvents", },
    "artist.getPodcast"    => { name => "artist.getPodcast" },
    "artist.getShouts"     => { name => "artist.getShouts" },
    "artist.getSimilar"    => { name => "artist.getSimilar", },
    "artist.getTags"      => { name => "artist.getTags", authrequired => 1, },
    "artist.getTopAlbums" => { name => "artist.getTopAlbums", },
    "artist.getTopFans"   => { name => "artist.getTopFans", },
    "artist.getTopTags"   => { name => "artist.getTopTags", },
    "artist.getTopTracks" => { name => "artist.getTopTracks", },
    "artist.removeTag" =>
        { name => "artist.removeTag", authrequired => 1, method => 'POST' },
    "artist.search" => { name => "artist.search", },
    "artist.share" =>
        { name => "artist.share", authrequired => 1, method => 'POST' },
    "artist.shout" =>
        { name => "artist.shout", authrequired => 1, method => 'POST' },
    "auth.getMobileSession" =>
        { name => "auth.getMobileSession", signrequired => 1, },
    "auth.getSession" => { name => "auth.getSession", signrequired => 1, },
    "auth.getToken"   => { name => "auth.getToken",   signrequired => 1, },
    "chart.getHypedArtists" => { name => "chart.getHypedArtists", },
    "chart.getHypedTracks"  => { name => "chart.getHypedTracks", },
    "chart.getLovedTracks"  => { name => "chart.getLovedTracks", },
    "chart.getTopArtists"   => { name => "chart.getTopArtists", },
    "chart.getTopTags"      => { name => "chart.getTopTags", },
    "chart.getTopTracks"    => { name => "chart.getTopTracks", },
    "event.attend" =>
        { name => "event.attend", authrequired => 1, method => 'POST' },
    "event.getAttendees" => { name => "event.getAttendees", },
    "event.getInfo"      => { name => "event.getInfo", },
    "event.getShouts"    => { name => "event.getShouts", },
    "event.share" =>
        { name => "event.share", authrequired => 1, method => 'POST' },
    "event.shout" =>
        { name => "event.shout", authrequired => 1, method => 'POST' },
    "geo.getEvents"           => { name => "geo.getEvents", },
    "geo.getMetroArtistChart" => { name => "geo.getMetroArtistChart", },
    "geo.getMetroHypeArtistChart" =>
        { name => "geo.getMetroHypeArtistChart", },
    "geo.getMetroHypeTrackChart" => { name => "geo.getMetroHypeTrackChart", },
    "geo.getMetroTrackChart"     => { name => "geo.getMetroTrackChart", },
    "geo.getMetroUniqueArtistChart" =>
        { name => "geo.getMetroUniqueArtistChart", },
    "geo.getMetroUniqueTrackChart" =>
        { name => "geo.getMetroUniqueTrackChart", },
    "geo.getMetroWeeklyChartlist" =>
        { name => "geo.getMetroWeeklyChartlist", },
    "geo.getMetros"              => { name => "geo.getMetros", },
    "geo.getTopArtists"          => { name => "geo.getTopArtists", },
    "geo.getTopTracks"           => { name => "geo.getTopTracks", },
    "group.getHype"              => { name => "group.getHype", },
    "group.getMembers"           => { name => "group.getMembers", },
    "group.getWeeklyAlbumChart"  => { name => "group.getWeeklyAlbumChart", },
    "group.getWeeklyArtistChart" => { name => "group.getWeeklyArtistChart", },
    "group.getWeeklyChartList"   => { name => "group.getWeeklyChartList", },
    "group.getWeeklyTrackChart"  => { name => "group.getWeeklyTrackChart", },
    "library.addAlbum" =>
        { name => "library.addAlbum", authrequired => 1, method => 'POST' },
    "library.addArtist" =>
        { name => "library.addArtist", authrequired => 1, method => 'POST' },
    "library.addTrack" =>
        { name => "library.addTrack", authrequired => 1, method => 'POST' },
    "library.getAlbums"  => { name => "library.getAlbums", },
    "library.getArtists" => {
        name    => "library.getArtists",
        returns => ['Music::LastFM::Artists'],
    },
    "library.getTracks" => { name => "library.getTracks", },
    "playlist.addTrack" =>
        { name => "playlist.addTrack", authrequired => 1, method => 'POST' },
    "playlist.create" =>
        { name => "playlist.create", authrequired => 1, method => 'POST' },
    "playlist.fetch" =>
        { name => "playlist.fetch", authrequired => 1, method => 'POST' },
    "radio.getPlaylist" => { name => "radio.getPlaylist", },
    "radio.search"      => { name => "radio.search", },
    "radio.tune" =>
        { name => "radio.tune", authrequired => 1, method => 'POST' },
    "tag.getInfo"              => { name => "tag.getInfo", },
    "tag.getSimilar"           => { name => "tag.getSimilar", },
    "tag.getTopAlbums"         => { name => "tag.getTopAlbums", },
    "tag.getTopArtists"        => { name => "tag.getTopArtists", },
    "tag.getTopTags"           => { name => "tag.getTopTags", },
    "tag.getTopTracks"         => { name => "tag.getTopTracks", },
    "tag.getWeeklyArtistChart" => { name => "tag.getWeeklyArtistChart", },
    "tag.getWeeklyChartList"   => { name => "tag.getWeeklyChartList", },
    "tag.search"               => { name => "tag.search", },
    "tasteometer.compare"      => { name => "tasteometer.compare", },
    "track.addTags" =>
        { name => "track.addTags", authrequired => 1, method => 'POST' },
    "track.ban" =>
        { name => "track.ban", authrequired => 1, method => 'POST' },
    "track.getBuylinks"   => { name => "track.getBuylinks", },
    "track.getCorrection" => { name => "track.getCorrection", },
    "track.getFingerprintMetadata" =>
        { name => "track.getFingerprintMetadata", },
    "track.getInfo"    => { name => "track.getInfo", },
    "track.getShouts"  => { name => "track.getShouts", },
    "track.getSimilar" => { name => "track.getSimilar", },
    "track.getTags"    => { name => "track.getTags", },
    "track.getTopFans" => { name => "track.getTopFans", },
    "track.getTopTags" => { name => "track.getTopTags", },
    "track.love" =>
        { name => "track.love", authrequired => 1, method => 'POST' },
    "track.removeTag" =>
        { name => "track.removeTag", authrequired => 1, method => 'POST' },
    "track.scrobble" =>
        { name => "track.scrobble", authrequired => 1, method => 'POST' },
    "track.search" => { name => "track.search", },
    "track.share" =>
        { name => "track.share", authrequired => 1, method => 'POST' },
    "track.unban" =>
        { name => "track.unban", authrequired => 1, method => 'POST' },
    "track.unlove" =>
        { name => "track.unlove", authrequired => 1, method => 'POST' },
    "track.updateNowPlaying" => {
        name         => "track.updateNowPlaying",
        authrequired => 1,
        method       => 'POST'
    },
    "user.getArtistTracks" => { name => "user.getArtistTracks", },
    "user.getBannedTracks" => { name => "user.getBannedTracks", },
    "user.getEvents"       => { name => "user.getEvents", },
    "user.getFriends"      => { name => "user.getFriends", },
    "user.getInfo"         => { name => "user.getInfo", },
    "user.getLovedTracks"  => { name => "user.getLovedTracks", },
    "user.getNeighbours"   => { name => "user.getNeighbours", },
    "user.getNewReleases"  => { name => "user.getNewReleases", },
    "user.getPastEvents"   => { name => "user.getPastEvents", },
    "user.getPersonalTags" => { name => "user.getPersonalTags", },
    "user.getPlaylists"    => { name => "user.getPlaylists", },
    "user.getRecentStations" =>
        { name => "user.getRecentStations", authrequired => 1, },
    "user.getRecentTracks"       => { name => "user.getRecentTracks", },
    "user.getRecommendedArtists" => { name => "user.getRecommendedArtists", },
    "user.getRecommendedEvents"  => { name => "user.getRecommendedEvents", },
    "user.getShouts"             => { name => "user.getShouts", },
    "user.getTopAlbums"          => { name => "user.getTopAlbums", },
    "user.getTopArtists" => { name => "user.getTopArtists", ignoretop => 1, },
    "user.getTopTags"    => { name => "user.getTopTags", },
    "user.getTopTracks"  => { name => "user.getTopTracks", },
    "user.getWeeklyAlbumChart"  => { name => "user.getWeeklyAlbumChart", },
    "user.getWeeklyArtistChart" => { name => "user.getWeeklyArtistChart", },
    "user.getWeeklyChartList"   => { name => "user.getWeeklyChartList", },
    "user.getWeeklyTrackChart"  => { name => "user.getWeeklyTrackChart", },
    "user.shout" =>
        { name => "user.shout", authrequired => 1, method => 'POST' },
    "venue.getEvents"     => { name => "venue.getEvents", },
    "venue.getPastEvents" => { name => "venue.getPastEvents", },
    "venue.search" =>
        { name => "venue.search", authrequired => 1, method => 'POST' },
);

coerce Method, from Str, via {
    if ( $METHODS{$_} ) {
        'Music::LastFM::Method'->new( %{ $METHODS{$_} } );
    }
};

subtype Methods, as ArrayRef [Method];

coerce Methods, from ArrayRef[Str], via {
    [ map { 'Music::LastFM::Method'->new( %{$METHODS{$_}} ) } @{$_} ];
};

coerce Methods, from ArrayRef, via {
    [ map { 'Music::LastFM::Method'->new( %{$_} ) } @{$_} ];
};


1;

