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
sub new {
	return XDG::Context::new(@_);
}
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
sub getenv {
    my $self = shift;
    foreach (@{&MYENV}) { $self->{$_} = $ENV{$_} }
    return $self->SUPER::getenv();
}
sub setenv {
    my $self = shift;
    $self->SUPER::setenv();
    foreach (@{&MYENV}) {
	delete $ENV{$_};
	$ENV{$_} = $self->{$_} if $self->{$_};
    }
    return $self;
}
sub DESKTOP_SESSION	{ return shift->get_or_set(DESKTOP_SESSION  =>@_) }
sub FBXDG_DE		{ return shift->get_or_set(FBXDG_DE	    =>@_) }
sub XDE_SESSION		{ return shift->get_or_set(XDE_SESSION	    =>@_) }
sub XDE_CONFIG_DIR	{ return shift->get_or_set(XDE_CONFIG_DIR   =>@_) }
sub XDE_CONFIG_FILE	{ return shift->get_or_set(XDE_CONFIG_FILE  =>@_) }
sub XDE_MENU_DIR	{ return shift->get_or_set(XDG_MENU_DIR	    =>@_) }
sub XDE_MENU_FILE	{ return shift->get_or_set(XDG_MENU_FILE    =>@_) }

sub set_session {
    my $self = shift;
    my $session = shift;
    if (exists &SESSIONS->{"\L$session\E"}) {
	$session = &SESSIONS->{"\L$session\E"};
	my $desktop = "\U$session\E";
	$self->setup({
	    XDG_CURRENT_DESKTOP => $desktop,
	    DESKTOP_SESSION	=> $desktop,
	    FBXDG_DE		=> $desktop,
	    XDE_SESSION		=> $session,
	    XDE_CONFIG_DIR	=> undef,
	    XDE_CONFIG_FILE	=> undef,
	    XDE_MENU_DIR	=> undef,
	    XDE_MENU_FILE	=> undef,
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

sub mkdirs {
    my $self = shift;
    $self->SUPER::mkdirs();
    foreach (qw(XDE_CONFIG_HOME XDE_CONFIG_DIR XDE_MENU_DIR)) {
	if (my $dir = $self->{$_}) {
	    eval { mkpath $dir; } unless -d $dir;
	}
    }
}

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

1;

