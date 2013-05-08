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
 my $xde = XDE::Context->new({
	xdg_rcdir   => 0,
	no_tmp_menu => 0, });
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
    },
    CONFDIR => {
	fluxbox		 => "~/.fluxbox",
	blackbox	 => "~/.blackbox",
	openbox		 => "~/.config/openbox",
	icewm		 => "~/.icewm",
	fvwm		 => "~/.fvwm",
	wmaker		 => "~/GNUstep",
    },
    CONFFILE => {
	fluxbox		 => 'xde-init',
	blackbox	 => 'xde-rc',
	openbox		 => 'xde-rc.xml',
	icewm		 => '', # multiple actually
	fvwm		 => 'config', # other names too
	wmaker		 => 'Defaults/WindowMaker',
    },
    MENUDIR => {
	fluxbox		 => '~/.fluxbox',
	blackbox	 => '~/.blackbox',
	openbox		 => '~/.config/openbox',
	icewm		 => '~/.icewm',
	fvwm		 => '~/.fvwm',
	wmaker		 => '~/GNUstep',
    },
    MENUFILE => {
	fluxbox		 => 'menu',
	blackbox	 => 'menu',
	openbox		 => 'menu.xml',
	icewm		 => 'menu',
	fvwm		 => 'preferences',
	wmaker		 => 'Library/WindowMaker/menu',
    },
};

=head1 METHODS

=over

=item B<new> XDG::Context::new

=cut

sub new {
	return XDG::Context::new(@_);
}

=item $xde->B<default>()

=cut

sub default {
    my $self = shift;
    $self->{XDG_CONFIG_PREPEND} = '/etc/xdg/xde' unless $self->{XDG_CONFIG_PREPEND};
    $self->{XDG_DATA_PREPEND} = '/usr/local/share/xde:/usr/share/xde' unless $self->{XDG_DATA_PREPEND};

    $self->SUPER::default();

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

    $self->{XDE_SESSION} = '' unless $self->{XDE_SESSION};
    $self->{XDE_SESSION} = $self->{XDG_CURRENT_DESKTOP} unless $self->{XDE_SESSION};
    $self->{XDE_SESSION} = $self->{DESKTOP_SESSION} unless $self->{XDE_SESSION};
    $self->{XDE_SESSION} = $self->{FBXDG_DE} unless $self->{XDE_SESSION};
    $self->{XDE_SESSION} = "\L$self->{XDE_SESSION}\E" if $self->{XDE_SESSION};

    $self->{XDE_SESSION} = &SESSIONS->{$self->{XDE_SESSION}} if exists &SESSIONS->{$self->{XDE_SESSION}};
    if (exists &SESSIONS->{$self->{XDE_SESSION}}) {
	my $session = $self->{XDE_SESSION};
	$self->{XDE_CONFIG_DIR}  = &CONFDIR->{$session};
	$self->{XDE_CONFIG_FILE} = &CONFDIR->{$session};
	$self->{XDE_MENU_DIR}    = &MENUDIR->{$session};
	$self->{XDE_MENU_FILE}   = &MENUFILE->{$session};
	if ($self->{xdg_rcdir}) {
	    $self->{XDE_CONFIG_DIR} = "$self->{XDG_CONFIG_HOME}/$session";
	}
	unless ($self->{no_tmp_menu}) {
	    my $prefix = $self->{XDG_MENU_PREFIX};
	    $prefix =~ s{-$}{};
	    $prefix = "/$prefix" if $prefix;
	    $self->{XDE_MENU_DIR} = "/tmp/xde/\U$session\E$prefix";
	    $self->{XDE_MENU_FILE} = &MENUFILE->{$session};
	    $self->{XDE_MENU_FILE} = 'menu' unless $self->{XDE_MENU_FILE};
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
    return $self;
}

=item $xde->B<getenv>()

Read environment variables into the context and recalculate defaults.

=cut

sub getenv {
    my $self = shift;
    foreach (@{&MYENV}) { $self->{$_} = $ENV{$_} }
    return $self->SUPER::getenv();
}

=item $xde->B<setenv>()

Write pertinent XDE environment variables from the context into the
environment.

=cut

sub setenv {
    my $self = shift;
    $self->SUPER::setenv();
    foreach (@{&MYENV}) {
	delete $ENV{$_};
	$ENV{$_} = $self->{$_} if $self->{$_};
    }
    return $self;
}

=item $xde->B<mkdirs>()

Create configuration directories in the user's home directory (and,
optionally, menu directories in /tmp) if they do not already exist.

=cut

sub mkdirs {
    my $self = shift;
    $self->SUPER::mkdirs();
    foreach (qw(XDE_CONFIG_HOME XDE_CONFIG_DIR XDE_MENU_DIR)) {
	if (my $dir = $self->{$_}) {
	    eval { mkpath $dir; } unless -d $dir;
	}
    }
}

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
	my $desktop = "\U$session\E";
	$self->setup(
	    XDG_CURRENT_DESKTOP => $desktop,
	    DESKTOP_SESSION	=> $desktop,
	    FBXDG_DE		=> $desktop,
	    XDE_SESSION		=> $session,
	    XDE_CONFIG_DIR	=> undef,
	    XDE_CONFIG_FILE	=> undef,
	    XDE_MENU_DIR	=> undef,
	    XDE_MENU_FILE	=> undef,
	);
	return $session;
    }
    return undef;
}

sub setup_session {
    my $self = shift;
    my $session = shift;
    my $rcdir = $self->{XDE_CONFIG_DIR};
    mkpath $rcdir unless -d $rcdir;
    foreach (@{&SUBDIRS->{$session}}) {
	mkpath "$rcdir/$_" unless -d "$rcdir/$_";
    }
    foreach my $file ($self->{XDE_CONFIG_FILE}, $self->{XDE_MENU_FILE},
	    @{&CFGFILES->{$session}}) {
	my $rcfile = "$rcdir/$file";
	my $base = $file; $base =~ s{^.*/}{};
	foreach my $dir (map {"$_/$session"} @{$self->{XDG_DATA_ARRAY}}) {
	    my $rcbase = "$dir/$base";
	    if (-f $rcbase) {
		system("/bin/cp -f \"$rcbase\" \"$rcfile\"")
		    unless -f $rcfile and (stat($rcfile))[9] > (stat($rcbase))[9];
		last;
	    }
	}
    }
}

=item $xde->B<default_banner>() => SCALAR

Determine the full path of the default branding banner from XDE/XDG
context and return it as a scalar.  L</set_vendor> should be called
before this function if it is to be called at all.

=cut

# determine the default branding banner
sub default_banner {
    my $self = shift;
    foreach my $file ("$self->{XDG_MENU_PREFIX}banner.png", "banner.png") {
	foreach my $dir (map {"$_/images"} $self->XDG_DATA_ARRAY) {
	    my $banner = "$dir/$file";
	    if (-f $banner) {
		print STDERR "Found banner '$banner'\n" if $self->{verbose};
		return $banner;
	    }
	    print STDERR "No banner named '$banner'\n" if $self->{verbose};
	}
    }
    print STDERR "Failed to find a banner\n" if $self->{verbose};
    return '';
}

=item $xde->B<get_themes> => HASHREF

Search out all XDG themes directories and collect XDE themes into a hash
reference.  The keys of the hash are the names of the theme subdirectory
in which the theme.ini file resided.  Themes follow XDG precedence rules
for XDG data directories.

Also establishes a hash refernece in $xdg->{dirs}{theme} that contains
all of the directories searched (whether they existed or not) for use in
conjunction with L<Linux::Inotify2(3pm)>.

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
	    my $short = $1 if $self->{lang} =~ /^(..)/;
	    foreach (keys %xl) {
		if (exists $xl{$_}{$self->{lang}}) {
                    $e{$_} = $xl{$_}{$self->{lang}};
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
		    $e{$wm}{$_} = $e{Theme}{$_} unless $e{$wm}{$_};
		}
	    }
	    $themes{$s} = \%e;
	}
	closedir($dir);
    }
    $self->{dirs}{theme} = \%themedirs;
    return \%themes;
}

=item $xde->B<get_styles> => HASHREF

Search out all window manager style directories and collect WM styles
into a hash reference.  The keys of the hash are the names of the style
subdirectory (or file) in which the WM-specific file resides.  Styles do
not fully follow XDG precedence rules, but follow WM-specific rules.
L</set_session> should be called before this function if it is to be
called at all.

Also establishes a hash refernece in $xdg->{dirs}{style} that contains
all of the directories searched (whether they existed or not) for use in
conjunction with L<Linux::Inotify2(3pm)>.

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
F<@XDG_DATA_DIRS/fluxbox/styles> with a fallback to
F<$HOME/.fluxbox/styles>.

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
		next unless $f =~ /^(.*)\.theme$/ and -f $f;
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
	    next unless $s =~ m{^Theme\.(.*)$} and -f "$dir/$s";
	    my $tn = $1;
	    $styles{$tn} = "$dir/$s";
	}
	closedir($dir);
    }
    $self->{dirs}{style} = \%styledirs;
    return \%styles;
}
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

=back

=cut

1;
# vim: sw=4 tw=72
