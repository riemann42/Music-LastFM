package Music::LastFM;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

use Moose;
use Music::LastFM::Types qw(Logger Int Str Cache);
use Music::LastFM::Meta::EasyAcc;

use Music::LastFM::Agent;
use Music::LastFM::SessionCache;
use Cache::FileCache;
use Log::Dispatch;

has username => (
    reader        => '_username',
    isa           => Str,
    required      => 1,
    documentation => 'This is the username for authenticated requests.'
);

has api_key => (
    reader         => '_api_key',
    isa           => Str,
    required      => 1,
    documentation => 'The API Key provided to you by LastFM'
);

has api_secret => (
    reader   => '_api_secret',
    isa      => Str,
    required => 1,
    documentation =>
        'The API Secret provided to you by LastFM.  Used to sign requests, so keep it secret.'
);


has session_cache => (
    is      => 'ro',
    isa     => Str,
    default => $ENV{HOME} . "/.music-lastfm-sessions",
    documentation =>
        'A filename to store session keys in.  Session Keys have an unlimited lifetime, so storing them is a good idea.'
);

has scrobble_queue => (
    is            => 'ro',
    isa           => Str,
    default       => $ENV{HOME} . "/.music-lastfm-queue",
    documentation => 'A filename to store scrobbles in before submitting'
);
has logfile => (
    is  => 'ro',
    isa => Str,
    documentation =>
        'Log file location to log requests and responses for debugging'
);
has cache_time => (
    is            => 'ro',
    isa           => Int,
    default       => 18000,
    documentation => 'Amount of time to cache LastFM responses'
);
has url => (
    reader        => '_url',
    isa           => Str,
    default       => 'http://ws.audioscrobbler.com/2.0/',
    documentation => 'The URL for the LastFM webservice'
);


has 'cache' => (
    reader => '_cache',
    lazy    => 1,
    isa     => Cache,
    default => sub {
        my $self = shift;
        return Cache::FileCache->new(
            {   namespace          => __PACKAGE__,
                default_expires_in => $self->cache_time
            }
        );
    },
    clearer =>'_no_cache',
    documentation => 'This object is used to cache JSON responses from the LastFM Web Service. Defaults to Cache::Filecache, using the cache_time attribute to determine amount of time to cache objects.  This can be cleared with no_cache.'
);


has sessioncache => (
    reader  => '_sessioncache',
    isa     => Cache,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Music::LastFM::SessionCache->new(
            filename => $self->session_cache );
    },
    documentation =>
        'This is the object used to store authenticated sessions in.  Defaults to a <L:Music::LastFM::SessionCache> object, using the session_cache attribute as the file',
);


has logger => (
    reader  => "_logger",
    isa     => Logger,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @outputs = [ 'Screen', min_level => 'warning' ];
        if ( $self->logfile ) {
            push @outputs, [
                'File',
                min_level => 'debug',
                filename  => $self->logfile,
                mode      => '>>',

            ];
        }
        Log::Dispatch->new(
            outputs   => \@outputs,
            callbacks => sub {
                my %p = @_;
                my @t = localtime();
                return sprintf(
                    '[%04d-%02d-%02d %02d:%02d:%02d] %-9s %s',
                    $t[5] + 1900,
                    $t[4] + 1,
                    $t[3], $t[2], $t[1], $t[0], $p{level}, $p{message}
                ) . "\n";
            }
        );
    },
    documentation => 'This is the object used for logging.  The default is a Log::Dispatch object.  If the logfile attribute is set, items are logged to this file.  Any object with debug, info, error, and critical methods can be used here.'
);

sub BUILD {
    my $self = shift;
    Music::LastFM::Agent->initialize(
        url          => $self->_url,
        api_key      => $self->_api_key,
        api_secret   => $self->_api_secret,
        username     => $self->_username,
        cache        => $self->_cache,
        sessioncache => $self->_sessioncache,
        logger       => $self->_logger,
    );
}

sub agent { return Music::LastFM::Agent->instance; }

sub query { shift->agent->query(@_); }

sub logger { shift->agent->logger(@_); }
sub cache { shift->agent->cache(@_); }
sub sessioncache { shift->agent->sessioncache(@_); }
sub url { shift->agent->url(@_); }
sub api_secret { shift->agent->api_secret(@_); }
sub username { shift->agent->username(@_); }
sub api_key { shift->agent->api_key(@_); }
sub no_cache { shift->agent->no_cache; }

sub set_logger { shift->agent->set_logger(@_); }
sub set_cache { shift->agent->set_cache(@_); }
sub set_sessioncache { shift->agent->set_sessioncache(@_); }
sub set_api_secret { shift->agent->set_api_secret(@_); }
sub set_url { shift->agent->set_url(@_); }
sub set_api_key { shift->agent->set_api_key(@_); }
sub set_username { shift->agent->set_username(@_); }

sub has_logger { shift->agent->has_logger(@_); }
sub has_cache { shift->agent->has_cache(@_); }
sub has_sessioncache { shift->agent->has_sessioncache(@_); }
sub has_api_secret { shift->agent->has_api_secret(@_); }
sub has_url { shift->agent->has_url(@_); }
sub has_api_key { shift->agent->has_api_key(@_); }
sub has_username { shift->agent->has_username(@_); }

sub artist { return Music::LastFM::Object::Artist->new(agent => shift->agent, @_); }
sub album  { return Music::LastFM::Object::Album->new( agent => shift->agent, @_); }
sub track  { return Music::LastFM::Object::Track->new( agent => shift->agent, @_); }
sub event  { return Music::LastFM::Object::Event->new( agent => shift->agent, @_); }
sub venue  { return Music::LastFM::Object::Venue->new( agent => shift->agent, @_); }
sub tag    { return Music::LastFM::Object::Tag->new(   agent => shift->agent, @_); }
sub user   { return Music::LastFM::Object::User->new(  agent => shift->agent, @_); }


__PACKAGE__->meta->make_immutable;
1;    # Magic true value required at end of module
__END__

=head1 NAME

Music::LastFM - [One line description of module's purpose here]


=head1 VERSION

This document describes Music::LastFM version 0.0.3


=head1 SYNOPSIS

    use Music::LastFM;
  
=head1 DESCRIPTION

Music::LastFM is an object-based module for working with the LastFM 2.0 API.  This module requires an API key from LastFM to work.

Music::LastFM is a factory module for Music::LastFM::Agent, and various Music::LastFM::XXX objects.  

A new Music::LastFM object generates a Music::LastFM::Agent singleton if it does not exists already.  This singleton is used to communicate with the 
LastFM servers, and generate a Music::LastFM::Response object.  The data in this object can be accessed via the 'data' method.  

The Music::LastFM::Agent object does not need to be explicitly accessed, however.  Music::LastFM::XXX Objects will query LastFM automatically when
you request data that has not been set.  For example:

    my $artist = $lfm->artist(name => 'Sarah Slean');
    print "$artist: ", $artist->mbid(), "\n";

will print 

    Sarah Slean: CA6FB0DE-336F-4BD9-ADF1-CE8EEBAA7FE1

This example demonstrates how object overloading works, and automatic data gathering.  


=head1 METHODS

=head2 Constructor

=over

=item new

   my $lfm = Music::LastFM->new(
        api_key => "MY_API_KEY_PROVIDED_BY_LASTFM",
        api_secret => "MY_API_SECRET_ABLE_TO_SIGN_REQUEST",
        username => "iAmCool",
   )

This creates a new Music::LastFM object.  The options provided are used to create the Music::LastFM singleton if it doesn't already exist.

The attributes can be any of the attributes listed below.

=head2 Attributes

=over

=item api_key has_api_key REQUIRED

The API Key provided to you by LastFM.

=item api_secret has_api_secret REQUIRED

The API Secret provided to you by LastFM.  Used to sign requests, so keep it secret.

=item username has_username REQUIRED

This is the username for authenticated requests.

=item cache has_cache 

Default: A Cache::FileCache object

This object is used to cache JSON responses from the LastFM Web Service. Defaults to Cache::FileCache, using the cache_time attribute to determine amount of time to cache objects.  This can be cleared with no_cache, or disabled by setting cache_time to 0.

=item cache_time has_cache_time 

Default: 18000

Amount of time to cache LastFM responses.

=item logfile has_logfile 

Log file location to log requests and responses for debugging

=item logger has_logger 

Default: Generated Automatically

This is the object used for logging.  The default is a Log::Dispatch object.  If the logfile attribute is set, items are logged to this file.  Any object with debug, info, error, and critical methods can be used here.

=item scrobble_queue has_scrobble_queue 

Default: /home/mythtv/.music-lastfm-queue

A filename to store scrobbles in before submitting

=item session_cache has_session_cache 

Default: /home/mythtv/.music-lastfm-sessions

A filename to store session keys in.  Session Keys have an unlimited lifetime, so storing them is a good idea.

=item sessioncache has_sessioncache 

Default: Generated Automatically

This is the object used to store authenticated sessions in.  Defaults to a <L:Music::LastFM::SessionCache> object, using the session_cache attribute as the file

=item url has_url 

Default: http://ws.audioscrobbler.com/2.0/

The URL for the LastFM webservice

=back

=head2 Convenience Methods

=over
 
=item agent

Return a shortcut to the agent singleton.

=item artist album track tag event venue user

Generate a new blank Music::LastFM::Object::Artist, Album, Track, Tag, Event, Venue or User object.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Music::LastFM requires no configuration files or environment variables.

=head1 DEPENDENCIES


=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-music-lastfm@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Edward Allen  C<< <ealleniii_at_cpan_dot_org> >>

=head1 LICENCE AND COPYRIGHT

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


