package Music::LastFM::Types::Method;
use warnings;
use strict;
use Carp;

use MooseX::Types -declare => [qw( Method Methods )];

use MooseX::Types::Moose qw(HashRef ArrayRef Str );

### Music::LastFM::Method
class_type Method, { class => 'Music::LastFM::Method' };
coerce Method, from HashRef, via { 'Music::LastFM::Method'->new( %{$_} ) };

use Music::LastFM::Method;

our %METHODS = (
    "album.addTags" => {
        name          => "album.addTags",
        auth_required => 1,
        http_method   => 'POST'
    },
    "album.getBuylinks" => { name => "album.getBuylinks" },
    "album.getInfo"     => { name => "album.getInfo", },
    "album.getShouts"   => { name => "album.getShouts" },
    "album.getTags" =>
        { name => "album.getTags", sign_required => 1, auth_required => 1, },
    "album.getTopTags" => { name => "album.getTopTags", },
    "album.removeTag"  => {
        name          => "album.removeTag",
        auth_required => 1,
        http_method   => 'POST'
    },
    "album.search" => { name => "album.search", },
    "album.share" =>
        { name => "album.share", auth_required => 1, http_method => 'POST' },
    "artist.addTags" => {
        name          => "artist.addTags",
        auth_required => 1,
        http_method   => 'POST'
    },
    "artist.getCorrection" => { name => "artist.getCorrection" },
    "artist.getEvents"     => { name => "artist.getEvents", },
    "artist.getImages"     => { name => "artist.getImages" },
    "artist.getInfo"       => { name => "artist.getInfo", },
    "artist.getPastEvents" => { name => "artist.getPastEvents", },
    "artist.getPodcast"    => { name => "artist.getPodcast" },
    "artist.getShouts"     => { name => "artist.getShouts" },
    "artist.getSimilar"    => { name => "artist.getSimilar", },
    "artist.getTags"       => {
        name          => "artist.getTags",
        auth_required => 1,
        sign_required => 1
    },
    "artist.getTopAlbums" => { name => "artist.getTopAlbums", },
    "artist.getTopFans"   => { name => "artist.getTopFans", },
    "artist.getTopTags"   => { name => "artist.getTopTags", },
    "artist.getTopTracks" => { name => "artist.getTopTracks", },
    "artist.removeTag"    => {
        name          => "artist.removeTag",
        auth_required => 1,
        http_method   => 'POST'
    },
    "artist.search" => { name => "artist.search", },
    "artist.share" =>
        { name => "artist.share", auth_required => 1, http_method => 'POST' },
    "artist.shout" =>
        { name => "artist.shout", auth_required => 1, http_method => 'POST' },
    "auth.getMobileSession" =>
        { name => "auth.getMobileSession", sign_required => 1, },
    "auth.getSession" => { name => "auth.getSession", sign_required => 1 },
    "auth.getToken" =>
        { name => "auth.getToken", sign_required => 1, ignore_top => 0 },
    "chart.getHypedArtists" => { name => "chart.getHypedArtists", },
    "chart.getHypedTracks"  => { name => "chart.getHypedTracks", },
    "chart.getLovedTracks"  => { name => "chart.getLovedTracks", },
    "chart.getTopArtists"   => { name => "chart.getTopArtists", },
    "chart.getTopTags"      => { name => "chart.getTopTags", },
    "chart.getTopTracks"    => { name => "chart.getTopTracks", },
    "event.attend" =>
        { name => "event.attend", auth_required => 1, http_method => 'POST' },
    "event.getAttendees" => { name => "event.getAttendees", },
    "event.getInfo"      => { name => "event.getInfo", },
    "event.getShouts"    => { name => "event.getShouts", },
    "event.share" =>
        { name => "event.share", auth_required => 1, http_method => 'POST' },
    "event.shout" =>
        { name => "event.shout", auth_required => 1, http_method => 'POST' },
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
    "library.addAlbum"           => {
        name          => "library.addAlbum",
        auth_required => 1,
        http_method   => 'POST'
    },
    "library.addArtist" => {
        name          => "library.addArtist",
        auth_required => 1,
        http_method   => 'POST'
    },
    "library.addTrack" => {
        name          => "library.addTrack",
        auth_required => 1,
        http_method   => 'POST'
    },
    "library.getAlbums"  => { name => "library.getAlbums", },
    "library.getArtists" => {
        name    => "library.getArtists",
        returns => ['Music::LastFM::Artists'],
    },
    "library.getTracks" => { name => "library.getTracks", },
    "playlist.addTrack" => {
        name          => "playlist.addTrack",
        auth_required => 1,
        http_method   => 'POST'
    },
    "playlist.create" => {
        name          => "playlist.create",
        auth_required => 1,
        http_method   => 'POST'
    },
    "playlist.fetch" => {
        name          => "playlist.fetch",
        auth_required => 1,
        http_method   => 'POST'
    },
    "radio.getPlaylist" => { name => "radio.getPlaylist", },
    "radio.search"      => { name => "radio.search", },
    "radio.tune" =>
        { name => "radio.tune", auth_required => 1, http_method => 'POST' },
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
    "track.addTags"            => {
        name          => "track.addTags",
        auth_required => 1,
        http_method   => 'POST'
    },
    "track.ban" =>
        { name => "track.ban", auth_required => 1, http_method => 'POST' },
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
        { name => "track.love", auth_required => 1, http_method => 'POST' },
    "track.removeTag" => {
        name          => "track.removeTag",
        auth_required => 1,
        http_method   => 'POST'
    },
    "track.scrobble" => {
        name          => "track.scrobble",
        auth_required => 1,
        http_method   => 'POST',
        parse_data    => 0
    },
    "track.search" => { name => "track.search", },
    "track.share" =>
        { name => "track.share", auth_required => 1, http_method => 'POST' },
    "track.unban" =>
        { name => "track.unban", auth_required => 1, http_method => 'POST' },
    "track.unlove" =>
        { name => "track.unlove", auth_required => 1, http_method => 'POST' },
    "track.updateNowPlaying" => {
        name          => "track.updateNowPlaying",
        auth_required => 1,
        http_method   => 'POST',
        parse_data    => 0,
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
        { name => "user.getRecentStations", auth_required => 1, },
    "user.getRecentTracks"       => { name => "user.getRecentTracks", },
    "user.getRecommendedArtists" => { name => "user.getRecommendedArtists", },
    "user.getRecommendedEvents"  => { name => "user.getRecommendedEvents", },
    "user.getShouts"             => { name => "user.getShouts", },
    "user.getTopAlbums"          => { name => "user.getTopAlbums", },
    "user.getTopArtists"         => { name => "user.getTopArtists" },
    "user.getTopTags"            => { name => "user.getTopTags", },
    "user.getTopTracks"          => { name => "user.getTopTracks", },
    "user.getWeeklyAlbumChart"   => { name => "user.getWeeklyAlbumChart", },
    "user.getWeeklyArtistChart"  => { name => "user.getWeeklyArtistChart", },
    "user.getWeeklyChartList"    => { name => "user.getWeeklyChartList", },
    "user.getWeeklyTrackChart"   => { name => "user.getWeeklyTrackChart", },
    "user.shout" =>
        { name => "user.shout", auth_required => 1, http_method => 'POST' },
    "venue.getEvents"     => { name => "venue.getEvents", },
    "venue.getPastEvents" => { name => "venue.getPastEvents", },
    "venue.search" =>
        { name => "venue.search", auth_required => 1, http_method => 'POST' },
);

coerce Method, from Str, via {
    if ( $METHODS{$_} ) {
        'Music::LastFM::Method'->new( %{ $METHODS{$_} } );
    }
};

subtype Methods, as ArrayRef [Method];

coerce Methods, from ArrayRef [Str], via {
    [ map { 'Music::LastFM::Method'->new( %{ $METHODS{$_} } ) } @{$_} ];
};

coerce Methods, from ArrayRef, via {
    [ map { 'Music::LastFM::Method'->new( %{$_} ) } @{$_} ];
};

1;

__END__

=head1 NAME

Music::LastFM::Types::Method - [One line description of module's purpose here]

=head1 VERSION

This document describes Music::LastFM version 0.0.3

=head1 SYNOPSIS

    use Music::LastFM;
  
=head1 DESCRIPTION

Support module for Music::LastFM.

=head1 METHODS

=head2 Constructor

=over

=item new

=head2 Attributes

=head2 Methods

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

See L<Music::LastFM>.

=head1 DEPENDENCIES

See L<Music::LastFM>.

=head1 INCOMPATIBILITIES

See L<Music::LastFM>.

=head1 BUGS AND LIMITATIONS

See L<Music::LastFM>.

=head1 AUTHOR

Edward Allen  C<< <ealleniii_at_cpan_dot_org> >>

=head1 LICENSE

Copyright (c) 2011, Edward Allen C<< <ealleniii_at_cpan_dot_org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
