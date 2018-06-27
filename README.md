# NAME

`rdapper` - a simple console-based RDAP client

# SYNOPSIS

        rdapper OBJECT

`rdapper` is a simple RDAP client. It uses [Net::RDAP](https://metacpan.org/pod/Net::RDAP) to retrieve
data about internet resources (domain names, IP addresses, and
autonymous systems) and outputs the information in a human-readable
format. If you want to consume this data in your own program you
should use [Net::RDAP](https://metacpan.org/pod/Net::RDAP) directly.

`rdapper` was originally conceived as a full RDAP client (back
when the RDAP protocol was still in draft form) but is now just
a very thin front-end to [Net::RDAP](https://metacpan.org/pod/Net::RDAP), and its main purpose is to
allow testing of that library.

You can pass any internet resource as an argument; this may be a:

- a "forward" domain name such as `example.com`;
- a "reverse" domain name such as `168.192.in-addr.arpa`;
- a IPv4 or IPv6 address or CIDR prefix, such as `192.168.0.1` or `2001:DB8::/32`;
- an Autonymous System Number such as `AS65536`.

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

# COPYRIGHT

Copyright 2018 CentralNic Ltd. All rights reserved.

# LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
