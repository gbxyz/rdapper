# NAME

rdapper

# DESCRIPTION

rdapper is a command-line client for the Registration Data Access Protocol
(RDAP), the successor protocol to Whois (RFC 3912). RDAP is currently being
developed by the WEIRDS IETF working group, and has not yet been finalized.

This tool will send an RDAP query to an RDAP server over HTTP or HTTPS, parse
the JSON response, and display it in human-readable form.

# INSTALLING

To install this program type the following commands in the source directory:

    perl Makefile.PL
    make
    make install

# USAGE

    rdapper [OPTIONS] QUERY

# OPTIONS

- \--host=HOST (default: rdap.org)

    Specify the host to query. If not set, rdapper uses `rdap.org` (see below).

- \--TYPE=TYPE

    Specify the type of object being queried. Possible values are: domain, 
    entity, nameserver, autnum, ip. Rdapper will automatically detect IPv4 
    and IPv6 addresses and AS numbers, and will fall back to domain queries 
    for everything else.

- \--tls

    Force use of TLS.

- \--username=USERNAME

    Specify a username to be used with Basic Authentication.

- \--password=PASSWORD

    Specify a password to be used with Basic Authentication.

- \--cert=CERTIFICATE

    Specify a client SSL certificate to present to the server.

- \--key=KEY

    Specify a private key matching the certificate given in `--password`.

- \--keypass=PASSPHRASE

    Specify a passphrase to decrypt the private key given by `--key`.

- \--raw

    Causes rdapper to emit pretty-printed JSON rather than text output.

- \--debug

    Causes rdapper to display the HTTP request and response rather than the text
    output.

- \--lang=LANGUAGE

    Specify a language. This is sent to the server using the `Accept-Language`
    header. If unset, the language will be taken from your `$LANG` environment
    variable (or `en` if that is not defined).

- \--encoding=ENCODING

    Specify an encoding. This is sent to the server using the `Accept-Encoding`
    header. If unset, the encoding will be taken from your `$LANG` environment
    variable (or `UTF-8` if that is not defined).

# USE OF RDAP.ORG

Unless instructed otherwise (via the --host argument), rdapper will send 
all queries to rdap.org: this server is an aggregator of RDAP services, 
and will provide an HTTP redirect where available.

# SEE ALSO

- [http://tools.ietf.org/wg/weirds/](http://tools.ietf.org/wg/weirds/)
- [https://www.centralnic.com/](https://www.centralnic.com/)
- [http://rdap.org/](http://rdap.org/)

# COPYRIGHT

rdapper is Copyright 2012 CentralNic Ltd. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.
