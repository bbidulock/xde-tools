package XDE::WMH;
use base qw(XDE::ICCCM);
use X11::Protocol;
use strict;
use warnings;

sub get_WIN_SUPPORTING_WM_CHECK {
    my $self = shift;
    my $win;
    if ($win = $self->getWMRootPropertyInt('_WIN_SUPPORTING_WM_CHECK')) {
	if (my $oth = $self->getWMPropertyInt($win,'_WIN_SUPPORTING_WM_CHECK')) {
	    unless ($win == $oth) {
		warn sprintf "Check window 0x%x != 0x%x", $win, $oth;
		$win = undef;
	    }
	}
    }
    unless ($win) {
	if ($win = $self->getWMRootPropertyInt('_WIN_SUPPORTING_WM_CHECK')) {
	    if (my $oth = $self->getWMPropertyInt($win,'_WIN_SUPPORTING_WM_CHECK')) {
		unless ($win == $oth) {
		    warn sprintf "Check window 0x%x != 0x%x", $win, $oth;
		    $win = undef;
		}
	    }
	}
    }
    if ($win) {
	# fill out some other stuff???
	$self->{windows}{$win} = {} unless $self->{windows}{$win};
	$self->{checkwin} = $self->{windows}{$win};
	$self->getWM_CLASS($win);
	$self->get_NET_WM_PID($win);
    } else {
	$win = delete $self->{_WIN_SUPPORTING_WM_CHECK};
	delete $self->{windows}{$win}{_WIN_SUPPORTING_WM_CHECK} if $win;
	delete $self->{_WIN_SUPPORTING_WM_CHECK};
	delete $self->{checkwin};
    }
    return $self->{_WIN_SUPPORTING_WM_CHECK};
}

sub event_handler_PropertyNotify_WIN_SUPPORTING_WM_CHECK {
    shift->get_WIN_SUPPORTING_WM_CHECK;
}

sub get_WIN_PROTOCOLS {
    return shift->getWMRootPropertyAtoms('_WIN_PROTOCOLS');
}

sub event_handler_PropertyNotify_WIN_PROTOCOLS {
    shift->get_WIN_PROTOCOLS;
}

sub get_WIN_WORKAREA {
    return shift->getWMRootPropertyInts('_WIN_WORKAREA');
}

sub set_WIN_WORKAREA {
    my ($self,$minX,$minY,$maxX,$maxY) = @_;
    my $X = $self->{X};
    $X->ChangeProperty($X->root,
	    $X->atom('_WIN_WORKAREA'),
	    $X->atom('CARDINAL'),
	    32, 'Replace', pack('LLLL',$minX,$minY,$maxX,$maxY));
    $X->flush;
}

sub event_handler_PropertyNotify_WIN_WORKAREA {
    shift->get_WIN_WORKAREA;
}

sub get_WIN_CLIENT_LIST {
    return shift->getWMRootPropertyInts('_WIN_CLIENT_LIST');
}

sub event_handler_PropertyNotify_WIN_CLIENT_LIST {
    shift->get_WIN_CLIENT_LIST;
}

sub get_WIN_WORKSPACE_COUNT {
    return shift->getWMRootPropertyInt('_WIN_WORKSPACE_COUNT');
}

sub set_WIN_WORKSPACE_COUNT {
    my ($self,$count) = @_;
    $count = 4 unless $count;
    my $X = $self->{X};
    $X->ChangeProperty($X->root,
	    $X->atom('_WIN_WORKSPACE_COUNT'),
	    $X->atom('CARDINAL'),
	    32, 'Replace', pack('L', $count));
    $X->flush;
}

sub event_handler_PropertyNotify_WIN_WORKSPACE_COUNT {
    shift->get_WIN_WORKSPACE_COUNT;
}

sub get_WIN_WORKSPACE_NAMES {
    return shift->getWMRootPropertyStrings('_WIN_WORKSPACE_NAMES');
}

sub set_WIN_WORKSPACE_NAMES {
    my ($self,@names) = @_;
    my $X = $self->{X};
    $X->ChangeProperty($X->root,
	    $X->atom('_WIN_WORKSPACE_NAMES'),
	    $X->atom('STRING'),
	    8, 'Replace', pack('(Z*)*',@names));
    $X->flush;
}

sub event_handler_PropertyNotify_WIN_WORKSPACE_NAMES {
    shift->get_WIN_WORKSPACE_NAMES;
}

sub get_WIN_DESKTOP_BUTTON_PROXY {
    return shift->getWMRootPropertyInt('_WIN_DESKTOP_BUTTON_PROXY');
}

sub event_handler_PropertyNotify_WIN_DESKTOP_BUTTON_PROXY {
    shift->get_WIN_DESKTOP_BUTTON_PROXY;
}

sub get_WIN_AREA_COUNT {
    my $self = shift;
    my $value = $self->getWMRootPropertyInts('_WIN_AREA_COUNT');
    $value = [ 1, 1 ] unless $value;
    return $value;
}

sub set_WIN_AREA_COUNT {
    my ($self,$cols,$rows) = @_;
    my $X = $self->{X};
    $X->ChangeProperty($X->root,
	    $X->atom('_WIN_AREA_COUNT'),
	    $X->atom('CARDINAL'),
	    32, 'Replace', pack('LL', $cols, $rows));
    $X->flush;
}

sub event_handler_PropertyNotify_WIN_AREA_COUNT {
    shift->get_WIN_AREA_COUNT;
}

sub get_WIN_ICONS {
    return $_[0]->getWMPropertyInts($_[1], '_WIN_ICONS');
}

sub event_handler_PropertyNotify_WIN_ICONS {
    $_[0]->get_WIN_ICONS($_[1]->{window});
}

sub get_WIN_EXPANDED_SIZE {
    return $_[0]->getWMPropertyInts($_[1],'_WIN_EXPANDED_SIZE');
}

sub event_handler_PropertyNotify_WIN_EXPANDED_SIZE {
    $_[0]->get_WIN_EXPANDED_SIZE($_[1]->{window});
}

sub get_WIN_CLIENT_MOVING {
    return $_[0]->getWMPropertyInt($_[1],'_WIN_CLIENT_MOVING');
}

sub set_WIN_CLIENT_MOVING {
    my ($self,$window,$bool) = @_;
    my $X = $self->{X};
    $X->ChangeProperty($window,
	    $X->atom('_WIN_CLIENT_MOVING'),
	    $X->atom('CARDINAL'),
	    32, 'Replace', pack('L',$bool));
    $X->flush;
}

sub event_handler_PropertyNotify_WIN_CLIENT_MOVING {
    $_[0]->get_WIN_CLIENT_MOVING($_[1]->{window});
}

sub get_WIN_LAYER {
    return $_[0]->getWMPropertyInt($_[1],'_WIN_LAYER');
}

use constant {
    _WIN_LAYER_DESKTOP		=> 0,
    _WIN_LAYER_BELOW		=> 2,
    _WIN_LAYER_NORMAL		=> 4,
    _WIN_LAYER_ONTOP		=> 6,
    _WIN_LAYER_DOCK		=> 8,
    _WIN_LAYER_ABOVEDOCK	=> 10,
    _WIN_LAYER_MENU		=> 12,
    _WIN_LAYER_FULLSCREEN	=> 14,
    _WIN_LAYER_ABOVEALL		=> 15,
};

sub set_WIN_LAYER {
    my($self,$window,$layer,$timestamp) = @_;
    $timestamp = 0 unless $timestamp;
    $self->ClientMessage(0,$window,_WIN_LAYER=>
	    pack('LLLLL',$layer,$timestamp,0,0,0));
}

sub event_handler_PropertyNotify_WIN_LAYER {
    $_[0]->get_WIN_LAYER($_[1]->{window});
}

use constant {
    _WIN_TRAY_IGNORE	    => 0,
    _WIN_TRAY_MINIMIZED	    => 1,
    _WIN_TRAY_EXCLUSIVE	    => 2,
};

sub get_ICEWM_TRAY {
    return $_[0]->getWMPropertyInt($_[1],'_ICEWM_TRAY');
}

sub set_ICEWM_TRAY {
    my ($self,$window,$option,$timestamp) = @_;
    $timestamp = 0 unless $timestamp;
    $self->ClientMessage(0,$window,_ICEWM_TRAY=>
	    pack('LLLLL',$option,$timestamp,0,0,0));
}

sub event_handler_PropertyNotify_ICEWM_TRAY {
    $_[0]->get_ICEWM_TRAY($_[1]->{window});
}

sub get_WIN_STATE {
    return $_[0]->getWMPropertyInt($_[1],'_WIN_STATE');
}

use constant {
    _WIN_STATE_STICKY		=> (1<<0),
    _WIN_STATE_MINIMIZED	=> (1<<1),
    _WIN_STATE_MAXIMIZED_VERT	=> (1<<2),
    _WIN_STATE_MAXIMIZED_HORZ	=> (1<<3),
    _WIN_STATE_HIDDEN		=> (1<<4),
    _WIN_STATE_SHADED		=> (1<<5),
    _WIN_STATE_HIDDEN_WORKSPACE	=> (1<<6),
    _WIN_STATE_HIDDEN_TRANSIENT	=> (1<<7),
    _WIN_STATE_FIXED_POSITION	=> (1<<8)|(1<<10),
    _WIN_STATE_ARRANGE_IGNORE	=> (1<<9)|(1<<11),
    _WIN_STATE_SKIP_TASKBAR	=> (1<<24),
    _WIN_STATE_MODAL		=> (1<<25),
    _WIN_STATE_BELOW		=> (1<<26),
    _WIN_STATE_ABOVE		=> (1<<27),
    _WIN_STATE_FULLSCREEN	=> (1<<28),
    _WIN_STATE_WASHIDDEN	=> (1<<29),
    _WIN_STATE_WASMINIMIZED	=> (1<<30),
    _WIN_STATE_WITHDRAWN	=> (1<<31),
};

sub set_WIN_STATE {
    my($self,$window,$toggles,$settings,$timestamp) = @_;
    $timestamp = 0 unless $timestamp;
    $self->ClientMessage(0,$window,_WIN_STATE=>
	    pack('LLLLL',$toggles,$settings,$timestamp,0,0));
}

sub event_handler_PropertyNotify_WIN_STATE {
    $_[0]->get_WIN_STATE($_[1]->{window});
}

sub get_WIN_HINTS {
    return $_[0]->getWMPropertyInt($_[1],'_WIN_HINTS');
}

use constant {
    _WIN_HINTS_SKIP_FOCUS	=> (1<<0),
    _WIN_HINTS_SKIP_WINLIST	=> (1<<1),
    _WIN_HINTS_SKIP_TASKBAR	=> (1<<2),
    _WIN_HINTS_GROUP_TRANSIENT	=> (1<<3),
    _WIN_HINTS_FOCUS_ON_CLICK	=> (1<<4),
    _WIN_HINTS_DO_NOT_COVER	=> (1<<5),
    _WIN_HINTS_DOCK_HORIZONTAL	=> (1<<6),
};

sub set_WIN_HINTS {
    my($self,$window,$hints) = @_;
    $self->ClientMessage(0,$window,_WIN_HINTS=>
	    pack('LLLLL',$hints,0,0,0,0));
}

sub event_handler_PropertyNotify_WIN_HINTS {
    $_[0]->get_WIN_HINTS($_[1]->{window});
}

use constant {
    _WIN_APP_STATE_NONE                 =>0,
    _WIN_APP_STATE_ACTIVE1              =>1,
    _WIN_APP_STATE_ACTIVE2              =>2,
    _WIN_APP_STATE_ERROR1               =>3,
    _WIN_APP_STATE_ERROR2               =>4,
    _WIN_APP_STATE_FATAL_ERROR1         =>5,
    _WIN_APP_STATE_FATAL_ERROR2         =>6,
    _WIN_APP_STATE_IDLE1                =>7,
    _WIN_APP_STATE_IDLE2                =>8,
    _WIN_APP_STATE_WAITING1             =>9,
    _WIN_APP_STATE_WAITING2             =>10,
    _WIN_APP_STATE_WORKING1             =>11,
    _WIN_APP_STATE_WORKING2             =>12,
    _WIN_APP_STATE_NEED_USER_INPUT1     =>13,
    _WIN_APP_STATE_NEED_USER_INPUT2     =>14,
    _WIN_APP_STATE_STRUGGLING1          =>15,
    _WIN_APP_STATE_STRUGGLING2          =>16,
    _WIN_APP_STATE_DISK_TRAFFIC1        =>17,
    _WIN_APP_STATE_DISK_TRAFFIC2        =>18,
    _WIN_APP_STATE_NETWORK_TRAFFIC1     =>19,
    _WIN_APP_STATE_NETWORK_TRAFFIC2     =>20,
    _WIN_APP_STATE_OVERLOADED1          =>21,
    _WIN_APP_STATE_OVERLOADED2          =>22,
    _WIN_APP_STATE_PERCENT000_1         =>23,
    _WIN_APP_STATE_PERCENT000_2         =>24,
    _WIN_APP_STATE_PERCENT010_1         =>25,
    _WIN_APP_STATE_PERCENT010_2         =>26,
    _WIN_APP_STATE_PERCENT020_1         =>27,
    _WIN_APP_STATE_PERCENT020_2         =>28,
    _WIN_APP_STATE_PERCENT030_1         =>29,
    _WIN_APP_STATE_PERCENT030_2         =>30,
    _WIN_APP_STATE_PERCENT040_1         =>31,
    _WIN_APP_STATE_PERCENT040_2         =>32,
    _WIN_APP_STATE_PERCENT050_1         =>33,
    _WIN_APP_STATE_PERCENT050_2         =>34,
    _WIN_APP_STATE_PERCENT060_1         =>35,
    _WIN_APP_STATE_PERCENT060_2         =>36,
    _WIN_APP_STATE_PERCENT070_1         =>37,
    _WIN_APP_STATE_PERCENT070_2         =>38,
    _WIN_APP_STATE_PERCENT080_1         =>39,
    _WIN_APP_STATE_PERCENT080_2         =>40,
    _WIN_APP_STATE_PERCENT090_1         =>41,
    _WIN_APP_STATE_PERCENT090_2         =>42,
    _WIN_APP_STATE_PERCENT100_1         =>43,
    _WIN_APP_STATE_PERCENT100_2         =>44,
};

sub get_WIN_APP_STATE {
    return $_[0]->getWMPropertyInt($_[1],'_WIN_APP_STATE');
}

sub event_handler_PropertyNotify_WIN_APP_STATE {
    $_[0]->get_WIN_APP_STATE($_[1]->{window});
}

sub get_WIN_WORKSPACE {
    return $_[0]->getWMPropertyInt($_[1], '_WIN_WORKSPACE');
}

sub set_WIN_WORKSPACE {
    my($self,$window,$workspace,$timestamp) = @_;
    $window = $self->{X}->root unless $window;
    $timestamp = 0 unless $timestamp;
    $self->ClientMessage(0,$window,_WIN_WORKSPACE=>
	    pack('LLLLL',$workspace,$timestamp,0,0,0));
}

sub event_handler_PropertyNotify_WIN_WORKSPACE {
    $_[0]->get_WIN_WORKSPACE($_[1]->{window});
}

sub get_WIN_WORKSPACES { 
    return $_[0]->getWMPropertyBits($_[1],'_WIN_WORKSPACES');
}

sub set_WIN_WORKSPACES {
    my ($self,$window,$add,$index,$bits,$timestamp) = @_;
    my $prop = $add ? '_WIN_WORKSPACES_ADD' : '_WIN_WORKSPACES_REMOVE';
    $self->ClientMessage(0,$window,$prop=>
	    pack('LLLLL',$index,$bits,$timestamp,0,0));
}

sub event_handler_PropertyNotify_WIN_WORKSPACES {
    $_[0]->get_WIN_WORKSPACES($_[1]->{window});
}

sub get_WIN_AREA {
    my $self = shift;
    my $value = $self->getWMRootPropertyInts('_WIN_WORKSPACE');
    $value = [ 0, 0 ] unless $value;
    return $value;
}

sub set_WIN_AREA {
    my($self,$col,$row) = @_;
    $self->ClientMessage(0,0,_WIN_AREA=>
	    pack('LLLLL',$col,$row,0,0,0));
}

sub event_handler_PropertyNotify_WIN_AREA {
    $_[0]->get_WIN_AREA($_[1]->{window});
}

1;

__END__

=head1 NAME

XDE::WMH -- provides methods for controling window manager hints.

=head1 SYNOPSIS

 use XDE::WMH;

 my $wmh = XDE::WMH->new();

 $wmh->get_WIN_WORKSPACE();

=head1 DESCRIPTION

Provides a module with methods that can be used to control a WMH
compliant window manager.  Note: not all that many window managers are
WMH compliant anymore.  Many that are EWMH compliant have removed
support for WMH (like L<fluxbox(1)>).  Several that support
C<_WIN_DESKTOP_BUTTON_PROXY>, such as L<icewm(1)> and L<fvwm(1)>, still
support WMH; however, L<icewm(1)> has not received any development in
some years.  L<fvwm(1)> may be the only XDE-supported window manager
that continues to be WMH compliant.

=head1 METHODS

The following methods are provided by this module.

=head3 _WIN_SUPPORTING_WM_CHECK, WINDOW/32

=over

=item $wmh->B<get_WIN_SUPPORTING_WM_CHECK> => $window

Returns the supporting window manager check window, or C<undef> is no
such window exists.  This method can support a certain amount of race
condition.

=item $wmh->B<event_handler_PropertyNotify_WIN_SUPPORTING_WM_CHECK>($e,$X,$v)

Event handler for changes in the C<_WIN_SUPPORTING_WM_CHECK> property.

=back

=head3 _WIN_PROTOCOLS, ATOM[]/32

=over

=item $wmh->B<get_WIN_PROTOCOLS> => [ @names ]

Returns an array reference to a list of atom names associated with the
root property indicating support of various WMH protocols, or C<undef>
if the property does not exist on the root window.  Possible values in
the list are:

    _WIN_LAYER, _WIN_STATE, _WIN_HINTS, _WIN_APP_STATE,
    _WIN_EXPANDED_SIZE, _WIN_ICONS, _WIN_WORKSPACE,
    _WIN_WORKSPACE_COUNT, _WIN_WORKSPACE_NAMES,
    _WIN_CLIENT_LIST

    _WIN_AREA_COUNT, _WIN_AREA, _WIN_DESKTOP_BUTTON_PROXY,
    _WIN_SUPPORTING_WM_CHECK, _WIN_WORKAREA

=item $wmh->B<event_handler_PropertyNotify_WIN_PROTOCOLS>($e,$X,$v)

Event handler for changes in the C<_WIN_PROTOCOLS> property.

=back

=head3 _WIN_WORKAREA, CARDINAL[]/32

=over

=item $wmh->B<get_WIN_WORKAREA> => [ $minX, $minY, $maxX, $maxY ]

Returns an array reference to the list of minimum and maximum x and y
coordinates of the avialable work area.  The minimum coordinates are the
upper-left corner and the maximum coordinates are the lower-right corner
of the available area.  This is only set by the window manager.

=item $wmh->B<set_WIN_WORKAREA>($minX,$minY,$maxX,$maxY)

Sets the available work area to the rectangle specified by C<$minX>,
C<$minY>, C<$maxX> and C<$maxY>.

=item $wmh->B<event_handler_PropertyNotify_WIN_WORKAREA>($e,$X,$v)

Event handler for changes in the C<_WIN_WORKAREA> property.

=back

=head3 _WIN_CLIENT_LIST, WINDOW[]/32

=over

=item $wmh->B<get_WIN_CLIENT_LIST> => [ @windows ]

Returns an array reference to a list of windows managed by the window
manager, or C<undef> if the property does not exist.  The list is not
necessarily in any specific order.

=item $wmh->B<event_handler_PropertyNotify_WIN_CLIENT_LIST>($e,$X,$v)

Event handler for changes in the C<_WIN_CLIENT_LIST> property.

=back

=head3 _WIN_WORKSPACE_COUNT, CARDINAL/32

=over

=item $wmh->B<get_WIN_WORKSPACE_COUNT> => $count

Return the number of workspaces, or C<undef> if the property does not
exist.

=item $wmh->B<set_WIN_WORKSPACE_COUNT>($count)

Sets the number of workspaces to C<$count>.  (This changes the root
window property and does not send client messages.)

=item $wmh->B<event_handler_PropertyNotify_WIN_WORKSPACE_COUNT>($e,$X,$v)

Event handler for changes in the C<_WIN_WORKSPACE_COUNT> property.

=back

=head3 _WIN_WORKSPACE_NAMES, STRING[]/8

=over

=item $wmh->B<get_WIN_WORKSPACE_NAMES> => [ @names ]

Return the workspace names as a reference to a list of name strings, or
C<undef> if the property does not exist.

=item $wmh->B<set_WIN_WORKSPACE_NAMES>(@names)

Set the workspace names to the list, C<@names>.  (This simply sets the
property and does not send a client message.)

=item $wmh->B<event_handler_PropertyNotify_WIN_WORKSPACE_NAMES>($e,$X,$v)

Event handler for changes in the C<_WIN_WORKSPACE_NAMES> property.

=back

=head3 _WIN_DESKTOP_BUTTON_PROXY, WINDOW/32

=over

=item $wmh->B<get_WIN_DESKTOP_BUTTON_PROXY> => $window

Gets the window, C<$window> acting as the desktop button proxy, or
C<undef> if no such window exists.

=item $wmh->B<event_handler_PropertyNotify_WIN_DESKTOP_BUTTON_PROXY>($e,$X,$v)

Event handler for changes in the C<_WIN_DESKTOP_BUTTON_PROXY> property.

=back

=head3 _WIN_AREA_COUNT, CARDINAL[]/32

=over

=item $wmh->B<get_WIN_AREA_COUNT> => [ $cols, $rows ]

Get the number of columns and rows of screens provided by the large
desktop area.  When large desktops are not supported, this value will be
(1,1).

=item $wmh->B<set_WIN_AREA_COUNT>($cols,$rows)

Set the number of columns and rows of screens provided by the large
desktop area.  When large desktops are not supported, this value will
always be (1,1).

=item $wmh->B<event_handler_PropertyNotify_WIN_AREA_COUNT>($e,$X,$v)

Event handler for changes in the C<_WIN_AREA_COUNT> property.

=back

=head3 _WIN_ICONS, CARDINAL[]/32

=over

=item $wmh->B<get_WIN_ICONS>($window) => [ $n, $length, ( $pixmap, $mask, $width, $height, $depth, $drawable ) ]

This property contains additional icons for the application.  If this
property is set, the WM will ignore default X icon hings and
KWM_WIN_ICON hint.  Icon Mask can be None if transparency is not
required.

=item $wmh->B<event_handler_PropertyNotify_WIN_ICONS>($e,$X,$v)

Event handler for changes in the C<_WIN_ICONS> property.

=back

=head3 _WIN_EXPANDED_SIZE, CARDINAL[]/32

=over

=item $wmh->B<get_WIN_EXPANDED_SIZE>($window) => [ $x, $y, $w, $h ]

Gets the expanded size of window, C<$window>, as an array reference to
the C<$x>, C<$y>, origin and the C<$w> width and C<$h> height.
The expanded space occupied is the area on the screen that the app's
window will occupy when "expanded".  That is, if you have a button on an
app that "hides" it by reducing its size, this is the geometry of the
expanded window - so the window manager can allow for this when doing
auto position of client windows assuming the app can at any point use
this area and thus try and keep it clear.  Only the client sets this.

=item $wmh->B<event_handler_PropertyNotify_WIN_EXPANDED_SIZE>($e,$X,$v)

Event handler for changes in the C<_WIN_ExPANDED_SIZE> property.

=back

=head3 _WIN_CLIENT_MOVING, CARDINAL/32

=over

=item $wmh->B<get_WIN_CLIENT_MOVING>($window) => $bool

This atom is a 32-bit integer that is either 0 or 1 (currently).  0
denotes everything is as per usual but 1 denotes that ALL configure
requests by the client on the client window with this property are not
just a simple "moving" of the window, but the result of a user move the
window BUT the client is handling that interaction by moving its own
window.  The window manager should respond accordingly by assuming any
configure requestsw for this window whilst this atom is "active" in the
"1" state are a client move and should handle flipping desktops if the
window is being dragged "off screen" or across desktop boundaries etc.
This atom is only ever set by the client.

=item $wmh->B<set_WIN_CLIENT_MOVING>($window,$bool)

Sets the client moving flag to C<$bool> for window, C<$window>.

=item $wmh->B<event_handler_PropertyNotify_WIN_CLIENT_MOVING>($e,$X,$v)

Event handler for changes in the C<_WIN_CLIENT_MOVING> property.

=back

=head3 _WIN_LAYER, CARDINAL/32

=over

=item $wmh->B<get_WIN_LAYER>($window) => $layer

Get the layer, C<$layer>, for the specified window, C<$window>.  The
layers are defined as follows:

    0 - desktop	    _WIN_LAYER_DESKTOP
    2 - below	    _WIN_LAYER_BELOW
    4 - normal	    _WIN_LAYER_NORMAL
    6 - ontop	    _WIN_LAYER_ONTOP
    8 - dock	    _WIN_LAYER_DOCK
   10 - abovedock   _WIN_LAYER_ABOVEDOCK
   12 - menu	    _WIN_LAYER_MENU
   14 - fullscreen  _WIN_LAYER_FULLSCREEN   (IceWM)
   15 - aboveall    _WIN_LAYER_ABOVEALL	    (IceWM)

=item $wmh->B<set_WIN_LAYER>($window,$layer,$timestamp)

Sets the layer for window, C<$window>, using the following client
message:

 _WIN_LAYER
   window = respective window
   message_type = _WIN_LAYER
   format = 32
   data.l[0] = layer
   data.l[1] = timestamp
   other data.l[] elements = 0

   layer is:

    0 - desktop	    _WIN_LAYER_DESKTOP
    2 - below	    _WIN_LAYER_BELOW
    4 - normal	    _WIN_LAYER_NORMAL
    6 - ontop	    _WIN_LAYER_ONTOP
    8 - dock	    _WIN_LAYER_DOCK
   10 - abovedock   _WIN_LAYER_ABOVEDOCK
   12 - menu	    _WIN_LAYER_MENU
   14 - fullscreen  _WIN_LAYER_FULLSCREEN   (IceWM)
   15 - aboveall    _WIN_LAYER_ABOVEALL	    (IceWM)

=item $wmh->B<event_handler_PropertyNotify_WIN_LAYER>($e,$X,$v)

Event handler for changes in the C<_WIN_LAYER> property.

=back

=head3 _ICEWM_TRAY, CARDINAL/32

=over

=item $wmh->B<get_ICEWM_TRAY>($window) => $option

Gets the IceWM tray option associate with C<$window>.  This can be
C<undef> when the property does not exist on C<$window>, or on one of
the following values:

   0 - ignore	    _WIN_TRAY_IGNORE
   1 - minimized    _WIN_TRAY_MINIMIZED
   2 - exclusive    _WIN_TRAY_EXCLUSIVE

When set to I<ignore> (default), the window has its window button only
on TaskPane.  When set to I<mimimized>, the window has its icon on
TrayPane and only has a window button on TaskPane if it is not
mimimized.  When set to I<exclusive>, the window only has its icon on
the TrayPane and there is no window button on TaskPane.  Note that using
the "Tray Icon" selection from the window menu, toggles from 0 to 2 and
back again.  The "TrayPane" is on the IceWM panel where the system tray is
located.  The "TaskPane" is the task bar portion of the IceWM panel.

=item $wmh->B<set_ICEWM_TRAY>($window,$option)

Sets the IceWM tray option, C<$option>, for the specified window,
C<$window>, by sending the following client message:

 _ICEWM_TRAY
   window = respective window
   message_type = _ICEWM_TRAY
   format = 32
   data.l[0] = tray_opt
   data.l[1] = timestamp
   other data.l[] elements = 0

   tray_opt is:

   0 - ignore	    _WIN_TRAY_IGNORE
   1 - minimized    _WIN_TRAY_MINIMIZED
   2 - exclusive    _WIN_TRAY_EXCLUSIVE

=item $wmh->B<event_handler_PropertyNotify_ICEWM_TRAY>($e,$X,$v)

Event handler for changes in the C<_ICEWM_TRAY> property.

=back

=head3 _WIN_STATE, CARDINAL/32

=over

=item $wmh->B<get_WIN_STATE>($window) => $state

Get the window state, C<$state> associated with a given window,
C<$window>.  The value is a bitmask that contains the following bit
defintions:

   0x001 - sticky		    _WIN_STATE_STICKY
   0x002 - minimized		    _WIN_STATE_MINIMIZED
   0x004 - maximized vertical	    _WIN_STATE_MAXIMIZED_VERT
   0x008 - maximized horizontal	    _WIN_STATE_MAXIMIZED_HORZ
   0x010 - hidden		    _WIN_STATE_HIDDEN
   0x020 - shaded		    _WIN_STATE_SHADED
   0x040 - hidden workspace	    _WIN_STATE_HIDDEN_WORKSPACE
   0x080 - hidden transient	    _WIN_STATE_HIDDEN_TRANSIENT
   0x100 - fixed position	    _WIN_STATE_FIXED_POSITION
   0x200 - arrange ignore	    _WIN_STATE_ARRANGE_IGNORE

   0x0400 - fixed position	    _WIN_STATE_FIXED_POSITION	(IceWM)
   0x0800 - arrange ignore	    _WIN_STATE_ARRANGE_IGNORE	(IceWM)

   0x01000000 - skip taskbar	    _WIN_STATE_SKIP_TASKBAR	(IceWM)
   0x02000000 - modal		    _WIN_STATE_MODAL		(IceWM)
   0x04000000 - below layer	    _WIN_STATE_BELOW		(IceWM)
   0x08000000 - above layer	    _WIN_STATE_ABOVE		(IceWM)
   0x10000000 - fullscreen	    _WIN_STATE_FULLSCREEN	(IceWM)
   0x20000000 - was hidden	    _WIN_STATE_WASHIDDEN	(IceWM)
   0x40000000 - was mimimized	    _WIN_STATE_WASMINIMIZED	(IceWM)
   0x80000000 - withdrawn	    _WIN_STATE_WITHDRAWN	(IceWM)

=item $wmh->B<set_WIN_STATE>($window,$toggles,$settings,$timestamp)

Sets the window state for window, C<$window>, using the folowing client
message:

 _WIN_STATE
   window = respective window
   message_type = _WIN_STATE
   format = 32
   data.l[0] = toggles
   data.l[1] = settings
   other data.l[] elements = 0

   toggles and settings are:

   0x0001 - sticky		    _WIN_STATE_STICKY
   0x0002 - minimized		    _WIN_STATE_MINIMIZED
   0x0004 - maximized vertical	    _WIN_STATE_MAXIMIZED_VERT
   0x0008 - maximized horizontal    _WIN_STATE_MAXIMIZED_HORZ
   0x0010 - hidden		    _WIN_STATE_HIDDEN
   0x0020 - shaded		    _WIN_STATE_SHADED
   0x0040 - hidden workspace	    _WIN_STATE_HIDDEN_WORKSPACE
   0x0080 - hidden transient	    _WIN_STATE_HIDDEN_TRANSIENT
   0x0100 - fixed position	    _WIN_STATE_FIXED_POSITION
   0x0200 - arrange ignore	    _WIN_STATE_ARRANGE_IGNORE

   0x0400 - fixed position	    _WIN_STATE_FIXED_POSITION	(IceWM)
   0x0800 - arrange ignore	    _WIN_STATE_ARRANGE_IGNORE	(IceWM)

   0x01000000 - skip taskbar	    _WIN_STATE_SKIP_TASKBAR	(IceWM)
   0x02000000 - modal		    _WIN_STATE_MODAL		(IceWM)
   0x04000000 - below layer	    _WIN_STATE_BELOW		(IceWM)
   0x08000000 - above layer	    _WIN_STATE_ABOVE		(IceWM)
   0x10000000 - fullscreen	    _WIN_STATE_FULLSCREEN	(IceWM)
   0x20000000 - was hidden	    _WIN_STATE_WASHIDDEN	(IceWM)
   0x40000000 - was mimimized	    _WIN_STATE_WASMINIMIZED	(IceWM)
   0x80000000 - withdrawn	    _WIN_STATE_WITHDRAWN	(IceWM)

Note that some documentation shows I<toggles> as the bits to toggle and
I<settings> as the bits to set.  Others show I<toggles> as a bit mask of bits
to set or reset and I<settings> as the absolute settings of those masked
bits.

=item $wmh->B<event_handler_PropertyNotify_WIN_STATE>($e,$X,$v)

Event handler for changes in the C<_WIN_STATE> property.

=back

=head3 _WIN_HINTS, CARDINAL/32

=over

=item $wmh->B<get_WIN_HINTS>($window) => $hints

Get the window manager hints associated with a window, C<$window> and
return them as a scalar integer value.  C<$hints> is a bitmask of zero
or more of the following:

    0x01 - skip focus (*)	    _WIN_HINTS_SKIP_FOCUS
    0x02 - skip winlist		    _WIN_HINTS_SKIP_WINLIST
    0x04 - skip taskbar		    _WIN_HINTS_SKIP_TASKBAR
    0x08 - group transient	    _WIN_HINTS_GROUP_TRANSIENT
    0x10 - focus on click (**)	    _WIN_HINTS_FOCUS_ON_CLICK
    0x20 - do not cover (***)	    _WIN_HINTS_DO_NOT_COVER	(IceWM)
    0x40 - dock horizontal (****)   _WIN_HINTS_DOCK_HORIZONTAL	(IceWM)

    (*)   alt-tab skips this window
    (**)   app only accepts focus if clicked
    (***)  attempt to not cover this window
    (****) docked horizontally

=item $wmh->B<set_WIN_HINTS>($window, $hints)

Sets the window manager hints, C<$hints>, associated with a window,
C<$window>, using the following client message:

 _WIN_HINTS
    window = respective window
    message_type = _WIN_HINTS
    format = 32
    data.l[0] = hints
    other data.l[] elements = 0

    hints is:

    0x01 - skip focus (*)	    _WIN_HINTS_SKIP_FOCUS
    0x02 - skip winlist		    _WIN_HINTS_SKIP_WINLIST
    0x04 - skip taskbar		    _WIN_HINTS_SKIP_TASKBAR
    0x08 - group transient	    _WIN_HINTS_GROUP_TRANSIENT
    0x10 - focus on click (**)	    _WIN_HINTS_FOCUS_ON_CLICK
    0x20 - do not cover (***)	    _WIN_HINTS_DO_NOT_COVER	(IceWM)
    0x40 - dock horizontal (****)   _WIN_HINTS_DOCK_HORIZONTAL	(IceWM)

    (*)   alt-tab skips this window
    (**)   app only accepts focus if clicked
    (***)  attempt to not cover this window
    (****) docked horizontally

=item $wmh->B<event_handler_PropertyNotify_WIN_HINTS>($e,$X,$v)

Event handler for changes in the C<_WIN_HINTS> property.

=back

=head3 _WIN_APP_STATE, CARDINAL/32

=over

=item $wmh->B<get_WIN_APP_STATE>($window) => $state

Gets the application state (also "color reactiveness") - the app can
keep changing this property when it changes its state and the WM or
monitoring program will pick this up and display something accordingly.
Only the client sets this property.

    _WIN_APP_STATE_NONE                 0
    _WIN_APP_STATE_ACTIVE1              1
    _WIN_APP_STATE_ACTIVE2              2
    _WIN_APP_STATE_ERROR1               3
    _WIN_APP_STATE_ERROR2               4
    _WIN_APP_STATE_FATAL_ERROR1         5
    _WIN_APP_STATE_FATAL_ERROR2         6
    _WIN_APP_STATE_IDLE1                7
    _WIN_APP_STATE_IDLE2                8
    _WIN_APP_STATE_WAITING1             9
    _WIN_APP_STATE_WAITING2             10
    _WIN_APP_STATE_WORKING1             11
    _WIN_APP_STATE_WORKING2             12
    _WIN_APP_STATE_NEED_USER_INPUT1     13
    _WIN_APP_STATE_NEED_USER_INPUT2     14
    _WIN_APP_STATE_STRUGGLING1          15
    _WIN_APP_STATE_STRUGGLING2          16
    _WIN_APP_STATE_DISK_TRAFFIC1        17
    _WIN_APP_STATE_DISK_TRAFFIC2        18
    _WIN_APP_STATE_NETWORK_TRAFFIC1     19
    _WIN_APP_STATE_NETWORK_TRAFFIC2     20
    _WIN_APP_STATE_OVERLOADED1          21
    _WIN_APP_STATE_OVERLOADED2          22
    _WIN_APP_STATE_PERCENT000_1         23
    _WIN_APP_STATE_PERCENT000_2         24
    _WIN_APP_STATE_PERCENT010_1         25
    _WIN_APP_STATE_PERCENT010_2         26
    _WIN_APP_STATE_PERCENT020_1         27
    _WIN_APP_STATE_PERCENT020_2         28
    _WIN_APP_STATE_PERCENT030_1         29
    _WIN_APP_STATE_PERCENT030_2         30
    _WIN_APP_STATE_PERCENT040_1         31
    _WIN_APP_STATE_PERCENT040_2         32
    _WIN_APP_STATE_PERCENT050_1         33
    _WIN_APP_STATE_PERCENT050_2         34
    _WIN_APP_STATE_PERCENT060_1         35
    _WIN_APP_STATE_PERCENT060_2         36
    _WIN_APP_STATE_PERCENT070_1         37
    _WIN_APP_STATE_PERCENT070_2         38
    _WIN_APP_STATE_PERCENT080_1         39
    _WIN_APP_STATE_PERCENT080_2         40
    _WIN_APP_STATE_PERCENT090_1         41
    _WIN_APP_STATE_PERCENT090_2         42
    _WIN_APP_STATE_PERCENT100_1         43
    _WIN_APP_STATE_PERCENT100_2         44

=item $wmh->B<event_handler_PropertyNotify_WIN_APP_STATE>($e,$X,$v)

Event handler for changes in the C<_WIN_APP_STATE> property.

=back

=head3 _WIN_WORKSPACE, CARDINAL/32

=over

=item $wmh->B<set_WIN_WORKSPACE>($window) =>  $workspace

Return the current workspace of a window, C<$window>, or the root, as a
scalar integer value.

=item $wmh->B<set_WIN_WORKSPACE>($window, $workspace, $timestamp)

Sets the active workspace to C<$workspace> using the following client
message:

 _WIN_WORKSPACE
   window = respective window
   message_type = _WIN_WORKSPACE
   format = 32
   data.l[0] = new_desktop_number
   data.l[1] = timestamp
   other data.l[] elements = 0

=item $wmh->B<event_handler_PropertyNotify_WIN_WORKSPACE>($e,$X,$v)

Event handler for changes in the C<_WIN_WORKSPACE> property.

=back

=head3 _WIN_WORKSPACES, CARDINAL[]/32

=over

=item $wmh->B<get_WIN_WORKSPACES>($window) = [ @bitmask ]

Return a bitmask of the workspaces on which a specified window,
C<$window> is to appear, or C<undef> if this propert is not set on
C<$window>.

=item $wmh->B<set_WIN_WORKSPACES>($window,$add,$index,$bits,$timestamp)

Sets a set of 32 workspaces on which a window, C<$window>, appears.
C<$add> is true when the workspaces are to be added to the list of
workspaces on which C<$window> appears; and false when they are to be
removed.  C<$index> provides an index of the set of 32 workspaces to
which the setting applies; C<$bits> is the bit mask of the 32 workspaces
indexed.  C<$timestamp> is the timestamp of the event causing the
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

=item $wmh->B<event_handler_PropertyNotify_WIN_WORKSPACES>($e,$X,$v)

Event handler for changes in the C<_WIN_WORKSPACES> property.

=back

=head3 _WIN_AREA, CARDINAL[]/32

=over

=item $wmh->B<get_WIN_AREA> => [ $col, $row ]

Return the current workspace area as a column index (starting at zero
0), C<$col>, and a row index (starting at 0), C<$row>.  Returns the
current area as an array reference.

=item $wmh->B<set_WIN_AREA>($col,$row)

Sets the active area within the workspace to the area starting at
index, C<$col>, C<$row> using the following client message:

 _WIN_AREA
   window = root
   message_type = _WIN_AREA
   format = 32
   data.l[0] = new_active_area_x
   data.l[1] = new_active_area_y
   other data.l[] elements = 0

=item $wmh->B<event_handler_PropertyNotify_WIN_AREA>($e,$X,$v)

Event handler for changes in the C<_WIN_AREA> property.

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>, L<XDE::ICCCM(3pm)>

=cut

# vim: sw=4 tw=72



