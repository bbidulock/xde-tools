package XDE::Startup;
use base XDE::Context;

use constant {
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
    SUBDIRS => {
	fluxbox		 => [qw(backgrounds icons pixmaps splash styles tiles)],
	blackbox	 => [qw(backgrounds styles)],
	openbox		 => [],
	icewm		 => [qw(themes)],
	fvwm		 => [qw(icons)],
    },
    CFGFILES => {
	fluxbox		 => [qw(overlay menuconfig startup windowmenu usermenu fbpager keys slitlist apps)],
	blackbox	 => [],
	openbox		 => [],
	icewm		 => [qw(focus_mode keys prefoverride programs theme)],
	fvwm		 => [qw(bindings decorations functions globalfeel iconstyles menus modules startup sytles)],
    },
};

sub new {
    my $type = shift;
    my $session = shift;
    return undef unless exists &SESSION->{$session};
    $session = &SESSIONS->{"\L$session\E"};
    my $desktop = "\U$session\E";
    my $self = &XDE::Context::new($type,{
	    XDG_CURRENT_DESKTOP	=> $desktop,
	    DESKTOP_SESSION	=> $desktop,
	    FBXDG_DE		=> $desktop,
	    XDE_SESSION		=> $session,
	    XDE_CONFIG_DIR	=> undef,
	    XDE_CONFIG_FILE	=> undef,
	    XDE_MENU_DIR	=> undef,
	    XDE_MENU_FILE	=> undef,
    });
}

sub set_session {
    my $self = shift;
    my ($session,$notmp,$xdg) = @_;
    my $tmp = $notmp ? 0 : 1;
    my $session = shift;
    if (exists &SESSIONS->{"\L$session\E"}) {
	$session = &SESSIONS->{"\L$session\E"};
	my $desktop = "\U$session\E";
	my $menudir = &MENUDIR->{$session};
	if ($tmp) {
	    my $prefix = $ENV{XDG_MENU_PREFIX};
	    $prefix = "$ENV{XDG_VENDOR_ID}-" unless $prefix or not $ENV{XDG_VENDOR_ID};
	    $prefix = '' unless $prefix;
	    $prefix =~ s{-$}{};
	    $prefix = "/$prefix" if $prefix;
	    $menudir = "/tmp/xde/$desktop$prefix";
	}
	my $confdir = &CONFDIR->{$session};
	if ($xdg) {
	    my $confhome = $ENV{XDG_CONFIG_HOME};
	    $confhome = "$ENV{HOME}/.config" unless $confhome;
	    $confdir = "$confhome/$session";
	}
	$self->setup({
	    XDG_CURRENT_DESKTOP => $desktop,
	    DESKTOP_SESSION	=> $desktop,
	    FBXDG_DE		=> $desktop,
	    XDE_SESSION		=> $session,
	    XDE_CONFIG_DIR	=> $confdir,
	    XDE_CONFIG_FILE	=> &CONFFILE->{$session},
	    XDE_MENU_DIR	=> $menudir,
	    XDE_MENU_FILE	=> &MENUFILE->{$session},
	});
	return $session;
    }
    return undef;
}

sub setup_session {
    my $self = shift;
    my $session = shift;
    my $rcdir = $self->{XDE_CONFIG_DIR};
    mkpath $rcdir unless -d $rcdir;
    foreach (@{&XDE::Context::SUBDIRS->{$session}}) {
	mkpath "$rcdir/$_" unless -d "$rcdir/$_";
    }
    foreach my $file ($self->{XDE_CONFIG_FILE}, $self->{XDE_MENU_FILE},
	    @{&XDE::Context::CFGFILES->{$session}}) {
	my $rcfile = "$rcdir/$file";
	$base = $file; $base =~ s{^.*/}{};
	foreach my $dir (map {"$_/$session"} @{$self->{XDG_DATA_ARRAY}}) {
	    my $rcbase = "$dir/$base";
	    if (-f $rcbase) {
		system("/bin/cp -f \"$rcbase\" \"$rcfile\"")
		    unless -f $rcfile and stat($rcfile)[9] > stat($rcbase);
		last;
	    }
	}
    }
}
