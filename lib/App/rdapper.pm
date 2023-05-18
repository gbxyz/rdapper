package App::rdapper;
use Carp qw(verbose);
use Getopt::Long;
use JSON;
use List::MoreUtils qw(any);
use Net::ASN;
use Net::DNS::Domain;
use Net::IP;
use Net::RDAP;
use Net::RDAP::EPPStatusMap;
use Pod::Usage;
use Term::ANSIColor;
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
    'WRAP_COLUMN'   => 72,
};
use vars qw($VERSION);
use strict;

$SIG{__DIE__} = sub { Carp::confess(@_) };

$VERSION = 0.7;

#
# global arg variables (note: nopager is now ignored)
#
my ($type, $object, $help, $debug, $short, $bypass, $auth, $nopager, $raw, $registrar, $nocolor, $reverse);

my $rdap = Net::RDAP->new(
    'use_cache' => !$bypass,
    'debug'     => $debug,
);

my %args;

sub main {
	GetOptions(
	    'type:s'        => \$type,
	    'object:s'      => \$object,
	    'help'          => \$help,
	    'debug'         => \$debug,
	    'short'         => \$short,
	    'bypass-cache'  => \$bypass,
	    'auth:s'        => \$auth,
	    'nopager'       => \$nopager,
	    'raw'           => \$raw,
	    'registrar'     => \$registrar,
	    'nocolor'       => \$nocolor,
	    'reverse'       => \$reverse,
	) || usage(qw(SYNOPSIS OPTIONS));

	$object = shift(@ARGV) if (!$object);

	show_usage('NAME', 'SYNOPSIS', 'OPTIONS', 'ADDITIONAL ARGUMENTS', 'COPYRIGHT') if ($help);
	show_usage(qw(SYNOPSIS OPTIONS)) if (length($object) < 1);

	binmode(select(), ':utf8');

	$Text::Wrap::columns = 80;

	my @displayorder = qw(registrant administrative technical billing abuse registrar reseller sponsor proxy notifications noc);

	if (!$type) {
	    if ($object =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)              { $type = 'ip'        } # v4 address
	    elsif ($object =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$/)  { $type = 'ip'        } # v4 range
	    elsif ($object =~ /^[0-9a-f:]+$/i)                                  { $type = 'ip'        } # v6 address
	    elsif ($object =~ /^[0-9a-f:]+\/\d{1,3}$/i)                         { $type = 'ip'        } # v6 range
	    elsif ($object =~ /^asn?\d+$/i)                                     { $type = 'autnum'    } # ASN
	    elsif ($object =~ /^(file|https)?:\/\//)                            { $type = 'url'       } # URL
	    else                                                                { $type = 'domain'    } # domain
	}

	($args{'user'}, $args{'pass'}) = split(/:/, $auth, 2) if ($auth);

	my $response;
	if ('ip' eq $type) {
	    $response = $rdap->ip(Net::IP->new($object), %args);

	    if ($reverse) {
	        $type = 'domain';
	        $response = $rdap->fetch($response->domain);
	    }

	} elsif ('autnum' eq $type) {
	    my $asn = $object;
	    $asn =~ s/^asn?//ig;
	    $response = $rdap->autnum(Net::ASN->new($asn), %args);

	} elsif ('domain' eq $type) {
	    $response = $rdap->domain(Net::DNS::Domain->new($object), %args);

	} elsif ('url' eq $type) {
	    $response = $rdap->fetch(URI->new($object), %args);

	} elsif ('entity' eq $type) {
	    $response = $rdap->entity($object, %args);

	} elsif ('nameserver' eq $type) {
	    my $url = Net::RDAP::Registry->get_url(Net::DNS::Domain->new($object));
	    my $path = $url->path;
	    $path =~ s!/domain/!/nameserver/!;
	    $url->path($path);
	    $response = $rdap->fetch($url, %args);

	} else {
	    error("Unable to handle type '$type'");

	}

	if (!$response) {
	    error("Unable to retrieve data");

	} elsif ($raw) {
	    print to_json({%{$response}});

	} else {
	    eval {
	        display($response);
	    };
	    if ($@) {
	        print STDERR $@;
	        error("Unable to parse and display response from server");
	    }
	}

	exit 0;
}

sub show_usage {
	pod2usage(
		'-input' 	=> __FILE__, 
		'-verbose' 	=> 99,
		'-sections' => \@_,
	);
}

sub display {
    my ($response, $indent) = @_;

    my @errors;

    if ($response->isa('Net::RDAP::Error')) {
        error('%03u (%s)', $response->errorCode, $response->title);

    } elsif ($registrar) {
        # avoid recursion
        $registrar = undef;

        foreach my $link ($response->links) {
            if ('related' eq $link->rel && 'application/rdap+json' eq $link->type) {
                my $related = $rdap->fetch($link->href, %args);
                exit;
            }
        }

        # if we're here, the response did not contain a related RDAP record
        display($response, $indent);

    } else {
        if ($response->can('name')) {
            my $name = $response->name;
            if ($name) {
                my $xname;

                if ('Net::DNS::Domain' eq ref($name)) {
                    $xname = $name->xname;
                    $name = $name->name;

                } else {
                    $xname = $name;

                }

                if ($xname ne $name) {
                    print_kv('Name', sprintf('%s (%s)', uc($xname), uc($name)));

                } else {
                    print_kv('Name', uc($name));

                }
            }
        }

        if ('ip network' eq $response->class) {
            print_kv('Handle',  $response->handle, $indent)         if ($response->handle);
            print_kv('Version', $response->version, $indent)        if ($response->version);
            print_kv('Domain',  colourise([qw(underline)], $response->domain->as_string), $indent) if ($response->domain);
            print_kv('Type',    $response->type, $indent)           if ($response->type);
            print_kv('Country', $response->country, $indent)        if ($response->country);

            print_kv('Parent',  $response->parentHandle, $indent)   if ($response->parentHandle);
            print_kv('Range',   $response->range->prefix, $indent)  if ($response->range);

            foreach my $cidr ($response->cidrs) {
                print_kv('CIDR', $cidr->prefix, $indent);
            }

        } elsif ('autnum' eq $response->class) {
            print_kv('Handle',  $response->handle, $indent) if ($response->handle);
            print_kv('Range',   sprintf('%u - %u', $response->start, $response->end), $indent) if ($response->start > 0 && $response->end > 0 && $response->end > $response->start);
            print_kv('Type',    $response->type, $indent)   if ($response->type);

        } elsif ('domain' eq $response->class) {
            print_kv('Handle', $response->handle, $indent) if ($response->handle);

            foreach my $ns (sort { lc($a->name->name) cmp lc($b->name->name) } $response->nameservers) {
                print_kv('Nameserver', uc($ns->name->name), $indent);
            }

            foreach my $ds ($response->ds) {
                print_kv('DS Record', sprintf('%s. IN DS %u %u %u %s', uc($ds->name), $ds->keytag, $ds->algorithm, $ds->digtype, uc($ds->digest)), $indent);
            }

            foreach my $key ($response->keys) {
                print_kv('DNSKEY Record', sprintf('%s. IN DNSKEY %u %u %u %s', uc($key->name), $key->flags, $key->protocol, $key->algorithm, uc($key->key)), $indent);
            }

            display_artRecord($response->{'artRecord_record'}, $indent) if ($response->{'artRecord_record'});
            display_platform_nameservers($response->{'platformNS_nameservers'}, $indent) if ($response->{'platformNS_nameservers'});

            print_kv('Registration Type', $response->{'regType_regType'}) if ($response->{'regType_regType'});

        } elsif ('entity' eq $response->class) {
            print_kv('Handle', $response->handle, $indent) if ($response->handle && $indent < 1);

            foreach my $id ($response->ids) {
                print_kv($id->type, $id->identifier, $indent);
            }

            print_vcard($response->vcard, $indent) if ($response->vcard);

        } elsif ('nameserver' eq $response->class) {
            print_kv('Handle', $response->handle, $indent) if ($response->handle);

            foreach my $ip ($response->addresses) {
                print_kv('IP Address', $ip->ip, $indent);
            }
        }

        foreach my $event ($response->events) {
            print_kv(ucfirst($event->action), scalar($event->date), $indent);
        }

        if ($indent < 1) {
            foreach my $status ($response->status) {
                my $epp = rdap2epp($status);
                if ($epp) {
                    print_kv('Status', sprintf('%s (EPP: %s, %s)', $status, $epp, colourise([qw(underline)], sprintf('https://icann.org/epp#%s', $epp))), $indent);

                } else {
                    print_kv('Status', $status, $indent);

                }
            }
        }

        foreach my $entity ($response->entities) {
            my $rstring = join(', ', map { sprintf('%s Contact', ucfirst($_)) } $entity->roles);

            if ($entity->handle && 'not applicable' ne $entity->handle && 'HANDLE REDACTED FOR PRIVACY' ne $entity->handle) {
                print_kv($rstring, $entity->handle, $indent);

            } else {
                print_kv($rstring, '', $indent);

            }

            eval {
                display($entity, 1+$indent);
            };
            if ($@) {
                print STDERR $@;
                warning('unable to parse and display entity');
            }
        }
    }

    if (!$short) {
        foreach my $link (grep { 'self' ne $_->rel } $response->links) {
            print_link($link, $indent);
        }

        foreach my $remark ($response->remarks) {
            print_remark_or_notice($remark, $indent);
        }

        foreach my $notice ($response->notices) {
            print_remark_or_notice($notice, $indent);
        }
    }

    map { warning($_) } @errors;

    print "\n" if ($indent < 1);
}

close(LESS);

sub print_remark_or_notice {
    my ($ron, $indent) = @_;

    my $type = ($ron->isa('Net::RDAP::Notice') ? 'Notice' : 'Remark');

    if (1 == scalar($ron->description)) {
        print_kv($ron->title || $type, ($ron->description)[0], $indent);

    } else {
        print_kv($ron->title || $type, $indent);

        foreach my $line ($ron->description) {
            select()->print((INDENT x (1+$indent)), $line, "\n");
        }
    }

    foreach my $link ($ron->links) {
        print_link($link, 1+$indent);
    }
}

sub print_link {
    my ($link, $indent) = @_;

    print_kv(
        $link->title || ('related' eq $link->rel ? 'Link' : ucfirst($link->rel)) || 'Link',
        colourise([qw(underline)], $link->href->as_string),
        $indent
    );
}

sub print_vcard {
    my ($card, $indent) = @_;

    if ($card->full_name || $card->organization) {
        print_kv('Name', $card->full_name, $indent) if ($card->full_name);
        print_kv('Organization', $card->organization, $indent) if ($card->organization);

    } else {
        print_kv('Name/Organization', '(not available)', $indent);

    }

    my @addresses = map { $_->{'address'} } @{$card->addresses};
    foreach my $address ( @addresses) {
        if ('ARRAY' eq ref($address->[ADR_STREET])) {
            foreach my $street (@{$address->[ADR_STREET]}) {
                print_kv('Street', $street, $indent) if ($street);
            }

        } elsif ($address->[ADR_STREET]) {
            print_kv('Street', $address->[ADR_STREET], $indent);

        }

        print_kv('City',            $address->[ADR_CITY], $indent)  if ($address->[ADR_CITY]);
        print_kv('State/Province',  $address->[ADR_SP], $indent)    if ($address->[ADR_SP]);
        print_kv('Postal Code',     $address->[ADR_PC], $indent)    if ($address->[ADR_PC]);
        print_kv('Country',         $address->[ADR_CC], $indent)    if ($address->[ADR_CC]);
    }

    foreach my $email (@{$card->email_addresses}) {
        if ($email->{'type'}) {
            print_kv('Email', sprintf('%s (%s)', colourise([qw(underline)], $email->{'address'}), $email->{'type'}), $indent);

        } else {
            print_kv('Email', colourise([qw(underline)], $email->{'address'}), $indent);

        }
    }

    foreach my $number (@{$card->phones}) {
        my @types = ('ARRAY' eq ref($number->{'type'}) ? @{$number->{'type'}} : ($number->{'type'}));
        my $type = ((any { lc($_) eq 'fax' } @types) ? 'Fax' : 'Phone');
        print_kv($type, colourise([qw(underline)], $number->{'number'}), $indent);
    }
}

sub colourise {
    my ($cref, $str) = @_;

    if (-t STDOUT && !$nocolor) {
        return colored($cref, $str);

    } else {
        return $str;

    }
}

sub print_kv {
    my ($k, $v, $i) = @_;

    my $line = colourise([qw(bold)], $k.':').' '.$v;

    select()->print(INDENT x $i, $line, "\n");
}

sub warning {
    my ($fmt, @params) = @_;
    my $str = sprintf("Warning: $fmt", @params);
    print STDERR colourise([qw(yellow)], $str)."\n";
}

sub error {
    my ($fmt, @params) = @_;
    my $str = sprintf("Error: $fmt", @params);
    print STDERR colourise([qw(red)], $str)."\n";
    exit 1;
}

sub display_artRecord {
    my ($records, $indent) = @_;
    print_kv('Art Record', undef, $indent);
    foreach my $record (@{$records}) {
        print_kv($record->{'name'}, $record->{'value'}, $indent+1);
    }
}

sub display_platform_nameservers {
    my ($nameservers, $indent) = @_;
    foreach my $ns (@{$nameservers}) {
        print_kv('Platform Nameserver', uc(Net::RDAP::Object::Nameserver->new($ns)->name->name), $indent);
    }
}

1;

__END__

=pod

=head1 NAME

App::rdapper - a simple console-based RDAP client.

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

=item * C<--debug> - enable L<Net::RDAP> debug mode.

=item * C<--short> - omit remarks, notices, and links.

=item * C<--bypass-cache> - disable local cache of RDAP objects.

=item * C<--auth=USER:PASS> - HTTP Basic Authentication credentials
to be used when accessing the specified resource.

=item * C<--nocolor> - disable ANSI colors in the formatted output.

=back

=head1 INSTALLATION

To install, run:

	cpanm --sudo App::rdapper

=head1 RUNNING VIA DOCKER

The L<git repository|https://github.com/gbxyz/rdapper> contains a C<Dockerfile>
that can be used to build an image on your local system.

Alternatively, you can pull the L<image from Docker Hub|https://hub.docker.com/repository/docker/gbxyz/rdapper/general>:

	$ docker pull gbxyz/rdapper

	$ docker run -it gbxyz/rdapper --help

=head1 DEPENDENCIES

In addition to L<Net::RDAP>, C<rdapper> uses the following modules, some
of which may already be installed:

=over

=item * L<Carp>

=item * L<Getopt::Long>

=item * L<List::MoreUtils>

=item * L<Pod::Usage>

=item * L<Term::ANSIColor>

=item * L<Text::Wrap>

=item * L<URI>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2023 CentralNic Ltd. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
