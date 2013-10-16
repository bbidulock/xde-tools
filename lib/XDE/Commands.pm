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

=item C<ICEWM_ACTION_SHUTDOWN> => 5

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

=item L<pekwm(1)>

=item L<jwm(1)>

=item L<fvwm(1)>

=item L<wmaker(1)>

=item L<metacity(1)>

=item L<afterstep(1)>

=item L<wmx(1)>

=back

=head1 METHODS

This module provides the following methods:

=over

=cut

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
