#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;

# Central structure for all language tests ---
my %lang_tests = (
    'pt' => { # Use simple lang code now
        'Help'         => 'Ajuda',
        'Billing'      => 'Faturação',
        'Last Changed' => 'Última Alteração',
    },
    'fr' => {
        'Help'         => 'Aide',
        'Billing'      => 'Facturation',
        'Last Changed' => 'Dernière modification',
    },
    'de' => {
        'Help'         => 'Hilfe',
        'Billing'      => 'Abrechnung',
        'Last Changed' => 'Letzte Änderung',
    },
);

# Dynamically calculate the number of tests
my $total_tests = 0;
$total_tests += scalar keys %{ $lang_tests{$_} } for keys %lang_tests;
plan tests => $total_tests;

# Main test loop
foreach my $lang_code ( sort keys %lang_tests ) {
    my $po_file = File::Spec->catfile('locale', $lang_code, 'LC_MESSAGES', 'rdapper.po');

    unless (-f $po_file) {
        diag("Skipping tests for '$lang_code': $po_file not found.");
        next;
    }

    # Parse the .po file into a hash
    my %translations = parse_po_file($po_file);

    # Run the specific tests for this language
    foreach my $original ( sort keys %{ $lang_tests{$lang_code} } ) {
        my $expected = $lang_tests{$lang_code}->{$original};
        my $translated = $translations{$original} // '';
        is($translated, $expected, "[$lang_code] '$original' -> '$expected'");
    }
}

done_testing();

# Simple .po file parser subroutine
sub parse_po_file {
    my ($file) = @_;
    my %data;
    open my $fh, '<:encoding(UTF-8)', $file or die "Cannot open $file: $!";

    my $current_msgid = '';
    while (my $line = <$fh>) {
        if ($line =~ /^msgid "(.*)"/) {
            $current_msgid = $1;
        }
        elsif ($line =~ /^msgstr "(.*?)"/ && $current_msgid) {
            $data{$current_msgid} = $1;
            $current_msgid = '';
        }
    }
    close $fh;
    return %data;
}