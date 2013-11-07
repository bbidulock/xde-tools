package X11::Protocol::WMH;
use X11::Protocol::Util  qw(:all);
use X11::Protocol::ICCCM qw(:all);
use X11::Protocol;
use X11::AtomConstants;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

%EXPORT_TAGS = (
    all => [qw(
	WinClientMessage
	get_WIN_SUPPORTING_WM_CHECK
	dmp_WIN_SUPPORTING_WM_CHECK
	set_WIN_SUPPORTING_WM_CHECK
	get_WIN_PROTOCOLS
	dmp_WIN_PROTOCOLS
	set_WIN_PROTOCOLS
	get_WIN_CLIENT_LIST
	dmp_WIN_CLIENT_LIST
	set_WIN_CLIENT_LIST
	get_WIN_WORKSPACE
	dmp_WIN_WORKSPACE
	set_WIN_WORKSPACE
	req_WIN_WORKSPACE
	got_WIN_WORKSPACE
	get_WIN_WORKSPACE_COUNT
	dmp_WIN_WORKSPACE_COUNT
	set_WIN_WORKSPACE_COUNT
	get_WIN_WORKSPACE_NAMES
	dmp_WIN_WORKSPACE_NAMES
	set_WIN_WORKSPACE_NAMES
	get_WIN_WORKAREA
	dmp_WIN_WORKAREA
	set_WIN_WORKAREA
	get_WIN_CLIENT_MOVING
	dmp_WIN_CLIENT_MOVING
	set_WIN_CLIENT_MOVING
	get_WIN_STATE
	dmp_WIN_STATE
	set_WIN_STATE
	req_WIN_STATE
	event_handler_ClientMessage_WIN_STATE
	got_WIN_STATE
	get_WIN_HINTS
	dmp_WIN_HINTS
	set_WIN_HINTS
	req_WIN_HINTS
	got_WIN_HINTS
	get_WIN_LAYER
	dmp_WIN_LAYER
	set_WIN_LAYER
	req_WIN_LAYER
	got_WIN_LAYER
	get_WIN_WORKSPACES 
	dmp_WIN_WORKSPACES
	set_WIN_WORKSPACES
	req_WIN_WORKSPACES
	got_WIN_WORKSPACES_ADD
	got_WIN_WORKSPACES_REMOVE
	get_WIN_EXPANDED_SIZE
	dmp_WIN_EXPANDED_SIZE
	set_WIN_EXPANDED_SIZE
	get_WIN_ICONS
	dmp_WIN_ICONS
	set_WIND_ICONS
	get_WIN_APP_STATE
	dmp_WIN_APP_STATE
	set_WIN_APP_STATE
	get_WIN_DESKTOP_BUTTON_PROXY
	dmp_WIN_DESKTOP_BUTTON_PROXY
	set_WIN_DESKTOP_BUTTON_PROXY
	get_WIN_AREA_COUNT
	dmp_WIN_AREA_COUNT
	set_WIN_AREA_COUNT
	get_WIN_AREA
	dmp_WIN_AREA
	set_WIN_AREA
	req_WIN_AREA
	got_WIN_AREA
    )],
    req => [qw(
	WinClientMessage
    )],
);

=head1 NAME

XDE::WMH -- provides methods for controlling window manager hints.

=head1 SYNOPSIS

 use X11::Protocol::WMH;

 my $wmh = X11::Protocol::WMH->new();

 $wmh->get_WIN_WORKSPACE();

=head1 DESCRIPTION

Provides a module with methods that can be used to control a WMH
compliant window manager.  Note: not all that many window managers are
WMH compliant anymore.  Many that are EWMH compliant have removed
support for WMH (like L<fluxbox(1)>).  Several that support
C<_WIN_DESKTOP_BUTTON_PROXY>, such as L<icewm(1)>, L<fvwm(1)>,
L<metacity(1)> still support WMH; however, L<icewm(1)> has not
received any development in some years.  L<fvwm(1)> may be the only
XDE-supported window manager that continues to be WMH compliant.

=head1 METHODS

The following methods are provided by this module.

=item B<WinClientMessage>(I<$X>,I<$window>,I<$type>,I<$data>)

=cut

sub WinClientMessage {
    my($X,$window,$type,$data) = @_;
    $window = 0 unless defined $window;
    $window = 0 if $window eq 'None';
    $window = $X->root unless $window;
    $type = ($type =~ m{^\d+$}) ? $type : $X->atom($type);
    $data = pack('LLLLL',@$data) if ref $data eq 'ARRAY';
    $X->SendEvent($X->root, 0,
	    $X->pack_event_mask('SubstructureNotify'),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$window,
		type=>$type,
		format=>32,
		data=>$data));
}

=head2 Detection of a GNOME compliant Window Manager

=head3 _WIN_SUPPORTING_WM_CHECK, CARDINAL/32

There is a single unambiguous way to detect if there currently is a GNOME
compliant Window Manager running.  It is the job of the Window Manager
to set up a few things to make this possible.  Using the following method
it is also possible for applications to detect compliance by receiving
an event when the Window Manager exits.

To do this the Window Manager should create a Window, that is a child of
the root window.  There is no need to map it, just create it.  The
Window Manager may reuse ANY window it has for this purpose - even if it
is mapped, just as long as the window is never destroyed while the
Window Manager is running.

Once the Window is created the Window Manager should set a property on
the root window of the name _WIN_SUPPORTING_WM_CHECK, and type CARDINAL.
The atom's data would be a CARDINAL that is the Window ID of the window
that was created above.  The window that was created would ALSO have
this property set on it with the same values and type.

=over

=cut

=item B<get_WIN_SUPPORTING_WM_CHECK>(I<$X>,I<$window>) => I<$check> or undef

Returns the supporting window manager check window, I<$check>, or
C<undef> when no such window exists.  This method can support a certain
amount of race condition.

=cut

sub get_WIN_SUPPORTING_WM_CHECK {
    return getWMRootPropertyRecursive($_[0],_WIN_SUPPORTING_WM_CHECK=>$_[1]);
}

=item B<set_WIN_SUPPORTING_WM_CHECK>(I<$X>,I<$check>)

Sets the supporting window manager check window by setting the
C<_WIN_SUPPORTING_WM_CHECK> property on both the window, I<$check>, and
the root window for I<$check>.  Only a window manager that owns the
C<WM_Sn> selection should call this function.

=cut

sub set_WIN_SUPPORTING_WM_CHECK {
    return setWMRootPropertyRecursive($_[0],_WIN_SUPPORTING_WM_CHECK=>WINDOW=>$_[1]);
}

=item B<dmp_WIN_SUPPORTING_WM_CHECK>(I<$X>,I<$check>)

Prints to standard output the value of get_WIN_SUPPORTING_WM_CHECK().

=cut

sub dmp_WIN_SUPPORTING_WM_CHECK {
    return dmpWMRootPropertyUint($_[0],_WIN_SUPPORTING_WM_CHECK=>check=>$_[1]);
}

=back

=head2 Listing GNOME Window Manager compliance

=cut

=head3 _WIN_PROTOCOLS, ATOM[]/32

Create a property on the root window of the atom name _WIN_PROTOCOLS.
This property contains a list (array) of atoms that are all the
properties the Window Manager supports.  These atoms are any number of
the following:

 _WIN_LAYER
 _WIN_STATE
 _WIN_HINTS
 _WIN_APP_STATE
 _WIN_EXPANDED_SIZE
 _WIN_ICONS
 _WIN_WORKSPACE
 _WIN_WORKSPACE_COUNT
 _WIN_WORKSPACE_NAMES
 _WIN_CLIENT_LIST

 _WIN_AREA_COUNT            (not in wm-comp.pdf)
 _WIN_AREA                  (not in wm-comp.pdf)
 _WIN_DESKTOP_BUTTON_PROXY  (not in wm-comp.pdf)
 _WIN_SUPPORTING_WM_CHECK   (not in wm-comp.pdf)
 _WIN_WORKAREA              (not in wm-comp.pdf)

If you list one of these properties then you support it and applications
can expect information provided by, or accepted by the Window Manager to
work.


=over

=cut

=item B<get_WIN_PROTOCOLS>(I<$X>,I<$root>) => I<$names> or undef

Returns I<$names> as a reference to a hash of atom names or C<undef>
when no C<_WIN_PROTOCOL> property exists on root window, I<$root>.
I<$root>, when unspecified, defaults to C<$X-E<gt>root>.  Possible keys
are as described above under L</_WIN_PROTOCOLS>.

=cut

sub get_WIN_PROTOCOLS {
    return getWMRootPropertyAtoms($_[0],_WIN_PROTOCOLS=>$_[1]);
}

=item B<set_WIN_PROTOCOLS>(I<$X>,I<$names>)

Sets the C<_WIN_PROTOCOLS> property to the atoms of the names of the
array or hash referenced by I<$names>, or when I<$names> is undefined,
removes the C<_WIN_PROTOCOLS> property from the C<$X-E<gt>root> window.

Note that C<_WIN_PROTOCOLS> should only be set by a window manager (the
owner of the C<_WIN_SUPPORTING_WM_CHECK> window).

=cut

sub set_WIN_PROTOCOLS {
    return setWMRootPropertyAtoms($_[0],_WIN_PROTOCOLS=>$_[1]);
}

=item B<dmp_WIN_PROTOCOLS>(I<$X>,I<$names>)

Prints to standard output the value of get_WIN_PROTOCOLS().

=cut

sub dmp_WIN_PROTOCOLS {
    return dmpWMRootPropertyAtoms($_[0],_WIN_PROTOCOLS=>protocols=>$_[1]);
}

=back

=head2 Providing shortcuts managed clients

=head3 _WIN_CLIENT_LIST, CARDINAL[]/32

As an aide in having external applications be able to list and access
clients being managed by the Window Manager, a property should be set on
the root window of the name _WIN_CLIENT_LIST which is an array of type
CARDINAL.  Each entry is the Window ID of a managed client. If the list
of managed clients changes, clients are added or deleted, this list
should be updated.

Note that the values in the list are saved as type C<CARDINAL> even
though their contents are of type C<WINDOW>.

=head4 Methods

In the following methods, I<$clients> is a reference to an array
containing the list of XIDs for client windows.

=over

=cut

=item B<get_WIN_CLIENT_LIST>(I<$X>,I<$root>) => I<$clients> or undef

Returns the C<_WIN_CLIENT_LIST> property client list as an array
reference, I<$clients>, or C<undef> when no C<_WIN_CLIENT_LIST> property
is set on the root window, I<$root>.  When I<$root> is unspecified, it
defaults to C<$X-E<gt>root>.

=cut

sub get_WIN_CLIENT_LIST {
    return getWMRootPropertyUints($_[0],_WIN_CLIENT_LIST=>$_[1]);
}

=item B<set_WIN_CLIENT_LIST>(I<$X>,I<$clients>)

Sets the C<_WIN_CLIENT_LIST> property to the array referenced by
I<$clients> on the root window, or when I<$clients> is C<undef>, deletes
the C<_WIN_CLIENT_LIST> property from the root window.

Only a window manager should set the C<_WIN_CLIENT_LIST> property
directly in this way.

=cut

sub set_WIN_CLIENT_LIST {
    return setWMRootPropertyUints($_[0],_WIN_CLIENT_LIST=>$_[1]);
}

=item B<dmp_WIN_CLIENT_LIST>(I<$X>,I<$clients>)

Prints to standard output the value of get_WIN_CLIENT_LIST().

=cut

sub dmp_WIN_CLIENT_LIST {
    return dmpWMRootPropertyUints($_[0],_WIN_CLIENT_LIST=>clients=>$_[1]);
}

=back

=head2 Providing Multiple/Virtual Desktop information

=head3 _WIN_WORKSPACE, CARDINAL/32

The C<_WIN_WORKSPACE> property on the root window contains the currently
displayed workspace index, counting from zero.  When set on a client
window, C<_WIN_WORKSPACE> specifies the workspace on which the client
window should appear.

=over

=cut

=item B<get_WIN_WORKSPACE>(I<$X>,I<$window>) =>  I<$workspace>

Return the C<_WIN_WORKSPACE> property workspace, I<$workspace>, for the
specified window, I<$window>, or C<undef> when no C<_WIN_WORKSPACE>
property exists on I<$window>.  I<$workspace>, when defined, is the
scalar index of the workspace (counting from zero).  When I<$window> is
a root window, I<$workspace> is the index of the current workspace; for
a client window, the index of the workspace on which the client appears,
but see also L</_WIN_WORKSPACES>.

=cut

sub get_WIN_WORKSPACE {
    return getWMPropertyUint($_[0],$_[1],_WIN_WORKSPACE=>);
}

=item B<set_WIN_WORKSPACE>(I<$X>,I<$window>,I<$workspace>)

Set the C<_WIN_WORKSPACE> property workspace, I<$workspace>, for the
specified window, I<$window>, or when I<$workspace> is C<undef>, remove
the C<_WIN_WORKSPACE> property from I<$window>.  I<$workspace>, when
defined, is the scalar index of the workspace (counting from zero).

The client should only set C<_WIN_WORKSPACE> directly before initially
mapping a top-level window.  After mapping, req_WIN_WORKSPACE() should
be used instead.  C<_WIN_WORKSPACE> should only be set on the root
window by the window manager.  The client should use req_WIN_WORKSPACE()
to request that the window manager change the property.

=cut

sub set_WIN_WORKSPACE {
    return setWMPropertyUint($_[0],$_[1],_WIN_WORKSPACE=>CARDINAL=>$_[2]);
}

=item B<dmp_WIN_WORKSPACE>(I<$X>,I<$workspace>)

Prints to standard output the value of get_WIN_WORKSPACE().

=cut

sub dmp_WIN_WORKSPACE {
    return dmpWMPropertyUint($_[0],_WIN_WORKSPACE=>workspace=>$_[1]);
}

=item B<req_WIN_WORKSPACE>(I<$X>,I<$window>,I<$workspace>,I<$timestamp>)

Sends a C<_WIN_WORKSPACE> client message to the root window to change
the workspace, I<$workspace>, for the specified window, I<$window>, with
the X service time stamp, I<$timestamp>.  I<$window> defaults to the
default root window, I<$workspace> defaults to zero (0) and
I<$timestamp> defaults to C<CurrentTime>.

When a client window is specified for I<$window>, a change to the active
workspace on which the client window appears is requested, but see also
L</_WIN_WORKSPACES>.  When a root window is specified for I<$window>, or
I<$window> is C<None> or C<undef>, a change to the actively displayed
workspace is requested.

=cut

sub req_WIN_WORKSPACE {
    my($X,$window,$workspace,$timestamp) = @_;
    $timestamp = 0 unless $timestamp;
    $timestamp = 0 if $timestamp eq 'CurrentTime';
    WinClientMessage($X,$window,_WIN_WORKSPACE=>[$workspace,$timestamp]);
}

sub got_WIN_WORKSPACE {
    my($X,$window,$workspace,$timestamp) = @_;
    $timestamp = 0 unless defined $timestamp;
    $timestamp = 'CurrentTime' unless $timestamp;
    return ($window,$workspace,$timestamp);
}

=back

=head3 _WIN_WORKSPACE_COUNT, CARDINAL/32

The C<_WIN_WORKSPACE_COUNT> root window property contains the number of
workspaces.

=over

=cut

=item B<get_WIN_WORKSPACE_COUNT>(I<$X>,I<$root>) => I<$count> or undef

Returns the C<_WIN_WORKSPACE_COUNT> property, I<$count>, from the root
window, or C<undef> when no C<_WIN_WORKSPACE_COUNT> property exists on
I<$root>.
When unspecified, I<$root> defaults to C<$X-E<gt>root>.
When defined, I<$count> is a scalar integer.

=cut

sub get_WIN_WORKSPACE_COUNT {
    return getWMRootPropertyUint($_[0],_WIN_WORKSPACE_COUNT=>$_[1]);
}

=item B<set_WIN_WORKSPACE_COUNT>(I<$X>,I<$count>)

Sets the number of workspaces to I<$count>, or when I<$count> is
undefined, 
Sets the number of workspaces to C<$count>.  (This changes the root
window property and does not send client messages.)

When unspecified, I<$root> defaults to C<$X-E<gt>root>.

=cut

sub set_WIN_WORKSPACE_COUNT {
    return setWMRootPropertyUint($_[0],_WIN_WORKSPACE_COUNT=>CARDINAL=>$_[1]);
}

=item B<dmp_WIN_WORKSPACE_COUNT>(I<$X>,I<$count>)

Prints to standard output the value of get_WIN_WORKSPACE_COUNT().

=cut

sub dmp_WIN_WORKSPACE_COUNT {
    return dmpWMRootPropertyUint($_[0],_WIN_WORKSPACE_COUNT=>count=>$_[1]);
}

=back

=head3 _WIN_WORKSPACE_NAMES, STRING[]/8

This property contains a list of null-separated name strings, one for
each desktop.

=over

=cut

=item B<get_WIN_WORKSPACE_NAMES>(I<$X>,I<$root>) => I<$names> or undef

Return the workspace names as a reference to a list of name strings, or
C<undef> if the property does not exist.
When unspecified, I<$root> defaults to C<$X-E<gt>root>.

=cut

sub get_WIN_WORKSPACE_NAMES {
    return getWMRootPropertyTermStrings($_[0],_WIN_WORKSPACE_NAMES=>$_[1]);
}

=item B<set_WIN_WORKSPACE_NAMES>(I<$X>,I<$names>)

Set the workspace names to the referenced list of names, C<$names>.
(This simply sets the property and does not send a client message.)
When unspecified, I<$root> defaults to C<$X-E<gt>root>.

=cut

sub set_WIN_WORKSPACE_NAMES {
    return setWMRootPropertyTermStrings($_[0],_WIN_WORKSPACE_NAMES=>COMPOUND_TEXT=>$_[1]);
}

=item B<dmp_WIN_WORKSPACE_NAMES>(I<$X>,I<$names>)

Prints to standard output the value of get_WIN_WORKSPACE_NAMES().

=cut

sub dmp_WIN_WORKSPACE_NAMES {
    my ($X,$names) = @_;
    return dmpWMRootPropertyDisplay($X,_WIN_WORKSPACE_NAMES=>sub{
	    my @vals = @$names;
	    my $i = 0;
	    while (@vals) {
		printf "\t%-20s: '%s'\n",'workspace('.$i.')',shift @vals; $i++;
	    }
    });
    return dmpWMRootPropertyTermStrings($_[0],_WIN_WORKSPACE_NAMES=>names=>$_[1]);
}

=back

=head3 _WIN_WORKAREA, CARDINAL[]/32

The C<_WIN_WORKAREA> property contains a list of minimum and maximum x
and y coordinates of the available work area.  The minimum coordinates
are the upper-left corner and the maximum coordinates are the
lower-right corner of the available area.  This is only set by the
window manager.

Note that even though the values specified are signed numbers, they are
stored in the property with type C<CARDINAL>.

=head4 Methods

In the methods that follow, I<$rectangle> is a reference to a hash
containing the following integer valued keys:

 minX   x-coordinate of work area upper-left  corner
 minY   y-coordinate of work area upper-left  corner
 maxX   x-coordinate of work area lower-right corner
 maxY   y-coordinate of work area lower-right corner

=over

=cut

=item B<get_WIN_WORKAREA>(I<$X>,I<$root>) => I<$rectangle> or undef

Returns the C<_WIN_WORKAREA> property available work area, I<$rectangle>,
or C<undef> when no such C<_WIN_WORKAREA> property exists on root
window, I<$root>.  When unspecified, I<$root> defaults to
C<$X-E<gt>root>.

=cut

sub get_WIN_WORKAREA {
    return getWMRootPropertyHashUints($_[0],_WIN_WORKAREA=>[qw(minX minY maxX maxY)],$_[1]);
}

=item B<set_WIN_WORKAREA>(I<$X>,I<$rectangle>)

Sets the C<_WIN_WORKAREA> available work area to the rectangle,
I<$rectangle>, or when I<$rectangle> is unspecified, deletes the
C<_WIN_WORKAREA> property from the root window, C<$X-E<gt>root>.

Note that the C<_WIN_WORKAREA> property is only set by the window
manager.

=cut

sub set_WIN_WORKAREA {
    return setWMRootPropertyHashUints($_[0],_WIN_WORKAREA=>CARDINAL=>[qw(minX maxX minY maxY)],$_[1]);
}

=item B<dmp_WIN_WORKAREA>(I<$X>,I<$rectangle>)

Prints to standard output the value of get_WIN_WORKAREA().

=cut

sub dmp_WIN_WORKAREA {
    return dmpWMRootPropertyHashUints($_[0],_WIN_WORKAREA=>[qw(minX minY maxX maxY)],$_[1]);
}

=back

=head3 _WIN_CLIENT_MOVING, CARDINAL/32

This atom is a 32-bit integer that is either 0 or 1 (currently).  0
denotes everything is as per usual but 1 denotes that ALL configure
requests by the client on the client window with this property are not
just a simple "moving" of the window, but the result of a user move the
window BUT the client is handling that interaction by moving its own
window.  The window manager should respond accordingly by assuming any
configure requests for this window whilst this atom is "active" in the
"1" state are a client move and should handle flipping desktops if the
window is being dragged "off screen" or across desktop boundaries etc.
This atom is only ever set by the client.

=over

=cut

=item B<get_WIN_CLIENT_MOVING>(I<$X>,I<$window>) => I<$bool>

Returns the C<_WIN_CLIENT_MOVING> property, I<$bool>, from the window,
I<$window>, or C<undef> when the property does not exist on I<$window>.
When defined, I<$bool> is a boolean value (0 or 1).

=cut

sub get_WIN_CLIENT_MOVING {
    return getWMPropertyUint($_[0],$_[1],'_WIN_CLIENT_MOVING');
}

=item B<set_WIN_CLIENT_MOVING>(I<$X>,I<$window>,I<$bool>)

Sets the client moving flag to C<$bool> for window, C<$window>, or when
I<$bool> is undefined, deletes the C<_WIN_CLIENT_MOVING> property from
the window, I<$window>.

=cut

sub set_WIN_CLIENT_MOVING {
    return setWMPropertyUint($_[0],$_[1],_WIN_CLIENT_MOVING=>CARDINAL=>$_[2]);
}

=item B<dmp_WIN_CLIENT_MOVING>(I<$X>,I<$bool>)

Prints to standard output the value of get_WIN_CLIENT_MOVING().

=cut

sub dmp_WIN_CLIENT_MOVING {
    return dmpWMPropertyUint($_[0],_WIN_CLIENT_MOVING=>moving=>$_[1]);
}

=back

=head2 Initial properties set on client window

When a client first maps a window, before calling XMapWindow, it will
set properties on the client window with certain atoms as their types.
The property atoms set can be any or all of _WIN_LAYER, _WIN_STATE,
_WIN_WORKSPACE, _WIN_EXPANDED_SIZE and _WIN_HINTS.

Each of these properties is of the type CARDINAL, and _WIN_EXPANDED_SIZE
is an array of 4 CARDINAL's. For the _WIN_STATE and _WIN_HINTS
properties, the bits set mean that state/property is desired by the
client.

The bitmask for _WIN_HINTS is as follows:

 #define WIN_HINTS_SKIP_FOCUS (1<<0) /*"alt-tab" skips this win*/
 #define WIN_HINTS_SKIP_WINLIST (1<<1) /*do not show in window list*/
 #define WIN_HINTS_SKIP_TASKBAR (1<<2) /*do not show on taskbar*/
 #define WIN_HINTS_GROUP_TRANSIENT (1<<3) /*Reserved - definition is unclear*/
 #define WIN_HINTS_FOCUS_ON_CLICK (1<<4) /*app only accepts focus if clicked*/

This is also a simple bitmask but only the application changes it, thus
whenever this property changes the Window Manager should re-read it and
honor any changes.  _WIN_WORKSPACE is a CARDINAL that is the Desktop
number the app would like to be on. This desktop number is updated by
the Window Manager after the window is mapped and until the window is
unmapped by the application. The value for this property is simply the
numeric for the desktop 0, being the first desktop available.

=head3 _WIN_STATE, CARDINAL/32

This property is of type CARDINAL.  The bits set mean that state is
desired by the client.  The bitmask for _WIN_STATE is as follows:

 #define WIN_STATE_STICKY          (1<<0) /* everyone knows sticky */
 #define WIN_STATE_MINIMIZED       (1<<1) /* Reserved - definition is unclear */
 #define WIN_STATE_MAXIMIZED_VERT  (1<<2) /* window in maximized V state */
 #define WIN_STATE_MAXIMIZED_HORIZ (1<<3) /* window in maximized H state */
 #define WIN_STATE_HIDDEN          (1<<4) /* not on taskbar but window visible */
 #define WIN_STATE_SHADED          (1<<5) /* shaded (MacOS / Afterstep style) */
 #define WIN_STATE_HID_WORKSPACE   (1<<6) /* not on current desktop */
 #define WIN_STATE_HID_TRANSIENT   (1<<7) /* owner of transient is hidden */
 #define WIN_STATE_FIXED_POSITION  (1<<8) /* window is fixed in position even */
 #define WIN_STATE_ARRANGE_IGNORE  (1<<9) /* ignore for auto arranging */

These are a simple bitmasks - if the bit is set, that state is desired
by the application.  Once the application window has been mapped it is
the responsibility of the Window Manager to set these properties to the
current state of the Window whenever it changes states.  If the window
is unmapped the application is again responsible, if unmapped by the
application.

=over

=cut

push @{$EXPORT_TAGS{const}}, qw(
    WIN_STATE_STICKY
    WIN_STATE_MINIMIZED
    WIN_STATE_MAXIMIZED_VERT
    WIN_STATE_MAXIMIZED_HORZ
    WIN_STATE_HIDDEN
    WIN_STATE_SHADED
    WIN_STATE_HIDDEN_WORKSPACE
    WIN_STATE_HIDDEN_TRANSIENT
    WIN_STATE_FIXED_POSITION
    WIN_STATE_ARRANGE_IGNORE
    WIN_STATE_SKIP_TASKBAR
    WIN_STATE_MODAL
    WIN_STATE_BELOW
    WIN_STATE_ABOVE
    WIN_STATE_FULLSCREEN
    WIN_STATE_WASHIDDEN
    WIN_STATE_WASMINIMIZED
    WIN_STATE_WITHDRAWN
    WindowState
);

use constant {
    WIN_STATE_STICKY		=> (1<<0),
    WIN_STATE_MINIMIZED		=> (1<<1),
    WIN_STATE_MAXIMIZED_VERT	=> (1<<2),
    WIN_STATE_MAXIMIZED_HORZ	=> (1<<3),
    WIN_STATE_HIDDEN		=> (1<<4),
    WIN_STATE_SHADED		=> (1<<5),
    WIN_STATE_HIDDEN_WORKSPACE	=> (1<<6),
    WIN_STATE_HIDDEN_TRANSIENT	=> (1<<7),
    WIN_STATE_FIXED_POSITION	=> (1<<8)|(1<<10),
    WIN_STATE_ARRANGE_IGNORE	=> (1<<9)|(1<<11),
    WIN_STATE_SKIP_TASKBAR	=> (1<<24),
    WIN_STATE_MODAL		=> (1<<25),
    WIN_STATE_BELOW		=> (1<<26),
    WIN_STATE_ABOVE		=> (1<<27),
    WIN_STATE_FULLSCREEN	=> (1<<28),
    WIN_STATE_WASHIDDEN		=> (1<<29),
    WIN_STATE_WASMINIMIZED	=> (1<<30),
    WIN_STATE_WITHDRAWN		=> (1<<31),

    WindowState => [
	'Sticky',
	'Minimized',
	'MaximizedVertical',
	'MaximizedHorizontal',
	'Hidden',
	'Shaded',
	'HiddenWorkspace',
	'HiddenTransient',
	'FixedPosition',
	'ArrangeIgnore',
	'FixedPosition',    # IceWM
	'ArrangeIgnore',    # IceWM
	12, 13, 14, 15,
	16, 17, 18, 19,
	20, 21, 22, 23,
	'SkipTaskbar',	    # IceWM
	'Modal',	    # IceWM
	'Below',	    # IceWM
	'Above',	    # IceWM
	'FullScreen',	    # IceWM
	'WasHidden',	    # IceWM
	'WasMinimized',	    # IceWM
	'Withdrawn',	    # IceWM
    ],
};

=item B<get_WIN_STATE>(I<$X>,I<$window>) => I<$state>

Get the window state, C<$state> associated with a given window,
C<$window>.  The value is a bitmask that contains the following bit
defintions:

   0x00000001 - Sticky		    WIN_STATE_STICKY
   0x00000002 - Minimized	    WIN_STATE_MINIMIZED
   0x00000004 - MaximizedVertical   WIN_STATE_MAXIMIZED_VERT
   0x00000008 - MaximizedHorizontal WIN_STATE_MAXIMIZED_HORZ
   0x00000010 - Hidden		    WIN_STATE_HIDDEN
   0x00000020 - Shaded		    WIN_STATE_SHADED
   0x00000040 - HiddenWorkspace	    WIN_STATE_HIDDEN_WORKSPACE
   0x00000080 - HiddenTransient	    WIN_STATE_HIDDEN_TRANSIENT
   0x00000100 - FixedPosition	    WIN_STATE_FIXED_POSITION
   0x00000200 - ArrangeIgnore	    WIN_STATE_ARRANGE_IGNORE

   0x00000400 - FixedPosition	    WIN_STATE_FIXED_POSITION	(IceWM)
   0x00000800 - ArrangeIgnore	    WIN_STATE_ARRANGE_IGNORE	(IceWM)

   0x01000000 - Skip Taskbar	    WIN_STATE_SKIP_TASKBAR	(IceWM)
   0x02000000 - Modal		    WIN_STATE_MODAL		(IceWM)
   0x04000000 - Below		    WIN_STATE_BELOW		(IceWM)
   0x08000000 - Above		    WIN_STATE_ABOVE		(IceWM)
   0x10000000 - FullScreen	    WIN_STATE_FULLSCREEN	(IceWM)
   0x20000000 - WasHidden	    WIN_STATE_WASHIDDEN		(IceWM)
   0x40000000 - WasMimimized	    WIN_STATE_WASMINIMIZED	(IceWM)
   0x80000000 - Withdrawn	    WIN_STATE_WITHDRAWN		(IceWM)

=cut

sub get_WIN_STATE {
    return getWMPropertyBitnames($_[0],$_[1],_WIN_STATE=>WindowState=>WindowState());
}

=item B<set_WIN_STATE>(I<$X>,I<$window>,I<$state>)

Sets the C<_WIN_STATE> property state, I<$state>, for the specified
window, I<$window>, or when I<$state> is C<undef>, deletes the
C<_WIN_STATE> property from I<$window>.  I<$state>, when defined, is an
interpreted scalar value as described under L</_WIN_STATE>, above.

The client should only set C<_WIN_STATE> directly before initially
mapping a top-level window.  After mapping, req_WIN_STATE() should be
used instead.

=cut

sub set_WIN_STATE {
    return setWMPropertyBitnames($_[0],$_[1],_WIN_STATE=>CARDINAL=>WindowState=>WindowState(),$_[2]);
}

=item B<dmp_WIN_STATE>(I<$X>,I<$state>)

Prints to standard output the value of get_WIN_STATE().

=cut

sub dmp_WIN_STATE {
    return dmpWMPropertyBitnames($_[0],_WIN_STATE=>state=>$_[1]);
}

=item B<req_WIN_STATE>(I<$X>,I<$window>,I<$toggles>,I<$settings>,I<$timestamp>)

Sets the window state for window, C<$window>, using the following client
message:

 _WIN_STATE
   window = respective window
   message_type = _WIN_STATE
   format = 32
   data.l[0] = toggles
   data.l[1] = settings
   other data.l[] elements = 0

   toggles and settings are:

   0x00000001 - Sticky		    WIN_STATE_STICKY
   0x00000002 - Minimized	    WIN_STATE_MINIMIZED
   0x00000004 - MaximizedVertical   WIN_STATE_MAXIMIZED_VERT
   0x00000008 - MaximizedHorizontal WIN_STATE_MAXIMIZED_HORZ
   0x00000010 - Hidden		    WIN_STATE_HIDDEN
   0x00000020 - Shaded		    WIN_STATE_SHADED
   0x00000040 - HiddenWorkspace	    WIN_STATE_HIDDEN_WORKSPACE
   0x00000080 - HiddenTransient	    WIN_STATE_HIDDEN_TRANSIENT
   0x00000100 - FixedPosition	    WIN_STATE_FIXED_POSITION
   0x00000200 - ArrangeIgnore	    WIN_STATE_ARRANGE_IGNORE

   0x00000400 - FixedPosition	    WIN_STATE_FIXED_POSITION	(IceWM)
   0x00000800 - ArrangeIgnore	    WIN_STATE_ARRANGE_IGNORE	(IceWM)

   0x01000000 - SkipTaskbar	    WIN_STATE_SKIP_TASKBAR	(IceWM)
   0x02000000 - Modal		    WIN_STATE_MODAL		(IceWM)
   0x04000000 - Below		    WIN_STATE_BELOW		(IceWM)
   0x08000000 - Above		    WIN_STATE_ABOVE		(IceWM)
   0x10000000 - FullScreen	    WIN_STATE_FULLSCREEN	(IceWM)
   0x20000000 - WasHidden	    WIN_STATE_WASHIDDEN		(IceWM)
   0x40000000 - WasMimimized	    WIN_STATE_WASMINIMIZED	(IceWM)
   0x80000000 - Withdrawn	    WIN_STATE_WITHDRAWN		(IceWM)

Note that some documentation shows I<toggles> as the bits to toggle and
I<settings> as the bits to set.  Others show I<toggles> as a bit mask of
bits to set or reset and I<settings> as the absolute settings of those
masked bits.

=cut

sub req_WIN_STATE {
    my($X,$window,$toggles,$settings,$timestamp) = @_;
    $timestamp = 0 unless $timestamp;
    $timestamp = 0 if $timestamp eq 'CurrentTime';
    WinClientMessage($X,$window,_WIN_STATE=>[$toggles,$settings,$timestamp]);
}

sub event_handler_ClientMessage_WIN_STATE {
    my($X,$e) = @_;
    my($window,$toggles,$settings,$timestamp) =
	$e->{window}, unpack('LLLLL',$e->{data});
}

sub got_WIN_STATE {
    my($X,$window,$toggles,$settings,$timestamp) = @_;
    $toggles = 0 unless $toggles;
    $toggles = bits2names(WindowState=>WindowState(),$toggles);
    $settings = 0 unless $settings;
    $settings = bits2names(WindowState=>WindowState(),$settings);
    $timestamp = 'CurrentTime' unless $timestamp;
    return ($window,$toggles,$settings,$timestamp);
}

=back

=head3 _WIN_HINTS, CARDINAL/32

=over

=cut

push @{$EXPORT_TAGS{const}}, qw(
    WIN_HINTS_SKIP_FOCUS
    WIN_HINTS_SKIP_WINLIST
    WIN_HINTS_SKIP_TASKBAR
    WIN_HINTS_GROUP_TRANSIENT
    WIN_HINTS_FOCUS_ON_CLICK
    WIN_HINTS_DO_NOT_COVER
    WIN_HINTS_DOCK_HORIZONTAL
    WindowHints
);

use constant {
    WIN_HINTS_SKIP_FOCUS	=> (1<<0),
    WIN_HINTS_SKIP_WINLIST	=> (1<<1),
    WIN_HINTS_SKIP_TASKBAR	=> (1<<2),
    WIN_HINTS_GROUP_TRANSIENT	=> (1<<3),
    WIN_HINTS_FOCUS_ON_CLICK	=> (1<<4),
    WIN_HINTS_DO_NOT_COVER	=> (1<<5),
    WIN_HINTS_DOCK_HORIZONTAL	=> (1<<6),

    WindowHints=>[qw(
            SkipFocus
            SkipWinList
            SkipTaskbar
            GroupTransient
            FocusOnClick
            DoNotCover
            DockHorizontal
            )],
};

=item B<get_WIN_HINTS>(I<$X>,I<$window>) => I<$hints>

Get the window manager hints associated with a window, C<$window> and
return them as a scalar integer value.  C<$hints> is a bitmask of zero
or more of the following:

    0x01 - SkipFocus (*)	    WIN_HINTS_SKIP_FOCUS
    0x02 - SkipWinList 		    WIN_HINTS_SKIP_WINLIST
    0x04 - SkipTaskbar 		    WIN_HINTS_SKIP_TASKBAR
    0x08 - GroupTransient 	    WIN_HINTS_GROUP_TRANSIENT
    0x10 - FocusOnClick (**)	    WIN_HINTS_FOCUS_ON_CLICK
    0x20 - DoNotCover (***)	    WIN_HINTS_DO_NOT_COVER	(IceWM)
    0x40 - DockHorizontal (****)    WIN_HINTS_DOCK_HORIZONTAL	(IceWM)

    (*)   alt-tab skips this window
    (**)   app only accepts focus if clicked
    (***)  attempt to not cover this window
    (****) docked horizontally

=cut

sub get_WIN_HINTS {
    return getWMPropertyBitnames($_[0],$_[1],_WIN_HINTS=>WindowHints=>WindowHints());
}

=item B<set_WIN_HINTS>(I<$X>,I<$window>,I<$hints>)

=cut

sub set_WIN_HINTS {
    return setWMPropertyBitnames($_[0],$_[1],_WIN_HINTS=>CARDINAL=>WindowHints=>WindowHints(),$_[2]);
}

=item B<dmp_WIN_HINTS>(I<$X>,I<$hints>)

Prints to standard output the value of get_WIN_HINTS().

=cut

sub dmp_WIN_HINTS {
    return dmpWMPropertyBitnames($_[0],_WIN_HINTS=>hints=>$_[1]);
}

=item B<req_WIN_HINTS>(I<$X>,I<$window>,I<$hints>,I<$timestamp>)

Sets the window manager hints, C<$hints>, associated with a window,
C<$window>, using the following client message:

 _WIN_HINTS
    window = respective window
    message_type = _WIN_HINTS
    format = 32
    data.l[0] = hints
    other data.l[] elements = 0

    hints is:

    0x01 - skip focus (*)	    WIN_HINTS_SKIP_FOCUS
    0x02 - skip winlist		    WIN_HINTS_SKIP_WINLIST
    0x04 - skip taskbar		    WIN_HINTS_SKIP_TASKBAR
    0x08 - group transient	    WIN_HINTS_GROUP_TRANSIENT
    0x10 - focus on click (**)	    WIN_HINTS_FOCUS_ON_CLICK
    0x20 - do not cover (***)	    WIN_HINTS_DO_NOT_COVER	(IceWM)
    0x40 - dock horizontal (****)   WIN_HINTS_DOCK_HORIZONTAL	(IceWM)

    (*)   alt-tab skips this window
    (**)   app only accepts focus if clicked
    (***)  attempt to not cover this window
    (****) docked horizontally

=cut

sub req_WIN_HINTS {
    my($X,$window,$hints,$timestamp) = @_;
    $timestamp = 0 unless $timestamp;
    $timestamp = 0 if $timestamp eq 'CurrentTime';
    $hints = 0 unless $hints;
    $hints = names2bits(WindowHints=>WindowHints(),$hints);
    WinClientMessage($X,$window,_WIN_HINTS=>[$hints,$timestamp]);
}

sub got_WIN_HINTS {
    my($X,$window,$hints,$timestamp) = @_;
    $timestamp = 'CurrentTime' unless $timestamp;
    $hints = 0 unless $hints;
    $hints = bits2names(WindowHints=>WindowHints(),$hints);
    return ($window,$hints,$timestamp);
}

=back

=head3 _WIN_LAYER, CARDINAL/32

_WIN_LAYER is also a CARDINAL that is the stacking layer the application
wishes to exist in. The values for this property are:

 WIN_LAYER_DESKTOP	=>  0	'Desktop'
 WIN_LAYER_BELOW	=>  2	'Below'
 WIN_LAYER_NORMAL	=>  4	'Normal'
 WIN_LAYER_ONTOP	=>  6	'OnTop'
 WIN_LAYER_DOCK		=>  8	'Dock'
 WIN_LAYER_ABOVEDOCK	=> 10	'AboveDock'
 WIN_LAYER_MENU		=> 12	'Menu'
 WIN_LAYER_FULLSCREEN	=> 14	'FullScreen'	# IceWM
 WIN_LAYER_ABOVEALL	=> 15	'AboveAll'	# IceWM

Once a window has been mapped, the client should request that the window
manager change the property using the following client message:

 xev.type = ClientMessage;
 xev.window = client_window;
 xev.message_type = XInternAtom(disp, XA_WIN_LAYER, False);
 xev.format = 32;
 xev.data.l[0] = new_layer;
 xev.data.l[1] = timestamp;
 XSendEvent(disp, root, False, SubstructureNotifyMask, (XEvent *) &xev);

=over

=cut

push @{$EXPORT_TAGS{const}}, qw(
    WIN_LAYER_DESKTOP
    WIN_LAYER_BELOW
    WIN_LAYER_NORMAL
    WIN_LAYER_ONTOP
    WIN_LAYER_DOCK
    WIN_LAYER_ABOVEDOCK
    WIN_LAYER_MENU
    WIN_LAYER_FULLSCREEN
    WIN_LAYER_ABOVEALL
    WindowLayer
);

use constant {
    WIN_LAYER_DESKTOP		=> 0,
    WIN_LAYER_BELOW		=> 2,
    WIN_LAYER_NORMAL		=> 4,
    WIN_LAYER_ONTOP		=> 6,
    WIN_LAYER_DOCK		=> 8,
    WIN_LAYER_ABOVEDOCK		=> 10,
    WIN_LAYER_MENU		=> 12,
    WIN_LAYER_FULLSCREEN	=> 14,
    WIN_LAYER_ABOVEALL		=> 15,
    WindowLayer => [
	'Desktop', 1,
	'Below', 3,
	'Normal', 5,
	'OnTop', 7,
	'Dock', 9,
	'AboveDock', 11,
	'Menu', 13,
	'FullScreen',
	'AboveAll'
    ],
};

=item B<get_WIN_LAYER>(I<$X>,I<$window>) => I<$layer> or undef

Return the C<_WIN_LAYER> property layer, I<$layer>, for the specified
window, I<$window>, or C<undef> when no C<_WIN_LAYER> property exists on
I<$window>.  I<$layer>, when defined, is an interpreted scalar value as
described under L</_WIN_LAYER>, above.

=cut

sub get_WIN_LAYER {
    return getWMPropertyInterp($_[0],$_[1],_WIN_LAYER=>WindowLayer=>WindowLayer());
}

=item B<set_WIN_LAYER>(I<$X>,I<$window>,I<$layer>)

Sets the C<_WIN_LAYER> property layer, I<$layer>, for the specified
window, I<$window>, or when I<$layer> is C<undef>, remove the
C<_WIN_LAYER> property from I<$window>.  I<$layer>, when defined, is an
interpreted scalar value as described under L</_WIN_LAYER>, above.

The client should only set C<_WIN_LAYER> directly before initially
mapping a top-level window.  After mapping, req_WIN_LAYER() should be
used instead.

=cut

sub set_WIN_LAYER {
    return setWMPropertyInterp($_[0],$_[1],_WIN_LAYER=>WindowLayer=>WindowLayer(),$_[2]);
}

=item B<dmp_WIN_LAYER>(I<$X>,I<$layer>)

Prints to standard output the value of get_WIN_LAYER().

=cut

sub dmp_WIN_LAYER {
    return dmpWMPropertyInterp($_[0],_WIN_LAYER=>layer=>$_[1]);
}

=item B<req_WIN_LAYER>(I<$X><I<$window>,I<$layer>,I<$timestamp>)

Sends a C<_WIN_LAYER> client message to the root window to change the
layer to I<$layer> for window, I<$window>, with the X server time stamp,
I<$timestamp>.  I<$layer> defaults to C<Normal> and I<$timestamp>
defaults to C<CurrentTime>.  See L</_WIN_LAYER>, above, for the possible
values of I<$layer>.

=cut

sub req_WIN_LAYER {
    my($X,$window,$layer,$timestamp) = @_;
    $layer = 'Normal' unless defined $layer;
    $layer = name2val(WindowLayer=>,WindowLayer(),$layer);
    $timestamp = 0 unless $timestamp;
    $timestamp = 0 if $timestamp eq 'CurrentTime';
    WinClientMessage($X,$window,_WIN_LAYER=>[$layer,$timestamp]);
}

sub got_WIN_LAYER {
    my($X,$window,$layer,$timestamp) = @_;
    $layer = 0 unless $layer;
    $layer = bits2names(WindowLayer=>WindowLayer(),$layer);
    $timestamp = 'CurrentTime' unless $timestamp;
    return ($window,$layer,$timestamp);
}

=back

=head3 _WIN_WORKSPACES, CARDINAL[]/32

This property is cumbersome enough to be largely unusable.

=over

=cut

=item B<get_WIN_WORKSPACES>(I<$X>,I<$window>) = [ I<@bitmask> ]

Return a bit mask of the workspaces on which a specified window,
C<$window> is to appear, or C<undef> if this property is not set on
C<$window>.

=cut

sub get_WIN_WORKSPACES { 
    my($X,$window) = @_;
    return getWMPropertyDecode($X,$window,sub{
            my $j = 0;
            my @bits = ();
            foreach my $bits (unpack('L*',shift)) {
                for(my $i=0;$i<32;$i++) {
                    push @bits, $i+$j if $bits & (1<<$i);
                }
                $j += 32;
            }
            return \@bits;
    });
}

=item B<set_WIN_WORKSPACES>(I<$X>,I<$window>,I<$bitmask>)

Sets a bit mask of the workspaces on which a specified window,
C<$window> is to appear, I<$bitmask>, or when undefined, removes the
C<_WIN_WORKSPACES> property from C<$window>.

=cut

sub set_WIN_WORKSPACES {
    my($X,$window,$bitmask) = @_;
    return setWMPropertyEncode($X,$window,_WIN_WORKSPACES=>sub{
            my @bits = ();
            @bits = @$bitmask if ref $bitmask eq 'ARRAY';
            @bits = map{$bitmask->{$_}?$_:()} keys %$bitmask if ref $bitmask eq 'HASH';
            my @vals = ();
            foreach (@bits) {
                my $j = $_>>5;
                my $i = $_&31;
                $vals[$j] |= 1<<$i;
            }
            return CARDINAL=>32,pack('L*',@vals);
    });
}

=item B<dmp_WIN_WORKSPACES>(I<$X>,I<$bitmask>)

Prints to standard output the value of get_WIN_WORKSPACES().

=cut

sub dmp_WIN_WORKSPACES {
    my($X,$workspaces) = @_;
    return dmpWMPropertyDisplay($X,_WIN_WORKSPACES=>sub{
	printf "\t%-20s: %s\n",workspaces=>join(', ',@$workspaces);
    });
}

=item B<req_WIN_WORKSPACES>(I<$X>,I<$window>,I<$add>,I<$index>,I<$bits>,I<$timestamp>)

Sets a set of 32 workspaces on which a window, C<$window>, appears.
C<$add> is true when the workspaces are to be added to the list of
workspaces on which C<$window> appears; and false when they are to be
removed.  C<$index> provides an index of the set of 32 workspaces to
which the setting applies; C<$bits> is the bit mask of the 32 workspaces
indexed.  C<$timestamp> is the time stamp of the event causing the
alteration, or C<CurrentTime> otherwise.  This method uses the following
client message:

 _WIN_WORKSPACES
  window = respective window
  message_type = _WIN_WORKSPACES_ADD or _WIN_WORKSPACES_REMOVE
  format = 32
  data.l[0] = index
  data.l[1] = bit mask
  data.l[2] = timestamp
  other data.l[] elements = 0

=cut

sub req_WIN_WORKSPACES {
    my($X,$window,$add,$index,$bits,$timestamp) = @_;
    my $prop = $add ? '_WIN_WORKSPACES_ADD' : '_WIN_WORKSPACES_REMOVE';
    $timestamp = 0 unless $timestamp;
    $timestamp = 0 if $timestamp eq 'CurrentTime';
    WinClientMessage($X,$window,$prop=>[$index,$bits,$timestamp]);
}

sub got_WIN_WORKSPACES_ADD {
    my($X,$window,$index,$bits,$timestamp) = @_;
    $index = 0 unless $index;
    $bits = 0 unless $bits;
    $timestamp = 'CurrentTime' unless $timestamp;
    return ($window,$index,$bits,$timestamp);
}

sub got_WIN_WORKSPACES_REMOVE {
    my($X,$window,$index,$bits,$timestamp) = @_;
    $index = 0 unless $index;
    $bits = 0 unless $bits;
    $timestamp = 'CurrentTime' unless $timestamp;
    return ($window,$index,$bits,$timestamp);
}

=back

=head3 _WIN_EXPANDED_SIZE, CARDINAL[4]/32

The C<_WIN_EXPANDED_SIZE> property is an array of 4 C<CARDINAL> numers
as follows:

 x   CARD32  x-position of expanded window origin
 y   CARD32  y-position of expanded window origin
 w   CARD32  width of expanded window
 h   CARD32  height of expanded window

The
expanded space occupied is the area on the screen that the app's window
will occupy when "expanded".  That is, if you have a button on an app
that "hides" it by reducing its size, this is the geometry of the
expanded window - so the window manager can allow for this when doing
auto position of client windows assuming the app can at any point use
this area and thus try and keep it clear.  Only the client sets this.

=head4 Methods

In the following methods, I<$geometry> refers to a hash reference
containing the following keys (containing integer values):

 x    x-position of expanded window origin
 y    y-position of expanded window origin
 w    width  of expanded window
 h    height of expanded window

=over

=cut

=item B<get_WIN_EXPANDED_SIZE>(I<$X>,I<$window>) => I<$geometry>

Gets the expanded size of window, C<$window>, as an array reference to
the C<$x>, C<$y>, origin and the C<$w> width and C<$h> height.

=cut

sub get_WIN_EXPANDED_SIZE {
    return getWMRootPropertyHashInts($_[0],_WIN_EXPANDED_SIZE=>[qw(x y w h)],$_[1]);
}

=item B<set_WIN_EXPANDED_SIZE>(I<$X>,I<$window>,I<$geometry>)

The C<_WIN_EXPANDED_SIZE> property should only be set by a client.

=cut

sub set_WIN_EXPANDED_SIZE {
    return setWMRootPropertyHashInts($_[0],_WIN_EXPANDED_SIZE=>CARDINAL=>[qw(x y w h)],$_[1]);
}

=item B<dmp_WIN_EXPANDED_SIZE>(I<$X>,I<$geometry>)

Prints to standard output the value of get_WIN_EXPANDED_SIZE().

=cut

sub dmp_WIN_EXPANDED_SIZE {
    return dmpWMRootPropertyHashInts($_[0],_WIN_EXPANDED_SIZE=>[qw(x y w h)],$_[1]);
}

=back

=head3 _WIN_ICONS, CARDINAL[]/32

This property contains additional icons for the application.  If this
property is set, the WM will ignore default X icon things and
KWM_WIN_ICON hint.  Icon Mask can be None if transparency is not
required.

=over

=cut

=item B<get_WIN_ICONS>(I<$X>,I<$window>) => [ $n, $length, ( $pixmap, $mask, $width, $height, $depth, $drawable ) ]

=cut

sub get_WIN_ICONS {
    return getWMPropertyUints($_[0],$_[1],_WIN_ICONS=>);
}

=item B<set_WIN_ICONS>(I<$X>,I<$window>,I<$icons>)

=cut

sub set_WIND_ICONS {
    return setWMPropertyUints($_[0],$_[1],_WIN_ICONS=>$_[2]);
}

=item B<dmp_WIN_ICONS>(I<$X>,I<$icons>)

Prints to standard output the value of get_WIN_ICONS().

=cut

sub dmp_WIN_ICONS {
    return dmpWMPropertyUints($_[0],_WIN_ICONS=>icons=>$_[1]);
}

=back

=head3 _WIN_APP_STATE, CARDINAL/32

The C<_WIN_APP_STATE> property contains the application state (also
"color reactiveness") - the application can keep changing this property
when it changes its state and the window manager or monitoring program
will pick this up and display something accordingly.  Only the client
sets this property.

=head4 Methods

In the methods that follow, I<$state> refers to an interpreted scalar of
type C<WindowAppState> that has the following interpreted value names
and symbolic constants:

    None                WIN_APP_STATE_NONE              =>  0
    Active1             WIN_APP_STATE_ACTIVE1           =>  1
    Active2             WIN_APP_STATE_ACTIVE2           =>  2
    Error1              WIN_APP_STATE_ERROR1            =>  3
    Error2              WIN_APP_STATE_ERROR2            =>  4
    FatalError1         WIN_APP_STATE_FATAL_ERROR1      =>  5
    FatalError2         WIN_APP_STATE_FATAL_ERROR2      =>  6
    Idle1               WIN_APP_STATE_IDLE1             =>  7
    Idle2               WIN_APP_STATE_IDLE2             =>  8
    Waiting1            WIN_APP_STATE_WAITING1          =>  9
    Waiting2            WIN_APP_STATE_WAITING2          => 10
    Working1            WIN_APP_STATE_WORKING1          => 11
    Working2            WIN_APP_STATE_WORKING2          => 12
    NeedUserInput1      WIN_APP_STATE_NEED_USER_INPUT1  => 13
    NeedUserInput2      WIN_APP_STATE_NEED_USER_INPUT2  => 14
    Struggling1         WIN_APP_STATE_STRUGGLING1       => 15
    Struggling2         WIN_APP_STATE_STRUGGLING2       => 16
    DiskTraffic1        WIN_APP_STATE_DISK_TRAFFIC1     => 17
    DiskTraffic2        WIN_APP_STATE_DISK_TRAFFIC2     => 18
    NetworkTraffic1     WIN_APP_STATE_NETWORK_TRAFFIC1  => 19
    NetworkTraffic2     WIN_APP_STATE_NETWORK_TRAFFIC2  => 20
    Overloaded1         WIN_APP_STATE_OVERLOADED1       => 21
    Overloaded2         WIN_APP_STATE_OVERLOADED2       => 22
    Percent000_1        WIN_APP_STATE_PERCENT000_1      => 23
    Percent000_2        WIN_APP_STATE_PERCENT000_2      => 24
    Percent010_1        WIN_APP_STATE_PERCENT010_1      => 25
    Percent010_2        WIN_APP_STATE_PERCENT010_2      => 26
    Percent020_1        WIN_APP_STATE_PERCENT020_1      => 27
    Percent020_2        WIN_APP_STATE_PERCENT020_2      => 28
    Percent030_1        WIN_APP_STATE_PERCENT030_1      => 29
    Percent030_2        WIN_APP_STATE_PERCENT030_2      => 30
    Percent040_1        WIN_APP_STATE_PERCENT040_1      => 31
    Percent040_2        WIN_APP_STATE_PERCENT040_2      => 32
    Percent050_1        WIN_APP_STATE_PERCENT050_1      => 33
    Percent050_2        WIN_APP_STATE_PERCENT050_2      => 34
    Percent060_1        WIN_APP_STATE_PERCENT060_1      => 35
    Percent060_2        WIN_APP_STATE_PERCENT060_2      => 36
    Percent070_1        WIN_APP_STATE_PERCENT070_1      => 37
    Percent070_2        WIN_APP_STATE_PERCENT070_2      => 38
    Percent080_1        WIN_APP_STATE_PERCENT080_1      => 39
    Percent080_2        WIN_APP_STATE_PERCENT080_2      => 40
    Percent090_1        WIN_APP_STATE_PERCENT090_1      => 41
    Percent090_2        WIN_APP_STATE_PERCENT090_2      => 42
    Percent100_1        WIN_APP_STATE_PERCENT100_1      => 43
    Percent100_2        WIN_APP_STATE_PERCENT100_2      => 44

=over

=cut

push @{$EXPORT_TAGS{const}}, qw(
    WIN_APP_STATE_NONE
    WIN_APP_STATE_ACTIVE1
    WIN_APP_STATE_ACTIVE2
    WIN_APP_STATE_ERROR1
    WIN_APP_STATE_ERROR2
    WIN_APP_STATE_FATAL_ERROR1
    WIN_APP_STATE_FATAL_ERROR2
    WIN_APP_STATE_IDLE1
    WIN_APP_STATE_IDLE2
    WIN_APP_STATE_WAITING1
    WIN_APP_STATE_WAITING2
    WIN_APP_STATE_WORKING1
    WIN_APP_STATE_WORKING2
    WIN_APP_STATE_NEED_USER_INPUT1
    WIN_APP_STATE_NEED_USER_INPUT2
    WIN_APP_STATE_STRUGGLING1
    WIN_APP_STATE_STRUGGLING2
    WIN_APP_STATE_DISK_TRAFFIC1
    WIN_APP_STATE_DISK_TRAFFIC2
    WIN_APP_STATE_NETWORK_TRAFFIC1
    WIN_APP_STATE_NETWORK_TRAFFIC2
    WIN_APP_STATE_OVERLOADED1
    WIN_APP_STATE_OVERLOADED2
    WIN_APP_STATE_PERCENT000_1
    WIN_APP_STATE_PERCENT000_2
    WIN_APP_STATE_PERCENT010_1
    WIN_APP_STATE_PERCENT010_2
    WIN_APP_STATE_PERCENT020_1
    WIN_APP_STATE_PERCENT020_2
    WIN_APP_STATE_PERCENT030_1
    WIN_APP_STATE_PERCENT030_2
    WIN_APP_STATE_PERCENT040_1
    WIN_APP_STATE_PERCENT040_2
    WIN_APP_STATE_PERCENT050_1
    WIN_APP_STATE_PERCENT050_2
    WIN_APP_STATE_PERCENT060_1
    WIN_APP_STATE_PERCENT060_2
    WIN_APP_STATE_PERCENT070_1
    WIN_APP_STATE_PERCENT070_2
    WIN_APP_STATE_PERCENT080_1
    WIN_APP_STATE_PERCENT080_2
    WIN_APP_STATE_PERCENT090_1
    WIN_APP_STATE_PERCENT090_2
    WIN_APP_STATE_PERCENT100_1
    WIN_APP_STATE_PERCENT100_2
    WindowAppState
);

use constant {
    WIN_APP_STATE_NONE                 =>0,
    WIN_APP_STATE_ACTIVE1              =>1,
    WIN_APP_STATE_ACTIVE2              =>2,
    WIN_APP_STATE_ERROR1               =>3,
    WIN_APP_STATE_ERROR2               =>4,
    WIN_APP_STATE_FATAL_ERROR1         =>5,
    WIN_APP_STATE_FATAL_ERROR2         =>6,
    WIN_APP_STATE_IDLE1                =>7,
    WIN_APP_STATE_IDLE2                =>8,
    WIN_APP_STATE_WAITING1             =>9,
    WIN_APP_STATE_WAITING2             =>10,
    WIN_APP_STATE_WORKING1             =>11,
    WIN_APP_STATE_WORKING2             =>12,
    WIN_APP_STATE_NEED_USER_INPUT1     =>13,
    WIN_APP_STATE_NEED_USER_INPUT2     =>14,
    WIN_APP_STATE_STRUGGLING1          =>15,
    WIN_APP_STATE_STRUGGLING2          =>16,
    WIN_APP_STATE_DISK_TRAFFIC1        =>17,
    WIN_APP_STATE_DISK_TRAFFIC2        =>18,
    WIN_APP_STATE_NETWORK_TRAFFIC1     =>19,
    WIN_APP_STATE_NETWORK_TRAFFIC2     =>20,
    WIN_APP_STATE_OVERLOADED1          =>21,
    WIN_APP_STATE_OVERLOADED2          =>22,
    WIN_APP_STATE_PERCENT000_1         =>23,
    WIN_APP_STATE_PERCENT000_2         =>24,
    WIN_APP_STATE_PERCENT010_1         =>25,
    WIN_APP_STATE_PERCENT010_2         =>26,
    WIN_APP_STATE_PERCENT020_1         =>27,
    WIN_APP_STATE_PERCENT020_2         =>28,
    WIN_APP_STATE_PERCENT030_1         =>29,
    WIN_APP_STATE_PERCENT030_2         =>30,
    WIN_APP_STATE_PERCENT040_1         =>31,
    WIN_APP_STATE_PERCENT040_2         =>32,
    WIN_APP_STATE_PERCENT050_1         =>33,
    WIN_APP_STATE_PERCENT050_2         =>34,
    WIN_APP_STATE_PERCENT060_1         =>35,
    WIN_APP_STATE_PERCENT060_2         =>36,
    WIN_APP_STATE_PERCENT070_1         =>37,
    WIN_APP_STATE_PERCENT070_2         =>38,
    WIN_APP_STATE_PERCENT080_1         =>39,
    WIN_APP_STATE_PERCENT080_2         =>40,
    WIN_APP_STATE_PERCENT090_1         =>41,
    WIN_APP_STATE_PERCENT090_2         =>42,
    WIN_APP_STATE_PERCENT100_1         =>43,
    WIN_APP_STATE_PERCENT100_2         =>44,

    WindowAppState => [qw(
	    None
	    Active1
	    Active2
	    Error1
	    Error2
	    FatalError1
	    FatalError2
	    Idle1
	    Idle2
	    Waiting1
	    Waiting2
	    Working1
	    Working2
	    NeedUserInput1
	    NeedUserInput2
	    Struggling1
	    Struggling2
	    DiskTraffic1
	    DiskTraffic2
	    NetworkTraffic1
	    NetworkTraffic2
	    Overloaded1
	    Overloaded2
	    Percent000_1
	    Percent000_2
	    Percent010_1
	    Percent010_2
	    Percent020_1
	    Percent020_2
	    Percent030_1
	    Percent030_2
	    Percent040_1
	    Percent040_2
	    Percent050_1
	    Percent050_2
	    Percent060_1
	    Percent060_2
	    Percent070_1
	    Percent070_2
	    Percent080_1
	    Percent080_2
	    Percent090_1
	    Percent090_2
	    Percent100_1
	    Percent100_2
    )],
};

=item B<get_WIN_APP_STATE>(I<$X>,I<$window>) => I<$state> or undef

Gets the application state, I<$state>, associated with a given window,
I<$window>.  The value is interpreted scalar as described under
L</_WIN_APP_STATE>, above.

=cut

sub get_WIN_APP_STATE {
    return getWMPropertyInterp($_[0],$_[1],_WIN_APP_STATE=>WindowAppState=>WindowAppState());
}

=item B<set_WIN_APP_STATE>(I<$X>,I<$window>,I<$state>)

Sets the application state, I<$state>, associated with a given window,
I<$window>.  The value is interpreted scalar as described under
L</_WIN_APP_STATE>, above.  THis property should only be set directly by
the application.

=cut

sub set_WIN_APP_STATE {
    return setWMPropertyInterp($_[0],$_[1],_WIN_APP_STATE=>WindowAppState=>WindowAppState(),$_[2]);
}

=item B<dmp_WIN_APP_STATE>(I<$X>,I<$state>)

Prints to standard output the value of get_WIN_APP_STATE().

=cut

sub dmp_WIN_APP_STATE {
    return dmpWMPropertyInterp($_[0],_WIN_APP_STATE=>state=>$_[1]);
}

=back


=head2 State change requests

After an application has mapped a window, it may wish to change its own
state.  To do this the client sends ClientMessages to the root window
with information on how to change the application's state. Clients will
send messages as follows:

 Display *disp;
 Window root, client_window;
 XClientMessageEvent xev;
 CARD32 new_layer;

 xev.type = ClientMessage;
 xev.window = client_window;
 xev.message_type = XInternAtom(disp, XA_WIN_LAYER, False);
 xev.format = 32;
 xev.data.l[0] = new_layer;
 XSendEvent(disp, root, False, SubstructureNotifyMask, (XEvent *) &xev);

 Display *disp;
 Window root, client_window;
 XClientMessageEvent xev;
 CARD32 mask_of_members_to_change, new_members;

 xev.type = ClientMessage;
 xev.window = client_window;
 xev.message_type = XInternAtom(disp, XA_WIN_STATE, False);
 xev.format = 32;
 xev.data.l[0] = mask_of_members_to_change;
 xev.data.l[1] = new_members;
 XSendEvent(disp, root, False, SubstructureNotifyMask, (XEvent *) &xev);

If an application wishes to change the current active desktop it will
send a client message to the root window as follows:

 Display *disp;
 Window root, client_window;
 XClientMessageEvent xev;
 CARD32 new_desktop_number;

 xev.type = ClientMessage;
 xev.window = client_window;
 xev.message_type = XInternAtom(disp, XA_WIN_WORKSPACE, False);
 xev.format = 32;
 xev.data.l[0] = new_desktop_number;
 XSendEvent(disp, root, False, SubstructureNotifyMask, (XEvent *) &xev);

If the Window Manager picks up any of these ClientMessage events it
should honor them.

=head2 Button press and release forwarding for the desktop window

X imposes the limitation that only 1 client can be selected for button
presses on a window - this is due to the implicit grab nature of button
press events in X. This poses a problem when more than one client wishes
to select for these events on the same window - E.g., the root window,
or in the case of a WM that has more than one root window (virtual
root windows) any of these windows. The solution to this is to have the
client that receives these events handle any of the events it is
interested in, and then "proxy" or "pass on" any events it does not care
about. The traditional model has always been that the WM selects for
button presses on the desktop, it is only natural that it keep doing
this BUT have a way of sending unwanted presses onto some other
process(es) that may well be interested.

This is done as follows:

=over

=item 1.

Set a property on the root window called _WIN_DESKTOP_BUTTON_PROXY.  It
is of the type cardinal - its value is the Window ID of another window
that is not mapped and is created as an immediate child of the root
window. This window also has this property set on it pointing to itself.

 Display *disp;
 Window root, bpress_win;
 Atom atom_set;
 CARD32 val;

 atom_set = XInternAtom(disp, "_WIN_DESKTOP_BUTTON_PROXY", False);
 bpress_win = ECreateWindow(root, -80, -80, 24, 24, 0);
 val = bpress_win;
 XChangeProperty(disp, root, atom_set, XA_CARDINAL, 32,

 PropModeReplace, (unsigned char *)&val, 1);
 XChangeProperty(disp, bpress_win, atom_set, XA_CARDINAL, 32,
     PropModeReplace, (unsigned char *)&val, 1);

=item 2.

Whenever the WM gets a button press or release event it can check the
button on the mouse pressed, any modifiers, etc. - if the WM wants the
event it can deal with it as per normal and not proxy it on - if the WM
does not wish to do anything as a result of this event, then it should
pass the event along like the following:

 Display *disp;
 Window bpress_win;
 XEvent *ev;
 
 XUngrabPointer(disp, CurrentTime);
 XSendEvent(disp, bpress_win, False, SubstructureNotifyMask, ev);

where ev is a pointer to the actual Button press or release event it
receives from the X Server (retaining timestamp, original window ID,
coordinates etc.) NB - the XUngrabPointer is only required before
proxying a press, not a release.

The WM should proxy both button press and release events. It should only
proxya release if it also proxied the press corresponding to that
release.  It is the responsibility of any applications listening for
these events (and as many applications as want to can since they are
being sent under the guise of SubstructureNotify events), to handle
grabbing the pointer again and handling all events for the mouse while
pressed until release etc.

=back

=head3 _WIN_DESKTOP_BUTTON_PROXY, CARDINAL/32

Note that the proxy window is save as type C<CARDINAL> even though its
contents are of type C<WINDOW>.

=over

=cut

=item B<get_WIN_DESKTOP_BUTTON_PROXY>(I<$X>,I<$root>) => I<$proxy>

Gets the window, I<$proxy>, acting as the desktop button proxy, or
C<undef> if no such window exists.

=cut

sub get_WIN_DESKTOP_BUTTON_PROXY {
    return getWMRootPropertyUint($_[0],_WIN_DESKTOP_BUTTON_PROXY=>$_[1]);
}

=item B<get_WIN_DESKTOP_BUTTON_PROXY>(I<$X>,I<$proxy>)

Sets the window, I<$proxy>, acting as the desktop button proxy, or,
when I<$proxy> is C<undef>, deletes the C<_WIN_DESKTOP_BUTTON_PROXY>
property from the root window.

=cut

sub set_WIN_DESKTOP_BUTTON_PROXY {
    return setWMRootPropertyUint($_[0],_WIN_DESKTOP_BUTTON_PROXY=>CARDINAL=>$_[1]);
}

=item B<dmp_WIN_DESKTOP_BUTTON_PROXY>(I<$X>,I<$proxy>)

Prints to standard output the value of get_WIN_DESKTOP_BUTTON_PROXY().

=cut

sub dmp_WIN_DESKTOP_BUTTON_PROXY {
    return dmpWMRootPropertyUint($_[0],_WIN_DESKTOP_BUTTON_PROXY=>proxy=>$_[1]);
}

=back


=head2 Desktop Areas as opposed to multiple desktops

The best way to explain this is as follows. Desktops are completely
geometrically disjoint workspaces. They have no geometric relevance to
each other in terms of the client window plane. Desktop Areas have
geometric relevance - they are next to, above, or below each other. The
best examples are FVWM's desktops and virtual desktops - you can have
multiple desktops that are disjoint and each desktop can be N x M
screens in size - these N x M areas are what are termed "desktop areas"
for the purposes of this document and the WM API.  If your WM supports
both methods like FVMW, Enlightenment and possible others, you should
use _WIN_WORKSPACE messages and atoms for the geometrically disjoint
desktops - for geometrically arranged desktops you should use the
_WIN_AREA messages and atoms.  If you only support one of these it is
preferable to use _WIN_WORKSPACE only.  The API for _WIN_AREA is very
similar to _WIN_WORKSPACE.

=cut

=head3 _WIN_AREA_COUNT, CARDINAL[]/32

To advertise the size of your areas (E.g., N x M screens in size) you
set an atom on the root window as follows:

 Display *disp;
 Window root;
 Atom atom_set;
 CARD32 val[2];

 atom_set = XInternAtom(disp, "_WIN_AREA_COUNT", False);
 val[0] = number_of_screens_horizontally;
 val[1] = number_of_screens_vertically;
 XChangeProperty(disp, root, atom_set, XA_CARDINAL, 32,
	 PropModeReplace, (unsigned char *)val, 2);

=head4 Methods

In the methods that follow, I<$count> is a reference to an array of two
values: columns and rows, respectively.

=over

=cut

=item B<get_WIN_AREA_COUNT>(I<$X>,I<$root>) => I<$count>

Get the number of columns and rows of screens provided by the large
desktop area.  When large desktops are not supported, this value will be
(1,1).

=cut

sub get_WIN_AREA_COUNT {
    return getWMRootPropertyUints($_[0],_WIN_AREA_COUNT=>$_[1]);
}

=item B<set_WIN_AREA_COUNT>(I<$X>,I<$count>)

Set the number of columns and rows of screens provided by the large
desktop area.  When large desktops are not supported, this value will
always be (1,1).

=cut

sub set_WIN_AREA_COUNT {
    return setWMRootPropertyUints($_[0],_WIN_AREA_COUNT=>$_[1]);
}

=item B<dmp_WIN_AREA_COUNT>(I<$X>,I<$count>)

Prints to standard output the value of get_WIN_AREA_COUNT().

=cut

sub dmp_WIN_AREA_COUNT {
    return dmpWMRootPropertyUints($_[0],_WIN_AREA_COUNT=>'cols, rows',$_[1]);
}

=back

=head3 _WIN_AREA, CARDINAL[]/32

To advertise which desktop area is currently the active one:

 Display *disp;
 Window root;
 Atom atom_set;
 CARD32 val[2];

 atom_set = XInternAtom(disp, "_WIN_AREA", False);
 val[0] = current_active_area_x; /* starts at 0 */
 val[1] = current_active_area_y; /* starts at 0 */
 XChangeProperty(disp, root, atom_set, XA_CARDINAL, 32,
	 PropModeReplace, (unsigned char *)val, 2);

If a client wishes to change what the current active area is they simply send a
client message like:

 Display *disp;
 Window root;
 XClientMessageEvent xev;

 xev.type = ClientMessage;
 xev.window = root;
 xev.message_type = XInternAtom(disp, "_WIN_AREA", False);
 xev.format = 32;
 xev.data.l[0] = new_active_area_x;
 xev.data.l[1] = new_active_area_y;
 XSendEvent(disp, root, False, SubstructureNotifyMask, (XEvent *) &xev);

=head4 Methods

In the methods that follow, I<$area> is a reference to an array of two
values: column and row, respectively.

=over

=cut

=item B<get_WIN_AREA>(I<$X>,I<$root>) => I<$area>

Return the current workspace area as a column index (starting at zero
0), C<$col>, and a row index (starting at 0), C<$row>.  Returns the
current area as an array reference.

=cut

sub get_WIN_AREA {
    return getWMRootPropertyUints($_[0],_WIN_AREA=>$_[1]);
}

=item B<set_WIN_AREA>(I<$X>,I<$area>)

Sets the current workspace area as a column index (starting at zero
0), C<$col>, and a row index (starting at 0), C<$row>.  I<$area>, when
defined, is a reference to an array containing the two indices.  This
property should only be set directly by a window manager.  Pagers should
use req_WIN_AREA().

=cut

sub set_WIN_AREA {
    return setWMRootPropertyUints($_[0],_WIN_AREA=>$_[1]);
}

=item B<dmp_WIN_AREA>(I<$X>,I<$area>)

Prints to standard output the value of get_WIN_AREA().

=cut

sub dmp_WIN_AREA {
    return dmpWMRootPropertyUints($_[0],_WIN_AREA=>'cols, rows',$_[1]);
}

=item B<req_WIN_AREA>(I<$X>,I<$col>,I<$row>,I<$timestamp>)

Sets the active area within the workspace to the area starting at index,
C<$col>, C<$row> using the following client message:

 _WIN_AREA
   window = root
   message_type = _WIN_AREA
   format = 32
   data.l[0] = new_active_area_x
   data.l[1] = new_active_area_y
   other data.l[] elements = 0

=cut

sub req_WIN_AREA {
    my($X,$col,$row,$timestamp) = @_;
    $timestamp = 0 unless $timestamp;
    $timestamp = 0 if $timestamp eq 'CurrentTime';
    WinClientMessage($X,$X->root,_WIN_AREA=>[$col,$row,$timestamp]);
}

sub got_WIN_AREA {
    my($X,$window,$col,$row,$timestamp) = @_;
    $timestamp = 'CurrentTime' unless $timestamp;
    return ($window,$col,$row,$timestamp);
}

=back

=cut

foreach my $pfx (qw(get set dmp req)) {
    push @{$EXPORT_TAGS{$pfx}},
	 grep {/^$pfx/} @{$EXPORT_TAGS{all}};
}

Exporter::export_ok_tags('all');

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>, L<XDE::ICCCM(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
