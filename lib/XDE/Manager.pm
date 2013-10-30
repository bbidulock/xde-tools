package XDE::Manager;
use base qw(XDE::WMH XDE::EWMH);
use strict;
use warnings;

=head1 NAME

XDE::Manager -- provides window manager specific control methods

=head1 DESCRIPTION

Provides a module with methods that can be used to control specific
window managers.  This module is meant to be used as a base for other
modules.  It supports actions performable using window-manager-specific
controls.

=head1 METHODS

This module provides the following methods:

=over

=item $manager->B<setup>()

Called to set up this module.  Setting up the module consists of
registering for the proper events on the root window and establishing
root window properties; setting up for file change notification.  If no
window manager yet exists, root window properties for WMH and EWMH will
be obtained when one appears.

=cut

=item $manager->B<wm_default>() => $manager

Internal method to establish defaults for the XDE::Manager object
without invoking the defaults of the superior module: used for multiple
inheritance.  Normally called by the default() method of this pakcage or
a derived package.  Establishes a wide range of XDG and XDE session
parameters and defaults.
This method may or may not be idempotent.

=cut

sub wm_default {
    my $self = shift;
    return $self;
}

use constant {
    MYENV => [qw(
	    DESKTOP_SESSION
	    FBXDG_DE
	    )],
    MYPROP => [qw(
	    _XDE_SESSION
	    _XDE_CONFIG_DIR
	    _XDE_CONFIG_FILE
	    _XDE_MENU_DIR
	    _XDE_MENU_FILE
	    )],
};

=item $manager->B<getenv>()

Read environment variables and X display root window properties into the
manager context and recalculate the defaults.  Environment variables
examined are B<DESKTOP_SESSION> and B<FBXDG_DE> and those described
under L<XDG::Context(3pm)/getenv>.  X display root window properties
examined are C<_XDE_SESSION>, C<_XDE_CONFIG_DIR>, C<_XDE_CONFIG_FILE>,
C<_XDE_MENU_DIR>, and C<_XDE_MENU_FILE>.  Also calls C<_getenv> of the
derived class when available.  This method may or may not be idempotent.

=cut

sub getenv {
    my $self = shift;
    foreach (@{&MYPROP}) {
	my $sub = $self->can("get_$_");
	&$sub($self) if $sub;
    }
    foreach (@{&MYENV}) { $self->{$_} = $ENV{$_} }
    return $self->XDE::Context::getenv(@_);;
}

=item $manager->B<setenv>()

Write pertinent XDE environment variables from the manager context to
the environment and X display root window.  Environment variables
written are: B<DESKTOP_SESSION> and B<FBXDG_DE>.  X display root window
properties written are C<_XDE_SESSION>, C<_XDE_CONFIG_DIR>,
C<_XDE_CONFIG_FILE>, C<_XDE_MENU_DIR>, C<_XDE_MENU_FILE>.
This method may or may not be idempotent.

=cut

sub setenv {
    my $self = shift;
    $self->XDE::Context::setenv(@_);
    foreach (@{&MYENV}) { delete $ENV{$_}; $ENV{$_} = $self->{$_} if $self->{$_}; }
    foreach (@{&MYPROP}) {
	my $sub = $self->can("set_$_");
	&$sub($self,$self->{$_}) if $sub;
    }
    return $self;
}

sub wm_specific_method {
    my $self = shift;
    my $name = shift;
    my $wmname = $self->{wmname};
    $wmname = 'none' unless $wmname;
    my $func = "${name}_\U$wmname\E";
    my $sub = $self->can("${name}_\U$wmname\E");
    $sub = $self->can("${name}_UNKNOWN") unless $sub;
    return (wantarray ? () : undef) unless $sub;
    return &$sub($self,@_);
}

=back

=head2 Window Manager PID

The following methods are used to discover the process identifier (PID)
of the running window manager.

Unfortunately, not all window managers set the PID of the window manager
in a property on the check or root window.  It is not ideal to send
signals to the window manager without the PID.  We could do, for
example, C<killall -HUP $self->{wmname}>, provided that the effect of
the signal does not disrupt other sessions on the same host for the same
user.

To try to side-step this issue, L<xde-session(1p)> and friends always
set the C<_\U$self->{wmname}\E_PID(CARDINAL)> property on the root
window before launching the window manager (and sometimes remove it upon
exit).  The following methods always check this root window property as
a fallback.

=over

=item $manager->B<wm_pid>() => $pid or undef

Returns the PID associated with the running window manager.  This should
only be called after get_NET_SUPPORTING_WM_CHECK().  It uses the window
manager name to choose the method to use to determine the window manager
process identifier.

=cut

sub wm_pid {
    return shift->wm_specific_method('wm_pid');
}

=over

=item $manager->B<wm_pid_FLUXBOX>() => $pid or undef

L<fluxbox(1)> does not set C<_NET_WM_PID> on the support window, but
does set C<_BLACKBOX_PID(CARDINAL)> on the root window to the PID of the
window manager process.

=cut

sub wm_pid_FLUXBOX {
    my $self = shift;
    my $pid = $self->{_BLACKBOX_PID};
    $pid = $self->get_BLACKBOX_PID unless $pid;
    $pid = $self->wm_pid_UNKNOWN unless $pid;
    $self->{wmpid} = $pid if $pid;
    return $pid;
}

=item $manager->B<wm_pid_BLACKBOX>() => $pid or undef

Older versions of L<blackbox(1)> did not set a PID anywhere.  Recent
versions of L<blackbox(1)> set the C<_NET_WM_PID(CARDINAL)> property
against the C<_NET_SUPPORTING_WM_CHECK(WINDOW)> window.

=cut

sub wm_pid_BLACKBOX {
    return shift->wm_pid_UNKNOWN(@_);
}

=item $manager->B<wm_pid_OPENBOX>() => $pid or undef

L<openbox(1)> does not set the C<_NET_WM_PID(CARDINAL)> property on the
check window, but does set C<_OPENBOX_PID(CARDINAL)> on the root window.

=cut

sub wm_pid_OPENBOX {
    return shift->wm_pid_UNKNOWN(@_);
}

=item $manager->B<wm_pid_ICEWM>() => $pid or undef

All recent versions of L<icewm(1)> correctly set the
C<_NET_WM_PID(CARDINAL)> property on the check window.

=cut

sub wm_pid_ICEWM {
    return shift->wm_pid_UNKNOWN(@_);
}

=item $manager->B<wm_pid_PEKWM>() => $pid or undef

L<pekwm(1)> is setting the C<_NET_WM_PID(CARDINAL)>, but it is setting
it on the root window instead of the check window.

=cut

sub wm_pid_PEKWM {
    return shift->wm_pid_UNKNOWN(@_);
}

=item $manager->B<wm_pid_JWM>() => $pid or undef

Current versions of L<jwm(1)> set the C<_NET_WM_PID(CARDINAL)> property
on the check window.  Previous versions did not set the pid anywhere.

=cut

sub wm_pid_JWM {
    return shift->wm_pid_UNKNOWN(@_);
}

=item $manager->B<wm_pid_WMAKER>() => $pid or undef

L<wmaker(1)> is not setting its process identifier anywhere: not on the
root window and not on the check window.

=cut

sub wm_pid_WMAKER {
    return shift->wm_pid_UNKNOWN(@_);
}

=item $manager->B<wm_pid_FVWM>() => $pid or undef

L<fvwm(1)> is not setting its process identifier anywhere: not on the
root window and not on the check window.

=cut

sub wm_pid_FVWM {
    return shift->wm_pid_UNKNOWN(@_);
}

=item $manager->B<wm_pid_AFTERSTEP>() => $pid or undef

L<afterstep(1). is not settings its process identifier anywhere: not on
the root window and not on the check window.

=cut

sub wm_pid_AFTERSTEP {
    return shift->wm_pid_UNKNOWN(@_);
}

=item $manager->B<wm_pid_METACITY>() => $pid or undef

L<metacity(1)> is not setting its process identifier anywhere: not on
the root window and not on the check window.

=cut

sub wm_pid_METACITY {
    return shift->wm_pid_UNKNOWN(@_);
}

=item $manager->B<wm_pid_WMX>() => $pid or undef

L<wmx(1)> is not setting its process identifier anywhere: not on the
root window and not on the check window.  Strange, because sending a
C<SIGTERM> or C<SIGINT> will cause L<wmx(1)> to exit, and sending a
C<SIGHUP> will cause it to restart.  Not providing any PID is rather odd
considering that L<wmx(1)> does not accept any root window messages for
restart or reload and can only be controlled (restarted) with signals.

=cut

sub wm_pid_WMX {
    return shift->wm_pid_UNKNOWN(@_);
}

=item $manager->B<wm_pid_UNKNOWN>() => $pid or undef

The default behaviour of a window manager is to set its PID in the
C<_NET_WM_PID(CARDINAL)> property on the check window.  When the window
manager is unknown, we first attempt that.  Next check whether the
C<_NET_WM_PID(CARDINAL)> property is set on the root window.  Next check
whether the C<_\U${wmname}\E_PID(CARDINAL)> property is being set on the
root window.

=cut

sub wm_pid_UNKNOWN {
    my $self = shift;
    my $pid;
    my $check = $self->{_NET_SUPPORTING_WM_CHECK};
    $check = $self->get_NET_SUPPORTING_WM_CHECK unless $check;
    if ($check) {
	$pid = $self->{windows}{$check}{_NET_WM_PID};
	$pid = $self->get_NET_WM_PID($check);
	return $pid if $pid;
    }
    $pid = $self->{_NET_WM_PID};
    $pid = $self->get_root_NET_WM_PID unless $pid;
    return $pid if $pid;
    my $atom = "_\U$self->{wmname}\E_PID";
    $pid = $self->{$atom};
    $pid = $self->getWMRootPropertyInt($atom);
    $self->{$atom} = $pid;
    return $pid;
}

=back

=back

=head2 Window Manager Configuration

The following methods are used to locate the configuration files of the
running window manager.

Unfortunately, not all window managers respect an environment variable
to assist in locating primary or secondary configuration files.
Therefore, for some window managers is is difficult to determine the
location of the configuration files used by the running instance.

To try to side-step this issue, L<xde-session(1p)> and friends always
invoke the window manager using the L<xde-startwm(1p)> program which
respects the environment variables established.

=over

=item $manager->B<wm_config>() => $sys, $usr, $file, $sfile

Obtain the system directory, I<$sys>, user directory, I<$usr>, primary
configuration file, I<$file>, and style or theme definition file,
I<$sfile>.  (Note that I<$sfile> is not always different than I<$file>.)

=cut

sub wm_config {
    return shift->wm_specific_method('wm_config');
}

=over

=item $manager->B<wm_config_FLUXBOX>() => $sys, $usr, $file, $sfile

The default configuration file for L<fluxbox(1)> is F<~/.fluxbox/init>.
L<xde-session(1p)> typically sets the C<FLUXBOX_RCFILE> environment
variable to F<$XDG_CONFIG_HOME/xde/fluxbox/init> and invokes
L<fluxbox(1)> equivalent to the following:

    fluxbox ${FLUXBOX_RCFILE:+-rc $FLUXBOX_RCFILE}

When unset, C<FLUXBOX_RCFILE> defaults to F<~/.fluxbox/init>;
C<FLUXBOX_SYSDIR> defaults to F</usr/share/fluxbox>, C<FLUXBOX_USRDIR>
defaults to F<~/.fluxbox> and C<FLUXBOX_STYLEF> defaults to
F<$FLUXBOX_RCFILE>.

=cut

sub wm_config_FLUXBOX {
    my $self = shift;
    unless ($self->{FLUXBOX_RCFILE}) {
	$self->{FLUXBOX_SYSDIR} = $ENV{FLUXBOX_SYSDIR};
	$self->{FLUXBOX_SYSDIR} = '/usr/share/fluxbox'
	    unless $self->{FLUXBOX_SYSDIR};
	$self->{FLUXBOX_USRDIR} = $ENV{FLUXBOX_USRDIR};
	$self->{FLUXBOX_USRDIR} = "$ENV{HOME}/.fluxbox"
	    unless $self->{FLUXBOX_SYSDIR};
	$self->{FLUXBOX_RCFILE} = $ENV{FLUXBOX_RCFILE};
	$self->{FLUXBOX_RCFILE} = "$self->{FLUXBOX_USRDIR}/init"
	    unless $self->{FLUXBOX_RCFILE};
	$self->{FLUXBOX_STYLEF} = $self->{FLUXBOX_RCFILE};
    }
    return ($self->{FLUXBOX_SYSDIR},
	    $self->{FLUXBOX_USRDIR},
	    $self->{FLUXBOX_RCFILE},
	    $self->{FLUXBOX_STYLEF});
}

=item $manager->B<wm_config_BLACKBOX>() => $sys, $usr, $file, $sfile

=cut

sub wm_config_BLACKBOX {
    my $self = shift;
    unless ($self->{BLACKBOX_RCFILE}) {
	$self->{BLACKBOX_SYSDIR} = $ENV{BLACKBOX_SYSDIR};
	$self->{BLACKBOX_SYSDIR} = '/usr/share/blackbox'
	    unless $self->{BLACKBOX_SYSDIR};
	$self->{BLACKBOX_USRDIR} = $ENV{BLACKBOX_USRDIR};
	$self->{BLACKBOX_USRDIR} = "$ENV{HOME}/.blackbox"
	    unless $self->{BLACKBOX_SYSDIR};
	$self->{BLACKBOX_RCFILE} = $ENV{BLACKBOX_RCFILE};
	$self->{BLACKBOX_RCFILE} = "$ENV{HOME}/.blackboxrc"
	    unless $self->{BLACKBOX_RCFILE};
	$self->{BLACKBOX_STYLEF} = $self->{BLACKBOX_RCFILE};
    }
    return ($self->{BLACKBOX_SYSDIR},
	    $self->{BLACKBOX_USRDIR},
	    $self->{BLACKBOX_RCFILE},
	    $self->{BLACKBOX_STYLEF});
}

=item $manager->B<wm_config_OPENBOX>() => $sys, $usr, $file, $sfile

=cut

sub wm_config_OPENBOX {
    my $self = shift;
    unless ($self->{OPENBOX_RCFILE}) {
	$self->{OPENBOX_SYSDIR} = $ENV{OPENBOX_SYSDIR};
	$self->{OPENBOX_SYSDIR} = '/usr/share/openbox'
	    unless $self->{OPENBOX_SYSDIR};
	$self->{OPENBOX_USRDIR} = $ENV{OPENBOX_USRDIR};
	$self->{OPENBOX_USRDIR} = "$self->{XDG_CONFIG_HOME}/openbox"
	    unless $self->{OPENBOX_USRDIR};
	$self->{OPENBOX_RCFILE} = $ENV{OPENBOX_RCFILE};
	$self->{OPENBOX_RCFILE} = "$self->{OPENBOX_USRDIR}/rc.xml"
	    unless $self->{OPENBOX_RCFILE};
	$self->{OPENBOX_STYLEF} = $ENV{OPENBOX_STYLEF};
	$self->{OPENBOX_STYLEF} = $self->{OPENBOX_RCFILE}
	    unless $self->{OPENBOX_STYLEF};
    }
    return ($self->{OPENBOX_SYSDIR},
	    $self->{OPENBOX_USRDIR},
	    $self->{OPENBOX_RCFILE},
	    $self->{OPENBOX_STYLEF});
}

=item $manager->B<wm_config_ICEWM>() => $sys, $usr, $file, $sfile

=cut

sub wm_config_ICEWM {
    my $self = shift;
    unless ($self->{ICEWM_RCFILE}) {
	$self->{ICEWM_SYSDIR} = $ENV{ICEWM_SYSDIR};
	$self->{ICEWM_SYSDIR} = '/usr/share/icewm'
	    unless $self->{ICEWM_SYSDIR};
	$self->{ICEWM_USRDIR} = $ENV{ICEWM_PRIVCFG};
	$self->{ICEWM_USRDIR} = "$ENV{HOME}/.icewm"
	    unless $self->{ICEWM_USRDIR};
	$self->{ICEWM_RCFILE} = $ENV{ICEWM_RCFILE};
	$self->{ICEWM_RCFILE} = "$self->{ICEWM_USRDIR}/preferences"
	    unless $self->{ICEWM_RCFILE};
	$self->{ICEWM_STYLEF} = $ENV{ICEWM_STYLEF};
	$self->{ICEWM_STYLEF} = "$self->{ICEWM_USRDIR}/theme"
	    unless $self->{ICEWM_STYLEF};
    }
    return ($self->{ICEWM_SYSDIR},
	    $self->{ICEWM_USRDIR},
	    $self->{ICEWM_RCFILE},
	    $self->{ICEWM_STYLEF});
}

=item $manager->B<wm_config_PEKWM>() => $sys, $usr, $file, $sfile

Unfortunately, L<pekwm(1)> places some system configuration files in
F</usr/share/pekwm> and others in F</etc/pekwm>.

=cut

sub wm_config_PEKWM {
    my $self = shift;
    unless ($self->{PEKWM_RCFILE}) {
	$self->{PEKWM_SYSDIR} = $ENV{PEKWM_SYSDIR};
	$self->{PEKWM_SYSDIR} = '/usr/share/pekwm'
	    unless $self->{PEKWM_SYSDIR};
	$self->{PEKWM_ETCDIR} = $ENV{PEKWM_ETCDIR};
	$self->{PEKWM_ETCDIR} = '/etc/pekwm'
	    unless $self->{PEKWM_ETCDIR};
	$self->{PEKWM_USRDIR} = $ENV{PEKWM_USRDIR};
	$self->{PEKWM_USRDIR} = "$ENV{HOME}/.pekwm"
	    unless $self->{PEKWM_USRDIR};
	$self->{PEKWM_RCFILE} = $ENV{PEKWM_RCFILE};
	$self->{PEKWM_RCFILE} = "$self->{PEKWM_USRDIR}/config"
	    unless $self->{PEKWM_RCFILE};
    }
    return ($self->{PEKWM_SYSDIR},
	    $self->{PEKWM_USRDIR},
	    $self->{PEKWM_RCFILE},
	    $self->{PEKWM_STYLEF});
}

=item $manager->B<wm_config_JWM>() => $sys, $usr, $file, $sfile

=cut

=item $manager->B<wm_config_WMAKER>() => $sys, $usr, $file, $sfile

=cut

=item $manager->B<wm_config_FVWM>() => $sys, $usr, $file, $sfile

=cut

=item $manager->B<wm_config_AFTERSTEP>() => $sys, $usr, $file, $sfile

=cut

=item $manager->B<wm_config_METACITY>() => $sys, $usr, $file, $sfile

=cut

=item $manager->B<wm_config_WMX>() => $sys, $usr, $file, $sfile

=cut

=back

=back

=head2 WIndow Manager Information

=over

=item $manager->B<wm_about>()

=cut

=over

=item $manager->B<wm_about_FLUXBOX>()

=cut

=item $manager->B<wm_about_BLACKBOX>()

=cut

=item $manager->B<wm_about_OPENBOX>()

=cut

=item $manager->B<wm_about_ICEWM>()

=cut

=item $manager->B<wm_about_PEKWM>()

=cut

=item $manager->B<wm_about_JWM>()

=cut

=item $manager->B<wm_about_WMAKER>()

=cut

=item $manager->B<wm_about_FVWM>()

=cut

=item $manager->B<wm_about_AFTERSTEP>()

=cut

=item $manager->B<wm_about_METACITY>()

=cut

=item $manager->B<wm_about_WMX>()

=cut

=back

=back

=head2 WIndow Manager Window List

=over

=item $manager->B<wm_winlist>()

=cut

=over

=item $manager->B<wm_winlist_FLUXBOX>()

=cut

=item $manager->B<wm_winlist_BLACKBOX>()

=cut

=item $manager->B<wm_winlist_OPENBOX>()

=cut

=item $manager->B<wm_winlist_ICEWM>()

=cut

=item $manager->B<wm_winlist_PEKWM>()

=cut

=item $manager->B<wm_winlist_JWM>()

=cut

=item $manager->B<wm_winlist_WMAKER>()

=cut

=item $manager->B<wm_winlist_FVWM>()

=cut

=item $manager->B<wm_winlist_AFTERSTEP>()

=cut

=item $manager->B<wm_winlist_METACITY>()

=cut

=item $manager->B<wm_winlist_WMX>()

=cut

=back

=back

=head2 WIndow Manager Reload

=over

=item $manager->B<wm_reload>()

=cut

=over

=item $manager->B<wm_reload_FLUXBOX>()

=cut

=item $manager->B<wm_reload_BLACKBOX>()

=cut

=item $manager->B<wm_reload_OPENBOX>()

=cut

=item $manager->B<wm_reload_ICEWM>()

=cut

=item $manager->B<wm_reload_PEKWM>()

=cut

=item $manager->B<wm_reload_JWM>()

=cut

=item $manager->B<wm_reload_WMAKER>()

=cut

=item $manager->B<wm_reload_FVWM>()

=cut

=item $manager->B<wm_reload_AFTERSTEP>()

=cut

=item $manager->B<wm_reload_METACITY>()

=cut

=item $manager->B<wm_reload_WMX>()

=cut

=back

=back

=head2 WIndow Manager Reconfiguration

=over

=item $manager->B<wm_reconfig>()

=cut

=over

=item $manager->B<wm_reconfig_FLUXBOX>()

=cut

=item $manager->B<wm_reconfig_BLACKBOX>()

=cut

=item $manager->B<wm_reconfig_OPENBOX>()

=cut

=item $manager->B<wm_reconfig_ICEWM>()

=cut

=item $manager->B<wm_reconfig_PEKWM>()

=cut

=item $manager->B<wm_reconfig_JWM>()

=cut

=item $manager->B<wm_reconfig_WMAKER>()

=cut

=item $manager->B<wm_reconfig_FVWM>()

=cut

=item $manager->B<wm_reconfig_AFTERSTEP>()

=cut

=item $manager->B<wm_reconfig_METACITY>()

=cut

=item $manager->B<wm_reconfig_WMX>()

=cut

=back

=back

=head2 WIndow Manager Restart

=over

=item $manager->B<wm_restart>()

=cut

=over

=item $manager->B<wm_restart_FLUXBOX>()

=cut

=item $manager->B<wm_restart_BLACKBOX>()

=cut

=item $manager->B<wm_restart_OPENBOX>()

=cut

=item $manager->B<wm_restart_ICEWM>()

=cut

=item $manager->B<wm_restart_PEKWM>()

=cut

=item $manager->B<wm_restart_JWM>()

=cut

=item $manager->B<wm_restart_WMAKER>()

=cut

=item $manager->B<wm_restart_FVWM>()

=cut

=item $manager->B<wm_restart_AFTERSTEP>()

=cut

=item $manager->B<wm_restart_METACITY>()

=cut

=item $manager->B<wm_restart_WMX>()

=cut

=back

=back

=head2 WIndow Manager Exit

=over

=item $manager->B<wm_exit>()

=cut

=over

=item $manager->B<wm_exit_FLUXBOX>()

=cut

=item $manager->B<wm_exit_BLACKBOX>()

=cut

=item $manager->B<wm_exit_OPENBOX>()

=cut

=item $manager->B<wm_exit_ICEWM>()

=cut

=item $manager->B<wm_exit_PEKWM>()

=cut

=item $manager->B<wm_exit_JWM>()

=cut

=item $manager->B<wm_exit_WMAKER>()

=cut

=item $manager->B<wm_exit_FVWM>()

=cut

=item $manager->B<wm_exit_AFTERSTEP>()

=cut

=item $manager->B<wm_exit_METACITY>()

=cut

=item $manager->B<wm_exit_WMX>()

=cut

=back

=back

=head2 WIndow Manager Style

=over

=item $manager->B<wm_setstyle>()

=cut

=over

=item $manager->B<wm_setstyle_FLUXBOX>()

=cut

=item $manager->B<wm_setstyle_BLACKBOX>()

=cut

=item $manager->B<wm_setstyle_OPENBOX>()

=cut

=item $manager->B<wm_setstyle_ICEWM>()

=cut

=item $manager->B<wm_setstyle_PEKWM>()

=cut

=item $manager->B<wm_setstyle_JWM>()

=cut

=item $manager->B<wm_setstyle_WMAKER>()

=cut

=item $manager->B<wm_setstyle_FVWM>()

=cut

=item $manager->B<wm_setstyle_AFTERSTEP>()

=cut

=item $manager->B<wm_setstyle_METACITY>()

=cut

=item $manager->B<wm_setstyle_WMX>()

=cut

=back

=back

=head2 General support methods

=over

=item $manager->B<get_BLACKBOX_PID>() => $pid or undef

=cut

sub get_BLACKBOX_PID {
    return shift->getWMRootPropertyInt('_BLACKBOX_PID');
}

=item $manager->B<event_handler_PropertyNotify_BLACKBOX_PID>(I<$e>,I<$X>,I<$v>)

=cut

sub event_handler_PropertyNotify_BLACKBOX_PID {
    my $self = shift;
    my ($e,$X,$v) = @_;
    return unless $e->{window} == $X->root;
    $self->get_BLACKBOX_PID;
}

=item $manager->B<get_OPENBOX_PID>() => $pid or undef

=cut

sub get_OPENBOX_PID {
    return shift->getWMRootPropertyInt('_OPENBOX_PID');
}

=item $manager->B<event_handler_PropertyNotify_OPENBOX_PID>(I<$e>,I<$X>,I<$v>)

=cut

sub event_handler_PropertyNotify_OPENBOX_PID {
    my $self = shift;
    my ($e,$X,$v) = @_;
    return unless $e->{window} == $X->root;
    $self->get_OPENBOX_PID;
}

=item $manager->B<get_XDE_WM_PID>() => $pid

=cut

=item $manager->B<set_XDE_WM_PID>($pid)

=cut

=item $manager->B<event_handler_PropertyNotify_XDE_WM_PID>(I<$e>,I<$X>,I<$v>)

=cut

=item $manager->B<get_XDE_SESSION>() => $string

=cut

=item $manager->B<set_XDE_SESSION>($string)

=cut

=item $manager->B<event_handler_PropertyNotify_XDE_SESSION>(I<$e>,I<$X>,I<$v>)

=cut

=item $manager->B<get_XDE_CONFIG_DIR>() => $string

=cut

=item $manager->B<set_XDE_CONFIG_DIR>($string)

=cut

=item $manager->B<event_handler_PropertyNotify_XDE_CONFIG_DIR>(I<$e>,I<$X>,I<$v>)

=cut

=item $manager->B<get_XDE_CONFIG_FILE>() => $string

=cut

=item $manager->B<set_XDE_CONFIG_FILE>($string)

=cut

=item $manager->B<event_handler_PropertyNotify_XDE_CONFIG_FILE>(I<$e>,I<$X>,I<$v>)

=cut

=item $manager->B<get_XDE_MENU_DIR>() => $string

=cut

=item $manager->B<set_XDE_MENU_DIR>($string)

=cut

=item $manager->B<event_handler_PropertyNotify_XDE_MENU_DIR>(I<$e>,I<$X>,I<$v>)

=cut

=item $manager->B<get_XDE_MENU_FILE>() => $string

=cut

=item $manager->B<set_XDE_MENU_FILE>($string)

=cut

=item $manager->B<event_handler_PropertyNotify_XDE_MENU_FILE>(I<$e>,I<$X>,I<$v>)

=cut

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::X11(3pm)>,
L<XDE::EWMH(3pm)>,
L<XDE::WMH(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
