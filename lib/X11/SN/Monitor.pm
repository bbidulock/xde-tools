package X11::SN::Monitor;
use base qw(X11::SN);
use strict;
use warnings;

=head1 NAME

X11::SN::Monitor - module supporting startup notification monitoring

=head1 SYNOPSIS

=head1 DESCRIPTION

The X11::SN::Monitor package provides implementation of monitor-specific
methods for use in startup notification monitoring.  The module provides
hooks for event loops; however, it does not provide an event loop of its
own.  See L</EVENT LOOP>.

Although this module mimics the functions of the libsn library, it does
not depend on the library and uses L<X11::Protocol(3pm)> to perform its
functions.

=head1 METHODS

The module provides the following methods:

=over

=item $monitor = X11::SN::Monitor->B<new>()

=back

=head2 EVENT HANDLERS

Several L<X11::Protocol::AnyEvent(3pm)> event handlers are provided for
monitoring as follows:

=over

=item $mon->B<event_handler_CreateNotify>(I<$e>)

This event handler selects for C<StructureNotify> and C<PropertyNotify>
events on newly created top-level windows so that we can track
applications that map windows by C<WMCLASS>.

=item $mon->B<event_handler_DestroyNotify>(I<$e>)

This is to remove windows from memory when they are destroyed.

=item $mon->B<event_handler_UnmapNotify>(I<$e>)

=item $mon->B<event_handler_MapNotify>(I<$e>)

When a window is mapped, this handler checks to see whether it forms the
completion of a startup notification sequence by C<WMCLASS>, or whether
the C<_NET_STARTUP_ID> property identifies a window mapped in completion
of a startup notification.  Also checked are the C<WM_CLIENT_MACHINE>
and C<_NET_WM_PID> properties to be able to add a C<HOST> and C<PID>
field to existing startup notification sequences.

=item $mon->B<event_handler_PropertyNotifyWM_STATE>(I<$e>)

When an ICCCM 2.0 compliant window manager starts managing a top-level
client window, it places the C<WM_STATE> proeprty on the window.  The
window manager only performs these functions when a request has been
made to map the window.  When we receive a C<CreateNotify> for a
top-level window, we start tracking.

Note that L<fluxbox(1)>, L<blackbox(1)>, L<openbox(1)> and L<pekwm(1)>
do not set the C<WM_STATE> property on WindowMaker dock apps (even
though, WindowMaker itself alway sets the C<WM_STATE> on dock apps).
This is bad because it also defeats the X Session Management proxy
L<smproxy(8)> from doing its job.  In particular, L<fluxbox(1)>,
L<blackbox(1)>, and L<pekwm(1)> do not support X Session Management
directly.

This is actually strange as L<ctwm(1)>, L<vtwm(1)> and even L<twm(1)>
supports X11R6 X Session Management.

=item $mon->B<event_handler_ClientMessage_NET_STARTUP_INFO_BEGIN>(I<$e>)

C<_NET_STARTUP_INFO_BEGIN> client messages start a sequence of
individual 20-byte startup notification messages that form a single
message.  Each begin message fragment contains enought bytes (20-bytes)
to identify the type of message (C<new>, C<change> or C<remove>) but are
unlikely to contain an entire startup notification ID parameter.

This handler establishes a new list of message fragements for the
sending window, C<$e-E<gt>{window}>.

When a beginning message fragment appears and an incomplete message
fragment sequence already exists, the incomplete fragments are
discarded.

=cut

sub _complete_message {
    my($X,$data) = @_;
    my $msg = Encode::decode('UTF-8',$data);
     # FIXME: more to do, parse and unpack message
}


sub event_handler_ClientMessage_NET_STARTUP_INFO_BGIN {
    my($X,$e) = @_;
    my $win = $e->{window};
    return unless $win;
    my $data = unpack('Z*',$e->{data}."\x00");
    return unless $data =~ m{^(new|change|remove): };
    $X->{sn}{messages}{$win} = $data;
    _complete_message($X,delete $X->{sn}{messages}{$win})
	if length($data) < 20;
}

=item $mon->B<event_handler_ClientMessage_NET_STARTUP_INFO>(I<$e>)

C<_NET_STARTUP_INFO> client messages continue a sequence of message
fragments that make up a complete message.  If there is a null byte
(0x00) in the data portion of the message, this message also completes a
message.

This method adds fragments to a message until it is complete and then
dispatches it to the appropriate L<X11::SN::Sequence(3pm)>.  For a
freshly compeleted C<new> message, a corresponding
L<X11::SN::Sequence(epm)> will be created and stored by startup
notification ID.  Completed C<remove> messages will result in the
destruction and dereferenceing of the corresponding
L<X11::SN::Sequence(3pm)>.  (Note that here, I<sequence>, referes to the
startup sequence and not the message fragement sequence.)

When a message fragment appears from a window for which no start
fragment was received, the fragment is discarded.

=cut

sub event_handler_ClientMessage_NET_STARTUP_INFO {
    my($X,$e) = @_;
    my $win = $e->{window};
    return unless $win;
    return unless exists $X->{sn}{messages}{$win};
    my $data = unpack('Z*',$e->{data}."\x00");
    $X->{sn}{messages}{$win} .= $data;
    _complete_message($X,delete $X->{sn}{messages}{$win})
	if length($data) < 20;
}

=back

=cut

1;

__END__

=head1 EVENT LOOP

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::SN(3pm)>,
L<X11::Protocol(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
