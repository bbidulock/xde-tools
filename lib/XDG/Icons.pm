package XDG::Icons;
use base qw(XDG::Context);
use strict;
use warnings;
use vars qw($FAST);

if (!eval { require Gtk2; }) {
    $FAST = 0;
    use XDG::Icons::Slow;
} else {
    $FAST = 1;
    use XDG::Icons::Fast;
}

=head1 NAME

XDG::Icons - read XDG icon directories

=head1 SYNOPSIS

 my $icons = new XDG::Icons;
 my $icon = $icons->FindIcon('start-here',16,[qw(png xpm)]);
 my $best = $icons->FindBestIcon(['start-here','about'],16);

=head1 DESCRIPTION

The following is from the XDG Icon specification:

=over

By default, apps should look in F<$HOME/.icons> (for backward
compatibility), in F<$XDG_DATA_DIRS/icons> and in F</usr/share/pixmaps>
(in that order).  Applications may further add their own icon
directories to this list, and users may extend or change the list (in
application/desktop specific ways).  In each of these directories themes
are stored as subdirectories.  A theme can be spread across several base
directories by having subdirectories of the same name.  This way users
can extend an override system themes.

To have a place for third party applications to install their icons,
there should always exist a theme called C<hicolor>.  The data for the
C<hicolor> theme is available for download at L<http://freedesktop.org>.
Implementations are required to look in the C<hicolor> theme if an icon
was not found in the current theme.

Each theme is stored as subdirectories of the base directories.  The
internal name of the theme is the name of the subdirectory, although the
user-visible name as specified by the theme may be different.  Hence,
theme names are case sensitive, and are limited to ASCII characters.
Theme names may also not contain comma or space.

In at least one of the theme directories there must be a file called
index.theme that describes the theme.  The first index.theme found while
searching the base directories in order is used.  This file describes
the general attributes of the theme.

In the theme directory are also a set of subdirectories containing image
files.  Each directory contains icons designed for a certain nominal
icon size, as described by the index.theme file.  The subdirectories are
allowed to be several levels deep, e.g. the subdirectory F<48x48/apps>
in the theme F<hicolor> would end up at F<$basedir/hicolor/48x48/apps>.

The image files must be one of the types: PNG, XPM, or SVG, and the
extension must be F<.png>, F<.xpm>, or F<.svg> (lower case).  The
support for SVG files is optional.  Implementations that do not support
SVGs should just ignore any F<.svg> files.  In addition to this there
may be an additional file with extra icon-data for each file.  It should
have the same base name as the image file, with the extension F<.icon>.

=back

=head1 METHODS

The XDG::Icons module provides the following methods:

=over

=item B<new>({I<%options>}) => XDG::Icons

Establishes the default theme, search directory paths, and reads all
available theme files.  The I<%options> can be:

=over

=item I<Prepend> => $directory

Prepend the given directory, C<$directory>, or colon-separated list of
directories, to the directory search path.

=item I<Append> => $directory

Append the given directory, C<$directory>, or colon-separated list of
directories, to the directory search path.

=item I<Theme> => $name

Use the given theme name, C<$name>, as the default icon theme.

=item I<Extensions> => [ $ext1, $ext2 ] or "$ext1,$ext2"

Specify the extensions to search.  The default if unspecified is 'png',
'svg' and 'xpm', in that order.  Extensions may be specified with an
arrayref or a scalar comma-separated list of extensions.

=back

=cut

sub new {
    my($type,$options) = @_;
    if ($FAST) {
	return XDG::Icons::Fast->new($options);
    } else {
	return XDG::Icons::Slow->new($options);
    }
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDG::Icons::Fast(3pm)>,
L<XDG::Icons::Slow(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
