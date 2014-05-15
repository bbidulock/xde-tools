package XDG::Icons::Fast;
use base qw(XDG::Icons);
require Gtk2;
use strict;
use warnings;

=head1 NAME

XDG::Icons::Fast - read XDG icon directories quickly

=head1 SYNOPSIS

 my $icons = new XDG::Icons;
 my $icon = $icons->FindIcon('start-here',16,[qw(png xpm)]);
 my $best = $icons->FindBestIcon(['start-here','about'],16);

=head1 DESCRIPTION

B<XDG::Icons::Fast> is an implementation package for L<XDG::Icons(3pm)>
that uses L<Gtk2(3pm)> to look up icons.  L<Gtk2> uses an icon cache and
is far more speedly that the L<XDG::Icons::Slow(3pm)> approach which
must scan directories for icon files at least once on startup.

=head1 METHODS

The B<XDG::Icons::Fast> module provides the following methods:

=over

=item B<new>({I<%options>}) => XDG::Icons::Fast

Establishes the default theme, search directory paths, and reads all
available theme files (cache).  The I<%options> can be:

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
    my $self = bless {}, shift;
    my $options = shift;
    $options = {} unless $options;

    Gtk2->init; # in case it hasn't already been called

    my $icontheme;
    if ($options->{Theme}) {
	$icontheme = Gtk2::IconTheme->new;
	$icontheme->set_custom_theme($options->{Theme});
	$self->{theme} = $options->{Theme};
    } else {
	$icontheme = Gtk2::IconTheme->get_default;
    }
    $self->{icontheme} = $icontheme;

    if ($options->{Prepend}) {
	foreach my $dir (reverse split(/:/,$options->{Prepend})) {
	    $icontheme->prepend_search_path($dir);
	}
    }
    if ($options->{Append}) {
	foreach my $dir (split(/:/,$options->{Append})) {
	    $icontheme->append_search_path($dir);
	}
    }
    $self->{dirs} = [ $icontheme->get_search_path ];

    $self->{extensions} = [qw(png svg xpm)];
    if (my $ext = $options->{Extensions}) {
        if (ref $ext eq 'ARRAY') {
            $self->{extensions} = $ext;
        }
        else {
            $self->{extensions} = split(/,/,$ext);
        }
    }
    return $self;
}

=item B<FindIcon>(I<$icon>,I<$size>,[I<$ext>]) => I<$filename>

Requests that the filename of the icon with name, C<$icon>, be found for
size, C<$size>, with extensions optionally specified with the arrayref
C<$ext>.  The filename is returned or C<undef> when no suitable icon
file could be found.  When no icon file can be found with the specified
size, an icon of a suitably close size will be sought.  This method
falls back to fall-back directories (e.g. F</usr/share/pixmaps>) if a
matching name is not found, to search a list of alternate names, see
L</FindBestIcon>.

=cut

sub FindIcon {
    my($self,$icon,$size,$exts) = @_;
    $exts = $self->{extensions} unless $exts;
    my $flags = [ ((",".join(',',@$exts)."," =~ /,svg,/) ? 'force-svg' : 'no-svg') ];
    my $filename;
    my $icontheme = $self->{icontheme};
    my $iconinfo = $icontheme->lookup_icon($icon,$size,$flags);
    $filename = $iconinfo->get_filename if $iconinfo;
    return $filename;
}

=item B<FindBestIcon>(I<$iconlist>,I<$size>,[I<$ext>]) => I<$filename>

Like L</FindIcon>, but searches for icons with the names provided in the
entire array referenced by C<$iconlist> before falling back to fall-back
directories (e.g. F</usr/share/pixmaps>).

=cut

sub FindBestIcon {
    my($self,$iconlist,$size,$exts) = @_;
    $exts = $self->{extensions} unless $exts;
    my $flags = [ ((",".join(',',@$exts)."," =~ /,svg,/) ? 'force-svg' : 'no-svg') ];
    my $filename;
    my $icontheme = $self->{icontheme};
    my $iconinfo = $icontheme->choose_icon($iconlist,$size,$flags);
    $filename = $iconinfo->get_filename if $iconinfo;
    return $filename;
}

=item B<Directories>() => list

Returns the list of directories in which B<XDG::Icons::Fast> searched
for files.  This list can be used with L<Linux::Inotify2(3pm)> to
indicate when icon calculations many need to be rerun.  However,
L<Gtk2(3pm)> will perform the update calculations itself when the cache
is updated.

=cut

sub Directories {
    return @{shift->{dirs}};
}

=item B<Rescan>() => undef

Ask B<XDG::Icons::Fast> to rescan its directories for themes and prepare
to have icons searched in the new set of directories.  This simply asks
L<Gtk2(3pm)> to update its icon cache and reexamine the current icon
theme.

=cut

sub Rescan {
    return shift->{icontheme}->rescan_if_needed;
}

=back

=head1 ENVIRONMENT

B<XDG::Icons> interprets the following environment variables:

=over

=item B<HOME>

This environment variable must be set for B<XDG::Icons> to locate other
directories in accordance with XDG specifications.  Icon themes and
fall-backs will be sought in F<$HOME/.icons>.

=item B<XDG_DATA_HOME>

The user data directories.  When unset, this variable defaults to
F<$HOME/.local/share> in accordance with XDG specifications.  Icon
themes and fall-backs will be sought in F<$XDG_DATA_HOME/icons>.

=item B<XDG_DATA_DIRS>

The system data directories.  When unset, this variable defaults to
F</usr/local/share:/usr/share> in accordance with XDG specifications.
Icon themes and fall-backs will be sought in F<$XDG_DATA_DIRS/icons>.
In addition, a fall-back of F</usr/share/pixmaps> will be appended.

=item B<GTK_RC_FILES>

Tells L<Gtk2(3pm)> where to find RC files to determine the icon theme
when it is not otherwise specified.

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDG::Icons(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
