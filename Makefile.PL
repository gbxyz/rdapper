#!perl
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	'NAME'			=> 'App::rdapper',
	'VERSION_FROM'	=> 'lib/App/rdapper.pm',
	'ABSTRACT_FROM'	=> 'lib/App/rdapper.pm',
	'AUTHOR'		=> [ 'Gavin Brown <gavin.brown@fastmail.uk>' ],
	'LICENSE'		=> 'perl_5',
	'EXE_FILES'		=> [ 'rdapper' ],
	'PREREQ_PM'		=> {
        'Getopt::Long'      => 0,
        'JSON'              => 0,
        'List::Util'        => '1.33',
        'Net::ASN'          => 0,
        'Net::DNS::Domain'  => 0,
        'Net::IDN::Encode'  => 0,
        'Net::IP'           => 0,
        'Net::RDAP'         => '0.35',
        'Pod::Usage'        => 0,
        'Term::ANSIColor'   => 0,
        'Term::Size'        => 0,
        'Text::Wrap'        => 0,
        'URI'               => 0,
	},
	'META_MERGE' 	=> {
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
