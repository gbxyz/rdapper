package App::rdapper;
use Getopt::Long qw(GetOptionsFromArray :config pass_through);
use JSON;
use List::Util qw(min max);
use List::MoreUtils qw(any);
use Net::ASN;
use Net::DNS::Domain;
use Net::IP;
use Net::RDAP::EPPStatusMap;
use Net::RDAP 0.26;
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
    'IANA_BASE_URL' => 'https://rdap.iana.org/',
};
use vars qw($VERSION);
use strict;

$VERSION = '1.05';

#
# global arg variables (note: nopager is now ignored)
#
my (
    $type, $object, $help, $short, $bypass, $auth, $nopager, $raw, $both,
    $registrar, $nocolor, $reverse, $version, $search
);

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
    'both'          => \$both,
    'registrar'     => \$registrar,
    'nocolor'       => \$nocolor,
    'reverse'       => \$reverse,
    'version'       => \$version,
    'search'        => \$search,
    'autnum'        => sub { $type = 'autnum' },
    'domain'        => sub { $type = 'domain' },
    'entity'        => sub { $type = 'entity' },
    'ip'            => sub { $type = 'ip' },
    'tld'           => sub { $type = 'tld' },
    'url'           => sub { $type = 'url' },
);

my %funcs = (
    'ip network' => sub { App::rdapper->print_ip(@_) },
    'autnum'     => sub { App::rdapper->print_asn(@_) },
    'domain'     => sub { App::rdapper->print_domain(@_) },
    'entity'     => sub { App::rdapper->print_entity(@_) },
    'nameserver' => sub { App::rdapper->print_nameserver(@_) },
    'help'       => sub { 1 }, # help only contains generic properties
);

my @ROLE_DISPLAY_NAMES_ORDER = qw(registrant administrative technical billing
    abuse registrar reseller sponsor proxy notifications noc);

my %ROLE_DISPLAY_NAMES = ('noc' => 'NOC');

my @EVENTS = (
    'registration',
    'reregistration',
    'last changed',
    'expiration',
    'deletion',
    'reinstantiation',
    'transfer',
    'locked',
    'unlocked',
    'last update of RDAP database',
    'registrar expiration',
    'enum validation expiration',
);

my %EVENT_DISPLAY_ORDER;
for (my $i = 0 ; $i < scalar(@EVENTS) ; $i++) {
    $EVENT_DISPLAY_ORDER{$EVENTS[$i]} = $i;
}

my @VCARD_DISPLAY_ORDER = qw(SOURCE KIND FN TITLE ROLE ORG ADR GEO EMAIL CONTACT-URI SOCIALPROFILE TEL IMPP URL CATEGORIES NOTE);
my %VCARD_NODE_NAMES = (
    FN              => 'Name',
    ORG             => 'Organization',
    TEL             => 'Phone',
    EMAIL           => 'Email',
    IMPP            => 'Messaging',
    URL             => 'Website',
    SOCIALPROFILE   => 'Profile',
    'CONTACT-URI'   => 'Contact Link',
    GEO             => 'Location',
);

my @ADR_DISPLAY_ORDER = (ADR_STREET, ADR_CITY, ADR_SP, ADR_PC, ADR_CC);
my %ADR_DISPLAY_NAMES = (
    &ADR_STREET => 'Street',
    &ADR_CITY   => 'City',
    &ADR_SP     => 'State/Province',
    &ADR_PC     => 'Postal Code',
    &ADR_CC     => 'Country',
);

my $json = JSON->new->utf8->canonical->pretty->convert_blessed;

my $rdap;

my $out = \*STDOUT;
my $err = \*STDERR;

$out->binmode(':utf8');
$err->binmode(':utf8');

$Text::Wrap::columns    = max((Term::Size::chars)[0], 75);
$Text::Wrap::huge       = 'overflow';

sub main {
    my $package = shift;

    GetOptionsFromArray(\@_, %opts) || $package->show_usage;

    $rdap = Net::RDAP->new(
        'use_cache' => !$bypass,
        'cache_ttl' => 300,
    );

    $package->show_version if ($version);

    $registrar ||= $both;

    $object = shift(@_) if (!$object);

    $package->show_usage if ($help || length($object) < 1);

    if (!$type) {
        if ($object =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)              { $type = 'ip'      }
        elsif ($object =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$/)  { $type = 'ip'      }
        elsif ($object =~ /^[0-9a-f:]+:[0-9a-f:]*$/i)                       { $type = 'ip'      }
        elsif ($object =~ /^[0-9a-f:]+:[0-9a-f:]*\/\d{1,3}$/i)              { $type = 'ip'      }
        elsif ($object =~ /^asn?\d+$/i)                                     { $type = 'autnum'  }
        elsif ($object =~ /^(file|https)?:\/\//)                            { $type = 'url'     }
        elsif ($object =~ /^([a-z]{2,}|xn--[a-z0-9\-]+)$/i)                 { $type = 'tld'     }
        else                                                                { $type = 'domain'  }
    }

    my %args;
    ($args{'user'}, $args{'pass'}) = split(/:/, $auth, 2) if ($auth);

    if ($search) {
        $package->search($rdap, $object, $type, %args);
        return;
    }

    my $response;
    if ('ip' eq $type) {
        my $ip = Net::IP->new($object);

        $package->error("Invalid IP address '$object'") unless ($ip);

        $response = $rdap->ip($ip, %args);

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

    } elsif ('tld' eq $type) {
        $response = $rdap->fetch(URI->new(IANA_BASE_URL.'domain/'.$object), %args);

    } elsif ('url' eq $type) {
        my $uri = URI->new($object);

        #
        # if the path ends with /help then we assume then it's a help query
        #
        $args{'class_override'} = 'help' if ('help' eq lc(($uri->path_segments)[-1]));

        $response = $rdap->fetch($uri, %args);

    } else {
        $package->error("Unable to handle type '$type'");

    }

    $package->display($response, 0);
}

sub show_usage {
    my $package = shift;

    pod2usage(
        '-input'    => __FILE__,
        '-verbose'  => 99,
        '-sections' => [qw(SYNOPSIS OPTIONS)],
    );
}

sub show_version {
    my $package = shift;
    $out->say(sprintf('%s v%s', $package, $VERSION));
    exit;
}

sub search {
    my ($package, $rdap, $object, $type, %args) = @_;

    if ('domain' eq $type) {
        $package->domain_search($rdap, $object, %args);

    } else {
        $package->error('Current unable to do searches for %s objects.', $type);

    }
}

sub domain_search {
    my ($package, $rdap, $query, %args) = @_;

    my @labels = grep { length > 0 } split(/\./, lc($query), 2);

    my $prefix = shift(@labels);
    my $suffix = shift(@labels) || '*';

    my $servers = {};
    my $zones = {};

    foreach my $service (Net::RDAP::Registry->load_registry(Net::RDAP::Registry::DNS_URL)->services) {
        foreach my $zone ($service->registries) {
            my $url = Net::RDAP::Registry->get_best_url($service->urls);

            if (!exists($servers->{$url->as_string})) {
                $servers->{$url->as_string} = Net::RDAP::Service->new($url);
            }

            $zones->{lc($zone)} = $url->as_string;
        }
    }

    my @zones = sort(keys(%{$zones}));
    @zones = grep { lc($suffix) eq $_ || $suffix =~ /\.$_/i } @zones if ($suffix ne '*');

    foreach my $zone (@zones) {
        my $server = $servers->{$zones->{$zone}};
        my $result = $server->domains(name => $prefix);

        if ($result->isa('Net::RDAP::Error')) {
            $package->warning(sprintf('%s.%s: %s %s', $prefix, $zone, $result->errorCode, $result->title));

        } elsif ($result->isa('Net::RDAP::SearchResult')) {
            $package->display_domain_search_results($result);

        }
    }
}

sub display_domain_search_results {
    my ($package, $result) = @_;

    foreach my $domain ($result->domains) {
        $out->say($domain->name->name);
    }
}

sub display_nameserver_search_results {
    my ($package, $result) = @_;

    foreach my $nameserver ($result->nameservers) {
        $out->say($nameserver->name->name);
    }
}

sub display_entity_search_results {
    my ($package, $result) = @_;

    foreach my $entity ($result->entities) {
        $out->say($entity->handle);
    }
}

sub display_search {
    my ($package, $result) = @_;

    $package->display_domain_search_results($result)        if (exists($result->{domainSearchResults}));
    $package->display_nameserver_search_results($result)    if (exists($result->{nameserverSearchResults}));
    $package->display_entity_search_results($result)        if (exists($result->{entitySearchResults}));
}

sub display {
    my ($package, $object, $indent, $nofatal) = @_;

    if ($object->isa('Net::RDAP::Error')) {
        if ($nofatal) {
            $package->warning('%03u (%s)', $object->errorCode, $object->title);

        } else {
            $package->error('%03u (%s)', $object->errorCode, $object->title);

        }

        return undef;
    }

    if ($registrar) {
        # avoid recursing infinitely
        $registrar = undef;

        my $link = (grep { 'related' eq $_->rel && $_->is_rdap } $object->links)[0];

        if (!$link) {
            $package->warning('No registrar link found, displaying the registry record...');
            return $package->display($object, $indent);
        }

        my $result = $rdap->fetch($link);

        if ($result->isa('Net::RDAP::Error')) {
            return $package->display($result, $indent, 1);

            $package->warning('Unable to retrieve registrar record, displaying the registry record...');
            return $package->display($object, $indent);
        }

        if ($both) {
            $package->display($object, $indent, 1);
        }

        return $package->display($result, $indent);
    }

    if ($raw) {
        $out->print($json->encode($object));

        return 1;
    }

    if ($object->isa('Net::RDAP::SearchResult')) {
        $package->display_search($object);

        return 1;
    }

    $package->error("JSON response does not include the 'objectClassName' properties") unless ($object->class);
    $package->error(sprintf("Unknown object type '%s'", $object->class)) unless ($funcs{$object->class});

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
    # links, remarks, notices and redactions, unless --short has been passed
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

        my @fields = $object->redactions;
        if (scalar(@fields) > 0) {
            $package->print_kv('Redacted Fields', '', $indent);
            foreach my $field (@fields) {
                $out->print(wrap(
                    (INDENT x ($indent + 1)),
                    (INDENT x ($indent + 2)),
                    sprintf("%s %s (reason: %s)\n", b('*'), $field->name, $field->reason)
                ));
            }
        }
    }

    $out->print("\n") if ($indent < 1);

    return 1;
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

    my $jcard = $entity->jcard;
    if ($jcard) {
        $package->print_jcard($jcard, $indent);
    }
}

sub print_jcard {
    my ($package, $jcard, $indent) = @_;

    foreach my $ptype (@VCARD_DISPLAY_ORDER) {
        foreach my $property (grep { $_->value } $jcard->properties($ptype)) {
            $package->print_jcard_property($property, $indent);
        }
    }
}

sub print_jcard_property {
    my ($package, $property, $indent) = @_;

    if ('ADR' eq uc($property->type)) {
        $package->print_jcard_adr($property, $indent);

    } else {
        my $label = $VCARD_NODE_NAMES{$property->type} || ucfirst(lc($property->type));

        if ('TEL' eq uc($property->type)) {
            if (any { 'fax' eq lc($_) } @{$property->param('type')}) {
                $label = 'Fax';

            } else {
                $label = 'Phone';

            }
        }

        $package->print_kv(
            $label,
            'uri' eq $property->value_type ? u($property->value) : $property->value,
            $indent
        );
    }
}

sub print_jcard_adr {
    my ($package, $property, $indent) = @_;

    $package->print_kv('Address', '', $indent);

    if ($property->param('label')) {
        $out->print(wrap(
            INDENT x ($indent + 1),
            INDENT x ($indent + 1),
            $property->param('label'),
        )."\n");

    } else {
        foreach my $i (@ADR_DISPLAY_ORDER) {
            if ($property->value->[$i]) {
                if ('ARRAY' eq ref($property->value->[$i])) {
                    foreach my $v (grep { $_ } @{$property->value->[$i]}) {
                        $package->print_kv($ADR_DISPLAY_NAMES{$i}, $v, $indent+1);
                    }

                } else {
                    $package->print_kv($ADR_DISPLAY_NAMES{$i}, $property->value->[$i], $indent+1);

                }
            }
        }
    }
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

    foreach my $event (sort { $EVENT_DISPLAY_ORDER{$a->action} - $EVENT_DISPLAY_ORDER{$b->action} } $object->events) {
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
    foreach my $role (@ROLE_DISPLAY_NAMES_ORDER) {
        for (my $i = 0 ; $i < scalar(@entities) ; $i++) {
            next if ($seen{$i});

            my $entity = $entities[$i];
            if (any { $role eq $_ } $entity->roles) {
                $seen{$i} = 1;

                my $rstring = join(', ', map { sprintf('%s Contact', $ROLE_DISPLAY_NAMES{$_} || ucfirst($_)) } $entity->roles);

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
    $err->say(colourise([qw(yellow)], $str));
}

sub error {
    my ($package, $fmt, @params) = @_;
    my $str = sprintf("Error: $fmt", @params);
    $err->say(colourise([qw(red)], $str));
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

App::rdapper - a simple console-based L<RDAP|https://about.rdap.org> client.

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

General form:

    rdapper [OPTIONS] OBJECT

Examples:

    rdapper example.com

    rdapper --tld foo

    rdapper 192.168.0.1

    rdapper https://rdap.org/domain/example.com

    rdapper --search "exampl*.com"

=head1 DESCRIPTION

C<rdapper> is a simple RDAP client. It uses L<Net::RDAP> to retrieve data about
internet resources (domain names, IP addresses, and autonymous systems) and
outputs the information in a human-readable format. If you want to consume this
data in your own program you should use L<Net::RDAP> directly.

=head1 OPTIONS

You can pass any internet resource as an argument; this may be:

=over

=item * a "forward" domain name such as C<example.com>;

=item * a top-level domain such as C<com>;

=item * a IPv4 or IPv6 address or CIDR prefix, such as C<192.168.0.1> or
C<2001:DB8::/32>;

=item * an Autonymous System Number such as C<AS65536>.

=item * a "reverse" domain name such as C<168.192.in-addr.arpa>;

=item * the URL of an RDAP resource such as
C<https://example.com/rdap/domain/example.com>.

=item * the "tagged" handle of an entity, such as an LIR, registrar, or domain
admin/tech contact. Because these handles are difficult to distinguish from
domain names, you must use the C<--type> argument to explicitly tell C<rdapper>
that you want to perform an entity query, .e.g C<rdapper --type=entity
ABC123-EXAMPLE>.

=back

C<rdapper> also implements limited support for in-bailiwick nameservers, but you
must use the C<--nameserver> argument to disambiguate from domain names. The
RDAP server of the parent domain's registry will be queried.

=head2 ARGUMENTS

=over

=item * C<--registrar> - follow referral to the registrar's RDAP record (if any)
which will be displayed instead of the registry record.

=item * C<--both> - display both the registry and (if any) registrar RDAP
records (implies C<--registrar>).

=item * C<--reverse> - if you provide an IP address or CIDR prefix, then this
option causes C<rdapper> to display the record of the corresponding
C<in-addr.arpa> or C<ip6.arpa> domain.

=item * C<--type=TYPE> - explicitly set the object type. C<rdapper> will guess
the type by pattern matching the value of C<OBJECT> but you can override this by
explicitly setting the C<--type> argument to one of : C<ip>, C<autnum>,
C<domain>, C<nameserver>, C<entity> or C<url>.

=over

=item * If C<--type=url> is used, C<rdapper> will directly fetch the specified
URL and attempt to process it as an RDAP response. If the URL path ends with
C</help> then the response will be treated as a "help" query response (if you
want to see the record for the .help TLD, use C<--type=tld help>).

=item * If C<--type=entity> is used, C<OBJECT> must be a a string containing a
"tagged" handle, such as C<ABC123-EXAMPLE>, as per L<RFC
8521|https://datatracker.ietf.org/doc/html/rfc8521>.

=back

=item * C<--$TYPE> - alias for C<--type=$TYPE>. eg C<--domain>, C<--autnum>, etc.

=item * C<--help> - display help message.

=item * C<--version> - display package and version.

=item * C<--raw> - print the raw JSON rather than parsing it.

=item * C<--short> - omit remarks, notices, links and redactions.

=item * C<--bypass-cache> - disable local cache of RDAP objects.

=item * C<--auth=USER:PASS> - HTTP Basic Authentication credentials to be used
when accessing the specified resource. This option B<SHOULD NOT> be used unless
you explicitly specify a URL, otherwise your credentials may be sent to servers
you aren't expecting them to.

=item * C<--nocolor> - disable ANSI colors in the formatted output.

=item * C<--search> - perform a search.

=back

=head1 RDAP Search

Some RDAP servers support the ability to perform simple substring searches.
You can use the C<--search> option to enable this functionality.

When the C<--search> option is used, C<OBJECT> will be used as a search term. If
it contains no dots (e.g. C<exampl*>), then C<rdapper> will send a search query
for C<exampl*> to I<all> known RDAP servers. If it contains one or more dots
(e.g. C<exampl*.com>), it will send the search query to the RDAP server for the
specified TLD (if any).

Any errors observed will be printed to C<STDERR>; any search results will be
printed to C<STDOUT>.

As of writing, search is only available for domain names.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2012-2023 CentralNic Ltd.

Copyright (c) 2023-2025 Gavin Brown.

All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
