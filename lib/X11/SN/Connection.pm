package X11::SN::Connection;
use base qw(X11::Protocol::Windows);
use X11::SN;
use strict;
use warnings;

=head1 NAME

X11::SN::Connection -- X server connection for startup notification.

=head1 METHODS

The following methods are provided:

=head2 EVENTS

=over

=item $sn->B<event_handler_CreateNotify>(I<$e>)

=item $sn->B<event_handler_DestroyNotify>(I<$e>)

=item $sn->B<event_handler_UnmapNotify>(I<$e>)

=item $sn->B<event_handler_MapNotify>(I<$e>)

=item $sn->B<event_handler_PropertyNotifyWM_STATE>(I<$e>)

=item $sn->B<event_handler_PropertyNotifyWM_CLASS>(I<$e>)

=item $sn->B<event_handler_PropertyNotifyWM_NAME>(I<$e>)

=item $sn->B<event_handler_PropertyNotifyWM_HINTS>(I<$e>)

=item $sn->B<event_handler_PropertyNotify_NET_STARTUP_ID>(I<$e>)

=item $sn->B<event_handler_PropertyNotifyWM_CLIENT_MACHINE>(I<$e>)

=item $sn->B<event_handler_PropertyNotify_NET_WM_PID>(I<$e>)

=item $sn->B<event_handler_ClientMessage_NET_STARTUP_INFO_BEGIN>(I<$e>)

=item $sn->B<event_handler_ClientMessage_NET_STARTUP_INFO>(I<$e>)

=item $sn->B<event_handler_CreateNotify>(I<$e>)

=item $sn->B<event_handler_CreateNotify>(I<$e>)

=item $sn->B<event_handler_CreateNotify>(I<$e>)

=item $sn->B<event_handler_CreateNotify>(I<$e>)

=item $sn->B<event_handler_CreateNotify>(I<$e>)

=item $sn->B<event_handler_CreateNotify>(I<$e>)

=item $sn->B<event_handler_CreateNotify>(I<$e>)

=item $sn->B<event_handler_CreateNotify>(I<$e>)

=item $sn->B<event_handler_CreateNotify>(I<$e>)

=item $sn->B<event_handler_CreateNotify>(I<$e>)

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
