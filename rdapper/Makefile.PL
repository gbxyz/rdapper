#!/usr/bin/perl
use ExtUtils::MakeMaker;
use strict;

my $script = 'rdapper';

WriteMakefile(
	'NAME'		=> $script,
	'VERSION_FROM'	=> $script,
	'EXE_FILES'	=> [$script],
	'PREREQ_PM'	=> {
		'LWP'			=> 0,
		'HTTP::Request::Common'	=> 0,
		'JSON'			=> 0,
		'Getopt::Long'		=> 0,
	},
);