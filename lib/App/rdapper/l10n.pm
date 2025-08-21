package App::rdapper::l10n;
use base qw(Locale::Maketext::Gettext);

=pod

=head1 NAME

C<App::rdapper::l10n> - internationalisation support for L<App::rdapper>

=head1 DESCRIPTION

The L<rdapper|App::rdapper> RDAP client can generate output that is localized to
the user's locale. It uses L<Locale::Maketext::Gettext> and a dictionary of
translated strings stored in .po files.

=head1 TRANSLATING STRINGS

C<rdapper> has an undocumented command line option, C<--strings>, which causes
it to print a .pot template on STDOUT. This is used to generate the
C<rdapper.pot> file in the C<locale> directory.

This directory contains subdirectories for each supported locale. To create a
new locale, create a new subdirectory and copy C<rdapper.pot> into it:

    $ mkdir -p ja/LC_MESSAGES
    $ cp rdapper.pot ja/LC_MESSAGES/rdapper.po

Once you have finished editing C<rdapper.po>, run C<mkmo.sh> to compile the
.po files into .mo files. These files are installed automatically when rdapper
is installed.

You will also need to edit the file C<l10.pm> to add a new package, which must
look like this:

    package App::rdapper::l10n::ja;
    use base qw(Locale::Maketext::Gettext);
    1;

=head1 CONTRIBUTING TRANSLATIONS

Translations are gratefully accepted. To contribute one, please L<fork the
repository|https://github.com/gbxyz/rdapper/fork>, make your edits, and then
L<submit a pull request|https://github.com/gbxyz/rdapper/compare>.

=cut

1;

#
# if you're adding a new language package, put it **BELOW** this comment!
#

package App::rdapper::l10n::en;
use base qw(Locale::Maketext::Gettext);
1;

package App::rdapper::l10n::es;
use base qw(Locale::Maketext::Gettext);
1;

package App::rdapper::l10n::fr;
use base qw(Locale::Maketext::Gettext);
1;

package App::rdapper::l10n::de;
use base qw(Locale::Maketext::Gettext);
1;

package App::rdapper::l10n::pt;
use base qw(Locale::Maketext::Gettext);
1;

#
# if you're adding a new language package, put it **ABOVE** this comment!
#
