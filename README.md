# NAME

App::rdapper - a simple console-based RDAP client.

# INSTALLATION

To install, run:

        cpanm --sudo App::rdapper

# RUNNING VIA DOCKER

The [git repository](https://github.com/gbxyz/rdapper) contains a `Dockerfile`
that can be used to build an image on your local system.

Alternatively, you can pull the [image from Docker Hub](https://hub.docker.com/r/gbxyz/rdapper):

        $ docker pull gbxyz/rdapper

        $ docker run -it gbxyz/rdapper --help

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

`rdapper` also implements limited support for in-bailiwick nameservers,
but you must use the `--type=nameserver` argument to disambiguate
from domain names. The RDAP server of the parent domain's registry will
be queried.

# ADDITIONAL ARGUMENTS

- `--registrar` - follow referral to the registrar's RDAP record
(if any) which will be displayed instead of the registry record.
- `--reverse` - if you provide an IP address or CIDR prefix, then
this option causes `rdapper` to display the record of the corresponding
`in-addr.arpa` or `ip6.arpa` domain.
- `--type=TYPE` - explicitly set the object type. `rdapper`
will guess the type by pattern matching the value of `OBJECT` but
you can override this by explicitly setting the `--type` argument
to one of : `ip`, `autnum`, `domain`, `nameserver`, `entity`
or `url`.

    If `--type=url` is used, `rdapper` will directly fetch the
    specified URL and attempt to process it as an RDAP response.

    If `--type=entity` is used, `OBJECT` must be a a string
    containing a "tagged" handle, such as `ABC123-EXAMPLE`, as per
    RFC 8521.

- `--help` - display help message.
- `--raw` - print the raw JSON rather than parsing it.
- `--short` - omit remarks, notices, and links.
- `--bypass-cache` - disable local cache of RDAP objects.
- `--auth=USER:PASS` - HTTP Basic Authentication credentials
to be used when accessing the specified resource.
- `--nocolor` - disable ANSI colors in the formatted output.

# COPYRIGHT & LICENSE

Copyright (c) 2023 CentralNic Ltd. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.
