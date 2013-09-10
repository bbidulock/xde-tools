package XDE::ICCCM;
use X11::Protocol;
use strict;
use warnings;

=head1 NAME

XDE::ICCCM -- provide methods for controlling ICCCM window manager functions.

=head1 SYNOPSIS

 use XDE::ICCCM;

 my $icccm = XDE::ICCCM->new();

 $icccm->get_XSETTINGS_S(0);

=head1 DESCRIPTION

Provides a module with methods that can be used to control a ICCCM
compliant window manager.

=head1 METHODS

The following methods are provided by the module.  Most of these are for
use by derived modules.

=over

=cut

=item $icccm->B<GetProperty>($win,$prop,$type,$format) => $data

Get a property from a window and return its full-length packed data
representation.  Returns C<undef> if the property does not exist.

=cut

sub GetProperty {
    my ($self,$win,$prop,$type) = @_;
    my $X = $self->{X};
    $win = $X->root unless $win;
    my $atom = $X->atom($prop);
    $type = 0 unless $type;
    my ($data,$val,$after,$format,$error);
    $error = $X->robust_req(GetProperty=>$win,$atom,$type,0,1);
    if (ref $error eq 'ARRAY') {
	($val,$type,$format,$after) = @$error;
	if ($val) {
	    if ($after) {
		my $part = $val;
		$error = $X->robust_req(GetProperty=>$win, $atom, $type, 1, (($after+3)>>2));
		if (ref $error eq 'ARRAY') {
		    ($val) = @$error;
		    $data = $part.$val;
		} else {
		    warn sprintf "Could not get property %s for window 0x%x", $prop, $win;
		}
	    } else {
		$data = $val;
	    }
	} else {
	    warn sprintf "Could not get property %s for window 0x%x", $prop, $win
		if $self->{ops}{verbose};
	}
    } else {
	warn sprintf "Could not get property %s for window 0x%x", $prop, $win;
    }
    return $data;
}

=item $icccm->B<ClientMessage>($targ,$win,$type,$data) => undef

Send a client message to a window, C<$targ>, with the specified window
as C<$win>, client message type the atom with name C<$type>, and
20-bytes of packed client message data, C<$data>.  The mask used is
C<StructureNotify> and C<SubstructureNotify>.

=cut

sub ClientMessage {
    my ($self,$target,$window,$type,$data) = @_;
    my $X = $self->{X};
    $target = $X->root unless $target;
    $window = $X->root unless $window;
    $X->SendEvent($target, 0,
	    $X->pack_event_mask(qw(
		    StructureNotify
		    SubstructureNotify
		    SubstructureRedirect)),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$window,
		format=>32,
		type=>$X->atom($type),
		data=>$data,
	    ));
    $X->flush;
}

=item $icccm->B<getWMRootPropertyDecode>($prop,$decode) => $value

Provides a method for obtaining a decoded property from the root window.
The property has atom name, C<$prop>, and decoder, C<$decode> is a
C<CODE> reference that accepts the packed data as an argument and
returns the decoded data.  This method is used by subsequent methods
below:

=over

=cut

sub getWMRootPropertyDecode {
    my ($self,$prop,$decode) = @_;
    if (my $data = $self->GetProperty(0,$prop)) {
	$self->{$prop} = &{$decode}($data);
    } else {
	warn "Could not retrieve property $prop!";
	delete $self->{$prop};
    }
    return $self->{$prop};
}

=item $icccm->B<getWMRootPropertyString>($prop) => $value

Returns C<$value> as a single scalar string value.

=cut

sub getWMRootPropertyString {
    my ($self,$prop) = @_;
    return $self->getWMRootPropertyDecode($prop,
	sub{ return unpack('Z*',shift); });
}

=item $icccm->B<getWMRootPropertyStrings>($prop) => $value

Returns C<$value> as a reference to an array of strings.

=cut

sub getWMRootPropertyStrings {
    my ($self,$prop) = @_;
    return $self->getWMRootPropertyDecode($prop,
	sub{ return [ unpack('(Z*)*',shift) ]; });
}

=item $icccm->B<getWMRootPropertyInt>($prop) => $value

Returns C<$value> as a single scalar integer value.

=cut

sub getWMRootPropertyInt {
    my ($self,$prop) = @_;
    return $self->getWMRootPropertyDecode($prop,
	sub{ return unpack('L',shift); });
}

=item $icccm->B<getWMRootPropertyInts>($prop) => $value

Returns C<$value> as an reference to an array of integer values.

=cut

sub getWMRootPropertyInts {
    my ($self,$prop) = @_;
    return $self->getWMRootPropertyDecode($prop,
	sub{ return [ unpack('L*',shift) ]; });
}

=item $icccm->B<getWMRootPropertyAtom>($prop) => $value

Returns C<$value> as a single scalar atom name.

=cut

sub getWMRootPropertyAtom {
    my ($self,$prop) = @_;
    my $X = $self->{X};
    return $self->getWMRootPropertyDecode($prop,
	sub{ return $X->atom_name(unpack('L',shift)); });
}

=item $icccm->B<getWMRootPropertyAtoms>($prop) => $value

Returns C<$value> as a reference to an array of atom names.

=cut

sub getWMRootPropertyAtoms {
    my ($self,$prop) = @_;
    my $X = $self->{X};
    return $self->getWMRootPropertyDecode($prop,
	sub{ return { map{$X->atom_name($_)=>1} unpack('L',shift) }; });
}

=back

=cut

=item $icccm->B<getWMPropertyDecode>($window,$prop,$decode)

Provides a method for obtaining a decoded property from a specified
window, C<$window>.  When undefined or zero, C<$window> defaults to
the active window.  The property has atom name, C<$prop>, and decoder,
C<$decode> is a C<CODE> reference that accepts the packed data as an
argument and returns the decoded data.  This method is usede by
subsequent methods below:

=over

=cut

sub getWMPropertyDecode {
    my ($self,$window,$prop,$decode) = @_;
    $window = $self->{_NET_ACTIVE_WINDOW} unless $window;
    $window = $self->{X}->root unless $window;
    if (my $data = $self->GetProperty($window, $prop)) {
	$self->{windows}{$window}{$prop} = &{$decode}($data);
    } else {
	delete $self->{windows}{$window}{$prop};
    }
    return $self->{windows}{$window}{$prop};

}

=item $icccm->B<getWMPropertyString>($window,$prop) => $value

Returns C<$value> as a single scalar string value.

=cut

sub getWMPropertyString {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return unpack('Z*',shift); });
}

=item $icccm->B<getWMPropertyStrings>($window,$prop) => $value

Returns C<$value> as a reference to an array of strings.

=cut

sub getWMPropertyStrings {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return [ unpack('(Z*)*',shift) ]; });
}

=item $icccm->B<getWMPropertyInt>($window,$prop) => $value

Returns C<$value> as a single scalar integer value.

=cut

sub getWMPropertyInt {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return unpack('L',shift); });
}

=item $icccm->B<getWMPropertyInts>($window,$prop) => $value

Returns C<$value> as an reference to an array of integer values.

=cut

sub getWMPropertyInts {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return [ unpack('L*',shift) ]; });
}

=item $icccm->B<getWMPropertyAtom>($window,$prop) => $value

Returns C<$value> as a single scalar atom name.

=cut

sub getWMPropertyAtom {
    my ($self,$window,$prop) = @_;
    my $X = $self->{X};
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return $X->atom_name(unpack('L',shift)); });
}

=item $icccm->B<getWMPropertyAtoms>($window,$prop) => $value

Returns C<$value> as a reference to an array of atom names.

=cut

sub getWMPropertyAtoms {
    my ($self,$window,$prop) = @_;
    my $X = $self->{X};
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return { map{$X->atom_name($_)=>1} unpack('L',shift) }; });
}

=item $icccm->B<getWMPropertyBits>($window,$prop) => $value

Returns C<$value> as a reference to an array of bit values or C<undef>
when the property, C<$prop>, does not exist on C<$window>.

=cut

sub getWMPropertyBits {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return [ map{unpack('b*',pack('V',$_))} unpack('L*',shift) ]; });
}

=back

=back

=head1 ICCCM Version 2.0 Methods

The ICCCM Version 2.0 Methods include: WM_STATE, WM_ICON_SIZE,
WM_NAME, WM_ICON_NAME, WM_NORMAL_HINTS, WM_HINTS, WM_CLASS,
WM_TRANSIENT_FOR, WM_PROTOCOLS, WM_DELETE_WINDOW, WM_TAKE_FOCUS,
WM_COLORMAP_WINDOWS, WM_CLIENT_MACHINE, WM_COLORMAP_WINDOWS,
WM_COLORMAP_NOTIFY.

=head2 Client properties

Client properties are properties that the client is repsonsible for
maintaining.  The following are client properties:

=head3 WM_NAME

The WM_NAME property is an unintepreted string that the client wants the
window manager to display in association with the window (for example,
in a window headline bar).

The encoding used for this string (and all other uninterpreted string
properties) is implied by the type of the property. The type atoms to be
used for this purpose are described in TEXT Properties.

Window managers are expected to make an effort to display this
information.  Simply ignoring WM_NAME is not acceptable behavior.
Clients can assume that at least the first part of this string is
visible to the user and that if the information is not visible to the
user, it is because the user has taken an explicit action to make it
invisible.

On the other hand, there is no guarantee that the user can see the
WM_NAME string even if the window manager supports window headlines. The
user may have placed the headline off-screen or have covered it by other
windows. WM_NAME should not be used for application-critical information
or to announce asynchronous changes of an application's state that
require timely user response. The expected uses are to permit the user
to identify one of a number of instances of the same client and to
provide the user with noncritical state information.

Even window managers that support headline bars will place some limit on
the length of the WM_NAME string that can be visible; brevity here will
pay dividends.

=over

=cut

=item $icccm->B<getWM_NAME>($window) => $name

Returns the name of associated with the window, C<$window>, or C<undef>
if there is no such property for C<$window>.

=cut

sub getWM_NAME {
    return $_[0]->getWMPropertyString($_[1],'WM_NAME');
}

=item $icccm->B<event_handler_PropertyNotifyWM_NAME>($e,$X,$v)

Event handler for changes in C<WM_NAME> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_NAME {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_NAME($e->{window});
}

=back

=head3 WM_ICON_NAME

The WM_ICON_NAME property is an uninterpreted string that the client
wants to be displayed in association with the window when it is
iconified (for example, in an icon label). In other respects, including
the type, it is similar to WM_NAME. For obvious geometric reasons, fewer
characters will normally be visible in WM_ICON_NAME than WM_NAME.

Clients should not attempt to display this string in their icon pixmaps
or windows; rather, they should rely on the window manager to do so.

=over

=cut

=item $icccm->B<getWM_ICON_NAME>($window) => $name

Returns the icon name associated with the window, C<$window>, or
C<undef> if there is no such property for C<$window>.

=cut

sub getWM_ICON_NAME {
    return $_[0]->getWMPropertyString($_[1],'WM_ICON_NAME');
}

=item $icccm->B<event_handler_PropertyNotifyWM_ICON_NAME>($e,$X,$v)

Event handler for changes in C<WM_ICON_NAME> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_ICON_NAME {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_ICON_NAME($e->{window});
}

=back

=head3 WM_NORMAL_HINTS

The type of WM_NORMAL_HINTS property is WM_SIZE_HINTS.  Its contents are
as follows:

 flags		CARD32	    (see the next table)
 pad		4*CARD32    For backward compatibility
 min_width	INT32	    If missing, assume base_width
 min_heigth	INT32	    if missing, assume base_height
 max_width	INT32
 max_heigth	INT32
 width_inc	INT32
 height_inc	INT32
 min_aspect	(INT32,INT32)
 max_aspect	(INT32,INT32)
 base_width	INT32	    If missing, assume min_width
 base_height	INT32	    If missing, assume min_height
 win_gravity	INT32	    If missing, assume NorthWest

The flags field bit defintions are as follows:

 USPosition	0x001	    User-specified x,y
 USSize		0x002	    user-specified width,height
 PPosition	0x004	    Program-specified position
 PSize		0x008	    Program-specified size
 PMinSize	0x010	    Program-specified minimum size
 PMaxSize	0x020	    Program-specified maximum size
 PResizeInc	0x040	    Program-specified resize increments
 PAspect	0x080	    Program-specified min and max aspect
 PBaseSize	0x100	    Program-specified base size
 PWinGravity	0x200	    Program-specified window gravity

To indicate that the size and position of the window (when a transition
from the Withdrawn state occurs) was specified by the user, the client
should set the USPosition and USSize flags, which allow a window manager
to know that the user specifically asked where the window should be
placed or how the window should be sized and that further interaction is
superfluous. To indicate that it was specified by the client without any
user involvement, the client should set PPosition and PSize.

The size specifiers refer to the width and height of the client's window
excluding borders.

The win_gravity may be any of the values specified for WINGRAVITY in the
core The win_gravity may be any of the values specified for WINGRAVITY
in the core protocol except for Unmap: NorthWest (1), North (2),
NorthEast (3), West (4), Center (5), East (6), SouthWest (7), South (8),
and SouthEast (9). It specifies how and whether the client window
wants to be shifted to make room for the window manager frame.

If the win_gravity is Static, the window manager frame is positioned so
that the inside border of the client window inside the frame is in the
same position on the screen as it was when the client requested the
transition from Withdrawn state. Other values of win_gravity specify a
window reference point. For NorthWest, NorthEast, SouthWest, and
SouthEast the reference point is the specified outer corner of the
window (on the outside border edge). For North, South, East and West the
reference point is the center of the specified outer edge of the window
border. For Center the reference point is the center of the window. The
reference point of the window manager frame is placed at the location on
the screen where the reference point of the client window was when the
client requested the transition from Withdrawn state.

The min_width and min_height elements specify the minimum size that the
window can be for the client to be useful. The max_width and max_height
elements specify the maximum size. The base_width and base_height
elements in conjunction with width_inc and height_inc define an
arithmetic progression of preferred window widths and heights for
non-negative integers i and j:

 width  = base_width  + ( i x width_inc  )
 height = base_height + ( j x heigth_inc )

Window managers are encouraged to use i and j instead of width and
height in reporting window sizes to users. If a base size is not
provided, the minimum size is to be used in its place and vice versa.

The min_aspect and max_aspect fields are fractions with the numerator
first and the denominator second, and they allow a client to specify the
range of aspect ratios it prefers. Window managers that honor aspect
ratios should take into account the base size in determining the
preferred window size. If a base size is provided along with the aspect
ratio fields, the base size should be subtracted from the window size
prior to checking that the aspect ration falls in range.  If a base size
is not provided, nothing should be subtracted from the window size.
(The minimum size is not to be used in place of the base size for this
purpose.)

=over

=cut

use constant {
    WM_NORMAL_HINTS_USPOSITION	=> (1<<0),
    WM_NORMAL_HINTS_USSIZE	=> (1<<1),
    WM_NORMAL_HINTS_PPOSITION	=> (1<<2),
    WM_NORMAL_HINTS_PSIZE	=> (1<<3),
    WM_NORMAL_HINTS_PMINSIZE	=> (1<<4),
    WM_NORMAL_HINTS_PMAXSIZE	=> (1<<5),
    WM_NORMAL_HINTS_PRESIZEINC	=> (1<<6),
    WM_NORMAL_HINTS_PASPECT	=> (1<<7),
    WM_NORMAL_HINTS_PBASESIZE	=> (1<<8),
    WM_NORMAL_HINTS_PWINGRAVITY	=> (1<<9),

    WM_NORMAL_HINTS_NORTHWEST	=> 1,
    WM_NORMAL_HINTS_NORTH	=> 2,
    WM_NORMAL_HINTS_NORTHEAST	=> 3,
    WM_NORMAL_HINTS_WEST	=> 4,
    WM_NORMAL_HINTS_CENTER	=> 5,
    WM_NORMAL_HINTS_EAST	=> 6,
    WM_NORMAL_HINTS_SOUTHWEST	=> 7,
    WM_NORMAL_HINTS_SOUTH	=> 8,
    WM_NORMAL_HINTS_SOUTHEAST	=> 9,
};

=item $icccm->B<getWM_NORMAL_HINTS>($window) => $hints

Returns the normal hints associated with the window, C<$window>, or
C<undef> if there is no such property for C<$window>.  C<$hints>, when
defined, is an array reference to the hints values.

=cut

sub getWM_NORMAL_HINTS {
    return $_[0]->getWMPropertyInts($_[1],'WM_NORMAL_HINTS');
}

=item $icccm->B<event_handler_PropertyNotifyWM_NORMAL_HINTS>($e,$X,$v)

Event handler for changes in C<WM_NORMAL_HINTS> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_NORMAL_HINTS {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_NORMAL_HINTS($e->{window});
}

=back

=head3 WM_HINTS

The WM_HINTS property (whose type is WM_HINTS) is used to communicate to
the window manager. It conveys the information the window manager needs
other than the window geometry, which is available from the window
itself; the constraints on that geometry, which is available from the
WM_NORMAL_HINTS structure; and various strings, which need separate
properties, such as WM_NAME. The contents of the properties are as
follows:

 flags		    CARD32	(see the next table)
 input		    CARD32	The client's input model
 initial_state	    CARD32	The state when first mapped
 icon_pixmap	    PIXMAP	The pixmap for the icon image
 icon_window	    WINDOW	The window for the icon impae
 icon_x		    INT32	The icon location
 icon_y		    INT32
 icon_mask	    PIXMAP	The mask for the icon shape
 window_group	    WINDOW	The ID of the group leader window

The WM_HINTS.flag bit defintions are as follows:

 InputHint	    0x001	input
 StateHint	    0x002	initial_state
 IconPixmapHint	    0x004	icon_pixmap
 IconWindowHint	    0x008	icon_window
 IconPositionHint   0x010	icon_x and icon_y
 IconMaskHint	    0x020	icon_mask
 WindowGroupHint    0x040	window_group
 MessageHint	    0x080	(this bit is obsolete)
 UrgencyHint	    0x100	urgency

Window managers are free to assume convenient values for all fields of
the WM_HINTS property if a window is mapped without one.

The input field is used to communicate to the window manager the input
focus model used by the client (see Input Focus).

Clients with the Globally Active and No Input models should set the
input flag to False. Clients with the Passive and Locally Active models
should set the input flag to True.

From the client's point of view, the window manager will regard the
client's toplevel window as being in one of three states:

=over

=item *

Normal

=item *

Iconic

=item *

Withdrawn

=back

The semantics of these states are described in Changing Window State.
Newly created windows start in the Withdrawn state. Transitions between
states happen when a toplevel window is mapped and unmapped and when
the window manager receives certain messages.

The value of the initial_state field determines the state the client
wishes to be in at the time the toplevel window is mapped from the
Withdrawn state, as shown in the following table:

 NormalState	    1	    The window is visible
 IconicState	    3	    The icon is visible

The icon_pixmap field may specify a pixmap to be used as an icon.  This
pixmap should be:

=over

=item *

One of the sizes specified in WM_ICON_SIZE property on the root if it
exists (see WM_ICON_SIZE property).

=item *

1-bit deep.  The window manager will select, through the defautls
database, suitable background (for the 0 bits) and foreground (for the 1
bits) colors.  These defaults can, of course, specify different colors
for the icons of different clients.

=back

The icon_mask specifies which pixels of the icon_pixmap should be used
as the icon, allowing for icons to appear nonrectangular.

The icon_window field is the ID of a window the client wants used as its
icon. Most, but not all, window managers will support icon windows.
Those that do not are likely to have a user interface in which small
windows that behave like icons are completely inappropriate. Clients
should not attempt to remedy the omission by working around it.

Clients that need more capabilities from the icons than a simple 2-color
bitmap should use icon windows. Rules for clients that do are set out in
Icons.

The (icon_x,icon_y) coordinate is a hint to the window manager as to
where it should position the icon. The policies of the window manager
control the positioning of icons, so clients should not depend on
attention being paid to this hint.

The window_group field lets the client specify that this window belongs
to a group of windows. An example is a single client manipulating
multiple children of the root window.

=over

=item Conventions

=over

=item *

The window_group field should be set to the ID of the group leader.  The
window group leader may be a window that exists only for that purpose; a
placeholder group leader of this kind would never be mapped either by
the client or by the window manager.

=item *

The properties of the window group leader are those for the group as a
whole (for example, the icon to be shown when the entire group is
iconified).

=back

Window managers may provide facilities for manipulating the group as a
whole.  Clients, at present, have no way to operate on the group as a
whole.

The messages bit, if set in the flags field, indicates that the client
is using an obsolete window manager communication protocol, rather than
the WM_PROTOCOLS mechanism of WM_PROTOCOLS Property.

The UrgencyHint flag, if set in the flags field, indicates that the
client deems the window contents to be urgent, requiring the timely
response of the user. The window manager must make some effort to draw
the user's attention to this window while this flag is set. The window
manager must also monitor the state of this flag for the entire time the
window is in the Normal or Iconic state and must take appropriate action
when the state of the flag changes. The flag is otherwise independent of
the window's state; in particular, the window manager is not required to
deiconify the window if the client sets the flag on an Iconic window.
Clients must provide some means by which the user can cause the
UrgencyHint flag to be set to zero or the window to be withdrawn. The
user's action can either mitigate the actual condition that made the
window urgent, or it can merely shut off the alarm.

=item Rationale

This mechanism is useful for alarm dialog boxes or reminder windows, in
cases where mapping the window is not enough (e.g., in the presence of
multi-workspace or virtual desktop window managers), and where using an
override-redirect window is too intrusive. For example, the window
manager may attract attention to an urgent window by adding an indicator
to its title bar or its icon. Window managers may also take additional
action for a window that is newly urgent, such as by flashing its icon
(if the window is iconic) or by raising it to the top of the stack.

=back

=over

=cut

use constant {
    WM_HINTS_INPUTHINT		    => (1<<0),
    WM_HINTS_STATEHINT		    => (1<<1),
    WM_HINTS_ICONPIXMAPHINT	    => (1<<2),
    WM_HINTS_ICONWINDOWHINT	    => (1<<3),
    WM_HINTS_ICONPOSITIONHINT	    => (1<<4),
    WM_HINTS_ICONMASKHINT	    => (1<<5),
    WM_HINTS_WINDOWGROUPHINT	    => (1<<6),
    WM_HINTS_MESSAGEHINT	    => (1<<7),
    WM_HINTS_URGENCYHINT	    => (1<<8),

    WM_HINTS_STATE_WITHDRAWN	    => 0,
    WM_HINTS_STATE_NORMAL	    => 1,
    WM_HINTS_STATE_ZOOM		    => 2,
    WM_HINTS_STATE_ICONIC	    => 3,
    WM_HINTS_STATE_INACTIVE	    => 4,

    WM_HINTS_FIELDNAMES		    => [qw(
	    input
	    initial_state
	    icon_pixmap
	    icon_window
	    icon_x
	    icon_y
	    icon_mask
	    window_group)],

    WM_HINTS_STATENAMES		    => [qw(
	    WithdrawnState
	    NormalState
	    ZoomState
	    IconicState
	    InactiveState)],
};

=item $icccm->B<getWM_HINTS>($window) => $hints

Returns the hints associated with the window, C<$window>, or C<undef> if
there is no such property for C<$window>.  C<$hints>, when defined, is a
hash reference containing the following keys:

=over

=item $hints->{input}

The client's input model.

=item $hints->{initial_state}

The state when first mapped.

=item $hints->{icon_pixmap}

The pixmap for the icon image.

=item $hints->{icon_window}

The window for the icon image.

=item $hints->{icon_x}, $hints->{icon_y}

The icon location.

=item $hints->{icon_mask}

The mask for the icon shape.

=item $hints->{window_group}

The XID of the group leader.

=back

=cut

sub getWM_HINTS {
    my ($self,$window) = @_;
    return $self->getWMPropertyDecode($window,'WM_HINTS',sub{
	    my $data = shift;
	    my %result = ();
	    my ($flags,@fields) = unpack('LLLLLllLL',$data);
	    for(my $i=0;$i<9;$i++) {
		$result{&WM_HINTS_FIELDNAMES->[$i]} = $fields[$i]
		    if $flags & (1<<$i);
	    }
	    foreach (qw(icon_pixmap icon_window icon_mask window_group)) {
		$result{$_} = 'None' if exists $result{$_} and $result{$_} == 0;
	    }
	    $result{initial_state} = &WM_HINTS_STATENAMES->[$result{initial_state}]
		if exists $result{initial_state} and
		    defined &WM_HINTS_STATENAMES->[$result{initial_state}];
#	    $result{input} = $result{input} ? 'True' : 'False'
#		if exists $result{input};
	    return \%result;
	    });
}

=item $icccm->B<event_handler_PropertyNotifyWM_HINTS>($e,$X,$v)

Event handler for changes in C<WM_HINTS> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_HINTS {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_HINTS($e->{window});
}

=back

=head3 WM_CLASS

The WM_CLASS property (of type STRING without control characters)
contains two consecutive null-terminated strings. These specify the
Instance and Class names to be used by both the client and the window
manager for looking up resources for the application or as identifying
information. This property must be present when the window leaves the
Withdrawn state and may be changed only while the window is in the
Withdrawn state. Window managers may examine the property only when they
start up and when the window leaves the Withdrawn state, but there
should be no need for a client to change its state dynamically.

The two strings, respecitvely, are:

=over

=item *

A string that names the particular instance of the application to which
the client that owns this window belongs. Resources that are specified
by instance name override any resources that are specified by class
name. Instance names can be specified by the user in an operating-system
specific manner. On POSIX-conformant systems, the following conventions
are used:

=over

=item *

If "-name NAME" is given on the command line, NAME is used as the
instance name.

=item *

Otherwise, if the environment variable RESOURCE_NAME is set, its value
will be used as the instance name.

=item *

Otherwise, the trailing part of the name used to invoke the program
(argv[0] stripped of any directory names) is used as the instance name.

=back

=item *

A string that names the general class of applications to which the
client that owns this window belongs. Resources that are specified by
class apply to all applications that have the same class name. Class
names are specified by the application writer. Examples of commonly used
class names include: "Emacs", "XTerm", "XClock", "XLoad", and so on.

=back

Note that WM_CLASS strings are null-terminated and, thus, differ from
the general conventions that STRING properties are null-separated. This
inconsistency is necessary for backwards compatibility.

=over

=cut

=item $icccm->B<getWM_CLASS>($window) => $class

=cut

sub getWM_CLASS {
    return $_[0]->getWMPropertyStrings($_[1],'WM_CLASS');
}

=item $icccm->B<event_handler_PropertyNotifyWM_CLASS>($e,$X,$v)

Event handler for changes in C<WM_CLASS> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_CLASS {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_CLASS($e->{window});
}

=back

=head3 WM_TRANSIENT_FOR

The WM_TRANSIENT_FOR property (of type WINDOW) contains the ID of
another top-level window. The implication is that this window is a
pop-up on behalf of the named window, and window managers may decide not
to decorate transient windows or may treat them differently in other
ways. In particular, window managers should present newly mapped
WM_TRANSIENT_FOR windows without requiring any user interaction, even if
mapping top-level windows normally does require interaction. Dialogue
boxes, for example, are an example of windows that should have
WM_TRANSIENT_FOR set.

It is important not to confuse WM_TRANSIENT_FOR with override-redirect.
WM_TRANSIENT_FOR should be used in those cases where the pointer is not
grabbed while the window is mapped (in other words, if other windows are
allowed to be active while the transient is up). If other windows must
be prevented from processing input (for example, when implementing
pop-up menus), use override-redirect and grab the pointer while the
window is mapped.

=over

=cut

=item $icccm->B<getWM_TRANSIENT_FOR>($window) => $leader

=cut

sub getWM_TRANSIENT_FOR {
    return $_[0]->getWMPropertyInt($_[1],'WM_TRANSIENT_FOR');
}

=item $icccm->B<event_handler_PropertyNotifyWM_TRANSIENT_FOR>($e,$X,$v)

Event handler for changes in C<WM_TRANSIENT_FOR> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_TRANSIENT_FOR {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_TRANSIENT_FOR($e->{window});
}

=back

=head3 WM_PROTOCOLS

The WM_PROTOCOLS property (of type ATOM) is a list of atoms. Each atom
identifies a communication protocol between the client and the window
manager in which the client is willing to participate. Atoms can
identify both standard protocols and private protocols specific to
individual window managers.

All the protocols in which a client can volunteer to take part involve
the window manager sending the client a ClientMessage event and the
client taking appropriate action. For details of the contents of the
event, see ClientMessage Events In each case, the protocol transactions
are initiated by the window manager.

The WM_PROTOCOLS property is not required. If it is not present, the
client does not want to participate in any window manager protocols.

The X Consortium will maintain a registry of protocols to avoid
collisions in the name space. The following table lists the protocols
that have been defined to date.

 WM_TAKE_FOCUS	   Input Focus	    Assignment of input focus
 WM_SAVE_YOURSELF  Appendix C	    Save client state request (depr)
 WM_DELETE_WINDOW  Window Deletion  Request to delete top-level window

It is expected that this table will grow over time.

=over

=cut

=item $icccm->B<getWM_PROTOCOLS>($window) => $protocols

Returns the list of supported protocols associated with the window,
C<$window>, or C<undef> if there is no such property for C<$window>.
C<$protocols>, when defined, is a reference to an array of supported
protocol atom names.

=cut

sub getWM_PROTOCOLS {
    return $_[0]->getWMPropertyAtoms($_[1], 'WM_PROTOCOLS');
}

=item $icccm->B<event_handler_PropertyNotifyWM_PROTOCOLS>($e,$X,$v)

Event handler for changes in C<WM_PROTOCOLS> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_PROTOCOLS {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_PROTOCOLS($e->{window});
}

=back

=head3 WM_COLORMAP_WINDOWS

The WM_COLORMAP_WINDOWS property (of type WINDOW) on a top-level window
is a list of the IDs of windows that may need colormaps installed that
differ from the colormap of the top-level window. The window manager
will watch this list of windows for changes in their colormap
attributes. The top-level window is always (implicitly or explicitly) on
the watch list. For the details of this mechanism, see Colormaps.

=over

=cut

=item $icccm->B<getWM_COLORMAP_WINDOWS>($window) => $windows

=cut

sub getWM_COLORMAP_WINDOWS {
    return $_[0]->getWMPropertyInts($_[1], 'WM_COLORMAP_WINDOWS');
}

=item $icccm=>B<event_handler_PropertyNotifyWM_COLORMAP_WINDOWS>($e,$X,$v)

Event handler for changes in C<WM_COLORMAP_WINDOWS> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_COLORMAP_WINDOWS {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_COLORMAP_WINDOWS($e->{window});
}

=back

=head3 WM_CLIENT_MACHINE

The client should set the WM_CLIENT_MACHINE property (of one of the TEXT
types) to a string that forms the name of the machine running the client
as seen from the machine running the server.

=head2 Window manager properties

Window manager properties are properties that the window manager is
responsible for maintaining on top-level windows.  This section
describes the properties that the window manager places on the client's
top-level windows and on the root.

=over

=cut

=item $icccm->B<getWM_CLIENT_MACHINE>($window) => $machine

=cut

sub getWM_CLIENT_MACHINE {
    return $_[0]->getWMPropertyString($_[1], 'WM_CLIENT_MACHINE');
}

=item $icccm->B<event_handler_PropertyNotifyWM_CLIENT_MACHINE>($e,$X,$v)

Event handler for changes in C<WM_CLIENT_MACHINE> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_CLIENT_MACHINE {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_CLIENT_MACHINE($e->{window});
}

=back

=head3 WM_STATE

The window manager will place a WM_STATE property (of type WM_STATE) on
each top-level client window that is not in the Withdrawn state.
Top-level windows in the Withdrawn state may or may not have the
WM_STATE property. Once the top-level window has been withdrawn, the
client may re-use it for another purpose. Clients that do so should
remove the WM_STATE property if it is still present.

Some clients (such as xprop) will ask the user to click over a window on
which the program is to operate. Typically, the intent is for this to be
a top-level window. To find a top-level window, clients should search
the window hierarchy beneath the selected location for a window with the
WM_STATE property. This search must be recursive in order to cover all
window manager reparenting possibilities. If no window with a WM_STATE
property is found, it is recommended that programs use a mapped
child-of-root window if one is present beneath the selected location.

The contents of the WM_STATE property are defines as follows:

 state	    CARD32	(see next table)
 icon	    WINDOW	ID of icon window

The following table lists the WM_STATE.state values:

 WithdrawnState	    0
 NormalState	    1
 IconicState	    3

Adding other fields to this property is reserved to the X Consortium.
Values for the state field other than those defined in the above table
are reserved for use by the X Consortium.

The state field describes the window manager's idea of the state the
window is in, which may not match the client's idea as expressed in the
initial_state field of the WM_HINTS property (for example, if the user
has asked the window manager to iconify the window). If it is
NormalState, the window manager believes the client should be animating
its window. If it is IconicState, the client should animate its icon
window. In either state, clients should be prepared to handle exposure
events from either window.

When the window is withdrawn, the window manager will either change the
state field's value to WithdrawnState or it will remove the WM_STATE
property entirely.

The icon field should contain the window ID of the window that the
window manager uses as the icon for the window on which this property is
set. If no such window exists, the icon field should be None. Note that
this window could be but is not necessarily the same window as the icon
window that the client may have specified in its WM_HINTS property. The
WM_STATE icon may be a window that the window manager has supplied and
that contains the client's icon pixmap, or it may be an ancestor of the
client's icon window.

=over

=item Changing Window State

From the client's point of view, the window manager will regard each of
the client's top-level windows as being in one of three states, whose
semantics are as follows:

=over

=item NormalState

The client's top-level window is viewable.

=item IconicState

The client's top-level window is iconic (whatever that means for this
window manager).  The client can assume that its top-level window is not
viewable, its icon_window (if any) will be viewable and, failing that,
its icon_pixmap (if any) or its WM_ICON_NAME will be displayed.

=item WithdrawnState

Neither the client's top-level window nor its icon is visible.

=back

In fact, the window manager may implement states with semantics other
than those described above. For example, a window manager might
implement a concept of an "inactive" state in which an infrequently used
client's window would be represented as a string in a menu. But this
state is invisible to the client, which would see itself merely as being
in the Iconic state.

Newly created top-level windows are in the Withdrawn state. Once the
window has been provided with suitable properties, the client is free to
change its state as follows:

=over

=item Withdrawn -> Normal

The client should map the window with WM_HINTS.initial_state being
NormalState.

=item Withdrawn -> Iconic

The client should map the window with WM_HINTS.initial_state being
IconicState.

=item Normal -> Iconic

The client should send a ClientMessage event as described later in this
section.

=item Normal -> Withdrawn

The client should unmap the window and follow it with a synthetic
UnmapNotify even as described later in this section.

=item Iconic -> Normal

The client should map the window.  The contents of
WM_HINTS.initial_state are irrelevant in this case.

=item Iconic -> Withdrawn

The client should unmap the window and follow it with a synthetic
UnmapNotify event as described later in this section.

=back

Only the client can effect a transition into or out of the Withdrawn
state. Once a client's window has left the Withdrawn state, the window
will be mapped if it is in the Normal state and the window will be
unmapped if it is in the Iconic state.  Reparenting window managers must
unmap the client's window when it is in the Iconic state, even if an
ancestor window being unmapped renders the client's window unviewable.
Conversely, if a reparenting window manager renders the client's window
unviewable by unmapping an ancestor, the client's window is by
definition in the Iconic state and must also be unmapped.

=item Advice to implementors

Clients can select for StructureNotify on their top-level windows to
track transitions between Normal and Iconic state.  Receipt of a
MapNotify event will indicate a transition to the Normal state, and
receipt of an UnmapNotify event will indicate a transition to the Iconic
state.

=back

When changing state of the window to Withdrawn, the client must (in
addition to unmapping the window), send a synthetic UnmapNotify event by
using a SendEvent request with the following arguments:

 destination = root
 propagate = false
 event_mask = SubstructureRedirect|SubstructureNotify
 event = UnmapNotify
 event = root
 window = the window itself
 from-configure = false

=over

=item Rationale

The reason for requiring the client to send a synthetic UnmapNotify
event is to ensure that the window manager gets some notification
of the client's desire to change state, even though the window may
already be unmapped when the desire is expressed.

=item Advice to implementors

For compatibility with obsolete clients, window managers should trigger
the transition to the Withdrawn state on the real UnmapNotify rather
than waiting for the synthetic one. They should also trigger the
transition if they receive a synthetic UnmapNotify on a window for which
they have not yet received a real UnmapNotify.

=back

When a client withdraws a window, the window manager will then update or
remove the WM_STATE property as described in WM_STATE Property. Clients
that want to re-use a client window (e.g., by mapping it again or
reparenting it elsewhere) after withdrawing it must wait for the
withdrawal to be complete before proceeding. The preferred method for
doing this is for clients to wait for the window manager to update or
remove the WM_STATE property.

If the transition is from the Normal to the Iconic state, the client
should send a Client message event to the root with:

 destination = root
 propagate = false
 event_mask = SubstructureRedirect|SubstructureNotify
 event = ClientMessage
 window = the window to be iconified
 type = WM_CHANGE_STATE
 format = 32
 data.l[0] = IconicState (3)
 other data.l[] elements = 0

Other values of data[0] are reserved for future extensions to these
conventions.  The parameters of the SendEvent requires should be those
described for the synthetic UnmapNotify event.

=over

=item Rationale

The format of this ClientMessage event does not match the format of
ClientMessages in ClientMessage Events. This is because they are sent by
the window manager to clients, and this message is sent by clients to
the window manager.

=item Advice to implementors

Clients can also select for VisibilityChange events on their top-level
or icon windows. They will then receive a VisibilityNotify
(state==FullyObscured) event when the window concerned becomes
completely obscured even though mapped (and thus, perhaps a waste of
time to update) and a VisibilityNotify (state!=FullyObscured) event when
it becomes even partly viewable.

When a window makes a transition from the Normal state to either the
Iconic or the Withdrawn state, clients should be aware that the window
manager may make transients for this window inaccessible.  Clients
should not rely on transient windows being available to the user when
the transient owner window is not in the Normal state.  When withdrawing
a window, clients are advised to withdraw transients for the window.

=back

=over

=cut

use constant {
    WM_STATE_WITHDRAWNSTATE	=> 0,
    WM_STATE_NORMALSTATE	=> 1,
    WM_STATE_ZOOMSTATE		=> 2,
    WM_STATE_ICONICSTATE	=> 3,
    WM_STATE_INACTIVESTATE	=> 4,
    WM_STATE_STATENAMES		=> [qw(
	    WithdrawnState
	    NormalState
	    ZoomState
	    IconicState
	    InactiveState)],
};

=item $icccm->B<getWM_STATE>($window) => $state

=cut

sub getWM_STATE {
    my ($self,$window) = @_;
    return $self->getWMPropertyDecode($window,'WM_STATE',sub{
	    my ($state,$icon) = unpack('LL',shift);
	    $state = &WM_STATE_STATENAMES->[$state]
		if exists &WM_STATE_STATENAMES->[$state];
	    $icon = 'None' unless $icon;
	    return [$state,$icon];
	    });
}

=item $icccm->B<event_handler_PropertyNotifyWM_STATE>($e,$X,$v)

Event handler for changes in C<WM_STATE> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_STATE {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_STATE($e->{window});
}

=back

=head3 WM_COMMAND

The WM_COMMAND property represents the command used to start or restart
the client. By updating this property, clients should ensure that it
always reflects a command that will restart them in their current state.
The content and type of the property depend on the operating system of
the machine running the client. On POSIX-conformant systems using ISO
Latin-1 characters for their command lines, the property should:

=over

=item *

Be of type STRING

=item *

Contain a list of null-terminated strings

=item *

Be initialized from argv

Other systems will need to set appropriate conventions for the type and
contents of WM_COMMAND properties. Window and session managers should
not assume that STRING is the type of WM_COMMAND or that they will be
able to understand or display its contents.

=back

Note that WM_COMMAND strings are null-terminated and differ from the
general conventions that STRING properties are null-separated. This
inconsistency is necessary for backwards compatibility.

A client with multiple top-level windows should ensure that exactly one
of them has a WM_COMMAND with nonzero length. Zero-length WM_COMMAND
properties can be used to reply to WM_SAVE_YOURSELF messages on other
top-level windows but will otherwise be ignored.

=over

=cut

=item $icccm->B<getWM_COMMAND>($window) => $command

Returns the command associated with the window, C<$window>, or C<undef>
if there is no such property for C<$window>.

=cut

sub getWM_COMMAND {
    return $_[0]->getWMPropertyStrings($_[1], 'WM_COMMAND');
}

=item $icccm->B<event_handler_PropertyNotifyWM_COMMAND>($e,$X,$v)

Event handler for changes in C<WM_COMMAND> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_COMMAND {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_COMMAND($e->{window});
}

=back

=head3 WM_ICON_SIZE

A window manager that wishes to place constraints on the sizes of icon
pixmaps and/or windows should place a property called WM_ICON_SIZE on
the root. The contents of this property are listed in the following
table.

 min_width	CARD32	    The data for the icon size series
 min_heigth	CARD32
 max_width	CARD32
 max_height	CARD32
 width_inc	CARD32
 height_inc	CARD32

For more details see section 14.1.12 in Xlib - C Language X Interface.

=over

=cut

=item $icccm->B<getWM_ICON_SIZE>($window) => $size

=cut

sub getWM_ICON_SIZE {
    return $_[0]->getWMRootPropertyInts('WM_ICON_SIZE');
}

=item $icccm->B<event_handler_PropertyNotifyWM_ICON_SIZE>($e,$X,$v)

Event handler for changes in C<WM_ICON_SIZE> for the window,
C<$e-E<gt>{window}>.
The default action is simply to get the property.

=cut

sub event_handler_PropertyNotifyWM_ICON_SIZE {
    my ($self,$e,$X,$v) = @_;
    $self->getWM_ICON_SIZE if $e->{window} == $X->root;
}

=back

=cut

1;

__END__

=head3 WM_TAKE_FOCUS

Windows with the atom WM_TAKE_FOCUS in their WM_PROTOCOLS property may
receive a ClientMessage event from the window manager (as described in
ClientMessage Events) with WM_TAKE_FOCUS in its data.l[0] field and a
valid timestamp (i.e., not CurrentTime) in its data.l[1] field.  If they
want the focus, they should response with a SetInputFocus request with
its window field set to the window  of theirs that last had the input
focuse or to their default input window, and the time field set to the
timestamp in the message.  For further information, see Input Focus.

A client could receive WM_TAKE_FOCUS when opening from an icon or when
the user has clicked outside the top-level window in an area that
indicates to the window manager that it should assign the focus (for
example, clicking in the headline bar can be used to assign the
focus).

The goal is to support window managers that want to assign the input
focus to a top-level window in such a way that the top-level window
either can assign it to one of its subwindows or can decline the offer
of the focus. For example, a clock or a text editor with no currently
open frames might not want to take focus even though the window manager
generally believes that clients should take the input focus after being
deiconified or raised.

Clients that set the input focus need to decide a value for the
revert-to field of the SetInputFocus request. This determines the
behavior of the input focus if the window the focus has been set to
becomes not viewable. The value can be any of the following:

=over

=item Parent

In general, clients should use this value when assigning focus to one of
their subwindows. Unmapping the subwindow will cause focus to revert to
the parent, which is probably what you want.

=item PointerRoot

Using this value with a click-to-type focus management policy leads to
race conditions because the window becoming unviewable may coincide with
the window manager deciding to move the focus elsewhere.

=item None

Using this value causes problems if the window manager reparents the
window, as most window managers will, and then crashes. The input focus
will be None, and there will probably be no way to change it.

=back

Note that neither PointerRoot nor None is really safe to use.  Clients
that invoke a SetInputFocus request should set the revert-to argument to
Parent.

A convention is also required for clients that want to give up the input
focus.  There is no safe value for them to set the input focus to;
therefore, they should ignore input material.

Clients should not give up the input focus on their own volition.  They
should ignore input that they receive instead.

=cut

=head3 WM_DELETE_WINDOW

Clients, usually those with multiple top-level windows, whose server
connection must survive the deletion of some of their top-level windows,
should include the atom WM_DELETE_WINDOW in the WM_PROTOCOLS property on
each such window. They will receive a ClientMessage event as described
above whose data[0] field is WM_DELETE_WINDOW.

Clients receiving a WM_DELETE_WINDOW message should behave as if the
user selected "delete window" from a hypothetical menu. They should
perform any confirmation dialog with the user and, if they decide to
complete the deletion, should do the following:

=over

=item *

Either change the window's state to Withdrawn (as described in Changing
Window State ) or destroy the window.

=item *

Destroy any internal state associated with the window.

=back

If the user aborts the deletion during the confirmation dialog, the
client should ignore the message.

Clients are permitted to interact with the user and ask, for example,
whether a file associated with the window to be deleted should be saved
or the window deletion should be cancelled. Clients are not required to
destroy the window itself; the resource may be reused, but all
associated state (for example, backing store) should be released.

If the client aborts a destroy and the user then selects DELETE WINDOW
again, the window manager should start the WM_DELETE_WINDOW protocol
again. Window managers should not use DestroyWindow requests on a window
that has WM_DELETE_WINDOW in its WM_PROTOCOLS property.

Clients that choose not to include WM_DELETE_WINDOW in the WM_PROTOCOLS
property may be disconnected from the server if the user asks for one of
the client's top-level windows to be deleted.

=cut

=head3 WM_COLORMAP_NOTIFY

=cut

=head3 WM_Sn Selection

For each screen they manage, window managers will acquire ownership of a
selection named WM_Sn, where n is the screen number, as described in
Discriminated Names.  Window managers should comply with the conventions
for Manager Selections described in Manager Selections.  The intent is
for clients to be able to request a variety of information or services
by issuing conversion request on this selection.  Window managers
shoulds upport conversion of the following target on their manager
selection:

 Atom	    Type	Data Received
 VERSION    INTEGER	Two integers, which are the major and minor
                        release numbers (respectively) of the ICCCM with
			which the window manager complies.  For this
			version of the ICCM, the numebs are 2 and 0.

As a special case, clients not wishing to implement a selection request
may simply issue a GetSelectionOwner request on the appropriate WM_Sn
selection.  If this selection is owned, clients may assume that the
window manager complies with ICCCM version 2.0 or later.

=cut

=head3 WM_SAVE_YOURSELF

Clients that want to be warned when the session manager feels that they
should save their internal state (for example, when termination impends)
should include the atom WM_SAVE_YOURSELF in the WM_PROTOCOLS property on
their top-level windows to participate in the WM_SAVE_YOURSELF
protocol. They will receive a ClientMessage event as described in
ClientMessage Events with the atom WM_SAVE_YOURSELF in its data[0]
field.

Clients that receive WM_SAVE_YOURSELF should place themselves in a state
from which they can be restarted and should update WM_COMMAND to be a
command that will restart them in this state. The session manager will
be waiting for a PropertyNotify event on WM_COMMAND as a confirmation
that the client has saved its state. Therefore, WM_COMMAND should be
updated (perhaps with a zero-length append) even if its contents are
correct. No interactions with the user are permitted during this
process.

Once it has received this confirmation, the session manager will feel
free to terminate the client if that is what the user asked for.
Otherwise, if the user asked for the session to be put to sleep, the
session manager will ensure that the client does not receive any mouse
or keyboard events.

After receiving a WM_SAVE_YOURSELF, saving its state, and updating
WM_COMMAND, the client should not change its state (in the sense of
doing anything that would require a change to WM_COMMAND) until it
receives a mouse or keyboard event. Once it does so, it can assume that
the danger is over. The session manager will ensure that these events do
not reach clients until the danger is over or until the clients have
been killed.

Irrespective of how they are arranged in window groups, clients with
multiple top-level windows should ensure the following:

=over

=item *

Only one of their top-level windows has a nonzero-length WM_COMMAND property.

=item *

They respond to a WM_SAVE_YOURSELF message by:

=over

=item *

First, updating the nonzero-length WM_COMMAND property, if necessary

=item *

Second, updating the WM_COMMAND property on the window for which they
received the WM_SAVE_YOURSELF message if it was not updated in the first
step

=back

=back

Receiving WM_SAVE_YOURSELF on a window is, conceptually, a command to save
the entire client state.

=head2 Configuring the window

Clients can resize and reposition their top-level windows by using the
ConfigureWindow request.  The attributes of the window that can be
altered with this request are as follows:

=over

=item *

The [x,y] location of the window's upper left-outer corner.

=item *

The [width,height] of the inner region of the window (excluding
borders).

=item *

The border width of the window.

=item *

The window's position in the stack.

=back

The coordinate system in which the location is expressed is that of the
root (irrespective of any reparenting that may have occurred).  The
border width to be used and win_gravity position hint to be use are
those most recently requested by the client.  Client configure requests
are interpreted by the window manager in the same manner as the initial
window geometry mapped from the Withdrawn state, as described in
WM_NORMAL_HINTS property.  Clients must be aware that there is no
guarantee that the window manager will allocate them the requested size
or location and must be prepared to deal with any size and location.  If
the window manager decides to respond to a ConfigureRequest by:

=over

=item *

Not changing the size, location, border width, or stacking order of the
window at all.

A client will receive a synthetic ConfigureNotify event that describes
the (unchanged) geometry of the window.  The (x,y) coordinates will be
in the root coordinate system, adjusted for the border width the client
requested, irrespective of any reparenting that has taken place.  The
border_width will be the border width the client requested.  The client
will not receive a real ConfigureNotify even because no change has
actually taken place.

=item *

Moving or restacking the window without resizing it or changing its
border width.

A client will receive a synthetic ConfigureNotify event following the
change that describes the new geometry of the window.  The event's
(x,y) coordiantes will be in the root coordinate system adjusted for the
border width the client requested.  The border_width will be the border
width the client requested.  The client may not receive a real
ConfigureNotify event that describes this change because the window
manager may have reparented the top-level window.  If the client does
receive a real event, the synthetic event will follow the real one.

=item *

Resizing the window or changing its border width (regardless of whether
the window was also moved or restacked).

A client that has selected for StructureNotify events will receive a
real ConfigureNotify event.  Note that the coordinates in this event are
relative to the parent, which may not be the root if the window has been
reparented.  The coordinates will reflect the actual border width of the
window (which the window manager may have changed).  The
TranslateCoordinates request can be used to convert the coordinates if
required.

=back

The general rule is that coordinates in real ConfigureNotify events are
in the parent's space; in synthetic events, they are in the root space.

=over

=item Advice to implementors

Clients cannot distinguish between the case where a top-level window is
resized and moved from the case where the window is resized but not
moved, since a real ConfigureNotify event will be received in both
cases. Clients that are concerned with keeping track of the absolute
position of a top-level window should keep a piece of state indicating
whether they are certain of its position. Upon receipt of a real
ConfigureNotify event on the top-level window, the client should note
that the position is unknown. Upon receipt of a synthetic
ConfigureNotify event, the client should note the position as known,
using the position in this event. If the client receives a KeyPress,
KeyRelease, ButtonPress, ButtonRelease, MotionNotify, EnterNotify or
LeaveNotify event on the window (or on any descendant), the client can
deduce the top-level window's position from the difference between the
(event-x, event-y) and (root-x, root-y) coordinates in these events.
Only when the position is unknown does the client need to use the
TranslateCoordinates request to find the position of a top-level window.

=back

Clients should be aware that their borders may not be visible. Window
managers are free to use reparenting techniques to decorate client's
top-level windows with borders containing titles, controls, and other
details to maintain a consistent look-and-feel.  If they do, they are
likely to override the client's attempts to set the border width and set
it to zero.  Clients, therefore, should nto depend on the top-level
window's border being visible or use it to display any critical
information.  Other window managers will allow the top-level windows
border to be visible.

=over

=item Convention

Clients should set the desired value of the border-width attribute on
all ConfiureWindow requests to avoid a race condition.

=back

Clients that change their position in the stack must be aware that they
may have been reparented, which means that windows that used to be
siblings no longer are.  Using a nonsibling as the sibling parameter on
a ConfigureWindow request will cause an error.

=over

=item Convention

Clients that use a ConfigureWindow request to request a change in their
position in the stack should do so using None in the sibling field.

=back

Clients that must position themselves in the stack relative to some
window that was originally a sibling must do the ConfigureWindow request
(in case they are running under a nonreparenting window manager), be
prepared to deal with a resulting error; and then follow with a
synthetic ConfigureRequest event by invoking a SendEvent request with
the following arguments:

 Argument	    Value
 --------           -----
 destination	    root
 propagate	    false
 event-mask	    SubstructureRedirect|SubstructureNotify
 event		    ConfigureRequest
 event		    root
 window		    the window itself
 -		    other parameters from the ConfigureWindow request

Window managers are in any case free to position windows in the stack as
they see fit, and so clients should not rely on receiving the stacking
order they have requested.  Clients should ignore the above-sibling
field of both real and synthetic ConfigureNotify events received on
their top-level windows because this field may not contain useful
information.

=head2 Changing window attributes

The attributes that may be supplied when a window is created may be
changed by using the ChangeWindowAttributes request.  The window
attributes are listed in the following table:

 Attribute		Private to client
 ---------		-----------------
 background pixmap	yes
 background pixel	yes
 border pixmap		yes
 border pixel		yes
 bit gravity		yes
 window gravity		no
 backing-store hint	yes
 save-under hint	no
 event-mask		no
 do-not-propagate mask	yes
 override-redirect flag	no
 colormap		yes
 cursor			yes

Most attribtues are private to the client and will never by interfered
with by the window manager.  For the attributes that are not private to
the client:

=over

=item *

The window manager is free to override the window gravity; a reparenting
window manager may want to set the top-level window's window gravity for
its own purposes.

=item *

Clients are free to set the save-under hint on their top-level windows,
but they must be aware that the hint may be overridden by the window
manager.

=item *

Windows, in effect, have per-client event masks, and so, clients may
select for whatever events are convenient irrespective of any events the
window manager is selecting for.  There are some events for which only
one client at a time may select, but the window manage should not select
for them on any of the client's windows.

=item *

Clients can set override-redirect on top-level windows but are
encouranged not to do so except as described in pop-up windows and
redirecting requests. 

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72



