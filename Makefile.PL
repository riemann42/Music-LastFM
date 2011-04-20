use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Music::LastFM',
    AUTHOR              => 'Edward Allen <ealleniii_at_cpan_dot_org>',
    VERSION_FROM        => 'lib/Music/LastFM.pm',
    ABSTRACT_FROM       => 'lib/Music/LastFM.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Music-LastFM-*' },
);
