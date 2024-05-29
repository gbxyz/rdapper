package App::rdapper;
use Getopt::Long qw(GetOptionsFromArray :config pass_through);
use JSON;
use List::Util qw(min);
use List::MoreUtils qw(any);
use Net::ASN;
use Net::DNS::Domain;
use Net::IP;
use Net::RDAP::EPPStatusMap;
use Net::RDAP;
use Pod::Usage;
use Term::ANSIColor;
use Term::Size;
use Text::Wrap;
use URI;
use constant {
    # see RFC 6350, Section 6.3.1.
    'ADR_STREET'    => 2,
    'ADR_CITY'      => 3,
    'ADR_SP'        => 4,
    'ADR_PC'        => 5,
    'ADR_CC'        => 6,
    'INDENT'        => '  ',
};
use vars qw($VERSION);
use strict;

$VERSION = '0.10';

#
# global arg variables (note: nopager is now ignored)
#
my ($type, $object, $help, $short, $bypass, $auth, $nopager, $raw, $registrar, $nocolor, $reverse);

#
# options spec for Getopt::Long
#
my %opts = (
    'type:s'        => \$type,
    'object:s'      => \$object,
    'help'          => \$help,
    'short'         => \$short,
    'bypass-cache'  => \$bypass,
    'auth:s'        => \$auth,
    'nopager'       => \$nopager,
    'raw'           => \$raw,
    'registrar'     => \$registrar,
    'nocolor'       => \$nocolor,
    'reverse'       => \$reverse,
);

my %funcs = (
    'ip network' => sub { App::rdapper->print_ip(@_) },
    'autnum'     => sub { App::rdapper->print_asn(@_) },
    'domain'     => sub { App::rdapper->print_domain(@_) },
    'entity'     => sub { App::rdapper->print_entity(@_) },
    'nameserver' => sub { App::rdapper->print_nameserver(@_) },
);

my @role_order = qw(registrant administrative technical billing abuse registrar reseller sponsor proxy notifications noc);
my %role_display = ('noc' => 'NOC');

my $rdap;

my $out = \*STDOUT;
my $err = \*STDERR;

$out->binmode(':utf8');
$err->binmode(':utf8');

$Text::Wrap::columns = min(
    (Term::Size::chars)[0] - 5,
    75,
);

$Text::Wrap::huge = 'overflow';

sub main {
    my $package = shift;

	GetOptionsFromArray(\@_, %opts) || $package->show_usage;

    $rdap = Net::RDAP->new(
        'use_cache' => !$bypass,
        'cache_ttl' => 300,
    );

	$object = shift(@_) if (!$object);

	$package->show_usage if ($help || length($object) < 1);

	if (!$type) {
	    if ($object =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)              { $type = 'ip'      } # v4 address
	    elsif ($object =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$/)  { $type = 'ip'      } # v4 range
	    elsif ($object =~ /^[0-9a-f:]+$/i)                                  { $type = 'ip'      } # v6 address
	    elsif ($object =~ /^[0-9a-f:]+\/\d{1,3}$/i)                         { $type = 'ip'      } # v6 range
	    elsif ($object =~ /^asn?\d+$/i)                                     { $type = 'autnum'  } # ASN
	    elsif ($object =~ /^(file|https)?:\/\//)                            { $type = 'url'     } # URL
	    else                                                                { $type = 'domain'  } # domain
	}

    my %args;
	($args{'user'}, $args{'pass'}) = split(/:/, $auth, 2) if ($auth);

	my $response;
	if ('ip' eq $type) {
	    $response = $rdap->ip(Net::IP->new($object), %args);

	    $response = $rdap->fetch($response->domain) if ($reverse);

	} elsif ('autnum' eq $type) {
	    my $asn = $object;
	    $asn =~ s/^asn?//ig;

	    $response = $rdap->autnum(Net::ASN->new($asn), %args);

	} elsif ('domain' eq $type) {
	    $response = $rdap->domain(Net::DNS::Domain->new($object), %args);

	} elsif ('nameserver' eq $type) {
	    my $url = Net::RDAP::Registry->get_url(Net::DNS::Domain->new($object));

        #
        # munge path
        #
	    my $path = $url->path;
	    $path =~ s!/domain/!/nameserver/!;
	    $url->path($path);

	    $response = $rdap->fetch($url, %args);

	} elsif ('entity' eq $type) {
	    $response = $rdap->entity($object, %args);

	} elsif ('url' eq $type) {
	    $response = $rdap->fetch(URI->new($object), %args);

	} else {
	    $package->error("Unable to handle type '$type'");

	}

    $package->display($response, 0);
}

sub show_usage {
    my $package = shift;

	pod2usage(
		'-input' 	=> __FILE__, 
		'-verbose' 	=> 99,
		'-sections' => [qw(SYNOPSIS OPTIONS)],
	);
}

sub display {
    my ($package, $object, $indent, $nofatal) = @_;

    if ($object->isa('Net::RDAP::Error')) {
        if ($nofatal) {
            $package->warning('%03u (%s)', $object->errorCode, $object->title);
            return undef;

        } else {
            $package->error('%03u (%s)', $object->errorCode, $object->title);

        }

    } elsif ($registrar) {
        # avoid recursing infinitely
        $registrar = undef;

        my $link = (grep { 'related' eq $_->rel && 'application/rdap+json' eq $_->type } $object->links)[0];

        if ($link && $package->display($rdap->fetch($link->href), $indent, 1)) {
            return 1;

        } else {
            return $package->display($object, $indent);

        }

    } elsif ($raw) {
	    $out->print(to_json({%{$object}}));

        return 1;

    } elsif (!defined($funcs{$object->class})) {
        $package->print_kv('Unknown object type', $object->class || '(missing objectClassName)', $indent);

        return undef;

    } else {
        #
        # generic properties
        #
        $package->print_kv('Object type', $object->class, $indent) if ($indent < 1);
        $package->print_kv('URL', u($object->self->href), $indent) if ($indent < 1 && $object->self);

        if ($object->can('name')) {
            my $name = $object->name;

            if ($name) {
                my $xname;

                if ('Net::DNS::Domain' eq ref($name)) {
                    $xname = $name->xname;
                    $name  = $name->name;

                } else {
                    $xname = $name;

                }

                if ($xname ne $name) {
                    $package->print_kv('Name', sprintf('%s (%s)', uc($xname), uc($name)));

                } else {
                    $package->print_kv('Name', uc($name));

                }
            }
        }

        #
        # object-specific properties
        #
        &{$funcs{$object->class}}($object, $indent);

        #
        # more generic properties
        #
        $package->print_events($object, $indent);
        $package->print_status($object, $indent, ('domain' eq $object->class));
        $package->print_entities($object, $indent);

        #
        # links, remarks and notices unless --short has been passed
        #
        if (!$short) {
            foreach my $link (grep { 'self' ne $_->rel } $object->links) {
                $package->print_link($link, $indent);
            }

            foreach my $remark ($object->remarks) {
                $package->print_remark_or_notice($remark, $indent);
            }

            foreach my $notice ($object->notices) {
                $package->print_remark_or_notice($notice, $indent);
            }
        }

        $out->print("\n") if ($indent < 1);

        return 1;
    }
}

sub print_ip {
    my ($package, $ip, $indent) = @_;

    $package->print_kv('Handle',    $ip->handle, $indent)               if ($ip->handle);
    $package->print_kv('Version',   $ip->version, $indent)              if ($ip->version);
    $package->print_kv('Domain',    u($ip->domain->as_string), $indent) if ($ip->domain);
    $package->print_kv('Type',      $ip->type, $indent)                 if ($ip->type);
    $package->print_kv('Country',   $ip->country, $indent)              if ($ip->country);
    $package->print_kv('Parent',    $ip->parentHandle, $indent)         if ($ip->parentHandle);
    $package->print_kv('Range',     $ip->range->prefix, $indent)        if ($ip->range);

    foreach my $cidr ($ip->cidrs) {
        $package->print_kv('CIDR', $cidr->prefix, $indent);
    }
}

sub print_asn {
    my ($package, $asn, $indent) = @_;

    $package->print_kv('Handle',    $asn->handle, $indent) if ($asn->handle);
    $package->print_kv('Range',     sprintf('%u - %u', $asn->start, $asn->end), $indent) if ($asn->start > 0 && $asn->end > 0 && $asn->end > $asn->start);
    $package->print_kv('Type',      $asn->type, $indent) if ($asn->type);
}

sub print_domain {
    my ($package, $domain, $indent) = @_;

    $package->print_kv('Handle', $domain->handle, $indent) if ($domain->handle);

    foreach my $ns (sort { lc($a->name->name) cmp lc($b->name->name) } $domain->nameservers) {
        $package->print_kv('Nameserver', uc($ns->name->name), $indent);
        $package->print_nameserver($ns, 1+$indent);
    }

    foreach my $ds ($domain->ds) {
        $package->print_kv('DS Record', $ds->plain, $indent);
    }

    foreach my $key ($domain->keys) {
        $package->print_kv('DNSKEY Record', $key->plain, $indent);
    }

    $package->display_artRecord($domain->{'artRecord_record'}, $indent) if ($domain->{'artRecord_record'});
    $package->display_platform_nameservers($domain->{'platformNS_nameservers'}, $indent) if ($domain->{'platformNS_nameservers'});

    $package->print_kv('Registration Type', $domain->{'regType_regType'}) if ($domain->{'regType_regType'});
}

sub display_artRecord {
    my ($package, $records, $indent) = @_;

    $package->print_kv('Art Record', undef, $indent);

    foreach my $record (@{$records}) {
        $package->print_kv($record->{'name'}, $record->{'value'}, 1+$indent);
    }
}

sub display_platform_nameservers {
    my ($package, $nameservers, $indent) = @_;

    foreach my $ns (@{$nameservers}) {
        $package->print_kv('Platform Nameserver', uc(Net::RDAP::Object::Nameserver->new($ns)->name->name), $indent);
    }
}

sub print_entity {
    my ($package, $entity, $indent) = @_;

    $package->print_kv('Handle', $entity->handle, $indent) if ($entity->handle && $indent < 1);

    foreach my $id ($entity->ids) {
        $package->print_kv($id->type, $id->identifier, $indent);
    }

    $package->print_vcard($entity->vcard, $indent) if ($entity->vcard);
}

sub print_nameserver {
    my ($package, $nameserver, $indent) = @_;

    $package->print_kv('Handle', $nameserver->handle, $indent) if ($nameserver->handle);

    foreach my $ip ($nameserver->addresses) {
        $package->print_kv('IP Address', $ip->ip, $indent);
    }
}

sub print_events {
    my ($package, $object, $indent) = @_;

    foreach my $event ($object->events) {
        if ($event->actor) {
            $package->print_kv(ucfirst($event->action), sprintf('%s (by %s)', scalar($event->date), $event->actor), $indent);
        } else {
            $package->print_kv(ucfirst($event->action), scalar($event->date), $indent);
        }
    }
}

sub print_status {
    my ($package, $object, $indent, $is_domain) = @_;

    foreach my $status ($object->status) {
        my $epp = rdap2epp($status);
        if ($epp && $is_domain && !$short) {
            $package->print_kv('Status', sprintf('%s (EPP: %s, %s)', $status, $epp, u(sprintf('https://icann.org/epp#%s', $epp))), $indent);

        } else {
            $package->print_kv('Status', $status, $indent);

        }
    }
}

sub print_entities {
    my ($package, $object, $indent) = @_;

    my @entities = $object->entities;

    my %seen;
    foreach my $role (@role_order) {
        for (my $i = 0 ; $i < scalar(@entities) ; $i++) {
            next if ($seen{$i});

            my $entity = $entities[$i];
            if (any { $role eq $_ } $entity->roles) {
                $seen{$i} = 1;

                my $rstring = join(', ', map { sprintf('%s Contact', $role_display{$_} || ucfirst($_)) } $entity->roles);

                if ($entity->handle && 'not applicable' ne $entity->handle && 'HANDLE REDACTED FOR PRIVACY' ne $entity->handle) {
                    $package->print_kv($rstring, $entity->handle, $indent);

                } else {
                    $package->print_kv($rstring, undef, $indent);

                }

                eval {
                    $package->display($entity, 1+$indent, 1);
                };
            }
        }
    }
}

sub print_remark_or_notice {
    my ($package, $thing, $indent) = @_;

    my $type = ($thing->isa('Net::RDAP::Notice') ? 'Notice' : 'Remark');

    if (1 == scalar($thing->description)) {
        $package->print_kv($thing->title || $type, ($thing->description)[0], $indent);

    } else {
        $package->print_kv($thing->title || $type, , '', $indent);

        $out->print(fill(
            (INDENT x (1+$indent)),
            (INDENT x (1+$indent)),
            $thing->description
        )."\n");
    }

    foreach my $link ($thing->links) {
        $package->print_link($link, 1+$indent);
    }
}

sub print_link {
    my ($package, $link, $indent) = @_;

    $package->print_kv(
        $link->title || ('related' eq $link->rel ? 'Link' : ucfirst($link->rel)) || 'Link',
        u($link->href->as_string),
        $indent,
    );
}

sub print_vcard {
    my ($package, $card, $indent) = @_;

    if ($card->full_name || $card->organization) {
        $package->print_kv('Name', $card->full_name, $indent) if ($card->full_name);
        $package->print_kv('Organization', $card->organization, $indent) if ($card->organization);

    } else {
        $package->print_kv('Name/Organization', '(not available)', $indent);

    }

    foreach my $address (map { $_->{'address'} } @{$card->addresses}) {
        if ('ARRAY' eq ref($address->[ADR_STREET])) {
            foreach my $street (@{$address->[ADR_STREET]}) {
                $package->print_kv('Street', $street, $indent) if ($street);
            }

        } elsif ($address->[ADR_STREET]) {
            $package->print_kv('Street', $address->[ADR_STREET], $indent);

        }

        $package->print_kv('City',            $address->[ADR_CITY], $indent)  if ($address->[ADR_CITY]);
        $package->print_kv('State/Province',  $address->[ADR_SP], $indent)    if ($address->[ADR_SP]);
        $package->print_kv('Postal Code',     $address->[ADR_PC], $indent)    if ($address->[ADR_PC]);
        $package->print_kv('Country',         $address->[ADR_CC], $indent)    if ($address->[ADR_CC]);
    }

    foreach my $email (@{$card->email_addresses}) {
        if ($email->{'type'}) {
            $package->print_kv('Email', sprintf('%s (%s)', u($email->{'address'}), $email->{'type'}), $indent);

        } else {
            $package->print_kv('Email', u($email->{'address'}), $indent);

        }
    }

    foreach my $number (@{$card->phones}) {
        my @types = ('ARRAY' eq ref($number->{'type'}) ? @{$number->{'type'}} : ($number->{'type'}));
        my $type = ((any { lc($_) eq 'fax' } @types) ? 'Fax' : 'Phone');
        $package->print_kv($type, u($number->{'number'}), $indent);
    }
}

sub print_kv {
    my ($package, $name, $value, $indent) = @_;

    $out->print(wrap(
        (INDENT x $indent),
        (INDENT x ($indent + 1)),
        sprintf("%s %s\n", b($name.':'), $value),
    ));
}

sub warning {
    my ($package, $fmt, @params) = @_;
    my $str = sprintf("Warning: $fmt", @params);
    $err->print(colourise([qw(yellow)], $str)."\n");
}

sub error {
    my ($package, $fmt, @params) = @_;
    my $str = sprintf("Error: $fmt", @params);
    $err->print(colourise([qw(red)], $str)."\n");
    exit 1;
}

sub colourise {
    my ($cref, $str) = @_;

    if (-t $out && !$nocolor) {
        return colored($cref, $str);

    } else {
        return $str;

    }
}

sub u { colourise([qw(underline)], shift) }
sub b { colourise([qw(bold)], shift) }

1;

__END__

=pod

=head1 NAME

App::rdapper - a simple console-based RDAP client.

=head1 INSTALLATION

To install, run:

	cpanm --sudo App::rdapper

=head1 RUNNING VIA DOCKER

The L<git repository|https://github.com/gbxyz/rdapper> contains a C<Dockerfile>
that can be used to build an image on your local system.

Alternatively, you can pull the L<image from Docker Hub|https://hub.docker.com/r/gbxyz/rdapper>:

	$ docker pull gbxyz/rdapper

	$ docker run -it gbxyz/rdapper --help

=head1 SYNOPSIS

    rdapper OBJECT [OPTIONS]

=head1 DESCRIPTION

C<rdapper> is a simple RDAP client. It uses L<Net::RDAP> to retrieve
data about internet resources (domain names, IP addresses, and
autonymous systems) and outputs the information in a human-readable
format. If you want to consume this data in your own program you
should use L<Net::RDAP> directly.

C<rdapper> was originally conceived as a full RDAP client (back
when the RDAP specification was still in draft form) but is now
just a very thin front-end to L<Net::RDAP>.

=head1 OPTIONS

You can pass any internet resource as an argument; this may be:

=over

=item * a "forward" domain name such as C<example.com>;

=item * a "reverse" domain name such as C<168.192.in-addr.arpa>;

=item * a IPv4 or IPv6 address or CIDR prefix, such as C<192.168.0.1>
or C<2001:DB8::/32>;

=item * an Autonymous System Number such as C<AS65536>.

=item * the URL of an RDAP resource such as
C<https://example.com/rdap/domain/example.com>.

=item * the "tagged" handle of an entity, such as an LIR, registrar,
or domain admin/tech contact. Because these handles are difficult
to distinguish from domain names, you must use the C<--type> argument
to explicitly tell C<rdapper> that you want to perform an entity query,
.e.g C<rdapper --type=entity ABC123-EXAMPLE>.

=back

C<rdapper> also implements limited support for in-bailiwick nameservers,
but you must use the C<--type=nameserver> argument to disambiguate
from domain names. The RDAP server of the parent domain's registry will
be queried.

=head1 ADDITIONAL ARGUMENTS

=over

=item * C<--registrar> - follow referral to the registrar's RDAP record
(if any) which will be displayed instead of the registry record.

=item * C<--reverse> - if you provide an IP address or CIDR prefix, then
this option causes C<rdapper> to display the record of the corresponding
C<in-addr.arpa> or C<ip6.arpa> domain.

=item * C<--type=TYPE> - explicitly set the object type. C<rdapper>
will guess the type by pattern matching the value of C<OBJECT> but
you can override this by explicitly setting the C<--type> argument
to one of : C<ip>, C<autnum>, C<domain>, C<nameserver>, C<entity>
or C<url>.

If C<--type=url> is used, C<rdapper> will directly fetch the
specified URL and attempt to process it as an RDAP response.

If C<--type=entity> is used, C<OBJECT> must be a a string
containing a "tagged" handle, such as C<ABC123-EXAMPLE>, as per
RFC 8521.

=item * C<--help> - display help message.

=item * C<--raw> - print the raw JSON rather than parsing it.

=item * C<--short> - omit remarks, notices, and links.

=item * C<--bypass-cache> - disable local cache of RDAP objects.

=item * C<--auth=USER:PASS> - HTTP Basic Authentication credentials
to be used when accessing the specified resource.

=item * C<--nocolor> - disable ANSI colors in the formatted output.

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2012-2023 CentralNic Ltd.

Copyright (c) 2023-2024 Gavin Brown.

All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
