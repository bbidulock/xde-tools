use X11:Protocol;
use X11:AtomConstants;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

%EXPORT_TAGS = (
    all => [qw(
    )],
    req => [qw(
    )],
);

=head1 NAME

X11::Protocol::MWMH -- provides methods for controlling window manager hints.

=head1 SYNOPSIS

 Use X11::Protocol::MWMH;

 my $mwmh = X11::Protocol::MWMH->new();

 $mwmh->get_MOTIF_WM_INFO();

=head1 DESCRIPTION

Provides a modules with methods that can be used to contorl a MWMH
compliant window manager (e.g. MWM and DTWM).  Note: not all that may
window managers are MWMH compliant anymore.  Many that are EWMH
compliant have removed support for MWMH.  Many, however, support the
client set C<_MOTIF_WM_HINTS>.  I added ful support to L<etwm(1)> and
L<echinus(1)> in an attempt to more gracefully support old OSF/Motif CDE
applications like L<xephem(1)>, and L<xpdf(1)>.

=head1 METHODS

The following methods are provided by this module.

=head2 OSF/Motif Properties

=head3 WM_DESKTOP

Lesstif MWM uses this property for desktops like _WIN_WORKSPACE.  It
sets it both on client windows and on the root window.

=head3 _MOTIF_BINDINGS

Provides the bindings of some buttons and keys to the Motif toolkit
buttons and keys.  This is very Motif specific and unnecessary when
mimicing MWM and DTWM behavior.  We do not actually get or set this
property.

=head3 _MOTIF_DEFAULT_BINDINGS

Perovie the default bindings of some buttons and keys to the Motif
toolkit buttons and keys.  This is very Motif specific and unnecessary
when mimicing MWM behavior.  We do not actually get or set this
property.

=head3 _MOTIF_WM_HINTS flags funcs decors input_mode status _MOTIF_WM_HINTS/8

This property is provided on a window before it is initially mapped and
specifies the function, decorations, input_mode and status of the
application window.

The flags field indicates the presence of the other files with a bitmask
as follows:

    MWM_HINTS_FUNCTIONS     - the function field is valid
    MWM_HINTS_DECORATIONS   - the decorations field is valid
    MWM_HINTS_INPUT_MODE    - the intput_mode field is valid
    MWM_HINTS_STATUS        - the status field is valid

The function field is a bitmask of any of the following:

    MWM_FUNC_ALL            - all functions
    MWM_FUNC_RESIZE         - whether the window can be resized
    MWM_FUNC_MOVE           - whether the window can be moved
    MWM_FUNC_MINIMIZE       - whether the window can be minimized
    MWM_FUNC_MAXIMIZE       - whether the window can be maximised
    MWM_FUNC_CLOSE          - whether the window can be closed

The decorations field is a bitmask of any of the following:

    MWM_DECOR_ALL           - all decorations
    MWM_DECOR_BORDER        - whether a decorative border is provided
    MWM_DECOR_RESIZEH       - whether resize handles are provided
    MWM_DECOR_TITLE         - whether a title bar is provdied
    MWM_DECOR_MENU          - whether a menu button is provided
    MWM_DECOR_MINIMIZE      - whether a minimize button is provided
    MWM_DECOR_MAXIMIZE      - whether a maximize button is provided

The input mode field is one of the following:

    MWM_INPUT_MODELESS           - normal
    MWM_INPUT_APPLICATION_MODAL  - model for window group
    MWM_INPUT_SYSTEM_MODAL       - model for all windows

The status field is a bitmask of any of the following:

    MWM_TEAROFF_WINDOW       - window is a tear-off menu

=cut

use constant {
    MWM_HINTS_FUNCTIONS		=> (1<<0),
    MWM_HINTS_DECORATIONS	=> (1<<1),
    MWM_HINTS_INPUT_MODE	=> (1<<2),
    MWM_HINTS_STATUS		=> (1<<3),

    MWM_FUNC_ALL		=> (1<< 0),
    MWM_FUNC_RESIZE		=> (1<< 1),	# like _NET_WM_ACTION_RESIZE
    MWM_FUNC_MOVE		=> (1<< 2),	# like _NET_WM_ACTION_MOVE
    MWM_FUNC_MINIMIZE		=> (1<< 3),	# like _NET_WM_ACTION_MINIMIZE
    MWM_FUNC_MAXIMIZE		=> (1<< 4),	# like _NET_WM_ACTION_(FULLSCREEN|MAXIMIZE_(HORZ|VERT)) 
    MWM_FUNC_CLOSE		=> (1<< 5),	# like _NET_WM_ACTION_CLOSE
    # following non-standard
    MWM_FUNC_SHADE		=> (1<< 6),	# like _NET_WM_ACTION_SHADE
    MWM_FUNC_STICK		=> (1<< 7),	# like _NET_WM_ACTION_STICK
    MWM_FUNC_FULLSCREEN		=> (1<< 8),	# like _NET_WM_ACTION_FULLSCREEN
    MWM_FUNC_ABOVE		=> (1<< 9),	# like _NET_WM_ACTION_ABOVE
    MWM_FUNC_BELOW		=> (1<<10),	# like _NET_WM_ACTION_BELOW
    MWM_FUNC_MAXIMUS		=> (1<<11),	# like _NET_WM_ACTION_MAXIMIS_(LEFT|RIGHT|TOP|BOTTOM)

    MWM_DECOR_ALL		=> (1<< 0),
    MWM_DECOR_BORDER		=> (1<< 1),
    MWM_DECOR_RESIZEH		=> (1<< 2),
    MWM_DECOR_TITLE		=> (1<< 3),
    MWM_DECOR_MENU		=> (1<< 4),
    MWM_DECOR_MINIMIZE		=> (1<< 5),
    MWM_DECOR_MAXIMIZE		=> (1<< 6),
    # following non-standard buttons
    MWM_DECOR_CLOSE		=> (1<< 7),
    MWM_DECOR_RESIZE		=> (1<< 8),
    MWM_DECOR_SHADE		=> (1<< 9),
    MWM_DECOR_STICK		=> (1<<10),
    MWM_DECOR_MAXIMUS		=> (1<<11),

    MWM_INPUT_MODELESS			=> (1<< 0),
    MWM_INPUT_PRIMARY_APPLICATION_MODAL	=> (1<< 1),
    MWM_INPUT_SYSTEM_MODAL		=> (1<< 2),
    MWM_INPUT_FULL_APPLICATION_MODAL	=> (1<< 3),
    MWM_INPUT_APPLICATION_MODAL		=> (1<< 1),

    MWM_TEAROFF_WINDOW		=> (1<< 0),
};

=over

=back

=head3 _MOTIF_WM_MESSAGES, _MOTIF_WM_OFFSET

This atom is used by a client in C<WM_PROTOCOLS> to indicate its desire
to receive C<_MOTIF_WM_OFFSET> messages.  When the protoocol is present,
MWM and DTWM will generate C<_MOTIF_WM_OFFSET> messages to the client
when the client window s intially mapped to indicate the offset from the
gravity reference point of the client window within the decorative frame
and borders.

A C<_MOTIF_WM_OFFSET> message is a C<_MOTIF_WM_MESSAGES> message type
that contains the C<_MOTIF_WM_OFFSET> atom int he data.l[0] element.
The data.l[1] and data.l[2] components contain the x and y of the client
window within its decorative border and frame considering the gravity
specified by the client for the window in the C<WM_HINTS> property.

=head3 _MOTIF_WM_MENU

=head3 _MOTIF_WM_INFO flags, wm_window _MOTIF_WM_INFO/32

This property is placed on the root window to identify the startup mode
and the main window manage window.  The main window is similar to the
supporting window manager check window of WinWM/WMW or NetWM/EWMH, ecept
that this is not a recursive property.

The Lesstif window manager (MWM) places this property on the root window
and sets the wm_window field (unfortunately) to the root window.
Openmotif MWM sets the wm_window field to the primary window manager
window (the one with WM_CLASS of 'mwm', 'Mwm').  To indicate motif
window manager support, we set the property on the root window to point
to the primary check window (the supporting wm check window for WinWM
and NetWM as well as the owner of the ICCCM 2.0 WM_S%d selection for the
screen.

This property is set by the window manager.

The I<flags> field is either

  MWM_STARTUP_STANDARD	    - I suppose a defalt startup file
  MWM_STARTUP_CUSTOM	    - I suppose a user-specified startup file

The I<wm_window> field points to the primary MWM/DTWM window.

=cut

use constant {
    MWM_STARTUP_STANDARD => (1<<0),
    MWM_STARTUP_CUSTOM => (1<<1),
};

=head2 DTWM Properties

=head3 _DT_WORKSPACE_HINTS version flags wsflags num [wkspc ...] _DT_WORKSPACE_HINTS/32

THis property is a list of atoms placed by the client on its top elvel
window(s).  Each atom is an "interned" string name for a workspace.  The
workspace manager looks at this property when it manages the window
(e.g. when the window is mapped) and will palce the window in the
workspace listed.

The client sets this property.

The version field is always one (1).

The flags field indicates the valid fields and contains a bitmask of the
following bits:

    DT_WORKSPACE_HINTS_WSFLAGS      - wsflags field is valid
    DT_WORKSPACE_HINTS_WORKSPACES   - numWorkspaces field is valid

The wsflags field is a bitmask contians the following bits:

    DT_WORKSPACE_FLAGS_OCCUPY_ALL   - occupy all workspaces

=cut

use constant {
    DT_WORKSPACE_HINTS_WSFLAGS		=> (1<< 0),
    DT_WORKSPACE_HINTS_WORKSPACES	=> (1<< 1),

    DT_WORKSPACE_FLAGS_OCCUPY_ALL	=> (1<< 0),
};

=head3 _DT_WORKSPACE_PRESENCE

This property is a list of atoms places on a client by L<dtwm(1)>.  Each
atom is a "interned" string name for workspace.  This property lists the
workspaces that this client lives in.

The window manager sets this property.

=head3 _DT_WORKSPACE_LIST

This property is a list of atoms.  Each atom represents a name of a
workspace.  The list is in "order" such that the first element is for
the first workspace and so on.  This property is placed on the mwm
window.

=head3 _DT_WORKSPACE_CURRENT

This property is a single atom, representing the current workspace.  it
is updated each time the workspace changes.  This propert is placed on
the mwm window.

The window manager sets this property.

=head3 _DT_WORKSPACE_INFO_<name> _DT_WORKSPACE_INFO/8

There is one property of this form for each workspace in
_DT_WORKSPACE_LIST.  THis property is a sequence of ISO-LATIN1
NULL-terminated strings representing the elements in a structure.  This
information was formerly in _DT_WORKSPACE_INFO but was broken out to
allow for extensibility.  THis property is placed on the MWM window.

The window manager sets this property.

The property contains:

    %s    title of the workspace
    %d    color set
    0x%lx backdrop background
    0x%lx backdrop foreground
    0x%lx backdrop name atom
    %d    number of backdrop windows
    0x%lx backdrop window
    0x%lx backdrop window ... for number of backdrop windows

=head3 _DT_WORKSPACE_INFO _DT_WORKSPACE_INFO/8

=head3 _DT_WM_HINTS flags functions behaviours attachWindow _DT_WM_HINTS/32

This peroperty requests specific window/workspace management behaviour.
The functions member of the property allows a client to enable or
disable worskpace management functions.  The behaviour member is used to
inciate front panels and slide-ups.

The client sets this property.

The flags field is a bitwise OR of the following:

    DTWM_HINTS_FUNCTIONS              (1<<0) - 
    DTWM_HINTS_BEHAVIORS              (1<<1)
    DTWM_HINTS_ATTACH_WINDOW          (1<<2)

    DTWM_FUNCTION_ALL                 (1<<0)
    DTWM_FUNCTION_OCCUPY_WS           (1<<1)

    DTWM_BEHAVIOR_PANEL               (1<<1)
    DTWM_BEHAVIOR_SUBPANEL            (1<<2)
    DTWM_BEHAVIOR_SUB_RESTORED        (1<<3)

=cut

use constant {
    DTWM_HINTS_FUNCTIONS => (1<<0),
    DTWM_HINTS_BEHAVIORS => (1<<1),
    DTWM_HINTS_ATTACH_WINDOW => (1<<2),

    DTWM_FUNCTION_ALL => (1<<0),
    DTWM_FUNCTION_OCCUPY_WS => (1<<1),

    DTWM_BEHAVIOR_PANEL => (1<<1),
    DTWM_BEHAVIOR_SUBPANEL => (1<<2),
    DTWM_BEHAVIOR_SUB_RESTORED => (1<<3),
};


=head3 _DT_WM_REQUEST

This property is of type string that is used to communicate function
requests to L<dtwm(1)>.  This property is placed on the mwm window.
Dtwm listens for changes to this property and dequeues reqeusts off the
top of the list.  Requests are NULL-terminated strings in the format:

    <req_type> <req_parms>

Each request ends with a literal '\0' character to insure separation
from the next request.

Clients must always add request to the end of the property (mode =
PropModeAppend).  Use of convenience routines is recommended since they
take care of proper formatting of the requests.

This property is changed by the client and window manager.

An example is appending

    f.restart

to restart the window manager.  Another is

    f.change_backdrop /usr/share/images/penguins/penguin.jpg 000003f

=head3 _DT_WORKSPACE_EMBEDDED_CLIENTS _DT_WORKSPACE_EMBEDDED_CLIENTS/32

This property is a list (array) of top-level windows that are embedded
in the front panel of the window manager.  They would not be picked up
ordinarily by a session manager in a nromal search for top-level windows
because they are reparented to the front panel which itself is a
top-level window.

=head3 _DT_WMSAVE_HINT flags _DT_WMSAVE_HINT/32

This hint is set on a window by the client.  It tells the window manager
which properties of the window should be saved for session management.
Some window managers (like L<fluxbox(1)>) have the ability to save this
information in a file.

=cut

use constant {
    WMSAVE_X			=> (1<< 0),
    WMSAVE_Y			=> (1<< 1),
    WMSAVE_WIDTH		=> (1<< 2),
    WMSAVE_HEIGHT		=> (1<< 3),
    WMSAVE_STATE		=> (1<< 4),
    WMSAVE_WORKSPACES		=> (1<< 5),
    WMSAVE_ICON_X		=> (1<< 6),
    WMSAVE_ICON_Y		=> (1<< 7),
};

=head2 Properties related to Drag and Drop.

=head3 _MOTIF_DRAG_WINDOW

=head3 _MOTIF_DRAG_PROXY_WINDOW

=head3 _MOTIF_DRAG_ATOM_PAIRS

=head3 _MOTIF_DRAG_TARGETS

=head3 _MOTIF_DRAG_INITIATOR_INFO

=head3 _MOTIF_DRAG_RECEIVER_INFO

=head3 _MOTIF_DRAG_MESSAGE

=head3 _MOTIF_DRAG_AND_DROP_MESSAGE


=over

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>, L<XDE::ICCCM(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
