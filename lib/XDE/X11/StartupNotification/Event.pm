package XDE::X11::StartupNotification::Event;
use strict;
use warnings;

=head1 NAME

XDE::X11::StartupNotification::Event - startup notification monitor event

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides a representation of an X11 startup notification
event.  It is not intended on being instantiated by users, but generated
and supplied to callbacks of the
L<XDE::X11::StartupNotification::Monitor(3pm)> object.

=head1 METHODS

The module provides the following methods:

=over

=cut

use constant {
    SN_MONITOR_EVENT_INITIATED=>0,
    SN_MONITOR_EVENT_COMPLETED=>1,
    SN_MONITOR_EVENT_CHANGED=>2,
    SN_MONITOR_EVENT_CANCELED=>3,
};

=item $event->B<get_type>() => $type

Return the type of the event.  This can be one of the following values:

 SN_MONITOR_EVENT_INITIATED => 0
 SN_MONITOR_EVENT_COMPLETED => 1
 SN_MONITOR_EVENT_CHANGED   => 2
 SN_MONITOR_EVENT_CANCELED  => 3

=item $event->B<get_startup_sequence>() => $sequence

Return the startup sequence object instance associated with the event,
C<$sequence>.
This is an instance of package L<XDE::X11::StartupNotification::Sequence(3pm)>.

=cut

sub get_startup_sequence {
    my $self = shift;
    return $self->{sequence};
}

=item $event->B<get_context>() => $context

Return the startup notification monitor context object instance
associated with the event, C<$context>.  This is an instance of package
L<XDE::X11::StartupNotification::Monitor(3pm)>.

=cut

sub get_context {
    my $self = shift;
    return $self->{context};
}

package XDE::X11::StartupNotification::Event::Initiated;
use base qw(XDE::X11::StartupNotification::Event);
use strict;
use warnings;

sub get_type {
    return &XDE::X11::StartupNotification::Event::SN_MONITOR_EVENT_INITIATED;
}

package XDE::X11::StartupNotification::Event::Completed;
use base qw(XDE::X11::StartupNotification::Event);
use strict;
use warnings;

sub get_type {
    return &XDE::X11::StartupNotification::Event::SN_MONITOR_EVENT_COMPLETED;
}

package XDE::X11::StartupNotification::Event::Changed;
use base qw(XDE::X11::StartupNotification::Event);
use strict;
use warnings;

sub get_type {
    return &XDE::X11::StartupNotification::Event::SN_MONITOR_EVENT_CHANGED;
}

package XDE::X11::StartupNotification::Event::Canceled;
use base qw(XDE::X11::StartupNotification::Event);
use strict;
use warnings;

sub get_type {
    return &XDE::X11::StartupNotification::Event::SN_MONITOR_EVENT_CANCELED;
}

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::X11::StartupNotification(3pm)>,
L<XDE::X11::StartupNotification::Monitor(3pm)>,
L<XDE::X11::StartupNotification::Sequence(3pm)>,
L<XDE::X11(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
