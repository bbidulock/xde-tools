package XDE::Setup;
use base qw(XDE::Gtk2);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Setup - setup an XDE session for a window manager

=head1 SYNOPSIS

 use XDE::Setup;

 my $xde = XDE::Setup->new(%OVERRIDES,ops=>%ops);

 $xde->getenv();
 $xde->set_session('fluxbox');
 $xde->setenv();

 $xde->setup_session('fluxbox') or die "Cannot use fluxbox";
 $xde->launch_session('fluxbox');

=head1 DESCRIPTION

The XDE::Setup module provides the ability to set up a window manager
environment for the I<X Desktop Environment>, L<XDE(3pm)>.

L<XDE(3pm)> relies on certain setup in the configuration files used for
supported window managers.  For the most part, I have attempted to stay
out of the way of base configurations for the respective window
managers.  Where possible, all files are located in
F<$XDG_CONFIG_HOME/xde/$wmname>, where $wmname is the lower-case name of
the window manager.

There are two non-invasive and one invasive ways to set up the
directories:

=over

=item 1.

Write a special primary configuration file and invoke the window manager
with the configuration file.  For example, create a
F<~/.fluxbox/xde-init> file and invoke L<fluxbox(1)> with C<fluxbox -rc
~/.fluxbox/xde-init>.

The problem with this method is that some window managers (e.g.
L<icewm(1)>, L<wmaker(1)>) do not have an independent primary
configuration file and rely on all config files being in the same
directory.

=item 2.

Write a full set of configuration files into a separate directory and
invoke the window manager to use the directory.  For example, create a
F<$XDG_CONFIG_HOME/xde/fluxbox> directory and invoke L<fluxbox(1)> with
C<fluxbox -rc $XDG_CONFIG_HOME/xde/fluxbox/init>.

The problem with this method is that some third-party or addon tools
might expect configuration files to exist in the normaly directory.

=item 3.

Overwrite or edit the files in the normal configuration directory.

The problem with this method is that we might overwrite somebodies
carefully hand-crafted configuration files.  This could be mitigated by
backing up whatever file is there.

=back

The boolean option C<xdg_rcdir> (see L</OPTIONS>) decides between
approach (2) and approach (1) or (3).  When not relocating directories,
approach (1) is chosen for window managers that have a primary
configuration file and approach (3) is chosen for window managers that
have no primary configuration file.

=head1 OPTIONS

XDE::Setup recognizes the following options:

=over

=item verbose => $boolean

When true, print diagnostic information to standard error during
operation.
Defaults to false.

=item xdg_rcdir => $boolean

When true, use F<$XDG_CONFIG_HOME/xde/$wmname> for all window manager
session configuration files instead of their normal locations.  Defaults
to true.

=item tmp_menu => $boolean

When true, use the F</tmp> directory to store dynamic copies of the
window manager root menu.  Not that setting this value to false will
likely result in a conflict when sessions are run on multiple hosts that
mount the same user home directory (but will not conflict for multiple
sessions on the same host).
Defaults to true.

=back

See L<XDG::Context(3pm)> for additional options recognized by the base
package.

=cut

use constant {
    MYENV => [qw(
	    ICEWM_PRIVCFG
	    ICEWM_CFGDIR
	    GNUSTEP_USER_ROOT
	    FVWM_USERDIR
    )],
};

=head1 METHODS

The following methods are provided:

=over

=item B<new> XDE::Setup I<%OVERRIDES>,ops=>\I<%ops> => $xde

Creates a new instance of an XDE::Setup object.  The XDE::Setup
module uses the L<XDE::Context(3pm)> module as a base, so the
I<%OVERRIDES> are simply passed to the L<XDE::Context(3pm)> module.
When an options hash, I<%ops>, is passed to the method, it is
initialized with default option values.  Otherwise, $xde->{ops} will
contain a reference to an options hash initialized with default values.

See L</OPTIONS> for the options recognized by XDE::Setup.

=cut

sub new {
    return XDE::Gtk2::new(@_);
}

=item $xde->B<_getenv>()

Read environment variables for this module into the context and
recalculate defaults.  Environment variables examined are:
$ICEWM_PRIVCFG, $ICEWM_CFGDIR and $GNUSTEP_USER_ROOT.  This
method may or may not be idempotent.

=cut

sub _getenv {
    my $self = shift;
    foreach (@{&MYENV}) { $self->{$_} = $ENV{$_} }
    return $self;
}

=item $xde->B<_setenv>()

Write pertinent L<XDE(3pm)> environment variables for this module from
the context into the environment.  Environment variables written are:
$ICEWM_PRIVCFG, $ICEWM_CFGDIR and $GNUSTEP_USER_ROOT.  This
method may or may not be idempotent.

=cut

sub _setenv {
    my $self = shift;
    foreach (@{&MYENV}) { delete $ENV{$_}; $ENV{$_} = $self->{$_} if $self->{$_}; }
    return $self;
}

=item $xde->B<setup_session>(I<$session>) => $xde or undef

Performs the actions necessary to prepare for the desktop session,
I<$session>.  Returns the $xde object itself, or C<undef> when the
preparation fails.  This method may launch a dialog window to prompt the
user and determine whether to overwrite files that are outdated or to
notify the user that files are being created.  When the user rejects any
of these actions, C<undef> is returned.  It may also launch a notice
dialog indicating the cause of the problem that caused the setup of the
session to fail.

=cut

sub setup_session {
    my $self = shift;
    my $session = shift;
    $session = $self->{ops}{session} unless $session;
    my $desktop = $self->set_session($session);
    my $method = "setup_session_$desktop";
    unless ($self->can($method)) {
	print STDERR "Unrecognized session '\U$desktop\E'\n";
	return undef;
    }
    $self->SUPER::setup_session($session);
    $self->setup_session_pcmanfm($session);
    $self->setup_session_lxpanel($session);
    $self->setup_session_xde($session);
    $self->$method($session);
    $self->setup_session_xde_init($session,$self->{startwm});
    return $self;
}

=over

=item $xde->B<setup_session_xde>(I<$session>) => $xde or undef

Perform the actions necessary to prepare for an L<xde-session(1)> for
the session I<$session>.  Populates the F<$XDG_CONFIG_HOME/xde>
directory with the necessary files, using defaults when necessary.

=cut

sub setup_session_xde {
    my $self = shift;
    my $session = shift;
    $session = $self->{ops}{session} unless $session;
    my $desktop = "\U$session\E";
    my $cfgdir = "$self->{XDG_CONFIG_HOME}/xde"; $cfgdir =~ s|~|$ENV{HOME}|;
    foreach my $profile ('default', $desktop) {
	my $pdir = "$cfgdir/$profile";
	$self->do_mkpath($pdir);
	foreach my $file (qw(desktop.conf session.ini input.ini xsettings.ini)) {
	    my $init = "$pdir/$file";
	    print STDERR ":: establishing: $init\n"
		if $self->{ops}{verbose};
	    my $base = $file; $base =~ s{^.*/}{};
	    foreach my $dir (map{"$_/xde-session/$profile"}$self->XDG_CONFIG_ARRAY) {
		my $ibase = "$dir/$base";
		if (-f $ibase) {
		    if (-f $init and (stat($init))[9] > (stat($ibase))[9]) {
			print STDERR "$init exists and is not older than $ibase\n"
			    if $self->{ops}{verbose};
		    } else {
			$self->do_system("/bin/cp -f --preserve=timestamps \"$ibase\" \"$init\"");
		    }
		    last;
		} else {
		    warn "$ibase does not exist"
			if $self->{ops}{verbose} and not -f $init;
		}
	    }
	}
    }
    foreach my $file (qw(autostart desktop.conf session.ini input.ini xsettings.ini)) {
	my $init = "$cfgdir/$desktop/$file";
	my $dflt = "$cfgdir/default/$file";
	if (-f $dflt) {
	    if (-f $init and (stat($init))[9] > (stat($dflt))[9]) {
		print STDERR "$init exists and is not older than $dflt\n"
		    if $self->{ops}{verbose};
	    } else {
		$self->do_system("/bin/cp -f --preserve=timestamps \"$dflt\" \"$init\"");
	    }
	} else {
	    warn "$dflt does not exist"
		if $self->{ops}{verbose} and not -f $init;
	}
    }
    return $self;
}

sub setup_session_xde_init {
    my ($self,$session,$startwm) = @_;
    my $desktop = "\U$session\E";
    my $xdedir = "$self->{XDG_CONFIG_HOME}/xde/$desktop";
    $self->do_mkpath($xdedir);
    my $sinit = "$xdedir/session.ini";
    print STDERR ":: establish a good $sinit file\n"
	if $self->{ops}{verbose};
    my $contents = <<INIT_EOF;
[Session]
StartWindowManager=$startwm
INIT_EOF
    if ($self->{ops}{dry_run}) {
	print STDERR "would overwrite $sinit with:\n",$contents;
    } else {
	if (open(my $fh,">",$sinit)) {
	    print $fh $contents,"\n";
	    close($fh);
	}
    }
    return $self;
}

=item $xde->B<setup_session_FLUXBOX>() => $xde or undef

Normally invoked as setup_session(), prepares the L<XDE(3pm)> files for
the L<fluxbox(1)> window manager and a C<FLUXBOX> L<XDE(3pm)> session.
This method primarily adjusts the file location definitions in the
F<init> file.  L<fluxbox(1)> normally has its configuration files in
F<$HOME/.fluxbox>.

L<fluxbox(1)> looks for its primary configuration in the file
F<~/.fluxbox/init>.  This file specifies the location of all other
configuration files.   L<fluxbox(1)> can be invoked with the C<-rc>
option specifying which F<init> file to use (i.e. one other than
F<~/.fluxbox/init>).  The difficulty with doing this is that
L<fluxbox(1)> provides no indication of the configuration file in use.
L<fluxbox-remote(1)> can be used (when the configuration file is
configured to allow it) to determine the location of the configuration
file.

Using this mechanism it is quite possible to relocate configuration
files to the directory F<$XDG_CONFIG_HOME/fluxbox>.

To avoid difficulties with restarting the L<fluxbox(1)> window manager
from within XDE, XDE should control the menu item for window manager
selection and add the C<-rc> option to the entry in the menu.


=cut

sub setup_session_FLUXBOX {
    my ($self,$session) = @_;
    my $rcdir = $self->{XDE_CONFIG_DIR}; $rcdir =~ s|~|$ENV{HOME}|;
    my $tilde = $rcdir; $tilde =~ s|^$ENV{HOME}|~|;
    my $rcfile = "$rcdir/$self->{XDE_CONFIG_FILE}";
    my @lines = ();
    if (-f $rcfile) {
	if (open(my $fh,"<",$rcfile)) {
	    while (<$fh>) { chomp;
		push @lines, $_;
	    }
	    close($fh);
	}
    }
    my %settings = (
	    'fbdesk.iconFile' => "$tilde/fbdesk.icons",
	    'session.styleOverlay' => "$tilde/overlay",
	    'session.slitlistFile' => "$tilde/slitlist",
	    'session.groupFile' => "$tilde/groups",
	    'session.menuFile' => "$tilde/menu",
	    'session.appsFile' => "$tilde/apps",
	    'session.keyFile' => "$tilde/keys",
	    'session.styleFile' => "/usr/share/fluxbox/styles/Squared_blue",
    );
    for (my $i=0;$i<@lines;$i++) {
	if ($lines[$i] =~ m{^([^!][^:]+):}) {
	    if (exists $settings{$1}) {
		$lines[$i] = "$1:\t".delete($settings{$1});
	    }
	}
    }
    while (my ($k,$v) = each %settings) {
	push @lines, "$k:\t$v";
    }
    if ($self->{ops}{dry_run}) {
	print STDERR "would overwrite $rcfile with:\n",join("\n",@lines),"\n";
    } else {
	if (open(my $fh,">",$rcfile)) {
	    print $fh join("\n",@lines),"\n";
	    close($fh);
	}
    }
    $rcfile =~ s|^$ENV{HOME}|\$HOME|;
    $self->{startwm} = "fluxbox -rc \"$rcfile\"";
    return $self;
}

=item $xde->B<setup_session_BLACKBOX>() => $xde or undef

Normally invoked as setup_session(), prepares the L<XDE(3pm)> files for
the L<blackbox(1)> window manager and a C<BLACKBOX> L<XDE(3pm)> session.
This method primarily adjust the file location definitions in the
F<xde-rc> file.

L<blackbox(1)> normally has its configuration file in
F<$HOME/.blackboxrc>, its menu file in F<$HOME/.bbmenu> and user styles
in the directory F<$HOME/.blackbox/styles>.  The configuration file can
be specified with the C<-rc> option when invoking L<blackbox(1)> (see
L<blackbox(1)/OPTIONS>).

The location of the menu file can be specified using the
C<session.menuFile> resource in the configuration file.  The menu file
defaults to F</usr/share/blackbox/menu>.

L<blackbox(1)> reads the configuration file on setup, and only writes
the configuration file on exit.  It will reread the configuration file
when asked to restart.

Styles and their locations in L<blackbox(1)> are specified using the
C<[stylesdir]> and C<[stylesmenu]> menu items.  By controlling the menu,
these menu items can be set to point anywhere.  Default L<blackbox(1)>
menus normally place styles in F</usr/share/blackbox/styles> and
F<$HOME/.blackbox/styles> directories.

XDE::Setup pushes all of this configuration into the user's
F<$XDG_CONFIG_HOME/blackbox> directory, creating it and populating it
when necessary.  Files to populate when creating the directory can be
found in F<@XDG_DATA_DIRS/blackbox>.

=cut

sub setup_session_BLACKBOX {
    my ($self,$session) = @_;
    my $rcdir = $self->{XDE_CONFIG_DIR}; $rcdir =~ s|~|$ENV{HOME}|;
    my $tilde = $rcdir; $tilde =~ s|^$ENV{HOME}|~|;
    my $rcfile = "$rcdir/$self->{XDE_CONFIG_FILE}";
    my @lines = ();
    if (-f $rcfile) {
	if (open(my $fh,"<",$rcfile)) {
	    while (<$fh>) { chomp;
		push @lines, $_;
	    }
	    close($fh);
	}
    }
    my %settings = (
	    'session.menuFile' => "$rcdir/menu",
	    'session.styleFile' => "/usr/share/blackbox/styles/Squared-blue",
    );
    for (my $i=0;$i<@lines;$i++) {
	if ($lines[$i] =~ m{^([^!][^:]+):}) {
	    if (exists $settings{$1}) {
		$lines[$i] = "$1:\t".delete($settings{$1});
	    }
	}
    }
    while (my ($k,$v) = each %settings) {
	push @lines, "$k:\t$v";
    }
    if ($self->{ops}{dry_run}) {
	print STDERR "would overwrite $rcfile with:\n",join("\n",@lines),"\n";
    } else {
	if (open(my $fh,">",$rcfile)) {
	    print $fh join("\n",@lines),"\n";
	    close($fh);
	}
    }
    $rcfile =~ s|^$ENV{HOME}|\$HOME|;
    $self->{startwm} = "blackbox -rc \"$rcfile\"";
    return $self;
}

=item $xde->B<setup_session_OPENBOX>() => $xde or undef

Normally invoked as setup_session(), prepares the L<XDE(3pm)> files for
the L<openbox(1)> window manager and a C<OPENBOX> L<XDE(3pm)> session.

I<Openbox> normally has its configuration file in
F<$XDG_CONFIG_HOME/openbox/rc.xml>, and its menu file in
F<$XDG_CONFIG_HOME/openbox/menu.xml>.

=cut

sub setup_session_OPENBOX {
    my ($self,$session) = @_;
    my $rcfile = "$self->{XDE_CONFIG_DIR}/$self->{XDE_CONFIG_FILE}";
    $rcfile =~ s|~|\$HOME|;
    $self->{startwm} = "openbox --config-file \"$rcfile\"";
    return $self;
}

=item $xde->B<setup_session_ICEWM>() => $xde or undef

Normally invoked as setup_session(), prepares the L<XDE(3pm)> files for
the L<icewm(1)> window manager and a C<ICEWM> L<XDE(3pm)> session.  All
we have to do for L<icewm(1)> is point it into the configuration
directory using the $ICEWM_PRIVCFG environment variable.  Note that
some other programs look for $ICEWM_CFGDIR, so we set that too.

=cut

sub setup_session_ICEWM {
    my ($self,$session) = @_;
    my $rcdir = $self->{XDE_CONFIG_DIR}; $rcdir =~ s|~|$ENV{HOME}|;
    $self->{ICEWM_PRIVCFG} = "$rcdir/";
    $self->{ICEWM_CFGDIR} = $rcdir;
    my $rcfile = "$rcdir/$self->{XDE_CONFIG_FILE}";
    $rcfile =~ s|^$ENV{HOME}|\$HOME|;
    $self->{startwm} = "icewm --config \"$rcfile\"";
    return $self;
}

=item $xde->B<setup_session_FVWM>() => $xde or undef

Normally invoked as setup_session(), prepares the L<XDE(3pm)> files for
the L<fvwm(1)> window manager and a C<FVWM> L<XDE(3pm)> session.

=cut

sub setup_session_FVWM {
    my ($self,$session) = @_;
    my $rcfile = "$self->{XDE_CONFIG_DIR}/$self->{XDE_CONFIG_FILE}";
    $rcfile =~ s|~|\$HOME|;
    $self->{startwm} = "fvwm -f \"$rcfile\"";
    return $self;
}

=item $xde->B<setup_session_JWM>() => $xde or undef

Normally invoked as setup_session(), prepares the L<XDE(3pm)> files for
the L<jwm(1)> window manager and a C<JWM> L<XDE(3pm)> session.

=cut

=item $xde->B<setup_session_PEKWM>() => $xde or undef

Normally invoked as setup_session(), prepares the L<XDE(3pm)> files for
the L<pekwm(1)> window manager and a C<PEKWM> L<XDE(3pm)> session.

=cut

=item $xde->B<setup_session_WMAKER>() => $xde or undef

Normally invoked as setup_session(), prepares the L<XDE(3pm)> files for
the L<wmaker(1)> window manager and a C<WMAKER> L<XDE(3pm)> session.
All we have to do for L<wmaker(1)> is point it into the configuration
directory using the $GNUSTEP_USER_ROOT environment variable.

=cut

sub setup_session_WMAKER {
    my ($self,$session) = @_;
    my $rcdir = $self->{XDE_CONFIG_DIR}; $rcdir =~ s|~|$ENV{HOME}|;
    $self->{GNUSTEP_USER_ROOT} = "$rcdir";
    $self->{startwm} = "wmaker";
    return $self;
}

=item $xde->B<setup_session_AFTERSTEP>() => $xde or undef

Normally invoked as setup_session(), prepares the L<XDE(3pm)> files for
the L<afterstep(1)> window manager and a C<AFTERSTEP> L<XDE(3pm)>
session.

=cut

=item $xde->B<setup_session_METACITY>() => $xde or undef

Normally invoked as setup_session(), prepares the L<XDE(3pm)> files for
the L<metacity(1)> window manager and a C<METACITY> L<XDE(3pm)> session.

=cut

=item $xde->B<setup_session_LXDE>() => $xde or undef

Normally invoked as setup_session(), prepares the L<XDE(3pm)> files for the
L<openbox(1)> window manager under an C<LXDE> L<XDE(3pm)> session.
L<xde-session(1)> behaves like L<lxsession(1)> in this setup.  There is
nothing additional to do because L<xde-session(1)> handles all
compatibility.

I<This method is deprecated: XDE no longer supports LXDE directly.>

=cut

sub setup_session_LXDE {
    my ($self,$session) = @_;
    my $rcfile = "$self->{XDE_CONFIG_DIR}/$self->{XDE_CONFIG_FILE}";
    $rcfile =~ s|~|\$HOME|;
    $self->{startwm} = "openbox --config-file \"$rcfile\"";
    return $self;
}

=item $xde->B<setup_session_lxpanel>(I<$session>)

To signal which profile for L<lxpanel(1)> to use, and which menu to
include, the environment variables $DESKTOP_SESSION,
$XDG_CURRENT_DESKTOP and $XDG_MENU_PREFIX are set to appropriate
values.  L<lxpanel(1)> looks for its configuration files in the
directory F<$XDG_CONFIG_HOME/lxpanel/$PROFILE>.  Otherwise, it looks for
files in F<$XDG_DATA_DIRS/lxpanel/profile/$PROFILE>, well really just
F</usr/share/lxpanel/profile/$PROFILE>.  It will use a profile equal to
the $DESKTOP_SESSION environment variable; and otherwise, will look
for the profile C<default>.  When the C<--profile> option is specified
to L<lxpanel(1)>, that profile overrides environment variables.

L<XDE(3pm)> installs default profile files in
F</usr/share/lxpanel/profile/$SESSION> for C<FLUXBOX>, C<BLACKBOX>,
C<OPENBOX>, C<ICEWM>, C<JWM>, C<PEKWM>, C<FVWM>, C<WMAKER>, C<AFTERSTEP>
and C<METACITY>.  So, XDE::Setup looks for them there.  XDE::Setup
also sets the $XDG_MENU_PREFIX environment variable appropriately, so
that L<lxpanel(1)> will present the correct menu.

=cut

sub setup_session_lxpanel {
    my $self = shift;
    my $session = shift;
    $session = $self->{ops}{session} unless $session;
    my $PROFILE = "\U$session\E";
    my $profdir = "$self->{XDG_CONFIG_HOME}/lxpanel/$PROFILE";
    my $panldir = "$profdir/panels";
    $self->do_mkpath($profdir);
    $self->do_mkpath($panldir);
    my $config = "$profdir/config";
    my $panel  = "$panldir/panel";
    print STDERR ":: establishing: $config and $panel\n"
	if $self->{ops}{verbose};
    foreach my $dir (map {"$_/lxpanel/profile/$PROFILE"}$self->XDG_DATA_ARRAY) {
        if (-f "$dir/config") {
	    if (-f $config and (stat($config))[9] >= (stat("$dir/config"))[9]) {
		print STDERR "$config exists and is not older than $dir/config\n"
		    if $self->{ops}{verbose};
	    } else {
		$self->do_system("/bin/cp -f --preserve=timestamps \"$dir/config\" \"$config\"");
	    }
            if (-f "$dir/panels/panel") {
		if (-f $panel and (stat($panel))[9] >= (stat("$dir/panels/panel"))[9]) {
		    print STDERR "$panel exists and is not older than $dir/panels/panel\n"
			if $self->{ops}{verbose};
		} else {
		    $self->do_system("/bin/cp -f --preserve=timestamps \"$dir/panels/panel\" \"$panel\"");
		}
            }
            last;
        } else {
	    print STDERR "no file $dir/config\n"
		if $self->{ops}{verbose} and not -f $config;
	}
    }
    my $contents = <<END_CONFIG;
[Command]
FileManager=pcmanfm -p $PROFILE %s
Terminal=lxterminal
Logout=xde-logout
END_CONFIG
    if ($self->{ops}{dry_run}) {
	print STDERR "would overwrite $config with:\n",$contents,"\n";
    } else {
	if (open(my $fh,">",$config)) {
	    print $fh $contents;
	    close($fh);
	}
    }
    return $self;
}

=item $xde->B<setup_session_pcmanfm>(I<$session>)

To signal which profile for L<pcmanfm(1)> to use, and which menu to
include, the environment variables $DESKTOP_SESSION,
$XDG_CURRENT_DESKTOP and $XDG_MENU_PREFIX are set to appropriate
values.  L<lxpanel(1)> looks for its configuration files in the
directory F<$XDG_CONFIG_HOME/pcmanfm/$PROFILE>.  Otherwise, it looks for
files in F<$XDG_CONFIG_DIRS/pcmanfm/$PROFILE>.  Note the difference here
from L<lxpanel(1)>.  It will use a profile equal to $DESKTOP_SESSION
environment variable; and otherwise, will look for the profile
C<default>.  When the C<--profile> option is specified to L<pcmanfm(1)>,
that profile overrides environment variables.

L<XDE(3pm)> install default profile files in
F</etc/xdg/pcmanfm/$SESSION> for C<FLUXBOX>, C<BLACKBOX>, C<OPENBOX>,
C<ICEWM>, C<JWM>, C<PEKWM>, C<FVWM>, C<WMAKER>, C<AFTERSTEP> and
C<METACITY>.  So, XDE::Setup looks for them there.  XDE::Setup
also sets the $XDG_MENU_PREFIX environment variable appropriately, so
that L<pcmanfm(1)> will present the correct menu under C<Applications>.

=cut

sub setup_session_pcmanfm {
    my $self = shift;
    my $session = shift;
    $session = $self->{ops}{session} unless $session;
    my $PROFILE = "\U$session\E";
    my $profdir = "$self->{XDG_CONFIG_HOME}/pcmanfm/$PROFILE";
    $self->do_mkpath($profdir);
    my $config = "$profdir/pcmanfm.conf";
    my $ditems = "$profdir/desktop-items-0.conf";
    print STDERR ":: establishing: $config and $ditems\n"
	if $self->{ops}{verbose};
    foreach my $dir (map {"$_/pcmanfm/$PROFILE"}$self->XDG_CONFIG_ARRAY) {
	if (-f "$dir/pcmanfm.conf") {
	    if (-f $config and (stat($config))[9] >= (stat("$dir/pcmanfm.conf"))[9]) {
		print STDERR "$config exists and is not older than $dir/pcmanfm.conf\n"
		    if $self->{ops}{verbose};
	    } else {
		$self->do_system("/bin/cp -f --preserve=timestamps \"$dir/pcmanfm.conf\" \"$config\"");
	    }
	    if (-f "$dir/desktop-items-0.conf") {
		if (-f $ditems and (stat($ditems))[9] >= (stat("$dir/desktop-items-0.conf"))[9]) {
		    print STDERR "$ditems exists and is not older than $dir/desktop-items-0.conf\n"
			if $self->{ops}{verbose};
		} else {
		    $self->do_system("/bin/cp -f --preserve=timestamps \"$dir/desktop-items-0.conf\" \"$ditems\"");
		}
	    }
	    last;
        } else {
	    print STDERR "no file $dir/pcmanfm.conf\n"
		if $self->{ops}{verbose} and not -f $config;
	}
    }
    return $self;
}

=back

=item $xde->B<prompt_initialize>(I<@details>) => $choice

An internal method to launch a dialog window to check whether the user
wishes us to initialize files in her home directory for use by the
session.  Only launched when a necessary file is missing.  Returns the
result of the dialog.  I<@details> is the textual description lines
detailing the actions that will be performed; which may or may not be
displayed.

=cut

=item $xde->B<prompt_overwrite>(I<@details>) => $choice

An internal method to launch a dialog window to check whether the user
wishes us to updated files in her home directory for use by the session
that are outdated in comparison to system files.  Returns the result of
the dialog.  I<@details> is the textual description lines detailing the
actions that will be performed; which may or may not be displayed.

=cut

=item $xde->B<launch_session>(I<$session>) => $xde

Launch the session.  This method never returns.

=cut

sub do_exec {
    my ($self,@cmds) = @_;
    my $cmd = join(' ',@cmds);
    if ($self->{ops}{dry_run}) {
	print STDERR "exec ",$cmd,"\n";
	return 1;
    }
    exec($cmd) or die "cannot launch XDE session: ", $cmd;
}

sub launch_session {
    my ($self,$session) = @_;
    $session = $self->{ops}{session} unless $session;
    my $startwm = $self->{startwm};
    $startwm =~ s|"|\\"|g;
    my $vendor = $self->{XDG_VENDOR_ID};
    $vendor = " -vendor $vendor" if $vendor;
    my $command = "xde-session${vendor} -desktop \U$session\E -startwm \"$startwm\"";
    $self->setenv();
    $self->do_exec($command);
    return $self;
}

1;

__END__

=back

See L<XDE::Gtk2(3pm)/METHODS> for additional inherited methods.

=head1 WINDOW MANAGERS

The following window managers are supported:

=over

=item L<fluxbox(1)>

L<fluxbox(1)> looks for its primary configuration in the file
F<~/.fluxbox/init>.  This file specifies the location of all other
configuration files.   L<fluxbox(1)> can be invoked with the C<-rc>
option specifying which F<init> file to use (i.e. one other than
F<~/.fluxbox/init>).  The difficulty with doing this is that
L<fluxbox(1)> provides no indication of the configuration file in use.
L<fluxbox-remote(1)> can be used (when the configuration file is
configured to allow it) to determine the location of the configuration
file.

Using this mechanism it is quite possible to relocate configuration
files to the directory F<$XDG_CONFIG_HOME/xde/fluxbox>.

To avoid difficulties with restarting the L<fluxbox(1)> window manager
from within XDE, XDE should control the menu item for window manager
selection and add the C<-rc> option to the entry in the menu.

=item L<blackbox(1)>

L<blackbox(1)> looks for its primary configuration in the file
F<~/.blackboxrc>.  This file specifies the location of all other
configuration files (typically placed under F<~/.blackbox>).
L<blackbox(1)> can be invoked with the C<-rc> option specifying the
location of a different F<rc> file to use (i.e. one other than
F<~/.blackboxrc>).  The difficulty with doing this is that
L<blackbox(1)> provides no indication of the configuration file in use.

Using this mechanism it is quite possible to relocate configuration
files to the directory F<$XDG_CONFIG_HOME/xde/blackbox>.

To avoid difficulties with restarting the L<blackbox(1)> window manager
from within XDE, XDE should control the menu item for window manager
selection and add the C<-rc> option to the entry in the menu.

=item L<openbox(1)>

L<openbox(1)> looks for its primary configuration in the file
F<~/.config/openbox/rc.xml>.  This file specifies the location of all
other configuration files (typically placed under F<~/.config/openbox>).
L<openbox(1)> can be invoked with the C<--config-file> option specifying
a different F<rc.xml> file.  L<openbox(1)> does set a root window
property, C<_OPENBOX_CONFIG>, indicating which F<rc> file is in use.

Using this mechanism it is quite possible to relocate configuration
files to the F<$XDG_CONFIG_HOME/xde/openbox> directory.

To avoid difficulties with restarting  the L<openbox(1)> window manager
from within XDE, XDE should control the menu item for window manager
selection and add the C<--config-file> option to the entry in the menu.

=item L<icewm(1)>

L<icewm(1)> looks for its configuration files in the directory
F<~/.icewm>.  L<icewm(1)> can be invoked with the $ICEWM_PRIVCFG
environment variable set to a different directory.  Examining the
$ICEWM_PRIVCFG environment variable will determine which
configuration files are in use.

Using this mechanism, it is quite possible to relocate configuration
files to the F<$XDG_CONFIG_HOME/xde/icewm> directory.

To avoid difficulties with restarting the L<icewm(1)> window manager
from within XDE, XDE should always set the $ICEWM_PRIVCFG environment
variable.

=item L<jwm(1)>

L<jwm(1)> looks for its primary configuration in the file F<~/.jwmrc>.
This file specifies the location of all other configuration files
(typically placed under F<~/.jwm>).  L<jwm(1)> has no mechanism for
specifying the name or location of the F<rc> file on startup.

For L<jwm(1)>, XDE must replace any user F<~/.jwmrc> configuration file
with one specialized for XDE.  The recommended technique is to move
F<~/.jwmrc> to F<~/.jwmrc.bak> (if F<~/.jwmrc> exists and is a file),
and symbolically link F<~/.jwmrc> to F<$XDG_CONFIG_HOME/xde/jwm/rc>.

=over 4

=item B<NOTE:>

I would prefer to fix L<jwm(1)> and add an C<-rc> option.

=back

=item L<pekwm(1)>

L<pekwm(1)> looks for its primary configuraiton in the file
F<~/.pekwm/config>.  This file specifies the location of all other
configuration files.  L<pekwm(1)> may be invoked with the C<--config>
option speciyfing the location of a different F<config> file to use
(i.e. other than F<~/.pekwm/config>).  The difficulty with doing this is
that L<pekwm(1)> provides no indication of the configuration file in
use.

Using this mechanism, it is quite possible to relocate configuration
files to the F<$XDG_CONFIG_HOME/xde/pekwm> directory.

To avoid difficulties with restarting the L<pekwm(1)> window manager
from within XDE, XDE needs to control the menu item for window manager
selection and add the C<--config> option to the entry in the menu.

=item L<fvwm(1)>

L<fvwm(1)> looks for its primary configuration in the file
F<~/.fvwm/config>.  This file specifies the location of all other
configuration files.  L<fvwm(1)> may be invoked with the C<-f> option
specifying the location of a different F<config> file to use (i.e. other
than F<~/.fvwm/config>).  Also, the directory F<~/.fvwm> can be altered
by setting the $FVWM_USERDIR environment variable.

Using this mechanism, it is quite possible to relocate configuration
files to the F<$XDG_CONFIG_HOME/xde/fvwm> directory.

To avoid difficulties with restarting the L<fvwm(1)> window manager from
within XDE, XDE should always set the $FVWM_USERDIR environment
variable.

=item L<wmaker(1)>

L<wmaker(1)> looks for its primary configuration in the file
F<~/GNUstep/Defaults/WindowMaker>.  This file specifies the location of
all other configuration files.  L<wmaker(1)> may be invoked with the
$GNUSTEP_USER_ROOT environment variable set, which changes the
directory from F<~/GNUstep> and the primary configuration file will be
located in F<$GNUSTEP_USER_ROOT/Defaults/WindowMaker>.

Using this mechanism, it is quite possible to reclocate configuration
files to the F<$XDG_CONFIG_HOME/wmaker> directory.

To avoid difficulties with restarting the L<wmaker(1)> window manager
from within XDE, XDE should always set the $GNUSTEP_USER_ROOT
environment variable.

=item L<afterstep(1)>

=item L<metacity(1)>

L<metacity(1)> does not read a configuraiton file on startup.  It uses
L<dconf(1)> to query the desktop configration database for window
manager settings.

=item L<wmx(1)>

=back

=head1 HISTORY

Originally, XDE::Setup would only set up directories and configuration
files for the window manager being launched.  However, to permit the
user to switch window managers mid-session, XDE::Setup was changed to
set up configuration for all supported window managers regardless of
which is launched.  The methods are still organized in the old fashion,
they are simply all executed instead of just one.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<fluxbox(1)>,
L<blackbox(1)>,
L<openbox(1)>,
L<icewm(1)>,
L<jwm(1)>,
L<pekwm(1)>,
L<fvwm(1)>,
L<wmaker(1)>,
L<afterstep(1)>,
L<metacity(1)>,
L<XDE::Gtk2(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
