#!/usr/bin/perl
use ExtUtils::MakeMaker;
use strict;

my $script = 'rdapper';

WriteMakefile(
	'NAME'		=> $script,
	'VERSION_FROM'	=> $script,
	'EXE_FILES'	=> [ $script ],
	'PREREQ_PM'	=> {
		'Getopt::Long'		=> 0,
		'HTTP::Request::Common' => 0,
		'JSON'			=> 0,
		'LWP'			=> 6.00,
		'MIME::Base64'		=> 0,
		'Mozilla::CA'		=> 0,
		'POSIX'			=> 0,
		'Pod::Usage'		=> 0,
	},
);