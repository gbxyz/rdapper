#!/usr/bin/perl
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	'NAME'		=> 'rdapper',
	'VERSION_FROM'	=> 'rdapper',
	'ABSTRACT_FROM'	=> 'rdapper',
	'AUTHOR'	=> [ 'Gavin Brown <gavin.brown@centralnic.com>' ],
	'LICENSE'	=> 'perl',
	'EXE_FILES'	=> [ 'rdapper' ],
	'PREREQ_PM'	=> {
		'Getopt::Long'		=> 0,
		'List::MoreUtils'	=> 0,
		'Net::ASN'		=> 0,
		'Net::DNS::Domain'	=> 0,
		'Net::IP'		=> 0,
		'Net::RDAP'		=> 0,
		'Term::ANSIColor'	=> 0,
	},
);
