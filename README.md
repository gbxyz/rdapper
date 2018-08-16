# NAME

`rdapper` - a simple console-based RDAP client.

# SYNOPSIS

        rdapper OBJECT

# DESCRIPTION

`rdapper` is a simple RDAP client. It uses [Net::RDAP](https://metacpan.org/pod/Net::RDAP) to retrieve
data about internet resources (domain names, IP addresses, and
autonymous systems) and outputs the information in a human-readable
format. If you want to consume this data in your own program you
should use [Net::RDAP](https://metacpan.org/pod/Net::RDAP) directly.

`rdapper` was originally conceived as a full RDAP client (back
when the RDAP protocol was still in draft form) but is now just
a very thin front-end to [Net::RDAP](https://metacpan.org/pod/Net::RDAP), and its main purpose is to
allow testing of that library.

# OPTIONS

You can pass any internet resource as an argument; this may be:

- a "forward" domain name such as `example.com`;
- a "reverse" domain name such as `168.192.in-addr.arpa`;
- a IPv4 or IPv6 address or CIDR prefix, such as `192.168.0.1`
or `2001:DB8::/32`;
- an Autonymous System Number such as `AS65536`.
- the URL of an RDAP resource such as
`https://example.com/rdap/domain/example.com`.

## ADDITIONAL ARGUMENTS

- `--type=TYPE` - explicitly set the object type. `rdapper`
will guess the type by pattern matching the value of `OBJECT` but
you can override this by explicitly setting the `--type` argument
to one of : `ip`, `autnum`, `domain` or `url`.

    If `--type=url` is used, `rdapper` will directly fetch the
    specified URL and attempt to process it as an RDAP response.

- `--help` - display help message.
- `--debug` - enable [Net::RDAP](https://metacpan.org/pod/Net::RDAP) debug mode.
- `--short` - omit remarks, notices, and links.
- `--expand` - attempt to "expand" truncated entity objects.
- `--bypass-cache` - disable local cache of RDAP objects.

# DEPENDENCIES

`rdapper` uses the following modules, some of which may already be
installed:

- [Getopt::Long](https://metacpan.org/pod/Getopt::Long)
- [List::MoreUtils](https://metacpan.org/pod/List::MoreUtils)
- [Net::ASN](https://metacpan.org/pod/Net::ASN)
- [Net::DNS::Domain](https://metacpan.org/pod/Net::DNS::Domain)
- [Net::IP](https://metacpan.org/pod/Net::IP)
- [Net::RDAP](https://metacpan.org/pod/Net::RDAP) (obviously)
- [Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor)
- [Text::Wrap](https://metacpan.org/pod/Text::Wrap)

# COPYRIGHT

Copyright 2018 CentralNic Ltd. All rights reserved.

# LICENSE

Copyright (c) 2018 CentralNic Ltd. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.
