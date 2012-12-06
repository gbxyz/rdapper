rdapper is a command line client to the RDAP protocol (also known as WEIRDS).
See http://datatracker.ietf.org/wg/weirds/charter/ for further info.

## Usage

rdapper --host=HOST [--type=TYPE] QUERY

Options:
  --help                Show this help
  --host=HOST           Set server hostname
  --type=TYPE           Set query type (default: domain)
  --raw			Show raw JSON response

## Dependencies

* LWP
* JSON

Both can be trivially installed from your upstream software vendor or CPAN

## License

rdapper is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
