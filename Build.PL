use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Music::LastFM',
    license             => 'perl',
    dist_author         => 'Edward Allen <ealleniii_at_cpan_dot_org>',
    dist_version_from   => 'lib/Music/LastFM.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Cache::FileCache' => 0,
        'Config::Std' => 0,
        'Data::Util' => 0,
        'File::Queue' => 0,
        'JSON' => 0,
        'Log::Dispatch' => 0,
        'Moose' => 2,
        'MooseX::Aliases' => 0,
        'MooseX::InsideOut' => 0,
        'MooseX::Params::Validate' => 0,
        'MooseX::Role::WithOverloading' => 0,
        'MooseX::Singleton' => 0,
        'MooseX::Types' => 0,
        'MooseX::Types::DateTimeX' => 0,
        'MooseX::Types::Locale::Country' => 0,
        'MooseX::Types::Structured' => 0,
        'MooseX::Types::UUID' => 0,
        'MooseX::Types::URI' => 0,
        'MooseX::Types::LWP::UserAgent' => 0,
        'namespace::autoclean' => 0,
        'Readonly' => 0,
        'Module::Load' => 0,
        'version' => 0,
    },
    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'Music-LastFM-*' ],
);

$builder->create_build_script();
