#!/usr/bin/env perl
use ExtUtils::MakeMaker;
use File::ShareDir::Install;
use strict;

install_share module => 'App::rdapper' => 'locale';

WriteMakefile(
    'NAME'          => 'App::rdapper',
    'VERSION_FROM'  => 'lib/App/rdapper.pm',
    'ABSTRACT_FROM' => 'lib/App/rdapper.pm',
    'AUTHOR'        => [ 'Gavin Brown <gavin.brown@fastmail.uk>' ],
    'LICENSE'       => 'perl_5',
    'EXE_FILES'     => [ 'rdapper' ],

    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker'       => 0,
        'File::ShareDir::Install'   => 0,
    },

    'TEST_REQUIRES' => {
        'Test::More' => 0,
    },

    'PREREQ_PM' => {
        'File::ShareDir'            => 0,
        'File::ShareDir::Install'   => 0,
        'Getopt::Long'              => 0,
        'JSON'                      => 0,
        'List::Util'                => '1.33',
        'Locale::Maketext::Gettext' => 0,
        'Net::ASN'                  => 0,
        'Net::DNS::Domain'          => 0,
        'Net::IDN::Encode'          => 0,
        'Net::IP'                   => 0,
        'Net::RDAP'                 => '0.40',
        'Pod::Usage'                => 0,
        'Term::ANSIColor'           => 0,
        'Term::Size'                => 0,
        'Text::Wrap'                => 0,
        'URI'                       => 0,
        'common::sense'             => 0,
    },

    'META_MERGE' => {
        'meta-spec' => { 'version' => 2 },
         'resources' => {
             'repository' => {
                 'type' => 'git',
                 'url'  => 'https://github.com/gbxyz/rdapper.git',
                 'web'  => 'https://github.com/gbxyz/rdapper',
             },
             'bugtracker' => {
                 'web' => 'https://github.com/gbxyz/rdapper/issues',
             },
         },
    },
);

package MY;
use File::ShareDir::Install qw(postamble);
