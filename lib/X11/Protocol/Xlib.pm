package X11::Protocol::Xlib;
use base qw(X11::Protocol);
use Encode;
use Encode::Unicode;
use Encode::X11;
use X11::Protocol;
use X11::Protocol::Enhanced;
use X11::AtomConstants;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

%EXPORT_TAGS = (
    icc => [qw(
	XFetchName
	XStoreName
	XGetWMName
	XSetWMName
	XGetIconName
	XSetIconName
	XGetWMIconName
	XSetWMIconName
	XGetWMSizeHints
	XSetWMSizeHints
	XGetWMNormalHints
	XSetWMNormalHints
	XGetWMHints
	XSetWMHints
	XGetClassHint
	XSetClassHint
	XGetTransientForHint
	XSetTransientForHint
	XGetWMProtocols
	XSetWMProtocols
	XGetWMColormapWindows
	XSetWMColormapWindows
	XGetWMClientMachine
	XSetWMClientMachine
	XGetClientMachine
	XSetClientMachine
	XGetCommand
	XSetCommand
	XGetWMState
	XSetWMState
	XChangeWMState
	XGetIconSizes
	XSetIconSizes
	XSetWMProperties
	XReconfigureWMWindow
	XIconifyWindow
	XWithdrawWindow
    )],
    x11 => [qw(
	XSelectInput
	XQueryTree
	XGetWindowAttributes
	XGetGeometry
    )],
    props => [qw(
	XStringListToTextProperty
	XTextPropertyToStringList
	XTextListToTextProperty
	XTextPropertyToTextList
	XGetTextProperty
	XSetTextProperty
    )],
    events => [qw(
	event_handler_ClientMessageWM_PROTOCOLS
	event_handler_ClientMessageMANAGER
	event_handler_DestroyNotify
    )],
    all => [qw(
    )],
);

=head1 NAME

X11::Protocol::Xlib -- Xlib methods for X11::Protocol

=head1 SYNOPSIS

 use X11::Protocol::Xlib;

 my $X = X11::Protocol::Xlib->new();

 if (my $sizes = XGetIconSizes($X,$X->root)) {
     while (my ($k,$v) = each %$sizes) {
	 printf "%-20s: %d\n", $k, $v;
     }
 }

=head1 DESCRIPTION

This modules provides a set of ICCCM compliant methods that are normally
available in C from Xlib.  Following the L<X11::Protocol(3pm)> convention
of avoiding the leading C<X> from C-languagefunction names, each of the
methods provided here corresponds to its Xlib function name by prefixing
C<X>, C<Xmb>, C<Xwc> or C<Xutf8> to the function name.  Where possible the
ICCCM section and Xlib library function is referenced.

This module is intended to work by extending the L<X11::Protocol(3pm)>
module.  X11::Protocol::Xlib uses L<X11::Protocol(3pm)> as a base.
Because it relies on some enhanced bit operations and constants, it uses
both L<X11::Protpcol::Enhanced(3pm)> and L<X11::AtomConstants(3pm)>.

=head1 METHODS

The following methods are provided.

=cut

sub new {
    my $self = X11::Protocol::new(@_);
    if ($self) {
	$self->{ext_const}{WMHints} = [qw(
		InputHint
		StateHint
		IconPixmapHint
		IconWindowHint
		IconPositionHint
		IconMaskHint
		WindowGroupHint
		MessageHint
		UrgencyHint)];
	$self->{ext_const}{WMState} = [qw(
		WithdrawnState
		NormalState
		ZoomState
		IconicState
		InactiveState)];
	$self->{ext_const}{WMSizeHints} = [qw(
		USPosition
		USSize
		PPosition
		PSize
		PMinSize
		PMaxSize
		PResizeInc
		PAspect
		PBaseSize
		PWinGravity)];
	$self->{ext_const}{IceWMTray} = [qw(
		Ignore
		Minimized
		Exclusive)];
    }
    return $self;
}

=head2 BASIC UTILITIES

=over

=item $X->B<XSelectInput>(I<$window>,I<$event_mask>) => I<$success>

I<$event_mask> defaults to an empty mask.  When specified, I<$event_mask>
may be an array reference to an array of event mask bit names or numbers;
a hash reference to with bit name or bit number keys and boolean values;
or a integer bit mask.

=cut

sub XSelectInput {
    my($X,$window,$mask) = @_;
    $mask = 0 unless $mask;
    my $events;
    if (ref $events eq 'ARRAY') {
	$events = $X->pack_mask('EventMask',@$events);
    } 
    elsif (ref $events eq 'HASH') {
	$events = $X->pack_mask('EventMask',
		grep {$events->{$_}} keys %$events);
    }
    else {
	$events = $mask;
    }
    my ($res) = $X->robust_req(ChangeWindowAttributes=>$window,event_mask=>$events);
    return 0 unless ref $res;
    return 1;
}

=item B<XQueryTree>(I<$X>,I<$window>) => I<$info>

I<$info>, when defined, is a referene to a hash containing the following
keys:

 root		- root window
 parent		- parent window
 children	- reference to an array of child windows

=cut

sub XQueryTree {
    my($X,$window) = @_;
    $window = $X->root unless $window;
    my ($res) = $X->robust_req(QuertyTree=>$window);
    return undef unless ref $res;
    return {
	root=>$res->[0],
	parent=>$res->[1],
	children=>splice(@$res,2),
    };
}

=item B<XGetWindowAttributes>(I<$X>,I<$window>) => I<$attrs>

I<$attrs>, when defined, is a reference to a hash containing the
following keys:

 x, y			- location of window
 width, height		- width and height of window
 border_width		- border width of window
 depth			- depth of window
 visual			- associated visual structure
 root			- root of screen containing window
 class			- InputOutput, InputOnly
 bit_gravity		- one of the bit gravity values
 win_gravity		- one of the window gravity values
 backing_store		- NotUseful, WhenMapped, Always
 backing_planes		- planes to be preserved if possible
 backing_pixel		- value to be used when restoring planes
 save_under		- boolean, should bits under be saved?
 colormap		- color map associated with window
 map_installed		- boolean, is color map currently installed?
 map_state		- IsUnmapped, IsUnviewable, IsViewable
 all_event_masks	- set of events all people have interest in
 your_event_maks	- my event mask
 do_not_propagate_mask	- set of events that should not propagate
 screen			- screen containing window

=cut

sub XGetWindowAttributes {
    my($X,$window) = @_;
    $window = $X->root unless $window;
    my ($res) = $X->robust_req(GetWindowAttributes=>$window);
    return undef unless ref $res;
    return { @$res };
}

=item B<XGetGeometry>(I<$X>,I<$drawable>) => I<$geom>

I<$geom>, when defined, is a reference to a hash containing the
following keys:

 root			- root window of drawable
 x, y			- upper-left corner relative to parent
 width, height		- dimensions of drawabl
 border_width		- border width in pixels
 depth			- depth of drawable

=cut

sub XGetGeometry {
    my($X,$window) = @_;
    $window = $X->root unless $window;
    my ($res) = $X->robust_req(GetGeometry=>$window);
    return undef unless ref $res;
    return { @$res };
}

=back

=head2 TEXT PROPERTIES

Perl has little need for text properties; however, in the methods that
follow, I<$text> can either be a simple perl string, or a reference to a
hash containing the following keys:

 value      contents of the property as a binary string
 encoding   encoding: C<STRING>, C<COMPOUND_TEXT>, C<UTF8_STRING>
 format	    format of the property: 8, 16, 32 (usually 8)
 nitems     number of octets in value: length($text->{value})

Use the features of the L<Encode(3pm)> module whenever you need to convert
between a binary string and a perl string.

Because of this, there are no I<Xmb*>, I<Xwc*> or I<Xutf8*> distinctions
for the implementation of Xlib functions.  Pass the vanilla method either
a text property hash reference as above, or a scalar perl (non-binary)
character string, and the method will simply do the right thing.  The only
exception is the XGetTextProperty() and XSetTextProperty() methods that
alway require or produce the hash reference.

For text properties other than those for which special get and set
functions are provided in this module, and when it is necessary to control
the encoding of the text property, use the XTextListToTextProperty() and
XTextPropertyToTextList() methods in conjunction with the XGetTextProperty()
and XSetTextProperty() methods, described below.

=over

=item B<XStringListToTextProperty>(I<$strings>) => I<$text>

Sets the text property, I<$text>, to be of type C<STRING> (format 8) with
a value representing the concatenation of the specified list of
null-separated character strings.

=cut

sub XStringListToTextProperty {
    return XTextListToTextProperty(shift,'StringStyle');
}

=item B<XTextPropertyToStringList>(I<$text>) => I<$strings>

Returns a reference to an array of strings, I<$strings>, representing the
null-separated elements of the specified text property, I<$text>.  The
data in I<$text> must be of type C<STRING> and format 8.  Multiple
elements of the property are separated by null (encoding 0).

=cut

sub XTextPropertyToStringList {
    return XTextPropertyToTextList(@_);
}

=item B<XTextListToTextProperty>(I<$strings>,I<$style>) => I<$text>

I<$style> may be one of the following:

 StringStyle         always use STRING [8]
 CompoundTextStyle   always use COMPOUND_TEXT [8]
 UTF8StringStyle     always use UTF8_STRING [8]
 StdICCTextStyle     use STRING or COMPOUND_TEXT [8] as necessary

Note that the I<Xmb*>, I<Xwc*> and I<Xutf8*> distinctions of this method
are unnecessary, as this method accepts perl internal character strings.

=cut

sub XTextListToTextProperty {
    my($strings,$style) = @_;
    $strings = [ $strings ] if defined $strings and ref $strings ne 'ARRAY';
    return undef unless $strings;
    my %text = ();
    if ($style eq 'StdICCTextStyle' or
	   ($style ne 'StringStyle' and
	    $style ne 'CompoundTextStyle' and
	    $style ne 'UTF8StringStyle')) {
	warn "style '$style' defautls to StdICCTextStyle"
	    if $style ne 'StdICCTextStyle';
	$style = 'StringStyle';
	foreach (@$strings) {
	    my $input = $_;
	    Encode::encode('iso-8859-1',$input,Encode::FB_QUIET());
	    if (length($input) > 0) {
		$style = 'CompoundTextStyle';
		last;
	    }
	}
	push @$strings, ''; # null terminate ICC strings
    }
    if ($style eq 'StringStyle') {
	$text{value} = join("\x00",map{Encode::encode('iso-8859-1',$_)}@$strings);
	$text{encoding} = 'STRING';
	$text{format} = 8;
    }
    elsif ($style eq 'CompoundTextStyle') {
	$text{value} = join("\x00",map{Encode::encode('x11-compound-text',$_)}@$strings);
	$text{encoding} = 'COMPOUND_TEXT';
	$text{format} = 8;
    }
    elsif ($style eq 'UTF8StringStyle') {
	$text{value} = join("\x00",map{Encode::encode('UTF-8',$_)}@$strings);
	$text{encoding} = 'UTF8_STRING';
	$text{format} = 8;
    }
    else {
	die "should not get here!";
    }
    $text{nitems} = length($text{value});
    return \%text;
}

=item B<XTextPropertyToTextList>(I<$text>) => I<$strings>

Note that the I<Xmb*>, I<Xwc*> and I<Xutf8*> distinctions of this method
are unnecessary, as this method produces perl internal characeter strings.

=cut

sub XTextPropertyToTextList {
    my $text = shift;
    return $text unless $text and ref $text eq 'HASH';
    return [ map{Encode::decode('iso-8859-1',$_)}unpack('(Z*)*',$text->{value}."\x00") ]
	if $text->{encoding} eq 'STRING';
    return [ map{Encode::decode('x11-compound-text',$_)}unpack('(Z*)*',$text->{value}."\x00") ]
	if $text->{encoding} eq 'COMPOUND_TEXT';
    warn "type '$text->{encoding}' defaults to UTF8_STRING"
	if $text->{encoding} ne 'UTF8_STRING';
    return [ map{Encode::decode('UTF-8',$_)}unpack('(Z*)*',$text->{value}."\x00") ];
}

=item $X->B<XGetTextProperty>(I<$window>,I<$prop>) => I<$text> or undef

Returns the text property, I<$text>, with name, I<$prop>, from a window,
I<$window>, or C<undef> when no property of that name exists on
I<$window>.
I<$prop> is normally C<WM_CLIENT_MACHINE>, C<WM_COMMAND>, C<WM_ICON_NAME>
or C<WM_NAME>.

=cut

sub XGetTextProperty {
    my($X,$window,$prop,$type) = @_;
    $type = 0 unless $type;
    my $atom = ($prop =~ m{^\d+$}) ? $prop : $X->atom($prop);
    my ($res) = $X->robust_req(
	    GetProperty=>$window,
	    $atom,$type,0,1);
    return undef unless ref $res;
    my($value,$rtype,$format,$after) = @$res;
    return undef unless $format;
    if ($after) {
	($res) = $X->robust_req(
		GetProperty=>$window,
		$atom,$type,1,(($after+3)>>2));
	return undef unless ref $res;
	return undef unless $res->[2]; # $format
	$value .= $res->[0];
    }
    return {
	value=>$value,
	format=>$format,
	encoding=>$X->atom_name($rtype),
	nitems=>length($value),
    };
}

=item $X->B<XSetTextProperty>(I<$window>,I<$text>,I<$prop>)

Sets the text property, I<$text>, with name, I<$prop>, on the window,
I<$window>.
I<$prop> can be C<WM_CLIENT_MACHINE>, C<WM_COMMAND>, C<WM_ICON_NAME>
or C<WM_NAME>.

=cut

sub XSetTextProperty {
    my($X,$window,$text,$prop) = @_;
    if (defined $text) {
	unless (ref $text) {
	    $text = {
		value=>Encode::decode('UTF-8',$text),
		encoding=>'UTF8_STRING',
		format=>8,
	    };
	    $text->{nitems} = length($text->{value});
	}
	$X->ChangeProperty($window,
		$prop =~ m{^\d+$} ? $prop : $X->atom($prop),
		$X->atom($text->{encoding}),
		$text->{format},
		Replace=>$text->{value});
    } else {
	$X->DeleteProperty($window,$X->atom($prop));
    }
}

=back

=head1 CLIENT PROPERTIES

Client properties are properties that the client is responsible for
maintaining.  The following are client properties:

=head2 WM_NAME

The WM_NAME property is an uninterpreted string that the client wants the
window manager to display in association with the window (for example, in
a window headline bar).

The encoding used for this string (and all other uninterpreted string
properties) is implied by the type of the property.  The type atoms to be
used for this purpose are described in TEXT Properties.

Window managers are expected to make an effort to display this
information.  Simply ignoring WM_NAME is not acceptable behavior.  Clients
can assume that at least the first part of this string is visible to the
user and that if the information is not visible to the user, it is because
the user has taken an explicit action to make it invisible.

On the other hand, there is no guarantee that the user can see the WM_NAME
string even if the window manager supports window headlines.  The user may
have placed the headline off-screen or have covered it by other windows.
WM_NAME should not be used for application-critical information or to
announce asynchronous changes of an application's state that require
timely user response.  The expected uses are to permit the user to
identify one of a number of instances of the same client and to provide
the user with noncritical state information.

Even window managers that support headline bars will place some limit on
the length of the WM_NAME string that can be visible; brevity here will
pay dividends.

=over

=item $X->B<XFetchName>(I<$window>) => I<$name> or undef

Returns the C<WM_NAME> property name, I<$name>, for the window,
I<$window>, or C<undef> when the C<WM_NAME> property does not exist for
I<$window>.  I<$name>, when defined, is a perl character string.

=cut

sub XFetchName {
    my($X,$window) = @_;
    my $list = XTextPropertyToTextList(XGetWMName($X,$window));
    return $list->[0] if $list;
    return undef;
}

=item $X->B<XStoreName>(I<$window>,I<$name>)

Sets the C<WM_NAME> property name, I<$name>, on the window, I<$window>;
or, when I<$name> is C<undef>, deletes the C<WM_NAME> property from
I<$window>.  When defined, I<$name> is a perl character string.

=cut

sub XStoreName {
    XSetWMName(@_[0..1],XTextListToTextProperty($_[2],'StdICCStyle'));
}

=item $X->B<XGetWMName>(I<$window>) => I<$text> or undef

Returns the C<WM_NAME> text property, I<$text>, for the window,
I<$window>, or C<undef> when no C<WM_NAME> property exists for I<$window>.
I<$text>, when defined, is a text property hash reference (see L</TEXT
PROPERTIES>).

=cut

sub XGetWMName {
    return XGetTextProperty(@_[0..1],X11::AtomConstants::WM_NAME()=>0);
}

=item $X->B<XSetWMName>(I<$window>,I<$text>)

Sets the C<WM_NAME> text property name, I<$text>, on the window
I<$window>; or, when I<$text> is C<undef>, deletes the C<WM_NAME> property
from I<$window>.  When defined, I<$text> is a text property hash (see
L</TEXT PROPERTIES>), or a perl character string.

=cut

sub XSetWMName {
    return XSetTextProperty(@_[0..1],X11::AtomConstants::WM_NAME()=>$_[2]);
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

=item $X->B<XGetIconName>(I<$window>) => I<$name> or undef

Returns the C<WM_ICON_NAME> property icon name, I<$name>, for the window,
I<$window>, or C<undef> when the C<WM_ICON_NAME> property does not exist
for I<$window>.  I<$name>, when defined, is a perl character string.

=cut

sub XGetIconName {
    my($X,$window) = @_;
    my $list = XTextPropertyToTextList(XGetWMIconName($X,$window));
    return $list->[0] if $list;
    return undef;
}

=item $X->B<XSetIconName>(I<$window>, I<$name>)

Sets the C<WM_ICON_NAME> property icon name, I<$name>, for the window,
I<$window>; or, when I<$name> is C<undef>, deletes the C<WM_ICON_NAME>
property from I<$window>.  I<$name>, when defined, is a perl character
string.

=cut

sub XSetIconName {
    $_[0]->XSetWMIconName($_[1],XTextListToTextProperty($_[2],'StdICCStyle'));
}

=item $X->B<XGetWMIconName>(I<$window>) => I<$text> or undef

Returns the C<WM_ICON_NAME> text property, I<$text>, for the window,
I<$window>, or C<undef> when no C<WM_ICON_NAME> property exists for
I<$window>.  I<$text>, when defined, is a text property hash reference
(see L</TEXT PROPERTIES>).

=cut

sub XGetWMIconName {
    return $_[0]->XGetTextProperty($_[1],X11::AtomConstants::WM_ICON_NAME()=>0);
}

=item $X->B<XSetWMIconName>(I<$window>, I<$text>)

Sets the C<WM_ICON_NAME> text property, I<$text>, for the window,
I<$window>: or, when I<$text> is C<undef>, deletes the C<WM_ICON_NAME>
property from I<$window>.  I<$text>, when defined, is a text property
hash (see L</TEXT PROPERTIES>), or a perl character string.

=cut

sub XSetWMIconName {
    $_[0]->XSetTextProperty($_[1],X11::AtomConstants::WM_ICON_NAME()=>$_[2]);
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

C<win_gravity> is an interpreted field of type C<WinGravity>
and takes one of the values defined in the core protocol
(L<X11::Protocol(3pm)>).

C<supplied> is an interpreted bit field and is a reference to an array
that can contain the following symbolic bit numbers:

   'USPosition'   WM_NORMAL_HINTS_USPOSITION	=> (1<<0)
   'USSize'       WM_NORMAL_HINTS_USSIZE	=> (1<<1)
   'PPosition'    WM_NORMAL_HINTS_PPOSITION	=> (1<<2)
   'PSize'        WM_NORMAL_HINTS_PSIZE		=> (1<<3)
   'PMinSize'     WM_NORMAL_HINTS_PMINSIZE	=> (1<<4)
   'PMaxSize'     WM_NORMAL_HINTS_PMAXSIZE	=> (1<<5)
   'PResizeInc'   WM_NORMAL_HINTS_PRESIZEINC	=> (1<<6)
   'PAspect'      WM_NORMAL_HINTS_PASPECT	=> (1<<7)

   'PBaseSize'    WM_NORMAL_HINTS_PBASESIZE	=> (1<<8)
   'PWinGravity'  WM_NORMAL_HINTS_PWINGRAVITY	=> (1<<9)

The C<min_aspect> and C<max_aspect> fields, when defined, contain a
reference to a hash containing the following keys:

   x  aspect numerator
   y  aspect denominator

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
};

=over

=item $X->B<XGetWMSizeHints>(I<$window>,I<$prop>) => I<$hints> or undef

Returns the I<$prop> property size hints, I<$hints>, for the window,
I<$window>, or C<undef> when no I<$prop> property exists for I<$window>.
I<$hints>, when defined, is a reference to a size hints hash: see
L</WM_SIZE_HINTS>.

=cut

sub XGetWMSizeHints {
    my($X,$window,$prop) = @_;
    my($res) = $X->robust_req(
	    GetProperty=>$window,
	    $X->atom($prop),
	    X11::AtomConstants::WM_SIZE_HINTS(),0,18);
    return undef unless ref $res;
    my($value,$rtype,$format,$after) = @$res;
    return undef unless $format;
    my @supplied = qw(USPosition USSize PPosition PSize PMinSize
	    PMaxSize PResizeInc PAspect);
    push @supplied, qw(PBaseSize PWinGravity)
	if length($value) >= 72;
    my($flag,@fields) = unpack('LLLLLl*',$value);
    $fields[15] = 0 unless defined $fields[15];
    $fields[16] = 0 unless defined $fields[16];
    $fields[17] = 0 unless defined $fields[17];
    my %hints;
    my %flags = $X->unpack_mask('WMSizeHints',$flag);
    $hints{supplied} = \@supplied;
    $hints{user_position} = 1
	if $flags{USPosition};
    $hints{user_size} = 1
	if $flags{USSize};
    $hints{program_position} = 1
	if $flags{PPosition};
    $hints{program_size} = 1
	if $flags{PSize};
    $hints{x} = $fields[0]
	if $flags{USPosition} or $flags{PPosition};
    $hints{y} = $fields[1]
	if $flags{USPosition} or $flags{PPosition};
    $hints{width}  = $fields[2]
	if $flags{USSize} or $flags{PSize};
    $hints{height} = $fields[3]
	if $flags{USSize} or $flags{PSize};
    $hints{min_width}  = $fields[4]
	if $flags{PMinSize};
    $hints{min_height} = $fields[5]
	if $flags{PMinSize};
    $hints{max_width}  = $fields[6]
	if $flags{PMaxSize};
    $hints{max_height} = $fields[7]
	if $flags{PMaxSize};
    $hints{width_inc}  = $fields[8]
	if $flags{PResizeInc};
    $hints{height_inc} = $fields[9]
	if $flags{PResizeInc};
    $hints{min_aspect} = { x=>$fields[10], y=>$fields[11] }
	if $flags{PAspect};
    $hints{max_aspect} = { x=>$fields[12], y=>$fields[13] }
	if $flags{PAspect};
    $hints{base_width}  = $fields[14]
	if $flags{PBaseSize};
    $hints{base_height} = $fields[15]
	if $flags{PBaseSize};
    $hints{win_gravity} = $X->interp('WinGravity', $fields[16])
	if $flags{PWinGravity};
    return \%hints;
}

=item $X->B<XSetWMSizeHints>(I<$window>,I<$hints>,I<$prop>)

Sets the I<$prop> property size hints, I<$hints>, on the window,
I<$window>; or, when I<$hints> is C<undef>, deletes the I<$prop> property
from I<$window>.
I<$hints>, when defined, is a reference to a size hints hash: see
L</WM_SIZE_HINTS>.

=cut

sub XSetWMSizeHints {
    my($X,$window,$hints,$prop) = @_;
    return $X->DeleteProperty($window,$X->atom($prop))
	unless $hints;
    my @flags = ();
    my @fields = (0 x 17);
    if ($hints->{user_position}) {
	push @flags, 'USPosition';
	$fields[0] = $hints->{x}
	    if $hints->{x};
	$fields[1] = $hints->{y}
	    if $hints->{y};
    }
    if ($hints->{program_position}) {
	push @flags, 'PPosition';
	$fields[0] = $hints->{x}
	    if $hints->{x};
	$fields[1] = $hints->{y}
	    if $hints->{y};
    }
    if ($hints->{user_position}) {
	push @flags, 'USSize';
	$fields[2] = $hints->{width}
	    if $hints->{width};
	$fields[3] = $hints->{height}
	    if $hints->{height};
    }
    if ($hints->{program_position}) {
	push @flags, 'PSize';
	$fields[2] = $hints->{width}
	    if $hints->{width};
	$fields[3] = $hints->{height}
	    if $hints->{height};
    }
    if (defined $hints->{min_width} or defined $hints->{min_height}) {
	push @flags, 'PMinSize';
	$fields[4] = $hints->{min_width}
	    if $hints->{min_width};
	$fields[5] = $hints->{min_height}
	    if $hints->{min_height};
    }
    if (defined $hints->{max_width} or defined $hints->{max_height}) {
	push @flags, 'PMaxSize';
	$fields[6] = $hints->{max_width}
	    if $hints->{max_width};
	$fields[7] = $hints->{max_height}
	    if $hints->{max_height};
    }
    if (defined $hints->{width_inc} or defined $hints->{height_inc}) {
	push @flags, 'PResizeInc';
	$fields[8] = $hints->{width_inc}
	    if $hints->{width_inc};
	$fields[9] = $hints->{height_inc}
	    if $hints->{height_inc};
    }
    if (defined $hints->{min_aspect} or defined $hints->{max_aspect}) {
	push @flags, 'PAspect';
	$fields[10] = $hints->{min_aspect}{x}
	    if $hints->{min_aspect}{x};
	$fields[11] = $hints->{min_aspect}{y}
	    if $hints->{min_aspect}{y};
	$fields[12] = $hints->{max_aspect}{x}
	    if $hints->{max_aspect}{x};
	$fields[13] = $hints->{max_aspect}{y}
	    if $hints->{max_aspect}{y};
    }
    if (defined $hints->{base_width} or defined $hints->{base_height}) {
	push @flags, 'PBaseSize';
	$fields[14] = $hints->{base_width}
	    if $hints->{base_width};
	$fields[15] = $hints->{base_height}
	    if $hints->{base_height};
    }
    if (defined $hints->{win_gravity}) {
	push @flags, 'PWinGravity';
	$fields[16] = $X->num($hints->{win_gravity})
	    if $hints->{win_gravity};
    }
    my $flag = $X->pack_mask('WMSizeHints',\@flags);
    $X->ChangeProperty($window,
	    $X->atom($prop),
	    X11::AtomConstants::WM_SIZE_HINTS(),32,
	    Replace=>pack('LLLLLlllllllllllll',$flag,@fields));
}

=item $X->B<XGetWMNormalHints>(I<$window>) => I<$hints> or undef

This method is equivalent to:

 $X->XGetWMSizeHints($window, 'WM_NORMAL_HINTS');

=cut

sub XGetWMNormalHints {
    my($X,$window) = @_;
    return $X->XGetWMSizeHints($window,'WM_NORMAL_HINTS');
}

=item $X->B<XSetWMNormalHints>(I<$window>,I<$hints>)

This method is equivalent to:

 $X->XSetWMSizeHints($window,$hints,'WM_NORMAL_HINTS')

=cut

sub XSetWMNormalHints {
    my($X,$window,$hints) = @_;
    return $X->XSetWMSizeHints($window,$hints,'WM_NORMAL_HINTS');
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

C<initial_state> is an interpreted field of type I<WMState>, as
described under L</WM_STATE>.

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
};

=over

=item $X->B<XGetWMHints>(I<$window>) => I<$hints> or undef

Returns the C<WM_HINTS> property hints, I<$hints>, for the window,
I<$window>, or C<undef> when no C<WM_HINTS> property exists for
I<$window>.
I<$hints>, when defined, is a reference to a hints hash: see L</WM_HINTS>.

=cut

sub XGetWMHints {
    my($X,$window) = @_;
    my ($res) = $X->robust_req(
	    GetProperty=>$window,
	    X11::AtomConstants::WM_HINTS(),
	    0,0,9);
    return undef unless ref $res;
    my($value,$rtype,$format,$after) = @$res;
    return undef unless $format;
    my($flag,@fields) = unpack('LLLLLllLL',$value);
    my %hints;
    my %flags = $X->unpack_mask(WMHints=>$flag);
    $hints{input} = $X->interp('Bool',$fields[0])
	if $flags{InputHint};
    $hints{initial_state} = $X->interp(WMState=>$fields[1])
	if $flags{StateHint};
    $hints{icon_pixmap} = $fields[2] ? $fields[2] : 'None'
	if $flags{IconPixmapHint};
    $hints{icon_window} = $fields[3] ? $fields[3] : 'None'
	if $flags{IconWindowHint};
    $hints{icon_x} = $fields[4]
	if $flags{IconPositionHint};
    $hints{icon_y} = $fields[5]
	if $flags{IconPositionHint};
    $hints{icon_mask} = $fields[6] ? $fields[6] : 'None'
	if $flags{IconMaskHint};
    $hints{window_group} = $fields[7] ? $fields[7] : 'None'
	if $flags{WindowGroupHint};
    $hints{message} = 1
	if $flags{MessageHint};
    $hints{urgency} = 1
	if $flags{UrgencyHint};
    return \%hints;
}

=item $X->B<XSetWMHints>(I<$window>,I<$hints>)

Sets the C<WM_HINTS> property hints, I<$hints>, on the window, I<$window>;
or, when I<$hints> is C<undef>, deletes the C<WM_HINTS> property from
I<$window>.
I<$hints>, when defined, is a reference to a hints hash: see L</WM_HINTS>.

=cut

sub XSetWMHints {
    my($X,$window,$hints) = @_;
    return $X->DeleteProperty($window,X11::AtomConstants::WM_HINTS())
	unless $hints;
    my @flags = ();
    my @fields = (0 x 9);
    if (defined $hints->{input}) {
	push @flags, 'InputHint';
	$fields[0] = $X->num('Bool',$hints->{input});
    }
    if (defined $hints->{initial_state}) {
	push @flags, 'StateHint';
	$fields[1] = $X->num(WMState=>$hints->{initial_state});
    }
    if (defined $hints->{icon_pixmap}) {
	push @flags, 'IconPixmapHint';
	$fields[2] = $hints->{icon_pixmap}
	    unless $hints->{icon_pixmap} eq 'None';
    }
    if (defined $hints->{icon_window}) {
	push @flags, 'IconWindowHint';
	$fields[3] = $hints->{icon_window}
	    unless $hints->{icon_window} eq 'None';
    }
    if (defined $hints->{icon_x} or defined $hints->{icon_y}) {
	push @flags, 'IconPositionHint';
	$fields[4] = $hints->{icon_x} if $hints->{icon_x};
	$fields[5] = $hints->{icon_y} if $hints->{icon_y};
    }
    if (defined $hints->{icon_mask}) {
	push @flags, 'IconMaskHint';
	$fields[6] = $hints->{icon_mask}
	    unless $hints->{icon_mask} eq 'None';
    }
    if (defined $hints->{window_group}) {
	push @flags, 'WindowGroupHint';
	$fields[7] = $hints->{window_group}
	    unless $hints->{window_group} eq 'None';
    }
    if ($hints->{message}) {
	push @flags, 'MessageHint';
    }
    if ($hints->{urgency}) {
	push @flags, 'UrgencyHint';
    }
    my $flag = $X->pack_mask(WMHints=>\@flags);
    $X->ChangeProperty($window,
	    X11::AtomConstants::WM_HINTS(),
	    X11::AtomConstants::WM_HINTS(),32,
	    Replace=>pack('LLLLLllLL',$flag,@fields));
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

=item $X->B<XGetClassHint>(I<$window>) => I<$hints> or undef

Returns the C<WM_CLASS> property class hints, I<$hints>, for the window,
I<$window>, or C<undef> when the C<WM_CLASS> property does not exist for
I<$window>.
I<$hints>, when defined, is a reference to a hints hash: see L</WM_CLASS>.

=cut

sub XGetClassHint {
    my($X,$window) = @_;
    my $text = $X->XGetTextProperty($window,X11::AtomConstants::WM_CLASS()=>0);
    return undef unless $text;
    if (substr($text->{value},-1,1) eq "\x00") {
	$text->{value} = substr($text->{value},0,length($text->{value})-1);
	$text->{nitems} -= 1;
    }
    my $list = XTextPropertyToTextList($text);
    return undef unless $list;
    my %hints = ( res_name=>'', res_class=>'' );
    $hints{res_name}  = $list->[0] if $list->[0];
    $hints{res_class} = $list->[1] if $list->[1];
    return \%hints;
}

=item $X->B<XSetClassHint>(I<$window>,I<$hints>)

Sets the C<WM_CLASS> property class hints, I<$hints>, on the window,
I<$window>; or, when I<$hints> is C<undef>, deletes the C<WM_CLASS>
property from I<$window>.
I<$hints>, when defined, is a reference to a hints hash: see L</WM_CLASS>.

=cut

sub XSetClassHint {
    my($X,$window,$hints) = @_;
    my $text;
    if ($hints) {
	$hints->{res_name}  = '' unless $hints->{res_name};
	$hints->{res_class} = '' unless $hints->{res_class};
	my $list = [ $hints->{res_name}, $hints->{res_class} ];
	$text = XTextListToTextProperty($list);
	if ($text) {
	    $text->{value} .= "\x00";
	    $text->{nitems} += 1;
	}
    }
    $X->XSetTextProperty($window,X11::AtomConstants::WM_CLASS()=>$text);
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

=item $X->B<XGetTransientForHint>(I<$window>) => I<$owner> or undef

Returns the C<WM_TRANSIENT_FOR> property owner window, I<$owner>, for the
window, I<$window>, or C<undef> when no C<WM_TRANSIENT_FOR> property
exists for I<$window>.
I<$owner>, when defined, contains the XID of the owner window.

=cut

sub XGetTransientForHint {
    my($X,$window) = @_;
    my($res) = $X->robust_req(
	    GetProperty=>$window,
	    X11::AtomConstants::WM_TRANSIENT_FOR(),
	    0,0,1);
    return undef unless ref $res;
    my($value,$rtype,$format,$after) = @$res;
    return undef unless $format;
    return unpack('L',$value);
}

=item $X->B<XSetTransientForHint>(I<$window>,I<$owner>)

Sets the C<WM_TRANSIENT_FOR> property owner windows, I<$owner>, for the
window, I<$window>; or, when I<$owner> is C<undef>, deletes the
C<WM_TRANSIENT_FOR> property from I<$window>.
I<$owner>, when defined, contains the XID of the owner window.

=cut

sub XSetTransientForHint {
    my($X,$window,$owner) = @_;
    return $X->DeleteProperty($window,X11::AtomConstants::WM_TRANSIENT_FOR())
	unless defined $owner;
    $X->ChangeProperty($window,
	    X11::AtomConstants::WM_TRANSIENT_FOR(),
	    X11::AtomConstants::WINDOW(),32,
	    Replace=>pack('L',$owner));
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

=item $X->B<XGetWMProtocols>(I<$window>) => I<$protocols> or undef

Returns the C<WM_PROTOCOLS> property protocols, I<$protocols>, for the
window, I<$window>, or C<undef> when no C<WM_PROTOCOLS> property exists
for I<$window>.  I<$protocols>, when defined, is a reference to an array
of protocol names.

=cut

sub XGetWMProtocols {
    my($X,$window) = @_;
    my($res) = $X->robust_req(
	    GetProperty=>$window,
	    $X->atom('WM_PROTOCOLS'),
	    0,0,1);
    return undef unless ref $res;
    my($value,$rtype,$format,$after) = @$res;
    return undef unless $format;
    if ($after) {
	($res) = $X->robust_req(
		GetProperty=>$window,
		$X->atom('WM_PROTOCOLS'),
		0,1,(($after+3)>>2));
	return undef unless ref $res;
	return undef unless $res->[2];
	$value .= $res->[0];
    }
    return [ unpack('L*', $value) ];
}

=item $X->B<XSetWMProtocols>(I<$window>, I<$protocols>)

Sets the C<WM_PROTOCOLS> property protocols, I<$protocols>, on window,
I<$window>.  I<$protocols>, when defined, is a reference to an array of
protocol names; when undefined, the property is deleted from I<$window>.

=cut

sub XSetWMProtocols {
    my($X,$window,$protocols) = @_;
    return $X->DeleteProperty($window,$X->atom('WM_PROTOCOLS'))
	unless $protocols;
    $X->ChangeProperty($window,
	    $X->atom('WM_PROTOCOLS'),
	    X11::AtomConstants::ATOM(),32,
	    Replace=>pack('L*',map{$X->atom($_)}@$protocols));
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

=item $X->B<XGetWMColormapWindows>(I<$window>) => I<$windows> or undef

Returns the C<WM_COLORMAP_WINDOWS> property colormap windows, I<$windows>,
for the window, I<$window>, or C<undef> when no C<WM_COLORMAP_WINDOWS>
property exists for I<$window>.  I<$windows>, when defined, is a reference
to an array containing the XIDs of the colormap windows.

=cut

sub XGetWMColormapWindows {
    my($X,$window) = @_;
    my ($res) = $X->robust_req(
	    GetProperty=>$window,
	    $X->atom('WM_COLORMAP_WINDOWS'),
	    0,0,1);
    return undef unless ref $res;
    my($value,$rtype,$format,$after) = @$res;
    return undef unless $format;
    if ($after) {
	($res) = $X->robust_req(
		GetProperty=>$window,
		$X->atom('WM_COLORMAP_WINDOWS'),
		0,1,(($after+3)>>2));
	return undef unless ref $res;
	return undef unless $res->[2];
	$value .= $res->[0];
    }
    return [ unpack('L*', $value) ];
}

=item $X->B<XSetWMColormapWindows>(I<$window>,I<$windows>)

Sets the C<WM_COLORMAP_WINDOWS> property colormap windows, I<$windows> on
the window, I<$window>; or, when I<$windows> is C<undef>, deletes the
C<WM_COLORMAP_WINDOWS> from I<$window>.  I<$windows>, when defined, is a
reference to an array containing the XIDs of the colormap windows.

=cut

sub XSetWMColormapWindows {
    my($X,$window,$windows) = @_;
    return $X->DeleteProperty($window,$X->atom('WM_COLORMAP_WINDOWS'))
	unless $windows;
    $X->ChangeProperty($window,
	    $X->atom('WM_COLORMAP_WINDOWS'),
	    X11::AtomConstants::WINDOW(),32,
	    Replace=>pack('L*',@$windows));
}

=back

=head2 WM_CLIENT_MACHINE

The client should set the WM_CLIENT_MACHINE property (of one of the TEXT
types) to a string that forms the name of the machine running the client
as seen from the machine running the server.

=over

=item $X->B<XGetWMClientMachine>(I<$window>) => I<$text> or undef

Returns the C<WM_CLIENT_MACHINE> property text, I<$text>, for the window,
I<$window>, or C<undef> when no C<WM_CLIENT_MACHINE> property exists for
I<$window>.  I<$text>, when defined, is a text property hash reference
(see L</TEXT PROPERTIES>).

=cut

sub XGetWMClientMachine {
    return $_[0]->XGetTextProperty($_[1],X11::AtomConstants::WM_CLIENT_MACHINE()=>0);
}

=item $X->B<XSetWMClientMachine>(I<$window>,I<$text>)

=cut

sub XSetWMClientMachine {
    return $_[0]->XSetTextProperty($_[1],X11::AtomConstants::WM_CLIENT_MACHINE()=>$_[2]);
}

=item $X->B<XGetClientMachine>(I<$window>) => $hostname

Returns the C<WM_CLIENT_MACHINE> property hostname, I<$hostname>, for the
window, I<$window>, or C<undef> when the C<WM_CLIENT_MACHINE> property
does not exist for I<$window>.  I<$hostname>, when defined, is a perl
character string.

=cut

sub XGetClientMachine {
    my($X,$window) = @_;
    my $list = XTextPropertyToTextList($X->XGetWMClientMachine($window));
    return $list->[0] if $list;
    return undef;
}

=item $X->B<XSetClientMachine>(I<$window>,I<$hostname>)

Sets the C<WM_CLIENT_MACHINE> property hostname, I<$hostname>, on the
window, I<$window>; or, when I<$hostname> is C<undef>, deletes the
C<WM_CLIENT_MACHINE> property from I<$window>.  When defined, I<$hostname>
is a perl character string.

=cut

sub XSetClientMachine {
    $_[0]->XSetWMClientMachine($_[1],XTextListToTextProperty($_[2],'StdICCStyle'));
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

=item $X->B<XGetCommand>(I<$window>) => I<$argv> or undef

Returns the C<WM_COMMAND> property program arguments, I<$argv>, for the
window, I<$window>, or C<undef> when the C<WM_COMMAND> property does not
exist for I<$window>.  I<$argv>, when defined, is a reference to an array
of strings.

=cut

sub XGetCommand {
    my($X,$window) = @_;
    my $text = $X->XGetTextProperty($window,X11::AtomConstants::WM_COMMAND()=>0);
    return undef unless $text;
    if (substr($text->{value},-1,1) eq "\x00") {
	$text->{value} = substr($text->{value},0,length($text->{value})-1);
	$text->{nitems} -= 1;
    }
    return XTextPropertyToTextList($text);
}

=item $X->B<XSetCommand>(I<$window>, I<$argv>)

Sets the C<WM_COMMAND> property with program arguments, I<$argv>, for the
window, I<$window>, or when I<$argv> is undefined, deletes the property
from I<$window>.  I<$argv>, when defined, is a reference to an array of
strings.

=cut

sub XSetCommand {
    my($X,$window,$argv) = @_;
    my $text = XTextListToTextProperty($argv);
    if ($text) {
	$text->{value} .= "\x00";
	$text->{nitems} += 1;
    }
    $X->XSetTextProperty($window,X11::AtomConstants::WM_COMMAND()=>$text);
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

 WithdrawnState  WM_STATE_WITHDRAWNSTATE => 0
 NormalState     WM_STATE_NORMALSTATE    => 1
 ZoomState       WM_STATE_ZOOMSTATE      => 2
 IconicState     WM_STATE_ICONICSTATE    => 3
 InactiveState   WM_STATE_INACTiVESTATE  => 4

=cut

use constant {
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
};

=over

=item $X->B<XGetWMState>(I<$window>) => $state or undef

Returns the C<WM_STATE> property state, I<$state>, for the window,
I<$window>, or C<undef> when the C<WM_STATE> property does not exist for
I<$window>.
I<$state>, when defined, is a reference to a state hash: see L</WM_STATE>.

=cut

sub XGetWMState {
    my($X,$window) = @_;
    my($res) = $X->robust_req(
	    GetProperty=>$window,
	    $X->atom('WM_STATE'),
	    0,0,2);
    return undef unless ref $res;
    my($value,$rtype,$format,$after) = @$res;
    return undef unless $format;
    my($state,$icon) = unpack('LL',$value);
    $state = $X->interp(WMState=>$state);
    $icon = 'None' unless $icon;
    return {state=>$state,icon=>$icon};
}

=item $X->B<XSetWMState>(I<$window>,I<$state>)

Sets the C<WM_STATE> property state, I<$state>, on the window, I<$window>,
or, when I<$state> is C<undef>, deletes the C<WM_STATE> property from
I<$window>.
I<$state>, when defined, is a reference to a state hash: see L</WM_STATE>.

=cut

sub XSetWMState {
    my($X,$window,$wmstate) = @_;
    return $X->DeleteProperty($window,$X->atom('WM_STATE'))
	unless $wmstate;
    my($state,$icon) = ($wmstate->{state},$wmstate->{icon});
    $state = 0 unless $state;
    $state = $X->num(WMState=>$state);
    $icon = 0 unless $icon;
    $icon = 0 if $icon eq 'None';
    $X->ChangeProperty($window,
	    $X->atom('WM_STATE'),
	    X11::AtomConstants::WINDOW(),32,
	    Replace=>pack('LL',$state,$icon));
}

=item $X->B<XChangeWMState>(I<$window>,I<$state>)

=cut

sub XChangeWMState {
    my($X,$window,$state) = @_;
    $state = 0 unless $state;
    $state = $X->do_interp(WMState=>$state) if $state =~ m{^\d+$};
    if ($state eq 'WithdrawnState') {
	$X->XWithdrawWindow($window);
    }
    elsif ($state eq 'IconicState') {
	$X->XIconifyWindow($window);
    }
    elsif ($state eq 'NormalState') {
	$X->MapWindow($window);
    }
    else {
	$X->SendEvent($X->root, 0,
		$X->pack_event_mask(qw(
			SubstructureRedirect
			SubstructureNotify)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$window,
		    type=>$X->atom('WM_CHANGE_STATE'),
		    format=>32,
		    data=>pack('Lxxxxxxxxxxxxxxxx',
			$X->num(WMState=>$state))));
    }
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

=item $X->B<XGetIconSizes>(I<$root>) => I<$sizes> or undef

Returns the C<WM_ICON_SIZE> property icon sizes, I<$sizes>, for the
window, I<$root>, or C<undef> when the C<WM_ICON_SIZE> property does not
exist for I<$root>.
I<$sizes>, when defined, is a reference to a size hints hash: see
L</WM_ICON_SIZE>.

When unspecified, null or zero, I<$root> defaults to C<$X-E<gt>root>.

=cut

sub XGetIconSizes {
    my($X,$root) = @_;
    $root = $X->root unless $root;
    my ($res) = $X->robust_req(
	    GetProperty=>$root,
	    X11::AtomConstants::WM_ICON_SIZE(),
	    0,0,6);
    return undef unless ref $res;
    my($value,$rtype,$format,$after) = @$res;
    return undef unless $format;
    my @cards = unpack('L*',$value);
    my %sizes;
    foreach (qw(min_width min_height max_width max_height width_inc height_inc)) {
	my $val = shift @cards;
	$sizes{$_} = $val ? $val : 0;
    }
    return \%sizes;
}

=item $X->B<XSetIconSizes>(I<$root>,I<$sizes>)

Sets the C<WM_ICON_SIZE> property icon sizes, I<$sizes>, on the window,
I<$root>; or, when I<$sizes> is C<undef>, deletes the C<WM_ICON_SIZE>
property from I<$root>.  I<$sizes>, when defined, is a refernce to a
size hints hash: see L</WM_ICON_SIZE>.

When unspecified, null or zero, I<$root> defaults to C<$X-E<gt>root>.

=cut

sub XSetIconSizes {
    my($X,$root,$sizes) = @_;
    $root = $X->root unless $root;
    return $X->DeleteProperty($root,X11::AtomConstants::CARDINAL())
	unless $sizes;
    my @cards = (0,0,0,0,0,0);
    my $i = 0;
    foreach (qw(min_width min_height max_width max_height width_inc height_inc)) {
	$cards[$i] = $sizes->{$_} if $sizes->{$_}; $i += 1;
    }
    $X->ChangeProperty($root,
	    X11::AtomConstants::WM_ICON_SIZE(),
	    X11::AtomConstants::CARDINAL(),32,
	    Replace=>pack('LLLLLL',@cards));
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

=head1 CONVENIENCE METHODS

=over

=item $X->B<XSetWMProperties>(I<$window>,I<$name>,I<$icon>,I<$argv>,I<$size>,I<$hints>,I<$class>)

Provides a single programming interface for setting those essential window
properties that are used for communicating with other clients
(particularly window and session managers).

When I<$name> is defined, XSetWMName() is called to set the C<WM_NAME>
property.  When I<$icon> is defined, XSetWMIconName() is called to set the
C<WM_ICON_NAME> property.  When I<$argv> is defined, XSetCommand() is called
to set the C<WM_COMMAND> property.  When I<$size> is defined,
XSetWMNormalHints() is called to set the C<WM_NORMAL_HINTS> property.  When
I<$hints> is defined, XSetWMHints() is called to set the C<WM_HINTS>
property.  When I<$class> is defined, XSetClassHint() is called to set the
C<WM_CLASS> property.  If the C<$class-E<gt>{res_name}> is undefined,
C<$ENV{RESOURCE_NAME}> will be used in its stead; when
C<$ENV{RESOURCE_NAME}> is undefined, C<$argv-E<gt>[0]> will be used in
its stead, stripped of directory path prefixes.

=cut

sub XSetWMProperties {
    my($X,$window,$name,$icon,$argv,$size,$hints,$class) = @_;
    $X->XStoreName($window,$name) if defined $name;
    $X->XSetIconName($window,$icon) if defined $icon;
    $X->XSetCommand($window,$argv) if defined $argv;
    $X->XSetWMNormalHints($window,$hints) if defined $hints;
    if (defined $class) {
	$class->{res_name}  = '' unless $class->{res_name};
	$class->{res_class} = '' unless $class->{res_class};
	$class->{res_name} = $ENV{RESOURCE_NAME} unless $class->{res_name};
	unless ($class->{res_name} or not $argv) {
	    my $command = $argv->[0];
	    $command = '' unless $command;
	    $command =~ s{^.*/}{};
	    $class->{res_name} = $command;
	}
	$class->{res_name} = '' unless $class->{res_name};
	$X->XSetClassHint($window,$class);
    }
}

=back

=over

=item $X->B<XReconfigureWMWindow>(I<$window>, I<$screen>, I<$changes>) => $boolean

Issues a ConfigureWindow() request on the specified top-level window.  If
the stacking mode is changed and the request fails with a C<Match> error,
the error is trapped and a synthetic C<ConfigureRequestEvent> containing
the same configuration parameters is sent to the root of the specified
window.

I<$changes>, when defined, is a reference to a hash containing the
following keys (just as passed to L<X11::Protocol/ConfigureWindow>):

 x, y
 width, height
 border_width
 sibling
 stack_mode

Only the keys that are to be changed are included.

=cut

sub XReconfigureWMWindow {
    my($X,$window,$screen,$changes) = @_;

    my ($res) = $X->robust_req(ConfigureWindow=>$window,%$changes);
    return 1 if ref $res eq 'ARRAY';
    return 0 unless $res eq 'Match';
    ($res) = $X->robust_req(QueryTree=>$window);
    return 0 unless $res eq 'ARRAY';
    my ($root) = @$res;
    $X->SendEvent($root,0,
	    $X->pack_event_mask(qw(
		    SubstructureRedirect
		    SubstructureNotify)),
	    $X->pack_event(
		name=>'ConfigureRequest',
		parent=>$root,
		window=>$window,
		%$changes));
    return 1;
}

=back

=head2 Changing Window State

=over

=item $X->B<XIconifyWindow>(I<$window>, I<$screen>) => $boolean

Sends a C<WM_CHANGE> C<ClientMessage> event the root window of the
specified screen to request that the window manager iconify a window.

=cut

sub XIconifyWindow {
    my($X,$window,$screen) = @_;
    my $root;
    if (defined $screen) {
	$root = $X->{screens}[$screen]{root}
	    if defined $X->{screens}[$screen];
    } else {
	my($res) = $X->robust_req(QueryTree=>$window);
	($root) = @$res if ref $res;
    }
    return unless $root;
    $X->SendEvent($root,0,
	    $X->pack_event_mask(qw(
		    SubstructureRedirect
		    SubstructureNotify)),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$window,
		type=> $X->atom('WM_CHANGE_STATE'),
		format=>32,
		data=>pack('LLLLL',3,0,0,0,0))); # 3 = IconicState
    return 1;
}

=item $X->B<XWithdrawWindow>(I<$window>, I<$screen>) => $boolean

Unmaps the window and sends a synthetic C<UnmapNotify> event to the root
window of the specified screen.

=cut

sub XWithdrawWindow {
    my($X,$window,$screen) = @_;
    my $root;
    if (defined $screen) {
	$root = $X->{screens}[$screen]{root}
	    if defined $X->{screens}[$screen];
    } else {
	my($res) = $X->robust_req(QueryTree=>$window);
	($root) = @$res if ref $res;
    }
    return unless $root;
    $X->UnmapWindow($window);
    $X->SendEvent($root,0,
	$X->pack_event_mask(qw(
		SubstructureRedirect
		SubstructureNotify)),
	$X->pack_event(
	    name=>'UnmapNotify',
	    event=>$root, # PEKWM wants $window
	    window=>$window,
	    from_configure=>0));
    return 1;
}

=back

=head1 EVENT HANDLERS

=over

=item $X->B<event_handler_ClientMessageWM_PROTOCOLS>(I<$e>)

=cut

sub event_handler_ClientMessageWM_PROTOCOLS {
    my($X,$e) = @_;
    my $W = $X->{windows}{$e->{window}} or return;
    my ($atom,$timestamp,@data) = unpack('L*',$e->{data});
    my $name = $X->atom_name($atom) or return;
    my $sub = $W->can("wm_protocol_$name");
    $sub = $W->can("wm_protocol") unless $sub;
    return unless $sub;
    &$sub($W,$X,$atom,$timestamp,@data);
}

=item $X->B<event_handler_ClientMessageMANAGER>(I<$e>)

C<MANAGER> client messages are sent to the root window of the default
screen (i.e. screen 0) or the i<primary> screen being controlled by a
window manager.

The C<MANAGER> client message is a notification to non-window manager
clients that the owner has changed for a selection.  With this message and
the C<DestroyNotify> message from the core, it is possible to determine the
manager of a selection without ever using the selection requrests from the
core.

One reason for tracking selections, is that the C<WM_S%d> selection
indicates the presence of an ICCCM 2.0 compliant window manager.  Also,
many window managers place additional information on the window owning the
C<WM_S%d> selection.  Often this window is also the same which as reported
in the C<_WIN_SUPPORING_WM_CHECK> and C<_NET_SUPPORTING_WM_CHECK>
properties on the root window.

=cut

sub _root_to_screen {
    my($X,$root) = @_;
    return undef unless $root;
    # dynamic initialization
    unless (exists $X->{roots}) {
	for (my $i=0;$i<@{$X->{screens}};$i++) {
	    my $sroot = $X->{screens}[$i]{root};
	    $X->{roots}{$sroot}{screen} = $i;
	}
    }
    return $X->{roots}{$root}{screen}
	if $X->{roots}{$root};
    return undef;
}

sub event_handler_ClientMessageMANAGER {
    my($X,$e) = @_;
    ($e->{timestamp},$e->{selection},$e->{owner}) =
	unpack('L*',$e->{data});
    $e->{selection} = $X->atom_name($e->{selection}) || return;
    my $res;
    if ($e->{selection} =~ m{^(.*_S)(\d+)$}) {
	$e->{selection} = $1;
	$e->{screen} = $2;
    } else {
	($res) = $X->robust_req(QueryTree=>$e->{owner});
	my $root = $res->[0] if ref $res;
	$e->{screen} = $X->_root_to_screen($root);
    }
    return unless defined $e->{screen};
    # keep track of selection owners
    ($res) = $X->robust_req(GetWindowAttributes=>$e->{owner});
    if (ref $res) {
	my %attrs = @$res;
	my $mask = $X->pack_event_mask(qw(StructureNotify));
	$mask |= $attrs{your_event_mask};
	($res) = $X->robust_req(ChangeWindowAttributes=>$e->{owner},
		event_mask=>$mask);
	if (ref $res) {
	    $X->{selections}{$e->{selection}}[$e->{screen}] = $e;
	    $X->{sel_owners}{$e->{owner}} = $e;
	}
    }
}

=item $X->B<event_handler_DestroyNotify>(I<$e>)

=cut

sub event_handler_DestroyNotify {
    my($X,$e) = @_;
    my $window = $e->{window};
    my $sel = delete $X->{sel_owners}{$window};
    delete $X->{selections}{$sel->{selection}}[$sel->{screen}] if $sel;
}

=back

=cut

{
    my %seen;
    push @{$EXPORT_TAGS{all}},
	grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
	    foreach keys %EXPORT_TAGS;
}

Exporter::export_ok_tags('all');

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::Protocol(3pm)>,
L<X11::Protocol::AnyEvent(3pm)>.

# vim: set sw=4 tw=72 fo=tcqlorn:
