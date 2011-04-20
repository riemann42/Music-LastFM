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
    },
    add_to_cleanup      => [ 'Music-LastFM-*' ],
);

$builder->create_build_script();
