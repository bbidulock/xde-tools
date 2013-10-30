package XDE::X11::StartupNotification::Launchee;
use base qw(XDE::X11::StartupNotification::Sequence);
use XDE::X11::StartupNotification;
use POSIX qw(getpid);
use Time::HiRes qw(gettimeofday);
use strict;
use warnings;

=head1 NAME

XDE::X11::StartupNotification::Launchee - startup notification lanchee module

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides methods supporting X11 startup notification that
are used by a I<lanuchee> (the X11 client program being launched).
This module provides a representation of an X11 startup notification
sequence.  Each startup notification sequence is identified by its
startup identifier.

=head1 METHODS

The module provides the following methods:

=over

=item B<new> XDE::X11::StartupNotifiction::Launchee I<$sn>, I<$startup_id> => $ctx

Creates a new launchee startup notification context and assigns it the
startup identifier, C<$startup_id>.  When the startup identifier is not
defined, it will be obtained from the C<DESKTOP_STARTUP_ID> environment
variable.  A valid and initialized L<XDE::X11::StartupNotification(3pm)>
object, I<$sn>, must be provided.

=cut

=item $ctx->B<get_startup_id>() => $startup_id

Return the startup notification identifier, C<$startup_id>, associated
with the launchee.

=cut

sub get_startup_id {
    return shift->{parms}{ID};
}

=item $ctx->B<get_id_has_timestamp>() => $boolean

Indicates whether the startup notification sequence has a timestamp
associated with it.

=cut

sub get_id_has_timestamp {
    return defined(shift->{parms}{TIMESTAMP});
}

=item $ctx->B<get_timestamp>() => $timestamp

Gets the timestamp associated with the startup notification sequence.

=cut

sub get_timestamp {
    return shift->{parms}{TIMESTAMP};
}

=item $ctx->B<complete>()

Completes the startup notification sequence by sending a C<remove>
message if the sequence is not already complete.

=cut

sub complete {
    return shift->XDE::X11::StartupNotification::Sequence::complete();
}

=item $ctx->B<setup_window>(I<$window>)

Sets up the X11 window XID, C<$window>, with appropriate EWMH properties
for startup notification.  This includes the C<_NET_STARTUP_ID> and
C<_NET_WM_USER_TIME> properties.

=cut

sub setup_window {
    my($self,$window) = @_;
# FIXME: write this method
}

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::X11::StartupNotification(3pm)>,
L<XDE::X11(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
