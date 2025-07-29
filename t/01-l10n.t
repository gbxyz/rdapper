#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use Locale::gettext;

# To add a new language, just add an entry here.
my %lang_tests = (
    'pt_PT' => {
        'Help'         => 'Ajuda',
        'Billing'      => 'Faturação',
        'Last Changed' => 'Última Alteração',
    },
    'fr_FR' => {
        'Help'         => 'Aide',
        'Billing'      => 'Facturation',
        'Last Changed' => 'Dernière modification',
    },
);

# Dynamically calculate the number of tests to run
my $total_tests = 0;
$total_tests += scalar keys %{ $lang_tests{$_} } for keys %lang_tests;
plan tests => $total_tests;

# Loop through each language defined above.
foreach my $locale ( sort keys %lang_tests ) {
    my ($lang_code) = ($locale =~ /^([a-z]{2})/); # Extract 'pt' from 'pt_PT'

    # Check that the compiled .mo file for this language exists
    my $mo_file = File::Spec->catfile('locale', $lang_code, 'LC_MESSAGES', 'rdapper.mo');
    unless (-f $mo_file) {
        diag("Skipping tests for '$locale': $mo_file not found.");
        next; # Skip to the next language
    }

    # Set the environment for the current language
    local $ENV{LANGUAGE} = $locale;
    local $ENV{LANG}     = "$locale.UTF-8";
    local $ENV{LC_ALL}   = "$locale.UTF-8";
    
    # Bind the text domain for gettext
    bindtextdomain('rdapper', 'locale');
    textdomain('rdapper');

    # Run the specific tests for this language
    foreach my $original ( sort keys %{ $lang_tests{$locale} } ) {
        my $expected = $lang_tests{$locale}->{$original};
        my $translated = gettext($original);
        is($translated, $expected, "[$lang_code] '$original' -> '$expected'");
    }
}

done_testing();