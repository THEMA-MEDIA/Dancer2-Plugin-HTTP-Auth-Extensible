use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer2::Plugin::HTTP::Auth::Extensible',
    AUTHOR              => q{Theo van Hoesel <Th.J.v.Hoesel@THEMA-MEDIA.nl>},
    VERSION_FROM        => 'lib/Dancer2/Plugin/HTTP/Auth/Extensible.pm',
    ABSTRACT_FROM       => 'lib/Dancer2/Plugin/HTTP/Auth/Extensible.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Mock::Quick' => 0,
        'Dancer2'     => 0,
        'Dancer2::Plugin::Auth::Extensible' => 0,
        'Crypt::SaltedHash' => 0,
        'HTTP::Headers::ActionPack' => 0,
        'YAML'       => 0, # for config files (TODO: make optional?)
        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer2-Plugin-HTTP-Auth-Extensible-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/THEMA-MEDIA/Dancer2-Plugin-HTTP-Auth-Extensible',
            bugtracker => 'https://github.com/THEMA-MEDIA/Dancer2-Plugin-HTTP-Auth-Extensible/issues',
            homepage   => 'https://github.com/THEMA-MEDIA/Dancer2-Plugin-HTTP-Auth-Extensible/',
        },
    },

);
