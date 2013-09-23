package XDE::Theme;
use base qw(XDE::Dual XDE::Actions);
use Linux::Inotify2;
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Theme - theme monitor and switcher for XDE

=head1 SYNOPSIS

 use XDE::Theme;

 my $xde = new XDG::Theme;
 $SIG{TERM} = sub{$xde->main_quit};
 $xde->init;
 $xde->set_theme(@themes);
 $xde->main;
 $xde->term;

=head1 DESCRIPTION

Provides a module that runs out of the L<Glib::Mainloop> that will set
the L<XDE> theme on a lightweight desktop and monitor for window manager
style changes.  When the style changes, the module will adjust the GTK2
theme for L<XDE> to a corresponding GTK2 theme.

=head1 METHODS

Most methods provided by XDE::Theme are internal functions used by the
module to implement certain functionality.  Only the B<new>, B<init>,
B<set_theme>, B<main> and B<term> functions are meant to be
called by the user of this package.

XDE::Theme provides the following methods:

=over

=cut

=item $theme = B<new> XDE::Theme I<%OVERRIDES>

Creates an instance of an XDE::Theme object.  The XDE::Theme module uses
the L<XDE::Context(3pm)> module as a base, so the I<%OVERRIDES> are
simply passed to the L<XDE::Context> module.

=cut

sub new {
    return XDE::Context::new(@_);
}

=item $theme->B<_init>() => $theme

Performs initialization for just this module.  Called after
L<XDE::Dual(3pm)> is fully initialized.  Determines the initial values
and settings of the root window on each screen of the display for
later management of themes.

=cut

sub _init {
    my $self = shift;
    # Set up an Inotify2 connection.
    my $N = $self->{N};
    unless ($N) {
	$N = $self->{N} = Linux::Inotify2->new;
	$N->blocking(FALSE);
    }
    Glib::Source->remove(delete $self->{notify}{watcher})
	if $self->{notify}{watcher};
    $self->{notify}{watcher} = Glib::IO->add_watch($N->fileno,
	    'in', sub{ $N->poll });

    # initialize extensions
    my $X = $self->{X};
    $X->init_extensions;

    # set up the EWMH/WMH environment
    $self->XDE::Actions::setup;

    $self->check_theme;
    return $self;
}

=item $theme->B<_term>() => $theme

Performs termination for just this module.  Called before
C<XDE::X11-E<gt>term()> is called.

=cut

sub _term {
    my $self = shift;
    return $self;
}

=item $theme->B<watch_theme_file>(I<$label>,I<$file>) => $boolean

Establish (I<$file> is set) or relinquish (I<$file> is null) a watcher
for modifications to a theme file.  On modifications to the file, the
watcher will recheck the theme.

=cut

sub watch_theme_file {
    my ($self,$label,$file) = @_;
    return 0 if $self->{$label} and $self->{$label} eq $file;
    $self->{$label} = $file;
    my $N = $self->{N};
    delete($self->{notify}{$label})->cancel
	if $self->{notify}{$label};
    $self->{notify}{$label} = $N->watch($file, IN_MODIFY, sub{
	    my $e = shift;
	    if ($self->{ops}{verbose}) {
		print STDERR "----------------------\n";
		print STDERR "$e->{w}{name} was modified\n"
		    if $e->IN_MODIFY;
		print STDERR "Rechecking theme\n";
	    }
	    $self->check_theme;
    }) if $file;
    return 1;
}

=item $theme->B<set_theme>(I<@themes>)

Sets the theme according to the list of theme names specified with
I<@themes>.  The first valid theme name is used, otherwise, a diagnostic
message is printed and no action is performed.

=cut

sub set_theme {
    my $self = shift;
    my (@themes) = @_;
}

=item $theme->B<set_theme_FLUXBOX>(I<@themes>)

Sets the theme explicitly for L<fluxbox(1)>.  L<fluxbox> sets its style
by changing the C<session.styleFile> argument in the L<fluxbox>
F<~/.fluxbox/init> file and then reloads the configuration.  We can do
the same.  We should check; however, whether the F<~/.fluxbox/init> file
is the file in use.

=cut

sub set_theme_FLUXBOX {
    my $self = shift;
    my (@themes) = @_;
}

=item $theme->B<set_theme_BLACKBOX>(I<@themes>)

=cut

sub set_theme_BLACKBOX {
    my $self = shift;
    my (@themes) = @_;
}

=item $theme->B<set_theme_OPENBOX>(I<@themes>)

=cut

sub set_theme_OPENBOX {
    my $self = shift;
    my (@themes) = @_;
}

=item $theme->B<set_theme_ICEWM>(I<@themes>)

=cut

sub set_theme_ICEWM {
    my $self = shift;
    my (@themes) = @_;
}

=item $theme->B<set_theme_JWM>(I<@themes>)

=cut

sub set_theme_JWM {
    my $self = shift;
    my (@themes) = @_;
}

=item $theme->B<set_theme_PEKWM>(I<@themes>)

=cut

sub set_theme_PEKWM {
    my $self = shift;
    my (@themes) = @_;
}

=item $theme->B<set_theme_FVWM>(I<@themes>)

=cut

sub set_theme_FVWM {
    my $self = shift;
    my (@themes) = @_;
}

=item $theme->B<set_theme_WMAKER>(I<@themes>)

=cut

sub set_theme_WMAKER {
    my $self = shift;
    my (@themes) = @_;
}

=item $theme->B<set_theme_AFTERSTEP>(I<@themes>)

=cut

sub set_theme_AFTERSTEP {
    my $self = shift;
    my (@themes) = @_;
}

=item $theme->B<set_theme_METACITY>(I<@themes>)

=cut

sub set_theme_METACITY {
    my $self = shift;
    my (@themes) = @_;
}

=item $theme->B<check_theme>() => $theme

Gets the theme according to the window manager, checks for a theme
change, and coordinates a theme change when necessary.

=cut

sub check_theme {
    my $self = shift;
}

=item $theme->B<get_theme_by_name>(I<$name>) => %e

Search out in XDG theme directories an XDE theme with the name,
I<$name>, and collect the sections and fields into a hash reference.
The keys of the hash reference are the sections in the file with subkeys
representing fields in the section.  An empty hash is returned when no
file of the appropriate name could be found or if the file was empty.
When successful, C<$e{file}> contains the filename read.

Because the theme name is derived from the window manager specific style
file or directory, it is possible to symbolicly link an arbitrary style
to a window manager specific style file or directory to associate it
with an XDE theme.  In this way, different XDE themes can use the same
window manager style.

Themes consist of a C<[Theme]> section that contains definitions that
apply to all window managers.  A window-manager-specific section can be
included, (e.g. C<[fluxbox]>) that provides overrides for that window
manager.

Themefiles are named F<theme.ini> and contain the following fields in
the C<[Theme]> section.  Any fields amy be overridden by a window
manager specific section (e.g. C<[fluxbox]>).

=over

 [Theme]
 Name=Airforce
 Style=Squared-green
 
 WallpaperDefault=emeraldcoast
 WallpaperRepeat=true
 Wallpaper0=emeraldcoast
 Wallpaper1=squad
 Wallpaper2=thunderbird
 Wallpaper3=overalaska
 
 Workspaces=6
 WorkspaceNames= 1 , 2 , 3 , 4 , 5 , 6 , 7 , 8 , 9 
 
 WorkspaceColor=rgb:00/20/40
 WorkspaceCenter=0
 WorkspaceScaled=0
 WorkspaceFull=1
 WorkspaceImage=airforce/emeraldcoast.jpg
 
 Workspace0Image=airforce/emeraldcoast.jpg
 Workspace1Image=airforce/fighterjets.jpg
 Workspace2Image=airforce/squad.jpg
 Workspace3Image=airforce/landing.jpg
 Workspace4Image=airforce/thunderbird.jpg
 Workspace5Image=airforce/overalaska.jpg
 
 [Xsettings]
 Gtk/ButtonImages=1
 Gtk/ColorScheme=
 Gtk/CursorThemeName=
 Gtk/CursorThemeSize=18
 Gtk/EnableEventInputFeedbackSounds=1
 Gtk/EnableEventSounds=1
 Gtk/FallbackIconTheme=
 Gtk/FontName=Liberation Sans 9
 Gtk/IconSizes=
 Gtk/IconThemeName=Mist
 Gtk/KeyThemeName=
 Gtk/MenuBarAccel=F10
 Gtk/MenuImages=1
 Gtk/SoundThemeName=freedesktop
 Gtk/ThemeName=Mist
 Gtk/ToolbarIconSize=2
 Gtk/ToolbarStyle=2
 
 Net/EnableEventSounds=1
 Net/EnableInputFeedbackSounds=1
 Net/IconThemeName=Mist
 Net/ThemeName=Mist
 
 Xft/Antialias=1
 Xft/Hinting=1
 Xft/HintStyle=hintfull
 Xft/RGBA=rgb
 
 Xde/ThemeName=Airforce
 Xde/MenuThemeName=Squared-green
 
 [fluxbox]
 
 [blackbox]
 WorkspaceNames=Workspace 1,Workspace 2,Workspace 3,\
		Workspace 4,Workspace 5,Workspace 6,\
		Workspace 7,Workspace 8,Workspace 9
 
 [openbox]
 WorkspaceNames=1,2,3,4,5,6,7,8,9
 
 [icewm]
 
 [jwm]
 WorkspaceNames=1,2,3,4,5,6,7,8,9
 
 [pekwm]
 
 [fvwm]
 
 [wmaker]

=back

=cut

sub get_theme_by_name {
    my ($self,$name) = @_;
    my $v = $self->{ops}{verbose};
    print STDERR "Getting theme for '$name'\n" if $v;
    foreach my $d (map{"$_/themes/$name"}@{$self->{XDG_DATA_ARRAY}}) {
	print STDERR "Checking directory '$d'\n" if $v;
	next unless -d $d;
	my $f = "$d/xde/theme.ini";
	print STDERR "Checking file '$f'\n" if $v;
	next unless -f $f;
	print STDERR "Found file '$f'\n" if $v;
	open (my $fh,"<",$f) or next;
	print STDERR "Reading file '$f'\n" if $v;
	my %e = (file=>$f,theme=>$name);
	my $section;
	while (<$fh>) { chomp;
	    next if m{^\s*\#}; # comment
	    if (m{^\[([^]]*)\]}) {
		$section = $1;
		print STDERR "Starting section '$section'\n" if $v;
	    }
	    elsif ($section and m{^([^=]*)=([^[:cntrl:]]*)}) {
		$e{$section}{$1} = $2;
		print STDERR "Reading field $1=$2\n" if $v;
	    }
	}
	close($fh);
	my $short = $1 if $self->{ops}{lang} =~ m{^(..)};
	$e{Theme}{Name} = $name unless $e{Theme}{Name};
	$e{Xsettings}{'Xde/ThemeName'} = $e{Theme}{Name}
	    unless $e{Xsettings}{'Xde/ThemeName'};
	foreach my $wm (qw(fluxbox blackbox openbox icewm jwm pekwm fvwm wmaker)) {
	    foreach (keys %{$e{Theme}}) {
		$e{$wm}{$_} = $e{Theme}{$_} unless exists $e{$wm}{$_};
	    }
	}
	my %r = ();
	my $theme = 'Theme';
	$theme = $self->{wmname} if $self->{wmname};
	foreach (keys %{$e{$self->{wmname}}}) {
	    my $valu = $e{$self->{wmname}}{$_};
	    if (m{^Workspace(\d+)?(Color|Image|Center|Scaled|Tiled|Full)}) {
		my $spec = (defined $1 and $1 ne '') ? $1 : 'all';
		my $part = $2;
#		$r{workspace}{$spec}{mode} = $r{workspace}{all}{mode}
#		    unless $r{workspace}{$spec}{mode};
#		$r{workspace}{$spec}{mode} = 'tiled'
#		    unless $r{workspace}{$spec}{mode};
		$r{numb} = $spec+1 if $spec ne 'all' and
		    (not defined $r{numb} or $spec >= $r{numb});
		if ($part eq 'Image') {
		    $r{workspace}{$spec}{pixmap} = $valu;
		}
		elsif ($part eq 'Color') {
		    $r{workspace}{$spec}{color} = $valu;
		}
		elsif ($part eq 'Center') {
		    $r{workspace}{$spec}{mode} = 'centered' if $valu =~ m{yes|true|1}i;
		}
		elsif ($part eq 'Scaled') {
		    $r{workspace}{$spec}{mode} = 'aspect' if $valu =~ m{yes|true|1}i;
		}
		elsif ($part eq 'Full') {
		    $r{workspace}{$spec}{mode} = 'fullscreen' if $valu =~ m{yes|true|1}i;
		}
	    }
	    elsif ($_ eq 'Workspaces') {
		$r{workspaces} = $valu;
	    }
	    elsif ($_ eq 'WorkspaceNames') {
		my $names = $valu;
		my @names = split(/,/,$names);
		$r{workspaces} = scalar(@names) unless $r{workspaces};
		$r{workspaceNames} = \@names;
	    }
	}
	$r{workspace}{all}{mode} = 'tiled'
	    unless $r{workspace}{all}{mode};
	if ($r{numb}) {
	    for (my $i=0;$i<$r{numb};$i++) {
		$r{workspace}{$i}{mode} = $r{workspace}{all}{mode}
		    unless $r{workspace}{$i}{mode};
	    }
	}
	%r = $self->correct_theme(%r);
	return %r;
    }
    return ();
}

=item $theme->B<read_anybox_style>(I<$file>) => $stylefile

Reads the F<init> or F<rc> file specified by I<$file> and obtains the
file name specified against the C<session.styleFile> resource.  This
works for L<fluxbox(1)> and L<blackbox(1)> but not L<openbox(1)> any
more, but use use the C<_OB_THEME> root window property for
L<openbox(1)> anyway.

=cut

sub read_anybox_style {
    my ($self,$file) = @_;
    if (-f $file) {
	print STDERR "Reading $file\n" if $self->{ops}{verbose};
	if (open(my $fh,"<",$file)) {
	    while (<$fh>) { chomp;
		next unless m{^session.styleFile:\s+(.*)};
		$style = $1; $style =~ s{\s+$}{};
		print STDERR "Anybox style file is: $style\n"
		    if $self->{ops}{verbose};
		last;
	    }
	} else {
	    warn $!;
	}
    } else {
	print STDERR "File '$file' does not exist\n";
    }
    return $style;
}

=item $theme->B<check_theme_FLUXBOX>() => $theme

Gets the style reported by the L<fluxbox(1)> window manager.

When L<fluxbox> changes its style, it writes the new style in the
C<session.styleFile> resource in the F<~/.fluxbox/init> file.  Note,
however, that unlike other window managers, it does not restart.
(Unfortunately this also leads to L<fluxbox> not correctly changing the
style of L<fluxbox> menus.)  We use L<Linux::Inotify2> to help us detect
a change to the file.  We might be able to also use L<fluxbox-remote(1)>
to restart L<fluxbox> and have it correctly render menus under the new
style.

Note also that F<~/.fluxbox/init> might be the incorrect file depending
on how L<fluxbox> was started.  We might also be able to use
L<fluxbox-remote(1)> to get L<fluxbox> to surrender its primary
configuration file path.  However, it is atypical to set up L<fluxbox>
to permit L<fluxbox-remote(1)> at all.

=cut

sub check_theme_FLUXBOX {
    my $self = shift;
    my $config = "$ENV{HOME}/.fluxbox/init"; # for now
    $self->watch_theme_file(config=>$config);
    my $style = $self->read_anybox_style($config) or return;
    $style = "$style/theme.cfg" if -d $style;
    return 0 if $self->{style} and $self->{style} eq $style;
    $self->{style} = $style;
#   THEME CHANGED
    my %r;
    my $theme = $style; $theme =~ s{/theme\.cfg$}{}; $theme =~ s{.*/}{};
    %r = $self->get_theme_by_name($theme);
    my $gtktheme = '';
    if (%r) {
	$gtktheme = $r{'Xde/ThemeName'};
	$gtktheme = $r{'Gtk/ThemeName'} unless $gtktheme;
	$gtktheme = $r{'Net/ThemeName'} unless $gtktheme;
	$gtktheme = '' unless $gtktheme;
    }
    return 0 if defined($self->{gtktheme}) and $self->{gtktheme} eq $gtktheme;
#   GTK2 THEME CHANGED
    $self->{gtktheme} = $gtktheme;
    $self->set_theme_name($gtktheme);
    return 1;
}

=item $theme->B<check_theme_BLACKBOX>() => $theme

Gets the style reported by the L<blackbox(1)> window manager.

=cut

sub check_theme_BLACKBOX {
    my $self = shift;
}

=item $theme->B<check_theme_OPENBOX>() => $theme

Gets the style reported by the L<openbox(1)> window manager.

=cut

sub check_theme_OPENBOX {
    my $self = shift;
}

=item $theme->B<check_theme_ICEWM>() => $theme

Gets the style reported by the L<icewm(1)> window manager.

=cut

sub check_theme_ICEWM {
    my $self = shift;
}

=item $theme->B<check_theme_JWM>() => $theme

Gets the style reported by the L<jwm(1)> window manager.

=cut

sub check_theme_JWM {
    my $self = shift;
}

=item $theme->B<check_theme_PEKWM>() => $theme

Gets the style reported by the L<pekwm(1)> window manager.

=cut

sub check_theme_PEKWM {
    my $self = shift;
}

=item $theme->B<check_theme_FVWM>() => $theme

Gets the style reported by the L<fvwm(1)> window manager.

=cut

sub check_theme_FVWM {
    my $self = shift;
}

=item $theme->B<check_theme_WMAKER>() => $theme

Gets the style reported by the L<wmaker(1)> window manager.

=cut

sub check_theme_WMAKER {
    my $self = shift;
}

=item $theme->B<check_theme_AFTERSTEP>() => $theme

Gets the style reported by the L<afterstep(1)> window manager.

=cut

sub check_theme_AFTERSTEP {
    my $self = shift;
}

=item $theme->B<check_theme_METACITY>() => $theme

Gets the style reported by the L<metacity(1)> window manager.

=cut

sub check_theme_METACITY {
    my $self = shift;
}

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72

