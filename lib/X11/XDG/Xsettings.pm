require AnyEvent;
require X11::Protocol;

package X11::XDG::Xsettings;
use base qw(X11::Protocol);
use strict;
use warnings;

sub new {
	my $type = shift;
	my $self;
	if (ref $_[2] eq 'ARRAY') {
		$self = new X11::Protocol(shift,shift);
	} else {
		$self = new X11::Protocol(shift);
	}
	return $self unless $self;
	if (ref $_[0] eq 'HASH') {
		$self->{_xsettings} = shift;
	}
	# start the watchers
	my $fh = $self->{connection}->fh;
	my $cb = $self->can('handle_event');
	$self->{_watchers}{X11} =
		AnyEvent->io(fh=>$fh,poll=>"r",cb=>$cb);
	return $self;
}

sub handle_event {
	my $event = shift;
}

=head1 NAME

 X11::XDG::Xsettings - XSETTINGS configuration daemon

=head1 SYNOPSIS

 use Ev;
 use X11::XDG::Xsettings;

 my $xset = new X11::XDG::Xsettings(repeat_rate=>55, ...);
 EV::loop;

=head1 DESCRIPTION

X11::XDG::Xsettings is an implementation of the XSETTINGS daemon as
specified in the L<XSETTINGS>[1] specification.  X11::XDG::Xsettings
uses L<AnyEvent(3)> for event handling so that you can integrate your
favorite event loop.

=head1 METHODS

=head2 new ( I<%hash> )

Creates a new X11::XDG::Xsettings object and return a reference to it.
I<%hash> can specify the initial options to be set on the X Display.  An
X11::XDG::Settings object is derived from a L<X11::Protocol(3)> object
and all methods provided by that object are supported.  Has values are
as follow:

=over

=item I<display>

Specify a display for the creation of the base L<X11::Protocol(3)> object.

=item I<connection>

Specify a connection for the creation of the base L<X11::Protocol(3)>
object.

=back

=head2 handle_event ( I<X11::Protocol::Event> )

The default event handler for the L<X11::Protocol(3)> subobject.  If you
want to intercept or filter messages for the XSETTINGS daemon, the
handler can be changed on the L<X11::Protocol(3)> subobject and
intercepted events passed to this method.

=head1 CLIENT BEHAVIOUR

On startup, each client that should identify the settings window by
calling L<XGetSelectionOwner(3)> for the C<_XSETTINGS_S[N]> selection and
select for notification on the settings window by calling
L<XSelectInput(3)> with a mask of C<StructureNotifyMask|PropertyChangeMask>.

To prevent race conditions a client B<must> grab the server while
performing these operations using L<XGrabServer(3)>.

If there is no owner of the C<_XSETTINGS_S[N]> selection, the client can
determine when an owner is established by listening for client messages
sent to the root window of the screen with type C<MANAGER>.  The format
of this message is:

 event-mask:  StructureNotify
 event:       ClientMessage
 type:        MANAGER
 format:      32
 data[0]:     timestamp
 data[1]:     _XSETTINGS_S[N] (atom)
 data[2]:     New owner of the selection
 data[3]:     0 (reserved)

The client can then proceed to read the contents of the
C<_XSETTINGS_SETTINGS> property from the settings window and interpret.

Clients must trap X error when reading the C<_XSETTING_SETTINGS>
property because it is possible that the selection window may be
destroyed at any time.

When the client is notified that the settings window has been destroyed
or discovers that the selection window has been destroyed, it shoud
reset all settings to their default values and then proceed as on intial
startup.

When a client receives a C<PropertyChangeNotify> event for the window it
should reread the _XSETTING_SETTINGS property.  It can use the C<serial>
field to tel what fields have been changed.  The client must parts the
entire property and read in all new values before taking action on
changed settings such as notifying listeners for those settings to
avoid using a mix of old and new data.

=head1 MANAGER BEHAVIOUR

The C<_XSETTING_S[N]> selection is managed as a manager selection
according to section 2.8 of the ICCCM and the handling of the selections
window, the C<_XSETTING_S[N]> window and C<MANAGER> client messages must
conform to that specification.

THe settings manager changes the contents of the C<_XSETTINGS_SETTINGS>
property of the root window whenever the source it derives them from
changes, taking care to increment the C<serial> field at each increment
and set the C<last-change-serial> fields appropriately.


=head1 SEE ALSO

L<X11::Protocol(3)>, L<X11::Protocol::Event(3)>.

=over

=item 1.

L<XSETTINGS|http://www.freedesktop.org/wiki/Specifications/xsettings-spec>

=back

=cut





