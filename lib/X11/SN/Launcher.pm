package X11::SN::Launcher;
use base qw(X11::SN);
use X11::SN::Sequence;
use strict;
use warnings;

=head1 NAME

X11::SN::Launcher - module supporting startup notification launching

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides methods supporting X11 startup notification that
are used by a I<launcher> (the program launching the X11 client
program).  It provides implementation of launcher-specific methods for
use in startup notification launchers.  The module provides hooks for
event loops; however, it does not provide an event loop of its own.  See
L</EVENT LOOP>.

Although this module mimics the functions of the libsn library, it does
not depend on the library and uses L<X11::Protocol(3pm)> to perform its
functions.

=head1 METHODS

The module provides the following methods:

=over

=item $launcher = X11::SN::Launcher->B<new>(I<@args>)

Creates a new startup notification launcher.

Creates a new startup notification launcher.  The launcher uses an
L<X11::Protocol::Connection(3pm)> connection, I<$X>, to communicate with
the X display.  When I<$X> is C<undef>, the launcher will create a new
L<X11::Protocol(3pm)> connection using the B<DISPLAY> environment
variable to communicate with the X display.  When an
L<X11::Protocol(3pm)> connection is supplied, the launcher will
initialize it in a way that attempts to share the connection with other
perl modules.

The method performs the following:

=over

=item

Selects for input C<ProprertyNotify> events from the root window, if
they have not already been selected.

=item

Creates a window for use as a unique identifier for sending startup
notification protocol C<ClientMessage>.

=item

Installs an event handler on the L<X11::Protocol(3pm)> connection that
intercepts C<_NET_STARTUP_INFO_BEGIN> and C<_NET_STARTUP_INFO> client
messages and directs them to the internal ClientMessage() event handler.

=back

=item $launcher->B<X>() => I<$X>

Returns the L<X11::Protocol(3pm)> connection associated with the
launcher.  This method is primarily for the case where the new() method
allocates its own L<X11::Protocol(3pm)> connection, and acces to the
connection is necessary for setting up event loops.  (See L</EVENT
LOOPS>.)

=item $launcher->B<ClientMessage>(I<$event>,I<$X>)

This method needs to be invoked by an L<X11::Protocol(3pm)> event
handler whenever a C<ClientMessage> of type C<_NET_STARTUP_INFO_BEGIN>
or C<_NET_STARTUP_INFO> is received on the connection.

=item $launcher->B<new_sequence>(I<%params>)

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::SN(3pm)>,
L<X11::Protocol(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
