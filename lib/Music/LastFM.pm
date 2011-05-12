package Music::LastFM;

use warnings;
use strict;
use Carp;
use utf8;

use version; our $VERSION = qv('0.0.3');

# Use inside out for this, as messing with this is a Bad IdeaTM.
use MooseX::InsideOut;
use Music::LastFM::Types qw(Int Str Cache);
use Music::LastFM::Meta::EasyAcc;

use Music::LastFM::Agent;
use Music::LastFM::SessionCache;
use Music::LastFM::Config;
use Music::LastFM::ScrobbleQueue;
use Music::LastFM::Scrobble;
use Cache::FileCache;
use Log::Dispatch;
use Module::Load;


# Should this all just be a subclass of the agent?

has api_key => (
    reader        => '_api_key',
    writer        => '_set__api_key',
    predicate     => '_has__api_key',
    isa           => Str,
    documentation => 'The API Key provided to you by LastFM',
);

has api_secret => (
    reader    => '_api_secret',
    writer    => '_set__api_secret',
    predicate => '_has__api_secret',
    isa       => Str,
    documentation =>
        'The API Secret provided to you by LastFM.  Used to sign requests, so keep it secret.',
);

has username => (
    reader        => '_username',
    writer        => '_set__username',
    predicate     => '_has__username',
    isa           => Str,
    documentation => q{The default username for authenticated requests.},
);

has scrobble_queue_filename => (
    is            => 'ro',
    isa           => Str,
    default       => $ENV{HOME} . '/.music-lastfm-queue',
    documentation => 'A filename to store scrobbles in before submitting',
);

has scrobble => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Music::LastFM::Scrobble->new(
            agent  => $self->agent,
            logger => $self->_logger,
            queue  => Music::LastFM::ScrobbleQueue->new(
                filename => $self->scrobble_queue_filename,
                logger   => $self->_logger,
            )
        );
    },
    handles => [
        qw(
            monitor_playback
            now_playing
            scrobble_track
            )
    ],

);

has log_filename => (
    is        => 'ro',
    writer    => '_set__log_filename',
    predicate => '_has__log_filename',
    isa       => Str,
    documentation =>
        'Log file location to log requests and responses for debugging',
);

sub has_log_filename {
    goto &_has__log_filename;
}

has config_filename => (
    is            => 'ro',
    isa           => Str,
    documentation => 'Filename for the config location',
);

has cache_time => (
    isa     => Int,
    reader  => '_cache_time',
    default => 604_800,         # One week per LastFM API terms.
    documentation => 'Amount of time to cache LastFM responses',
);

has url => (
    reader        => '_url',
    writer        => '_set__url',
    predicate     => '_has__url',
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
        'This is the object used to store authenticated sessions in.  Defaults to a <L:Music::LastFM::SessionCache> object.',
);

sub _session_cache_default {
    my $self = shift;
    if ($self->has_config_filename) {
        return Music::LastFM::SessionCache->new( config => $self->config );
    }
    return undef;
}

has logger => (
    reader => '_logger',

    #    isa       => 'Music::LastFM::Types::Logger',
    builder   => '_logger_default',
    predicate => '_has_logger',
    lazy      => 1,
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
    if ( $self->_has_logger ) {
        Music::LastFM::Logger->initialize( logger => $self->_logger );
    }
    if ( $self->has_config_filename ) {
        Music::LastFM::Config->initialize(
            filename => $self->config_filename );
        my $options = Music::LastFM::Config->instance();
        for my $attrib (qw(api_key api_secret url log_filename username)) {
            my $writer = '_set__' . $attrib;
            my $reader = '_has__' . $attrib;
            if ( ( !$self->$reader ) && ( $options->get_option($attrib) ) ) {
                $self->$writer( $options->get_option($attrib) );
            }
        }
    }
    if ( !$self->_has__api_key ) {
        Music::LastFM::Exception->throw('Required option api_key not set');
    }
    my %agent_ops = (
        url           => $self->_url,
        api_key       => $self->_api_key,
        cache         => $self->_cache,
        logger        => $self->_logger,
    );
    if ($self->has_config_filename) {
        $agent_ops{session_cache} = $self->_session_cache;
    }
    Music::LastFM::Agent->initialize(%agent_ops);
    if ( $self->_has__api_secret ) {
        $self->agent->set_api_secret( $self->_api_secret );
    }
    if ( $self->_has__username ) {
        $self->agent->set_username( $self->_username );
    }
    return;
}

has 'agent' => (
    is        => 'ro',
    lazy      => 1,
    predicate => 'has_agent',
    default   => sub { Music::LastFM::Agent->instance },
    handles   => [
        qw(
            api_key         set_api_key        has_api_key
            api_secret      set_api_secret     has_api_secret
            cache           set_cache          has_cache
            no_cache
            cache_time      set_cache_time     has_cache_time
            lwp_ua          set_lwp_ua         has_lwp_ua
            rate_limit      set_rate_limit     has_rate_limit
            session_cache   set_session_cache  has_session_cache
            url             set_url            has_url
            username        set_username       has_username
            query           logger
            )
    ],
);

sub config { return Music::LastFM::Config->instance; }

do {
    my $package_meta = __PACKAGE__->meta();
    my $agent_meta   = Class::MOP::Class->initialize('Music::LastFM::Agent');

    my $object_base = 'Music::LastFM::Object::';

    # Consider using a plugin model for this?  Am I overthinking it?
    for my $object_type (qw(Artist Album Track Event Venue Tag User)) {
        my $package_name = $object_base . $object_type;
        load($package_name);
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

Music::LastFM - Moose Framework for LastFM 2.0 API


=head1 VERSION

This document describes Music::LastFM version 0.0.3


=head1 SYNOPSIS

=for test

=for test "synopsis" begin

    use Music::LastFM;
    use strict;

    # Create a new lfm object
    my $lfm = Music::LastFM->new(
        api_key => "MY_API_KEY_PROVIDED_BY_LASTFM",
        api_secret => "MY_API_SECRET_ABLE_TO_SIGN_REQUEST",
        username => "iAmCool",
    );

    # This will return a Music::LastFM::Response object
    my $response = $lfm->query(method  => 'artist.getInfo', 
                               options => { artist => 'Amy Kuney' });


    # This will return a Music::LastFM::Object::Artist object if all goes
    # according to plan.
    my $artist = $response->data();

    # This will run a query for you and return an ArrayRef of Artists
    my $similar = $artist->similar();

    # This will recurse it for most similar artist:

    my @artists = ();
    push @artists, @{$similar};
    push @artists, @{$similar->[0]->similar()};

    print join("\n", @artists);


=begin test

    return { 
        lfm => $lfm, 
        artist => $artist, 
        similar => $similar, 
        artists => \@artists 
           };

=end test

=for test "synopsis" end

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

=back

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

=head1 SHOULD I USE THIS MODULE?

Maybe.  It is written using Moose 2, which is still shiny and new.  This adds
a significant delay at compile time.  This should not be used in a script
which needs to run very quickly (e.g. CGI).

Also, it does a heck of a lot for you.  You may not need that.  If you review
L<Net::LastFM> you will find a much smaller module which may be what you need.

Here are some things that L<Music::LastFM> can do for you:

=over

=item *

Make scrobbling easier.  All the work is done for you, except querying your player.

=item *

Make chained calls (such as all the artists by all your neighbors) easy.

=item *

Provide a class infrastructure that can be inhereted and used to integrate
LastFM seamlessly into a larger system.

=item *

Provide a robust error checking infrastructure.

=item *

Provide basic infrastructure for Caching, and other LastFM best practieces.

=back

All these features do have a cost, however.  These include:

=over

=item *

Larger code base means much more likely to have far more bugs.

=item *

Long compile time

=item *

Heavy handed design which may cramp your style.

=back

Please keep these things in mind before using this module, and before flaming
me for writing this monstrousity.  Don't say I didn't warn you.

=head1 SYSTEM OVERVIEW

This is a L<Moose> 2.0 based module. There are several objects that are part
of the overall system.  I am realtivly new to Moose, so please be kind and
send bug reports, critiques, etc via CPAN.

This system is designed to be used in a way that allows you to only use the
pieces you need to get the job done. If you already have a logging system,
and a Database system, then you can use these, instead of the ones provided
here.

=head2 Request process

=head2 Components

To make sense of the relationship of the modules, I will list them here:

=over

=item L<Music::LastFM>

This is the main module.  This module is designed to provide a good
configuration and collection of support modules.

=item L<Music::LastFM::Agent>

This module does all the work.  It provides a singleton object.  It may make
sense in your use case to initialize this module and call it directly.  This
is true especially if you overwrite several other objects, and want to make
sure that junk you don't need isn't created.

=item L<Music::LastFM::Config>

This module provides a basic config Singleton using Config::Std.  The config allows
several options to be set in an INI type config file and passed to
Music::LastFM::Agent when initialize.

=item L<Music::LastFM::Exception>

This is a L<Exception::Class> based module that provides the Exception objects
passed when an exception occurs.

=item L<Music::LastFM::Logger>

This is a very basic wrapper module that allows you to create a singleton for
your logger.

=item L<Music::LastFM::Method>

This is the object class for all LastFM api methods.  Objects in this class
are usually coerced from a string with the method name.  The coercions are set
in L<Music::LastFM::Types:Method>.

=item L<Music::LastFM::Object>

Base class for all objects in response data and request data.

=over

=item L<Music::LastFM::Object::Album>

=item L<Music::LastFM::Object::Artist>

If a response contains artist data, it is coerced into this.  Also, this
object can be used to make requests back to the service.

Example of using it to make requests:

=for test "artist" begin

    my $artist = $lfm->new_artist(name => 'U2');
    if ($artist->check) {
        print $artist->bio->{content}
    }


=item L<Music::LastFM::Object::Event>

=item L<Music::LastFM::Object::Tag>

=item L<Music::LastFM::Object::Track>

=item L<Music::LastFM::Object::User>

=item L<Music::LastFM::Object::Venue>

=back

=item L<Music::LastFM::Response>

This object is returned by the agent.  It is responsible for object creation.
If you would like to use different classes or subclasses of the Object classes
for reponse data, there is a class Attribute 'expects' which can be revised to
use your methods instead of the defaults.

=item L<Music::LastFM::Scrobble>

This is the module responsible for all Scrobbling

=item L<Music::LastFM::ScrobbleQueue>

This is a very simple queue based on L<File::Queue>. This may be a good
canidate to replace in a larger system with a relational database.  

=item L<Music::LastFM::SessionCache>

This is an extremly simple method of saving session keys.  It simply uses the
=item L<Music::LastFM::Config> singleton to store them to the config file.

Because session keys, along with your api_secret enable you to make
authenticated requests, keeping these in a secure location is encouraged.  One
way to do this would be to replace L<Music::LastFM::Config> with a secure
database call and bring this along for the ride.  

=item L<Music::LastFM::Types>

This is a collection module used to import types internally.

=over

=item L<Music::LastFM::Types::Country>

Used for the country type

=item L<Music::LastFM::Types::LastFM>

This is where most of the internally used types hide.

=item L<Music::LastFM::Types::Method>

This is where all the main coercion changing method strings to method objects
happens.  This is where a new API method needs to be placed.

=item L<Music::LastFM::Types::Objects::Country>

This is copied from an example by MORIYA Masaki (守屋 雅樹) for MooseX::Types::Locale::Country.

=item L<Music::LastFM::Meta::EasyAcc>

This is a rip from L<MooseX::FollowPBP> to make accessor generation easier.

=over

=item L<Music::LastFM::Meta::EasyAcc::Role::Attribute>

Supporting role for L<Music::LastFM::Meta::EasyAcc>

=back

=item L<Music::LastFM::Meta::LastFM>

This is a Moose extension that provides sugar for configuring objects.

=over

=item L<Music::LastFM::Meta::LastFM::Role::Attribute>

=item L<Music::LastFM::Meta::LastFM::Role::Class>

=item L<Music::LastFM::Meta::LastFM::Role::LastFM>

=item L<Music::LastFM::Meta::LastFM::Role::Object>

=back

=back

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Music::LastFM requires no configuration files or environment variables.

=head1 DEPENDENCIES

This module was designed as a framework for larger Moose projects.  Therefore,
it requires Moose and several CPAN MooseX extensions. 

=over


=item Perl 5.8 or newer.  May work on 5.6, but I doubt it.

=item L<version> 0.77

=item L<Cache::Cache> 

=item L<Config::Std> 

=item L<Data::Util> 0.57

=item L<File::Queue> 1.01

=item L<JSON> 2.00

=item L<Log::Dispatch> 

=item L<Moose> 2.0006

=item L<MooseX::Aliases> 0.09

=item L<MooseX::InsideOut> 0.106

=item L<MooseX::Params::Validate> 0.16

=item L<MooseX::Role::WithOverloading> 0.09

=item L<MooseX::Singleton> 0.26

=item L<MooseX::Types> 0.25

=item L<MooseX::Types::DateTimeX> 0.06

=item L<MooseX::Types::Locale::Country> 0.04

=item L<MooseX::Types::Structured> 0.23

=item L<MooseX::Types::UUID> 0.02

=item L<MooseX::Types::URI> 0.02

=item L<MooseX::Types::LWP::UserAgent> 0.02

=item L<namespace::autoclean> 

=item L<Readonly> 1.03

=item L<Module::Load> 

=item L<version> 0.77

=item L<LWP> 

=item L<Exception::Class> 

=back

Some of the above modules are only required for the default config.  These
include:

=over

=item L<Cache::Cache> 

=item L<Config::Std> 

=item L<File::Queue> 

=item L<Log::Dispatch> 

=back

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


