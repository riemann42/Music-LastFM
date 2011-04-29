package Music::LastFM;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

# Use inside out for this, as messing with this is a Bad IdeaTM.
use MooseX::InsideOut;
use Music::LastFM::Types qw(Logger Int Str Cache);
use Music::LastFM::Meta::EasyAcc;

use Music::LastFM::Agent;
use Music::LastFM::SessionCache;
use Cache::FileCache;
use Log::Dispatch;

# Should this all just be a subclass of the agent?

has username => (
    reader        => '_username',
    isa           => Str,
    required      => 1,
    documentation => 'This is the username for authenticated requests.',
);

has api_key => (
    reader        => '_api_key',
    isa           => Str,
    required      => 1,
    documentation => 'The API Key provided to you by LastFM',
);

has api_secret => (
    reader   => '_api_secret',
    isa      => Str,
    required => 1,
    documentation =>
        'The API Secret provided to you by LastFM.  Used to sign requests, so keep it secret.',
);

has session_cache_filename => (
    is      => 'ro',
    isa     => Str,
    default => $ENV{HOME} . '/.music-lastfm-sessions',
    documentation =>
        'A filename to store session keys in.  Session Keys have an unlimited lifetime, so storing them is a good idea.',
);

has scrobble_queue_filename => (
    is            => 'ro',
    isa           => Str,
    default       => $ENV{HOME} . '/.music-lastfm-queue',
    documentation => 'A filename to store scrobbles in before submitting',
);
has log_filename => (
    is  => 'ro',
    isa => Str,
    documentation =>
        'Log file location to log requests and responses for debugging',
);
has cache_time => (
    isa           => Int,
    reader        => '_cache_time',
    default       => 18_000,
    documentation => 'Amount of time to cache LastFM responses',
);
has url => (
    reader        => '_url',
    isa           => Str,
    default       => 'http://ws.audioscrobbler.com/2.0/',
    documentation => 'The URL for the LastFM webservice',
);

has 'cache' => (
    reader  => '_cache',
    lazy    => 1,
    isa     => Cache,
    builder => '_cache_default',
    documentation =>
        'This object is used to cache JSON responses from the LastFM Web Service. Defaults to Cache::Filecache, using the cache_time attribute to determine amount of time to cache objects.  This can be cleared with no_cache.',
);

sub _cache_default {
    my $self = shift;
    return Cache::FileCache->new(
        {   namespace          => __PACKAGE__,
            default_expires_in => $self->_cache_time
        }
    );
}

has session_cache => (
    reader  => '_session_cache',
    isa     => Cache,
    lazy    => 1,
    builder => '_session_cache_default',
    documentation =>
        'This is the object used to store authenticated sessions in.  Defaults to a <L:Music::LastFM::SessionCache> object, using the session_cache_filename attribute as the file',
);

sub _session_cache_default {
    my $self = shift;
    return Music::LastFM::SessionCache->new(
        filename => $self->session_cache_filename );
}

has logger => (
    reader  => '_logger',
    isa     => Logger,
    builder => '_logger_default',
    predicate => '_has_logger',
    lazy    => 1,
    documentation =>
        'This is the object used for logging.  The default is a Log::Dispatch object.  If the log_filename attribute is set, items are logged to this file.  Any object with debug, info, error, and critical methods can be used here.',
);

sub _logger_default {
    my $self = shift;
    my @outputs = ( [ 'Screen', min_level => 'warning' ] );
    if ( $self->has_log_filename ) {
        push @outputs, [
            'File',
            min_level => 'debug',
            filename  => $self->log_filename,
            mode      => '>>',

        ];
    }
    return Log::Dispatch->new(
        outputs   => \@outputs,
        callbacks => sub {
            my %p = @_;
            my @t = localtime;
            ## no critic (ProhibitMagicNumbers)
            return sprintf(
                '[%04d-%02d-%02d %02d:%02d:%02d] %-9s %s',
                $t[5] + 1900,
                $t[4] + 1,
                $t[3], $t[2], $t[1], $t[0], $p{level}, $p{message}
            ) . "\n";
            ## use critic
        }
    );
}

sub BUILD {
    my $self = shift;
    if ($self->_has_logger) {
        Music::LastFM::Logger->initialize(logger => $self->_logger);
    }
    Music::LastFM::Agent->initialize(
        url           => $self->_url,
        api_key       => $self->_api_key,
        api_secret    => $self->_api_secret,
        username      => $self->_username,
        cache         => $self->_cache,
        session_cache => $self->_session_cache,
        logger        => $self->_logger,
    );
    return;
}

sub agent { return Music::LastFM::Agent->instance; }
## no critic (Subroutines::RequireArgUnpacking)
sub query { return shift->agent->query(@_); }
## use critic
do {
    my $package_meta = __PACKAGE__->meta();
    my $agent_meta   = Class::MOP::Class->initialize('Music::LastFM::Agent');
    for my $agent_attribute ( $agent_meta->get_all_attributes() ) {
    METHOD:
        for my $attribute_method_name (
            $agent_attribute->associated_methods() ) {

            # my $attribute_method_name = $attribute_method->name();
            next METHOD if ( $attribute_method_name =~ m{ \A _ }xms );

            # TODO : Check for collision with __PACKAGE__ namespace!
            $package_meta->add_method( $agent_attribute->name,
                sub { shift->agent->$attribute_method_name() } );
        }
    }

    my $object_base = 'Music::LastFM::Object::';
    for my $object_type (qw(Artist Album Track Event Venue Tag User)) {
        my $package_name = $object_base . $object_type;

        #        require $package_name;
        $package_meta->add_method(
            'new_' . lc($object_type),
            sub {
                return $package_name->new( agent => shift->agent, @_ );
            },
        );
    }
};

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

    my $artist = $lfm->new_artist(name => 'Sarah Slean');
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

=item log_filename has_log_filename 

Log file location to log requests and responses for debugging

=item logger has_logger 

Default: Generated Automatically

This is the object used for logging.  The default is a Log::Dispatch object.  If the log_filename attribute is set, items are logged to this file.  Any object with debug, info, error, and critical methods can be used here.

=item scrobble_queue_filename has_scrobble_queue_filename 

Default: /home/mythtv/.music-lastfm-queue

A filename to store scrobbles in before submitting

=item session_cache has_session_cache 

Default: /home/mythtv/.music-lastfm-sessions

A filename to store session keys in.  Session Keys have an unlimited lifetime, so storing them is a good idea.

=item session_cache has_session_cache 

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

=item new_artist new_album new_track new_tag new_event new_venue new_user

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


