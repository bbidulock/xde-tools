package XDE::Commands;
use base qw(XDE::Actions);
use strict;
use warnings;

=head1 NAME

XDE::Commands -- provides methods for performing actions on window managers

=head1 DESCRIPTION

Provides a module with methods that can be used to control a window
manager.  This module is meant to be used as a base for other modules.
It supports actions performable using signals to the window manager PID
or by sending window manager specific client messages to the root
window.

Most window managers will reload or restart when sent a C<SIGHUP>
signal.  Most will exit gracefully when sent a C<SIGTERM> or C<SIGINT>
signal.  Some respond in various ways to C<SIGUSR1> or C<SIGUSR2>
signals.  Many window managers, however, do not set the PID of the
window manager against any X-display property and therefore cannot be
signalled by a program that did not start the window manager as a child
process.

Some window managers provide client message definitions that allow a
C<ClientMessage> to be send to the root window to control the window
manager.  These messages can normally perform reconfiguration, restart
and exit.  Some window managers provide more advanced or finer controls.
Some require a configuration setting to permit the actions to be
performed in response to client messages.

=head2 WINDOW MANAGERS

The behaviour of various L<XDE(3pm)> supported window managers are
described below:

=over

=item L<fluxbox(1)>

L<fluxbox(1)> provides for very fine control using properties instead of
client messages; however, the fluxbox-remote features must be enabled by
configuration and has security considerations.  L<fluxbox(1)> does,
however, provide good control by sending signals and sets its PID in the
C<_BLACKBOX_PID(CARDINAL)> property on the root window.

The following signals are acted upon:

=over

=item C<SIGTERM> and C<SIGINT>

The window manager gracefully exits.

=item C<SIGHUP>

The window manager restarts.  This reloads the entire configuration and
can be used to affect any change to style or menu.

=item C<SIGUSR1>

The configuration file is reloaded; however, the existing style file is
not overwritten so this command cannot be used to change the style.

=item C<SIGUSR2>

The configuration file is reloaded, including the style file; so, this
command can be used to change the style.

=back

=item L<blackbox(1)>

L<blackbox(1)> does not provide any client message definitions and can
only be controlled using signals.  Current versions of L<blackbox(1)>
set the PID of the window manager against the C<_NET_WM_PID(CARDINAL)>
property on the C<_NET_SUPPORTING_WM_CHECK(WINDOW)> check window.  Older
versions of L<blackbox(1)> must obtain the PID from the child process
used by a session manager to launch the window manager.

The following signals are acted upon:

=over

=item C<SIGTERM> or C<SIGINT>

The window manager gracefully exits.

=item C<SIGHUP>

The window manager restarts.

=item C<SIGUSR1>

The window manager reconfigures itself from configuration files.

=item C<SIGUSR2>

The window manager reloads the menu file.

=back

=item L<openbox(1)>

L<openbox(1)> provides for client message control; however, it does
require the feature to be enabled by configuration.  L<openbox(1)> does,
however, provide control by sending signals and sets its PID in the
C<_OPENBOX_PID(CARDINAL)> property on the root window.

The following client messages are defined:

=over

=item C<_OB_CONTROL>

This client message defines one long argument which can have one of the
following values:

=over

=item C<OB_CONTROL_RECONFIGURE> => 1

The window manager reconfigures itself from configuration files.  This
is sufficient for altering styles and is used by the L<obconf(1)>
utility.

=item C<OB_CONTROL_RESTART> => 2

The window manager restarts.

=item C<OB_CONTROL_EXIT> => 3

The window manager exits gracefully.

=back

=back

The following signals are acted upon:

=over

=item C<SIGTERM> or C<SIGINT>

The window manager exits gracefully with a zero exit status.

=item C<SIGHUP>

The window manager exits gracefully with a non-zero exit status.

=item C<SIGUSR1>

The window manager restarts.

=item C<SIGUSR2>

The window manager reconfigures itself from configuration files.  This
is sufficient for altering styles.

=back

=item L<icewm(1)>

L<icewm(1)> provides for client message control; however, this is broken
(and ignored) by some versions of L<icewm(1)>.  It is fixed in current
versions.  L<icewm(1)> does provide for control by sending signals and
sets its PID in the C<_NET_WM_PID(CARDINAL)> property on the check
window.

The following client messages are defined:

=over

=item C<_ICEWM_ACTION>

This client message defines one long argument which can have one of the
following values:

=over

=item C<ICEWM_ACTION_NOP> => 0

The window manager performs no action: this is a no-op.

=item C<ICEWM_ACTION_PING> => 1

Was used at one time to perform a ping protoocl with the window manager;
however, it is currently ignored.

=item C<ICEWM_ACTION_LOGOUT> => 2

Initiates a logout from the window manager.

=item C<ICEWM_ACTION_CANCEL_LOGOUT> => 3

Cancels a pending logout from the window manager.

=item C<ICEWM_ACTION_REBOOT> => 4

Logs out of the window manager and then the window manager executes the
C<rebootCommand> defined by configuration (normally rebooting the
computer).

=item C<ICEWM_ACTION_SHUTDOWN> => 5

Logs out of the window manager and then the window manager executes the
C<shutdownCommand> defined by configuration (normally shutting down the
computer).

=item C<ICEWM_ACTION_ABOUT> => 6

Causes the window manager to display its I<about> window.

=item C<ICEWM_ACTION_WINDOWLIST> => 7

Causes the window manager to display its I<window list> window.

=item C<ICEWM_ACTION_RESTARTWM> => 8

Causes the window manager to restart.  This is sufficient for resetting
styles and other configuration file properties.

=back

=back

The following signals are acted upon:

=over

=item C<SIGTERM> or C<SIGINT>

Causes the window manager to exit.  This exits the window manager
without launching a verification prompt.

=item C<SIGQUIT>

Causes the window manager to intiate a logout.  This is the same as the
response to a C<ICEWM_ACTION_LOGOUT> client message.

=item C<SIGHUP>

Causes the window manager to restart.  This is the same as the response
to a C<ICEWM_ACTION_RESTARTWM> client message.

=back

=item L<pekwm(1)>

L<pekwm(1)> does not provide any client message definitions and can only
be controlled by using signals.  Current versions of L<pekwm(1)> set the
PID of the window manager in the C<_NET_WM_PID(CARDINAL)> property on
the root window (instead of the check window).

The following signals are acted upon:

=over

=item C<SIGTERM> or C<SIGINT>

The window manager exits gracefully.

=item C<SIGHUP>

The window manager reloads its configuration.

=back

=item L<jwm(1)>

L<jwm(1)> provides for client message control.  It can also be
controlled by signals and sets its process id (PID) in the
C<_NET_WM_PID(CARDINAL)> on the check window in current versions of the
window manager.  Older versions of L<jwm(1)> must obtain the PID from
the child process used by a session manager to launch the window
manager.

The following client messages are defined:

=over

=item C<_JWM_RELOAD>

Causes the window manager to reload the root menu.

=item C<_JWM_RESTART>

Causes the window manager to restart, reloading all configuration from
configuration files.  This is sufficient for resetting styles.

=item C<_JWM_EXIT>

Causes the window manager to exit.

=back

The following signals are acted upon:

=over

=item C<SIGTERM>, C<SIGINT> or C<SIGHUP>

The window manager exits gracefully.

=back

=item L<fvwm(1)>

L<fvwm(1)> does not set its process identifier (PID) on any window
property.  The PID, therefore, must be obtained from the child process
used by a session manager to launch the window manager.

The following signals are acted upon:

=over

=item C<SIGTERM>, C<SIGINT>, C<SIGHUP>, C<SIGQUIT>

Causes the window manager to exit gracefully.

=item C<SIGUSR1>

Causes the window manager to restart.

=back

=item L<wmaker(1)>

L<wmaker(1)> provides for client message control.  It also provides for
sending signals to the window manager PID; however, L<wmaker(1)> does
not set its process identifier (PID) on any window property.

The following client messages are defined:

=over

=item C<_WINDOWMAKER_COMMAND>

This client message defines one character string argument as follows:

=over

=item C<Reconfigure>

The window manager reconfigures itself from configuration files,
including reconfiguration of themes.

=back

No other string argument is acted upon.

=back

The following signals are acted upon:

=over

=item C<SIGTERM>, C<SIGINT>, C<SIGHUP>

Causes the window manager to exit.

=item C<SIGUSR2>

Causes the window manager to reread defaults.

=item C<SIGUSR1>

Causes the window manager to restart.

=back

=item L<metacity(1)>

L<metacity(1)> does not set its process identifier (PID) on any window
property.

=item L<afterstep(1)>

L<afterstep(1)> does not set its process identifier (PID) on any window
property.

=item L<wmx(1)>

Patched version of L<wmx(1)> sets its process identifier (PID) in the
C<_NET_WM_PID(CARDINAL)> property on the check window.  Older versions
of L<wmx(1)> does not set its process identifier (PID) on any window
property.  For older version, the PID must be obtained from the child
process used by a session manager to launch the window manager.

The following signals are acted upon:

=over

=item C<SIGTERM> or C<SIGINT>

Causes the window manager to exit.

=item C<SIGHUP>

Causes the window manager to restart.

=back

=back

=head1 METHODS

This module provides the following methods:

=over

=item $cmds->B<setup>

Called to set up this module.  Setting up the module consists of calling
the setup proceedure for the XDE::Actions module and establishing the
PID of the window manager where possible.

=cut

sub setup {
    my $self = shift;
    $self->XDE::Actions::setup();
    $self->get_wm_pid();
}

=back

=head2 Obtaining the window manager PID

Some window managers set the PID of the window manager against a root
or check window property.  This permits support clients to control the
window manager by sending signals to the process.   One difficulty with
sending signals to a process is that they should be sent by a program
running on the same host as the window manager, otherwise, they will go
astray.

Some window managers permit control of the window manager using client
messages sent to the root window instead of or in addition to signals.
This is preferrable because the client controlling the window manager
need not be running on the same host as the window manager.

Some window managers do not provides a mechanism for discovering the PID
of the window manager; and some do not provide client messages either.
L<XDE(3pm)> provides support for these window managers by performing
several actions:

=over

=item 1.

Before launching the window manager, the session manager sets the
C<_XDE_WM_COMMAND(STRING)> property on the root window to the command
and arguments used to launch the window manager.  It also forks a child
process for the window manager and sets the C<_XDE_WM_PID(CARDINAL)>
property on the root window to the PID of the child process.

=item 2.

When the session manager starts a window manager, it awaits the
appearance of the check window and sets the C<_NET_WM_PID(CARDINAL)>
property on the check window to the PID of the window manager it it was
not already set by the window manager.  It also sets the
C<WM_COMMAND(STRING)> property on the check window to the command used
to launch the window manager unless it too has already been set.

=item 3.

The session manager listens for changes in the window manager.  When it
can determine the PID or command of for the window manager from some
other means, it sets the C<_XDE_WM_PID> and C<_NET_WM_PID> properties
and C<_XDE_WM_COMMAND> and C<WM_COMMAND> properties on the root and
check windows appropriately.

=item 4.

The session manager listens for client messages sent to the root window
with C<StructureNotify> or C<SubstructureNotify> event masks, and acts
on them as follows:

=over

=item C<_XDE_RELOAD>

The session manager will reload the root menu (if required and
possible).  The session manager may perform a C<_XDE_RECONFIG> operation
to effect root menu loading.

=item C<_XDE_RECONFIG>

The session manager will reload the configuration files (if required and
possible).  This will always be sufficient for updating the style or
theme of the window manager.  The session manager may perform a
C<_XDE_RESTART> operation to effect reconfigureation.

=item C<_XDE_RESTART>

The session manager will restart the window manager (if required and
possible).  This will result in the graceful exit and restart of the
window manager.  The session manager may perform a C<_XDE_EXIT>
operation followed by an C<_XDE_START> operation to effect a restart.

=item C<_XDE_EXIT>

The session manager will exit the window manager (if required and
possible).  This will result in the graceful exit of the window manager.
The session manager may send a C<SIGTERM> signal to the window manager
process identifier to effect this action.

=item C<_XDE_START>

The session maanger will start the window manager using the command
specified by the F<*.desktop> file, where the F<*> is specified as a
single string argument to the client message.  The session manager will
use the XDG environment to locate the F<*.desktop> file and perform the
C<Exec> or C<X-XDE-Exec> actions associated with the file.

=back

=back

The following methods are used to obtain the window manager PID.  Only
the get_wm_pid() method should be called directly.  The other methods
are invoked internally.

=over

=item $cmds->B<get_wm_pid>() => $pid

Obtains the PID of the window manager and stores it in
C<$self-E<gt>{wmpid}>, where possible.

=cut

sub get_wm_pid {
    my $self = shift;
    my $wmname = $self->{wmname};
    $wmname = 'unknown' unless $wmname;
    if (my $sub = $self->can("get_wm_pid_\U$wmname\E")) {
	return &$sub($self);
    }
    return $self->{wmpid};
}

=over

=item $cmds->B<get_wm_pid_FLUXBOX>() => $pid

Obtain the PID of the L<fluxbox(1)> window manager.  L<fluxbox(1)> sets
the window manager PID in the C<_BLACKBOX_PID(CARDINAL)> property on the
root window.
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_FLUXBOX {
    my $self = shift;
    my ($pid,$check);
    if ($check = $self->{_NET_SUPPORTING_WM_CHECK}) {
	$pid = $self->get_XDE_WM_PID($check) unless $pid;
    }
    $pid = $self->get_root_XDE_WM_PID unless $pid;
    $pid = $self->get_BLACKBOX_PID unless $pid;
    $self->{wmpid} = $pid;
    return $pid;
}

=over

=item $cmds->B<get_BLACKBOX_PID>() => $pid

Update the PID for L<fluxbox(1)>.

=cut

sub get_BLACKBOX_PID {
    my $self = shift;
    $self->{wmpid} = $self->getWMRootPropertyInt('_BLACKBOX_PID');
    return $self->{wmpid};
}

=item $cmds->B<event_handler_PropertyNotify_BLACKBOX_PID>(I<$e>,I<$X>,I<$v>)

Handle a property change to the L<fluxbox(1)> PID.

=cut

sub event_handler_PropertyNotify_BLACKBOX_PID {
    my($self,$e,$X,$v) = @_;
    $self->get_BLACKBOX_PID if $e->{window} == $X->root;
}

=back

=item $cmds->B<get_wm_pid_BLACKBOX>() => $pid

Obtain the PID of the L<blackbox(1)> window manager.  L<blackbox(1)>
sets the window manager PID in the C<_NET_WM_PID(CARDINAL)> property on
the check window.  This PID is retreived by XDE::Actions::setup().
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_BLACKBOX {
    my $self = shift;
    my ($pid,$check);
    if ($check = $self->{_NET_SUPPORTING_WM_CHECK}) {
	$pid = $self->get_NET_WM_PID($check) unless $pid;
	$pid = $self->get_XDE_WM_PID($check) unless $pid;
    }
    $pid = $self->get_root_XDE_WM_PID unless $pid;
    $self->{wmpid} = $pid;
    return $pid;
}

=item $cmds->B<get_wm_pid_OPENBOX>() => $pid

Obtain the PID of the L<openbox(1)> window manager.  L<openbox(1)> sets
the window manager PID in the C<_OPENBOX_PID(CARDINAL)> property on the
root window.
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_OPENBOX {
    return shift->get_OPENBOX_PID;
}

=over

=item $cmds->B<get_OPENBOX_PID>() => $pid

Update the PID for L<openbox(1)>.

=cut

sub get_OPENBOX_PID {
    my $self = shift;
    $self->{wmpid} = $self->getWMRootPropertyInt('_OPENBOX_PID');
    return $self->{wmpid};
}

=item $cmds->B<event_handler_PropertyNotify_OPENBOX_PID>(I<$e>,I<$X>,I<$v>)

Handle a property change to the L<openbox(1)> PID.

=cut

sub event_handler_PropertyNotify_OPENBOX_PID {
    my($self,$e,$X,$v) = @_;
    $self->get_OPENBOX_PID if $e->{window} == $X->root;
}

=back

=item $cmds->B<get_wm_pid_ICEWM>() => $pid

Obtain the PID of the L<icewm(1)> window manager.  L<icewm(1)> sets the
window manager PID in the C<_NET_WM_PID(CARDINAL)> property on the check
window.  This PID is retrieved by XDE::Actions::setup().
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_ICEWM {
    my $self = shift;
    my ($pid,$check);
    if ($check = $self->{_NET_SUPPORTING_WM_CHECK}) {
	$pid = $self->get_NET_WM_PID($check) unless $pid;
	$pid = $self->get_XDE_WM_PID($check) unless $pid;
    }
    $pid = $self->get_root_XDE_WM_PID unless $pid;
    $self->{wmpid} = $pid;
    return $pid;
}

=item $cmds->B<get_wm_pid_PEKWM>() => $pid

Obtain the PID of the L<pekwm(1)> window manager.  L<pekwm(1)> sets the
window manager PID in the C<_NET_WM_PID(CARDINAL)> property on the root
window.
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_PEKWM {
    my $self = shift;
    my ($pid,$check);
    if ($check = $self->{_NET_SUPPORTING_WM_CHECK}) {
	$pid = $self->get_XDE_WM_PID($check) unless $pid;
    }
    $pid = $self->get_root_NET_WM_PID unless $pid;
    $pid = $self->get_root_XDE_WM_PID unless $pid;
    $self->{wmpid} = $pid;
    return $pid;
}

=over

=item $cmds->B<get_root_NET_WM_PID>() => $pid

Update the PID for L<pekwm(1)>.

=cut

sub get_root_NET_WM_PID {
    my $self = shift;
    $self->{wmpid} = $self->getWMRootPropertyInt('_NET_WM_PID');
    return $self->{wmpid};
}

=item $cmds->B<event_handler_PropertyNotify_NET_WM_PID>(I<$e>,I<$X>,I<$v>)

Handle a property change to the L<pekwm(1)> PID.

=cut

sub event_handler_PropertyNotify_NET_WM_PID {
    my($self,$e,$X,$v) = @_;
    if ($e->{window} == $X->root) {
	$self->get_root_NET_WM_PID;
    } else {
	$self->get_NET_WM_PID($e->{window});
    }
}

=back

=item $cmds->B<get_wm_pid_JWM>() => $pid

Obtain the PID of the L<jwm(1)> window manager.  Recent versions of
L<jwm(1)> set the window manager PID in the C<_NET_WM_PID(CARDINAL)>
property on the check window.  This PID is retrieved by
XDE::Actions::setup().
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_JWM {
    my $self = shift;
    my ($pid,$check);
    if ($check = $self->{_NET_SUPPORTING_WM_CHECK}) {
	$pid = $self->get_NET_WM_PID($check) unless $pid;
	$pid = $self->get_XDE_WM_PID($check) unless $pid;
    }
    $pid = $self->get_root_XDE_WM_PID($check) unless $pid;
    $self->{wmpid} = $pid;
    return $pid;
}

=item $cmds->B<get_wm_pid_FVWM>() => $pid

Obtain the PID of the L<fvwm(1)> window manager.  L<fvwm(1)> does not
set its PID anywhere, so an undefined value or previous value is
returned.
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_FVWM {
    return shift->get_wm_pid_XDE;
}

=item $cmds->B<get_wm_pid_WMAKER>() => $pid

Obtain the PID of the L<wmaker(1)> window manager.  L<wmaker(1)> does
not set its PID anywhere, so an undefined value or previous value is
returned.
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_WMAKER {
    return shift->get_wm_pid_XDE;
}

=item $cmds->B<get_wm_pid_METACITY>() => $pid

Obtain the PID of the L<metacity(1)> window manager.  L<metacity(1)>
does not set its PID anywhere, so an undefined value or previous value
is returned.
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_METACITY {
    return shift->get_wm_pid_XDE;
}

=item $cmds->B<get_wm_pid_AFTERSTEP>() => $pid

Obtain the PID of the L<afterstep(1)> window manager.  L<afterstep(1)>
does not set its PID anywhere, so an undefined value or previous value
is returned.
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_AFTERSTEP {
    return shift->get_wm_pid_XDE;
}

=item $cmds->B<get_wm_pid_WMX>() => $pid

Obtain the PID of the L<wmx(1)> window manager.  L<wmx(1)> does not set
its PID anywhere, so an undefined value or previous value is returned.
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_WMX {
    return shift->get_wm_pid_XDE;
}

=item $cmds->B<get_wm_pid_UNKNOWN>() => $pid

Obtain the PID of an unknown window manager.  We cannot rely on an
unknown window manager to set the PID anywhere, so an undefined or
previous value is returned.
An L<XDE(3pm)> session manager established value is used when available.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_UNKNOWN {
    return shift->get_wm_pid_XDE;
}

=item $cmds->B<get_wm_pid_XDE>() => $pid

Get the PID of the window manager using L<XDE(3pm)> session manager
established window properties.
This internal method should not be called directly: call get_wm_pid()
instead.

=cut

sub get_wm_pid_XDE {
    my $self = shift;
    my ($pid,$check);
    if ($check = $self->{_NET_SUPPORTING_WM_CHECK}) {
	$pid = $self->get_XDE_WM_PID($check) unless $pid;
	$pid = $self->get_NET_WM_PID($check) unless $pid;
    }
    $pid = $self->get_root_XDE_WM_PID unless $pid;
    $pid = $self->get_root_NET_WM_PID unless $pid;
    $pid = $self->get_BLACKBOX_PID unless $pid;
    $pid = $self->get_OPENBOX_PID unless $pid;
    $self->{wmpid} = $pid;
    return $pid;
}

=over

=item $cmds->B<get_root_XDE_WM_PID>() => $pid

Get the PID of the window manager using L<XDE(3pm)> session manager
established window properties.

=cut

sub get_root_XDE_WM_PID {
    my $self = shift;
    my $pid = $self->getWMRootPropertyInt('_XDE_WM_PID');
    $self->{wmpid} = $pid if $pid;
    return $pid;
}

=item $cmds->B<get_XDE_WM_PID>() => $pid

Get the PID of the window manager using L<XDE(3pm)> session manager
established window properties.

=cut

sub get_XDE_WM_PID {
    my($self,$window) = @_;
    my $pid = $self->getWMPropertyInt($window, '_XDE_WM_PID');
    $self->{wmpid} = $pid if $pid and $window == $self->{_NET_SUPPORTING_WM_CHECK};
    return $pid;
}

=item $cmds->B<event_handler_PropertyNotify_XDE_WM_PID>(I<$e>,I<$X>,I<$v>)

Handle a property change to the L<XDE(3pm)> session manager established
window manager PID.

=cut

sub event_handler_PropertyNotify_XDE_WM_PID {
    my($self,$e,$X,$v) = @_;
    if ($e->{window} == $X->root) {
	$self->get_root_XDE_WM_PID;
    } else {
	$self->get_XDE_WM_PID($e->{window});
    }
}

=back

=back

=back

=head2 Controlling the window manager with requests

The following methods request that actions be performed on the window
manager.

=over

=item $cmds->B<request_wm_reload>()

Requests that the L<XDE::Session(3pm)> manager cause the window manager
to reload its root menus by sending an C<_XDE_RELOAD> client message to
the root window.
The method will attempt to reload the window manager itself when an
L<XDE::Session(3pm)> manager is not currently running.

=cut

sub request_wm_reload {
    my $self = shift;
    if ($ENV{XDE_SESSION_PID} or $self->get_XDE_SESSION_PID) {
	my $X = $self->{X};
	$X->SendEvent($X->root, 0,
		$X->pack_event_mask(qw(
			StructureNotify
			SubstructureNotify
			SubstructureRedirect)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$X->root,
		    format=>32,
		    type=>$X->atom('_XDE_RELOAD'),
		    data=>pack('LLLLL',0,0,0,0,0),
		));
	$X->flush;
    } else {
	$self->wm_reload;
    }
}

=item $cmds->B<request_wm_reconfig>()

Requests that the L<XDE::Session(3pm)> manager cause the window manager
to reconfigure itself from configuration files by sending an
C<_XDE_RECONFIG> client message to the root window.
The method will attempt to reconfigure the window manager itself when an
L<XDE::Session(3pm)> manager is not currently running.

=cut

sub request_wm_reconfig {
    my $self = shift;
    if ($ENV{XDE_SESSION_PID} or $self->get_XDE_SESSION_PID) {
	my $X = $self->{X};
	$X->SendEvent($X->root, 0,
		$X->pack_event_mask(qw(
			StructureNotify
			SubstructureNotify
			SubstructureRedirect)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$X->root,
		    format=>32,
		    type=>$X->atom('_XDE_RECONFIG'),
		    data=>pack('LLLLL',0,0,0,0,0),
		));
	$X->flush;
    } else {
	$self->wm_reconfig;
    }
}

=item $cmds->B<request_wm_restart>()

Requests that the L<XDE::Session(3pm)> manager cause the window manager
to restart itself by sending an C<_XDE_RESTART> client message to the
root window.
The method will attempt to restart the window manager itself when an
L<XDE::Session(3pm)> manager is not currently running.

=cut

sub request_wm_restart {
    my $self = shift;
    if ($ENV{XDE_SESSION_PID} or $self->get_XDE_SESSION_PID) {
	my $X = $self->{X};
	$X->SendEvent($X->root, 0,
		$X->pack_event_mask(qw(
			StructureNotify
			SubstructureNotify
			SubstructureRedirect)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$X->root,
		    format=>32,
		    type=>$X->atom('_XDE_RESTART'),
		    data=>pack('LLLLL',0,0,0,0,0),
		));
	$X->flush;
    } else {
	$self->wm_restart;
    }
}

=item $cmds->B<request_wm_exit>()

Requests that the L<XDE::Session(3pm)> manager cause the window manager
to exit by sending an C<_XDE_EXIT> client message to the root window.
The method will attempt to terminate the window manager itself when an
L<XDE::Session(3pm)> manager is not currently running.

=cut

sub request_wm_exit {
    my $self = shift;
    if ($ENV{XDE_SESSION_PID} or $self->get_XDE_SESSION_PID) {
	my $X = $self->{X};
	$X->SendEvent($X->root, 0,
		$X->pack_event_mask(qw(
			StructureNotify
			SubstructureNotify
			SubstructureRedirect)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$X->root,
		    format=>32,
		    type=>$X->atom('_XDE_EXIT'),
		    data=>pack('LLLLL',0,0,0,0,0),
		));
	$X->flush;
    } else {
	$self->wm_exit;
    }
}

=item $cmds->B<request_wm_start>(I<$wmname>)

Requests that the L<XDE::Session(3pm)> manager cause a new window
manager to start by sending an C<_XDE_START> client message to the root
window.
The method will attempt to start the window manager itself when an
L<XDE::Session(3pm)> manager is not currently running.

=cut

sub request_wm_start {
    my($self,$wmname) = @_;
    if ($ENV{XDE_SESSION_PID} or $self->get_XDE_SESSION_PID) {
	my $X = $self->{X};
	$X->SendEvent($X->root, 0,
		$X->pack_event_mask(qw(
			StructureNotify
			SubstructureNotify
			SubstructureRedirect)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$X->root,
		    format=>32,
		    type=>$X->atom('_XDE_START'),
		    data=>substr(0,20,pack('Z',$wmname).pack('LLLLL',0,0,0,0,0)),
		));
	$X->flush;
    } else {
	$self->wm_start($wmname);
    }
}

=back

=head2 Controlling the window manager directly

The following methods perform actions on the window manager.

=over

=item $cmds->B<wm_reload>()

Request that the window manager reload the root menu (where required and
possible).

=over

=item $cmds->B<wm_reload_FLUXBOX>()

Ask the L<fluxbox(1)> window manager to reload its root menu.

=item $cmds->B<wm_reload_BLACKBOX>()

Ask the L<blackbox(1)> window manager to reload its root menu.

=item $cmds->B<wm_reload_OPENBOX>()

Ask the L<openbox(1)> window manager to reload its root menu.

=item $cmds->B<wm_reload_ICEWM>()

Ask the L<icewm(1)> window manager to reload its root menu.

=item $cmds->B<wm_reload_PEKWM>()

Ask the L<pekwm(1)> window manager to reload its root menu.

=item $cmds->B<wm_reload_JWM>()

Ask the L<jwm(1)> window manager to reload its root menu.

=item $cmds->B<wm_reload_FVWM>()

Ask the L<fvwm(1)> window manager to reload its root menu.

=item $cmds->B<wm_reload_WMAKER>()

Ask the L<wmaker(1)> window manager to reload its root menu.

=item $cmds->B<wm_reload_METACITY>()

Ask the L<metacity(1)> window manager to reload its root menu.

=item $cmds->B<wm_reload_AFTERSTEP>()

Ask the L<afterstep(1)> window manager to reload its root menu.

=item $cmds->B<wm_reload_WMX>()

Ask the L<wmx(1)> window manager to reload its root menu.

=back

=cut

=item $cmds->B<wm_reconfig>()

Request that the window manager reload its configuration files (where
required and possible).

=over

=item $cmds->B<wm_reconfig_FLUXBOX>()

Ask the L<fluxbox(1)> window manager to reload its configuration from
configuration files.

=item $cmds->B<wm_reconfig_BLACKBOX>()

Ask the L<blackbox(1)> window manager to reload its configuration from
configuration files.

=item $cmds->B<wm_reconfig_OPENBOX>()

Ask the L<openbox(1)> window manager to reload its configuration from
configuration files.

=item $cmds->B<wm_reconfig_ICEWM>()

Ask the L<icewm(1)> window manager to reload its configuration from
configuration files.

=item $cmds->B<wm_reconfig_PEKWM>()

Ask the L<pekwm(1)> window manager to reload its configuration from
configuration files.

=item $cmds->B<wm_reconfig_JWM>()

Ask the L<jwm(1)> window manager to reload its configuration from
configuration files.

=item $cmds->B<wm_reconfig_FVWM>()

Ask the L<fvwm(1)> window manager to reload its configuration from
configuration files.

=item $cmds->B<wm_reconfig_WMAKER>()

Ask the L<wmaker(1)> window manager to reload its configuration from
configuration files.

=item $cmds->B<wm_reconfig_METACITY>()

Ask the L<metacity(1)> window manager to reload its configuration from
configuration files.

=item $cmds->B<wm_reconfig_AFTERSTEP>()

Ask the L<afterstep(1)> window manager to reload its configuration from
configuration files.

=item $cmds->B<wm_reconfig_WMX>()

Ask the L<wmx(1)> window manager to reload its configuration from
configuration files.

=back

=cut

=item $cmds->B<wm_restart>()

Request that the window manager restart gracefully (where required and
possible).

=over

=item $cmds->B<wm_restart_FLUXBOX>()

Ask the L<fluxbox(1)> window manager to restart.  The most reliable way
to restart L<fluxbox(1)> is to send a C<SIGHUP> to the window manager
PID.

=cut

sub wm_restart_FLUXBOX {
    my $self = shift;
    if (my $pid = $self->get_wm_pid_FLUXBOX) {
	kill 'HUP', $pid;
    } else {
	warn "Cannot restart fluxbox without a pid!";
    }
}

=item $cmds->B<wm_restart_BLACKBOX>()

Ask the L<blackbox(1)> window manager to restart.  The L<blackbox(1)>
window manager can be restarted by sending a C<SIGHUP> to the window
manager PID.

=cut

sub wm_restart_BLACKBOX {
    my $self = shift;
    if (my $pid = $self->get_wm_pid_BLACKBOX) {
	kill 'HUP', $pid;
    } else {
	warn "Cannot restart blackbox without a pid!";
    }
}

=item $cmds->B<wm_restart_OPENBOX>()

Ask the L<openbox(1)> window manager to restart.  The L<openbox(1)>
window manager can be restarted by sending a C<SIGHUP> to the window
manager PID, or by sending a C<_OB_CONTROL> client message to the root
window with the C<OB_CONTROL_RESTART> argument.
It is preferrable to send the client message, because the window manager
process may be executing on a different host than this program.

=cut

sub wm_restart_OPENBOX {
    my $self = shift;
    if (1) {
	my $X = $self->{X};
	$X->SendEvent($X->root, 0,
		$X->pack_event_mask(qw(
			StructureNotify
			SubstructureNotify
			SubstructureRedirect)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$X->root,
		    format=>32,
		    type=>$X->atom('_OB_CONTROL'),
		    data=>pack('LLLLL',&OB_CONTROL_RESTART,0,0,0,0),
		));
	$X->flush;
    } else {
	if (my $pid = $self->get_wm_pid_OPENBOX) {
	    kill 'HUP', $pid;
	} else {
	    warn "Cannot restart openbox without a pid!";
	}
    }
}

=item $cmds->B<wm_restart_ICEWM>()

Ask the L<icewm(1)> window manager to restart.  The L<icewm(1)> window
manager can be restarted by sending a C<SIGHUP> to the window manager
PID, or by sending a C<_ICEWM_ACTION> client message to the root window
with the C<ICEWM_ACTION_RESTARTWM> argument.
It is prefferable to send the client message, because the window manager
process may be executing on a different host than this program.
However, some versions of L<icewm(1)> have the bug that they ignore
these client messages.

=cut

sub wm_restart_ICEWM {
    my $self = shift;
    if (1) {
	my $X = $self->{X};
	$X->SendEvent($X->root, 0,
		$X->pack_event_mask(qw(
			StructureNotify
			SubstructureNotify
			SubstructureRedirect)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$X->root,
		    format=>32,
		    type=>$X->atom('_ICEWM_ACTION'),
		    data=>pack('LLLLL',&ICEWM_ACTION_RESTARTWM,0,0,0,0),
		));
	$X->flush;
    } else {
	if (my $pid = $self->get_wm_pid_ICEWM) {
	    kill 'HUP', $pid;
	} else {
	    warn "Cannot restart icewm without a pid!";
	}
    }
}

=item $cmds->B<wm_restart_PEKWM>()

Ask the L<pekwm(1)> window manager to restart.  The L<pekwm(1)> window
manager cannot be restarted externally.  It has an internal C<Restart>
command that can be invoked by a key-stroke or button-press; however, it
is not connected to any signal or client message.  The only way to
restart the window manager externally is to cause the window manager to
exit and then execute the command that was used to invoke it in the
first place.  This can likely only be performed by a session manager.

=cut

sub wm_restart_PEKWM {
}

=item $cmds->B<wm_restart_JWM>()

Ask the L<jwm(1)> window manager to restart.  The L<jwm(1)> can be
restarted by sending a C<_JWM_RESTART> client message to the root
window.

=cut

sub wm_restart_JWM {
    my $self = shift;
    my $X = $self->{X};
    $X->SendEvent($X->root, 0,
	    $X->pack_event_mask(qw(
		    StructureNotify
		    SubstructureNotify
		    SubstructureRedirect)),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$X->root,
		format=>32,
		type=>$X->atom('_JWM_RESTART'),
		data=>pack('LLLLL',0,0,0,0,0),
	    ));
    $X->flush;
}

=item $cmds->B<wm_restart_FVWM>()

Ask the L<fvwm(1)> window manager to restart.  The L<fvwm(1)> window
manager can be restarted by sending a C<SIGUSR1> signal to the window
manager PID; however, there is no way to determine the window manager
PID other than from the session manager that launched the window
manager.

=cut

sub wm_restart_FVWM {
    my $self = shift;
    if (my $pid = $self->get_wm_pid_FVWM) {
	kill 'USR1', $pid;
    } else {
	warn "Cannot restart fvwm without a pid!";
    }
}

=item $cmds->B<wm_restart_WMAKER>()

Ask the L<wmaker(1)> window manager to restart.  The L<wmaker(1)> window
manager can be restarted by sending a C<SIGUSR1> signal to the window
manager PID; however, there is no way to determine the window manager
PID other than from the session manager that launched the window
manager.

=cut

sub wm_restart_WMAKER {
    my $self = shift;
    if (my $pid = $self->get_wm_pid_WMAKER) {
	kill 'USR1', $pid;
    } else {
	warn "Cannot restart wmaker without a pid!";
    }
}

=item $cmds->B<wm_restart_METACITY>()

Ask the L<metacity(1)> window manager to restart.

=cut

=item $cmds->B<wm_restart_AFTERSTEP>()

Ask the L<afterstep(1)> window manager to restart.

=cut

=item $cmds->B<wm_restart_WMX>()

Ask the L<wmx(1)> window manager to restart.

=cut

=item $cmds->B<wm_restart_UNKNOWN>()

Ask an unknown window manager to restart.

=cut

=back

=cut

=item $cmds->B<wm_exit>()

Request that the window manager exit gracefully (where required and
possible).

=over

=item $cmds->B<wm_exit_FLUXBOX>()

Ask the L<fluxbox(1)> window manager to exit gracefully.

=item $cmds->B<wm_exit_BLACKBOX>()

Ask the L<blackbox(1)> window manager to exit gracefully.

=item $cmds->B<wm_exit_OPENBOX>()

Ask the L<openbox(1)> window manager to exit gracefully.

=item $cmds->B<wm_exit_ICEWM>()

Ask the L<icewm(1)> window manager to exit gracefully.

=item $cmds->B<wm_exit_PEKWM>()

Ask the L<pekwm(1)> window manager to exit gracefully.

=item $cmds->B<wm_exit_JWM>()

Ask the L<jwm(1)> window manager to exit gracefully.

=item $cmds->B<wm_exit_FVWM>()

Ask the L<fvwm(1)> window manager to exit gracefully.

=item $cmds->B<wm_exit_WMAKER>()

Ask the L<wmaker(1)> window manager to exit gracefully.

=item $cmds->B<wm_exit_METACITY>()

Ask the L<metacity(1)> window manager to exit gracefully.

=item $cmds->B<wm_exit_AFTERSTEP>()

Ask the L<afterstep(1)> window manager to exit gracefully.

=item $cmds->B<wm_exit_WMX>()

Ask the L<wmx(1)> window manager to exit gracefully.

=item $cmds->B<wm_exit_UNKNOWN>()

Ask an unknown window manager to exit gracefully.  There are several
techniques for asking an unknown window manager to exit:

=over

=item 1.

Send a C<SIGTERM> to the PID of the window manager if the PID is known.

=item 2.

Take ownership of the C<WM_S%d> selection for each screen of the
display.  ICCCM compliant window managers should exit when this happens.

=back

=back

=back

=head2 Command event handlers

=over

=item $cmds->B<event_handler_ClientMessage_XDE_RELOAD>(I<$e>,I<$X>,I<$v>)

Handle an C<_XDE_RELOAD> client message.  This message is sent when a
client wants the window manager to reload its menus.
Only the session manager should respond to these client messages.

=cut

sub event_handler_ClientMessage_XDE_RELOAD {
    my($self,$e,$X,$v) = @_;
     #$self->wm_reload if $e->{window} == $X->root;
}

=item $cmds->B<event_handler_ClientMessage_XDE_RECONFIG>(I<$e>,I<$X>,I<$v>)

Handle an C<_XDE_RECONFIG> client message.  This message is sent when a
client wants the window manager to reload its configuration from
configuration files.
Only the session manager should respond to these client messages.

=cut

sub event_handler_ClientMessage_XDE_RECONFIG {
    my($self,$e,$X,$v) = @_;
     #$self->wm_reconfig if $e->{window} == $X->root;
}

=item $cmds->B<event_handler_ClientMessage_XDE_RESTART>(I<$e>,I<$X>,I<$v>)

Handle an C<_XDE_RESTART> client message.  This message is sent when a
client wants the window manager to restart.
Only the session manager should respond to these client messages.

=cut

sub event_handler_ClientMessage_XDE_RESTART {
    my($self,$e,$X,$v) = @_;
     #$self->wm_restart if $e->{window} == $X->root;
}

=item $cmds->B<event_handler_ClientMessage_XDE_EXIT>(I<$e>,I<$X>,I<$v>)

Handle an C<_XDE_EXIT> client message.  This message is sent when a
client wants the window manager to exit.
Only the session manager should respond to these client messages.

=cut

sub event_handler_ClientMessage_XDE_EXIT {
    my($self,$e,$X,$v) = @_;
     #$self->wm_exit if $e->{window} == $X->root;
}

=item $cmds->B<event_handler_ClientMessage_XDE_START>(I<$e>,I<$X>,I<$v>)

Handle an C<_XDE_START> client message.  This message is sent when a
client wants the window manager to restart on a new window manager.
Only the session manager should respond to these client messages.

=cut

sub event_handler_ClientMessage_XDE_START {
    my($self,$e,$X,$v) = @_;
     #$self->wm_start(unpack('Z',$e->{data})) if $e->{window} == $X->root;
}

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::X11(3pm)>,
L<XDE::Actions(3pm)>,
L<XDE::EWMH(3pm)>,
L<XDE::WMH(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
