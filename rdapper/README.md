# NAME

rdapper

# DESCRIPTION

rdapper is a command-line client for the Registration Data Access Protocol
(RDAP), the successor protocol to Whois (RFC 3912). RDAP is currently being
developed by the WEIRDS IETF working group, and has not yet been finalized.

This tool will send an RDAP query to an RDAP server over HTTP or HTTPS, parse
the JSON response, and display it in human-readable form.

# USAGE

    rdapper --host=HOST [--type=TYPE] [--tls] [--raw] QUERY

# OPTIONS

- \--host=HOST

    Specify the host to query

- \--TYPE=TYPE (default: domain)

    Specify the type of object being queried. Possible values are: domain, entity,
    nameserver, autnum, ip.

- \--tls

    Force use of TLS.

- \--raw

    Causes rdapper to emit pretty-printed JSON rather than text output.

# SEE ALSO

- [http://tools.ietf.org/wg/weirds/](http://tools.ietf.org/wg/weirds/)
- [https://www.centralnic.com/](https://www.centralnic.com/)

# COPYRIGHT

rdapper is Copyright 2012 CentralNic Ltd. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.
