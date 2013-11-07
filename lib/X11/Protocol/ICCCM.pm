package X11::Protocol::ICCCM;
use X11::Protocol::Util qw(:all);
use X11::Protocol;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

%EXPORT_TAGS = (
    all => [qw(
	getWM_NAME
	dmpWM_NAME
	setWM_NAME
	getWM_ICON_NAME
	dmpWM_ICON_NAME
	setWM_ICON_NAME
	getWM_NORMAL_HINTS
	dmpWM_NORMAL_HINTS
	setWM_NORMAL_HINTS
	getWM_HINTS
	dmpWM_HINTS
	setWM_HINTS
	getWM_CLASS
	dmpWM_CLASS
	setWM_CLASS
	getWM_TRANSIENT_FOR
	dmpWM_TRANSIENT_FOR
	setWM_TRANSIENT_FOR
	getWM_PROTOCOLS
	dmpWM_PROTOCOLS
	setWM_PROTOCOLS
	getWM_COLORMAP_WINDOWS
	dmpWM_COLORMAP_WINDOWS
	setWM_COLORMAP_WINDOWS
	getWM_CLIENT_MACHINE
	dmpWM_CLIENT_MACHINE
	setWM_CLIENT_MACHINE
	getWM_COMMAND
	dmpWM_COMMAND
	setWM_COMMAND
	getWM_STATE
	dmpWM_STATE
	setWM_STATE
	reqWM_STATE
	getWM_ICON_SIZE
	dmpWM_ICON_SIZE
	setWM_ICON_SIZE
	getSM_CLIENT_ID
	dmpSM_CLIENT_ID
	setWM_CLIENT_ID
	getWM_CLIENT_LEADER
	dmpWM_CLIENT_LEADER
	setWM_CLIENT_LEADER
	getWM_WINDOW_ROLE
	dmpWM_WINDOW_ROLE
	setWM_WINDOW_ROLE
	getWM_LOCALE_NAME
	dmpWM_LOCALE_NAME
	setWM_LOCALE_NAME
    )],
);

=head1 NAME

X11::Protocol::ICCCM -- methods for controlling ICCCM window managers

=head1 SYNOPSIS

 package MyWmModule;
 use base qw(X11::Protocol::AnyEvent X11::Protocol::ICCCM);

 package main;
 my $icccm = MyWmModule->new();
 $icccm->get_XSETTINGS_S(0);

=head1 DESCRIPTION

Provides a module with methods that can be used to control an ICCCM
compliant client application or window manager.

=head1 METHODS

The ICCCM Version 2.0 Methods include: WM_STATE, WM_ICON_SIZE, WM_NAME,
WM_ICON_NAME, WM_NORMAL_HINTS, WM_HINTS, WM_CLASS, WM_TRANSIENT_FOR,
WM_PROTOCOLS, WM_DELETE_WINDOW, WM_TAKE_FOCUS, WM_COLORMAP_WINDOWS,
WM_CLIENT_MACHINE, WM_COLORMAP_WINDOWS, WM_COLORMAP_NOTIFY.

=head1 CLIENT PROPERTIES

Client properties are properties that the client is responsible for
maintaining.  The following are client properties:

=head2 WM_NAME

The WM_NAME property is an uninterpreted string that the client wants the
window manager to display in association with the window (for example, in
a window headline bar).

The encoding used for this string (and all other uninterpreted string
properties) is implied by the type of the property. The type atoms to be
used for this purpose are described in TEXT Properties.

Window managers are expected to make an effort to display this
information.  Simply ignoring WM_NAME is not acceptable behavior.  Clients
can assume that at least the first part of this string is visible to the
user and that if the information is not visible to the user, it is because
the user has taken an explicit action to make it invisible.

On the other hand, there is no guarantee that the user can see the WM_NAME
string even if the window manager supports window headlines. The user may
have placed the headline off-screen or have covered it by other windows.
WM_NAME should not be used for application-critical information or to
announce asynchronous changes of an application's state that require
timely user response. The expected uses are to permit the user to
identify one of a number of instances of the same client and to provide
the user with noncritical state information.

Even window managers that support headline bars will place some limit on
the length of the WM_NAME string that can be visible; brevity here will
pay dividends.

=over

=item B<getWM_NAME>(I<$X>,I<$window>) => I<$name> or undef

Returns the C<WM_NAME> property name, I<$name>, for the window,
I<$window>, or C<undef> when the C<WM_NAME> property does not exist for
I<$window>.  I<$name>, when defined, is a perl character string.

=cut

sub getWM_NAME {
    return getWMPropertyString(@_[0..1],WM_NAME=>);
}

=item B<setWM_NAME>(I<$X>,I<$window>,I<$name>)

Sets the C<WM_NAME> property name, I<$name>, on the window, I<$window>;
or, when I<$name> is C<undef>, deletes the C<WM_NAME> property from
I<$window>.  When defined, I<$name> is a perl character string.

=cut

sub setWM_NAME {
    return setWMPropertyString(@_[0..1],WM_NAME=>COMPOUND_TEXT=>$_[2]);
}

=item B<dmpWM_NAME>(I<$X>,I<$name>)

Prints to standard output the value of getWM_NAME().

=cut

sub dmpWM_NAME {
    return dmpWMPropertyString($_[0],WM_NAME=>name=>$_[1]);
}

=back

=head2 WM_ICON_NAME

The WM_ICON_NAME property is an uninterpreted string that the client wants
to be displayed in association with the window when it is iconified (for
example, in an icon label). In other respects, including the type, it is
similar to WM_NAME. For obvious geometric reasons, fewer characters will
normally be visible in WM_ICON_NAME than WM_NAME.

Clients should not attempt to display this string in their icon pixmaps or
windows; rather, they should rely on the window manager to do so.

=over

=item B<getWM_ICON_NAME>(I<$X>,I<$window>) => I<$name> or undef

Returns the C<WM_ICON_NAME> property icon name, I<$name>, for the window,
I<$window>, or C<undef> when the C<WM_ICON_NAME> property does not exist
for I<$window>.  I<$name>, when defined, is a perl character string.

=cut

sub getWM_ICON_NAME {
    return getWMPropertyString(@_[0..1],WM_ICON_NAME=>);
}

=item B<setWM_ICON_NAME>(I<$X>,I<$window>,I<$name>)

Sets the C<WM_ICON_NAME> property icon name, I<$name>, for the window,
I<$window>; or, when I<$name> is C<undef>, deletes the C<WM_ICON_NAME>
property from I<$window>.  I<$name>, when defined, is a perl character
string.

=cut

sub setWM_ICON_NAME {
    return setWMPropertyString(@_[0..1],WM_ICON_NAME=>COMPOUND_TEXT=>$_[2]);
}

=item B<dmpWM_ICON_NAME>(I<$X>,I<$name>)

Prints to standard output the value of getWM_ICON_NAME().

=cut

sub dmpWM_ICON_NAME {
    return dmpWMPropertyString($_[0],WM_ICON_NAME=>name=>$_[1]);
}

=back

=head2 WM_NORMAL_HINTS

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
should set the C<USPosition> and C<USSize> flags, which allow a window
manager to know that the user specifically asked where the window should
be placed or how the window should be sized and that further interaction
is superfluous. To indicate that it was specified by the client without
any user involvement, the client should set C<PPosition> and C<PSize>.

The size specifiers refer to the width and height of the client's window
excluding borders.

The win_gravity may be any of the values specified for C<WINGRAVITY> in
the core.   The C<win_gravity> may be any of the values specified for
C<WINGRAVITY> in the core protocol except for C<Unmap>: C<NorthWest> (1),
C<North> (2), C<NorthEast> (3), C<West> (4), C<Center> (5), C<East> (6),
C<SouthWest> (7), C<South> (8), and C<SouthEast> (9). It specifies how and
whether the client window wants to be shifted to make room for the window
manager frame.

If the win_gravity is Static, the window manager frame is positioned so
that the inside border of the client window inside the frame is in the
same position on the screen as it was when the client requested the
transition from Withdrawn state. Other values of win_gravity specify a
window reference point. For C<NorthWest>, C<NorthEast>, C<SouthWest>, and
C<SouthEast> the reference point is the specified outer corner of the
window (on the outside border edge). For C<North>, C<South>, C<East> and
C<West> the reference point is the center of the specified outer edge of
the window border. For Center the reference point is the center of the
window. The reference point of the window manager frame is placed at the
location on the screen where the reference point of the client window was
when the client requested the transition from Withdrawn state.

The min_width and min_height elements specify the minimum size that the
window can be for the client to be useful. The max_width and max_height
elements specify the maximum size. The base_width and base_height elements
in conjunction with width_inc and height_inc define an arithmetic
progression of preferred window widths and heights for non-negative
integers C<i> and C<j>:

 width  = base_width  + ( i x width_inc  )
 height = base_height + ( j x heigth_inc )

Window managers are encouraged to use C<i> and C<j> instead of width and
height in reporting window sizes to users. If a base size is not provided,
the minimum size is to be used in its place and vice versa.

The min_aspect and max_aspect fields are fractions with the numerator
first and the denominator second, and they allow a client to specify the
range of aspect ratios it prefers. Window managers that honor aspect
ratios should take into account the base size in determining the preferred
window size. If a base size is provided along with the aspect ratio
fields, the base size should be subtracted from the window size prior to
checking that the aspect ration falls in range.  If a base size is not
provided, nothing should be subtracted from the window size.  (The minimum
size is not to be used in place of the base size for this purpose.)

=head3 Methods

In the methods that follow, I<$hints>, when defined, is a reference to a
hash containing the following keys:

    supplied                  supplied fields
    user_position             user-specified initial position
    user_size                 user-specified initial size
    program_position          program-specified initial position
    program_size              program-specified initial size
    x, y                      position (obsolete)
    width, height             size (obsolete)
    min_width, min_height     program-specified minimum size
    max_width, max_height     program-specified maximum size
    width_inc, height_inc     program-specified resize increments
    min_aspect, max_aspect    program-specified aspect
    base_width, base_height   program-specified base size
    win_gravity               program-specified window gravity

The C<min_aspect> and C<max_aspect> fields, when defined, contain a
reference to a hash containing the following keys:

    x  aspect numerator
    y  aspect denominator

C<supplied> is an intepreted bit mask that can contain the following bit
definitions:

    USPosition      => WM_NORMAL_HINTS_USPOSITION   => (1<<0),
    USSize          => WM_NORMAL_HINTS_USSIZE       => (1<<1),
    PPosition       => WM_NORMAL_HINTS_PPOSITION    => (1<<2),
    PSize           => WM_NORMAL_HINTS_PSIZE        => (1<<3),
    PMinSize        => WM_NORMAL_HINTS_PMINSIZE     => (1<<4),
    PMaxSize        => WM_NORMAL_HINTS_PMAXSIZE     => (1<<5),
    PResizeInc      => WM_NORMAL_HINTS_PRESIZEINC   => (1<<6),
    PAspect         => WM_NORMAL_HINTS_PASPECT      => (1<<7),
    PBaseSize       => WM_NORMAL_HINTS_PBASESIZE    => (1<<8),
    PWinGravity     => WM_NORMAL_HINTS_PWINGRAVITY  => (1<<9),

=cut

push @{$EXPORT_TAGS{const}}, qw(
    WM_NORMAL_HINTS_USPOSITION
    WM_NORMAL_HINTS_USSIZE
    WM_NORMAL_HINTS_PPOSITION
    WM_NORMAL_HINTS_PSIZE
    WM_NORMAL_HINTS_PMINSIZE
    WM_NORMAL_HINTS_PMAXSIZE
    WM_NORMAL_HINTS_PRESIZEINC
    WM_NORMAL_HINTS_PASPECT
    WM_NORMAL_HINTS_PBASESIZE
    WM_NORMAL_HINTS_PWINGRAVITY
    WMSizeHints
);

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

    WMSizeHints=>[qw(
	USPosition
	USSize
	PPosition
	PSize
	PMinSize
	PMaxSize
	PResizeInc
	PAspect
	PBaseSize
	PWinGravity)],

    WMSizeHintsFields=>[qw(
	supplied
	user_position
	user_size
	program_position
	program_size
	x y width height
	min_width min_height
	max_width max_height
	width_inc height_inc
	min_aspect_num min_aspect_den max_aspect_num max_aspect_den
	base_width base_height
	win_gravity
    )],
};

=over

=item B<getWM_NORMAL_HINTS>(I<$X>,I<$window>) => I<$hints> or undef

Returns the I<$prop> property size hints, I<$hints>, for the window,
I<$window>, or C<undef> when no I<$prop> property exists for I<$window>.
I<$hints>, when defined, is a reference to a size hints hash: see
L</WM_SIZE_HINTS>.

=cut

sub getWM_NORMAL_HINTS {
    my($X,$window) = @_;
    return getWMPropertyDecode($X,$window,WM_NORMAL_HINTS=>sub{
	    my $data = shift;
	    my($flags,
		$x,$y,$width,$height,
		$min_width,$min_height,
		$max_width,$max_height,
		$width_inc,$height_inc,
		$min_aspect_num,$min_aspect_den,
		$max_aspect_num,$max_aspect_den,
		$base_width, $base_height,
		$win_gravity);
	    if (length($data) >= 72) {
		($flags,
		 $x,$y,$width,$height,
		 $min_width,$min_height,
		 $max_width,$max_height,
		 $width_inc,$height_inc,
		 $min_aspect_num,$min_aspect_den,
		 $max_aspect_num,$max_aspect_den,
		 $base_width, $base_height,
		 $win_gravity) =
		    unpack('LLLLLlllllllllllll',$data);
	    }
	    else {
		($flags,
		 $x,$y,$width,$height,
		 $min_width,$min_height,
		 $max_width,$max_height,
		 $width_inc,$height_inc,
		 $min_aspect_num,$min_aspect_den,
		 $max_aspect_num,$max_aspect_den,
		 $base_width, $base_height,
		 $win_gravity) =
		    unpack('LLLLLllllllllll',$data);
		$base_width = $min_width;
		$base_height = $min_height;
		$win_gravity = 2;
		$flags |= &WM_NORMAL_HINTS_PWINGRAVITY;
		$flags |= &WM_NORMAL_HINTS_PBASESIZE
		    if $flags & &WM_NORMAL_HINTS_PMINSIZE;
	    }
	    my %hints = ();
	    if ($flags & &WM_NORMAL_HINTS_USPOSITION) {
		$hints{user_position} = 'True';
		$hints{x} = $x;
		$hints{y} = $y;
	    }
	    if ($flags & &WM_NORMAL_HINTS_USSIZE) {
		$hints{user_size} = 'True';
		$hints{width} = $width;
		$hints{height} = $height;
	    }
	    if ($flags & &WM_NORMAL_HINTS_PPOSITION) {
		$hints{program_position} = 'True';
		$hints{x} = $x;
		$hints{y} = $y;
	    }
	    if ($flags & &WM_NORMAL_HINTS_PSIZE) {
		$hints{program_size} = 'True';
		$hints{width} = $width;
		$hints{height} = $height;
	    }
	    if ($flags & &WM_NORMAL_HINTS_PMINSIZE) {
		$hints{min_width} = $min_width;
		$hints{min_height} = $min_height;
	    }
	    if ($flags & &WM_NORMAL_HINTS_PMAXSIZE) {
		$hints{max_width} = $max_width;
		$hints{max_height} = $max_height;
	    }
	    if ($flags & &WM_NORMAL_HINTS_PRESIZEINC) {
		$hints{width_inc} = $width_inc;
		$hints{height_inc} = $height_inc;
	    }
	    if ($flags & &WM_NORMAL_HINTS_PASPECT) {
		$hints{min_aspect_num} = $min_aspect_num;
		$hints{min_aspect_den} = $min_aspect_den;
		$hints{max_aspect_num} = $max_aspect_num;
		$hints{max_aspect_den} = $max_aspect_den;
	    }
	    if ($flags & &WM_NORMAL_HINTS_PBASESIZE) {
		$hints{base_width} = $base_width;
		$hints{base_height} = $base_height;
	    }
	    if ($flags & &WM_NORMAL_HINTS_PWINGRAVITY) {
		$hints{win_gravity} =
		    val2name(WinGravity=>$X->{const}{WinGravity},$win_gravity);
	    }
	    return \%hints;
    });
}

=item B<setWM_NORMAL_HINTS>(I<$X>,I<$window>,I<$hints>)

Sets the I<$prop> property size hints, I<$hints>, on the window,
I<$window>; or, when I<$hints> is C<undef>, deletes the I<$prop> property
from I<$window>.
I<$hints>, when defined, is a reference to a size hints hash: see
L</WM_SIZE_HINTS>.

=cut

sub setWM_NORMAL_HINTS {
    my($X,$window,$hints) = @_;
    return setWMPropertyEncode($X,$window,WM_NORMAL_HINTS=>sub{
	    my @vals = ();
	    if (ref $hints eq 'ARRAY') {
		@vals = @$hints;
	    }
	    elsif (ref $hints eq 'HASH') {
		@vals = (
		    $hints->{user_position},
		    $hints->{user_size},
		    $hints->{program_position},
		    $hints->{program_size},
		    $hints->{x},
		    $hints->{y},
		    $hints->{width},
		    $hints->{height},
		    $hints->{min_width},
		    $hints->{min_height},
		    $hints->{max_width},
		    $hints->{max_height},
		    $hints->{width_inc},
		    $hints->{height_inc},
		    $hints->{min_aspect_num},
		    $hints->{min_aspect_den},
		    $hints->{max_aspect_num},
		    $hints->{max_aspect_den},
		    $hints->{base_width},
		    $hints->{base_height},
		    $hints->{win_gravity},
		    );
	    }
	    my $flags = 0;
	    $vals[0] = name2val(Boolean=>[qw(False True)],$vals[0]) if defined $vals[0];
	    $vals[1] = name2val(Boolean=>[qw(False True)],$vals[1]) if defined $vals[1];
	    $vals[2] = name2val(Boolean=>[qw(False True)],$vals[2]) if defined $vals[2];
	    $vals[3] = name2val(Boolean=>[qw(False True)],$vals[3]) if defined $vals[3];
	    $vals[20] = name2val(WinGravity=>$X->{const}{WinGravity},$vals[20]) if defined $vals[20];
	    $flags |= &WM_NORMAL_HINTS_USPOSITION   if $vals[0];
	    $flags |= &WM_NORMAL_HINTS_USSIZE	    if $vals[1];
	    $flags |= &WM_NORMAL_HINTS_PPOSITION    if $vals[2];
	    $flags |= &WM_NORMAL_HINTS_PSIZE	    if $vals[3];
	    $flags |= &WM_NORMAL_HINTS_PMINSIZE	    if defined $vals[ 8] or defined $vals[ 9];
	    $flags |= &WM_NORMAL_HINTS_PMAXSIZE	    if defined $vals[10] or defined $vals[11];
	    $flags |= &WM_NORMAL_HINTS_PRESIZEINC   if defined $vals[12] or defined $vals[13];
	    $flags |= &WM_NORMAL_HINTS_PASPECT	    if defined $vals[14] or defined $vals[15] or defined $vals[16] or defined $vals[17];
	    $flags |= &WM_NORMAL_HINTS_PBASESIZE    if defined $vals[18] or defined $vals[19];
	    $flags |= &WM_NORMAL_HINTS_PWINGRAVITY  if defined $vals[20];
	    foreach (4..19) { $vals[$_] = 0 unless $vals[$_] }
	    return CARDINAL=>32,pack('LLLLLlllllllllllll',$flags,@vals[4..20]);
    });
}

=item B<dmpWM_NORMAL_HINTS>(I<$X>,I<$hints>)

Prints to standard output the value of getWM_NORMAL_HINTS().

=cut

sub dmpWM_NORMAL_HINTS {
    return dmpWMPropertyHashInts($_[0],WM_NORMAL_HINTS=>[qw(
		user_position user_size program_position program_size
		x y width height min_width min_height max_width
		max_height width_inc height_inc min_aspect_num
		min_aspect_den max_aspect_num max_aspect_den base_width
		base_height win_gravity)],$_[1]);
}

=back

=head2 WM_HINTS

The WM_HINTS property (whose type is WM_HINTS) is used to communicate to
the window manager. It conveys the information the window manager needs
other than the window geometry, which is available from the window itself;
the constraints on that geometry, which is available from the
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

Window managers are free to assume convenient values for all fields of the
WM_HINTS property if a window is mapped without one.

The input field is used to communicate to the window manager the input
focus model used by the client (see Input Focus).

Clients with the Globally Active and No Input models should set the input
flag to False. Clients with the Passive and Locally Active models should
set the input flag to True.

From the client's point of view, the window manager will regard the
client's top-level window as being in one of three states:

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
states happen when a top-level window is mapped and unmapped and when the
window manager receives certain messages.

The value of the initial_state field determines the state the client
wishes to be in at the time the top-level window is mapped from the
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
bits) colors.  These defaults can, of course, specify different colors for
the icons of different clients.

=back

The icon_mask specifies which pixels of the icon_pixmap should be used as
the icon, allowing for icons to appear nonrectangular.

The icon_window field is the ID of a window the client wants used as its
icon. Most, but not all, window managers will support icon windows.  Those
that do not are likely to have a user interface in which small windows
that behave like icons are completely inappropriate. Clients should not
attempt to remedy the omission by working around it.

Clients that need more capabilities from the icons than a simple 2-color
bitmap should use icon windows. Rules for clients that do are set out in
Icons.

The (icon_x,icon_y) coordinate is a hint to the window manager as to where
it should position the icon. The policies of the window manager control
the positioning of icons, so clients should not depend on attention being
paid to this hint.

The window_group field lets the client specify that this window belongs to
a group of windows. An example is a single client manipulating multiple
children of the root window.

=over

=item Conventions

=over

=item *

The window_group field should be set to the ID of the group leader.  The
window group leader may be a window that exists only for that purpose; a
placeholder group leader of this kind would never be mapped either by the
client or by the window manager.

=item *

The properties of the window group leader are those for the group as a
whole (for example, the icon to be shown when the entire group is
iconified).

=back

Window managers may provide facilities for manipulating the group as a
whole.  Clients, at present, have no way to operate on the group as a
whole.

The messages bit, if set in the flags field, indicates that the client is
using an obsolete window manager communication protocol, rather than the
WM_PROTOCOLS mechanism of WM_PROTOCOLS Property.

The UrgencyHint flag, if set in the flags field, indicates that the client
deems the window contents to be urgent, requiring the timely response of
the user. The window manager must make some effort to draw the user's
attention to this window while this flag is set. The window manager must
also monitor the state of this flag for the entire time the window is in
the Normal or Iconic state and must take appropriate action when the state
of the flag changes. The flag is otherwise independent of the window's
state; in particular, the window manager is not required to deiconify the
window if the client sets the flag on an Iconic window.  Clients must
provide some means by which the user can cause the UrgencyHint flag to be
set to zero or the window to be withdrawn. The user's action can either
mitigate the actual condition that made the window urgent, or it can
merely shut off the alarm.

=item Rationale

This mechanism is useful for alarm dialog boxes or reminder windows, in
cases where mapping the window is not enough (e.g., in the presence of
multi-workspace or virtual desktop window managers), and where using an
override-redirect window is too intrusive. For example, the window manager
may attract attention to an urgent window by adding an indicator to its
title bar or its icon. Window managers may also take additional action for
a window that is newly urgent, such as by flashing its icon (if the window
is iconic) or by raising it to the top of the stack.

=back

=head3 Methods

In the methods that follow, I<$hints>, when defined, is a reference to a
hash that contains the following keys:

    input            input mode: True or False
    initial_state    initial state: WithdrawnState, NormalState
                     ZoomState, IconicState, InactiveState
    icon_pixmap      icon pixmap:  XID or None
    icon_window      icon window:  XID or None
    icon_x, icon_y   icon position
    icon_mask        icon mask:    XID or None
    window_group     window group: XID or None
    message          message hint: boolean
    urgency          urgency hint: boolean

=cut

push @{$EXPORT_TAGS{const}}, qw(
    WM_STATE_WITHDRAWNSTATE
    WM_STATE_NORMALSTATE
    WM_STATE_ZOOMSTATE
    WM_STATE_ICONICSTATE
    WM_STATE_INACTIVESTATE
    WMState
);

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

    WMHints => [qw(
	InputHint
	StateHint
	IconPixmapHint
	IconWindowHint
	IconPositionHint
	IconMaskHint
	WindowGroupHint
	MessageHint
	UrgencyHint
    )],

    WM_STATE_WITHDRAWNSTATE	=> 0,
    WM_STATE_NORMALSTATE	=> 1,
    WM_STATE_ZOOMSTATE		=> 2,
    WM_STATE_ICONICSTATE	=> 3,
    WM_STATE_INACTIVESTATE	=> 4,

    WMState => [qw(
	WithdrawnState
	NormalState
	ZoomState
	IconicState
	InactiveState
    )],

    WMHintsFields => [qw(
	input
	initial_state
	icon_pixmap
	icon_window
	icon_x icon_y
	icon_mask
	window_group
	message
	urgency
    )],
};

=over

=item B<getWM_HINTS>(I<$X>,I<$window>) => I<$hints>

Returns the C<WM_HINTS> property hints, I<$hints>, for the window,
I<$window>, or C<undef> when no C<WM_HINTS> property exists for
I<$window>.
I<$hints>, when defined, is a reference to a hints hash: see L</WM_HINTS>.

=cut

sub getWM_HINTS {
    my($X,$window) = @_;
    return getWMPropertyDecode($X,$window,WM_HINTS=>sub{
	    my($flags, $input, $initial_state, $icon_pixmap,
		$icon_window, $icon_x, $icon_y, $icon_mask,
		$window_group) = unpack('LLLLLllLL',shift);
	    my %hints = ();
	    if ($flags & &WM_HINTS_INPUTHINT) {
		$hints{input} = $input ? 'True' : 'False';
	    }
	    if ($flags & &WM_HINTS_STATEHINT) {
		$hints{initial_state} =
		    val2name(WMState=>WMState(),$initial_state);
	    }
	    if ($flags & &WM_HINTS_ICONPIXMAPHINT) {
		$hints{icon_pixmap} = $icon_pixmap ? $icon_pixmap : 'None';
	    }
	    if ($flags & &WM_HINTS_ICONWINDOWHINT) {
		$hints{icon_window} = $icon_window ? $icon_window : 'None';
	    }
	    if ($flags & &WM_HINTS_ICONPOSITIONHINT) {
		$hints{icon_x} = $icon_x;
		$hints{icon_y} = $icon_y;
	    }
	    if ($flags & &WM_HINTS_ICONMASKHINT) {
		$hints{icon_mask} = $icon_mask ? $icon_mask : 'None';
	    }
	    if ($flags & &WM_HINTS_WINDOWGROUPHINT) {
		$hints{window_group} = $window_group ? $window_group : 'None';
	    }
	    if ($flags & &WM_HINTS_MESSAGEHINT) {
		$hints{message} = 'True';
	    }
	    if ($flags & &WM_HINTS_URGENCYHINT) {
		$hints{urgency} = 'True';
	    }
	    return \%hints;
    });
}

=item B<setWM_HINTS>(I<$X>,I<$window>,I<$hints>)

Sets the C<WM_HINTS> property hints, I<$hints>, on the window, I<$window>;
or, when I<$hints> is C<undef>, deletes the C<WM_HINTS> property from
I<$window>.
I<$hints>, when defined, is a reference to a hints hash: see L</WM_HINTS>.

=cut

sub setWM_HINTS {
    my($X,$window,$hints) = @_;
    return setWMPropertyEncode($X,$window,WM_HINTS=>sub{
	    my @vals = ();
	    if (ref $hints eq 'ARRAY') {
		@vals = @$hints;
	    }
	    elsif (ref $hints eq 'HASH') {
		@vals = (
		    $hints->{input},
		    $hints->{initial_state},
		    $hints->{icon_pixmap},
		    $hints->{icon_window},
		    $hints->{icon_x},
		    $hints->{icon_y},
		    $hints->{icon_mask},
		    $hints->{window_group},
		    $hints->{message},
		    $hints->{urgency});
	    }
	    my $flags = 0;
	    $vals[0] = name2val(Boolean=>[qw(False True)],$vals[0]) if defined $vals[0];
	    $vals[1] = name2val(WMState=>WMState(),$vals[1]) if defined $vals[1];
	    $vals[2] = 0 if $vals[2] and $vals[2] eq 'None';
	    $vals[3] = 0 if $vals[3] and $vals[3] eq 'None';
	    $vals[6] = 0 if $vals[6] and $vals[6] eq 'None';
	    $vals[7] = 0 if $vals[7] and $vals[7] eq 'None';
	    $vals[8] = name2val(Boolean=>[qw(False True)],$vals[8]) if defined $vals[8];
	    $vals[9] = name2val(Boolean=>[qw(False True)],$vals[9]) if defined $vals[9];
	    $flags |= &WM_HINTS_INPUTHINT	 if defined $vals[0];
	    $flags |= &WM_HINTS_STATEHINT	 if defined $vals[1];
	    $flags |= &WM_HINTS_ICONPIXMAPHINT	 if defined $vals[2];
	    $flags |= &WM_HINTS_ICONWINDOWHINT	 if defined $vals[3];
	    $flags |= &WM_HINTS_ICONPOSITIONHINT if defined $vals[4];
	    $flags |= &WM_HINTS_ICONPOSITIONHINT if defined $vals[5];
	    $flags |= &WM_HINTS_ICONMASKHINT	 if defined $vals[6];
	    $flags |= &WM_HINTS_WINDWOGROUPHINT  if defined $vals[7];
	    $flags |= &WM_HINTS_MESSAGEHINT	 if $vals[8];
	    $flags |= &WM_HINTS_URGENCYHINT	 if $vals[9];
	    foreach (0..9) { $vals[$_] = 0 unless defined $vals[$_] }
	    return CARDINAL=>32,pack('LLLLLllLL',$flags,@vals[0..7]);
    });
}

=item B<dmpWM_HINTS>(I<$X>,I<$hints>)

Prints to standard output the value of getWM_HINTS().

=cut

sub dmpWM_HINTS {
    my($X,$hints) = @_;
    return dmpWMPropertyDisplay($X,WM_HINTS=>sub{
	    foreach (qw(input initial_state)) {
		next unless defined $hints->{$_};
		printf "\t%-20s: %s\n",$_,$hints->{$_};
	    }
	    foreach (qw(icon_pixmap icon_window)) {
		next unless defined $hints->{$_};
		if ($hints->{$_} =~ m{^\d+$}) {
		    printf "\t%-20s: 0x%08x\n",$_,$hints->{$_};
		} else {
		    printf "\t%-20s: %s\n",$_,$hints->{$_};
		}
	    }
	    foreach (qw(icon_x icon_y)) {
		next unless defined $hints->{$_};
		printf "\t%-20s: %s\n",$_,$hints->{$_};
	    }
	    foreach (qw(icon_mask window_group)) {
		next unless defined $hints->{$_};
		if ($hints->{$_} =~ m{^\d+$}) {
		    printf "\t%-20s: 0x%08x\n",$_,$hints->{$_};
		} else {
		    printf "\t%-20s: %s\n",$_,$hints->{$_};
		}
	    }
	    foreach (qw(message urgency)) {
		next unless defined $hints->{$_};
		printf "\t%-20s: %s\n",$_,$hints->{$_};
	    }
    });
}

=back

=head2 WM_CLASS

The WM_CLASS property (of type STRING without control characters) contains
two consecutive null-terminated strings. These specify the Instance and
Class names to be used by both the client and the window manager for
looking up resources for the application or as identifying information.
This property must be present when the window leaves the Withdrawn state
and may be changed only while the window is in the Withdrawn state. Window
managers may examine the property only when they start up and when the
window leaves the Withdrawn state, but there should be no need for a
client to change its state dynamically.

The two strings, respectively, are:

=over

=item *

A string that names the particular instance of the application to which
the client that owns this window belongs. Resources that are specified by
instance name override any resources that are specified by class name.
Instance names can be specified by the user in an operating-system
specific manner. On POSIX-conforming systems, the following conventions
are used:

=over

=item *

If "-name NAME" is given on the command line, NAME is used as the instance
name.

=item *

Otherwise, if the environment variable RESOURCE_NAME is set, its value
will be used as the instance name.

=item *

Otherwise, the trailing part of the name used to invoke the program
(argv[0] stripped of any directory names) is used as the instance name.

=back

=item *

A string that names the general class of applications to which the client
that owns this window belongs. Resources that are specified by class apply
to all applications that have the same class name. Class names are
specified by the application writer. Examples of commonly used class names
include: "Emacs", "XTerm", "XClock", "XLoad", and so on.

=back

Note that WM_CLASS strings are null-terminated and, thus, differ from the
general conventions that STRING properties are null-separated. This
inconsistency is necessary for backwards compatibility.

=head3 Methods

In the method that follows, I<$hints> is a reference to a hash that
contains the following keys:

    res_name    resource name
    res_class   resource class

Note that C<WM_CLASS> contains null-terminated strings instead of
null-separated strings.

=over

=item B<getWM_CLASS>(I<$X>,I<$window>) => I<$hints> or undef

Returns the C<WM_CLASS> property class hints, I<$hints>, for the window,
I<$window>, or C<undef> when the C<WM_CLASS> property does not exist for
I<$window>.
I<$hints>, when defined, is a reference to a hints hash: see L</WM_CLASS>.

=cut

sub getWM_CLASS {
    return getWMPropertyTermStrings(@_[0..1],WM_CLASS=>);
}

=item B<setWM_CLASS>(I<$X>,I<$window>,I<$class>)

Sets the C<WM_CLASS> property class hints, I<$hints>, on the window,
I<$window>; or, when I<$hints> is C<undef>, deletes the C<WM_CLASS>
property from I<$window>.
I<$hints>, when defined, is a reference to a hints hash: see L</WM_CLASS>.

=cut

sub setWM_CLASS {
    return setWMPropertyTermStrings(@_[0..1],WM_CLASS=>COMPOUND_TEXT=>$_[2]);
}

=item B<dmpWM_CLASS>(I<$X>,I<$class>)

Prints to standard output the value of getWM_CLASS().

=cut

sub dmpWM_CLASS {
    return dmpWMPropertyTermStrings($_[0],WM_CLASS=>class=>$_[1]);
}

=back

=head2 WM_TRANSIENT_FOR

The WM_TRANSIENT_FOR property (of type WINDOW) contains the ID of another
top-level window. The implication is that this window is a pop-up on
behalf of the named window, and window managers may decide not to decorate
transient windows or may treat them differently in other ways. In
particular, window managers should present newly mapped WM_TRANSIENT_FOR
windows without requiring any user interaction, even if mapping top-level
windows normally does require interaction. Dialogue boxes, for example,
are an example of windows that should have WM_TRANSIENT_FOR set.

It is important not to confuse WM_TRANSIENT_FOR with override-redirect.
WM_TRANSIENT_FOR should be used in those cases where the pointer is not
grabbed while the window is mapped (in other words, if other windows are
allowed to be active while the transient is up). If other windows must be
prevented from processing input (for example, when implementing pop-up
menus), use override-redirect and grab the pointer while the window is
mapped.

=over

=item B<getWM_TRANSIENT_FOR>(I<$X>,I<$window>) => I<$owner> or undef

Returns the C<WM_TRANSIENT_FOR> property owner window, I<$owner>, for the
window, I<$window>, or C<undef> when no C<WM_TRANSIENT_FOR> property
exists for I<$window>.
I<$owner>, when defined, contains the XID of the owner window.

=cut

sub getWM_TRANSIENT_FOR {
    return getWMPropertyUint(@_[0..1],WM_TRANSIENT_FOR=>);
}

=item B<setWM_TRANSIENT_FOR>(I<$X>,I<$window>,I<$owner>)

Sets the C<WM_TRANSIENT_FOR> property owner windows, I<$owner>, for the
window, I<$window>; or, when I<$owner> is C<undef>, deletes the
C<WM_TRANSIENT_FOR> property from I<$window>.
I<$owner>, when defined, contains the XID of the owner window.

=cut

sub setWM_TRANSIENT_FOR {
    return setWMPropertyUint(@_[0..1],WM_TRANSIENT_FOR=>WINDOW=>$_[2]);
}

=item B<dmpWM_TRANSIENT_FOR>(I<$X>,I<$owner>)

Prints to standard output the value of getWM_TRANSIENT_FOR().

=cut

sub dmpWM_TRANSIENT_FOR {
    return dmpWMPropertyUint($_[0],WM_TRANSIENT_FOR=>owner=>$_[1]);
}


=back

=head2 WM_PROTOCOLS

The WM_PROTOCOLS property (of type ATOM) is a list of atoms. Each atom
identifies a communication protocol between the client and the window
manager in which the client is willing to participate. Atoms can identify
both standard protocols and private protocols specific to individual
window managers.

All the protocols in which a client can volunteer to take part involve the
window manager sending the client a C<ClientMessage> event and the client
taking appropriate action. For details of the contents of the event, see
C<ClientMessage> Events.   In each case, the protocol transactions are
initiated by the window manager.

The WM_PROTOCOLS property is not required. If it is not present, the
client does not want to participate in any window manager protocols.

The X Consortium will maintain a registry of protocols to avoid collisions
in the name space. The following table lists the protocols that have been
defined to date.

 WM_TAKE_FOCUS	   Input Focus	    Assignment of input focus
 WM_SAVE_YOURSELF  Appendix C	    Save client state request (depr)
 WM_DELETE_WINDOW  Window Deletion  Request to delete top-level window

It is expected that this table will grow over time.

=over

=item B<getWM_PROTOCOLS>(I<$X>,I<$window>) => I<$protocols> or undef

Returns the C<WM_PROTOCOLS> property protocols, I<$protocols>, for the
window, I<$window>, or C<undef> when no C<WM_PROTOCOLS> property exists
for I<$window>.  I<$protocols>, when defined, is a reference to an array
of protocol names.

=cut

sub getWM_PROTOCOLS {
    return getWMPropertyAtoms(@_[0..1],WM_PROTOCOLS=>);
}

=item B<setWM_PROTOCOLS>(I<$X>,I<$window>,I<$protocols>)

Sets the C<WM_PROTOCOLS> property protocols, I<$protocols>, on window,
I<$window>.  I<$protocols>, when defined, is a reference to an array of
protocol names; when undefined, the property is deleted from I<$window>.

=cut

sub setWM_PROTOCOLS {
    return setWMPropertyAtoms(@_[0..1],WM_PROTOCOLS=>$_[2]);
}

=item B<dmpWM_PROTOCOLS>(I<$X>,I<$protocols>)

Prints to standard output the value of getWM_PROTOCOLS().

=cut

sub dmpWM_PROTOCOLS {
    return dmpWMPropertyAtoms($_[0],WM_PROTOCOLS=>protocols=>$_[1]);
}

=back

=head2 WM_COLORMAP_WINDOWS

The WM_COLORMAP_WINDOWS property (of type WINDOW) on a top-level window is
a list of the IDs of windows that may need color-maps installed that
differ from the color-map of the top-level window. The window manager will
watch this list of windows for changes in their color-map attributes. The
top-level window is always (implicitly or explicitly) on the watch list.
For the details of this mechanism, see Color-maps.

=over

=item B<getWM_COLORMAP_WINDOWS>(I<$X>,I<$window>) => I<$windows> or undef

Returns the C<WM_COLORMAP_WINDOWS> property colormap windows, I<$windows>,
for the window, I<$window>, or C<undef> when no C<WM_COLORMAP_WINDOWS>
property exists for I<$window>.  I<$windows>, when defined, is a reference
to an array containing the XIDs of the colormap windows.

=cut

sub getWM_COLORMAP_WINDOWS {
    return getWMPropertyUints(@_[0..1],WM_COLORMAP_WINDOWS=>);
}

=item B<setWM_COLORMAP_WINDOWS>(I<$X>,I<$window>,I<$windows>)

Sets the C<WM_COLORMAP_WINDOWS> property colormap windows, I<$windows> on
the window, I<$window>; or, when I<$windows> is C<undef>, deletes the
C<WM_COLORMAP_WINDOWS> from I<$window>.  I<$windows>, when defined, is a
reference to an array containing the XIDs of the colormap windows.

=cut

sub setWM_COLORMAP_WINDOWS {
    return setWMPropertyUints(@_[0..1],WM_COLORMAP_WINDOWS=>WINDOW=>$_[2]);
}

=item B<dmpWM_COLORMAP_WINDOWS>(I<$X>,I<$windows>)

Prints to standard output the value of getWM_COLORMAP_WINDOWS().

=cut

sub dmpWM_COLORMAP_WINDOWS {
    return dmpWMPropertyUints($_[0],WM_COLORMAP_WINDOWS=>windows=>$_[1]);
}

=back

=head2 WM_CLIENT_MACHINE

The client should set the WM_CLIENT_MACHINE property (of one of the TEXT
types) to a string that forms the name of the machine running the client
as seen from the machine running the server.

=over

=item B<getWM_CLIENT_MACHINE>(I<$X>,I<$window>) => I<$hostname> or undef

Returns the C<WM_CLIENT_MACHINE> property hostname, I<$hostname>, for the
window, I<$window>, or C<undef> when the C<WM_CLIENT_MACHINE> property
does not exist for I<$window>.  I<$hostname>, when defined, is a perl
character string.

=cut

sub getWM_CLIENT_MACHINE {
    return getWMPropertyString(@_[0..1],WM_CLIENT_MACHINE=>);
}

=item B<setWM_CLIENT_MACHINE>(I<$X>,I<$window>,I<$hostname>)

Sets the C<WM_CLIENT_MACHINE> property hostname, I<$hostname>, on the
window, I<$window>; or, when I<$hostname> is C<undef>, deletes the
C<WM_CLIENT_MACHINE> property from I<$window>.  When defined, I<$hostname>
is a perl character string.

=cut

sub setWM_CLIENT_MACHINE {
    return setWMPropertyString(@_[0..1],WM_CLIENT_MACHINE=>COMPOUND_STRING=>$_[2]);
}

=item B<dmpWM_CLIENT_MACHINE>(I<$X>,I<$hostname>)

Prints to standard output the value of getWM_CLIENT_MACHINE().

=cut

sub dmpWM_CLIENT_MACHINE {
    return dmpWMPropertyString($_[0],WM_CLIENT_MACHINE=>hostname=>$_[1]);
}

=back

=head1 WINDOW MANAGER PROPERTIES

Window manager properties are properties that the window manager is
responsible for maintaining on top-level windows.  This section describes
the properties that the window manager places on the client's top-level
windows and on the root.

=head2 WM_COMMAND

The WM_COMMAND property represents the command used to start or restart
the client. By updating this property, clients should ensure that it
always reflects a command that will restart them in their current state.
The content and type of the property depend on the operating system of the
machine running the client. On POSIX-conforming systems using ISO Latin-1
characters for their command lines, the property should:

=over

=item *

Be of type STRING

=item *

Contain a list of null-terminated strings

=item *

Be initialized from argv

Other systems will need to set appropriate conventions for the type and
contents of WM_COMMAND properties. Window and session managers should not
assume that STRING is the type of WM_COMMAND or that they will be able to
understand or display its contents.

=back

Note that WM_COMMAND strings are null-terminated and differ from the
general conventions that STRING properties are null-separated. This
inconsistency is necessary for backwards compatibility.

A client with multiple top-level windows should ensure that exactly one of
them has a WM_COMMAND with nonzero length. Zero-length WM_COMMAND
properties can be used to reply to WM_SAVE_YOURSELF messages on other
top-level windows but will otherwise be ignored.

Note that C<WM_COMMAND> contains null-terminated strings instead of
null-separated strings.

=over

=item B<getWM_COMMAND>(I<$X>,I<$window>) => I<$argv> or undef

Returns the C<WM_COMMAND> property program arguments, I<$argv>, for the
window, I<$window>, or C<undef> when the C<WM_COMMAND> property does not
exist for I<$window>.  I<$argv>, when defined, is a reference to an array
of strings.

=cut

sub getWM_COMMAND {
    return getWMPropertyTermStrings(@_[0..1],WM_COMMAND=>);
}

sub escape_arg {
    my $str = shift;
    if ($str =~ m{['"|&;()<>]} or $str =~ m{\s}) {
	$str = "'".join("'\"'\"'",split(/'/,$str))."'";
    }
    return $str;
}

sub shell_command {
    my($command,@args) = @_;
    my @parms = map{escape_arg($_)}@args;
    return join(' ',$command,@parms);
}


=item B<setWM_COMMAND>(I<$X>,I<$window>,I<$argv>)

Sets the C<WM_COMMAND> property with program arguments, I<$argv>, for the
window, I<$window>, or when I<$argv> is undefined, deletes the property
from I<$window>.  I<$argv>, when defined, is a reference to an array of
strings.

=cut

sub setWM_COMMAND {
    return setWMPropertyTermStrings(@_[0..1],WM_COMMAND=>COMPOUND_TEXT=>$_[2]);
}


=item B<dmpWM_COMMAND>(I<$X>,I<$argv>)

Prints to standard output the value of getWM_COMMAND().

=cut

sub dmpWM_COMMAND {
    my($X,$argv) = @_;
    return dmpWMPropertyDisplay($X,WM_COMMAND=>sub{
	printf "\t%-20s: %s\n",command=>shell_command(@$argv);
    });
}

=back

=head2 WM_STATE

The window manager will place a WM_STATE property (of type WM_STATE) on
each top-level client window that is not in the Withdrawn state.
Top-level windows in the Withdrawn state may or may not have the WM_STATE
property. Once the top-level window has been withdrawn, the client may
re-use it for another purpose. Clients that do so should remove the
WM_STATE property if it is still present.

Some clients (such as L<xprop(1)>) will ask the user to click over a
window on which the program is to operate. Typically, the intent is for
this to be a top-level window. To find a top-level window, clients should
search the window hierarchy beneath the selected location for a window
with the WM_STATE property. This search must be recursive in order to
cover all window manager reparenting possibilities. If no window with a
WM_STATE property is found, it is recommended that programs use a mapped
child-of-root window if one is present beneath the selected location.

The contents of the WM_STATE property are defines as follows:

 state	    CARD32	(see next table)
 icon	    WINDOW	ID of icon window

The following table lists the WM_STATE.state values:

 WithdrawnState	    0
 NormalState	    1
 IconicState	    3

Adding other fields to this property is reserved to the X Consortium.
Values for the state field other than those defined in the above table are
reserved for use by the X Consortium.

The state field describes the window manager's idea of the state the
window is in, which may not match the client's idea as expressed in the
initial_state field of the WM_HINTS property (for example, if the user has
asked the window manager to iconify the window). If it is C<NormalState>,
the window manager believes the client should be animating its window. If
it is C<IconicState>, the client should animate its icon window. In either
state, clients should be prepared to handle exposure events from either
window.

When the window is withdrawn, the window manager will either change the
state field's value to C<WithdrawnState> or it will remove the WM_STATE
property entirely.

The icon field should contain the window ID of the window that the window
manager uses as the icon for the window on which this property is set. If
no such window exists, the icon field should be None. Note that this
window could be but is not necessarily the same window as the icon window
that the client may have specified in its WM_HINTS property. The WM_STATE
icon may be a window that the window manager has supplied and that
contains the client's icon pixmap, or it may be an ancestor of the
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
viewable, its icon_window (if any) will be viewable and, failing that, its
icon_pixmap (if any) or its WM_ICON_NAME will be displayed.

=item WithdrawnState

Neither the client's top-level window nor its icon is visible.

=back

In fact, the window manager may implement states with semantics other than
those described above. For example, a window manager might implement a
concept of an "inactive" state in which an infrequently used client's
window would be represented as a string in a menu. But this state is
invisible to the client, which would see itself merely as being in the
Iconic state.

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

The client should map the window.  The contents of WM_HINTS.initial_state
are irrelevant in this case.

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
unviewable by unmapping an ancestor, the client's window is by definition
in the Iconic state and must also be unmapped.

=item Advice to implementors

Clients can select for StructureNotify on their top-level windows to track
transitions between Normal and Iconic state.  Receipt of a MapNotify event
will indicate a transition to the Normal state, and receipt of an
UnmapNotify event will indicate a transition to the Iconic state.

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

The reason for requiring the client to send a synthetic UnmapNotify event
is to ensure that the window manager gets some notification of the
client's desire to change state, even though the window may already be
unmapped when the desire is expressed.

=item Advice to implementors

For compatibility with obsolete clients, window managers should trigger
the transition to the Withdrawn state on the real UnmapNotify rather than
waiting for the synthetic one. They should also trigger the transition if
they receive a synthetic UnmapNotify on a window for which they have not
yet received a real UnmapNotify.

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
the window manager to clients, and this message is sent by clients to the
window manager.

=item Advice to implementors

Clients can also select for VisibilityChange events on their top-level or
icon windows. They will then receive a VisibilityNotify
(state==FullyObscured) event when the window concerned becomes completely
obscured even though mapped (and thus, perhaps a waste of time to update)
and a VisibilityNotify (state!=FullyObscured) event when it becomes even
partly viewable.

When a window makes a transition from the Normal state to either the
Iconic or the Withdrawn state, clients should be aware that the window
manager may make transients for this window inaccessible.  Clients should
not rely on transient windows being available to the user when the
transient owner window is not in the Normal state.  When withdrawing a
window, clients are advised to withdraw transients for the window.

=back

=head3 Methods

In the methods that follow, I<$state>, when defined, is a reference to a
hash containing the following keys:

 state     the state name (see table)
 icon      XID of an icon window or 'None'

The state names are as follows:

 WithdrawnState  (0)
 NormalState     (1)
 ZoomState       (2)
 IconicState     (3)
 InactiveState   (4)

=over

=item B<getWM_STATE>(I<$X>,I<$window>) => I<$state> or undef

Returns the C<WM_STATE> property state, I<$state>, for the window,
I<$window>, or C<undef> when the C<WM_STATE> property does not exist for
I<$window>.
I<$state>, when defined, is a reference to a state hash: see L</WM_STATE>.

=cut

sub getWM_STATE {
    return getWMPropertyDecode(@_[0..1],WM_STATE=>sub{
	    my ($state,$icon) = unpack('LL',shift);
	    $state = 0 unless $state;
	    $state = val2name(WMState=>WMState(),$state);
	    $icon = 'None' unless $icon;
	    return { state=>$state, icon=>$icon };
    });
}

=item B<setWM_STATE>(I<$X>,I<$window>,I<$state>)

Sets the C<WM_STATE> property state, I<$state>, on the window, I<$window>,
or, when I<$state> is C<undef>, deletes the C<WM_STATE> property from
I<$window>.
I<$state>, when defined, is a reference to a state hash: see L</WM_STATE>.

=cut

sub setWM_STATE {
    my($X,$window,$wmstate) = @_;
    return setWMPropertyEncode($X,$window,WM_STATE=>sub{
	    my($state,$icon);
	    if (ref $wmstate eq 'ARRAY') {
		($state,$icon) = @$wmstate;
	    }
	    elsif (ref $wmstate eq 'HASH') {
		$state = $wmstate->{state};
		$icon  = $wmstate->{icon};
	    }
	    $state = 0 unless $state;
	    $state = name2val(WMState=>WMState(),$state);
	    $icon = 0 unless $icon;
	    $icon = 0 if $icon eq 'None';
	    return CARDINAL=>32,pack('LL',$state,$icon);
    });
}

=item B<dmpWM_STATE>(I<$X>,I<$state>)

Prints to standard output the value of getWM_STATE().

=cut

sub dmpWM_STATE {
    my($X,$state) = @_;
    return dmpWMPropertyDisplay($X,WM_STATE=>sub{
	printf "\t%-20s: %s\n",state=>$state->{state};
	printf "\t%-20s: %s\n",icon=>$state->{icon};
    });
}

=item B<reqWM_STATE>(I<$X>,I<$window>,I<$state>)

=cut

sub reqWM_STATE {
    my($X,$window,$state) = @_;
    $state = 0 unless $state;
    $state = name2val(WMState=>WMState(),$state);
    my($res) = $X->robust_req(QueryTree=>$window);
    return 0 unless ref $res;
    my($root) = @$res;
    if ($state == WM_STATE_WITHDRAWNSTATE) {
	($res) = $X->robust_req(UnmapWindow=>$window);
	return 0 unless ref $res;
	($res) = $X->robust_req(SendEvent=>$root,0,
		$X->pack_event_mask(qw(
			SubstructureRedirect
			SubstructureNotify)),
		$X->pack_event(
		    name=>'UnmapNotify',
		    event=>$root, # PEKWM wants $window
		    window=>$window,
		    from_configure=>0));
	return 0 unless ref $res;
    }
    elsif ($state == WM_STATE_NORMALSTATE) {
	($res) = $X->robust_req(MapWindow=>$window);
	return 0 unless ref $res;
    }
    else {
	($res) = $X->robust_req(SendEvent=>$root,0,
		$X->pack_event_mask(qw(
			SubstructureRedirect
			SubstructureNotify)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$window,
		    type=>$X->atom('WM_CHANGE_STATE'),
		    format=>32,
		    data=>pack('Lxxxxxxxxxxxxxxxx',$state)));
	return 0 unless ref $res;
    }
    return 1;
}

=back

=head2 WM_ICON_SIZE

A window manager that wishes to place constraints on the sizes of icon
pixmaps or icon windows should place a property called C<WM_ICON_SIZE>
on the root. The contents of this property are listed in the following
table:

 min_width	CARD32	    The data for the icon size series
 min_heigth	CARD32
 max_width	CARD32
 max_height	CARD32
 width_inc	CARD32
 height_inc	CARD32

For more details see section 14.1.12 in Xlib - C Language X Interface.

In the methods that follow, I<$sizes>, when defined, is a reference to a
hash with the following keys:

    min_width    minimum icon width
    min_height   minimum icon height
    max_width    maximum icon width
    max_height   maximum icon height
    width_inc    icon width  increment
    heigth_inc   icon height increment

=over

=item B<getWM_ICON_SIZE>(I<$X>,I<$root>) => I<$sizes> or undef

Returns the C<WM_ICON_SIZE> property icon sizes, I<$sizes>, for the
window, I<$root>, or C<undef> when the C<WM_ICON_SIZE> property does not
exist for I<$root>.
I<$sizes>, when defined, is a reference to a size hints hash: see
L</WM_ICON_SIZE>.

When unspecified, null or zero, I<$root> defaults to C<$X-E<gt>root>.

=cut

sub getWM_ICON_SIZE {
    return getWMPropertyHashInts(@_[0..1],WM_ICON_SIZE=>[qw(min_width min_height max_width max_height width_inc height_inc)])
}

=item B<setWM_ICON_SIZE>(I<$X>,I<$root>,I<$sizes>)

Sets the C<WM_ICON_SIZE> property icon sizes, I<$sizes>, on the window,
I<$root>; or, when I<$sizes> is C<undef>, deletes the C<WM_ICON_SIZE>
property from I<$root>.  I<$sizes>, when defined, is a refernce to a
size hints hash: see L</WM_ICON_SIZE>.

When unspecified, null or zero, I<$root> defaults to C<$X-E<gt>root>.

=cut

sub setWM_ICON_SIZE {
    return setWMPropertyHashInts(@_[0..1],WM_ICON_SIZE=>CARDINAL=>[qw(min_width min_height max_width max_height width_inc height_inc)],$_[2])
}

=item B<dmpWM_ICON_SIZE>(I<$X>,I<$sizes>)

Prints to standard output the value of getWM_ICON_SIZE().

=cut

sub dmpWM_ICON_SIZE {
    return dmpWMPropertyHashInts($_[0],WM_ICON_SIZE=>[qw(min_width min_height max_width max_height width_inc height_inc)],$_[1]);
}

=back

=head2 WM_TAKE_FOCUS

Windows with the atom WM_TAKE_FOCUS in their WM_PROTOCOLS property may
receive a C<ClientMessage> event from the window manager (as described in
C<ClientMessage> Events) with WM_TAKE_FOCUS in its C<data.l[0]> field and
a valid time stamp (i.e., not C<CurrentTime>) in its C<data.l[1]> field.
If they want the focus, they should response with a C<SetInputFocus>
request with its window field set to the window  of theirs that last had
the input focus or to their default input window, and the time field set
to the time stamp in the message.  For further information, see Input
Focus.

A client could receive WM_TAKE_FOCUS when opening from an icon or when the
user has clicked outside the top-level window in an area that indicates to
the window manager that it should assign the focus (for example, clicking
in the headline bar can be used to assign the focus).

The goal is to support window managers that want to assign the input focus
to a top-level window in such a way that the top-level window either can
assign it to one of its subwindows or can decline the offer of the focus.
For example, a clock or a text editor with no currently open frames might
not want to take focus even though the window manager generally believes
that clients should take the input focus after being deiconified or
raised.

Clients that set the input focus need to decide a value for the revert-to
field of the C<SetInputFocus> request. This determines the behavior of the
input focus if the window the focus has been set to becomes not viewable.
The value can be any of the following:

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

Note that neither C<PointerRoot> nor C<None> is really safe to use.
Clients that invoke a C<SetInputFocus> request should set the revert-to
argument to Parent.

A convention is also required for clients that want to give up the input
focus.  There is no safe value for them to set the input focus to;
therefore, they should ignore input material.

Clients should not give up the input focus on their own volition.  They
should ignore input that they receive instead.

=head2 WM_DELETE_WINDOW

Clients, usually those with multiple top-level windows, whose server
connection must survive the deletion of some of their top-level windows,
should include the atom WM_DELETE_WINDOW in the WM_PROTOCOLS property on
each such window. They will receive a C<ClientMessage> event as described
above whose data[0] field is WM_DELETE_WINDOW.

Clients receiving a WM_DELETE_WINDOW message should behave as if the user
selected "delete window" from a hypothetical menu. They should perform any
confirmation dialog with the user and, if they decide to complete the
deletion, should do the following:

=over

=item *

Either change the window's state to Withdrawn (as described in Changing
Window State ) or destroy the window.

=item *

Destroy any internal state associated with the window.

=back

If the user aborts the deletion during the confirmation dialog, the client
should ignore the message.

Clients are permitted to interact with the user and ask, for example,
whether a file associated with the window to be deleted should be saved or
the window deletion should be cancelled. Clients are not required to
destroy the window itself; the resource may be reused, but all associated
state (for example, backing store) should be released.

If the client aborts a destroy and the user then selects DELETE WINDOW
again, the window manager should start the WM_DELETE_WINDOW protocol
again. Window managers should not use DestroyWindow requests on a window
that has WM_DELETE_WINDOW in its WM_PROTOCOLS property.

Clients that choose not to include WM_DELETE_WINDOW in the WM_PROTOCOLS
property may be disconnected from the server if the user asks for one of
the client's top-level windows to be deleted.

=head2 WM_COLORMAP_NOTIFY

=head2 WM_Sn Selection

For each screen they manage, window managers will acquire ownership of a
selection named WM_Sn, where n is the screen number, as described in
Discriminated Names.  Window managers should comply with the conventions
for Manager Selections described in Manager Selections.  The intent is for
clients to be able to request a variety of information or services by
issuing conversion request on this selection.  Window managers should
support conversion of the following target on their manager selection:

 Atom	    Type	Data Received
 VERSION    INTEGER	Two integers, which are the major and minor
                        release numbers (respectively) of the ICCCM with
			which the window manager complies.  For this
			version of the ICCM, the numebs are 2 and 0.

As a special case, clients not wishing to implement a selection request
may simply issue a C<GetSelectionOwner> request on the appropriate WM_Sn
selection.  If this selection is owned, clients may assume that the window
manager complies with ICCCM version 2.0 or later.

=head2 SM_CLIENT_ID

Each session participant will obtain a unique client identifier
(client-ID) from the session manager. The client must identify one top
level window as the "client leader." This window must be created by the
client. It may be in any state, including the Withdrawn state. The
client leader window must have a SM_CLIENT_ID property, which contains
the client-ID obtained from the session management protocol. That
property must:

=over

=item

be of type STRING;

=item

be of format 8; and

=item

contain the client-ID as a string of XPCS characters encoded using ISO 8859-1.

=back

A client must withdraw all of its top level windows on the same display
before modifiying either the WM_CLIENT_LEADER or the SM_CLIENT_ID
property of its client leader window.

=over

=item B<getSM_CLIENT_ID>(I<$X>,I<$window>) => I<$clientid> or undef

=cut

sub getSM_CLIENT_ID {
    return getWMPropertyString(@_[0..1],SM_CLIENT_ID=>);
}

=item B<setSM_CLIENT_ID>(I<$X>,I<$window>,I<$clientid>)

=cut

sub setWM_CLIENT_ID {
    return setWMPropertyString(@_[0..1],SM_CLIENT_ID=>STRING=>$_[2]);
}

=item B<dmpSM_CLIENT_ID>(I<$X>,I<$clientid>)

Prints to standard output the value of getWM_CLIENT_ID().

=cut

sub dmpSM_CLIENT_ID {
    return dmpWMPropertyString($_[0],SM_CLIENT_ID=>client_id=>$_[1]);
}

=back

=head2 WM_CLIENT_LEADER

All top-level, non-transient windows created by a client on the same
display as the client leader must have a WM_CLIENT_LEADER property.
This property contains a window ID that identifies the client leader
window. The client leader window must have a WM_CLIENT_LEADER property
containing its own window ID (i.e. the client leader window is pointing
to itself). Transient windows need not have a WM_CLIENT_LEADER property
if the client leader can be determined using the information in the
WM_TRANSIENT_FOR property. The WM_CLIENT_LEADER property must:

=over

=item

be of type WINDOW;

=item

be of format 32; and

=item

contain the window ID of the client leader window.

=back

A client must withdraw all of its top level windows on the same display
before modifiying either the WM_CLIENT_LEADER or the SM_CLIENT_ID
property of its client leader window.

=over

=item B<getWM_CLIENT_LEADER>(I<$X>,I<$window>) => I<$leader> or undef

=cut

sub getWM_CLIENT_LEADER {
    return getWMPropertyRecursive(@_[0..1],WM_CLIENT_LEADER=>);
}

=item B<setWM_CLIENT_LEADER>(I<$X>,I<$window>,I<$leader>)

=cut

sub setWM_CLIENT_LEADER {
    return setWMPropertyRecursive(@_[0..1],WM_CLIENT_LEADER=>WINDOW=>$_[2]);
}

=item B<dmpWM_CLIENT_LEADER>(I<$X>,I<$leader>)

Prints to standard output the value of getWM_CLIENT_LEADER().

=cut

sub dmpWM_CLIENT_LEADER {
    return dmpWMPropertyUint($_[0],WM_CLIENT_LEADER=>leader=>$_[1]);
}

=back

=head2 WM_WINDOW_ROLE

It is necessary that other clients be able to uniquely identify a window
(across sessions) among all windows related to the same client-ID. For
example, a window manager can require this unique ID to restore geometry
information from a previous session, or a workspace manager could use it
to restore information about which windows are in which workspace. A
client may optionally provide a WM_WINDOW_ROLE property to uniquely
identify a window within the scope specified above. The combination of
SM_CLIENT_ID and WM_WINDOW_ROLE can be used by other clients to uniquely
identify a window across sessions.

If the WM_WINDOW_ROLE property is not specified on a top level window,
a client that needs to uniquely identify that window will try to use
instead the values of WM_CLASS and WM_NAME. If a client has multiple
windows with identical WM_CLASS and WM_NAME properties, then it should
provide a WM_WINDOW_ROLE property.

The client must set the WM_WINDOW_ROLE property to a string that
uniquely identifies that window among all windows that have the same
client leader window. The property must:

=over

=item

be of type STRING;

=item

be of format 8; and

=item

contain a string restricted to the XPCS characters, encoded in ISO 8859-1.

=back

=over

=item B<getWM_WINDOW_ROLE>(I<$X>,I<$window>) => I<$role> or undef

=cut

sub getWM_WINDOW_ROLE {
    return getWMPropertyString(@_[0..1],WM_WINDOW_ROLE=>);
}

=item B<setWM_WINDOW_ROLE>(I<$X>,I<$window>,I<$role>)

=cut

sub setWM_WINDOW_ROLE {
    return setWMPropertyString(@_[0..1],WM_WINDOW_ROLE=>STRING=>$_[2]);
}

=item B<setWM_WINDOW_ROLE>(I<$X>,I<$role>)

Prints to standard output the value of getWM_WINDOW_ROLE().

=cut

sub dmpWM_WINDOW_ROLE {
    return dmpWMPropertyString($_[0],WM_WINDOW_ROLE=>role=>$_[1]);
}

=back

=head2 WM_SAVE_YOURSELF

Clients that want to be warned when the session manager feels that they
should save their internal state (for example, when termination impends)
should include the atom WM_SAVE_YOURSELF in the WM_PROTOCOLS property on
their top-level windows to participate in the WM_SAVE_YOURSELF protocol.
They will receive a C<ClientMessage> event as described in
C<ClientMessage> Events with the atom WM_SAVE_YOURSELF in its data[0]
field.

Clients that receive WM_SAVE_YOURSELF should place themselves in a state
from which they can be restarted and should update WM_COMMAND to be a
command that will restart them in this state. The session manager will be
waiting for a C<PropertyNotify> event on WM_COMMAND as a confirmation that
the client has saved its state. Therefore, WM_COMMAND should be updated
(perhaps with a zero-length append) even if its contents are correct. No
interactions with the user are permitted during this process.

Once it has received this confirmation, the session manager will feel free
to terminate the client if that is what the user asked for.  Otherwise, if
the user asked for the session to be put to sleep, the session manager
will ensure that the client does not receive any mouse or keyboard events.

After receiving a WM_SAVE_YOURSELF, saving its state, and updating
WM_COMMAND, the client should not change its state (in the sense of doing
anything that would require a change to WM_COMMAND) until it receives a
mouse or keyboard event. Once it does so, it can assume that the danger is
over. The session manager will ensure that these events do not reach
clients until the danger is over or until the clients have been killed.

Irrespective of how they are arranged in window groups, clients with
multiple top-level windows should ensure the following:

=over

=item *

Only one of their top-level windows has a nonzero-length WM_COMMAND
property.

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

=head2 WM_LOCALE_NAME

=over

=item B<getWM_LOCALE_NAME>(I<$X>,I<$window>) => I<$locale> or undef

=cut

sub getWM_LOCALE_NAME {
    return getWMPropertyString(@_[0..1],WM_LOCALE_NAME=>);
}

=item B<setWM_LOCALE_NAME>(I<$X>,I<$window>,I<$locale>)

=cut

sub setWM_LOCALE_NAME {
    return setWMPropertyString(@_[0..1],WM_LOCALE_NAME=>STRING=>$_[2]);
}

=item B<dmpWM_LOCALE_NAME>(I<$X>,I<$locale>)

Prints to standard output the value of getWM_LOCALE_NAME().

=cut

sub dmpWM_LOCALE_NAME {
    return dmpWMPropertyString($_[0],WM_LOCALE_NAME=>locale=>$_[1]);
}

=back

=head2 Configuring the window

Clients can resize and reposition their top-level windows by using the
ConfigureWindow request.  The attributes of the window that can be altered
with this request are as follows:

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
root (irrespective of any reparenting that may have occurred).  The border
width to be used and win_gravity position hint to be use are those most
recently requested by the client.  Client configure requests are
interpreted by the window manager in the same manner as the initial window
geometry mapped from the Withdrawn state, as described in WM_NORMAL_HINTS
property.  Clients must be aware that there is no guarantee that the
window manager will allocate them the requested size or location and must
be prepared to deal with any size and location.  If the window manager
decides to respond to a ConfigureRequest by:

=over

=item *

Not changing the size, location, border width, or stacking order of the
window at all.

A client will receive a synthetic ConfigureNotify event that describes the
(unchanged) geometry of the window.  The (x,y) coordinates will be in the
root coordinate system, adjusted for the border width the client
requested, irrespective of any reparenting that has taken place.  The
border_width will be the border width the client requested.  The client
will not receive a real ConfigureNotify even because no change has
actually taken place.

=item *

Moving or restacking the window without resizing it or changing its border
width.

A client will receive a synthetic ConfigureNotify event following the
change that describes the new geometry of the window.  The event's (x,y)
coordiantes will be in the root coordinate system adjusted for the border
width the client requested.  The border_width will be the border width the
client requested.  The client may not receive a real ConfigureNotify event
that describes this change because the window manager may have reparented
the top-level window.  If the client does receive a real event, the
synthetic event will follow the real one.

=item *

Resizing the window or changing its border width (regardless of whether
the window was also moved or restacked).

A client that has selected for StructureNotify events will receive a real
ConfigureNotify event.  Note that the coordinates in this event are
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
resized and moved from the case where the window is resized but not moved,
since a real ConfigureNotify event will be received in both cases. Clients
that are concerned with keeping track of the absolute position of a
top-level window should keep a piece of state indicating whether they are
certain of its position. Upon receipt of a real ConfigureNotify event on
the top-level window, the client should note that the position is unknown.
Upon receipt of a synthetic ConfigureNotify event, the client should note
the position as known, using the position in this event. If the client
receives a KeyPress, KeyRelease, ButtonPress, ButtonRelease, MotionNotify,
EnterNotify or LeaveNotify event on the window (or on any descendant), the
client can deduce the top-level window's position from the difference
between the (event-x, event-y) and (root-x, root-y) coordinates in these
events.  Only when the position is unknown does the client need to use the
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

Clients should set the desired value of the border-width attribute on all
ConfiureWindow requests to avoid a race condition.

=back

Clients that change their position in the stack must be aware that they
may have been reparented, which means that windows that used to be
siblings no longer are.  Using a nonsibling as the sibling parameter on a
ConfigureWindow request will cause an error.

=over

=item Convention

Clients that use a C<ConfigureWindow> request to request a change in their
position in the stack should do so using None in the sibling field.

=back

Clients that must position themselves in the stack relative to some window
that was originally a sibling must do the C<ConfigureWindow> request (in
case they are running under a nonreparenting window manager), be prepared
to deal with a resulting error; and then follow with a synthetic
C<ConfigureRequest> event by invoking a C<SendEvent> request with the
following arguments:

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
order they have requested.  Clients should ignore the above-sibling field
of both real and synthetic C<ConfigureNotify> events received on their
top-level windows because this field may not contain useful information.

=head1 Changing window attributes

The attributes that may be supplied when a window is created may be
changed by using the C<ChangeWindowAttributes> request.  The window
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

Most attributes are private to the client and will never by interfered
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
window manager is selecting for.  There are some events for which only one
client at a time may select, but the window manage should not select for
them on any of the client's windows.

=item *

Clients can set override-redirect on top-level windows but are encouranged
not to do so except as described in pop-up windows and redirecting
requests. 

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

L<X11::Protocol(3pm)>,
L<X11::Protocol::AnyEvent(3pm)>.

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
