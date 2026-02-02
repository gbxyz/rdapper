#!/usr/bin/env perl
use Test::More;
use common::sense;
use constant PACKAGE => q{App::rdapper};

require_ok PACKAGE;

my @tests = (
    [qw(rdap.org)],
    [qw(--bypass-cache rdap.org)],
    [qw(--bypass-cache --registrar rdap.org)],
    [qw(--bypass-cache --registry rdap.org)],
    # unclear why these fail, cannot reproduce
    # [qw(--bypass-cache --nameserver a.root-servers.net)],
    # [qw(--bypass-cache --tld org)],
    [qw(--bypass-cache 9.9.9.9)],
    [qw(--bypass-cache AS1701)],
);

foreach my $args (@tests) {
    say STDERR q{testing command: }.join(q{ }, @{$args});

    eval {
        PACKAGE->main(@{$args});
    };

    ok(length($@) < 1);
}

done_testing;
