use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Music::LastFM',
    license             => 'perl',
    dist_author         => 'Edward Allen <ealleniii_at_cpan_dot_org>',
    dist_version_from   => 'lib/Music/LastFM.pm',
    requires => {
        'version'    => 0.77,
        'Cache::Cache' => 0,
        'Config::Std' => 0,
        'Data::Util' => 0.57,
        'File::Queue' => 1.01,
        'JSON' => 2.00,
        'Log::Dispatch' => 0,
        'Moose' => 2.0000,
        'MooseX::Aliases' => 0.09,
        'MooseX::InsideOut' => 0.106,
        'MooseX::Params::Validate' => 0.16,
        'MooseX::Role::WithOverloading' => 0.09,
        'MooseX::Singleton' => 0.26,
        'MooseX::Types' => 0.25,
        'MooseX::Types::DateTimeX' => 0.06,
        'MooseX::Types::Locale::Country' => 0.04,
        'MooseX::Types::Structured' => 0.23,
        'MooseX::Types::UUID' => 0.02,
        'MooseX::Types::URI' => 0.02,
        'MooseX::Types::LWP::UserAgent' => 0.02,
        'namespace::autoclean' => 0,
        'Readonly' => 1.03,
        'Module::Load' => 0,
        'version' => 0.77,
        'LWP' => 0,
        'Exception::Class' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'TAP::Harness' => 0,
    },
    use_tap_harness => 1,
    create_license => 1,
    release_status => 'unstable',
    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'Music-LastFM-*' ],
);

$builder->create_build_script();
