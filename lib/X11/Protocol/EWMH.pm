package X11::Protocol::EWMH;
use X11::Protocol::Util  qw(:all);
use X11::Protocol::ICCCM qw(:all);
use X11::Protocol;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

%EXPORT_TAGS = (
    all => [qw(
	NetClientMessage
	get_NET_SUPPORTED
	dmp_NET_SUPPORTED
	set_NET_SUPPORTED
	get_NET_CLIENT_LIST
	dmp_NET_CLIENT_LIST
	set_NET_CLIENT_LIST
	get_NET_CLIENT_LIST_STACKING
	dmp_NET_CLIENT_LIST_STACKING
	set_NET_CLIENT_LIST_STACKING
	get_NET_NUMBER_OF_DESKTOPS
	dmp_NET_NUMBER_OF_DESKTOPS
	set_NET_NUMBER_OF_DESKTOPS
	req_NET_NUMBER_OF_DESKTOPS
	got_NET_NUMBER_OF_DESKTOPS
	get_NET_DESKTOP_GEOMETRY
	dmp_NET_DESKTOP_GEOMETRY
	set_NET_DESKTOP_GEOMETRY
	req_NET_DESKTOP_GEOMETRY
	got_NET_DESKTOP_GEOMETRY
	get_NET_DESKTOP_VIEWPORT
	dmp_NET_DESKTOP_VIEWPORT
	set_NET_DESKTOP_VIEWPORT
	req_NET_DESKTOP_VIEWPORT
	got_NET_DESKTOP_VIEWPORT
	get_NET_CURRENT_DESKTOP
	dmp_NET_CURRENT_DESKTOP
	set_NET_CURRENT_DESKTOP
	req_NET_CURRENT_DESKTOP
	got_NET_CURRENT_DESKTOP
	get_NET_DESKTOP_NAMES
	dmp_NET_DESKTOP_NAMES
	set_NET_DESKTOP_NAMES
	req_NET_DESKTOP_NAMES
	get_NET_ACTIVE_WINDOW
	dmp_NET_ACTIVE_WINDOW
	set_NET_ACTIVE_WINDOW
	req_NET_ACTIVE_WINDOW
	got_NET_ACTIVE_WINDOW
	get_NET_WORKAREA
	dmp_NET_WORKAREA
	set_NET_WORKAREA
	req_NET_WORKAREA
	get_NET_SUPPORTING_WM_CHECK
	dmp_NET_SUPPORTING_WM_CHECK
	set_NET_SUPPORTING_WM_CHECK
	get_NET_VIRTUAL_ROOTS
	dmp_NET_VIRTUAL_ROOTS
	set_NET_VIRTUAL_ROOTS
	get_NET_DESKTOP_LAYOUT
	dmp_NET_DESKTOP_LAYOUT
	set_NET_DESKTOP_LAYOUT
	get_NET_SHOWING_DESKTOP
	dmp_NET_SHOWING_DESKTOP
	set_NET_SHOWING_DESKTOP
	req_NET_SHOWING_DESKTOP
	got_NET_SHOWING_DESKTOP
	req_NET_CLOSE_WINDOW
	got_NET_CLOSE_WINDOW
	req_NET_MOVERESIZE_WINDOW
	got_NET_MOVERESIZE_WINDOW
	req_NET_WM_MOVERESIZE
	got_NET_WM_MOVERESIZE
	req_NET_RESTACK_WINDOW
	got_NET_RESTACK_WINDOW
	req_NET_REQUEST_FRAME_EXTENTS
	got_NET_REQUEST_FRAME_EXTENTS
	get_NET_WM_NAME
	dmp_NET_WM_NAME
	set_NET_WM_NAME
	get_NET_WM_VISIBLE_NAME
	dmp_NET_WM_VISIBLE_NAME
	set_NET_WM_VISIBLE_NAME
	get_NET_WM_ICON_NAME
	dmp_NET_WM_ICON_NAME
	set_NET_WM_ICON_NAME
	get_NET_WM_VISIBLE_ICON_NAME
	dmp_NET_WM_VISIBLE_ICON_NAME
	set_NET_WM_VISIBLE_ICON_NAME
	get_NET_WM_ICON_VISIBLE_NAME
	dmp_NET_WM_ICON_VISIBLE_NAME
	set_NET_WM_ICON_VISIBLE_NAME
	get_NET_WM_DESKTOP
	dmp_NET_WM_DESKTOP
	set_NET_WM_DESKTOP
	req_NET_WM_DESKTOP
	got_NET_WM_DESKTOP
	get_NET_WM_WINDOW_TYPE
	dmp_NET_WM_WINDOW_TYPE
	set_NET_WM_WINDOW_TYPE
	get_NET_WM_STATE
	dmp_NET_WM_STATE
	set_NET_WM_STATE
	req_NET_WM_STATE
	get_NET_WM_ALLOWED_ACTIONS
	dmp_NET_WM_ALLOWED_ACTIONS
	set_NET_WM_ALLOWED_ACTIONS
	get_NET_WM_STRUT
	dmp_NET_WM_STRUT
	set_NET_WM_STRUT
	get_NET_WM_STRUT_PARTIAL
	dmp_NET_WM_STRUT_PARTIAL
	set_NET_WM_STRUT_PARTIAL
	get_NET_WM_ICON_GEOMETRY
	dmp_NET_WM_ICON_GEOMETRY
	set_NET_WM_ICON_GEOMETRY
	get_NET_WM_ICON
	dmp_NET_WM_ICON
	set_NET_WM_ICON
	get_NET_WM_PID
	dmp_NET_WM_PID
	set_NET_WM_PID
	get_NET_WM_HANDLED_ICONS
	dmp_NET_WM_HANDLED_ICONS
	set_NET_WM_HANDLED_ICONS
	get_NET_WM_USER_TIME
	dmp_NET_WM_USER_TIME
	set_NET_WM_USER_TIME
	get_NET_WM_USER_TIME_WINDOW
	dmp_NET_WM_USER_TIME_WINDOW
	set_NET_WM_USER_TIME_WINDOW
	get_NET_FRAME_EXTENTS
	dmp_NET_FRAME_EXTENTS
	set_NET_FRAME_EXTENTS
	get_NET_WM_OPAQUE_REGION
	dmp_NET_WM_OPAQUE_REGION
	set_NET_WM_OPAQUE_REGION
	get_NET_WM_BYPASS_COMPOSITOR
	dmp_NET_WM_BYPASS_COMPOSITOR
	set_NET_WM_BYPASS_COMPOSITOR
	get_NET_WM_FULLSCREEN_MONITORS
	dmp_NET_WM_FULLSCREEN_MONITORS
	set_NET_WM_FULLSCREEN_MONITORS
	req_NET_WM_FULLSCREEN_MONITORS
	get_NET_WM_WINDOW_OPACITY
	dmp_NET_WM_WINDOW_OPACITY
	set_NET_WM_WINDOW_OPACITY
	get_NET_WM_SYNC_REQUEST_COUNTER
	dmp_NET_WM_SYNC_REQUEST_COUNTER
	set_NET_WM_SYNC_REQUEST_COUNTER
	get_NET_DESKTOP_PIXMAPS
	dmp_NET_DESKTOP_PIXMAPS
	set_NET_DESKTOP_PIXMAPS
	get_NET_SYSTEM_TRAY_ORIENTATION
	dmp_NET_SYSTEM_TRAY_ORIENTATION
	set_NET_SYSTEM_TRAY_ORIENTATION
	get_NET_SYSTEM_TRAY_VISUAL
	dmp_NET_SYSTEM_TRAY_VISUAL
	set_NET_SYSTEM_TRAY_VISUAL
	get_XEMBED_INFO
	dmp_XEMBED_INFO
	set_XEMBED_INFO
    )],
    req => [qw(
	NetClientMessage
    )],
);


foreach my $pfx (qw(get set dmp req)) {
    push @{$EXPORT_TAGS{$pfx}},
	 grep {/^$pfx/} @{$EXPORT_TAGS{all}};
}

Exporter::export_ok_tags('all');

=head1 NAME

X11::Protocol::EWMH -- provide methods for controlling enhanced window manager hints.

=head1 SYNOPSIS

 use X11::Protocol::EWMH;

 my $ewmh = X11::Protocol::EWMH->new();

 $ewmh->req_NET_DESKTOP_VIEWPORT(0,1);

=head1 DESCRIPTION

Provides a module with methods that can be used to control a EWMH
compliant window manager.

=head1 METHODS

The following methods are provided by this module:

=over

=item B<NetClientMessage>(I<$X>,I<$window>,I<$type>,I<$data>)

=cut

sub NetClientMessage {
    my($X,$window,$type,$data) = @_;
    $window = 0 unless defined $window;
    $window = 0 if $window eq 'None';
    $window = $X->root unless $window;
    $type = ($type =~ m{^\d+$}) ? $type : $X->atom($type);
    $data = pack('LLLLL',@$data) if ref $data eq 'ARRAY';
    $X->SendEvent($X->root, 0,
	    $X->pack_event_mask(qw(
		    SubstructureNotify
		    SubstructureRedirect)),
	    $X->pack_event(
		name => 'ClientMessage',
		window => $window,
		type => $type,
		format => 32,
		data => $data));
}

use constant {
    _NET_SOURCE_UNSPECIFIED => 0,
    _NET_SOURCE_APPLICATION => 1,
    _NET_SOURCE_PAGER	    => 2,

    NetSource => [qw(Unspecified Application Pager)],
};

=back

=head2 Root window properties (and related messages)

The following are root window properties and related messages of the
EWMH/NetWM specification 1.5.

=head3 _NET_SUPPORTED, ATOM[]/32

This property MUST be set by the Window Manager to indicate which hints
it supports. For example: considering _NET_WM_STATE both this atom and
all supported states e.g. _NET_WM_STATE_MODAL, _NET_WM_STATE_STICKY,
would be listed. This assumes that backwards incompatible changes will
not be made to the hints (without being renamed).

This property is handled inconsistently by window managers:

=over

=item 1.

L<jwm(1)>, L<pekwm(1)>, L<icewm(1)>, L<fvwm(1)> and L<afterstep(1)>
place C<_NET_SUPPORTED> in C<_NET_SUPPORTED>: this is, of course,
unnecessary.

=back

=over

=cut

=item B<get_NET_SUPPORTED>(I<$X>,I<$root>) => I<$names> or undef

Returns a reference to a hash with each existing index reflecting the
name of a supported atom and a value of 1.
Returns C<undef> when no C<_NET_SUPPORTED> property exists on I<$root>.
I<$root> defaults to C<$X-E<gt>root>.

=cut

sub get_NET_SUPPORTED {
    return getWMRootPropertyAtoms($_[0],_NET_SUPPORTED=>$_[1]);
}

sub dmp_NET_SUPPORTED {
    return dmpWMRootPropertyAtoms($_[0],_NET_SUPPORTED=>supported=>$_[1]);
}

=item B<set_NET_SUPPORTED>(I<$X>,I<$names>)

Sets the supported atoms to I<$names>.  I<$names> can be C<undef>, in
which case the C<_NET_SUPPORTED> property will be deleted; a hash
reference, in which case the atom names or numbers are the keys in the
hash with true values; or an array reference to a list of atom names or
numbers.
The C<_NET_SUPPORTED> property should only be set directly by a window manager.

=cut

sub set_NET_SUPPORTED {
    return setWMRootPropertyAtoms($_[0],_NET_SUPPORTED=>$_[1]);
}

=back

=head3 _NET_CLIENT_LIST, _NET_CLIENT_LIST_STACKING, WINDOW[]/32

These arrays contain all X Windows managed by the Window Manager.
C<_NET_CLIENT_LIST> has initial mapping order, starting with the oldest
window. C<_NET_CLIENT_LIST_STACKING> has bottom-to-top stacking order.
These properties SHOULD be set and updated by the Window Manager.

=over

=cut

=item B<get_NET_CLIENT_LIST>(I<$X>,I<$root>) => I<$windows> or undef

Returns the array reference to an array of clients (XID numbers).
Returns C<undef> when no C<_NET_CLIENT_LIST> property exists on I<$root>.
I<$root> defaults to C<$X-E<gt>root>.

=cut

sub get_NET_CLIENT_LIST {
    return getWMRootPropertyUints($_[0],_NET_CLIENT_LIST=>$_[1]);
}

sub dmp_NET_CLIENT_LIST {
    return dmpWMRootPropertyUints($_[0],_NET_CLIENT_LIST=>clients=>$_[1]);
}

=item B<set_NET_CLIENT_LIST>(I<$X>,I<$windows>)

The C<_NET_CLIENT_LIST> property should only be set directly by a window manager.

=cut

sub set_NET_CLIENT_LIST {
    return setWMRootPropertyUints($_[0],_NET_CLIENT_LIST=>WINDOW=>$_[1]);
}

=item B<get_NET_CLIENT_LIST_STACKING>(I<$X>,I<$root>) => I<$windows> or undef

Returns an array reference to an array of clients (XID numbers).
Returns C<undef> when no C<_NET_CLIENT_LIST_STACKING> property exists on I<$root>.
I<$root> defaults to C<$X-E<gt>root>.

=cut

sub get_NET_CLIENT_LIST_STACKING {
    return getWMRootPropertyUints($_[0],_NET_CLIENT_LIST_STACKING=>$_[1]);
}

sub dmp_NET_CLIENT_LIST_STACKING {
    return dmpWMRootPropertyUints($_[0],_NET_CLIENT_LIST_STACKING=>clients=>$_[1]);
}

=item B<set_NET_CLIENT_LIST_STACKING>(I<$X>,I<$windows>)

The C<_NET_CLIENT_LIST_STACKING> property should only be set directly by a window manager.

=cut

sub set_NET_CLIENT_LIST_STACKING {
    return setWMRootPropertyUints($_[0],_NET_CLIENT_LIST_STACKING=>WINDOW=>$_[1]);
}

=back

=head3 _NET_NUMBER_OF_DESKTOPS, CARDINAL/32

This property SHOULD be set and updated by the Window Manager to
indicate the number of virtual desktops.

A Pager can request a change in the number of desktops by sending a
_NET_NUMBER_OF_DESKTOPS message to the root window:

 _NET_NUMBER_OF_DESKTOPS
   message_type = _NET_NUMBER_OF_DESKTOPS
   format = 32
   data.l[0] = new_number_of_desktops
   other data.l[] elements = 0

The Window Manager is free to honor or reject this request. If the
request is honored _NET_NUMBER_OF_DESKTOPS MUST be set to the new
number of desktops, _NET_VIRTUAL_ROOTS MUST be set to store the new
number of desktop virtual root window IDs and _NET_DESKTOP_VIEWPORT and
_NET_WORKAREA must also be changed accordingly. The _NET_DESKTOP_NAMES
property MAY remain unchanged.

If the number of desktops is shrinking and _NET_CURRENT_DESKTOP is out
of the new range of available desktops, then this MUST be set to the
last available desktop from the new set. Clients that are still present
on desktops that are out of the new range MUST be moved to the very
last desktop from the new set. For these _NET_WM_DESKTOP MUST be
updated.

=over

=cut

=item B<get_NET_NUMBER_OF_DESKTOPS>(I<$X>,I<$root>) => I<$desktops>

Returns the number of desktops specified by the root window property,
C<$desktops>, or C<undef> when no root window property exists.

=cut

sub get_NET_NUMBER_OF_DESKTOPS {
    return getWMRootPropertyUint($_[0],_NET_NUMBER_OF_DESKTOPS=>$_[1]);
}

sub dmp_NET_NUMBER_OF_DESKTOPS {
    return dmpWMRootPropertyUint($_[0],_NET_NUMBER_OF_DESKTOPS=>number=>$_[1]);
}

=item B<set_NET_NUMBER_OF_DESKTOPS>(I<$X>,I<$desktops>)

The C<_NET_NuMBER_OF_DESKTOPS> property should only be set directly by a window manager.

=cut

sub set_NET_NUMBER_OF_DESKTOPS {
    return setWMRootPropertyUint($_[0],_NET_NUMBER_OF_DESKTOPS=>$_[1]);
}

=item B<req_NET_NUMBER_OF_DESKTOPS>(I<$X>,I<$desktops>)

Sets the number of desktops, C<$desktops>, using the following client
message:

 _NET_NUMBER_OF_DESKTOPS
    target = root
    propagate = false
    name = ClientMessage
    event mask = StructureNotify
    message_type = _NET_NUMBER_OF_DESKTOPS
    window = root
    format = 32
    data.l[0] = number
    other data.l[] elements = 0

=cut

sub req_NET_NUMBER_OF_DESKTOPS {
    my ($X,$desktops) = @_;
    NetClientMessage($X,$X->root,_NET_NUMBER_OF_DESKTOPS=>[$desktops]);
}

sub got_NET_NUMBER_OF_DESKTOPS {
    my($X,$window,$desktops) = @_;
    return ($window,$desktops);
}

=back

=head3 _NET_DESKTOP_GEOMETRY width, height, CARDINAL[2]/32

Array of two cardinals that defines the common size of all desktops
(this is equal to the screen size if the Window Manager doesn't support
large desktops, otherwise it's equal to the virtual size of the
desktop). This property SHOULD be set by the Window Manager.

A Pager can request a change in the desktop geometry by sending a
_NET_DESKTOP_GEOMETRY client message to the root window:

 _NET_DESKTOP_GEOMETRY
   message_type = _NET_DESKTOP_GEOMETRY
   format = 32
   data.l[0] = new_width
   data.l[1] = new_height
   other data.l[] elements = 0

The Window Manager MAY choose to ignore this message, in which case
_NET_DESKTOP_GEOMETRY property will remain unchanged.

B<Note:> This property is not handled consistently across supported
window managers:

=over

=item 1.

L<icewm(1)> does not set this property.  For this reason, we default to
the screen size when this property is not set.

=back

=over

=cut

=item B<get_NET_DESKTOP_GEOMETRY>(I<$X>,I<$root>) => I<$geometry>

Returns the desktop geometry as a reference to a list of desktop width
and height in pixels, or C<undef> if the property does not exist on the
root window.

=cut

sub get_NET_DESKTOP_GEOMETRY {
    return getWMRootPropertyUints($_[0],_NET_DESKTOP_GEOMETRY=>$_[1]);
}

sub dmp_NET_DESKTOP_GEOMETRY {
    my($X,$geometry) = @_;
    return dmpWMRootPropertyDisplay($X,_NET_DESKTOP_GEOMETRY=>sub{
	my @vals = @$geometry;
	my $i = 0;
	while (@vals) {
	    printf "\t%-20s: (%d,%d)\n",'desktop('.$i.')',shift @vals,shift @vals; $i++;
	}
    });
}

=item B<set_NET_DESKTOP_GEOMETRY>(I<$X>,I<$geometry>)

The C<_NET_DESKTOP_GEOMETRY> property should only be set directly by a window manager.

=cut

sub set_NET_DESKTOP_GEOMETRY {
    return setWMRootPropertyUints($_[0],_NET_DESKTOP_GEOMETRY=>CARDINAL=>$_[1]);
}

=item B<req_NET_DESKTOP_GEOMETRY>(I<$X>,I<$w>,I<$h>)

Sets the desktop geometry to th specified width, C<$w>, and height,
C<$h> using the following client message:

 _NET_DESKTOP_GEOMETRY
    message_type = _NET_DESKTOP_GEOMETRY
    format = 32
    data.l[0] = new_width
    data.l[1] = new_height
    other data.l[] elements = 0

=cut

sub req_NET_DESKTOP_GEOMETRY {
    my ($X, $w, $h) = @_;
    NetClientMessage($X,$X->root,_NET_DESKTOP_GEOMETRY=>[$w,$h]);
}

sub got_NET_DESKTOP_GEOMETRY {
    my($X,$window,$w,$h) = @_;
    return ($window,$w,$h);
}

=back

=head3 _NET_DESKTOP_VIEWPORT, CARDINAL[]/32

Array of pairs of cardinals that define the top left corner of each
desktop's viewport. For Window Managers that don't support large
desktops, this MUST always be set to (0,0).

B<Note:>  This property is handled very inconsistently by window
managers:

=over

=item 1.

A number of window managers (L<fluxbox(1)>, L<jwm(1)>,
L<blackbox(1)>) take that last sentence literally and set
_NET_DESKTOP_VIEWPORT to (0,0) regardless of the number of desktops.

=item 2.

Others (L<openbox(1)>, L<wmaker(1)>) more correctly set it to (0,0) for
each desktop.

=item 3.

L<afterstep(1)> supports large desktops an largely sets it correctly,
however, at points _NET_NUMBER_OF_DESKTOPS can be larger than the
_NET_DESKTOP_VIEWPORT array; with the assumption it seems that the
viewport is (0,0) for any desktops not represented in the
_NET_DESKTOP_VIEWPORT array.  L<afterstep(1)> does not tie the viewport
on each desktop together, and there may be different viewport settings
for different desktops.

=item 4.

L<fvwm(1)> supports large desktops and sets this correctly; however, the
viewport on each desktop are tied together (that is, when positioned at
(x,y), this property has (x,y) for each desktop).

=item 5.

Still others (L<pekwm(1)>, L<icewm(1)>) do not set the property at all.

=back

A Pager can request to change the viewport for the current desktop by
sending a _NET_DESKTOP_VIEWPORT client message to the root window:

 _NET_DESKTOP_VIEWPORT
   message_type = _NET_DESKTOP_VIEWPORT
   format = 32
   data.l[0] = new_vx
   data.l[1] = new_vy
   other data.l[] elements = 0

The Window Manager MAY choose to ignore this message, in which case
_NET_DESKTOP_VIEWPORT property will remain unchanged.

=over

=cut

=item B<get_NET_DESKTOP_VIEWPORT>(I<$X>,I<$root>) => I<$viewport>

Returns the desktop viewport as a reference to a list of x and y
coordinats (C<$vx> and C<$vy>), or C<undef> if no such property exists
on the root window.

=cut

sub get_NET_DESKTOP_VIEWPORT {
    my($X,$root) = @_;
    my $value = getWMRootPropertyInts($X,_NET_DESKTOP_VIEWPORT=>$root);
    if ($value) {
	# window managers are very inconsistent about their treatment of
	# this property, so we need to make some corrections.
	my $n = get_NET_NUMBER_OF_DESKTOPS($X,$root);
	$n = 1 unless defined $n;
	if (@$value < ($n<<1)) {
	    push @$value, (0,0) x ($n - (@$value>>1));
	}
    }
    return $value;
}

sub dmp_NET_DESKTOP_VIEWPORT {
    my($X,$viewport) = @_;
    return dmpWMRootPropertyDisplay($X,_NET_DESKTOP_VIEWPORT=>sub{
	my @vals = @$viewport;
	my $i = 0;
	while (@vals) {
	    printf "\t%-20s: (%d,%d)\n",'desktop('.$i.')',shift @vals,shift @vals; $i++;
	}
    });
}

=item B<set_NET_DESKTOP_VIEWPORT>(I<$X>,I<$viewport>)

The C<_NET_DESKTOP_VIEWPORT> property should only be set directly by a window manager.

=cut

sub set_NET_DESKTOP_VIEWPORT {
    return setWMRootPropertyUints($_[0],_NET_DESKTOP_VIEWPORT=>CARDINAL=>$_[1]);
}

=item B<req_NET_DESKTOP_VIEWPORT>(I<$X>,I<$vx>,I<$vy>)

A pager can request to change the viewport for the current desktop by
sending a _NET_DESKTOP_VIEWPORT client message to the root window:

 _NET_DESKTOP_VIEWPORT
   message_type = _NET_DESKTOP_VIEWPORT
   format = 32
   data.l[0] = new_vx
   data.l[1] = new_vy
   other data.l[] elements = 0

=cut

sub req_NET_DESKTOP_VIEWPORT {
    my($X,$vx,$vy) = @_;
    NetClientMessage($X,$X->root,_NET_DESKTOP_VIEWPORT=>[$vx,$vy]);
}

sub got_NET_DESKTOP_VIEWPORT {
    my($X,$window,$vx,$vy) = @_;
    return ($window,$vx,$vy);
}

=back

=head3 _NET_CURRENT_DESKTOP desktop, CARDINAL/32

The index of the current desktop. This is always an integer between 0
and _NET_NUMBER_OF_DESKTOPS - 1. This MUST be set and updated by the
Window Manager. If a Pager wants to switch to another virtual desktop,
it MUST send a _NET_CURRENT_DESKTOP client message to the root window:

 _NET_CURRENT_DESKTOP
   message_type = _NET_CURRENT_DESKTOP
   format = 32
   data.l[0] = new_index
   data.l[1] = time
   other data.l[] elements = 0

Note that the time may be 0 for clients using an older version of
this spec, in which case the time field should be ignored.

=over

=cut

=item B<get_NET_CURRENT_DESKTOP>(I<$X>,I<$root>) => I<$desktop>

Returns the scalar index value of the current desktop, or C<undef> if no
such property exists on the root window.  The first desktop has an index
value of zero (0).

=cut

sub get_NET_CURRENT_DESKTOP {
    return getWMRootPropertyUint($_[0],_NET_CURRENT_DESKTOP=>$_[1]);
}

sub dmp_NET_CURRENT_DESKTOP {
    return dmpWMRootPropertyUint($_[0],_NET_CURRENT_DESKTOP=>current=>$_[1]);
}

=item B<set_NET_CURRENT_DESKTOP>(I<$X>,I<$desktop>)

The C<_NET_CURRENT_DESKTOP> property should only be set directly by a window manager.

=cut

sub set_NET_CURRENT_DESKTOP {
    return setWMRootPropertyUint($_[0],_NET_CURRENT_DESKTOP=>CARDINAL=>$_[1]);
}

=item B<req_NET_CURRENT_DESKTOP>(I<$X>,I<$index>,I<$time>)

If a pager wants to switch to another virtual desktop, it must send a
_NET_CURRENT_DESKTOP client message to the root window:

 _NET_CURRENT_DESKTOP
   message_type = _NET_CURRENT_DESKTOP
   format = 32
   data.l[0] = new_index
   data.l[1] = time
   other data.l[] elements = 0

=cut

sub req_NET_CURRENT_DESKTOP {
    my($X,$index,$time) = @_;
    $time = 0 unless $time;
    NetClientMessage($X,$X->root,_NET_CURRENT_DESKTOP=>[$index,$time]);
}

sub got_NET_CURRENT_DESKTOP {
    my($X,$window,$index,$time) = @_;
    $time = 'CurrentTime' unless $time;
    return ($window,$index,$time);
}

=back

=head3 _NET_DESKTOP_NAMES, UTF8_STRING[]

The names of all virtual desktops. This is a list of NULL-terminated
strings in UTF-8 encoding [UTF8]. This property MAY be changed by a
Pager or the Window Manager at any time.

Note: The number of names could be different from
_NET_NUMBER_OF_DESKTOPS. If it is less than _NET_NUMBER_OF_DESKTOPS,
then the desktops with high numbers are unnamed. If it is larger than
_NET_NUMBER_OF_DESKTOPS, then the excess names outside of the
_NET_NUMBER_OF_DESKTOPS are considered to be reserved in case the
number of desktops is increased.

Rationale: The name is not a necessary attribute of a virtual desktop.
Thus the availability or unavailability of names has no impact on
virtual desktop functionality. Since names are set by users and users
are likely to preset names for a fixed number of desktops, it doesn't
make sense to shrink or grow this list when the number of available
desktops changes.

=over

=cut

=item B<get_NET_DESKTOP_NAMES>(I<$X>,I<$root>) => I<$names>

Returns a reference to a list of desktop name strings that represent the
names of the corresponding ordinal desktops, or C<undef> when there is
no such property on the root window.

=cut

sub get_NET_DESKTOP_NAMES {
    return getWMRootPropertyTermStrings($_[0],_NET_DESKTOP_NAMES=>$_[1]);
}

sub dmp_NET_DESKTOP_NAMES {
    my($X,$names) = @_;
    return dmpWMRootPropertyDisplay($X,_NET_DESKTOP_NAMES=>sub{
	my $i = 0;
	foreach (@$names) {
	    printf "\t%-20s: %s\n",'desktop('.$i.')',"'".$_."'"; $i++;
	}
    });
}

=item B<set_NET_DESKTOP_NAMES>(I<$X>,I<$names>)

=cut

sub set_NET_DESKTOP_NAMES {
    return setWMRootPropertyStrings($_[0],_NET_DESKTOP_NAMES=>UTF8_STRING=>$_[1]);
}

=item B<req_NET_DESKTOP_NAMES>(I<$X>,I<@names>)

Sets the desktop names to the specified list of names, C<@names>, by
directly changing the property.

=cut

sub req_NET_DESKTOP_NAMES {
    my ($X,@names) = @_;
    return set_NET_DESKTOP_NAMES($X,\@names);
}

=back

=head3 _NET_ACTIVE_WINDOW, WINDOW/32

The window ID of the currently active window or None if no window has
the focus. This is a read-only property set by the Window Manager. If a
Client wants to activate another window, it MUST send a
_NET_ACTIVE_WINDOW client message to the root window:

 _NET_ACTIVE_WINDOW
   window  = window to activate
   message_type = _NET_ACTIVE_WINDOW
   format = 32
   data.l[0] = source indication
   data.l[1] = time
   data.l[2] = requestor's currently active window, 0 if none
   other data.l[] elements = 0

Source indication should be 1 when the request comes from an
application, and 2 when it comes from a pager. Clients using older
version of this spec use 0 as source indication, see the section called
"Source indication in requests" for details. The time is Client's
last user activity time (see _NET_WM_USER_TIME) at the time of the
request, and the currently active window is the Client's active
toplevel window, if any (the Window Manager may be e.g. more likely to
obey the request if it will mean transferring focus from one active
window to another).

Depending on the information provided with the message, the Window
Manager may decide to refuse the request (either completely ignore it,
or e.g. use _NET_WM_STATE_DEMANDS_ATTENTION).

=over

=cut

=item B<get_NET_ACTIVE_WINDOW>(I<$X>,I<$root>) => I<$active>

Returns the scalar value of the active window, or C<undef> when there is
no such property on the root window.

=cut

sub get_NET_ACTIVE_WINDOW {
    return getWMRootPropertyUint($_[0],_NET_ACTIVE_WINDOW=>$_[1]);
}

sub dmp_NET_ACTIVE_WINDOW {
    return dmpWMRootPropertyUint($_[0],_NET_ACTIVE_WINDOW=>active=>$_[1]);
}

=item B<set_NET_ACTIVE_WINDOW>(I<$X>,I<$active>)

The C<_NET_ACTIVE_WINDOW> property should only be set directly by a window manager.

=cut

sub set_NET_ACTIVE_WINDOW {
    return setWMRootPropertyUint($_[0],_NET_ACTIVE_WINDOW=>WINDOW=>$_[1]);
}

=item B<req_NET_ACTIVE_WINDOW>(I<$X>,I<$window>,I<$source>,I<$time>,I<$current>)

Sets C<$window> as the active window.  C<$source> is 1 for application,
or 2 for pager/taskbar.  C<$time> should be the time of the
KeyPress event that caused the activation.  C<$current> is the source's
currently active window (or zero if none).

 _NET_ACTIVE_WINDOW
   window = window to activate
   message_type = _NET_ACTIVE_WINDOW
   format = 32
   data.l[0] = source indication
   data.l[1] = time
   data.l[2] = requestor's currently active window, 0 if none
   other data.l[] elements = 0

=cut

sub req_NET_ACTIVE_WINDOW {
    my($X,$window,$source,$time,$current) = @_;
    $source = 2 unless defined $source;
    $source = name2val(NetSource=>NetSource(),$source);
    $current = 0 unless $current;
    $current = 0 if $current eq 'None';
    $time = 0 unless $time;
    $time = 0 if $time eq 'CurrentTime';
    NetClientMessage($X,$window,_NET_ACTIVE_WINDOW=>[$source,$time,$current]);
}

sub got_NET_ACTIVE_WINDOW {
    my($X,$window,$source,$time,$current) = @_;
    $source = val2name(NetSource=>NetSource(),$source);
    $current = 'None' unless $current;
    $time = 'CurrentTime' unless $time;
    return ($window,$source,$time,$current);
}

=back

=head3 _NET_WORKAREA, x, y, width, height CARDINAL[][4]/32

This property MUST be set by the Window Manager upon calculating the
work area for each desktop. Contains a geometry for each desktop. These
geometries are specified relative to the viewport on each desktop and
specify an area that is completely contained within the viewport. Work
area SHOULD be used by desktop applications to place desktop icons
appropriately.

The Window Manager SHOULD calculate this space by taking the current
page minus space occupied by dock and panel windows, as indicated by
the _NET_WM_STRUT or _NET_WM_STRUT_PARTIAL properties set on client
windows.

B<Note:> Window managers are inconsistent in their treatment of this
property:

=over

=item 1.

L<pekwm(1)> incorrectly only sets the work area for one desktop
regardless of the number of desktops.

=item 2.

L<icewm(1)> does not set the property at all, even though it
sets _WIN_WORKAREA.

=item 3.

L<wmaker(1)> does not set the property at all even when space is
reserved for the clip and dock.

=item 4.

L<afterstep(1)> does not set this property at all, even when displaying
its own panel.

=item 5.

L<jwm(1)> sets this property incorrectly to the full screen size
regardless of the fact that it has its own panel displayed.

=item 6.

L<fvwm(1)> sets this property incorrectly to the fulls screen size
regardless of when its own panel is being displayed.

=back

=over

=cut

=item B<get_NET_WORKAREA>(I<$X>,I<$root>) => I<$workarea>

Returns a reference to a list of (x,y) coordinates, width and height
that represents the work area, or C<undef> when no such property exists
on the root window.

=cut

sub get_NET_WORKAREA {
    my($X,$root) = @_;
    my $value = getWMRootPropertyInts($_[0],_NET_WORKAREA=>$_[1]);
    if ($value) {
	my $n = get_NET_NUMBER_OF_DESKTOPS($X,$root);
	$n = 1 unless $n;
	# this is for pekwm which only sets the first 4-tuple in the
	# array
	my $num = @$value;
	if ($num < ($n<<2)) {
	    for (my $i=0;$i<($n-($num>>2));$i++) {
		push @$value, @$value[0..3];
	    }
	}
    }
    return $value;
}

sub dmp_NET_WORKAREA {
    my($X,$workarea) = @_;
    return dmpWMRootPropertyDisplay($X,_NET_WORKAREA=>sub{
	my @vals = @$workarea;
	my $i = 0;
	while (@vals) {
	    printf "\t%-20s: (%d,%d),(%d,%d)\n",'desktop('.$i.')',splice(@vals,0,4); $i++;
	}
    });
}

=item B<set_NET_WORKAREA>(I<$X>,I<$workarea>)

The C<_NET_WORKAREA> property should only be set directly by a window manager.

=cut

sub set_NET_WORKAREA {
    return setWMRootPropertyInts($_[0],_NET_WORKAREA=>CARDINAL=>$_[1]);
}

=item B<req_NET_WORKAREA>(I<$X>,I<$x>,I<$y>,I<$w>,I<$h>)

Set the work area to that specified by the (x,y) coordinates, width and
height, C<$x>, C<$y>, C<$w>, C<$h>.  The property is set directly rather
than sending a client message.

=cut

sub req_NET_WORKAREA {
    my ($X,@vals) = @_;
    return set_NET_WORKAREA($X,\@vals);
}

=back

=head3 _NET_SUPPORTING_WM_CHECK, WINDOW/32

The Window Manager MUST set this property on the root window to be the
ID of a child window created by himself, to indicate that a compliant
window manager is active. The child window MUST also have the
_NET_SUPPORTING_WM_CHECK property set to the ID of the child window.
The child window MUST also have the _NET_WM_NAME property set to the
name of the Window Manager.

Rationale: The child window is used to distinguish an active Window
Manager from a stale _NET_SUPPORTING_WM_CHECK property that happens to
point to another window. If the _NET_SUPPORTING_WM_CHECK window on the
client window is missing or not properly set, clients SHOULD assume
that no conforming Window Manager is present.

=over

=cut

=item B<get_NET_SUPPORTING_WM_CHECK>(I<$X>,I<$window>) => I<$window>

Returns the supporting window manager check window, C<$window>, but only
when the property is properly set on both the root window and the check
window.  Returns C<undef> when there is no such property set on the root
window, or when it is impropertly set on the check window.

=cut

sub get_NET_SUPPORTING_WM_CHECK {
    return getWMRootPropertyRecursive($_[0],_NET_SUPPORTING_WM_CHECK=>$_[1]);
}

sub dmp_NET_SUPPORTING_WM_CHECK {
    return dmpWMPropertyUint($_[0],_NET_SUPPORTING_WM_CHECK=>check=>$_[1]);
}

=item B<set_NET_SUPPORTING_WM_CHECK>(I<$X>,I<$window>,I<$check>)

The C<_NET_SUPPORTING_WM_CHECK> property should only be set directly by a window manager.

=cut

sub set_NET_SUPPORTING_WM_CHECK {
    return setWMRootPropertyRecursive($_[0],_NET_SUPPORTING_WM_CHECK=>WINDOW=>$_[1]);
}

=back

=head3 _NET_VIRTUAL_ROOTS, WINDOW[]/32

To implement virtual desktops, some Window Managers reparent client
windows to a child of the root window. Window Managers using this
technique MUST set this property to a list of IDs for windows that are
acting as virtual root windows. This property allows background setting
programs to work with virtual roots and allows clients to figure out
the window manager frame windows of their windows.

=over

=cut

=item B<get_NET_VIRTUAL_ROOTS>(I<$X>,I<$root>) => I<$roots>

Returns a reference to the list of virtual root windows, or C<undef>
when no such property exists on the root window.

=cut

sub get_NET_VIRTUAL_ROOTS {
    my($X,$root) = @_;
    my $value = getWMRootPropertyUints($X,_NET_VIRTUAL_ROOTS=>$root);
    if ($value) {
	# AfterStep incorrectly puts the root window itself in
	# _NET_VIRTUAL ROOTS on the root window
	my @list = (@$value);
	my $ok = 1;
	foreach (@list) {
	    if ($_ == $root) {
		$value = undef;
		last;
	    }
	}
    }
    return $value;
}

sub dmp_NET_VIRTUAL_ROOTS {
    return dmpWMRootPropertyUints($_[0],_NET_VIRTUAL_ROOTS=>roots=>$_[1]);
}

=item B<set_NET_VIRTUAL_ROOTS>(I<$X>,I<$roots>)

The C<_NET_VIRTUAL_ROOTS> property should only be set directly by a window manager.

=cut

sub set_NET_VIRTUAL_ROOTS {
    return setWMRootPropertyUints($_[0],_NET_VIRTUAL_ROOTS=>WINDOW=>$_[1]);
}

=back

=head3 _NET_DESKTOP_LAYOUT, orientation, columns, rows, starting_corner CARDINAL[4]/32

 #define _NET_WM_ORIENTATION_HORZ 0
 #define _NET_WM_ORIENTATION_VERT 1

 #define _NET_WM_TOPLEFT     0
 #define _NET_WM_TOPRIGHT    1
 #define _NET_WM_BOTTOMRIGHT 2
 #define _NET_WM_BOTTOMLEFT  3

This property is set by a Pager, not by the Window Manager. When setting
this property, the Pager must own a manager selection (as defined in the
ICCCM 2.8). The manager selection is called _NET_DESKTOP_LAYOUT_Sn where
n is the screen number. The purpose of this property is to allow the
Window Manager to know the desktop layout displayed by the Pager.

_NET_DESKTOP_LAYOUT describes the layout of virtual desktops relative to
each other. More specifically, it describes the layout used by the owner
of the manager selection. The Window Manager may use this layout
information or may choose to ignore it. The property contains four
values: the Pager orientation, the number of desktops in the X
direction, the number in the Y direction, and the starting corner of the
layout, i.e. the corner containing the first desktop.

Note: In order to inter-operate with Pagers implementing an earlier
draft of this document, Window Managers should accept a
_NET_DESKTOP_LAYOUT property of length 3 and use _NET_WM_TOPLEFT as the
starting corner in this case.

The virtual desktops are arranged in a rectangle with rows rows and
columns columns. If rows times columns does not match the total number
of desktops as specified by _NET_NUMBER_OF_DESKTOPS, the
highest-numbered workspaces are assumed to be nonexistent. Either rows
or columns (but not both) may be specified as 0 in which case its actual
value will be derived from _NET_NUMBER_OF_DESKTOPS.

When the orientation is _NET_WM_ORIENTATION_HORZ the desktops are laid
out in rows, with the first desktop in the specified starting corner.
So a layout with four columns and three rows starting in the
_NET_WM_TOPLEFT corner looks like this:

 +--+--+--+--+
 | 0| 1| 2| 3|
 +--+--+--+--+
 | 4| 5| 6| 7|
 +--+--+--+--+
 | 8| 9|10|11|
 +--+--+--+--+

With starting_corner _NET_WM_BOTTOMRIGHT, it looks like this:

 +--+--+--+--+
 |11|10| 9| 8|
 +--+--+--+--+
 | 7| 6| 5| 4|
 +--+--+--+--+
 | 3| 2| 1| 0|
 +--+--+--+--+

When the orientation is _NET_WM_ORIENTATION_VERT the layout with four
columns and three rows starting in the _NET_WM_TOPLEFT corner looks
like:

 +--+--+--+--+
 | 0| 3| 6| 9|
 +--+--+--+--+
 | 1| 4| 7|10|
 +--+--+--+--+
 | 2| 5| 8|11|
 +--+--+--+--+

With starting_corner _NET_WM_TOPRIGHT, it looks like:

 +--+--+--+--+
 | 9| 6| 3| 0|
 +--+--+--+--+
 |10| 7| 4| 1|
 +--+--+--+--+
 |11| 8| 5| 2|
 +--+--+--+--+

The numbers here are the desktop numbers, as for _NET_CURRENT_DESKTOP.

=over

=cut

use constant {
    _NET_WM_ORIENTATION_HORZ => 0,
    _NET_WM_ORIENTATION_VERT => 1,

    NetOrientation=>[qw(
	    Horizontal
	    Vertical
	    )],

    _NET_WM_TOPLEFT     => 0,
    _NET_WM_TOPRIGHT    => 1,
    _NET_WM_BOTTOMRIGHT => 2,
    _NET_WM_BOTTOMLEFT  => 3,

    NetPosition=>[qw(
	    TopLeft
	    TopRight
	    BottomRight
	    BottomLeft
	    )],
};

=item B<get_NET_DESKTOP_LAYOUT>(I<$X>,I<$root>) => I<$layout>

Returns a reference to a list containing the orientation, C<$dir>,
number of rows and columns (C<$rows>,C<$cols>), and starting corner,
C<$start> describing the layout of desktops on a pager.

C<$dir> is one of:

    _NET_WM_ORIENTATION_HORZ => 0,
    _NET_WM_ORIENTATION_VERT => 1,

C<$start> is one of:

    _NET_WM_TOPLEFT     => 0,
    _NET_WM_TOPRIGHT    => 1,
    _NET_WM_BOTTOMRIGHT => 2,
    _NET_WM_BOTTOMLEFT  => 3,

=cut

sub get_NET_DESKTOP_LAYOUT {
    my($X,$root) = @_;
    return getWMRootPropertyDecode($X,_NET_DESKTOP_LAYOUT=>sub{
	    my @vals = unpack('L*',shift);
	    $vals[0] = 0 unless defined $vals[0];
	    $vals[0] = val2name(NetOrientation=>NetOrientation(),$vals[0]);
	    $vals[1] = 0 unless defined $vals[1];
	    $vals[2] = 1 unless defined $vals[2];
	    $vals[3] = 0 unless defined $vals[3];
	    $vals[3] = val2name(NetPosition=>NetPosition(),$vals[3]);
	    return {
		orientation=>$vals[0],
		columns=>$vals[1],
		rows=>$vals[2],
		starting_corner=>$vals[3] };
    },$root);
}

sub dmp_NET_DESKTOP_LAYOUT {
    return dmpWMRootPropertyHashUints($_[0],_NET_DESKTOP_LAYOUT=>[qw(
		orientation columns rows starting_corner)],$_[1]);
}

=item B<set_NET_DESKTOP_LAYOUT>(I<$X>,I<$layout>)

The C<_NET_DESKTOP_LAYOUT> property should only be set directly by a window manager.

=cut

sub set_NET_DESKTOP_LAYOUT {
    my($X,$layout) = @_;
    return setWMRootPropertyEncode($X,_NET_DESKTOP_LAYOUT=>sub{
	    my @vals = ();
	    if (ref $layout eq 'ARRAY') { @vals = @$layout }
	    elsif (ref $layout eq 'HASH') {
		push @vals, $layout->{orientation},
		            $layout->{columns},
			    $layout->{rows},
			    $layout->{starting_corner};
	    }
	    $vals[0] = 0 unless defined $vals[0];
	    $vals[0] = name2val(NetOrientation=>NetOrientation(),$vals[0]);
	    $vals[3] = 0 unless defined $vals[3];
	    $vals[3] = name2val(NetPosition=>NetPosition(),$vals[3]);
	    return CARDINAL=>32,pack('L*',@vals);
    });
}

=back

=head3 _NET_SHOWING_DESKTOP desktop, CARDINAL/32

Some Window Managers have a "showing the desktop" mode in which windows
are hidden, and the desktop background is displayed and focused. If a
Window Manager supports the _NET_SHOWING_DESKTOP hint, it MUST set it
to a value of 1 when the Window Manager is in "showing the desktop"
mode, and a value of zero if the Window Manager is not in this mode.

If a Pager wants to enter or leave the mode, it MUST send a
_NET_SHOWING_DESKTOP client message to the root window requesting the
change:

 _NET_SHOWING_DESKTOP
   message_type = _NET_SHOWING_DESKTOP
   format = 32
   data.l[0] = boolean 0 or 1
   other data.l[] elements = 0

The Window Manager may choose to ignore this client message.

=over

=cut

=item B<get_NET_SHOWING_DESKTOP>(I<$X>,I<$root>) => I<$bool>

Returns a boolean indicating whether the window manager is in I<showing
the desktop> mode or not, or C<undef> if this property is not defined on
the root window.

=cut

sub get_NET_SHOWING_DESKTOP {
    return getWMRootPropertyUint($_[0],_NET_SHOWING_DESKTOP=>$_[1]);
}

sub dmp_NET_SHOWING_DESKTOP {
    return dmpWMRootPropertyUint($_[0],_NET_SHOWING_DESKTOP=>showing=>$_[1]);
}

=item B<set_NET_SHOWING_DESKTOP>(I<$X>,I<$bool>)

The C<_NET_SHOWING_DESKTOP> property should only be set directly by a window manager.

=cut

sub set_NET_SHOWING_DESKTOP {
    return setWMRootPropertyUint($_[0],_NET_SHOWING_DESKTOP=>CARDINAL=>$_[1]?1:0);
}

=item B<req_NET_SHOWING_DESKTOP>(I<$X>,I<$bool>)

If a pager wants to enter or leave the showing desktop mode, it must
send a _NET_SHOWING_DESKTOP client message to the root window requesting
the change:

 _NET_SHOWING_DESKTOP
   message_type = _NET_SHOWING_DESKTOP
   format = 32
   data.l[0] = boolean 0 or 1
   other data.l[] elements = 0

=cut

sub req_NET_SHOWING_DESKTOP {
    my($X,$flag) = @_;
    NetClientMessage($X,$X->root,_NET_SHOWING_DESKTOP=>[$flag]);
}

sub got_NET_SHOWING_DESKTOP {
    my($X,$window,$flag) = @_;
    $flag = 0 unless $flag;
    return ($window,$flag);
}

=back

=head2 Other root window messages

Other root window messages are as follows:

=head3 _NET_CLOSE_WINDOW

Pagers wanting to close a window MUST send a _NET_CLOSE_WINDOW client
message request to the root window:

 _NET_CLOSE_WINDOW
   window = window to close
   message_type = _NET_CLOSE_WINDOW
   format = 32
   data.l[0] = time
   data.l[1] = source indication
   other data.l[] elements = 0

The Window Manager MUST then attempt to close the window specified. See
the section called "Source indication in requests" for details on the
source indication.

Rationale: A Window Manager might be more clever than the usual method
(send WM_DELETE message if the protocol is selected, XKillClient
otherwise). It might introduce a timeout, for example. Instead of
duplicating the code, the Window Manager can easily do the job.

=over

=cut

=item B<req_NET_CLOSE_WINDOW>(I<$X>,I<$window>,I<$time>,I<$source>)

Close a window.  For EWMH, send a _NET_CLOSE_WINDOW client message
request to the root window with the window to close, format 32 time
and source indication.

 _NET_CLOSE_WINDOW
   window = window to close
   message_type = _NET_CLOSE_WINDOW
   format = 32
   data.l[0] = time
   data.l[1] = source indication
   other data.l[] elements = 0

=cut

sub req_NET_CLOSE_WINDOW {
    my($X,$window,$time,$source) = @_;
    $source = 2 unless defined $source;
    $source = name2val(NetSource=>NetSource(),$source);
    $time = 0 unless $time;
    $time = 0 if $time eq 'CurrentTime';
    NetClientMessage($X,$window,_NET_CLOSE_WINDOW=>[$time,$source]);
}

sub got_NET_CLOSE_WINDOW {
    my($X,$window,$time,$source) = @_;
    $source = 2 unless defined $source;
    $source = val2name(NetSource=>NetSource(),$source);
    $time = 'CurrentTime' unless $time;
    return ($window,$time,$source);
}

=back

=head3 _NET_MOVERESIZE_WINDOW

 _NET_MOVERESIZE_WINDOW
   window = window to be moved or resized
   message_type = _NET_MOVERESIZE_WINDOW
   format = 32
   data.l[0] = gravity and flags
   data.l[1] = x
   data.l[2] = y
   data.l[3] = width
   data.l[4] = height

The low byte of data.l[0] contains the gravity to use; it may contain
any value allowed for the WM_SIZE_HINTS.win_gravity property: NorthWest
(1), North (2), NorthEast (3), West (4), Center (5), East (6),
SouthWest (7), South (8), SouthEast (9) and Static (10). A gravity of 0
indicates that the Window Manager should use the gravity specified in
WM_SIZE_HINTS.win_gravity. The bits 8 to 11 indicate the presence of x,
y, width and height. The bits 12 to 15 indicate the source (see the
section called "Source indication in requests"), so 0001 indicates the
application and 0010 indicates a Pager or a Taskbar. The remaining bits
should be set to zero.

Pagers wanting to move or resize a window may send a
_NET_MOVERESIZE_WINDOW client message request to the root window
instead of using a ConfigureRequest.

Window Managers should treat a _NET_MOVERESIZE_WINDOW message exactly
like a ConfigureRequest (in particular, adhering to the ICCCM rules
about synthetic ConfigureNotify events), except that they should use
the gravity specified in the message.

Rationale: Using a _NET_MOVERESIZE_WINDOW message with StaticGravity
allows Pagers to exactly position and resize a window including its
decorations without knowing the size of the decorations.

=over

=cut

=item B<req_NET_MOVERESIZE_WINDOW>(I<$X>,I<$window>,I<$gravity>,I<$source>,I<$x>,I<$y>,I<$width>,I<$height>)

Move or resize (or both) a window.

 _NET_MOVERESIZE_WINDOW
   window = window to be moved or resized
   message_type = _NET_MOVERESIZE_WINDOW
   format = 32
   data.l[0] = gravity | flags | source
   data.l[1] = x
   data.l[2] = y
   data.l[3] = width
   data.l[4] = height

 gravity = default(0), NW(1), N(2), NE(3), W(4), C(5), E(6), SW(7),
           S(8), SE(9), STATIC(10)
 flags = x(0x100)|y(0x200)|width(0x400)|height(0x800)
 source = application(0x1000), pager/taskbar(0x2000)

=cut

sub req_NET_MOVERESIZE_WINDOW {
    my($X,$window,$gravity,$source,$x,$y,$width,$height) = @_;
    $gravity = 0 unless $gravity;
    $gravity = name2val(WinGravity=>$X->{const}{WinGravity},$gravity);
    $source = 2 unless defined $source;
    $source = name2val(NetSource=>NetSource(),$source);
    my $flag = $gravity;
    $flag |= 0x100 if defined $x;
    $flag |= 0x200 if defined $y;
    $flag |= 0x400 if defined $width;
    $flag |= 0x800 if defined $height;
    $flag |= ($source<<12);
    $x = 0 unless $x;
    $y = 0 unless $y;
    $width = 0 unless $width;
    $height = 0 unless $height;
    NetClientMessage($X,$window,_NET_MOVERESIZE_WINDOW=>[$flag,$x,$y,$width,$height]);
}

sub got_NET_MOVERESIZE_WINDOW {
    my($X,$window,$flag,$x,$y,$width,$height) = @_;
    $flag = 0 unless $flag;
    my $source = $flag>>12;
    $source = 0 unless $source;
    $source = val2name(NetSource=>NetSource(),$source);
    my $gravity = $flag&0xff;
    $gravity = 0 unless $gravity;
    $gravity = val2name(WinGravity=>$X->{const}{WinGravity},$gravity);
    $flag &= 0xf00;
    $x = 0 unless $x;
    $y = 0 unless $y;
    $width = 0 unless $width;
    $height = 0 unless $height;
    $x = undef unless $flag&0x100;
    $y = undef unless $flag&0x200;
    $width = undef unless $flag&0x400;
    $height = undef unless $flag&0x800;
    return ($window,$gravity,$source,$x,$y,$width,$height);
}

=back

=head3 _NET_WM_MOVERESIZE

 _NET_WM_MOVERESIZE
   window = window to be moved or resized
   message_type = _NET_WM_MOVERESIZE
   format = 32
   data.l[0] = x_root
   data.l[1] = y_root
   data.l[2] = direction
   data.l[3] = button
   data.l[4] = source indication
 
This message allows Clients to initiate window movement or resizing.
They can define their own move and size "grips", whilst letting the
Window Manager control the actual operation. This means that all
moves/resizes can happen in a consistent manner as defined by the
Window Manager. See the section called "Source indication in requests"
for details on the source indication.

When sending this message in response to a button press event, button
SHOULD indicate the button which was pressed, x_root and y_root MUST
indicate the position of the button press with respect to the root
window and direction MUST indicate whether this is a move or resize
event, and if it is a resize event, which edges of the window the size
grip applies to. When sending this message in response to a key event,
the direction MUST indicate whether this this is a move or resize event
and the other fields are unused.

 _NET_WM_MOVERESIZE_SIZE_TOPLEFT     =>  0
 _NET_WM_MOVERESIZE_SIZE_TOP         =>  1
 _NET_WM_MOVERESIZE_SIZE_TOPRIGHT    =>  2
 _NET_WM_MOVERESIZE_SIZE_RIGHT       =>  3
 _NET_WM_MOVERESIZE_SIZE_BOTTOMRIGHT =>  4
 _NET_WM_MOVERESIZE_SIZE_BOTTOM      =>  5
 _NET_WM_MOVERESIZE_SIZE_BOTTOMLEFT  =>  6
 _NET_WM_MOVERESIZE_SIZE_LEFT        =>  7
 _NET_WM_MOVERESIZE_MOVE             =>  8   # movement only
 _NET_WM_MOVERESIZE_SIZE_KEYBOARD    =>  9   # size via keyboard
 _NET_WM_MOVERESIZE_MOVE_KEYBOARD    => 10   # move via keyboard
 _NET_WM_MOVERESIZE_CANCEL           => 11   # cancel operation

The Client MUST release all grabs prior to sending such message (except
for the _NET_WM_MOVERESIZE_CANCEL message).

The Window Manager can use the button field to determine the events on
which it terminates the operation initiated by the _NET_WM_MOVERESIZE
message. Since there is a race condition between a client sending the
_NET_WM_MOVERESIZE message and the user releasing the button, Window
Managers are advised to offer some other means to terminate the
operation, e.g. by pressing the ESC key. The special value
_NET_WM_MOVERESIZE_CANCEL also allows clients to cancel the operation
by sending such message if they detect the release themselves (clients
should send it if they get the button release after sending the move
resize message, indicating that the WM did not get a grab in time to
get the release).

=over

=cut

use constant {
    _NET_WM_MOVERESIZE_SIZE_TOPLEFT	=> 0,
    _NET_WM_MOVERESIZE_SIZE_TOP		=> 1,
    _NET_WM_MOVERESIZE_SIZE_TOPRIGHT	=> 2,
    _NET_WM_MOVERESIZE_SIZE_RIGHT	=> 3,
    _NET_WM_MOVERESIZE_SIZE_BOTTOMRIGHT	=> 4,
    _NET_WM_MOVERESIZE_SIZE_BOTTOM	=> 5,
    _NET_WM_MOVERESIZE_SIZE_BOTTOMLEFT	=> 6,
    _NET_WM_MOVERESIZE_SIZE_LEFT	=> 7,
    _NET_WM_MOVERESIZE_MOVE		=> 8,	# movement only
    _NET_WM_MOVERESIZE_SIZE_KEYBOARD	=> 9,	# size via keyboard
    _NET_WM_MOVERESIZE_MOVE_KEYBOARD	=> 10,	# move via keyboard
    _NET_WM_MOVERESIZE_CANCEL		=> 11,	# cancel operation

    NetMoveResize => [qw(
	    topleft
	    top
	    topright
	    right
	    bottomright
	    bottom
	    bottomleft
	    left
	    move
	    size_kbd
	    move_kbd
	    cancel
    )],
};

=item B<req_NET_WM_MOVERESIZE>(I<$X>,I<$window>,I<$x>,I<$y>,I<$direction>,I<$button>,I<$source>)

 _NET_WM_MOVERESIZE
   window = window to be moved or resized
   message_type = _NET_WM_MOVERESIZE
   format = 32
   data.l[0] = x_root
   data.l[1] = y_root
   data.l[2] = direction
   data.l[3] = button
   data.l[4] = source indication

 direction = topleft(0), top(1), topright(2), right(3), bottomright(4),
	     bottom(5), bottomleft(6), left(7), move(8), size_kbd(9),
	     move_kbd(10), cancel(11)

=cut

sub req_NET_WM_MOVERESIZE {
    my($X,$window,$x_root,$y_root,$direction,$button,$source) = @_;
    $x_root = 0 unless $x_root;
    $y_root = 0 unless $y_root;
    $direction = 11 unless defined $direction;
    $direction = name2val(NetMoveResize=>NetMoveResize(),$direction);
    $button = 0 unless $button;
    $source = 2 unless defined $source;
    $source = name2val(NetSource=>NetSource(),$source);
    NetClientMessage($X,$window,_NET_WM_MOVERESIZE=>[$x_root,$y_root,$direction,$button,$source]);
}

sub got_NET_WM_MOVERESIZE {
    my($X,$window,$x_root,$y_root,$direction,$button,$source) = @_;
    $x_root = 0 unless $x_root;
    $y_root = 0 unless $y_root;
    $direction = 0 unless $direction;
    $direction = val2name(NetMoveResize=>NetMoveResize(),$direction);
    $button = 0 unless $button;
    $source = 0 unless $source;
    $source = val2name(NetSource=>NetSource(),$source);
    return ($window,$x_root,$y_root,$direction,$button,$source);
}

=back

=head3 _NET_RESTACK_WINDOW

Pagers wanting to restack a window SHOULD send a _NET_RESTACK_WINDOW
client message request to the root window:

 _NET_RESTACK_WINDOW
   window = window to restack
   message_type = _NET_RESTACK_WINDOW
   format = 32
   data.l[0] = source indication
   data.l[1] = sibling window
   data.l[2] = detail
   other data.l[] elements = 0

This request is similar to ConfigureRequest with CWSibling and
CWStackMode flags. It should be used only by pagers, applications can
use normal ConfigureRequests. The source indication field should be
therefore set to 2, see the section called "Source indication in
requests" for details.

Rationale: A Window Manager may put restrictions on configure requests
from applications, for example it may under some conditions refuse to
raise a window. This request makes it clear it comes from a pager or
similar tool, and therefore the Window Manager should always obey it.

=over

=cut

use constant {
    _NET_RESTACK_WINDOW_ABOVE		=> 0,
    _NET_RESTACK_WINDOW_BELOW		=> 1,
    _NET_RESTACK_WINDOW_TOPIF		=> 2,
    _NET_RESTACK_WINDOW_BOTTOMIF	=> 3,
    _NET_RESTACK_WINDOW_OPPOSITE	=> 4,

    NetRestackWindow => [qw(
	    Above
	    Below
	    TopIf
	    BottomIf
	    Opposite
    )],
};

=item B<req_NET_RESTACK_WINDOW>(I<$X>,I<$window>,I<$detail>,I<$sibling>,I<$source>)

 _NET_RESTACK_WINDOW
   window = window to restack
   message_type = _NET_RESTACK_WINDOW
   format = 32
   data.l[0] = source indication
   data.l[1] = sibling window
   data.l[2] = detail: above(0), below(1), topif(2), bottomif(3), opposite(4)
   other data.l[] elements = 0

The window is restacked as follows:

=over

=item Above, _NET_RESTACK_WINDOW_ABOVE => 0

The window is placed just above the sibling.  When no sibling is
specified (set to zero), the window is placed at the top of the stack.

=item Below, _NET_RESTACK_WINDOW_BELOW => 1

The window is placed just below the sibling.  When no sibling is
specified (set to zero), the window is placed at the bottom of the
stack.

=item TopIf, _NET_RESTACK_WINDOW_TOPIF => 2

If the sibling occludes the window, then the window is placed at the top
of the stack.  When no sibling is specified, when any sibling occludes
the window, then the window is placed at the top of the stack.

=item BottomIf, _NET_RESTACK_WINDOW_BOTTOMIF => 3

If the window occludes the sibling, then the window is placed at the
bottom of the stack.  When no sibling is specified, when the window
occludes any sibling, then the window is placed at the bottom of the
stack.

=item Opposite, _NET_RESTACK_WINDOW_OPPOSITE => 4

If the sibling occludes the window, then the window is placed at the top
of the stack.  Otherwise, if the window occludes the sibling, then the
window is placed at the bottom of the stack.  When no sibling is
specified, if any sibling occludes the window, then the window is placed
at the top of the stack.  Otherwise, if the window occludes any sibling,
then the window is placed at the bottom of the stack.

=back

=cut

sub req_NET_RESTACK_WINDOW {
    my ($X,$window,$detail,$sibling,$source) = @_;
    $detail = 0 unless $detail;
    $detail = name2val(NetRestackWindow=>NetRestackWindow(),$detail);
    $source = 2 unless defined $source;
    $source = name2val(NetSource=>NetSource(),$source);
    $sibling = 0 unless $sibling;
    $sibling = 0 if $sibling eq 'None';
    NetClientMessage($X,$window,_NET_RESTACK_WINDOW=>[$source,$sibling,$detail]);
}

sub got_NET_RESTACK_WINDOW {
    my($X,$window,$source,$sibling,$detail) = @_;
    $source = 0 unless $source;
    $source = val2name(NetSource=>NetSource(),$source);
    $sibling = 'None' unless $sibling;
    $detail = 0 unless $detail;
    $detail = val2name(NetRestackWindow=>NetRestackWindow(),$detail);
    return ($X,$window,$detail,$sibling,$source);
}

=back

=head3 _NET_REQUEST_FRAME_EXTENTS

 _NET_REQUEST_FRAME_EXTENTS
   window = window for which to set _NET_FRAME_EXTENTS
   message_type = _NET_REQUEST_FRAME_EXTENTS

A Client whose window has not yet been mapped can request of the Window
Manager an estimate of the frame extents it will be given upon mapping.
To retrieve such an estimate, the Client MUST send a
_NET_REQUEST_FRAME_EXTENTS message to the root window. The Window
Manager MUST respond by estimating the prospective frame extents and
setting the window's _NET_FRAME_EXTENTS property accordingly. The
Client MUST handle the resulting _NET_FRAME_EXTENTS PropertyNotify
event. So that the Window Manager has a good basis for estimation, the
Client MUST set any window properties it intends to set before sending
this message. The Client MUST be able to cope with imperfect estimates.

Rationale: A client cannot calculate the dimensions of its window's
frame before the window is mapped, but some toolkits need this
information. Asking the window manager for an estimate of the extents
is a workable solution. The estimate may depend on the current theme,
font sizes or other window properties. The client can track changes to
the frame's dimensions by listening for _NET_FRAME_EXTENTS
PropertyNotify events.

=over

=cut

=item B<req_NET_REQUEST_FRAME_EXTENTS>(I<$X>,I<$window>)

Request the frame extents for the specified window, C<$window>.  This
issues the following client message:

 _NET_REQUEST_FRAME_EXTENTS
   window = windos for which to set _NET_FRAME_EXTENTS
   message_type = _NET_REQUEST_FRAME_EVENTS
   format = 32
   all data.l[] elements = 0

=cut

sub req_NET_REQUEST_FRAME_EXTENTS {
    my ($X,$window) = @_;
    NetClientMessage($X,$window,_NET_REQUEST_FRAME_EXTENTS=>[]);
}

sub got_NET_REQUEST_FRAME_EXTENTS {
    my ($X,$window) = @_;
    return ($window);
}

=back

=head2 Application window properties

The following are application window properties:

=head3 _NET_WM_NAME, UTF8_STRING

The Client SHOULD set this to the title of the window in UTF-8 encoding.
If set, the Window Manager should use this in preference to WM_NAME.
Note that the window manager must set C<_NET_WM_NAME> on the check
window (specified by the C<_NET_SUPPORTING_WM_CHECK> property on the
root window), however, at least one window manager does not do this:
L<wmaker(1)>.

=over

=cut

=item B<get_NET_WM_NAME>(I<$X>,I<$window>) => I<$name>

Returns the name associated with C<$window>, or C<undef> if the property
does not exist on C<$window>.

=cut

sub get_NET_WM_NAME {
    return getWMPropertyString($_[0],$_[1],_NET_WM_NAME=>);
}

sub dmp_NET_WM_NAME {
    return dmpWMPropertyString($_[0],_NET_WM_NAME=>name=>$_[1]);
}

=item B<set_NET_WM_NAME>(I<$X>,I<$window>,I<$name>)

The C<_NET_WM_NAME> property should only be set by a client.

=cut

sub set_NET_WM_NAME {
    return setWMPropertyString($_[0],$_[1],_NET_WM_NAME=>UTF8_STRING=>$_[2]);
}

=back

=head3 _NET_WM_VISIBLE_NAME, UTF8_STRING

If the Window Manager displays a window name other than _NET_WM_NAME the
Window Manager MUST set this to the title displayed in UTF-8 encoding.

Rationale: This property is for Window Managers that display a title
different from the _NET_WM_NAME or WM_NAME of the window (i.e. xterm
<1>, xterm <2>, ... is shown, but _NET_WM_NAME / WM_NAME is still xterm
for each window) thereby allowing Pagers to display the same title as
the Window Manager.

=over

=cut

=item B<get_NET_WM_VISIBLE_NAME>(I<$X>,I<$window>) => I<$name>

Returns the visible name for C<$window>, or C<undef> if no such property
exists on the window.

=cut

sub get_NET_WM_VISIBLE_NAME {
    return getWMPropertyString($_[0],$_[1],_NET_WM_VISIBLE_NAME=>);
}

sub dmp_NET_WM_VISIBLE_NAME {
    return dmpWMPropertyString($_[0],_NET_WM_VISIBLE_NAME=>name=>$_[1]);
}

=item B<set_NET_WM_VISIBLE_NAME>(I<$x>,I<$window>,I<$name>)

The C<_NET_WM_VISIBLE_NAME> property should only be set by a client.

=cut

sub set_NET_WM_VISIBLE_NAME {
    return setWMPropertyString($_[0],$_[1],_NET_WM_VISIBLE_NAME=>UTF8_STRING=>$_[2]);
}

=back

=head3 _NET_WM_ICON_NAME, UTF8_STRING

The Client SHOULD set this to the title of the icon for this window in
UTF-8 encoding. If set, the Window Manager should use this in preference
to WM_ICON_NAME.

=over

=cut

=item B<get_NET_WM_ICON_NAME>(I<$X>,I<$window>) => I<$name>

Gets the name of the icon for window C<$window>, or C<undef> if this
property is not specified on C<$window>.

=cut

sub get_NET_WM_ICON_NAME {
    return getWMPropertyString($_[0],$_[1],_NET_WM_ICON_NAME=>);
}

sub dmp_NET_WM_ICON_NAME {
    return dmpWMPropertyString($_[0],_NET_WM_ICON_NAME=>name=>$_[1]);
}

=item B<set_NET_WM_ICON_NAME>(I<$X>,I<$window>,I<$name>)

The C<_NET_WM_ICON_NAME> property should only be set by a client.

=cut

sub set_NET_WM_ICON_NAME {
    return setWMPropertyString($_[0],$_[1],_NET_WM_ICON_NAME=>UTF8_STRING=>$_[2]);
}

=back

=head3 _NET_WM_VISIBLE_ICON_NAME, UTF8_STRING

If the Window Manager displays an icon name other than
_NET_WM_ICON_NAME the Window Manager MUST set this to the title
displayed in UTF-8 encoding.

=over

=item B<get_NET_WM_VISIBLE_ICON_NAME>(I<$X>,I<$window>) => I<$name>

Returns the visiable name of the icon for window, C<$window>, or
C<undef> if no such propert exists in C<$window>.

=cut

sub get_NET_WM_VISIBLE_ICON_NAME {
    return getWMPropertyString($_[0],$_[1],_NET_WM_VISIBLE_ICON_NAME=>);
}

sub dmp_NET_WM_VISIBLE_ICON_NAME {
    return dmpWMPropertyString($_[0],_NET_WM_VISIBLE_ICON_NAME=>name=>$_[1]);
}

=item B<set_NET_WM_VISIBLE_ICON_NAME>(I<$X>,I<$window>,I<$name>)

The C<_NET_WM_VISIBLE_NAME> property should only be set by a client.

=cut

sub set_NET_WM_VISIBLE_ICON_NAME {
    return setWMPropertyString($_[0],$_[1],_NET_WM_VISIBLE_ICON_NAME=>UTF8_STRING=>$_[2]);
}

=back

Note that FVWM misspells this property as C<_NET_WM_ICON_VISIBLE_NAME>
instead of the newer C<_NET_WM_VISIBLE_ICON_NAME>.  The atom was renamed
as some point for consistency and FVWM has not followed suit.

=over

=item B<get_NET_WM_ICON_VISIBLE_NAME>(I<$X>,I<$window>) => I<$name>

Returns the visiable name of the icon for window, C<$window>, or
C<undef> if no such propert exists in C<$window>.

=cut

sub get_NET_WM_ICON_VISIBLE_NAME {
    return getWMPropertyString($_[0],$_[1],_NET_WM_ICON_VISIBLE_NAME=>);
}

sub dmp_NET_WM_ICON_VISIBLE_NAME {
    return dmpWMPropertyString($_[0],_NET_WM_ICON_VISIBLE_NAME=>name=>$_[1]);
}

=item B<set_NET_WM_ICON_VISIBLE_NAME>(I<$X>,I<$window>,I<$name>)

The C<_NET_WM_VISIBLE_NAME> property should only be set by a client.

=cut

sub set_NET_WM_ICON_VISIBLE_NAME {
    return setWMPropertyString($_[0],$_[1],_NET_WM_ICON_VISIBLE_NAME=>UTF8_STRING=>$_[2]);
}

=back

=head3 _NET_WM_DESKTOP desktop, CARDINAL/32

Cardinal to determine the desktop the window is in (or wants to be)
starting with 0 for the first desktop. A Client MAY choose not to set
this property, in which case the Window Manager SHOULD place it as it
wishes. 0xFFFFFFFF indicates that the window SHOULD appear on all
desktops.

The Window Manager should honor _NET_WM_DESKTOP whenever a withdrawn
window requests to be mapped.

The Window Manager should remove the property whenever a window is
withdrawn but it should leave the property in place when it is shutting
down, e.g. in response to losing ownership of the WM_Sn manager
selection.

Rationale: Removing the property upon window withdrawal helps legacy
applications which want to reuse withdrawn windows. Not removing the
property upon shutdown allows the next Window Manager to restore
windows to their previous desktops.

A Client can request a change of desktop for a non-withdrawn window by
sending a _NET_WM_DESKTOP client message to the root window:

 _NET_WM_DESKTOP
   window  = the respective client window
   message_type = _NET_WM_DESKTOP
   format = 32
   data.l[0] = new_desktop
   data.l[1] = source indication
   other data.l[] elements = 0

See the section called "Source indication in requests" for details on
the source indication. The Window Manager MUST keep this property
updated on all windows.

=over

=cut

=item B<get_NET_WM_DESKTOP>(I<$X>,I<$window>) => I<$desktop>

Returns the desktop index of the desktop associated with window,
C<$window>, or C<undef> if no such property exists on C<$window>.

=cut

sub get_NET_WM_DESKTOP {
    return getWMPropertyUint($_[0],$_[1],_NET_WM_DESKTOP=>);
}

sub dmp_NET_WM_DESKTOP {
    return dmpWMPropertyUint($_[0],_NET_WM_DESKTOP=>desktop=>$_[1]);
}

=item B<set_NET_WM_DESKTOP>(I<$X>,I<$window>,I<$desktop>)

The C<_NET_WM_DESKTOP> property should only be set by a client before
initial mapping of a top-level window or while a window is in the
withdrawn state.

=cut

sub set_NET_WM_DESKTOP {
    return setWMPropertyUint($_[0],$_[1],_NET_WM_DESKTOP=>CARDINAL=>$_[2]);
}

=item B<req_NET_WM_DESKTOP>(I<$X>,I<$window>, I<$desktop>, I<$source>)

A client can request a change of desktop for a non-withdrawn window by
sending a _NET_WM_DESKTOP client message to the root window.

=cut

sub req_NET_WM_DESKTOP {
    my ($X,$window,$index,$source) = @_;
    $index = 0 unless $index;
    $source = 2 unless defined $source;
    $source = name2val(NetSource=>NetSource(),$source);
    NetClientMessage($X,$window,_NET_WM_DESKTOP=>[$index,$source]);
}

sub got_NET_WM_DESKTOP {
    my($X,$window,$index,$source) = @_;
    $index = 0 unless $index;
    $source = 0 unless $source;
    $source = val2name(NetSource=>NetSource(),$source);
    return ($window,$index,$source);
}

=back

=head3 _NET_WM_WINDOW_TYPE, ATOM[]/32

This SHOULD be set by the Client before mapping to a list of atoms
indicating the functional type of the window. This property SHOULD be
used by the window manager in determining the decoration, stacking
position and other behavior of the window. The Client SHOULD specify
window types in order of preference (the first being most preferable)
but MUST include at least one of the basic window type atoms from the
list below. This is to allow for extension of the list of types whilst
providing default behavior for Window Managers that do not recognize
the extensions.

This hint SHOULD also be set for override-redirect windows to allow
compositing managers to apply consistent decorations to menus, tooltips
etc.

Rationale: This hint is intended to replace the MOTIF hints. One of the
objections to the MOTIF hints is that they are a purely visual
description of the window decoration. By describing the function of the
window, the Window Manager can apply consistent decoration and behavior
to windows of the same type. Possible examples of behavior include
keeping dock/panels on top or allowing pinnable menus / toolbars to
only be hidden when another window has focus (NextStep style).

    _NET_WM_WINDOW_TYPE_DESKTOP, ATOM
    _NET_WM_WINDOW_TYPE_DOCK, ATOM
    _NET_WM_WINDOW_TYPE_TOOLBAR, ATOM
    _NET_WM_WINDOW_TYPE_MENU, ATOM
    _NET_WM_WINDOW_TYPE_UTILITY, ATOM
    _NET_WM_WINDOW_TYPE_SPLASH, ATOM
    _NET_WM_WINDOW_TYPE_DIALOG, ATOM
    _NET_WM_WINDOW_TYPE_DROPDOWN_MENU, ATOM
    _NET_WM_WINDOW_TYPE_POPUP_MENU, ATOM
    _NET_WM_WINDOW_TYPE_TOOLTIP, ATOM
    _NET_WM_WINDOW_TYPE_NOTIFICATION, ATOM
    _NET_WM_WINDOW_TYPE_COMBO, ATOM
    _NET_WM_WINDOW_TYPE_DND, ATOM
    _NET_WM_WINDOW_TYPE_NORMAL, ATOM

=over

=item _NET_WM_WINDOW_TYPE_DESKTOP

indicates a desktop feature. This can include a single window containing
desktop icons with the same dimensions as the screen, allowing the
desktop environment to have full control of the desktop, without the
need for proxying root window clicks.

=item _NET_WM_WINDOW_TYPE_DOCK

indicates a dock or panel feature. Typically a Window Manager would keep
such windows on top of all other windows.

=item _NET_WM_WINDOW_TYPE_TOOLBAR and _NET_WM_WINDOW_TYPE_MENU

indicate toolbar and pinnable menu windows, respectively (i.e. toolbars
and menus "torn off" from the main application). Windows of this type
may set the WM_TRANSIENT_FOR hint indicating the main application
window.  Note that the _NET_WM_WINDOW_TYPE_MENU should be set on
torn-off managed windows, where _NET_WM_WINDOW_TYPE_DROPDOWN_MENU and
_NET_WM_WINDOW_TYPE_POPUP_MENU are typically used on override-redirect
windows.

=item _NET_WM_WINDOW_TYPE_UTILITY

indicates a small persistent utility window, such as a palette or
toolbox. It is distinct from type TOOLBAR because it does not correspond
to a toolbar torn off from the main application. It's distinct from type
DIALOG because it isn't a transient dialog, the user will probably keep
it open while they're working. Windows of this type may set the
WM_TRANSIENT_FOR hint indicating the main application window.

=item _NET_WM_WINDOW_TYPE_SPLASH

indicates that the window is a splash screen displayed as an application
is starting up.

=item _NET_WM_WINDOW_TYPE_DIALOG

indicates that this is a dialog window. If _NET_WM_WINDOW_TYPE is not
set, then managed windows with WM_TRANSIENT_FOR set MUST be taken as
this type. Override-redirect windows with WM_TRANSIENT_FOR, but without
_NET_WM_WINDOW_TYPE must be taken as _NET_WM_WINDOW_TYPE_NORMAL.

=item _NET_WM_WINDOW_TYPE_DROPDOWN_MENU

indicates that the window in question is a dropdown menu, ie., the kind
of menu that typically appears when the user clicks on a menubar, as
opposed to a popup menu which typically appears when the user
right-clicks on an object. This property is typically used on
override-redirect windows.

=item _NET_WM_WINDOW_TYPE_POPUP_MENU

indicates that the window in question is a popup menu, ie., the kind of
menu that typically appears when the user right clicks on an object, as
opposed to a dropdown menu which typically appears when the user clicks
on a menubar. This property is typically used on override-redirect
windows.

=item _NET_WM_WINDOW_TYPE_TOOLTIP

indicates that the window in question is a tooltip, ie., a short piece
of explanatory text that typically appear after the mouse cursor hovers
over an object for a while. This property is typically used on
override-redirect windows.

=item _NET_WM_WINDOW_TYPE_NOTIFICATION

indicates a notification. An example of a notification would be a bubble
appearing with informative text such as "Your laptop is running out of
power" etc. This property is typically used on override-redirect
windows.

=item _NET_WM_WINDOW_TYPE_COMBO

should be used on the windows that are popped up by combo boxes. An
example is a window that appears below a text field with a list of
suggested completions. This property is typically used on
override-redirect windows.

=item _NET_WM_WINDOW_TYPE_DND

indicates that the window is being dragged.  Clients should set this
hint when the window in question contains a representation of an object
being dragged from one place to another. An example would be a window
containing an icon that is being dragged from one file manager window to
another. This property is typically used on override-redirect windows.

=item _NET_WM_WINDOW_TYPE_NORMAL

indicates that this is a normal, top-level window, either managed or
override-redirect. Managed windows with neither _NET_WM_WINDOW_TYPE nor
WM_TRANSIENT_FOR set MUST be taken as this type. Override-redirect
windows without _NET_WM_WINDOW_TYPE, must be taken as this type, whether
or not they have WM_TRANSIENT_FOR set.

=back

=over

=cut

=item B<get_NET_WM_WINDOW_TYPE>(I<$X>,I<$window>) => I<$types>

Returns a reference to a hash of atom names associated with the window
type for C<$window>, or C<undef> if the window has no such property.

=cut

sub get_NET_WM_WINDOW_TYPE {
    return getWMPropertyAtoms($_[0],$_[1],_NET_WM_WINDOW_TYPE=>);
}

sub dmp_NET_WM_WINDOW_TYPE {
    return dmpWMPropertyAtoms($_[0],_NET_WM_WINDOW_TYPE=>type=>$_[1]);
}

=item B<set_NET_WM_WINDOW_TYPE>(I<$X>,I<$window>,I<$types>)

The C<_NET_WM_WINDOW_TYPE> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_WINDOW_TYPE {
    return setWMPropertyAtoms($_[0],$_[1],_NET_WM_WINDOW_TYPE=>$_[2]);
}

=back

=head3 _NET_WM_STATE, ATOM[]

A list of hints describing the window state. Atoms present in the list
MUST be considered set, atoms not present in the list MUST be
considered not set. The Window Manager SHOULD honor _NET_WM_STATE
whenever a withdrawn window requests to be mapped. A Client wishing to
change the state of a window MUST send a _NET_WM_STATE client message
to the root window (see below). The Window Manager MUST keep this
property updated to reflect the current state of the window.

The Window Manager should remove the property whenever a window is
withdrawn, but it should leave the property in place when it is
shutting down, e.g. in response to losing ownership of the WM_Sn
manager selection.

Rationale: Removing the property upon window withdrawal helps legacy
applications which want to reuse withdrawn windows. Not removing the
property upon shutdown allows the next Window Manager to restore
windows to their previous state.

Possible atoms are:

 _NET_WM_STATE_MODAL, ATOM
 _NET_WM_STATE_STICKY, ATOM
 _NET_WM_STATE_MAXIMIZED_VERT, ATOM
 _NET_WM_STATE_MAXIMIZED_HORZ, ATOM
 _NET_WM_STATE_SHADED, ATOM
 _NET_WM_STATE_SKIP_TASKBAR, ATOM
 _NET_WM_STATE_SKIP_PAGER, ATOM
 _NET_WM_STATE_HIDDEN, ATOM
 _NET_WM_STATE_FULLSCREEN, ATOM
 _NET_WM_STATE_ABOVE, ATOM
 _NET_WM_STATE_BELOW, ATOM
 _NET_WM_STATE_DEMANDS_ATTENTION, ATOM
 _NET_WM_STATE_FOCUSED, ATOM

An implementation MAY add new atoms to this list. Implementations
without extensions MUST ignore any unknown atoms, effectively removing
them from the list. These extension atoms MUST NOT start with the
prefix _NET.

=over

=item _NET_WM_STATE_MODAL

indicates that this is a modal dialog box. If the WM_TRANSIENT_FOR hint
is set to another toplevel window, the dialog is modal for that window;
if WM_TRANSIENT_FOR is not set or set to the root window the dialog is
modal for its window group.

=item _NET_WM_STATE_STICKY

indicates that the Window Manager SHOULD keep the window's position
fixed on the screen, even when the virtual desktop scrolls.

=item _NET_WM_STATE_MAXIMIZED_{VERT,HORZ}

indicates that the window is {vertically,horizontally} maximized.

=item _NET_WM_STATE_SHADED

indicates that the window is shaded.

=item _NET_WM_STATE_SKIP_TASKBAR

indicates that the window should not be included on a taskbar. This hint
should be requested by the application, i.e. it indicates that the
window by nature is never in the taskbar. Applications should not set
this hint if _NET_WM_WINDOW_TYPE already conveys the exact nature of the
window.

=item _NET_WM_STATE_SKIP_PAGER

indicates that the window should not be included on a Pager. This hint
should be requested by the application, i.e. it indicates that the
window by nature is never in the Pager.  Applications should not set
this hint if _NET_WM_WINDOW_TYPE already conveys the exact nature of the
window.

=item _NET_WM_STATE_HIDDEN

should be set by the Window Manager to indicate that a window would not
be visible on the screen if its desktop/viewport were active and its
coordinates were within the screen bounds. The canonical example is that
minimized windows should be in the _NET_WM_STATE_HIDDEN state. Pagers
and similar applications should use _NET_WM_STATE_HIDDEN instead of
WM_STATE to decide whether to display a window in miniature
representations of the windows on a desktop.

Implementation note: if an Application asks to toggle
_NET_WM_STATE_HIDDEN the Window Manager should probably just ignore the
request, since _NET_WM_STATE_HIDDEN is a function of some other aspect
of the window such as minimization, rather than an independent state.

=item _NET_WM_STATE_FULLSCREEN

indicates that the window should fill the entire screen and have no
window decorations. Additionally the Window Manager is responsible for
restoring the original geometry after a switch from fullscreen back to
normal window. For example, a presentation program would use this hint.

=item _NET_WM_STATE_ABOVE

indicates that the window should be on top of most windows (see the
section called "Stacking order" for details).

_NET_WM_STATE_ABOVE and _NET_WM_STATE_BELOW are mainly meant for user
preferences and should not be used by applications e.g. for drawing
attention to their dialogs (the Urgency hint should be used in that
case, see the section called "Urgency").'

=item _NET_WM_STATE_BELOW

indicates that the window should be below most windows (see the section
called "Stacking order" for details).

_NET_WM_STATE_ABOVE and _NET_WM_STATE_BELOW are mainly meant for user
preferences and should not be used by applications e.g. for drawing
attention to their dialogs (the Urgency hint should be used in that
case, see the section called "Urgency").'

=item _NET_WM_STATE_DEMANDS_ATTENTION

indicates that some action in or with the window happened. For example,
it may be set by the Window Manager if the window requested activation
but the Window Manager refused it, or the application may set it if it
finished some work. This state may be set by both the Client and the
Window Manager. It should be unset by the Window Manager when it decides
the window got the required attention (usually, that it got activated).

=item _NET_WM_STATE_FOCUSED

indicates whether the window's decorations are drawn in an active state.
Clients MUST regard it as a read-only hint.  It cannot be set at map
time or changed via a _NET_WM_STATE client message. The window given by
_NET_ACTIVE_WINDOW will usually have this hint, but at times other
windows may as well, if they have a strong association with the active
window and will be considered as a unit with it by the user. Clients
that modify the appearance of internal elements when a toplevel has
keyboard focus SHOULD check for the availability of this state in
_NET_SUPPORTED and, if it is available, use it in preference to tracking
focus via FocusIn events. By doing so they will match the window
decorations and accurately reflect the intentions of the Window Manager.

=back

To change the state of a mapped window, a Client MUST send a
_NET_WM_STATE client message to the root window:

 _NET_WM_STATE
   window  = the respective client window
   message_type = _NET_WM_STATE
   format = 32
   data.l[0] = the action, as listed below
   data.l[1] = first property to alter
   data.l[2] = second property to alter
   data.l[3] = source indication
   other data.l[] elements = 0

This message allows two properties to be changed simultaneously,
specifically to allow both horizontal and vertical maximization to
be altered together. l[2] MUST be set to zero if only one property is to
be changed. See the section called "Source indication in requests" for
details on the source indication. l[0], the action, MUST be one of:

 _NET_WM_STATE_REMOVE => 0  # remove/unset property
 _NET_WM_STATE_ADD    => 1  # add/set property
 _NET_WM_STATE_TOGGLE => 2  # toggle property

See also the implementation notes on urgency and fixed size windows.

=over

=cut

=item B<get_NET_WM_STATE>(I<$X>,I<$window>) => I<$states> or undef

Returns a hash reference to a hash with indices corresponding to the
names of the atoms associated with the window state for window,
C<$window>, or C<undef> if the property does not exist on C<$window>.

=cut

sub get_NET_WM_STATE {
    return getWMPropertyAtoms($_[0],$_[1],_NET_WM_STATE=>);
}

sub dmp_NET_WM_STATE {
    return dmpWMPropertyAtoms($_[0],_NET_WM_STATE=>state=>$_[1]);
}

=item B<set_NET_WM_STATE>(I<$X>,I<$window>,I<$states>)

Taks a hash reference, I<$states>, to a hash with keys corresponding to
the names of atoms associated with the window state for window,
I<$window>; or an array of atom names or numbers, or C<undef> to delete
the C<_NET_WM_STATE> property.

The C<_NET_WM_STATE> property should only be set directly by a window
manager, or by a client prior to initial mapping of a top-level window.
Clients should use req_NET_WM_STATE() after a window has been mapped to
request that the window manager alter the state.

=cut

sub set_NET_WM_STATE {
    return setWMPropertyAtoms($_[0],$_[1],_NET_WM_STATE=>$_[2]);
}

=item B<req_NET_WM_STATE>(I<$X>,I<$window>, I<$action>, I<$source>, I<$property1>, I<$property2>)

To change the state of a mapped window, the client must send a
_NET_WM_STATE client message to the root window:

 _NEW_WM_STATE
   window = the respective client window
   message_type = _NET_WM_STATE
   format = 32
   data.l[0] = the action: remove(0), add(1), toggle(2)
   data.l[1] = first property
   data.l[2] = second property
   data.l[3] = source indication
   other data.l[] elements = 0

This message allows two properties to be changed simulaneously,
specifically to allow both horizontal and vertical maximization to be
altered together.  l[2] must be set to zero if only one property is to
be changed.  The action must be one of:

=over

=item _NET_WM_STATE_REMOVE(0)

Remove or unset the property.

=item _NET_WM_STATE_ADD(1)

Add or set the property.

=item _NET_WM_STATE_TOGGLE(2)

Toggle the property.

=back

=cut

use constant {
    _NET_WM_STATE_REMOVE    => 0,
    _NET_WM_STATE_ADD	    => 1,
    _NET_WM_STATE_TOGGLE    => 2,

    NetStateAction => [qw(Remove Add Toggle)],
};

sub req_NET_WM_STATE {
    my ($X,$window,$action,$prop1,$prop2,$source) = @_;
    $action = 0 unless $action;
    $action = name2val(NetStateAction=>NetStateAction(),$action);
    $prop1 = 0 unless $prop1; $prop1 = ($prop1 =~ m{^\d+$}) ? $prop1 : $X->atom($prop1);
    $prop2 = 0 unless $prop2; $prop2 = ($prop2 =~ m{^\d+$}) ? $prop2 : $X->atom($prop2);
    $source = 2 unless defined $source;
    $source = name2val(NetSource=>NetSource(),$source);
    NetClientMessage($X,$window,_NET_WM_STATE=>[$action,$prop1,$prop2,$source]);
}

=back

=head3 _NET_WM_ALLOWED_ACTIONS, ATOM[]/32

A list of atoms indicating user operations that the Window Manager
supports for this window. Atoms present in the list indicate allowed
actions, atoms not present in the list indicate actions that are not
supported for this window. The Window Manager MUST keep this property
updated to reflect the actions which are currently "active" or
"sensitive" for a window. Taskbars, Pagers, and other tools use
_NET_WM_ALLOWED_ACTIONS to decide which actions should be made
available to the user.

Possible atoms are:

 _NET_WM_ACTION_MOVE, ATOM
 _NET_WM_ACTION_RESIZE, ATOM
 _NET_WM_ACTION_MINIMIZE, ATOM
 _NET_WM_ACTION_SHADE, ATOM
 _NET_WM_ACTION_STICK, ATOM
 _NET_WM_ACTION_MAXIMIZE_HORZ, ATOM
 _NET_WM_ACTION_MAXIMIZE_VERT, ATOM
 _NET_WM_ACTION_FULLSCREEN, ATOM
 _NET_WM_ACTION_CHANGE_DESKTOP, ATOM
 _NET_WM_ACTION_CLOSE, ATOM
 _NET_WM_ACTION_ABOVE, ATOM
 _NET_WM_ACTION_BELOW, ATOM

An implementation MAY add new atoms to this list. Implementations
without extensions MUST ignore any unknown atoms, effectively removing
them from the list. These extension atoms MUST NOT start with the
prefix _NET.

Note that the actions listed here are those that the Window Manager
will honor for this window. The operations must still be requested
through the normal mechanisms outlined in this specification. For
example, _NET_WM_ACTION_CLOSE does not mean that clients can send a
WM_DELETE_WINDOW message to this window; it means that clients can use
a _NET_CLOSE_WINDOW message to ask the Window Manager to do so.

Window Managers SHOULD ignore the value of _NET_WM_ALLOWED_ACTIONS when
they initially manage a window. This value may be left over from a
previous Window Manager with different policies.

=over

=item _NET_WM_ACTION_MOVE

indicates that the window may be moved around the screen.

=item _NET_WM_ACTION_RESIZE

indicates that the window may be resized.  (Implementation note: Window
Managers can identify a non-resizable window because its minimum and
maximum size in WM_NORMAL_HINTS will be the same.)

=item _NET_WM_ACTION_MINIMIZE

indicates that the window may be iconified.

=item _NET_WM_ACTION_SHADE

indicates that the window may be shaded.

=item _NET_WM_ACTION_STICK

indicates that the window may have its sticky state toggled (as for
_NET_WM_STATE_STICKY). Note that this state has to do with viewports,
not desktops.

=item _NET_WM_ACTION_MAXIMIZE_HORZ

indicates that the window may be maximized horizontally.

=item _NET_WM_ACTION_MAXIMIZE_VERT

indicates that the window may be maximized vertically.

=item _NET_WM_ACTION_FULLSCREEN

indicates that the window may be brought to fullscreen state.

=item _NET_WM_ACTION_CHANGE_DESKTOP

indicates that the window may be moved between desktops.

=item _NET_WM_ACTION_CLOSE

indicates that the window may be closed (i.e. a _NET_CLOSE_WINDOW
message may be sent).

=item _NET_WM_ACTION_ABOVE

indicates that the window may placed in the "above" layer of windows
(i.e. will respond to _NET_WM_STATE_ABOVE changes; see also the section
 called "Stacking order" for details).

=item _NET_WM_ACTION_BELOW

indicates that the window may placed in the "below" layer of windows
(i.e. will respond to _NET_WM_STATE_BELOW changes; see also the section
called "Stacking order" for details)).

=back

=over

=cut

=item B<get_NET_WM_ALLOWED_ACTIONS>(I<$X>,I<$window>) => I<$actions>

Returns a reference to a hash containing the atom names of allowed
acitions for C<$window> as indices, or C<undef> if no such property
exists on C<$window>.

=cut

sub get_NET_WM_ALLOWED_ACTIONS {
    return getWMPropertyAtoms($_[0],$_[1],_NET_WM_ALLOWED_ACTIONS=>);
}

sub dmp_NET_WM_ALLOWED_ACTIONS {
    return dmpWMPropertyAtoms($_[0],_NET_WM_ALLOWED_ACTIONS=>allowed=>$_[1]);
}

=item B<set_NET_WM_ALLOWED_ACTIONS>(I<$X>,I<$window>,I<$actions>)

The C<_NET_WM_ALLOWED_ACTIONS> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_ALLOWED_ACTIONS {
    return setWMPropertyAtoms($_[0],$_[1],_NET_WM_ALLOWED_ACTIONS=>$_[2]);
}

=back

=head3 _NET_WM_STRUT, left, right, top, bottom, CARDINAL[4]/32

This property is equivalent to a _NET_WM_STRUT_PARTIAL property where
all start values are 0 and all end values are the height or width of
the logical screen. _NET_WM_STRUT_PARTIAL was introduced later than
_NET_WM_STRUT, however, so clients MAY set this property in addition to
_NET_WM_STRUT_PARTIAL to ensure backward compatibility with Window
Managers supporting older versions of the Specification.

=over

=cut

=item ->B<get_NET_WM_STRUT>(I<$X>,I<$window>) => I<$strut>

Returns a reference to a hash of coordinates representing the strut for
window, I<$window>, or C<undef> if no C<_NET_WM_STRUT> property exists
on I<$window>.  I<$strut>, when defined, is a reference to an unsigned
integer valued hash containing the following keys:

 left    pixels reserved at the left of the screen
 right   pixels reserved at the right of the screen
 top     pixels reserved at the top of the screen
 bottom  pixels reserved at the bottom of the screen

=cut

sub get_NET_WM_STRUT {
    return getWMPropertyHashUints($_[0],$_[1],_NET_WM_STRUT=>[qw(left right top bottom)]);
}

sub dmp_NET_WM_STRUT {
    return dmpWMPropertyHashUints($_[0],_NET_WM_STRUT=>[qw(left right top bottom)],$_[1]);
}

=item B<set_NET_WM_STRUT>(I<$X>,I<$window>,I<$strut>)

Sets the C<_NET_WM_STRUT> property on window, I<$window>, to the strut
represented by I<$strut>, or, when I<$strut> is C<undef>, deletes the
C<_NET_WM_STRUT> property from I<$window>.  I<$strut>, when defined, can
be a reference to an unsigned integer valued hash containing the
following keys:

 left    pixels reserved at the left of the screen
 right   pixels reserved at the right of the screen
 top     pixels reserved at the top of the screen
 bottom  pixels reserved at the bottom of the screen

I<$strut> may also be a reference to an array of field values in the
order in which they appear above.

The C<_NET_WM_STRUT> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_STRUT {
    return setWMPropertyHashUints($_[0],$_[1],_NET_WM_STRUT=>CARDINAL=>[qw(left right top bottom)],$_[2]);
}

=back

=head3 _NET_WM_STRUT_PARTIAL, left, right, top, bottom, left_start_y, left_end_y,
right_start_y, right_end_y, top_start_x, top_end_x, bottom_start_x,
bottom_end_x,CARDINAL[12]/32

This property MUST be set by the Client if the window is to reserve
space at the edge of the screen. The property contains 4 cardinals
specifying the width of the reserved area at each border of the screen,
and an additional 8 cardinals specifying the beginning and end
corresponding to each of the four struts. The order of the values is
left, right, top, bottom, left_start_y, left_end_y, right_start_y,
right_end_y, top_start_x, top_end_x, bottom_start_x, bottom_end_x. All
coordinates are root window coordinates. The client MAY change this
property at any time, therefore the Window Manager MUST watch for
property notify events if the Window Manager uses this property to
assign special semantics to the window.

If both this property and the _NET_WM_STRUT property are set, the
Window Manager MUST ignore the _NET_WM_STRUT property values and use
instead the values for _NET_WM_STRUT_PARTIAL. This will ensure that
Clients can safely set both properties without giving up the improved
semantics of the new property.

The purpose of struts is to reserve space at the borders of the
desktop. This is very useful for a docking area, a taskbar or a panel,
for instance. The Window Manager should take this reserved area into
account when constraining window positions - maximized windows, for
example, should not cover that area.

The start and end values associated with each strut allow areas to be
reserved which do not span the entire width or height of the screen.
Struts MUST be specified in root window coordinates, that is, they are
not relative to the edges of any view port or Xinerama monitor.

For example, for a panel-style Client appearing at the bottom of the
screen, 50 pixels tall, and occupying the space from 200-600 pixels
from the left of the screen edge would set a bottom strut of 50, and
set bottom_start_x to 200 and bottom_end_x to 600. Another example is a
panel on a screen using the Xinerama extension. Assume that the set up
uses two monitors, one running at 1280x1024 and the other to the right
running at 1024x768, with the top edge of the two physical displays
aligned. If the panel wants to fill the entire bottom edge of the
smaller display with a panel 50 pixels tall, it should set a bottom
strut of 306, with bottom_start_x of 1280, and bottom_end_x of 2303.
Note that the strut is relative to the screen edge, and not the edge of
the xinerama monitor.

Rationale: A simple "do not cover" hint is not enough for dealing with
e.g. auto-hide panels.

Notes: An auto-hide panel SHOULD set the strut to be its minimum,
hidden size. A "corner" panel that does not extend for the full length
of a screen border SHOULD only set one strut.

=over

=cut

=item B<get_NET_WM_STRUT_PARTIAL>(I<$X>,I<$window>) => I<$partial>

Returns a reference to a list of coordinates describing the partial
strut for window, C<$window>, or C<undef> when the property does not
exist for C<$window>.

=cut

sub get_NET_WM_STRUT_PARTIAL {
    return getWMPropertyHashUints($_[0],$_[1],_NET_WM_STRUT_PARTIAL=>[qw(left right top bottom left_start_y left_end_y right_start_y right_end_y top_start_x top_end_x bottom_start_x bottom_end_x)]);
}

sub dmp_NET_WM_STRUT_PARTIAL {
    return dmpWMPropertyHashUints($_[0],_NET_WM_STRUT_PARTIAL=>[qw(left right top bottom left_start_y left_end_y right_start_y right_end_y top_start_x top_end_x bottom_start_x bottom_end_x)],$_[1]);
}

=item B<set_NET_WM_STRUT_PARTIAL>(I<$X>,I<$window>,I<$partial>)

The C<_NET_WM_STRUT_PARTIAL> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_STRUT_PARTIAL {
    return setWMPropertyHashUints($_[0],$_[1],_NET_WM_STRUT_PARTIAL=>CARDINAL=>[qw(left right top bottom left_start_y left_end_y right_start_y right_end_y top_start_x top_end_x bottom_start_x bottom_end_x)],$_[2]);
}

=back

=head3 _NET_WM_ICON_GEOMETRY, x, y, width, height, CARDINAL[4]/32

This optional property MAY be set by stand alone tools like a taskbar
or an iconbox. It specifies the geometry of a possible icon in case the
window is iconified.

Rationale: This makes it possible for a Window Manager to display a
nice animation like morphing the window into its icon.

=over

=cut

=item B<get_NET_WM_ICON_GEOMETRY>(I<$X>,I<$window>) => I<$geometry>

Returns a reference to a list of coordinates specifying the geometry of
the icon for window, C<$window>, or C<undef> if no such property exists
for C<$window>.

=cut

sub get_NET_WM_ICON_GEOMETRY {
    return getWMPropertyHashInts($_[0],$_[1],_NET_WM_ICON_GEOMETRY=>[qw(x y width height)]);
}

sub dmp_NET_WM_ICON_GEOMETRY {
    return dmpWMPropertyHashInts($_[0],_NET_WM_ICON_GEOMETRY=>[qw(x y width height)],$_[1]);
}

=item B<set_NET_WM_ICON_GEOMETRY>(I<$X>,I<$window>,I<$geometry>)

The C<_NET_WM_ICON_GEOMETRY> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_ICON_GEOMETRY {
    return setWMPropertyHashInts($_[0],$_[1],_NET_WM_ICON_GEOMETRY=>CARDINAL=>[qw(x y width height)]);
}

=back

=head3 _NET_WM_ICON CARDINAL[][2+n]/32

This is an array of possible icons for the client. This specification
does not stipulate what size these icons should be, but individual
desktop environments or toolkits may do so. The Window Manager MAY
scale any of these icons to an appropriate size.

This is an array of 32bit packed CARDINAL ARGB with high byte being A,
low byte being B. The first two cardinals are width, height. Data is in
rows, left to right and top to bottom.

=over

=cut

=item B<get_NET_WM_ICON>(I<$X>,I<$window>) => I<$icons>

Returns a reference to an array of data from this property for window,
C<$window>, or C<undef> when there is no such property associated with
window, C<$window>.

=cut

sub get_NET_WM_ICON {
    my($X,$window) = @_;
    return getWMPropertyDecode($X,$window,_NET_WM_ICON=>sub{
	    my @vals = unpack('L*',shift);
	    my @icons = ();
	    while (@vals) {
		my %icon = ();
		($icon{width},$icon{height}) = splice(@vals,0,2);
		$icon{width} = 0 unless $icon{width};
		$icon{height} = 0 unless $icon{height};
		$icon{data} = [ splice(@vals,0,$icon{width}*$icon{height}) ];
		push @icons, \%icon;
	    }
	    return \@icons;
    });
}

sub dmp_NET_WM_ICON {
    my($X,$icons) = @_;
    return dmpWMPropertyDisplay($X,_NET_WM_ICON=>sub{
	foreach my $icon (@$icons) {
	    foreach (qw(width height)) {
		printf "\t%-20s: %s\n",$_=>$icon->{$_};
	    }
	    printf "\t%-20s: %s\n",data=>join('',map{sprintf('%08x',$_)}@{$icon->{data}});
	}
    });
}

=item B<set_NET_WM_ICON>(I<$x>,I<$window>,I<$icons>)

The C<_NET_WM_ICON> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_ICON {
    my($X,$window,$icons) = @_;
    return setWMPropertyEncode($X,$window,_NET_WM_ICON=>sub{
	    my @vals = ();
	    foreach my $icon (@$icons) {
		next unless
		    $icon->{width} and
		    $icon->{height} and
		    scalar(@{$icon->{data}}) == $icon->{width}*$icon->{height};
		push @vals, $icon->{width}, $icon->{height}, @{$icon->{data}};
	    }
	    return CARDINAL=>32,pack('L*',@vals);
    });
}

=back

=head3 _NET_WM_PID CARDINAL/32

If set, this property MUST contain the process ID of the client owning
this window. This MAY be used by the Window Manager to kill windows
which do not respond to the _NET_WM_PING protocol.

If _NET_WM_PID is set, the ICCCM-specified property WM_CLIENT_MACHINE
MUST also be set. While the ICCCM only requests that WM_CLIENT_MACHINE
is set " to a string that forms the name of the machine running the
client as seen from the machine running the server" conformance to this
specification requires that WM_CLIENT_MACHINE be set to the
fully-qualified domain name of the client's host.

See also the implementation notes on killing hung processes.

=over

=cut

=item B<get_NET_WM_PID>(I<$X>,I<$window>) => I<$pid>

Returns the process id of the process associated with the window,
C<$window>, or C<undef> when no such property exists for C<$window>.

=cut

sub get_NET_WM_PID {
    return getWMPropertyUint($_[0],$_[1],_NET_WM_PID=>);
}

sub dmp_NET_WM_PID {
    return dmpWMPropertyUint($_[0],_NET_WM_PID=>pid=>$_[1]);
}

=item B<set_NET_WM_PID>(I<$X>,I<$window>,I<$pid>)

The C<_NET_WM_PID> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_PID {
    return setWMPropertyUint($_[0],$_[1],_NET_WM_PID=>CARDINAL=>$_[2]);
}

=back

=head3 _NET_WM_HANDLED_ICONS

This property can be set by a Pager on one of its own toplevel windows
to indicate that the Window Manager need not provide icons for
iconified windows, for example if it is a taskbar and provides buttons
for iconified windows.

=over

=cut

=item B<get_NET_WM_HANDLED_ICONS>(I<$X>,I<$window>) => I<$bool>

Returns a defined scalar value representing the presence of handled
icons for window, C<$window>, or C<undef> when no such property exists
for C<$window>.

=cut

sub get_NET_WM_HANDLED_ICONS {
    return getWMPropertyUint($_[0],$_[1],_NET_WM_HANDLED_ICONS=>);
}

sub dmp_NET_WM_HANDLED_ICONS {
    return dmpWMPropertyUint($_[0],_NET_WM_HANDLED_ICONS=>handled=>$_[1]);
}

=item B<set_NET_WM_HANDLED_ICONS>(I<$X>,I<$window>,I<$bool>)

The C<_NET_WM_HANDLED_ICONS> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_HANDLED_ICONS {
    return setWMPropertyUint($_[0],$_[1],_NET_WM_HANDLED_ICONS=>CARDINAL=>$_[2]);
}

=back

=head3 _NET_WM_USER_TIME CARDINAL/32

This property contains the XServer time at which last user activity in
this window took place.

Clients should set this property on every new toplevel window (or on
the window pointed out by the _NET_WM_USER_TIME_WINDOW property),
before mapping the window, to the time of the user interaction
that caused the window to appear. A client that only deals with core
events, might, for example, use the time of the last KeyPress or
ButtonPress event. ButtonRelease and KeyRelease events should not
generally be considered to be user interaction, because an application
may receive KeyRelease events from global keybindings, and generally
release events may have later time than actions that were
triggered by the matching press events. Clients can obtain the
time that caused its first window to appear from the
DESKTOP_STARTUP_ID environment variable, if the app was launched with
startup notification. If the client does not know the time of the
user interaction that caused the first window to appear (e.g. because
it was not launched with startup notification), then it should not set
the property for that window. The special value of zero on a newly
mapped window can be used to request that the window not be initially
focused when it is mapped.

If the client has the active window, it should also update this
property on the window whenever there's user activity.

Rationale: This property allows a Window Manager to alter the focus,
stacking, and/or placement behavior of windows when they are mapped
depending on whether the new window was created by a user action or is
a "pop-up" window activated by a timer or some other event.

=over

=cut

=item B<get_NET_WM_USER_TIME>(I<$X>,I<$window>) => I<$time>

Returns the user time associated with window, C<$window>, or C<undef> if
no such property is associated with C<$window>.

=cut

sub get_NET_WM_USER_TIME {
    return getWMPropertyUint($_[0],$_[1],_NET_WM_USER_TIME=>);
}

sub dmp_NET_WM_USER_TIME {
    return dmpWMPropertyUint($_[0],_NET_WM_USER_TIME=>time=>$_[1]);
}

=item B<set_NET_WM_USER_TIME>(I<$X>,I<$window>,I<$time>)

The C<_NET_WM_HANDLED_ICONS> property should only be set by a client.

=cut

sub set_NET_WM_USER_TIME {
    return setWMPropertyUint($_[0],$_[1],_NET_WM_USER_TIME=>CARDINAL=>$_[2]);
}

=back

=head3 _NET_WM_USER_TIME_WINDOW WINDOW/32

This property contains the XID of a window on which the client sets the
_NET_WM_USER_TIME property. Clients should check whether the window
manager supports _NET_WM_USER_TIME_WINDOW and fall back to setting the
_NET_WM_USER_TIME property on the toplevel window if it doesn't.

Rationale: Storing the frequently changing _NET_WM_USER_TIME property
on the toplevel window itself causes every application that is
interested in any of the properties of that window to be woken up on
every keypress, which is particularly bad for laptops running on
battery power.

=over

=cut

=item B<get_NET_WM_USER_TIME_WINDOW>(I<$X>,I<$window>) => I<$timewin>

Returns the window associated with the user time for window, C<$window>,
or C<undef> if no such property is associated with C<$window>.

=cut

sub get_NET_WM_USER_TIME_WINDOW {
    return getWMPropertyUint(@_[0..1],_NET_WM_USER_TIME_WINDOW=>);
}

sub dmp_NET_WM_USER_TIME_WINDOW {
    return dmpWMPropertyUint($_[0],_NET_WM_USER_TIME_WINDOW=>window=>$_[1]);
}

=item B<set_NET_WM_USER_TIME_WINDOW>(I<$X>,I<$window>,I<$timewin>)

The C<_NET_WM_USER_TIME_WINDOW> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_USER_TIME_WINDOW {
    return setWMPropertyUint(@_[0..1],_NET_WM_USER_TIME_WINDOW=>WINDOW=>$_[2]);
}

=back

=head3 _NET_FRAME_EXTENTS, left, right, top, bottom, CARDINAL[4]/32

The Window Manager MUST set _NET_FRAME_EXTENTS to the extents of the
window's frame. left, right, top and bottom are widths of the
respective borders added by the Window Manager.

=over

=cut

=item B<get_NET_FRAME_EXTENTS>(I<$X>,I<$window>) => I<$extents>

Returns a reference to the list of frame extents for window, C<$window>,
or C<undef> if no such property is associated with C<$window>.

=cut

sub get_NET_FRAME_EXTENTS {
    return getWMPropertyHashUints($_[0],$_[1],_NET_FRAME_EXTENTS=>[qw(left right top bottom)]);
}

sub dmp_NET_FRAME_EXTENTS {
    return dmpWMPropertyHashUints($_[0],_NET_FRAME_EXTENTS=>[qw(left right top bottom)],$_[1]);
}

=item B<set_NET_FRAME_EXTENTS>(I<$X>,I<$window>,I<$extents>)

The C<_NET_FRAME_EXTENTS> property should only be set directly by a window manager.

=cut

sub set_NET_FRAME_EXTENTS {
    return setWMPropertyHashUints($_[0],$_[1],_NET_FRAME_EXTENTS=>CARDINAL=>[qw(left right top bottom)],$_[2]);
}

=back

=head3 _NET_WM_OPAQUE_REGION, x, y, width, height, CARDINAL[][4]/32

The Client MAY set this property to a list of 4-tuples [x, y, width,
height], each representing a rectangle in window coordinates where the
pixels of the window's contents have a fully opaque alpha value. If the
window is drawn by the compositor without adding any transparency, then
such a rectangle will occlude whatever is drawn behind it. When the
window has an RGB visual rather than an ARGB visual, this property is
not typically useful, since the effective opaque region of a window is
exactly the bounding region of the window as set via the shape
extension. For windows with an ARGB visual and also a bounding region
set via the shape extension, the effective opaque region is given by
the intersection of the region set by this property and the bounding
region set via the shape extension. The compositing manager MAY ignore
this hint.

Rationale: This gives the compositing manager more room for
optimizations. For example, it can avoid drawing occluded portions
behind the window.

=over

=cut

=item B<get_NET_WM_OPAQUE_REGION>(I<$X>,I<$window>) => I<$region>

Returns a reference to a list of regions of opaque geometries for
window, C<$window>, or C<undef> if no such property is associated with
C<$window>.

=cut

sub get_NET_WM_OPAQUE_REGION {
    return getWMPropertyHashInts($_[0],$_[1],_NET_WM_OPAQUE_REGION=>[qw(x y width height)]);
}

sub dmp_NET_WM_OPAQUE_REGION {
    return dmpWMPropertyHashInts($_[0],_NET_WM_OPAQUE_REGION=>[qw(x y width height)],$_[1]);
}

=item B<set_NET_WM_OPAQUE_REGION>(I<$X>,I<$window>,I<$region>)

The C<_NET_WM_OPAQUE_REGION> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_OPAQUE_REGION {
    return setWMPropertyHashInts($_[0],$_[1],_NET_WM_OPAQUE_REGION=>CARDINAL=>[qw(x y width height)],$_[2]);
}

=back

=head3 _NET_WM_BYPASS_COMPOSITOR, CARDINAL/32

The Client MAY set this property to hint the compositor that the window
would benefit from running uncomposited (i.e not redirected offscreen)
or that the window might be hurt from being uncomposited. A value of 0
indicates no preference. A value of 1 hints the compositor to disabling
compositing of this window. A value of 2 hints the compositor to not
disabling compositing of this window. All other values are reserved and
should be treated the same as a value of 0. The compositing manager MAY
bypass compositing for both fullscreen and non-fullscreen windows if
bypassing is requested, but MUST NOT bypass if it would cause
differences from the composited appearance.

Rationale: Some applications like fullscreen games might want run
without the overhead of being redirected offscreen (to avoid extra
copies) and thus perform better. An application which creates pop-up
windows might always want to run composited to avoid exposes.

=over

=cut

use constant {
    _NET_BYPASS_NO_PREFERENCE	=> 0,
    _NET_BYPASS_DISABLE		=> 1,
    _NET_BYPASS_NO_DISABLE	=> 2,

    NetBypass=>[qw(
	    NoPreference
	    Disable
	    NoDisable
	    )],
};

=item B<get_NET_WM_BYPASS_COMPOSITOR>(I<$X>,I<$window>) => I<$hint>

Returns the scalar hint associated with window, C<$window>, or C<undef>
if no such property is associated with C<$window>.

=cut

sub get_NET_WM_BYPASS_COMPOSITOR {
    return getWMPropertyInterp($_[0],$_[1],_NET_WM_BYPASS_COMPOSITOR=>NetBypass=>NetBypass())
}

sub dmp_NET_WM_BYPASS_COMPOSITOR {
    return dmpWMPropertyInterp($_[0],_NET_WM_BYPASS_COMPOSITOR=>bypass=>$_[1])
}

=item B<set_NET_WM_BYPASS_COMPOSITOR>(I<$X>,I<$window>,I<$hint>)

The C<_NET_WM_BYPASS_COMPOSITOR> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_BYPASS_COMPOSITOR {
    return setWMPropertyInterp($_[0],$_[1],_NET_WM_BYPASS_COMPOSITOR=>CARDINAL=>NetBypass=>NetBypass(),$_[2]);
}

=back

=head2 Window manger protocols

The following are window manager protocols:

=head3 _NET_WM_FULLSCREEN_MONITORS, CARDINAL[4]/32

A read-only list of 4 monitor indices indicating the top, bottom, left,
and right edges of the window when the fullscreen state is enabled. The
indices are from the set returned by the Xinerama extension.

Windows transient for the window with _NET_WM_FULLSCREEN_MONITORS set,
such as those with type _NEW_WM_WINDOW_TYPE_DIALOG, are generally
expected to be positioned (e.g. centered) with respect to only one of
the monitors. This might be the monitor containing the mouse pointer or
the monitor containing the non-full-screen window.

A Client wishing to change this list MUST send a
_NET_WM_FULLSCREEN_MONITORS client message to the root window. The
Window Manager MUST keep this list updated to reflect the current state
of the window.

 _NET_WM_FULLSCREEN_MONITORS
   window  = the respective client window
   message_type = _NET_WM_FULLSCREEN_MONITORS
   format = 32
   data.l[0] = the monitor whose top edge defines the top edge of the fullscreen window
   data.l[1] = the monitor whose bottom edge defines the bottom edge of the fulls creen window
   data.l[2] = the monitor whose left edge defines the left edge of the fullscreen window
   data.l[3] = the monitor whose right edge defines the right edge of the fullscreen window
   data.l[4] = source indication

See the section called "Source indication in requests" for details on
the source indication.

Virtual machine software may use this hint to have a virtual operating
system instance that sees multiple monitors. The application window
stretches over several monitors, giving the appearance that these
monitors have been taken over by the guest virtual machine.

This hint might also be used by a movie or presentation application
allowing users to display the media spanned over several monitors.

In both cases, the application would have some user interface allowing
users to configure which monitors the application fullscreens to. The
window manager need not provide such an interface, though it could.

In the event of a change in monitor configuration, the application is
responsible for re-computing the monitors on which it wants to appear.
The window manager may continue using the same monitor indices as
before or simply clear the list, returning to "normal" fullscreen.

=over

=cut

=item B<get_NET_WM_FULLSCREEN_MONITORS>(I<$X>,I<$window>) => I<$monitors>

Returns a reference to a list of top, bottom, left and right monitors
for fullscreen operation for window, C<$window>, or C<undef> if no such
property is associated with C<$window>.

=cut

sub get_NET_WM_FULLSCREEN_MONITORS {
    return getWMPropertyHashUints($_[0],$_[1],_NET_WM_FULLSCREEN_MONITORS=>[qw(top bottom left right)]);
}

sub dmp_NET_WM_FULLSCREEN_MONITORS {
    return dmpWMPropertyHashUints($_[0],_NET_WM_FULLSCREEN_MONITORS=>[qw(top bottom left right)],$_[1]);
}

=item B<set_NET_WM_FULLSCREEN_MONITORS>(I<$X>,I<$window>,I<$monitors>)

The C<_NET_WM_FULLSCREEN_MONITORS> property should only be set by a client before
initial mapping of a top-level window.

=cut

sub set_NET_WM_FULLSCREEN_MONITORS {
    return setWMPropertyHashUints($_[0],$_[1],_NET_WM_FULLSCREEN_MONITORS=>CARDINAL=>[qw(top bottom left right)],$_[2]);
}

=item B<req_NET_WM_FULLSCREEN_MONITORS>(I<$X>,I<$window>,I<$t>,I<$b>,I<$l>,I<$r>,I<$source>)

Sets the top, bottom, left and right monitors for fullscreen operation
for window, C<$window>.

=cut

sub req_NET_WM_FULLSCREEN_MONITORS {
    my ($X,$window,$t,$b,$l,$r,$source) = @_;
    $t = 0 unless $t;
    $b = 0 unless $b;
    $l = 0 unless $l;
    $r = 0 unless $r;
    $source = 2 unless defined $source;
    $source = name2val(NetSource=>NetSource(),$source);
    NetClientMessage($X,$window,_NET_WM_FULLSCREEN_MONITORS=>[$t,$b,$l,$r,$source]);
}

=back

=head3 _NET_WM_WINDOW_OPACITY, CARDINAL/32

=over

=item B<get_NET_WM_WINDOW_OPACITY>(I<$X>,I<$window>) => I<$opacity> or undef

=cut

sub get_NET_WM_WINDOW_OPACITY {
    return getWMPropertyUint(@_[0..1],_NET_WM_WINDOW_OPACITY=>);
}

sub dmp_NET_WM_WINDOW_OPACITY {
    return dmpWMPropertyUint($_[0],_NET_WM_WINDOW_OPACITY=>opacity=>$_[1]);
}

=item B<set_NET_WM_WINDOW_OPACITY>(I<$X>,I<$window>,I<$opacity>)

=cut

sub set_NET_WM_WINDOW_OPACITY {
    return setWMPropertyUint(@_[0..1],_NET_WM_WINDOW_OPACITY=>CARDINAL=>$_[2]);
}

=back

=head3 _NET_WM_SYNC_REQUEST_COUNTER, CARDINAL/32

=over

=item B<get_NET_WM_SYNC_REQUEST_COUNTER>(I<$X>,I<$window>) => I<$opacity> or undef

=cut

sub get_NET_WM_SYNC_REQUEST_COUNTER {
    return getWMPropertyUint(@_[0..1],_NET_WM_SYNC_REQUEST_COUNTER=>);
}

sub dmp_NET_WM_SYNC_REQUEST_COUNTER {
    return dmpWMPropertyUint($_[0],_NET_WM_SYNC_REQUEST_COUNTER=>counter=>$_[1]);
}

=item B<set_NET_WM_SYNC_REQUEST_COUNTER>(I<$X>,I<$window>,I<$opacity>)

=cut

sub set_NET_WM_SYNC_REQUEST_COUNTER {
    return setWMPropertyUint(@_[0..1],_NET_WM_SYNC_REQUEST_COUNTER=>CARDINAL=>$_[2]);
}

=back

=head3 _NET_DESKTOP_PIXMAPS, PIXMAP[]/32

=over

=item B<get_NET_DESKTOP_PIXMAPS>(I<$X>,I<$root>) => I<$pixmaps> or undef

=cut

sub get_NET_DESKTOP_PIXMAPS {
    return getWMRootPropertyUints($_[0],_NET_DESKTOP_PIXMAPS=>$_[1]);
}

sub dmp_NET_DESKTOP_PIXMAPS {
    my($X,$pixmaps) = @_;
    return dmpWMRootPropertyDisplay($X,_NET_DESKTOP_PIXMAPS=>sub{
	printf "\t%-20s: %s\n",pixmaps=>join(', ',map{sprintf('0x%08x',$_)}@$pixmaps);
    });
}

=item B<set_NET_DESKTOP_PIXMAPS>(I<$X>,I<$pixmaps>)

=cut

sub set_NET_DESKTOP_PIXMAPS {
    return setWMRootPropertyUints($_[0],_NET_CLIENT_LIST=>PIXMAP=>$_[1]);
}

=back

=head3 _NET_SYSTEM_TRAY_ORIENTATION, orientation CARDINAL/32

The tray manager should set this hint on the selection owner window.

The property should be set by the tray manager to indicates the current
orientation of thet tray.  Tray icons may use this hint in order to
maintain the icon's aspect ration and also as an indication of how the
icon cntents should be laid out.

 #define _NET_SYSTEM_TRAY_ORIENTATION_HORZ 0
 #define _NET_SYSTEM_TRAY_ORIENTATION_VERT 1

=cut

use constant {
    _NET_SYSTEM_TRAY_ORIENTATION_HORZ	=> 0,
    _NET_SYSTEM_TRAY_ORIENTATION_VERT	=> 1,

    NetWMTrayOrientation => [qw(
	    Horizontal
	    Vertical
    )],
};

=over

=item B<get_NET_SYSTEM_TRAY_ORIENTATION>(I<$X>,I<$window>) => I<$orientation> or undef

=cut

sub get_NET_SYSTEM_TRAY_ORIENTATION {
    return getWMPropertyInterp(@_[0..1],_NET_SYSTEM_TRAY_ORIENTATION=>NetWMTrayOrientation=>NetWMTrayOrientation());
}

sub dmp_NET_SYSTEM_TRAY_ORIENTATION {
    return dmpWMPropertyInterp($_[0],_NET_SYSTEM_TRAY_ORIENTATION=>orientation=>$_[1]);
}

=item B<set_NET_SYSTEM_TRAY_ORIENTATION>(I<$X>,I<$window>,I<$orientation>)

=cut

sub set_NET_SYSTEM_TRAY_ORIENTATION {
    return setWMPropertyInterp(@_[0..1],_NET_SYSTEM_TRAY_ORIENTATION=>CARDINAL=>NetWMTrayOrientation=>NetWMTrayOrientation(),$_[2]);
}

=back

=head3 _NET_SYSTEM_TRAY_VISUAL visual_id VISUALID/32

The tray manager should set this hint on the selection owner window.

The property should be set by the tray manager to indicate the preferred
visual for icon windows.  To avoid ambiguity about the colormap to use
the visual must either be the default visual for the screen or it must
eb a TrueColor visual.  If this property is set to a visual with an
alpha channel, the tray manager must use the Composite extension to
composite the icon against the background using PictOpOver.

=over

=item B<get_NET_SYSTEM_TRAY_VISUAL>(I<$X>,I<$window>) => I<$visual_id> or undef

=cut

sub get_NET_SYSTEM_TRAY_VISUAL {
    return getWMPropertyUint(@_[0..1],_NET_SYSTEM_TRAY_VISUAL=>);
}

sub dmp_NET_SYSTEM_TRAY_VISUAL {
    return dmpWMPropertyUint($_[0],_NET_SYSTEM_TRAY_VISUAL=>visual_id=>$_[1]);
}

=item B<set_NET_SYSTEM_TRAY_VISUAL>(I<$X>,I<$window>,I<$visual_id>)

=cut

sub set_NET_SYSTEM_TRAY_VISUAL {
    return setWMPropertyUint(@_[0..1],_NET_SYSTEM_TRAY_VISUAL=>VISUALID=>$_[2]);
}

=back

=head3 _XEMBED_INFO

The protocol is started by the embedder. The window ID of the client
window is passed (by unspecified means) to the embedding application,
and the embedder calls XReparentWindow() to reparent the client window
into the embedder window.

Implementations may choose to support an alternate method of beginning
the protocol where the window ID of the embedder is passed to client
application and the client creates a window within the embedder, or
reparents an existing window into the embedder's window. Which method of
starting XEmbed is used a matter up to higher level agreement and
outside the scope of this specification.

In either case the client window must have a property called
_XEMBED_INFO on it. This property has type _XEMBED_INFO and format 32.
The contents of the property are:

 version  CARD32    the protocol version
 flags    CARD32    a bitfield of flags

The version field indicates the maximum version of the protocol that the
client supports.  The embedder should retrieve this field and set the
data2 difled of the XEMBED_EMBEDDED_NOTIFY to Min (version, max version
supported by embedder).  The version number corresponding to the current
verison of the protocol is 0.

The currently defined bit in the flag field is:

 #define XEMBED_MAPPED   (1<<0)

=over

=item XEMBED_MAPPED

If set the client should be mapped.  The embedder must track the flags
field by selecting the PropertyNotify events on the client and map and
unmap the client appropriately.  (The embedder can leave the client
unmapped when this bit is set, but should immediately unmap the client
upon detecting that the bit has been unset.)

=over

=item Rationale:

the reason for using this bit rather than MapRequest events is so that
the client can reliably control it's map state before the inception of
the protocol without worry that the client window will become visible as
a child of the root window.

=back

To support future expansion, all fields not currently defined must be
set to zero.  To add proprietary externsions to the XEMBED protocol, an
application must use a separate property, rather than using unused bits
in the struct field or extending the _XEMBED_INFO property.

At the start of the protocol, the embedder first sends an
XEMBED_EMBEDDED_NOTIFY message, then sends XEBMED_FOCUS_IN,
XEMBED_WINDOW_ACTIVATE, and XEMBED_MODALITY_ON messages as necessary to
synchronize the state of the client with that of the embedder.  Before
any of these messages are reecived, the state of the client is:

 Not focused
 Not active
 Modality off

If the embedder is geometry managed and can change its size, it should
obey the client's WMNormalHints settings. Note that most toolkits will
not have equivalents for all the hints in the WMNormalHints settings,
clients must not assume that the requested hints will be obeyed exactly.
The width_inc, height_inc, min_aspect, and max_aspect fields are
examples of fields from WMNormalHints that are unlikely to be supported
by embedders.

The protocol ends in one of three ways:

=over

=item 1.

The embedder can unmap the client and reparent the client window to the
root window. If the client receives an ReparentNotify event, it should
check the parent field of the XReparentEvent structure. If this is the
root window of the window's screen, then the protocol is finished and
there is no further interaction. If it is a window other than the root
window, then the protocol continues with the new parent acting as the
embedder window.

=item 2.

The client can reparent its window out of the embedder window. If the
embedder receives a ReparentNotify signal with the window field being
the current client and the parent field being a different window, this
indicates the end of the protocol.  [ GTK+ doesn't currently handle
this; but it seems useful to allow the protocol to be ended in a
non-destructive fashion from either end. ]

=item 3.

The client can destroy its window.

=back

=back

=over

=item B<get_XEMBED_INFO>(I<$X>,I<$window>) => I<$info> or undef

=cut

use constant {
    XEmbedInfo => [qw(
	    Mapped
    )],
};

sub get_XEMBED_INFO {
    return getWMPropertyDecode(@_[0..1],_XEMBED_INFO=>sub{
	    my($version,$flags) = unpack('LL',shift);
	    my %info = ();
	    $info{version} = $version;
	    $info{flags} = bits2names(XEmbedInfo=>XEmbedInfo(),$flags);
	    return \%info;
    });
}

sub dmp_XEMBED_INFO {
    return dmpWMPropertyHashUints($_[0],_XEMBED_INFO=>[qw(version flags)],$_[1]);
}

=item B<set_XEMBED_INFO>(I<$X>,I<$window>,I<$info>)

=cut

sub set_XEMBED_INFO {
    my $info = $_[2];
    return setWMPropertiesEncode(@_[0..1],_XEMBED_INFO=>sub{
	    my($version,$flags);
	    $version = $info->{version};
	    $version = 0 unless $version;
	    $flags = names2bits(XEmbedInfo=>XEmbedInfo(),$info->{flags});
	    $flags = 0 unless $flags;
	    return _XEMBED_INFO=>32,pack('LL',$version,$flags);
    });
}

=back

=cut

1;

__END__

=head2 Other properties

The following are other properties:

=head3 _NET_WM_FULL_PLACEMENT

By including this hint in _NET_SUPPORTED the Window Manager announces
that it performs reasonable window placement for all window types it
supports (for example centering dialogs on the mainwindow or whatever
handling the Window Manager considers reasonable). This in turn means
that Clients, when they detect that this hint is supported, SHOULD NOT
abuse or often even use PPosition and USPosition hints for requesting
placement. In particular:

=over

=item *

USPosition is reserved to be used only to indicate that the position was
specified by the user and MUST NOT be used for anything else (see ICCCM
section 4.1.2.3 for details)

=item *

PPosition SHOULD be used for for specifying position only if a specific
position should be used. Position SHOULD NOT be specified for "default"
placement such as centering dialog windows on their mainwindow.

=back

Rationale: Window managers can often perform better placement (that may
be even configurable) for windows than the application. However at the
time of writing this it is problematic for Window managers to decide
when to use them because many applications abuse positioning flags
and/or provide unnecessary default positions.

Note: The property is not used anywhere else besides being listed in
_NET_SUPPORTED.

=head1 WINDOW MANAGERS

This section provides the current state of compliance of the various
window managers supported by L<XDE(3pm)> with the EWMH specification, in
order of support:

=over

=item L<metacity(1)> EWMH(66:5) WMH(1:16)

=over

=item 1.

L<metacity(1)> does not list support for C<_NET_VIRTUAL_ROOTS>.

=item 2.

L<metacity(1)> does not list support for C<_NET_WM_FULL_PLACEMENT>.

=item 3.

L<metacity(1)> does not list support for C<_NET_HANDLED_ICONS>.

=item 4.

L<metacity(1)> does not list support for C<_NET_WM_SYNC_REQUEST_COUNTER>.

=item 5.

L<metacity(1)> does not list support for C<_NET_WM_SYNC_REQUEST>.

=item 6.

L<metacity(1)> does not list support for C<_NET_WM_VISIBLE_ICON_NAME>.

=item 7.

L<metacity(1)> does not list support for C<_NET_WM_VISIBLE_NAME>.

=item 8.

L<metacity(1)> does not list support for C<_NET_WM_TYPE_NOTIFICATION>.

=back

=item L<openbox(1)> EWMH(65:5) WMH(0:17)

=over

=item 1.

L<openbox(1)> does not list support for C<_NET_VIRTUAL_ROOTS>.

=item 2.

L<openbox(1)> does not list support for C<_NET_WM_ACTION_STICK>.

=item 3.

L<openbox(1)> does not list support for C<_NET_WM_FULLSCREEN_MONITORS>.

=item 4.

L<openbox(1)> does not list support for C<_NET_WM_HANDLED_ICONS>.

=item 5.

L<openbox(1)> does not list support for C<_NET_WM_PING>.

=item 6.

L<openbox(1)> does not list support for C<_NET_WM_STATE_STICKY>.

=item 7.

L<openbox(1)> does not list support for C<_NET_WM_USER_TIME_WINDOW>.

=item 8.

L<openbox(1)> does not list support for C<_NET_WM_TYPE_NOTIFICATION>.

=back

=item L<pekwm(1)> EWMH(55:16) WMH(0:17)

=over

=item 1.

L<pekwm(1)> does not list support for C<_NET_FRAME_EXTENTS>.

=item 2.

L<pekwm(1)> does not list support for C<_NET_MOVERESIZE_WINDOW>.

=item 3.

L<pekwm(1)> does not list support for C<_NET_REQUEST_FRAME_EXTENTS>.

=item 4.

L<pekwm(1)> does not list support for C<_NET_RESTACK_WINDOW>.

=item 5.

L<pekwm(1)> does not list support for C<_NET_SHOWING_DESKTOP>.

=item 6.

L<pekwm(1)> does not list support for C<_NET_STARTUP_ID>.

=item 7.

L<pekwm(1)> does not list support for C<_NET_VIRTUAL_ROOTS>.

=item 8.

L<pekwm(1)> does not list support for C<_NET_WM_ACTION_ABOVE>.

=item 9.

L<pekwm(1)> does not list support for C<_NET_WM_ACTION_BELOW>.

=item 10.

L<pekwm(1)> does not list support for C<_NET_WM_FULL_PLACEMENT>.

=item 11.

L<pekwm(1)> does not list support for C<_NET_WM_FULLSCREEN_MONITORS>.

=item 12.

L<pekwm(1)> does not list support for C<_NET_WM_MOVERESIZE>.

=item 13.

L<pekwm(1)> does not list support for C<_NET_WM_PING>.

=item 14.

L<pekwm(1)> does not list support for C<_NET_WM_STRUT_PARTIAL>.

=item 15.

L<pekwm(1)> does not list support for C<_NET_WM_SYNC_REQUEST_COUNTER>.

=item 16.

L<pekwm(1)> does not list support for C<_NET_WM_SYNC_REQUEST>.

=item 17.

L<pekwm(1)> does not list support for C<_NET_WM_USER_TIME>.

=item 18.

L<pekwm(1)> does not list support for C<_NET_WM_USER_TIME_WINDOW>.

=item 19.

L<pekwm(1)> does not list support for C<_NET_WM_WINDOW_TYPE_NOTIFICATION>.

=back

=item L<fluxbox(1)> EWMH(52:16) WMH(0:17)

=over

=item 1.

L<fluxbox(1)> does not list support for C<_NET_DESKTOP_LAYOUT>.

=item 2.

L<fluxbox(1)> does not list support for C<_NET_SHOWING_DESKTOP>.

=item 3.

L<fluxbox(1)> does not list support for C<_NET_STARTUP_ID>.

=item 4.

L<fluxbox(1)> does not list support for C<_NET_VIRTUAL_ROOTS>.

=item 5.

L<fluxbox(1)> does not list support for C<_NET_WM_ACTION_ABOVE>.

=item 6.

L<fluxbox(1)> does not list support for C<_NET_WM_ACTION_BELOW>.

=item 7.

L<fluxbox(1)> does not list support for C<_NET_WM_FULL_PLACEMENT>.

=item 8.

L<fluxbox(1)> does not list support for C<_NET_WM_FULLSCREEN_MONITORS>.

=item 9.

L<fluxbox(1)> does not list support for C<_NET_WM_HANDLED_ICONS>.

=item 10.

L<fluxbox(1)> does not list support for C<_NET_WM_ICON_GEOMETRY>.

=item 11.

L<fluxbox(1)> does not list support for C<_NET_WM_PID>.

=item 12.

L<fluxbox(1)> does not list support for C<_NET_WM_PING>.

=item 13.

L<fluxbox(1)> does not list support for C<_NET_WM_STATE_SKIP_PAGER>.

=item 14.

L<fluxbox(1)> does not list support for C<_NET_WM_STRUT_PARTIAL>.

=item 15.

L<fluxbox(1)> does not list support for C<_NET_WM_SYNC_REQUEST_COUNTER>.

=item 16.

L<fluxbox(1)> does not list support for C<_NET_WM_SYNC_REQUEST>.

=item 17.

L<fluxbox(1)> does not list support for C<_NET_WM_USER_TIME>.

=item 18.

L<fluxbox(1)> does not list support for C<_NET_WM_USER_TIME_WINDOW>.

=item 19.

L<fluxbox(1)> does not list support for C<_NET_WM_VISIBLE_ICON_NAME>.

=item 20.

L<fluxbox(1)> does not list support for C<_NET_WM_VISIBLE_NAME>.

=item 21.

L<fluxbox(1)> does not list support for C<_NET_WM_TYPE_NOTIFICAITON>.

=item 22.

L<fluxbox(1)> does not list support for C<_NET_WM_TYPE_UTILITY>.

=back

=item L<jwm(1)> EWMH(50:18) WMH(0:17)

L<jwm(1)> does not list support for C<_NET_DESKTOP_LAYOUT> even though it
provides a pager and the pager has a layout.

L<jwm(1)> does not list support for C<_NET_RESTACK_WINDOW>.

L<jwm(1)> is one of the few window managers that supports
C<_NET_SHOWING_DESKTOP>.

L<jwm(1)> unnecessarily places C<_NET_SUPPORTED> in C<_NET_SUPPORTED>.

L<jwm(1)> unnecessarily places C<_NET_SYSTEM_TRAY_OPCODE> in
C<_NET_SUPPORTED>.

L<jwm(1)> does not list support for C<_NET_WM_ACTION_FULLSCREEN>.

L<jwm(1)> does not report support for C<_NET_WM_FULL_PLACEMENT>, even
though it really does.

L<jwm(1)> does not list support for C<_NET_WM_FULLSCREEN_MONITORS>.

L<jwm(1)> does not report support C<_NET_WM_HANDLED_ICONS> even though
it essentially does (because it would never handle the icons itself
anyway).

L<jwm(1)> does not list support for C<_NET_WM_ICON_GEOMETRY> but it is optional
anyway.

L<jwm(1)> does not report support C<_NET_WM_ICON_NAME>, although it
essentially does (it supports C<WM_ICON_NAME>).

L<jwm(1)> does not list support for C<_NET_WM_MOVERESIZE>.

L<jwm(1)> does not report support for C<_NET_WM_PID> even though it
essentially does: support for killing hung processes is optional.

L<jwm(1)> does not list support for C<_NET_WM_PING>.

L<jwm(1)> does not list support for C<_NET_WM_STATE_DEMANDS_ATTENTION>.

L<jwm(1)> does not list support for C<_NET_WM_STATE_MODAL>.

L<jwm(1)> does not list support for C<_NET_WM_SYNC_REQUEST_COUNTER>.

L<jwm(1)> does not list support for C<_NET_WM_SYNC_REQUEST>.

L<jwm(1)> does not list support for C<_NET_WM_USER_TIME>.

L<jwm(1)> does not list support for C<_NET_WM_USER_TIME_WINDOW>.

L<jwm(1)> does not list support for C<_NET_VISIBLE_ICON_NAME>.

L<jwm(1)> does not list support for C<_NET_VISIBLE_NAME>.

L<jwm(1)> does not list support for C<_NET_WM_WINDOW_OPACITY>.

L<jwm(1)> does not list support for C<_NET_WM_WINDOW_TYPE_MENU>.

L<jwm(1)> does not list support for C<_NET_WM_WINWOW_TYPE_NOTIFICATION>.

L<jwm(1)> does not list support for C<_NET_WM_WINDOW_TYPE_TOOLBAR>.

L<jwm(1)> does not list support for C<_NET_WM_WINDOW_TYPE_UTILITY>.

=item L<fvwm(1)> EWMH(52:20) WMH(12:5)

=over

=item 1.

L<fvwm(1)> does not list support for C<_NET_DESKTOP_LAYOUT>.

=item 2.

L<fvwm(1)> does not list support for C<_NET_REQUEST_FRAME_EXTENTS>.

=item 3.

L<fvwm(1)> does not list support for C<_NET_SHOWING_DESKTOP>.

=item 4.

L<fvwm(1)> does not list support for C<_NET_STARTUP_ID>.

=item 5.

L<fvwm(1)> does not list support for C<_NET_WM_ACTION_ABOVE>.

=item 6.

L<fvwm(1)> does not list support for C<_NET_WM_ACTION_BELOW>.

=item 7.

L<fvwm(1)> does not list support for C<_NET_WM_FULL_PLACEMENT>.

=item 8.

L<fvwm(1)> does not list support for C<_NET_WM_FULLSCREEN_MONITORS>.

=item 9.

L<fvwm(1)> does not list support for C<_NET_WM_HANDLED_ICONS>.

=item 10.

L<fvwm(1)> does not list support for C<_NET_WM_STATE_ABOVE>.

=item 11.

L<fvwm(1)> does not list support for C<_NET_WM_STATE_DEMANDS_ATTENTION>.

=item 12.

L<fvwm(1)> does not list support for C<_NET_WM_STRUT_PARTIAL>.

=item 13.

L<fvwm(1)> does not list support for C<_NET_WM_SYNC_REQUEST_COUNTER>.

=item 14.

L<fvwm(1)> does not list support for C<_NET_WM_SYNC_REQUEST>.

=item 15.

L<fvwm(1)> does not list support for C<_NET_WM_USER_TIME>.

=item 16.

L<fvwm(1)> does not list support for C<_NET_WM_USER_TIME_WINDOW>.

=item 17.

L<fvwm(1)> does not list support for C<_NET_WM_VISIBLE_ICON_NAME>.

=item 18.

L<fvwm(1)> does not list support for C<_NET_WM_TYPE_SPLASH>.

=item 19.

L<fvwm(1)> does not list support for C<_NET_WM_TYPE_UTILITY>.

=back

=item L<wmaker(1)> EWMH(49:21) WMH(0:17)

=over

=item 1.

L<wmaker(1)> does not list support for C<_NET_CLOSE_WINDOW>.

=item 2.

L<wmaker(1)> does not list support for C<_NET_DESKTOP_LAYOUT>.

=item 3.

L<wmaker(1)> does not list support for C<_NET_MOVERESIZE_WINDOW>.

=item 4.

L<wmaker(1)> does not list support for C<_NET_REQUEST_FRAME_EXTENTS>.

=item 5.

L<wmaker(1)> does not list support for C<_NET_RESTACK_WINDOW>.

=item 6.

L<wmaker(1)> does not list support for C<_NET_STARTUP_ID>.

=item 7.

L<wmaker(1)> does not list support for C<_NET_VIRTUAL_ROOTS>.

=item 8.

L<wmaker(1)> does not list support for C<_NET_WM_ACTION_ABOVE>.

=item 9.

L<wmaker(1)> does not list support for C<_NET_WM_ACTION_BELOW>.

=item 10.

L<wmaker(1)> does not list support for C<_NET_WM_FULL_PLACEMENT>.

=item 11.

L<wmaker(1)> does not list support for C<_NET_WM_FULLSCREEN_MONITORS>.

=item 12.

L<wmaker(1)> does not list support for C<_NET_WM_MOVERESIZE>.

=item 13.

L<wmaker(1)> does not list support for C<_NET_WM_PID>.

=item 14.

L<wmaker(1)> does not list support for C<_NET_WM_STATE_DEMANDS_ATTENTION>.

=item 15.

L<wmaker(1)> does not list support for C<_NET_WM_STATE_MODAL>.

=item 16.

L<wmaker(1)> does not list support for C<_NET_WM_STRUT_PARTIAL>.

=item 17.

L<wmaker(1)> does not list support for C<_NET_WM_SYNC_REQUEST_COUNTER>.

=item 18.

L<wmaker(1)> does not list support for C<_NET_WM_SYNC_REQUEST>.

=item 19.

L<wmaker(1)> does not list support for C<_NET_WM_USER_TIME>.

=item 20.

L<wmaker(1)> does not list support for C<_NET_WM_USER_TIME_WINDOW>.

=item 21.

L<wmaker(1)> does not list support for C<_NET_WM_VISIBLE_ICON_NAME>.

=item 22.

L<wmaker(1)> does not list support for C<_NET_WM_VISIBLE_NAME>.

=item 23.

L<wmaker(1)> does not list support for C<_NET_WM_TYPE_NOTIFICATION>.

=item 24.

L<wmaker(1)> does not list support for C<_NET_WORKAREA>.

=back

=item L<blackbox(1)> EWMH(45:22) WMH(0:17)

=over

=item 1.

L<blackbox(1)> does not list support for C<_NET_DESKTOP_GEOMETRY>.

=item 2.

L<blackbox(1)> does not list support for C<_NET_DESKTOP_VIEWPORT>.

=item 3.

L<blackbox(1)> does not list support for C<_NET_FRAME_EXTENTS>.

=item 4.

L<blackbox(1)> does not list support for C<_NET_REQUEST_FRAME_EXTENTS>.

=item 5.

L<blackbox(1)> does not list support for C<_NET_RESTACK_WINDOW>.

=item 6.

L<blackbox(1)> does not list support for C<_NET_SHOWING_DESKTOP>.

=item 7.

L<blackbox(1)> does not list support for C<_NET_STARTUP_ID>.

=item 8.

L<blackbox(1)> does not list support for C<_NET_VIRTUAL_ROOTS>.

=item 9.

L<blackbox(1)> does not list support for C<_NET_WM_ACTION_ABOVE>.

=item 10.

L<blackbox(1)> does not list support for C<_NET_WM_ACTION_BELOW>.

=item 11.

L<blackbox(1)> does not list support for C<_NET_WM_ACTION_STICK>.

=item 12.

L<blackbox(1)> does not list support for C<_NET_WM_FULL_PLACEMENT>.

=item 13.

L<blackbox(1)> does not list support for C<_NET_WM_FULLSCREEN_MONITORS>.

=item 14.

L<blackbox(1)> does not list support for C<_NET_WM_HANDLED_ICONS>.

=item 15.

L<blackbox(1)> does not list support for C<_NET_WM_ICON_GEOMETRY>.

=item 16.

L<blackbox(1)> does not list support for C<_NET_WM_ICON>.

=item 17.

L<blackbox(1)> does not list support for C<_NET_WM_MOVERESIZE>.

=item 18.

L<blackbox(1)> does not list support for C<_NET_WM_PID>.

=item 19.

L<blackbox(1)> does not list support for C<_NET_WM_STATE_DEMANDS_ATTENTION>.

=item 20.

L<blackbox(1)> does not list support for C<_NET_WM_STATE_STICKY>.

=item 21.

L<blackbox(1)> does not list support for C<_NET_WM_STRUT_PARTIAL>.

=item 22.

L<blackbox(1)> does not list support for C<_NET_WM_SYNC_REQUEST_COUNTER>.

=item 23.

L<blackbox(1)> does not list support for C<_NET_WM_SYNC_REQUEST>.

=item 24.

L<blackbox(1)> does not list support for C<_NET_WM_USER_TIME>.

=item 25.

L<blackbox(1)> does not list support for C<_NET_WM_USER_TIME_WINDOW>.

=item 26.

L<blackbox(1)> does not list support for C<_NET_WM_WINDOW_TYPE_NOTIFICATION>.

=back

=item L<afterstep(1)> EWMH(29:42) WMH(?:17)

=over

=item 1.

L<afterstep(1)> does not list support for C<_NET_CLOSE_WINDOW>.

=item 2.

L<afterstep(1)> does not list support for C<_NET_DESKTOP_LAYOUT>.

=item 3.

L<afterstep(1)> does not list support for C<_NET_FRAME_EXTENTS>.

=item 4.

L<afterstep(1)> does not list support for C<_NET_MOVERESIZE_WINDOW>.

=item 5.

L<afterstep(1)> does not list support for C<_NET_REQUEST_FRAME_EXTENTS>.

=item 6.

L<afterstep(1)> does not list support for C<_NET_RESTACK_WINDOW>.

=item 7.

L<afterstep(1)> does not list support for C<_NET_SHOWING_DESKTOP>.

=item 8.

L<afterstep(1)> does not list support for C<_NET_STARTUP_ID>.

=item 9.

L<afterstep(1)> does not list support for C<_NET_VIRTUAL_ROOTS>.

=item 10.

L<afterstep(1)> does not list support for C<_NET_WM_ACTION_ABOVE>.

=item 11.

L<afterstep(1)> does not list support for C<_NET_WM_ACTION_BELOW>.

=item 12.

L<afterstep(1)> does not list support for C<_NET_WM_ACTION_CHANGE_DESKTOP>.

=item 13.

L<afterstep(1)> does not list support for C<_NET_WM_ACTION_CLOSE>.

=item 14.

L<afterstep(1)> does not list support for C<_NET_WM_ACTION_FULLSCREEN>.

=item 15.

L<afterstep(1)> does not list support for C<_NET_WM_ACTION_MAXIMIZE_HORZ>.

=item 16.

L<afterstep(1)> does not list support for C<_NET_WM_ACTION_MAXIMIZE_VERT>.

=item 17.

L<afterstep(1)> does not list support for C<_NET_WM_ACTION_MINIMIZE>.

=item 18.

L<afterstep(1)> does not list support for C<_NET_WM_ACTION_MOVE>.

=item 19.

L<afterstep(1)> does not list support for C<_NET_WM_ACTION_RESIZE>.

=item 20.

L<afterstep(1)> does not list support for C<_NET_WM_ACTION_SHADE>.

=item 21.

L<afterstep(1)> does not list support for C<_NET_WM_ACITON_STICK>.

=item 22.

L<afterstep(1)> does not list support for C<_NET_WM_ALLOWED_ACTIONS>.

=item 23.

L<afterstep(1)> does not list support for C<_NET_WM_FULL_PLACEMENT>.

=item 24.

L<afterstep(1)> does not list support for C<_NET_WM_FULLSCREEN_MONITORS>.

=item 25.

L<afterstep(1)> does not list support for C<_NET_WM_HANDLED_ICONS>.

=item 26.

L<afterstep(1)> does not list support for C<_NET_WM_ICON_GEOMETRY>.

=item 27.

L<afterstep(1)> does not list support for C<_NET_WM_ICON_NAME>.

=item 28.

L<afterstep(1)> does not list support for C<_NET_WM_NOVERESIZE>.

=item 29.

L<afterstep(1)> does not list support for C<_NET_WM_STATE_ABOVE>.

=item 30.

L<afterstep(1)> does not list support for C<_NET_WM_STATE_BELOW>.

=item 31.

L<afterstep(1)> does not list support for C<_NET_WM_STATE_DEMANDS_ATTENTION>.

=item 32.

L<afterstep(1)> does not list support for C<_NET_WM_STATE_FULLSCREEN>.

=item 33.

L<afterstep(1)> does not list support for C<_NET_WM_STATE_HIDDEN>.

=item 34.

L<afterstep(1)> does not list support for C<_NET_WM_STATE_SKIP_PAGER>.

=item 35.

L<afterstep(1)> does not list support for C<_NET_WM_STRUT_PARTIAL>.

=item 36.

L<afterstep(1)> does not list support for C<_NET_WM_STRUT>.

=item 37.

L<afterstep(1)> does not list support for C<_NET_WM_SYNC_REQUEST_COUNTER>.

=item 38.

L<afterstep(1)> does not list support for C<_NET_WM_SYNC_REQUEST>.

=item 39.

L<afterstep(1)> does not list support for C<_NET_WM_USER_TIME>.

=item 40.

L<afterstep(1)> does not list support for C<_NET_WM_USER_TIME_WINDOW>.

=item 41.

L<afterstep(1)> does not list support for C<_NET_WM_VISIBLE_ICON_NAME>.

=item 42.

L<afterstep(1)> does not list support for C<_NET_WM_VISIBLE_NAME>.

=item 43.

L<afterstep(1)> does not list support for C<_NET_WM_WINDOW_TYPE_NOTIFICATION>.

=item 44.

L<afterstep(1)> does not list support for C<_NET_WM_WINDOW_TYPE_SPLASH>.

=item 45.

L<afterstep(1)> does not list support for C<_NET_WM_WINDOW_TYPE_UTILITY>.

=item 46.

L<afterstep(1)> does not list support for C<_NET_WORKAREA>.

=back

=item L<icewm(1)> EWMH(21:46) WMH(14:2)

=over

=item 1.

L<icewm(1)> does not list support for C<_NET_DESKTOP_GEOMETRY>.

=item 2.

L<icewm(1)> does not list support for C<_NET_DESKTOP_LAYOUT>.

=item 3.

L<icewm(1)> does not list support for C<_NET_DESKTOP_NAMES>.

=item 4.

L<icewm(1)> does not list support for C<_NET_DESKTOP_VIEWPORT>.

=item 5.

L<icewm(1)> does not list support for C<_NET_FRAME_EXTENTS>.

=item 6.

L<icewm(1)> does not list support for C<_NET_MOVERESIZE_WINDOW>.

=item 7.

L<icewm(1)> does not list support for C<_NET_REQUEST_FRAME_EXTENTS>.

=item 8.

L<icewm(1)> does not list support for C<_NET_RESTACK_WINDOW>.

=item 9.

L<icewm(1)> does not list support for C<_NET_SHOWING_DESKTOP>.

=item 10.

L<icewm(1)> does not list support for C<_NET_STARTUP_ID>.

=item 11.

L<icewm(1)> does not list support for C<_NET_VIRTUAL_ROOTS>.

=item 12.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_ABOVE>.

=item 13.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_BELOW>.

=item 14.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_CHANGE_DESKTOP>.

=item 15.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_CLOSE>.

=item 16.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_FULLSCREEN>.

=item 17.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_MAXIMIZE_HORZ>.

=item 18.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_MAXIMIZE_VERT>.

=item 19.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_MINIMIZE>.

=item 20.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_MOVE>.

=item 21.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_RESIZE>.

=item 22.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_SHADE>.

=item 23.

L<icewm(1)> does not list support for C<_NET_WM_ACTION_STICK>.

=item 24.

L<icewm(1)> does not list support for C<_NET_WM_ALLOWED_ACTIONS>.

=item 25.

L<icewm(1)> does not list support for C<_NET_WM_FULL_PLACEMENT>.

=item 26.

L<icewm(1)> does not list support for C<_NET_WM_FULLSCREEN_MONITORS>.

=item 27.

L<icewm(1)> does not list support for C<_NET_WM_HANDLED_ICONS>.

=item 28.

L<icewm(1)> does not list support for C<_NET_WM_ICON_GEOMETRY>.

=item 29.

L<icewm(1)> does not list support for C<_NET_WM_ICON_NAME>.

=item 30.

L<icewm(1)> does not list support for C<_NET_WM_ICON>.

=item 31.

L<icewm(1)> does not list support for C<_NET_WM_MOVERESIZE>.

=item 32.

L<icewm(1)> does not list support for C<_NET_WM_NAME>.

=item 33.

L<icewm(1)> does not list support for C<_NET_WM_PID>.

=item 34.

L<icewm(1)> does not list support for C<_NET_WM_PING>.

=item 35.

L<icewm(1)> does not list support for C<_NET_WM_STATE_DEMANDS_ATTENTION>.

=item 36.

L<icewm(1)> does not list support for C<_NET_WM_STATE_HIDDEN>.

=item 37.

L<icewm(1)> does not list support for C<_NET_WM_STATE_MODAL>.

=item 38.

L<icewm(1)> does not list support for C<_NET_WM_SKIP_PAGER>.

=item 39.

L<icewm(1)> does not list support for C<_NET_WM_STATE_STICKY>.

=item 40.

L<icewm(1)> does not list support for C<_NET_WM_STRUT_PARTIAL>.

=item 41.

L<icewm(1)> does not list support for C<_NET_WM_SYNC_REQUEST_COUNTER>.

=item 42.

L<icewm(1)> does not list support for C<_NET_WM_SYNC_REQUEST>.

=item 43.

L<icewm(1)> does not list support for C<_NET_WM_USER_TIME>.

=item 44.

L<icewm(1)> does not list support for C<_NET_WM_USER_TIME_WINDOW>.

=item 45.

L<icewm(1)> does not list support for C<_NET_WM_VISIBLE_ICON_NAME>.

=item 46.

L<icewm(1)> does not list support for C<_NET_WM_VISIBLE_NAME>.

=item 47.

L<icewm(1)> does not list support for C<_NET_WM_WINDOW_TYPE_DIALOG>.

=item 48.

L<icewm(1)> does not list support for C<_NET_WM_WINDOW_TYPE_MENU>.

=item 49.

L<icewm(1)> does not list support for C<_NET_WM_WINDOW_TYPE_NORMAL>.

=item 50.

L<icewm(1)> does not list support for C<_NET_WM_WINDOW_TYPE_NOTIFICATION>.

=item 51.

L<icewm(1)> does not list support for C<_NET_WM_TYPE_TOOLBAR>.

=item 52.

L<icewm(1)> does not list support for C<_NET_WM_TYPE_UTILITY>.

=item 53.

L<icewm(1)> does not list support for C<_NET_WM_WINDOW_TYPE>.

=item 54.

L<icewm(1)> does not list support for C<_NET_WORKAREA>.

=back

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72



