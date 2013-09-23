package XDE::Keys;
use base qw(XDE::Dual);
use Glib qw(TRUE FALSE);
use strict;
use warnings;

=head1 NAME

XDE::Keys -- perform actions on key bindings

=head1 SYNOPSIS

 use XDE::Keys;

 my $keys = XDE::Keys->new();
 $keys->init;
 $keys->set_bindings(
    'Alt+Up' => 'WindowRaise',
    'Alt+Down' => 'WindowLower');
 $keys->main;

=head1 DESCRIPTION

Provides a module that runs out of the L<Glib::Mainloop(3pm)> that will
set key bindings and perform the actions associated with those key
bindings.  It basically performs a similar action to that of
L<bbkeys(1)>, but also provides the ability to edit the key definitions
with a graphical interface and performs some functions not provided by
L<bbkeys(1)>.

=head1 METHODS

=over

=cut

=item $keys = XDE::Keys->B<new>(I<%OVERRIDES>)

Creates an instance of an XDE::Keys object.  The XDE::Keys module uses
the L<XDE::Context(3pm)> module as a base, so the C<%OVERRIDES> are
simply passed to the L<XDE::Context(3pm)> module.

=cut

sub new {
    return XDE::Context::new(@_);
}

=item $keys->B<wmpropcheck>() => $window or undef

Internal method for checking a recursive property such as
B<_NET_SUPPORTING_WM_CHECK>.

=cut

sub wmpropcheck {
    my $self = shift;
    my ($screen,$root,$n,$atom,$label) = @_;
    return undef unless $screen;
    my $result = undef;
    my $X = $self->{X};
    my $v = $self->{ops}{verbose};
    my ($val,$type) = $X->GetProperty($root,$atom,0,0,1);
    if ($type) {
	my $check = unpack('L',substr($val,0,4));
	print STDERR "found $label check on root window\n" if $v;
	($val,$type) = $X->GetProperty($check,$atom,0,0,1);
	if ($type and $check == unpack('L',substr($val,0,4))) {
	    print STDERR "found $label on check window\n" if $v;
	    unless ($screen->{$label} and $screen->{$label} == $check) {
		print STDERR "new $label check window\n" if $v;
		$screen->{$label} = $check;
		$self->{roots}{$check} = $n;
		$result = $check;
	    } else {
		print STDERR "$label check unchanged\n" if $v;
		$result = 0;
	    }
	} else {
	    print STDERR "Could not retrieve ", $X->atom_name($atom), "\n";
	}
    } else {
	print STDERR "Could not retrieve ", $X->atom_name($atom), "\n";
    }
    return $result;
}

=item $xde->B<win_wmcheck>()

Internal method to check for B<_WIN_SUPPORTING_WM_CHECK>.  Unfortunately
there is not enough information to identify the window manager.

=cut

sub win_wmcheck {
    my $self = shift;
    my $X = $self->{X};
    my $atom = $X->atom('_WIN_SUPPORTING_WM_CHECK');
    return $self->wmpropcheck(@_, $atom, 'wcheck');
}

=item $xde->B<net_wmcheck>()

Internal method to check for B<_NET_SUPPORTING_WM_CHECK> and establish
the identity of the window manager.

=cut

sub net_wmcheck {
    my $self = shift;
    my $X = $self->{X};
    my $atom = $X->atom('_NET_SUPPORTING_WM_CHECK');
    my $check = $self->wmpropcheck(@_, $atom, 'ncheck');
    if ($check) {
	my $atom = $X->atom('_NET_WM_NAME');
	my ($val,$type) = $X->GetProperty($check, $atom, 0, 0, 255);
	if ($type) {
	    my ($name) = unpack('(Z*)*',$val);
	    ($name) = split(/\s+/,$name);
	    if ($name) {
		$self->{wmname} = "\L$name\E";
		print STDERR "Window Manager name is: \L$name\E\n"
		    if $self->{ops}{verbose};
	    } else {
		print STDERR "Null name!\n";
		$self->{wmname} = '' unless $self->{wmname};
	    }
	} else {
	    print STDERR "Could not retrieve ", $X->atom_name($atom), "\n";
	    print STDERR "Guessing WindowMaker\n";
	    $self->{wmname} = 'wmaker';
	}
	# TODO: There are some other things to do here, such as
	# resetting the theme.
    }
    return $check;
}

=item $xde->B<win_bpcheck>()

Internal method to check for B<_WIN_DESKTOP_BUTTON_PROXY>.  Also,
register for C<SubstructureNotify> events when the button proxy exists
so that we can receive scroll wheel events to change the desktop.

=cut

sub win_bpcheck {
    my $self = shift;
    my ($screen,$root,$n) = @_;
    my $X = $self->{X};
    my $atom = $X->atom('_WIN_DESKTOP_BUTTON_PROXY');
    my $proxy = $self->wmpropcheck(@_, $atom, 'proxy');
    if ($screen->{proxy}) {
	$X->ChangeWindowAttributes($screen->{proxy},
		event_mask=>$X->pack_event_mask('SubstructureNotify'));
    }
    return $proxy;
}

=item $xde->B<_init>()

Performs initialization for just this module.  Called after
L<XDE::Dual(3pm)> is fully initialized.

=cut

sub _init {
    my $self = shift;
    my $X = $self->{X};
    my $v = $self->{ops}{verbose};
    $X->ChangeWindowAttributes($X->root,
	    event_mask=>$X->pack_event_mask(
		'PropertyChange',
		'StructureNotify'));
    for (my $n=0;$n<@{$X->{screens}};$n++) {
	my $screen = $self->{screen}[$n];
	$screen = $self->{screen}[$n] = {index=>$n} unless $screen;
	my $root = $screen->{root} = $X->{screens}[$n]{root};
	$self->{roots}{$root} = $n;
	$self->win_bpcheck($screen,$root,$n);
	$self->win_wmcheck($screen,$root,$n);
	$self->net_wmcheck($screen,$root,$n);
    }
    return $self;
}

=item $keys->B<_term>()

Performs termination for just this module.  Called before
C<XDE::X11-E<gt>term()> is called.

B<XDE::Keys> performs some passive key grabs, but they do not persist on
close.

=cut

sub _term {
    my $self = shift;
}

# send functions

=item $keys->B<send_WINDOWMAKER_COMMAND>

There is only one L<wmaker(1)> command: 'Reconfigure', sent to the root
window as follows:

 _WINDOWMAKER_COMMAND
    target = root
    mask = SubstructureRedirect
    window = root
    message_type = _WINDOWMAKER_COMMAND
    format = 8
    data.b[] = 'Reconfigure'

=cut

sub send_WINDOWMAKER_COMMAND {
    my($self) = @_;
    my $X = $self->{X};
    $X->SendEvent($X->root, 0,
	    $X->pack_event_mask(qw(
		    StructureNotify
		    SubstructureNotify
		    SubstructureRedirect)),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$X->root,
		type=>$X->atom('_WINDOWMAKER_COMMAND'),
		format=>8,
		data=>pack('a20','Reconfigure'),
	    ));
    $X->flush;
}

=item $keys->B<send_WINDOWMAKER_WM_FUNCTION>($window,$how)

The WM function can be sent to perform a hide application or hide other
applications on a window under L<wmaker(1)>.  The client message is sent
to the root window as follows:

 _WINDOWMAKER_WM_FUNCTION
    target = root
    mask = SubstructureRedirect | SubstructureNotify
    window = respective window
    message_type = _WINDOWMAKER_WM_FUNCTION
    format = 32
    data.l[0] = how: hideapp(12), hideothers(10)
    other data.l[] elements = 0

=cut

sub send_WINDOWMAKER_WM_FUNCTION {
    my($self,$window,$how) = @_;
    my $X = $self->{X};
    $X->SendEvent($X->root, 0,
	    $X->pack_event_mask(qw(
		    StructureNotify
		    SubstructureNotify
		    SubstructureRedirect)),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$window,
		type=>$X->atom('_WINDOWMAKER_WM_FUNCTION'),
		format=>32,
		data=>pack('LLLLL',$how,0,0,0,0),
	    ));
    $X->flush;
}

=item $keys->B<send_GNUSTEP_TITLEBAR_STATE>($window,$state)

This client message can be sent to a client window to set the state of
the title bar to normal, main, or key.  The client message is sent to the
client window as follows:

 _GNUSTEP_TITLEBAR_STATE
    target = respective window
    mask = SubstructureRedirect | SubstructureNotify
    window = respective window
    message_type = _GNUSTEP_TITLEBAR_STATE
    format = 32
    data.l[0] = state: Key(0), Normal(1), Main(2)
    other data.l[] elements = 0

Key(0) corresponds to the FOCUSED state for themes (C<FTitleColor> and
C<FTitleBack>); C<Normal>(1) the C<UNFOCUSED> state (C<UTitleColor> and
C<UTitleBack>), and C<Main>(2) the C<PFOCUSED> state (C<PTitleColor>
and C<PTitleBack>).  I'm not sure how useful this is.

=cut


# specials

=item $keys->B<get_WINDOWMAKER_WM_PROTOCOLS>()

=item $keys->B<event_handler_PropertyNotify_WINDOWMAKER_WM_PROTOCOLS>

These include _WINDOWMAKER_MENU, _WINDOWMAKER_WM_FUNCTION, and
_WINDOWMAKER_NOTICEBOARD.  Looks like a way to pop the menu, perform a
windowmaker-specific function, and post the windowmaker notice board.
There are also atoms for _WINDOWMAKER_COMMAND, _WINDOWMAKER_ICON_SIZE,
_WINDOWMAKER_ICON_TILE, and _WINDOWMAKER_STATE.

There is also _GNUSTEP_TITLEBAR_STATE, _GNUSTEP_WM_ATTR,
_GNUSTEP_WM_FUNCTION, and _GNUSTEP_WM_MINIATURIZE_WINDOW.

=item $keys->B<get_WIN_AREA>()

=item $keys->B<event_handler_PropertyNotify_WIN_AREA>

=item $keys->B<get_WIN_AREA_COUNT>()

=item $keys->B<event_handler_PropertyNotify_WIN_AREA_COUNT>

=item $keys->B<get_WIN_CLIENT_LIST>()

=item $keys->B<event_handler_PropertyNotify_WIN_CLIENT_LIST>

=item $keys->B<get_WIN_DESKTOP_BUTTON_PROXY>()

=item $keys->B<event_handler_PropertyNotify_WIN_DESKTOP_BUTTON_PROXY>

There are two window managers that provide a desktop button proxy: IceWM
and FVWM.

=item $keys->B<get_WIN_PROTOCOLS>()

=item $keys->B<event_handler_PropertyNotify_WIN_PROTOCOLS>

=item $keys->B<get_WIN_SUPPORTING_WM_CHECK>()

=item $keys->B<event_handler_PropertyNotify_WIN_SUPPORTING_WM_CHECK>

=item $keys->B<get_WIN_WORKAREA>()

=item $keys->B<event_handler_PropertyNotify_WIN_WORKAREA>

=item $keys->B<get_WIN_WORKSPACE>()

=item $keys->B<event_handler_PropertyNotify_WIN_WORKSPACE>

=item $keys->B<get_WIN_WORKSPACE_COUNT>()

=item $keys->B<event_handler_PropertyNotify_WIN_WORKSPACE_COUNT>

=item $keys->B<get_WIN_WORKSPACE_NAMES>()

=item $keys->B<event_handler_PropertyNotify_WIN_WORKSPACE_NAMES>

=item $keys->B<get_NET_ACTIVE_WINDOW>()

=item $keys->B<event_handler_PropertyNotify_NET_ACTIVE_WINDOW>

=item $keys->B<get_NET_CLIENT_LIST>()

=item $keys->B<event_handler_PropertyNotify_NET_CLIENT_LIST>

=item $keys->B<get_NET_CLIENT_LIST_STACKING>()

=item $keys->B<event_handler_PropertyNotify_NET_CLIENT_LIST_STACKING>

=item $keys->B<get_NET_CURRENT_DESKTOP>()

=item $keys->B<event_handler_PropertyNotify_NET_CURRENT_DESKTOP>

=item $keys->B<get_NET_DESKTOP_GEOMETRY>()

=item $keys->B<event_handler_PropertyNotify_NET_DESKTOP_GEOMETRY>

=item $keys->B<get_NET_DESKTOP_LAYOUT>()

=item $keys->B<event_handler_PropertyNotify_NET_DESKTOP_LAYOUT>

_NET_DESKTOP_LAYOUT is 3 or 4 integers: C<orientation>, C<rows>,
C<columns>, C<starting corner>.  If C<starting corner> is not present,
it is assumed to be top-left for backward compatibility.
C<orientation> is horizontal(0) or vertical(1); if C<rows> or C<columns>
is zero(0), the actual number should be derived from
_NET_NUMBER_OF_DESKTOPS.  C<starting corner> is topleft(0), topright(1),
bottomright(1) or bottomleft(3).

Supported by OpenBox, PeK,

=item $keys->B<get_NET_DESKTOP_NAMES>()

=item $keys->B<event_handler_PropertyNotify_NET_DESKTOP_NAMES>

=item $keys->B<get_NET_DESKTOP_PIXMAPS>()

=item $keys->B<event_handler_PropertyNotify_NET_DESKTOP_PIXMAPS>

=item $keys->B<get_NET_DESKTOP_VIEWPORT>()

=item $keys->B<event_handler_PropertyNotify_NET_DESKTOP_VIEWPORT>

=item $keys->B<get_NET_NUMBER_OF_DESKTOPS>()

=item $keys->B<event_handler_PropertyNotify_NET_NUMBER_OF_DESKTOPS>

=item $keys->B<get_NET_SHOWING_DESKTOP>()

=item $keys->B<event_handler_PropertyNotify_NET_SHOWING_DESKTOP>

Note supported by all XDE window managers.  The following support it:
WindowMaker, OpenBox, JWM.

=item $keys->B<get_NET_SUPPORTED>()

=item $keys->B<event_handler_PropertyNotify_NET_SUPPORTED>

=item $keys->B<get_NET_SUPPORTING_WM_CHECK>()

=item $keys->B<event_handler_PropertyNotify_NET_SUPPORTING_WM_CHECK>

=item $keys->B<get_NET_WM_PID>()

=item $keys->B<event_handler_PropertyNotify_NET_WM_PID>

Note that PeK sets _NET_WM_PID on the root window while most others set
it on the check window.

=item $keys->B<get_NET_WORKAREA>()

=item $keys->B<event_handler_PropertyNotify_NET_WORKAREA>

=back

=head1 SUPPORT

The following window managers at the time of writing support the
following:

=over

=item JWM

 _NET_WM_CM_S0
 _XSETTINGS_S0
 _NET_SYSTEM_TRAY_S0

 _NET_ACTIVE_WINDOW
 _NET_CLIENT_LIST
 _NET_CLIENT_LIST_STACKING
 _NET_CLOSE_WINDOW
 _NET_CURRENT_DESKTOP
 _NET_DESKTOP_GEOMETRY
 _NET_DESKTOP_NAMES
 _NET_DESKTOP_VIEWPORT
 _NET_FRAME_EXTENTS
 _NET_MOVERESIZE_WINDOW
 _NET_NUMBER_OF_DESKTOPS
 _NET_REQUEST_FRAME_EXTENTS
 _NET_SHOWING_DESKTOP
 _NET_SUPPORTED
 _NET_SUPPORTING_WM_CHECK
 _NET_SYSTEM_TRAY_OPCODE
 _NET_WM_ACTION_ABOVE
 _NET_WM_ACTION_BELOW
 _NET_WM_ACTION_CHANGE_DESKTOP
 _NET_WM_ACTION_CLOSE
 _NET_WM_ACTION_MAXIMIZE_HORZ
 _NET_WM_ACTION_MAXIMIZE_VERT
 _NET_WM_ACTION_MINIMIZE
 _NET_WM_ACTION_MOVE
 _NET_WM_ACTION_RESIZE
 _NET_WM_ACTION_SHADE
 _NET_WM_ACTION_STICK
 _NET_WM_ALLOWED_ACTIONS
 _NET_WM_DESKTOP
 _NET_WM_ICON
 _NET_WM_NAME
 _NET_WM_STATE
 _NET_WM_STATE_ABOVE
 _NET_WM_STATE_BELOW
 _NET_WM_STATE_FULLSCREEN
 _NET_WM_STATE_HIDDEN
 _NET_WM_STATE_MAXIMIZED_HORZ
 _NET_WM_STATE_MAXIMIZED_VERT
 _NET_WM_STATE_SHADED
 _NET_WM_STATE_SKIP_PAGER
 _NET_WM_STATE_SKIP_TASKBAR
 _NET_WM_STATE_STICKY
 _NET_WM_STRUT
 _NET_WM_STRUT_PARTIAL
 _NET_WM_WINDOW_TYPE
 _NET_WM_WINDOW_TYPE_DESKTOP
 _NET_WM_WINDOW_TYPE_DIALOG
 _NET_WM_WINDOW_TYPE_DOCK
 _NET_WM_WINDOW_TYPE_NORMAL
 _NET_WM_WINDOW_TYPE_SPLASH
 _NET_WORKAREA

=item Fluxbox

 _NET_WM_CM_S0
 _XSETTINGS_S0
 _NET_SYSTEM_TRAY_S0
 _NET_DESKTOP_LAYOUT_S0 <- xde-panel

 _NET_ACTIVE_WINDOW
 _NET_CLIENT_LIST
 _NET_CLIENT_LIST_STACKING
 _NET_CLOSE_WINDOW
 _NET_CURRENT_DESKTOP
 _NET_DESKTOP_GEOMETRY
 _NET_DESKTOP_NAMES
 _NET_DESKTOP_VIEWPORT
 _NET_FRAME_EXTENTS
 _NET_MOVERESIZE_WINDOW
 _NET_NUMBER_OF_DESKTOPS
 _NET_REQUEST_FRAME_EXTENTS
 _NET_RESTACK_WINDOW
 _NET_SUPPORTING_WM_CHECK
 _NET_WM_ACTION_CHANGE_DESKTOP
 _NET_WM_ACTION_CLOSE
 _NET_WM_ACTION_FULLSCREEN
 _NET_WM_ACTION_MAXIMIZE_HORZ
 _NET_WM_ACTION_MAXIMIZE_VERT
 _NET_WM_ACTION_MINIMIZE
 _NET_WM_ACTION_MOVE
 _NET_WM_ACTION_RESIZE
 _NET_WM_ACTION_SHADE
 _NET_WM_ACTION_STICK
 _NET_WM_ALLOWED_ACTIONS
 _NET_WM_DESKTOP
 _NET_WM_ICON
 _NET_WM_ICON_NAME
 _NET_WM_MOVERESIZE
 _NET_WM_NAME
 _NET_WM_STATE
 _NET_WM_STATE_ABOVE
 _NET_WM_STATE_BELOW
 _NET_WM_STATE_DEMANDS_ATTENTION
 _NET_WM_STATE_FULLSCREEN
 _NET_WM_STATE_HIDDEN
 _NET_WM_STATE_MAXIMIZED_HORZ
 _NET_WM_STATE_MAXIMIZED_VERT
 _NET_WM_STATE_MODAL
 _NET_WM_STATE_SHADED
 _NET_WM_STATE_SKIP_TASKBAR
 _NET_WM_STATE_STICKY
 _NET_WM_STRUT
 _NET_WM_WINDOW_TYPE
 _NET_WM_WINDOW_TYPE_DESKTOP
 _NET_WM_WINDOW_TYPE_DIALOG
 _NET_WM_WINDOW_TYPE_DOCK
 _NET_WM_WINDOW_TYPE_MENU
 _NET_WM_WINDOW_TYPE_NORMAL
 _NET_WM_WINDOW_TYPE_SPLASH
 _NET_WM_WINDOW_TYPE_TOOLBAR
 _NET_WORKAREA

 _FLUXBOX_ACTION
 _FLUXBOX_ACTION_RESULT
 _FLUXBOX_GROUP_LEFT
 _BLACKBOX_PID  <-- funny
 _BLACKBOX_ATTRIBUTES

=item PeKWM

 _NET_WM_CM_S0
 _XSETTINGS_S0
 WM_S0
 _NET_SYSTEM_TRAY_S0
 _NET_DESKTOP_LAYOUT_S0

 _NET_ACTIVE_WINDOW
 _NET_CLIENT_LIST
 _NET_CLIENT_LIST_STACKING
 _NET_CLOSE_WINDOW
 _NET_CURRENT_DESKTOP
 _NET_DESKTOP_GEOMETRY
 _NET_DESKTOP_LAYOUT
 _NET_DESKTOP_NAMES
 _NET_DESKTOP_VIEWPORT
 _NET_NUMBER_OF_DESKTOPS
 _NET_SUPPORTED
 _NET_SUPPORTING_WM_CHECK
 _NET_WM_ACTION_CHANGE_DESKTOP
 _NET_WM_ACTION_CLOSE
 _NET_WM_ACTION_FULLSCREEN
 _NET_WM_ACTION_MAXIMIZE_HORZ
 _NET_WM_ACTION_MAXIMIZE_VERT
 _NET_WM_ACTION_MINIMIZE
 _NET_WM_ACTION_MOVE
 _NET_WM_ACTION_RESIZE
 _NET_WM_ACTION_SHADE
 _NET_WM_ACTION_STICK
 _NET_WM_ALLOWED_ACTIONS
 _NET_WM_DESKTOP
 _NET_WM_ICON
 _NET_WM_ICON_NAME
 _NET_WM_NAME
 _NET_WM_PID
 _NET_WM_STATE
 _NET_WM_STATE_ABOVE
 _NET_WM_STATE_BELOW
 _NET_WM_STATE_DEMANDS_ATTENTION
 _NET_WM_STATE_FULLSCREEN
 _NET_WM_STATE_HIDDEN
 _NET_WM_STATE_MAXIMIZED_HORZ
 _NET_WM_STATE_MAXIMIZED_VERT
 _NET_WM_STATE_MODAL
 _NET_WM_STATE_SHADED
 _NET_WM_STATE_SKIP_PAGER
 _NET_WM_STATE_SKIP_TASKBAR
 _NET_WM_STATE_STICKY
 _NET_WM_STRUT
 _NET_WM_VISIBLE_ICON_NAME
 _NET_WM_VISIBLE_NAME
 _NET_WM_WINDOW_OPACITY
 _NET_WM_WINDOW_TYPE
 _NET_WM_WINDOW_TYPE_DESKTOP
 _NET_WM_WINDOW_TYPE_DIALOG
 _NET_WM_WINDOW_TYPE_DOCK
 _NET_WM_WINDOW_TYPE_MENU
 _NET_WM_WINDOW_TYPE_NORMAL
 _NET_WM_WINDOW_TYPE_SPLASH
 _NET_WM_WINDOW_TYPE_TOOLBAR
 _NET_WM_WINDOW_TYPE_UTILITY
 _NET_WORKAREA
 UTF8_STRING

 _PEKWM_FRAME_ID
 _PEKWM_FRAME_ORDER
 _PEKWM_FRAME_ACTIVE
 _PEKWM_FRAME_DECOR
 _PEKWM_FRAME_SKIP
 _PEKWM_TITLE
 
=item IceWM

 _NET_WM_CM_S0
 _XSETTINGS_S0
 _NET_SYSTEM_TRAY_S0
 _ICEWM_INTTRAY_S0
 WM_S0

 _ICEWM_TRAY
 _NET_ACTIVE_WINDOW
 _NET_CLIENT_LIST
 _NET_CLIENT_LIST_STACKING
 _NET_CLOSE_WINDOW
 _NET_CURRENT_DESKTOP
 _NET_NUMBER_OF_DESKTOPS
 _NET_SUPPORTED
 _NET_SUPPORTING_WM_CHECK
 _NET_WM_DESKTOP
 _NET_WM_STATE
 _NET_WM_STATE_ABOVE
 _NET_WM_STATE_BELOW
 _NET_WM_STATE_FULLSCREEN
 _NET_WM_STATE_MAXIMIZED_HORZ
 _NET_WM_STATE_MAXIMIZED_VERT
 _NET_WM_STATE_SHADED
 _NET_WM_STATE_SKIP_TASKBAR
 _NET_WM_STRUT
 _NET_WM_WINDOW_TYPE_DESKTOP
 _NET_WM_WINDOW_TYPE_DOCK
 _NET_WM_WINDOW_TYPE_SPLASH
 _WIN_CLIENT_LIST
 _WIN_HINTS
 _WIN_ICONS
 _WIN_LAYER
 _WIN_STATE
 _WIN_SUPPORTING_WM_CHECK
 _WIN_WORKAREA
 _WIN_WORKSPACE
 _WIN_WORKSPACE_COUNT
 _WIN_WORKSPACE_NAMES

 _ICEWM_ACTION
 _ICEWM_TRAY
 _ICEWMBG_QUIT
 _ICEWMBG_RESTART
 _ICEWM_INTTRAY_S0
 _ICEWM_WINOPTHINT
 ICEWM_FONT_PATH

 _WIN_AREA
 _WIN_AREA_COUNT
 _WIN_CLIENT_LIST
 _WIN_DESKTOP_BUTTON_PROXY
 _WIN_HINTS
 _WIN_ICONS
 _WIN_LAYER
 _WIN_PROTOCOLS
 _WIN_STATE
 _WIN_SUPPORTING_WM_CHECK
 _WIN_WORKAREA
 _WIN_WORKSPACE
 _WIN_WORKSPACE_COUNT
 _WIN_WORKSPACE_NAMES

=item Blackbox

 _NET_WM_CM_S0
 _XSETTINGS_S0
 _NET_SYSTEM_TRAY_S0 <- xde-panel
 _NET_DESKTOP_LAYOUT_S0 <- xde-panel

 _NET_ACTIVE_WINDOW
 _NET_CLIENT_LIST
 _NET_CLIENT_LIST_STACKING
 _NET_CLOSE_WINDOW
 _NET_CURRENT_DESKTOP
 _NET_DESKTOP_NAMES
 _NET_MOVERESIZE_WINDOW
 _NET_NUMBER_OF_DESKTOPS
 _NET_WM_ACTION_CHANGE_DESKTOP
 _NET_WM_ACTION_CLOSE
 _NET_WM_ACTION_FULLSCREEN
 _NET_WM_ACTION_MAXIMIZE_HORZ
 _NET_WM_ACTION_MAXIMIZE_VERT
 _NET_WM_ACTION_MINIMIZE
 _NET_WM_ACTION_MOVE
 _NET_WM_ACTION_RESIZE
 _NET_WM_ACTION_SHADE
 _NET_WM_ALLOWED_ACTIONS
 _NET_WM_DESKTOP
 _NET_WM_ICON_NAME
 _NET_WM_NAME
 _NET_WM_STATE
 _NET_WM_STATE_ABOVE
 _NET_WM_STATE_BELOW
 _NET_WM_STATE_FULLSCREEN
 _NET_WM_STATE_HIDDEN
 _NET_WM_STATE_MAXIMIZED_HORZ
 _NET_WM_STATE_MAXIMIZED_VERT
 _NET_WM_STATE_MODAL
 _NET_WM_STATE_SHADED
 _NET_WM_STATE_SKIP_PAGER
 _NET_WM_STATE_SKIP_TASKBAR
 _NET_WM_STRUT
 _NET_WM_VISIBLE_ICON_NAME
 _NET_WM_VISIBLE_NAME
 _NET_WM_WINDOW_TYPE
 _NET_WM_WINDOW_TYPE_DESKTOP
 _NET_WM_WINDOW_TYPE_DIALOG
 _NET_WM_WINDOW_TYPE_DOCK
 _NET_WM_WINDOW_TYPE_MENU
 _NET_WM_WINDOW_TYPE_NORMAL
 _NET_WM_WINDOW_TYPE_SPLASH
 _NET_WM_WINDOW_TYPE_TOOLBAR
 _NET_WM_WINDOW_TYPE_UTILITY
 _NET_WORKAREA

 _BB_THEME <- am I setting this?
 _BLACKBOX_HINTS
 _BLACKBOX_ATTRIBUTES
 _BLACKBOX_CHANGE_ATTRIBUTES

=item WindowMaker

 _NET_WM_CM_S0
 _XSETTINGS_S0
 _NET_SYSTEM_TRAY_S0 <- xde-panel
 _NET_DESKTOP_LAYOUT_S0 <- xde-panel

 _NET_ACTIVE_WINDOW
 _NET_CLIENT_LIST
 _NET_CLIENT_LIST_STACKING
 _NET_CURRENT_DESKTOP
 _NET_DESKTOP_GEOMETRY
 _NET_DESKTOP_NAMES
 _NET_DESKTOP_VIEWPORT
 _NET_FRAME_EXTENTS
 _NET_NUMBER_OF_DESKTOPS
 _NET_SHOWING_DESKTOP
 _NET_SUPPORTING_WM_CHECK
 _NET_WM_ACTION_CHANGE_DESKTOP
 _NET_WM_ACTION_CLOSE
 _NET_WM_ACTION_FULLSCREEN
 _NET_WM_ACTION_MAXIMIZE_HORZ
 _NET_WM_ACTION_MAXIMIZE_VERT
 _NET_WM_ACTION_MINIMIZE
 _NET_WM_ACTION_MOVE
 _NET_WM_ACTION_RESIZE
 _NET_WM_ACTION_SHADE
 _NET_WM_ACTION_STICK
 _NET_WM_ALLOWED_ACTIONS
 _NET_WM_DESKTOP
 _NET_WM_HANDLED_ICONS
 _NET_WM_ICON
 _NET_WM_ICON_GEOMETRY
 _NET_WM_ICON_NAME
 _NET_WM_NAME
 _NET_WM_STATE
 _NET_WM_STATE_ABOVE
 _NET_WM_STATE_BELOW
 _NET_WM_STATE_FULLSCREEN
 _NET_WM_STATE_HIDDEN
 _NET_WM_STATE_MAXIMIZED_HORZ
 _NET_WM_STATE_MAXIMIZED_VERT
 _NET_WM_STATE_SHADED
 _NET_WM_STATE_SKIP_PAGER
 _NET_WM_STATE_SKIP_TASKBAR
 _NET_WM_STATE_STICKY
 _NET_WM_STRUT
 _NET_WM_WINDOW_TYPE
 _NET_WM_WINDOW_TYPE_DESKTOP
 _NET_WM_WINDOW_TYPE_DIALOG
 _NET_WM_WINDOW_TYPE_DOCK
 _NET_WM_WINDOW_TYPE_MENU
 _NET_WM_WINDOW_TYPE_NORMAL
 _NET_WM_WINDOW_TYPE_SPLASH
 _NET_WM_WINDOW_TYPE_TOOLBAR
 _NET_WM_WINDOW_TYPE_UTILITY

 _WINDOWMAKER_MENU
 _WINDOWMAKER_STATE
 _WINDOWMAKER_WM_PROTOCOLS
 _WINDOWMAKER_WM_FUNCTION
 _WINDOWMAKER_NOTICEBOARD
 _WINDOWMAKER_COMMAND
 _WINDOWMAKER_ICON_SIZE
 _WINDOWMAKER_ICON_TILE
 _GNUSTEP_WM_ATTR
 _GNUSTEP_WM_MINIATURIZE_WINDOW
 _GNUSTEP_TITLEBAR_STATE
 _GNUSTEP_WM_FUNCTION

=item Openbox

 _NET_WM_CM_S0
 _XSETTINGS_S0
 WM_S0
 _NET_SYSTEM_TRAY_S0
 _NET_DESKTOP_LAYOUT_S0

 _KDE_NET_WM_FRAME_STRUT
 _KDE_NET_WM_WINDOW_TYPE_OVERRIDE
 _KDE_WM_CHANGE_STATE
 _NET_ACTIVE_WINDOW
 _NET_CLIENT_LIST
 _NET_CLIENT_LIST_STACKING
 _NET_CLOSE_WINDOW
 _NET_CURRENT_DESKTOP
 _NET_DESKTOP_GEOMETRY
 _NET_DESKTOP_LAYOUT
 _NET_DESKTOP_NAMES
 _NET_DESKTOP_VIEWPORT
 _NET_FRAME_EXTENTS
 _NET_MOVERESIZE_WINDOW
 _NET_NUMBER_OF_DESKTOPS
 _NET_REQUEST_FRAME_EXTENTS
 _NET_RESTACK_WINDOW
 _NET_SHOWING_DESKTOP
 _NET_STARTUP_ID
 _NET_SUPPORTING_WM_CHECK
 _NET_WM_ACTION_ABOVE
 _NET_WM_ACTION_BELOW
 _NET_WM_ACTION_CHANGE_DESKTOP
 _NET_WM_ACTION_CLOSE
 _NET_WM_ACTION_FULLSCREEN
 _NET_WM_ACTION_MAXIMIZE_HORZ
 _NET_WM_ACTION_MAXIMIZE_VERT
 _NET_WM_ACTION_MINIMIZE
 _NET_WM_ACTION_MOVE
 _NET_WM_ACTION_RESIZE
 _NET_WM_ACTION_SHADE
 _NET_WM_ALLOWED_ACTIONS
 _NET_WM_DESKTOP
 _NET_WM_FULL_PLACEMENT
 _NET_WM_ICON
 _NET_WM_ICON_GEOMETRY
 _NET_WM_ICON_NAME
 _NET_WM_MOVERESIZE
 _NET_WM_NAME
 _NET_WM_PID
 _NET_WM_PING
 _NET_WM_STATE
 _NET_WM_STATE_ABOVE
 _NET_WM_STATE_BELOW
 _NET_WM_STATE_DEMANDS_ATTENTION
 _NET_WM_STATE_FULLSCREEN
 _NET_WM_STATE_HIDDEN
 _NET_WM_STATE_MAXIMIZED_HORZ
 _NET_WM_STATE_MAXIMIZED_VERT
 _NET_WM_STATE_MODAL
 _NET_WM_STATE_SHADED
 _NET_WM_STATE_SKIP_PAGER
 _NET_WM_STATE_SKIP_TASKBAR
 _NET_WM_STRUT
 _NET_WM_STRUT_PARTIAL
 _NET_WM_SYNC_REQUEST
 _NET_WM_SYNC_REQUEST_COUNTER
 _NET_WM_USER_TIME
 _NET_WM_VISIBLE_ICON_NAME
 _NET_WM_VISIBLE_NAME
 _NET_WM_WINDOW_TYPE
 _NET_WM_WINDOW_TYPE_DESKTOP
 _NET_WM_WINDOW_TYPE_DIALOG
 _NET_WM_WINDOW_TYPE_DOCK
 _NET_WM_WINDOW_TYPE_MENU
 _NET_WM_WINDOW_TYPE_NORMAL
 _NET_WM_WINDOW_TYPE_SPLASH
 _NET_WM_WINDOW_TYPE_TOOLBAR
 _NET_WM_WINDOW_TYPE_UTILITY
 _NET_WORKAREA
 _OB_APP_CLASS
 _OB_APP_NAME
 _OB_APP_ROLE
 _OB_APP_TITLE
 _OB_APP_TYPE
 _OB_CONFIG_FILE
 _OB_CONTROL
 _OB_THEME
 _OB_VERSION
 _OB_WM_ACTION_UNDECORATE
 _OB_WM_STATE_UNDECORATED
 _OPENBOX_PID

=item FVWM

 WM_S0
 _NET_WM_CM_S0
 _XSETTINGS_S0

 _KDE_NET_SYSTEM_TRAY_WINDOWS
 _KDE_NET_WM_FRAME_STRUT
 _KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR
 _NET_ACTIVE_WINDOW
 _NET_CLIENT_LIST
 _NET_CLIENT_LIST_STACKING
 _NET_CLOSE_WINDOW
 _NET_CURRENT_DESKTOP
 _NET_DESKTOP_GEOMETRY
 _NET_DESKTOP_NAMES
 _NET_DESKTOP_VIEWPORT
 _NET_FRAME_EXTENTS
 _NET_MOVERESIZE_WINDOW
 _NET_NUMBER_OF_DESKTOPS
 _NET_RESTACK_WINDOW
 _NET_SUPPORTED
 _NET_SUPPORTING_WM_CHECK
 _NET_VIRTUAL_ROOTS
 _NET_WM_ACTION_CHANGE_DESKTOP
 _NET_WM_ACTION_CLOSE
 _NET_WM_ACTION_FULLSCREEN
 _NET_WM_ACTION_MAXIMIZE_HORZ
 _NET_WM_ACTION_MAXIMIZE_VERT
 _NET_WM_ACTION_MINIMIZE
 _NET_WM_ACTION_MOVE
 _NET_WM_ACTION_RESIZE
 _NET_WM_ACTION_SHADE
 _NET_WM_ACTION_STICK
 _NET_WM_ALLOWED_ACTIONS
 _NET_WM_DESKTOP
 _NET_WM_HANDLED_ICON
 _NET_WM_ICON
 _NET_WM_ICON_GEOMETRY
 _NET_WM_ICON_NAME
 _NET_WM_ICON_VISIBLE_NAME
 _NET_WM_MOVERESIZE
 _NET_WM_NAME
 _NET_WM_PID
 _NET_WM_STATE
 _NET_WM_STATE_ABOVE
 _NET_WM_STATE_BELOW
 _NET_WM_STATE_FULLSCREEN
 _NET_WM_STATE_HIDDEN
 _NET_WM_STATE_MAXIMIZED_HORIZ
 _NET_WM_STATE_MAXIMIZED_HORZ
 _NET_WM_STATE_MAXIMIZED_VERT
 _NET_WM_STATE_MODAL
 _NET_WM_STATE_SHADED
 _NET_WM_STATE_SKIP_PAGER
 _NET_WM_STATE_SKIP_TASKBAR
 _NET_WM_STATE_STAYS_ON_TOP
 _NET_WM_STATE_STICKY
 _NET_WM_STRUT
 _NET_WM_VISIBLE_NAME
 _NET_WM_WINDOW_TYPE
 _NET_WM_WINDOW_TYPE_DESKTOP
 _NET_WM_WINDOW_TYPE_DIALOG
 _NET_WM_WINDOW_TYPE_DOCK
 _NET_WM_WINDOW_TYPE_MENU
 _NET_WM_WINDOW_TYPE_NORMAL
 _NET_WM_WINDOW_TYPE_NOTIFICATION
 _NET_WM_WINDOW_TYPE_TOOLBAR
 _NET_WORKAREA

 _WIN_AREA
 _WIN_AREA_COUNT
 _WIN_CLIENT_LIST
 _WIN_DESKTOP_BUTTON_PROXY
 _WIN_HINTS
 _WIN_LAYER
 _WIN_PROTOCOLS
 _WIN_STATE
 _WIN_SUPPORTING_WM_CHECK
 _WIN_WORKSPACE
 _WIN_WORKSPACE_COUNT
 _WIN_WORKSPACE_NAMES


=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

1;

# vim: sw=4 tw=72



