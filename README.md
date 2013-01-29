# NAME

rdapper - a command-line RDAP client.

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

    Specify the type of object being queried. Possible values are: `domain`, 
    `entity` (also `contact`), `nameserver` (also `host`), `autnum` and `ip`.
    rdapper will detect IPv4 and IPv6 addresses and CIDR networks and AS numbers, and
    will fall back to domain queries for everything else.

- \--follow

    Instructs rdapper to follow links to retrieve full entity information.

- \--links

    Display URIs for referenced objects.

- \--path=PATH

    Specify a JSONPath query. Any elements in the response which match this path
    will be printed in JSON format.

    See below for details of JSONPath.

- \--tls

    Force use of TLS.

- \--insecure

    Disable server certificate checking and hostname verification.

- \--username=USERNAME

    Specify a username to be used with Basic Authentication.

- \--password=PASSWORD

    Specify a password to be used with Basic Authentication.

    Note: if the initial request is redirected, authentication credentials will be
    sent in the subsequent request to the target server, so users should consider
    whether these credentials might be disclosed inappropriately.

- \--cert=CERTIFICATE

    Specify a client SSL certificate to present to the server.

- \--key=KEY

    Specify a private key matching the certificate given in `--cert`.

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

# JSONPath

You can use JSONPath to specify a subset of the complete response. JSONPath is
an XPath-like syntax for querying JSON structures. The following are examples of
JSONPath queries:

	$.handle		# the handle of an object
	$.nameServers[0].name	# the name of a domain's first nameserver
	$.entities[0].emails[0]	# the first email address of an object's first entity
	$.nameServers..name	# the names of every nameserver

For a full explanation of the available syntax, see the link below.

# USE OF RDAP.ORG

Unless instructed otherwise (via the `--host` argument), rdapper will send 
all queries to rdap.org: this server is an aggregator of RDAP services, and will
provide an HTTP redirect to the appropriate service where available.

# SEE ALSO

- [http://tools.ietf.org/wg/weirds/](http://tools.ietf.org/wg/weirds/)
- [https://www.centralnic.com/](https://www.centralnic.com/)
- [http://rdap.org/](http://rdap.org/)
- [http://goessner.net/articles/JsonPath/](http://goessner.net/articles/JsonPath/)

# COPYRIGHT

rdapper is Copyright 2013 CentralNic Ltd. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.
