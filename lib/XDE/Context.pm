package XDE::Context;
require XDG::Context;
use base XDG::Context;
use File::Path;
use strict;
use warnings;

=head1 NAME

XDE::Context - establish an XDE environment context

=head1 SYNOPSIS

 use XDE::Context;

 my $xde = XDE::Context->new();

 $xde->getenv();
 $xde->set_session('fluxbox') or die "Cannot use fluxbox";
 $xde->setenv();

 print "Config file is ",
	$xde->XDE_CONFIG_DIR,'/',
	$xde->XDE_CONFIG_FILE,"\n";
 print "Menu file is ",
	$xde->XDE_MENU_DIR,'/',
	$xde->XDE_MENU_FILE,"\n";

=cut

use constant {
    MYENV => [qw(
	XDE_SESSION
	XDE_CONFIG_DIR
	XDE_CONFIG_FILE
	XDE_MENU_DIR
	XDE_MENU_FILE
	DESKTOP_SESSION
	FBXDG_DE
    )],
    MYPATH => [qw(
	XDE_CONFIG_HOME
	XDE_CONFIG_DIR
	XDE_MENU_DIR
    )],
    SESSIONS => {
	fluxbox		 => 'fluxbox',
	'fluxbox-xde'	 => 'fluxbox',
	blackbox	 => 'blackbox',
	'blackbox-xde'	 => 'blackbox',
	openbox		 => 'openbox',
	'openbox-session'=> 'openbox',
	'openbox-xde'	 => 'openbox',
	icewm		 => 'icewm',
	'icewm-session'	 => 'icewm',
	'icewm-xde'	 => 'icewm',
	fvwm		 => 'fvwm',
	fvwm2		 => 'fvwm',
	'fvwm-xde'	 => 'fvwm',
	wmaker		 => 'wmaker',
	'wmaker-xde'	 => 'wmaker',
	windowmaker	 => 'wmaker',
	lxde		 => 'lxde',
	'lxde/openbox'	 => 'lxde',
    },
    CONFDIR => {
	fluxbox		 => "~/.fluxbox",
	blackbox	 => "~/.blackbox",
	openbox		 => "~/.config/openbox",
	icewm		 => "~/.icewm",
	fvwm		 => "~/.fvwm",
	wmaker		 => "~/GNUstep",
	lxde		 => "~/.config/openbox",
    },
    CONFFILE => {
	fluxbox		 => 'xde-init',
	blackbox	 => 'xde-rc',
	openbox		 => 'xde-rc.xml',
	icewm		 => 'preferences', # multiple actually
	fvwm		 => 'config', # other names too
	wmaker		 => 'Defaults/WindowMaker',
	lxde		 => 'lxde-rc.xml',
    },
    MENUDIR => {
	fluxbox		 => '~/.fluxbox',
	blackbox	 => '~/.blackbox',
	openbox		 => '~/.config/openbox',
	icewm		 => '~/.icewm',
	fvwm		 => '~/.fvwm',
	wmaker		 => '~/GNUstep',
	lxde		 => '~/.config/openbox',
    },
    MENUFILE => {
	fluxbox		 => 'menu',
	blackbox	 => 'menu',
	openbox		 => 'menu.xml',
	icewm		 => 'menu',
	fvwm		 => 'menus',
	wmaker		 => 'Library/WindowMaker/menu',
	lxde		 => 'menu.xml',
    },
    SUBDIRS => {
	fluxbox		 => [qw(backgrounds icons pixmaps splash styles tiles)],
	blackbox	 => [qw(backgrounds styles)],
	openbox		 => [],
	icewm		 => [qw(themes sounds)],
	fvwm		 => [qw(icons)],
	wmaker		 => [],
	lxde		 => [],
    },
    CFGFILES => {
	fluxbox		 => [qw(apps fbdesk fbdesk.icons fbpager keys menuconfig overlay slitlist startup usermenu windowmenu)],
	blackbox	 => [],
	openbox		 => [],
	icewm		 => [qw(focus_mode keys prefoverride programs theme toolbar winoptions startup shutdown)],
	fvwm		 => [qw(bindings decorations functions globalfeel iconstyles menus modules startup sytles)],
	wmaker		 => [],
	lxde		 => [],
    },
};

=head1 METHODS

The following methods are provided:

=over

=item $xde = XDE::Context->B<new>(I<%OVERRIDES>,ops=>\I<%ops>) => blessed HASHREF

Creates a new instance of an XDE::Context object an retruns a blessed
reference.  The XDE::Context module uses the L<XDG::Context(3pm)> module
as a base, so the C<%OVERRIDES> are simply passed to the
L<XDG::Context(3pm)> module.  When an options hash, I<%ops>, is passed
to the method, it is initialized with default option values.
See L</OPTIONS> for details on the options recognized by this module.

=cut

sub new {
	return XDG::Context::new(@_);
}

=item $xde->B<xde_default>() => $xde

Internal method to establish defaults for the XDE::Context object
without invoking the defaults of the superior module: used for multiple
inheritance.  Normally called by the B<default> method of this package
or a derived package.  Establishes a wide range of XDG and XDE session
parameters and defaults.
This method may or may not be indempotent.

=cut

sub xde_default {
    my $self = shift;
    $self->{XDG_CURRENT_DESKTOP} = $self->{DESKTOP_SESSION} unless $self->{XDG_CURRENT_DESKTOP};
    $self->{XDG_CURRENT_DESKTOP} = $self->{FBXDG_DE} unless $self->{XDG_CURRENT_DESKTOP};
    $self->{XDG_CURRENT_DESKTOP} = '' unless $self->{XDG_CURRENT_DESKTOP};
    $self->{XDG_CURRENT_DESKTOP} = "\U$self->{XDG_CURRENT_DESKTOP}\E" if $self->{XDG_CURRENT_DESKTOP};

    $self->{DESKTOP_SESSION} = $self->{XDG_CURRENT_DESKTOP} unless $self->{DESKTOP_SESSION};
    $self->{DESKTOP_SESSION} = $self->{FBXDG_DE} unless $self->{DESKTOP_SESSION};
    $self->{DESKTOP_SESSION} = '' unless $self->{DESKTOP_SESSION};
    $self->{DESKTOP_SESSION} = "\U$self->{DESKTOP_SESSION}\E" if $self->{DESKTOP_SESSION};

    $self->{FBXDG_DE} = $self->{XDG_CURRENT_DESKTOP} unless $self->{FBXDG_DE};
    $self->{FBXDG_DE} = $self->{DESKTOP_SESSION} unless $self->{FBXDG_DE};
    $self->{FBXDG_DE} = '' unless $self->{FBXDG_DE};
    $self->{FBXDG_DE} = "\U$self->{FBXDG_DE}\E" if $self->{FBXDG_DE};

    $self->{XDE_SESSION} = $self->{ops}{session};
    $self->{XDE_SESSION} = '' unless $self->{XDE_SESSION};
    $self->{XDE_SESSION} = $self->{XDG_CURRENT_DESKTOP} unless $self->{XDE_SESSION};
    $self->{XDE_SESSION} = $self->{DESKTOP_SESSION} unless $self->{XDE_SESSION};
    $self->{XDE_SESSION} = $self->{FBXDG_DE} unless $self->{XDE_SESSION};
    $self->{XDE_SESSION} = "\L$self->{XDE_SESSION}\E" if $self->{XDE_SESSION};

    if (exists &SESSIONS->{$self->{XDE_SESSION}}) {
	my $session = $self->{XDE_SESSION} = &SESSIONS->{$self->{XDE_SESSION}};
	$self->{XDE_CONFIG_DIR}  = &CONFDIR->{$session};
	$self->{XDE_CONFIG_FILE} = &CONFFILE->{$session};
	$self->{XDE_MENU_DIR}    = &MENUDIR->{$session};
	$self->{XDE_MENU_FILE}   = &MENUFILE->{$session};
	$self->{XDE_MENU_FILE} = 'menu' unless $self->{XDE_MENU_FILE};
	$self->{XDE_MENU_FILE} = "$self->{XDG_MENU_PREFIX}$self->{XDE_MENU_FILE}";
	if ($self->{ops}{xdg_rcdir}) {
	    $self->{XDE_CONFIG_DIR} = "$self->{XDG_CONFIG_HOME}/$session";
	}
	if ($self->{ops}{tmp_menu}) {
	    $self->{XDE_MENU_DIR} = "/tmp/xde/\U$session\E";
	}
    }
    else {
	    $self->{XDE_SESSION} = '';
    }
    $self->{XDE_CONFIG_DIR}  = '' unless $self->{XDE_CONFIG_DIR};
    $self->{XDE_CONFIG_FILE} = '' unless $self->{XDE_CONFIG_FILE};
    $self->{XDE_MENU_DIR}    = '' unless $self->{XDE_MENU_DIR};
    $self->{XDE_MENU_FILE}   = '' unless $self->{XDE_MENU_FILE};

    $self->{XDE_CONFIG_HOME} = "$self->{XDG_CONFIG_HOME}/xde"
	unless $self->{XDE_CONFIG_HOME};
    $self->{XDE_CONFIG_HOME} = "$ENV{HOME}/.config/xde"
	unless $self->{XDE_CONFIG_HOME};

    $self->{XDE_DEFAULT_FILE} = "$self->{XDE_CONFIG_HOME}/default"
	unless $self->{XDE_DEFAULT_FILE};
    $self->{XDE_CURRENT_FILE} = "$self->{XDE_CONFIG_HOME}/current"
	unless $self->{XDE_CURRENT_FILE};

    foreach my $var (@{&MYPATH}) {
	$self->{$var} =~ s(~)($self->{HOME})g if $self->{$var};
    }
    $self->{XDE_BANNER_FILE} = $self->{ops}{banner} unless $self->{XDE_BANNER_FILE} and not $self->{ops}{banner};
    unless ($self->{XDE_BANNER_FILE} or not $self->{XDG_MENU_PREFIX}) {
	foreach (map{"$_/images"}$self->XDG_DATA_ARRAY) {
	    if (-f "$_/$self->{XDG_MENU_PREFIX}banner.png") {
		$self->{XDE_BANNER_FILE} = "$_/$self->{XDG_MENU_PREFIX}banner.png";
		last;
	    }
	}
    }
#    $self->{XDE_BANNER_FILE} = $self->default_banner unless $self->{XDE_BANNER_FILE} or not $self->{XDG_MENU_PREFIX};
    $self->{XDE_BANNER_FILE} = '' unless $self->{XDE_BANNER_FILE};
    $self->{ops}{banner} = $self->{XDE_BANNER_FILE} unless $self->{ops}{banner};
    return $self;
}

=item $xde->B<default>() => $xde

Internal method invoked by L<XDG::Context(3pm)> to establish defaults
for the instance.  Invokes the superior B<default> method with the
additional XDG_CONFIG_DIRS prepend of F</etc/xdg/xde> and XDG_DATA_DIRS
prepend of F</usr/local/share/xde> and F</usr/share/xde>.  Invokes the
B<xde_default> XDE::Context method, above.
Invokes the C<defaults> method of the derived class if available.
This method may or may not be indempotent.

=cut

sub default {
    my $self = shift;
    $self->{XDG_CONFIG_PREPEND} = '/etc/xdg/xde' unless $self->{XDG_CONFIG_PREPEND};
    $self->{XDG_DATA_PREPEND} = '/usr/local/share/xde:/usr/share/xde' unless $self->{XDG_DATA_PREPEND};

    $self->SUPER::default(@_);
    $self->XDE::Context::xde_default(@_);
    my $sub = $self->can('defaults');
    &$sub($self,@_) if $sub;

    return $self;
}

=item $xde->B<getenv>()

Read environment variables into the context and recalculate defaults.
Environment variables examined are B<XDE_SESSION>, B<XDE_CONFIG_DIR>,
B<XDE_CONFIG_FILE>, B<XDE_MENU_DIR>, B<XDE_MENU_FILE>,
B<DESKTOP_SESSION>, B<FBXDG_DE>, and those described under
L<XDG::Context(3pm)/getenv>.  Also calls C<_getenv> of the derived class
when available.  This method may or may not be indempotent.

=cut

sub getenv {
    my $self = shift;
    if (my $sub = $self->can('_getenv')) { &$sub($self,@_) }
    foreach (@{&MYENV}) { $self->{$_} = $ENV{$_} }
    return $self->SUPER::getenv(@_);
}

=item $xde->B<setenv>()

Write pertinent XDE environment variables from the context into the
environment.  Environment variables written are: B<XDE_SESSION>,
B<XDE_CONFIG_DIR>, B<XDE_CONFIG_FILE>, B<XDE_MENU_DIR>,
B<XDE_MENU_FILE>, B<DESKTOP_SESSION>, B<FBXDG_DE>, and those described
under L<XDG::Context(3pm)/setenv>.  Also calls C<_setenv> of the derived
class when available.  This method may or may not be indempotent.

=cut

sub setenv {
    my $self = shift;
    $self->SUPER::setenv(@_);
    foreach (@{&MYENV}) { delete $ENV{$_}; $ENV{$_} = $self->{$_} if $self->{$_}; }
    if (my $sub = $self->can('_setenv')) { &$sub($self,@_) }
    return $self;
}

=item $xde->B<mkdirs>()

Create configuration directories in the user's home directory (and,
optionally, menu directories in /tmp) if they do not already exist.
The directories created are: B<XDE_CONFIG_HOME>, B<XDE_CONFIG_DIR>,
B<XDE_MENU_DIR>.  See L<XDG::Context(3pm)> for additional directories
established.
This method is indempotent.

=cut

sub do_mkpath {
    my ($self,$dir) = @_;
    if ($self->{ops}{dry_run}) {
	print STDERR "mkdir -p $dir\n";
    } else {
	eval { mkpath $dir; } unless -d $dir;
    }
}

sub mkdirs {
    my $self = shift;
    $self->SUPER::mkdirs();
    foreach (qw(XDE_CONFIG_HOME XDE_CONFIG_DIR XDE_MENU_DIR)) {
	if (my $dir = $self->{$_}) {
	    $self->do_mkpath($dir);
	}
    }
}

=item $xde->B<DESKTOP_SESSION>(I<$newvalue>) => $value

=item $xde->B<FBXDG_DE>(I<$newvalue>) => $value

=item $xde->B<XDE_SESSION>(I<$newvalue>) => $value

=item $xde->B<XDE_CONFIG_DIR>(I<$newvalue>) => $value

=item $xde->B<XDE_CONFIG_FILE>(I<$newvalue>) => $value

=item $xde->B<XDE_MENU_DIR>(I<$newvalue>) => $value

=item $xde->B<XDE_MENU_FILE>(I<$newvalue>) => $value

Get or set the corresponding environment variable in the context.

=cut

sub DESKTOP_SESSION	{ return shift->get_or_set(DESKTOP_SESSION  =>@_) }
sub FBXDG_DE		{ return shift->get_or_set(FBXDG_DE	    =>@_) }
sub XDE_SESSION		{ return shift->get_or_set(XDE_SESSION	    =>@_) }
sub XDE_CONFIG_DIR	{ return shift->get_or_set(XDE_CONFIG_DIR   =>@_) }
sub XDE_CONFIG_FILE	{ return shift->get_or_set(XDE_CONFIG_FILE  =>@_) }
sub XDE_MENU_DIR	{ return shift->get_or_set(XDG_MENU_DIR	    =>@_) }
sub XDE_MENU_FILE	{ return shift->get_or_set(XDG_MENU_FILE    =>@_) }

=item $xde->B<set_session>($session)

Sets the desktop session (window manager) to the string specified with
the C<$session> argument.  Performs no actions unless the session
argument is recognized.  The C<$session> argument is case insensitive.
Returns the session argument if it is recognized, otherwise it returns
C<undef>.

=cut

sub set_session {
    my $self = shift;
    my $session = $self->{session} = shift;
    if (exists &SESSIONS->{"\L$session\E"}) {
	$session = &SESSIONS->{"\L$session\E"};
    }
    my $desktop = "\U$session\E";
    $self->setup(
	XDG_CURRENT_DESKTOP => $desktop,
	DESKTOP_SESSION	    => $desktop,
	FBXDG_DE	    => $desktop,
	XDE_SESSION	    => $session,
	XDE_CONFIG_DIR	    => undef,
	XDE_CONFIG_FILE	    => undef,
	XDE_MENU_DIR	    => undef,
	XDE_MENU_FILE	    => undef,
    );
    $self->default;
    return $desktop;
}

=item $xde->B<setup_session>(I<$session>)

Perform default common session directory subdirectory and configuration
file setup.

=cut

sub do_system {
    my ($self,@cmds) = @_;
    my $cmd = join(' ',@cmds);
    if ($self->{ops}{dry_run}) {
	print STDERR $cmd,"\n";
	return 1;
    }
    return system($cmd);
}

sub setup_session {
    my $self = shift;
    my $session = shift;
    $session = "\L$session\E";
    my $desktop = "\U$session\E";
    my $rcdir = $self->{XDE_CONFIG_DIR}; $rcdir =~ s|~|$ENV{HOME}|;
    $self->do_mkpath($rcdir);
    foreach (@{&SUBDIRS->{$session}}) {
	$self->do_mkpath("$rcdir/$_");
    }
    foreach my $file ($self->{XDE_CONFIG_FILE}, @{&CFGFILES->{$session}}) {
	my $rcfile = "$rcdir/$file";
	print STDERR ":: establishing: $rcfile\n"
	    if $self->{ops}{verbose};
	my $base = $file; $base =~ s{^.*/}{};
	foreach my $dir (map {"$_/$session"} $self->XDG_DATA_ARRAY) {
	    my $rcbase = "$dir/$base";
	    if (-f $rcbase) {
		if (-f $rcfile and (stat($rcfile))[9] > (stat($rcbase))[9]) {
		    print STDERR "$rcfile exists and is not older than $rcbase\n"
			if $self->{ops}{verbose};
		} else {
		    $self->do_system("/bin/cp -f --preserve=timestamps \"$rcbase\" \"$rcfile\"");
		}
		last;
	    } else {
		warn "$rcbase does not exist"
		    if $self->{ops}{verbose} and not -f $rcfile;
	    }
	}
    }
    my $menudir = $self->{XDE_MENU_DIR}; $menudir =~ s|~|$ENV{HOME}|;
    $self->do_mkpath($menudir);
    my $menu = "$menudir/$self->{XDE_MENU_FILE}";
    print STDERR ":: establishing: $menu\n"
	if $self->{ops}{verbose};
    foreach my $dir (map {"$_/$session"} $self->XDG_DATA_ARRAY) {
	my $menubase = "$dir/$self->{XDE_MENU_FILE}";
	if (-f $menubase) {
	    if (-f $menu and (stat($menu))[9] > (stat($menubase))[9]) {
		print STDERR "$menu exists and is not older than $menubase\n"
		    if $self->{ops}{verbose};
	    } else {
		$self->do_system("/bin/cp -f --preserve=timestamps \"$menubase\" \"$menu\"");
	    }
	    last;
	} else {
	    warn "$menubase does not exist"
		if $self->{ops}{verbose} and not -f $menu;
	}
    }
    unless (-f $menu) {
	$self->do_system("touch \"$menu\"");
    }
    unless ($menudir eq $rcdir) {
	$self->do_system("rm -f \"$rcdir/$self->{XDE_MENU_FILE}\"");
	$self->do_system("ln -sf \"$menu\" \"$rcdir/$self->{XDE_MENU_FILE}\"");
    }
}

=item $xde->B<default_banner>() => SCALAR

Determine the full path of the default branding banner from XDE/XDG
context and return it as a scalar.

=cut

# determine the default branding banner
sub default_banner {
    my $self = shift;
    foreach my $file ("$self->{XDG_MENU_PREFIX}banner.png", "banner.png") {
	foreach my $dir (map {"$_/images"} $self->XDG_DATA_ARRAY) {
	    my $banner = "$dir/$file";
	    if (-f $banner) {
		print STDERR "Found banner '$banner'\n" if $self->{ops}{verbose};
		return $banner;
	    }
	    print STDERR "No banner named '$banner'\n" if $self->{ops}{verbose};
	}
    }
    print STDERR "Failed to find a banner\n" if $self->{ops}{verbose};
    return '';
}

=item $xde->B<get_themes> => HASHREF

Search out all XDG themes directories and collect XDE themes into a hash
reference.  The keys of the hash are the names of the theme subdirectory
in which the theme.ini file resided.  Themes follow XDG precedence rules
for XDG data directories.

Also establishes a hash reference in $xdg->{dirs}{themes} that contains
all of the directories searched (whether they existed or not) for use in
conjunction with L<Linux::Inotify2(3pm)>.  See L<XDE::Inotify(3pm)>.

=cut

sub get_themes {
    my $self = shift;
    my %themedirs = ();
    my %themes = ();
    foreach my $d (reverse map {"$_/themes"} @{$self->{XDG_DATA_ARRAY}}) {
	$themedirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $s (readdir($dir)) {
	    next if $s eq '.' or $s eq '..';
	    next unless -d "$d/$s";
	    my $f = "$d/$s/xde/theme.ini";
	    next unless -f $f;
	    open (my $fh,"<","$d/$f") or next;
	    my $parsing = 0;
	    my %e = (file=>$f,theme=>$s);
	    my %xl = ();
	    my $section;
	    while (<$fh>) {
		next if /^\s*\#/; # comment
		if (/^\[([^]]*)\]/) {
		    $section = $1;
		    $parsing = 1;
		}
                elsif ($parsing and /^([^=\[]+)\[([^=\]]+)\]=([^[:cntrl:]]*)/) {
		    $xl{$section}{$1}{$2} = $3;
		}
                elsif ($parsing and /^([^=]*)=([^[:cntrl:]]*)/) {
		    $e{$section}{$1} = $2;
		}
	    }
	    close($fh);
	    my $short = $1 if $self->{ops}{lang} =~ /^(..)/;
	    foreach (keys %xl) {
		if (exists $xl{$_}{$self->{ops}{lang}}) {
                    $e{$_} = $xl{$_}{$self->{ops}{lang}};
		}
                elsif ($short and exists $xl{$_}{$short}) {
                    $e{$_} = $xl{$_}{$short};
		}
	    }
	    $e{Theme}{Name} = $s unless $e{Theme}{Name};
	    $e{Xsettings}{'Xde/ThemeName'} = $e{Theme}{Name}
		unless $e{Xsettings}{'Xde/ThemeName'};
	    foreach my $wm (qw(fluxbox blackbox openbox icewm fvwm wmaker)) {
		foreach (keys %{$e{Theme}}) {
		    $e{$wm}{$_} = $e{Theme}{$_} unless exists $e{$wm}{$_};
		}
	    }
	    $themes{$s} = \%e;
	}
	closedir($dir);
    }
    $self->{dirs}{themes} = \%themedirs;
    $self->{objs}{themes} = \%themes;
    return (\%themes,\%themedirs) if wantarray;
    return \%themes;
}

=item $xde->B<get_styles> => HASHREF

Search out all window manager style directories and collect WM styles
into a hash reference.  The keys of the hash are the names of the style
subdirectory (or file) in which the WM-specific file resides.  Styles do
not fully follow XDG precedence rules, but follow WM-specific rules.
B<set_session> should be called before this function if it is to be
called at all.

Also establishes a hash reference in $xdg->{dirs}{style} that contains
all of the directories searched (whether they existed or not) for use in
conjunction with L<Linux::Inotify2(3pm)>.

The following methods are used to implement B<get_styles>:

=over

=cut

sub get_styles {
    my $self = shift;
    unless ($self->{session}) {
	print STDERR "Session must be set before calling XDE::Context::get_styles\n";
	return {};
    }
    my $method = "get_styles_\U$self->{session}\E";
    unless ($self->can($method)) {
	print STDERR "Unrecognized session '\U$self->{session}\E'\n";
	return {};
    }
    return $self->$method(@_);
}

=item $xde->B<get_styles_FLUXBOX>() => HASHREF

Normally invoked as B<get_styles>, gets the styles hash when the session
is a C<FLUXBOX> session.  The directories searched are
F<@XDG_DATA_DIRS/fluxbox/styles> with an override from
F<$HOME/.fluxbox/styles>.  Styles are named by the name of an immediate
subdirectory containing a F<theme.cfg> file, or by the file name of a
theme file contained in the directory.

=cut

sub get_styles_FLUXBOX {
    my $self = shift;
    my %styledirs = ();
    my %styles = ();
    foreach my $d (reverse map{"$_/fluxbox/styles"}@{$self->{XDG_DATA_ARRAY}},
	    "$ENV{HOME}/.fluxbox/styles") {
	$styledirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $s (readdir($dir)) {
	    next if $s eq '.' or $s eq '..';
	    if (-d "$dir/$s" and -f "$dir/$s/theme.cfg") {
		$styles{$s} = "$dir/$s/theme.cfg";
	    }
	    elsif (-f "$dir/$s") {
		$styles{$s} = "$dir/$s";
	    }
	}
	closedir($dir);
    }
    $self->{dirs}{style} = \%styledirs;
    return \%styles;
}

=item $xde->B<get_styles_BLACKBOX>() => HASHREF

Normally invoked as B<get_styles>, gets the styles hash when the session
is a C<BLACKBOX> session.  The directories searched are
F<@XDG_DATA_DIRS/backbox/styles> with an override from
F<$HOME/.fluxbox/styles>.  Styles are named by the name of the theme
file.

=cut

sub get_styles_BLACKBOX {
    my $self = shift;
    my %styledirs = ();
    my %styles = ();
    foreach my $d (reverse
	    map{"$_/blackbox/styles"}@{$self->{XDG_DATA_ARRAY}},
	    "$ENV{HOME}/.blackbox/styles") {
	$styledirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $s (readdir($dir)) {
	    next if $s eq '.' or $s eq '..';
	    next unless -f "$dir/$s";
	    $styles{$s} = "$dir/$s";
	}
	closedir($dir);
    }
    $self->{dirs}{style} = \%styledirs;
    return \%styles;
}

=item $xde->B<get_styles_OPENBOX>() => HASHREF

Normally invoked as B<get_styles>, gets the styles hash when the session
is a C<OPENBOX> session.  The directories searched are
F<@XDG_DATA_DIRS/themes/*/openbox-3>.  Styles are named by the name of
the F<themes> subdirectory containing a F<openbox-3/themerc> file.

=cut

sub get_styles_OPENBOX {
    my $self = shift;
    my %styledirs = ();
    my %styles = ();
    foreach my $d (reverse map{"$_/themes"}@{$self->{XDG_DATA_ARRAY}}) {
	$styledirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $s (readdir($dir)) {
	    next if $s eq '.' or $s eq '..';
	    next unless -d "$d/$s";
	    my $f = "$d/$s/openbox-3/themerc";
	    next unless -f $f;
	    $styles{$s} = $f;
	}
	closedir($dir);
    }
    $self->{dirs}{style} = \%styledirs;
    return \%styles;
}

=item $xde->B<get_styles_ICEWM>() => HASHREF

Normaly invoked as B<get_styles>, gets the styles hash wen the session
is an C<ICEWM> session.  The directories searched are
F<@XDG_DATA_DIRS/icewm/themes> with an override from
F<$HOME/.icewm/themes>.  Styles are named by the name of the
subdirectory containing a F<default.theme> file, or the name of the
subdirectory and the base name of
another F<*.theme> file: I<subdirectory/name>F<.theme>.

=cut

sub get_styles_ICEWM {
    my $self = shift;
    my %styledirs = ();
    my %styles = ();
    foreach my $d (reverse
	    map{"$_/icewm/themes"}@{$self->{XDG_DATA_ARRAY}},
	    "$ENV{HOME}/.icewm/themes") {
	$styledirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $s (readdir($dir)) {
	    next if $s eq '.' or $s eq '..';
	    next unless -d "$dir/$s";
	    opendir(my $t, "$dir/$s") or next;
	    foreach my $e (readdir($t)) {
		my $f = "$dir/$s/$e";
		next unless $e =~ /^(.*)\.theme$/ and -f $f;
		my $tn = $1 eq 'default' ? "$s" : "$s/$1";
		$styles{$tn} = $f;
	    }
	    closedir($t);
	}
	closedir($dir);
    }
    $self->{dirs}{style} = \%styledirs;
    return \%styles;
}

=item $xde->B<get_styles_JWM>() => HASHREF

Normally invoked as B<get_styles>, gets the styles hash when the session
is a C<JWM> session.  The directories searched are
F<@XDG_DATA_DIRS/jwm/styles> with an override from F<$HOME/.jwm/styles>.
Styles are named by the theme file name.

=cut

sub get_styles_JWM {
    my $self = shift;
    my %styledirs = ();
    my %styles = ();
    foreach my $d (reverse
	    map{"$_/jwm/styles"}@{$self->{XDG_DATA_ARRAY}},
	    "$ENV{HOME}/.jwm/styles") {
	$styledirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $s (readdir($dir)) {
	    next if $s eq '.' or $s eq '..';
	    next unless -f "$dir/$s";
	    $styles{$s} = "$dir/$s";
	}
	closedir($dir);
    }
    $self->{dirs}{style} = \%styledirs;
    return \%styles;
}

=item $xde->B<get_styles_PEKWM>() => HASHREF

Normally invoked as B<get_styles>, gets the styles hash when the session
is a C<PEKWM> session.  The directories searched are
F<@XDG_DATA_DIRS/pekwm/themes> with an override from
F<$HOME/.pekwm/themes>.  Styles are named by the subdirectories
containing a file named F<theme>.

=cut

sub get_styles_PEKWM {
    my $self = shift;
    my %styledirs = ();
    my %styles = ();
    foreach my $d (reverse map{"$_/pekwm/themes"}@{$self->{XDG_DATA_ARRAY}},
	    "$ENV{HOME}/.pekwm/themes") {
	$styledirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $s (readdir($dir)) {
	    next if $s eq '.' or $s eq '..';
	    next unless -d "$dir/$s" and -f "$dir/$s/theme";
	    $styles{$s} = "$dir/$s/theme";
	}
	closedir($dir);
    }
    $self->{dirs}{style} = \%styledirs;
    return \%styles;
}

=item $xde->B<get_styles_FVWM>() => HASHREF

Normally invoked as B<get_styles>, gets the styles hash when the session
is an C<FVWM> session.  The directories searched are
F<@XDG_DATA_DIRS/fvwm/themes> with an override from
F<$HOME/.fvwm/themes>.  FVWM does not really have any basic themes, the
L<fvwm-themes(1)> package does.  These themes are named after their
subdirectory (with the first character capitalized it seems), unless a
F<theme-name.cfg> file exists in the subdirectory, in which case the
C<name> key-field in that file gives the exact name.

=cut

sub get_styles_FVWM {
    my $self = shift;
    my %styledirs = ();
    my %styles = ();
    foreach my $d (reverse
	    map{"$_/fvwm/themes"}@{$self->{XDG_DATA_ARRAY}},
	    "$ENV{HOME}/.fvwm/themes") {
	$styledirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $s (readdir($dir)) {
	    next if $s eq '.' or $s eq '..';
	    # FIXME: make this work like the POD description
	    next unless $s =~ m{^Theme\.(.*)$} and -f "$dir/$s";
	    my $tn = $1;
	    $styles{$tn} = "$dir/$s";
	}
	closedir($dir);
    }
    $self->{dirs}{style} = \%styledirs;
    return \%styles;
}

=item $xde->B<get_styles_WMAKER>() => HASHREF

Normally invoked as B<get_styles>, gets the styles hash when the session
is a C<WMAKER> session.  The directories searched are
F<@XDG_DATA_DIRS/WindowMaker/{Themes,Styles}> with an override from
F<{$GNUSTEP_USER_ROOT,$HOME/GNUstep}/Library/WindowMaker/{Themes,Styles}>.
Styles named I<name>F<.style> are files containing theme information.
Styles named I<name>F<.themed> are directories containing a file named
F<style> that contains the theme information.

=cut

sub get_styles_WMAKER {
    my $self = shift;
    my %styledirs = ();
    my %styles = ();
    my $home = $ENV{GNUSTEP_USER_ROOT};
    $home = "$ENV{HOME}/GNUstep" unless $home;
    $home = "$ENV{HOME}/$home" unless $home =~ m{^/};
    foreach my $d (reverse
	    map{("$_/WindowMaker/Themes","$_/WindowMaker/Styles")}
	    @{$self->{XDG_DATA_ARRAY}},
	    "$home/Library/WindowMaker/Themes",
	    "$home/Library/WindowMaker/Styles") {
	$styledirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $s (readdir($dir)) {
	    next if $s eq '.' or $s eq '..';
	    if ($s =~ m{^(.*)\.style} and -f "$dir/$s") {
		my $tn = $1;
		$styles{$tn} = "$dir/$s";
	    }
	    elsif ($s = m{^(.*)\.themed} and -d "$dir/$s" and -f
		    "$dir/$s/style") {
		my $tn = $1;
		$styles{$tn} = "$dir/$s/style";
	    }
	}
	closedir($dir);
    }
    $self->{dirs}{style} = \%styledirs;
    return \%styles;
}

=item $xde->B<get_styles_METACITY>() => HASHREF

Normally invoked as B<get_styles>, gets the styles hash when the session
is a C<METACITY> session.  The directories searched are
F<@XDG_DATA_DIRS/themes/*/metacity-1>.  Styles are named by the name of
the F<themes> subdirectory containing a F<metacity-theme-1.xml> file.

=cut

sub get_styles_METACITY {
    my $self = shift;
    my %styledirs = ();
    my %styles = ();
    foreach my $d (reverse map{"$_/themes"}@{$self->{XDG_DATA_ARRAY}}) {
	$styledirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $s (readdir($dir)) {
	    next if $s eq '.' or $s eq '..';
	    next unless -d "$d/$s";
	    my $f = "$d/$s/metacity-1/metacity-theme-1.xml";
	    next unless -f $f;
	    $styles{$s} = $f;
	}
	closedir($dir);
    }
    $self->{dirs}{style} = \%styledirs;
    return \%styles;
}

=back

=back

=cut

1;

__END__

=head1 OPTIONS

XDE::Context recognizes the following options passed in the I<%ops> hash
to the B<new> method:

=over

=item xdg_rcdir => $boolean

When true, use F<$XDG_CONFIG_HOME> for all window manager session
configuration files instead of their normal locations (this does not
apply to L<openbox(1)> (even under L<startlxde(1)>), which normally
places its configuration files in the F<$XDG_CONFIG_HOME> directory).
Defaults to false.

=item tmp_menu => $boolean

When true, use the F</tmp> directory to store dynamic copies of the
window manager root menu.  Not that setting this value to false will
likely result in a conflict when sessions are run on multiple hosts that
mount the same user home directory (but will not conflict for multiple
sessions on the same host).  Defaults to true.

=item banner => $banner

The filename of the branding banner to include in the display.  Selected
from the I<vendor> option or XDG environment variables when not
specified.

=item side => $side

Specifies the side of the window on which the logo will be placed.  This
can be one of the following scalar strings: C<left>, C<top>, C<right> or
C<bottom>.  When unspecified, it defaults to C<top>.

=back

See L<XDG::Context(3pm)> for additional options recognized by the base
package.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72
