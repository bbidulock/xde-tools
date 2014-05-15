package XDG::Icons::Slow;
use base qw(XDG::Icons);
require XDG::IconTheme;
require XDG::IconData;
use strict;
use warnings;

=head1 NAME

XDG::Icons::Slow - read XDG icon directories slowly

=head1 SYNOPSIS

 my $icons = new XDG::Icons;
 my $icon = $icons->FindIcon('start-here',16,[qw(png xpm)]);
 my $best = $icons->FindBestIcon(['start-here','about'],16);

=head1 DESCRIPTION

B<XDG::Icons::Slow> is an implementation package for L<XDG::Icons(3pm)>
that uses pure-perl lookup procedures derived from XDG specifications.
This can be quite slow, so L<XDG::Icons(3pm)> uses the
L<XDG::Icons::Fast(3pm)> whenever L<Gtk2(3pm)> is available.  The sole
purpose for this implementation is so that L<xdg-menugen(1)> can work on
systems without L<Gtk2(3pm)> installed, albeit more slowly.

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

The B<XDG::Icons::Slow> module provides the following methods:

=over

=item B<new>({I<%options>}) => XDG::Icons::Slow

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
    my $self = bless {}, shift;
    my $options = shift; $options = {} unless $options;
    $self->{dirs} = [];
    push @{$self->{dirs}}, "$ENV{HOME}/.icons";

    my $XDG_DATA_HOME = $ENV{XDG_DATA_HOME};
    $XDG_DATA_HOME = "$ENV{HOME}/.local/share" unless $XDG_DATA_HOME;
    $ENV{XDG_DATA_HOME} = $XDG_DATA_HOME;

    my $XDG_DATA_DIRS = $ENV{XDG_DATA_DIRS};
    $XDG_DATA_DIRS = "/usr/local/share:/usr/share" unless $XDG_DATA_DIRS;
    $ENV{XDG_DATA_DIRS} = $XDG_DATA_DIRS;

    my @XDG_DATA_DIRS = split(/:/,$XDG_DATA_HOME.':'.$XDG_DATA_DIRS);
    push @{$self->{dirs}}, map {"$_/icons"} @XDG_DATA_DIRS;
    push @{$self->{dirs}}, map {"$_/pixmaps"} @XDG_DATA_DIRS;

    unshift @{$self->{dirs}}, split(/:/,$options->{Prepend}) if $options->{Prepend};
    push    @{$self->{dirs}}, split(/:/,$options->{Append})  if $options->{Append};
    

    my $XDG_ICON_THEME = $ENV{XDG_ICON_THEME};
    unless ($XDG_ICON_THEME) {
	if (-f "$ENV{HOME}/.gtkrc-2.0") {
	    my @lines = (`cat $ENV{HOME}/.gtkrc-2.0`);
	    foreach (@lines) { chomp;
		if (m{gtk-icon-theme-name=["]?(.*[^"])["]?$}) {
		    $XDG_ICON_THEME = "$1";
		    last;
		}
	    }
	} else {
	    $XDG_ICON_THEME = 'hicolor';
	}
    }
    $XDG_ICON_THEME = $options->{Theme} if $options->{Theme};
    $ENV{XDG_ICON_THEME} = $XDG_ICON_THEME;
    $self->{theme} = $XDG_ICON_THEME;

    $self->{extensions} = [qw(png svg xpm)];
    if (my $ext = $options->{Extensions}) {
        if (ref $ext eq 'ARRAY') {
            $self->{extensions} = $ext;
        }
        else {
            $self->{extensions} = split(/,/,$ext);
        }
    }
    return $self->Rescan();
}

=item B<FindIcon>($icon,$size,[$ext]) => $filename

Requests that the filename of an icon with name, C<$icon>, be found for
size, C<$size>, with extensions optionally specified with the arrayref
C<$ext>.  The filename is returned or C<undef> when no suitable icon file
could be found.  When no icon file can be found with the specified size,
an icon of a suitably close size will be sought.  This method falls back
to fall-back directories (e.g. F</usr/share/pixmaps>) if a matching name
is not found, to search a list of alternate names, see L</FindBestIcon>.

=cut

sub FindIcon {
    my ($self,$icon,$size,$exts) = @_;
    my $fn = $self->_FindIconHelper($icon,$size,$self->{theme},$exts);
    return $fn if $fn;
    $fn = $self->_FindIconHelper($icon,$size,'hicolor',$exts);
    return $fn if $fn;
    return $self->_LookupFallbackIcon($icon,$exts);
}

sub _FindIconHelper {
    my ($self,$icon,$size,$name,$exts) = @_;
    my $theme = $self->{themes}{$name};
    return undef unless $theme;
    my $fn = $self->_LookupIcon($icon,$size,$theme,$exts);
    return $fn if $fn;
    if (my $inherit = $theme->{Inherits}) {
	$fn = $self->_FindIconHelper($icon,$size,$inherit,$exts);
	return $fn if $fn;
    }
    return $fn;
}

sub _LookupIcon {
    my ($self,$iconname,$size,$theme,$exts) = @_;
    $exts = $self->{extensions} unless $exts;
    foreach my $subdir ($theme->Directories) {
	if ($theme->DirectoryMatchesSize($subdir,$size)) {
	    foreach my $dir (@{$self->{dirs}}) {
		foreach my $ext (@$exts) {
			my $fn = "$dir/$theme->{name}/$subdir/$iconname.$ext";
			return $fn if -f $fn;
		}
	    }
	}
    }
    my $minimal_size = 0x7ffffff;
    my $closest_filename = undef;
    foreach my $subdir ($theme->Directories) {
	foreach my $dir (@{$self->{dirs}}) {
	    foreach my $ext (@$exts) {
		my $fn = "$dir/$theme->{name}/$subdir/$iconname.$ext";
		if (-f $fn and $theme->DirectorySizeDistance($subdir,$size) < $minimal_size) {
		    $closest_filename = $fn;
		    $minimal_size = $theme->DirectorySizeDistance($subdir,$size);
		}
	    }
	}
    }
    if ($closest_filename) {
	return $closest_filename;
    }
    return undef;
}

sub _LookupFallbackIcon {
    my ($self,$iconname,$exts) = @_;
    $exts = $self->{extensions} unless $exts;
    foreach my $dir (@{$self->{dirs}}) {
	foreach my $ext (@$exts) {
	    my $fn = "$dir/$iconname.$ext";
	    return $fn if -f $fn;
	}
    }
    return undef;
}

=item B<FindBestIcon>($iconlist,$size,[$ext]) => $filename

Like L</FindIcon>, but searches for icons with the names provided in the
entire array referenced by C<$iconlist> before falling back to fall-back
directories (e.g. F</usr/share/pixmaps>).

=cut

sub FindBestIcon {
    my ($self,$iconlist,$iconsize,$exts) = @_;
    my $fn = $self->_FindBestIconHelper($iconlist,$iconsize,$self->{theme},$exts);
    return $fn if $fn;
    $fn = $self->_FindBestIconHelper($iconlist,$iconsize,'hicolor',$exts);
    return $fn if $fn;
    foreach my $icon (@$iconlist) {
	$fn = $self->_LookupFallbackIcon($icon,$exts);
	return $fn if $fn;
    }
    return undef;
}

sub _FindBestIconHelper {
    my ($self,$iconlist,$iconsize,$name,$exts) = @_;
    my $theme = $self->{themes}{$name};
    return undef unless $theme;
    foreach my $icon (@$iconlist) {
	my $fn = $self->_LookupIcon($icon,$iconsize,$theme,$exts);
	return $fn if $fn;
    }
    if (my $parent = $theme->{Inherits}) {
	my $fn = $self->_FindBestIconHelper($iconlist,$iconsize,$parent,$exts);
	return $fn if $fn;
    }
    return undef;
}

=item B<Directories>() => list

Returns the list of directories in which B<XDG::Icons> searched for
files.  This list can be used with L<Linux::Inotify2(3pm)> to indicate
when icon calculations many need to be rerun.

=cut

sub Directories {
	my $self = shift;
	return @{$self->{dirs}};
}

=item B<Rescan>() => undef

Ask B<XDG::Icons> to rescan its directories for themes and prepare to
have icons searched in the new set of directories.

=cut

sub Rescan {
    my $self = shift;
    $self->{themes} = {};
    foreach my $dir (reverse @{$self->{dirs}}) {
	opendir(my $fh, $dir) or next;
	foreach my $subdir (readdir($fh)) {
	    next if $subdir eq '.' or $subdir eq '..';
	    next unless -d "$dir/$subdir";
	    if (-f "$dir/$subdir/index.theme") {
		if (my $theme = new XDG::IconTheme("$dir/$subdir/index.theme")) {
		    $theme->{name} = $subdir;
		    $self->{themes}{$subdir} = $theme;
		}
	    }
	}
	close($fh);
    }
    return $self;
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

=item B<XDG_ICON_THEME>

The user icon theme.  When unset, the variable will be derived from
F<$HOME/.gtkrc-2.0> if it exists, and set to C<hicolor>, otherwise.

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDG::Icons(3pm)>,
L<XDG::IconTheme(3pm)>,
L<XDG::IconData(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
