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
    is            => 'ro',
    isa           => Str,
    required      => 1,
    writer        => '_set_username',
    documentation => 'This is the username for authenticated requests.'
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
has api_key => (
    is            => 'ro',
    isa           => Str,
    required      => 1,
    documentation => 'The API Key provided to you by LastFM'
);
has api_secret => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    documentation =>
        'The API Secret provided to you by LastFM.  Used to sign requests, so keep it secret.'
);
has url => (
    is            => 'ro',
    isa           => Str,
    default       => 'http://ws.audioscrobbler.com/2.0/',
    documentation => 'The URL for the LastFM webservice'
);

has 'cache' => (
    is      => 'ro',
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
    documentation => 'This object is used to cache JSON responses from the LastFM Web Service. Defaults to Cache::Filecache, using the cache_time attribute to determine amount of time to cache objects.  This can be cleared with no_cache, or disabled by setting cache_time to 0.'
);


has sessioncache => (
    is      => 'ro',
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
    is      => "ro",
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
        url          => $self->url,
        api_key      => $self->api_key,
        api_secret   => $self->api_secret,
        username     => $self->username,
        cache        => $self->cache,
        cache_time   => $self->cache_time,
        sessioncache => $self->sessioncache,
        logger       => $self->logger,
    );
}

sub agent {
    return Music::LastFM::Agent->instance;
}

sub query {
    my $self = shift;
    $self->agent->query(@_);
}

sub set_username {
    my $self     = shift;
    my $username = shift;
    $self->agent->set_username($username);
    $self->_set_username($username);
}

sub no_cache {
    my $self = shift;
    $self->agent->no_cache;
    $self->_no_cache;
}

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
    print $artist . ": ". $artist->mbid();

will print 

    Sarah Slean: CA6FB0DE-336F-4BD9-ADF1-CE8EEBAA7FE1

This example demonstrates how object overloading works, and automatic data gathering.  


=head1 METHODS=item api_key has_api_key REQUIRED

The API Key provided to you by LastFM

=item api_secret has_api_secret REQUIRED

The API Secret provided to you by LastFM.  Used to sign requests, so keep it secret.

=item cache has_cache 

Default: Generated Automatically

This object is used to cache JSON responses from the LastFM Web Service. Defaults to Cache::Filecache, using the cache_time attribute to determine amount of time to cache objects.  This can be cleared with no_cache, or disabled by setting cache_time to 0.

=item cache_time has_cache_time 

Default: 18000

Amount of time to cache LastFM responses

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

=item username has_username REQUIRED

This is the username for authenticated requests.

 

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


