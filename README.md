# NAME

`rdapper` - a simple console-based RDAP client.

# SYNOPSIS

    rdapper OBJECT [OPTIONS]

# DESCRIPTION

`rdapper` is a simple RDAP client. It uses [Net::RDAP](https://metacpan.org/pod/Net%3A%3ARDAP) to retrieve
data about internet resources (domain names, IP addresses, and
autonymous systems) and outputs the information in a human-readable
format. If you want to consume this data in your own program you
should use [Net::RDAP](https://metacpan.org/pod/Net%3A%3ARDAP) directly.

`rdapper` was originally conceived as a full RDAP client (back
when the RDAP specification was still in draft form) but is now
just a very thin front-end to [Net::RDAP](https://metacpan.org/pod/Net%3A%3ARDAP).

# OPTIONS

You can pass any internet resource as an argument; this may be:

- a "forward" domain name such as `example.com`;
- a "reverse" domain name such as `168.192.in-addr.arpa`;
- a IPv4 or IPv6 address or CIDR prefix, such as `192.168.0.1`
or `2001:DB8::/32`;
- an Autonymous System Number such as `AS65536`.
- the URL of an RDAP resource such as
`https://example.com/rdap/domain/example.com`.
- the "tagged" handle of an entity, such as an LIR, registrar,
or domain admin/tech contact. Because these handles are difficult
to distinguish from domain names, you must use the `--type` argument
to explicitly tell `rdapper` that you want to perform an entity query,
.e.g `rdapper --type=entity ABC123-EXAMPLE`.

## ADDITIONAL ARGUMENTS

- `--registrar` - follow referral to the registrar's RDAP record
(if any) which will be displayed instead of the registry record.
- `--type=TYPE` - explicitly set the object type. `rdapper`
will guess the type by pattern matching the value of `OBJECT` but
you can override this by explicitly setting the `--type` argument
to one of : `ip`, `autnum`, `domain`, `entity` or `url`.

    If `--type=url` is used, `rdapper` will directly fetch the
    specified URL and attempt to process it as an RDAP response.

    If `--type=entity` is used, `OBJECT` must be a a string
    containing a "tagged" handle, such as `ABC123-EXAMPLE`, as per
    RFC 8521.

- `--help` - display help message.
- `--debug` - enable [Net::RDAP](https://metacpan.org/pod/Net%3A%3ARDAP) debug mode.
- `--short` - omit remarks, notices, and links. Implies
`--nopager`.
- `--expand` - attempt to "expand" truncated entity objects.
- `--bypass-cache` - disable local cache of RDAP objects.
- `--auth=USER:PASS` - HTTP Basic Authentication credentials
to be used when accessing the specified resource.
- `--nopager` - by default, `rdapper` will pass its output
to `less(1)`. Setting `--nopager` disables this behaviour.
- `--raw` - output raw JSON response (implies `--nopager`).

# INSTALLATION

To install, run:

    perl Makefile.PL
    make
    sudo make install

You may need to manually install one or more of the dependencies
(listed below), if they are not already installed, using `cpanm` or
your operating system vendor's packages.

# DEPENDENCIES

`rdapper` uses the following modules, some of which may already be
installed:

- [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)
- [List::MoreUtils](https://metacpan.org/pod/List%3A%3AMoreUtils)
- [Net::ASN](https://metacpan.org/pod/Net%3A%3AASN)
- [Net::DNS::Domain](https://metacpan.org/pod/Net%3A%3ADNS%3A%3ADomain)
- [Net::IP](https://metacpan.org/pod/Net%3A%3AIP)
- [Net::RDAP](https://metacpan.org/pod/Net%3A%3ARDAP) (obviously)
- [Term::ANSIColor](https://metacpan.org/pod/Term%3A%3AANSIColor)
- [Text::Wrap](https://metacpan.org/pod/Text%3A%3AWrap)

# COPYRIGHT & LICENSE

Copyright (c) 2022 CentralNic Ltd. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.
