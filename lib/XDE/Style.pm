package XDE::Style;
use base qw(XDE::Actions);
use Linux::Inotify2;
use strict;
use warnings;

=head1 NAME

XDE::Style - provides methods for monitoring and managing window manager styles

=head1 SYNOPSIS

 package XDE::Setbg;
 use base qw(XDE::Dual XDE::Style);

=head1 DESCRIPTION

Provides a module with methods that can be used to monitor and manage
style changes in window managers supported by L<XDE(3pm)>.

=head1 METHODS

This module provides the following methods:

=over

=cut

=item $style->B<_init>() => $style

=cut

sub _init {
    my $self = shift;
    $self->XDE::Actions::_init(@_);
    $self->get_OB_THEME;
    return $self;
}

=item $style->B<_term>() => $style

=cut

sub _term {
    my $self = shift;
    $self->XDE::Actions::_term(@_);
    return $self;
}

=back

=head2 Style setting

=over

=item $style->B<set_style>(I<@styles>) => $result

=cut

sub set_style {
    my $self = shift;
    my $v = $self->{ops}{verbose};
    print STDERR "Setting style\n" if $v;
    my $wm = "\U$self->{wmname}\E" if $self->{wmname};
    $wm = 'NONE' unless $wm;
    my $setter = "set_style_$wm";
    print STDERR "Setter: $setter\n" if $v;
    my $sub = $self->can($setter);
    $sub = $self->can('set_style_UNKNOWN') unless $sub;
    my $result = &$sub($self,@_) if $sub;
    return $result;
}

=item $style->B<set_style_FLUXBOX>(I<@styles>) => $result

=cut

=item $style->B<set_style_BLACKBOX>(I<@styles>) => $result

=cut

=item $style->B<set_style_OPENBOX>(I<@styles>) => $result

=cut

=item $style->B<set_style_ICEWM>(I<@styles>) => $result

=cut

=item $style->B<set_style_JWM>(I<@styles>) => $result

=cut

=item $style->B<set_style_PEKWM>(I<@styles>) => $result

=cut

=item $style->B<set_style_FVWM>(I<@styles>) => $result

=cut

=item $style->B<set_style_WMAKER>(I<@styles>) => $result

=cut

=item $style->B<set_style_AFTERSTEP>(I<@styles>) => $result

=cut

=item $style->B<set_style_METACITY>(I<@styles>) => $result

=cut

=item $style->B<set_style_NONE>(I<@styles>) => $result

=cut

=item $style->B<set_style_UNKNOWN>(I<@styles>) => $result

=cut

=back

=head2 Style checking

=over

=item $style->B<check_style>() => $result

Gets the them according to the current window manager, checks for a
theme change, and coordinates a theme change when necessary.

=cut

sub check_style {
    my $self = shift;
    my $v = $self->{ops}{verbose};
    print STDERR "Checking style\n" if $v;
    my $wm = "\U$self->{wmname}\E" if $self->{wmname};
    $wm = 'NONE' unless $wm;
    my $checker = "check_style_$wm";
    print STDERR "Checker: $checker\n" if $v;
    my $sub = $self->can($checker);
    $sub = $self->can('check_style_UNKNOWN') unless $sub;
    my $result = &$sub($self,@_) if $sub;
    return $result;
}

sub lookup_theme {
    my ($self,$name) = @_;
    my %entry = $self->get_style_by_name($name);
    my $theme;
    if (%entry) {
	$theme = $theme{'Xde/ThemeName'};
	$theme = $theme{'Net/ThemeName'} unless $theme;
	$theme = $theme{'Gtk/ThemeName'} unless $theme;
    }
    $theme = $name unless $theme;
    return $theme, %entry;
}

=item $style->B<check_style_FLUXBOX>() => $result

Checks the style reported by the L<fluxbox(1)> window manager.

When L<fluxbox> changes its style, it writes the new style in the
C<session.styleFile> resource in the F<~/.fluxbox/init> file.  Note,
however, that unlike other window managers, it does not restart.
(Unfortunately, this also leads to L<fluxbox> not correctly changing the
style of the L<fluxbox> menus.)  We use L<Linux::Inotify2> to help us
detect a change to the file.  We might be able to also use
L<fluxbox-remote(1)> to restart L<fluxbox> and have it correctly render
menus under the new style.

Note also that F<~/.fluxbox/init> might be the incorrect file depending
on how L<fluxbox> was started.  We might also be able to use
L<fluxbox-remote(1)> to get L<fluxbox> to surrender its primary
configuration file path.  However, it is atypical to set up L<fluxbox>
to permit L<fluxbox-remote(1)> operation at all.

When there is no XDE theme name corresponding to the L<fluxbox> style,
we can still use the L<fluxbox> style name to lookup a GTK2 theme name
to use for GTK2 applications that are associated with the desktop and
which should maintain a style similar to that of the window manager.

=cut

sub check_style_FLUXBOX {
    my $self = shift;
    my $config = "$ENV{HOME}/.fluxbox/init"; # for now
    $self->watch_style_file(config=>$config);
    my $style = $self->read_anybox_style($config) or return undef;
    $style = "$style/theme.cfg" if -d $style;
    return undef if defined($self->{style}) and $self->{style} eq $style;
    $self->{style} = $style;
#   STYLE CHANGED
    my $name = $style; $name =~ s{/theme\.cfg$}{}; $name =~ s{.*/}{};
    my ($theme, %entry) = $self->get_style_by_name($name);
    return undef if defined($self->{theme}) and $self->{theme} eq $theme;
    $self->{theme} = $theme;
    return $theme, %entry;
}

=item $style->B<check_style_BLACKBOX>() => $result

Checks the style reported by the L<blackbox(1)> window manager.

L<blackbox(1)> is similar to L<fluxbox(1)>: it sets the style in the
F<~/.blackboxrc> file when changing styles; however, L<blackbox(1)>
normally changes the background with every style change, therefore, a
change in the background image should also trigger a recheck.

=cut

sub check_style_BLACKBOX {
    my $self = shift;
    my $config = "$ENV{HOME}/.blackboxrc"; # for now
    $self->watch_style_file(config=>$config);
    my $style = $self->read_anybox_style($config) or return undef;
    return undef if defined($self->{style}) and $self->{style} eq $style;
    $self->{style} = $style;
#   STYLE CHANGED
    my $name = $style; $name =~ s{.*/}{};
    my ($theme, %entry) = $self->get_style_by_name($name);
    return undef if defined($self->{theme}) and $self->{theme} eq $theme;
    $self->{theme} = $theme;
    return $theme, %entry;
}

=item $style->B<check_style_OPENBOX>() => $result

Checks the style reported by the L<openbox(1)> window manager.

L<openbox(1)> will change the C<_OB_THEME> property on the root window
when its theme changes: so a simple C<PropertyNotify> on this property
should trigger the recheck.  Note that L<openbox(1)> also set
C<_OB_CONFIG_FILE> on the root window when the configuration file
differs from the default (but not otherwise).  Note that L<openbox(1)>
also changes the C<theme> section in F<~/.config/openbox/rc.xml> and
writes the file, but we don't need that.

=cut

sub check_style_OPENBOX {
    my $self = shift;
    $self->watch_style_file(config=>'');
    my $style = $self->{_OB_THEME} or return undef;
    return undef if defined($self->{style}) and $self->{style} eq $style;
    $self->{style} = $style;
#   STYLE CHANGED
    my $name = $style;
    my ($theme, %entry) = $self->get_style_by_name($name);
    return undef if defined ($self->{theme}) and $self->{theme} eq $theme;
    $self->{theme} = $theme;
    return $theme, %entry;
}

=item $style->B<check_style_ICEWM>() => $result

Checks the style reported by the L<icewm(1)> window manager.

When L<icewm(1)> changes its theme it restarts, which results in a new
C<_NET_SUPPORTING_WM_CHECK> window, which invokes this internal
function.  L<icewm(1)> changes the setting for the theme in its
F<~/.icewm/theme> file (or C<$ICEWM_PRIVCFG/theme>) file.

=cut

sub check_style_ICEWM {
    my $self = shift;
    my $cfgdir = $ENV{ICEWM_PRIVCFG} if $ENV{ICEWM_PRIVCFG};
    $cfgdir = "$ENV{HOME}/.icewm" unless $cfgdir;
    my $config = "$cfgdir/theme";
    $self->watch_style_file(config=>$config);
    my @styles = $self->read_icewm_style($config) or return;
    #
    # each @styles is a relative path that can be in two places:
    # @XDG_DATA_DIRS/icewm/themes or $ICEWM_PRIVCFG/themes.  User themes
    # override system themes of the same name.  When a theme cannot be
    # found, try an older theme in the list.
    #
    my $v = $self->{ops}{verbose};
    my ($style,$name);
    foreach my $s (@styles) {
	foreach my $dir ($cfgdir, "$ENV{HOME}/.icewm",
		map{"$_/icewm"} $self->XDG_DATA_ARRAY) {
	    print STDERR "Directory: '$dir'\nStyle: '$s'\n" if $v;
	    my $file = "$dir/themes/$s";
	    if (-f $file) {
		$name = $s;
		$style = $file;
		last;
	    }
	}
	last if $style;
    }
    return undef if defined($self->{style}) and $self->{style} eq $style;
    $self->{style} = $style;
    if ($name) {
	$name =~ s{/default\.theme$}{};
	$name =~ s{\.theme$}{};
    }
    my ($theme,%entry) = $self->get_style_by_name($name);
    return undef if defined($self->{theme}) and $self->{theme} eq $theme;
    $self->{theme} = $theme;
    return $theme, %entry;
}

=item $style->B<check_style_JWM>() => $result

=cut

=item $style->B<check_style_PEKWM>() => $result

=cut

=item $style->B<check_style_FVWM>() => $result

=cut

=item $style->B<check_style_WMAKER>() => $result

=cut

=item $style->B<check_style_AFTERSTEP>() => $result

=cut

=item $style->B<check_style_METACITY>() => $result

=cut

=item $style->B<check_style_NONE>() => $result

=cut

=item $style->B<check_style_UNKNOWN>() => $result

=cut

=back

=head2 Support methods

=over

=item $style->B<watch_style_file>(I<$label>,I<$file>) => $installed

=cut

=item $style->B<get_style_by_name>(I<$name>) => %entry

Search out in XDG theme directories an XDE theme with the name,
I<$name>, and collect the sections and fields into a hash reference.
The keys of the hash reference are the sections in the file with subkeys
represented fields in the section.  An empty hash is returned when no
file of the appropriate name could be found or if the file was empty.
When successful, C<$entry{file}> contains the filename read.

Because the theme name is derived from the window manager specific style
file or directory, it is possible to symbolically link an arbitrary
style to a window manager specific style file or directory to associate
it with an XDE theme.  In this way, different XDE themes can use the
same window manager style.  See L</CONFIGURATION> for more information
on XDE theme file contents.

=cut

sub get_style_by_name {
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
	foreach my $wm (qw(fluxbox blackbox openbox icewm jwm pekwm fvwm wmaker afterstep metacity)) {
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

=back

=head2 Event handlers

=over

=item $style->get_OB_THEME() => $theme

=cut

sub get_OB_THEME {
    my $self = shift;
    my $theme = $self->getWMRootPropertyString('_OB_THEME');
    $theme = '' unless $theme;
    return $theme;
}

=item $style->event_handler_PropertyNotify_OB_THEME(I<$e>,I<$X>,I<$v>)

Event handler for changes in the C<_OB_THEME> property.

=cut

sub event_handler_PropertyNotify_OB_THEME {
    my ($self,$e,$X,$v) = @_;
    $self->get_OB_THEME if $e->{window} == $X->root;
    $self->check_style;
}


1;

__END__

=back

=head1 CONFIGURATION

Theme files are DOS F<.ini> style files.  They consist of a C<[Theme]>
section that contains definitions that apply to all window managers.  A
window-manager-specific section can be included, (e.g. C<[fluxbox]>)
that provides overrides for that window manager.

Theme files are named F<theme.ini> and contain the following fields in
the C<[Theme]> section.  Any fields may be overridden by a window
manager specific section (e.g. C<[fluxbox]>).

Following is an example theme file:

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

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72

