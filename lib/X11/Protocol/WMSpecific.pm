package X11::Protocol::WMSpecific;
use X11::Protocol::Util  qw(:all);
use X11::Protocol::ICCCM qw(:all);
use X11::Protocol::WMH   qw(:all);
use X11::Protocol::EWMH  qw(:all);
use X11::Protocol;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

=head1 NAME

X11::Protocol::WMSpecific -- window manager specific things

=head1 SYNOPSIS

 package X11::Protocol::My;
 use base qw(X11::Protocol::WMSpecific X11::Protocol);

 package main;

 my $wm = X11::Protocol::My->new();

 my $pid = $wm->get_BLACKBOX_PID;

=head1 DESCRIPTION

Provides a module with methods that can be used to interrogate window
manager specific properties and issue or receive window manager specific
client messages.

=head1 METHODS

The following methods are provided by this module:

=over

=item $wm = X11::Protocol::WMSpecific->B<new>(I<$X>)

Creates a new instance of an X11::Protocol::WMSpecific object.  When the
passed argument, I<$X>, is C<undef>, a new X11::Protocol object will be
created.  Otherwise, if an X11::Protocol object is passed, it will be
initialized and blessed as an X11::Protocol::WMSpecific object.

=cut

sub new {
    my($type,$X) = @_;
    $X = X11::Protocol->new() unless $X and ref($X) and
	$X->isa('X11::Protocol');
    bless $X, $type;
    return $X;
}

=back

=head2 General

=cut

$EXPORT_TAGS{common} = [qw(
    wm_check
)];

=over

=item B<wm_check>(I<$X>,I<$screen>) => I<$boolean>

Checks for a running window manager and attempts to determine the window
manager, its process identifier, and the host on which the window
manager is running.

=cut

my %TEST_WINDOWS = (
	[ 'pager',  'Mwm',  'Mwm Pager',    'mwm' ],
	[ 'mwm',    'Mwm',  'mwm',	    'mwm' ],
);

sub wm_check {
    my($X,$screen) = @_;
    my $result = 0;
    if (defined $screen) {
	my ($check,$name,$pid,$host,$maybe) = (0,'',0,'','');
	my @totest = ();
	return 0 unless $X->{screens}[$screen];
	$X->choose_screen($screen);
	my %seen = ();
	# perform ICCCM checks
	$check = get_NET_SUPPORTING_WM_CHECK($X);
	$check = get_NET_SUPPORTING_WM_CHECK($X) unless $check;
	if ($check) {
	    unless ($seen{$check}) {
		push @totest,$check;
		$seen{$check} = 1;
	    }
	    $X->{screens}[$screen]{wm}{net}{check} = $check;
	    printf STDERR "Window Manager NetWM check window 0x%08x\n", $check;
	} else {
	    delete $X->{screens}[$screen]{wm}{net}{check};
	    warn "Window Manager does not support NetWM/EWMH";
	}
	$check = get_WIN_SUPPORTING_WM_CHECK($X);
	$check = get_WIN_SUPPORTING_WM_CHECK($X) unless $check;
	if ($check) {
	    unless ($seen{$check}) {
		push @totest,$check;
		$seen{$check} = 1;
	    }
	    $X->{screens}[$screen]{wm}{win}{check} = $check;
	    printf STDERR "Window Manager Gnome check window 0x%08x\n", $check;
	} else {
	    delete $X->{screens}[$screen]{wm}{win}{check};
	    warn "Window Manager does not support Gnome/WMH";
	}
	$check = get_WINDOWMAKER_NOTICEBOARD($X);
	$check = get_WINDOWMAKER_NOTICEBOARD($X) unless $check;
	if ($check) {
	    unless ($seen{$check}) {
		push @totest,$check;
		$seen{$check} = 1;
	    }
	    $maybe = 'wmaker';
	    $X->{screens}[$screen]{wm}{noticeboard} = $check;
	    printf STDERR "Window Manager wmaker notice window 0x%08x\n", $check;
	} else {
	    delete $X->{screens}[$screen]{wm}{noticeboard};
	    warn "Window Manager does not support WindowMaker";
	}
	$check = get_MOTIF_WM_INFO($X);
	$check = get_MOTIF_WM_INFO($X) unless $check;
	$check = $check->{wm_window} if $check;
	if ($check) {
	    unless ($seen{$check}) {
		push @totest,$check;
		$seen{$check} = 1;
	    }
	    $maybe = 'mwm';
	    $X->{screens}[$screen]{wm}{mwm}{check} = $check;
	    printf STDERR "Window Manager Motif check window 0x%08x\n", $check;
	} else {
	    delete $X->{screens}[$screen]{wm}{mwm}{check};
	    warn "Window Manager does not support Motif/MWMH";
	}
	my $sel = sprintf("WM_S%d",$screen);
	my $selection = $X->atom($sel);
	$check = $X->GetSelectionOwner($selection);
	$check = $X->GetSelectionOwner($selection) unless $check and $check ne 'None';
	if ($check and $check ne 'None') {
	    unless ($seen{$check}) {
		push @totest,$check;
		$seen{$check} = 1;
	    }
	    $X->{screens}[$screen]{wm}{owner} = $check;
	    printf STDERR "Window Manager ICCCM 2.0 %s owner 0x%08x\n", $sel, $check;
	} else {
	    delete $X->{screens}[$screen]{wm}{owner};
	    warn "Window Manager does not support ICCCM 2.0 $sel";
	}
	my %attrs = $X->GetWindowAttributes($X->root);
	my @events = $X->unpack_event_mask($attrs{all_event_masks});
	if (grep /SubstructureRedirect/, @events) {
	    printf STDERR "Window Manager present (SubstructureRedirect).\n";
	} else {
	    warn "Window Manager not present (!SubstructureRedirect)";
	}
	push @totest, $X->root;
#
# Note that pekwm and openbox are settting a null WM_CLASS porperty on
# the check window.  fvwm is setting WM_NAME and WM_CLASS properly on
# the check window.  Recent jwm, blackbox and icewm are properly setting
# _NET_WM_NAME and WM_CLASS on the check window.
#
	foreach $check (@totest) {
	    $name = get_NET_WM_NAME($X,$check) unless $name;
	    $name = getWM_NAME($X,$check) unless $name;
	    unless ($name) {
		if (my $class = getWM_CLASS($X,$check)) {
		    $name = $check->[0];
		}
	    }
	    unless ($name) {
		if (my $command = getWM_COMMAND($X,$check)) {
		    $name = $command->[0];
		}
	    }
	    unless ($name) {
		if (my $command = getWM_COMMAND($X,$X->root)) {
		    $name = $command->[0];
		}
	    }
	    $name = get_NET_WM_ICON_NAME($X,$check) unless $name;
	    $name = getWM_ICON_NAME($X,$check) unless $name;
	    last if $name;
	}
	if ($name) {
	    ($name) = split(/\s+/,$name,2);
	    $name =~ s{^.*/}{};
	    $name ="\L$name\E";
	}
#
# CTWM with the old GNOME support uses the work space manager window as
# a check window.  Newer CTWM is fully Net/EWMH compliant.
#
	$name = $maybe unless $name;
	$name = "ctwm" if $name and $name eq 'workspacemanager';
#
# When there is no name found with these approaches, we need to go look
# for windows to check.
#
	unless ($name) {
	}
	foreach $check (@totest) {
#
# Note that fluxbox is setting _BLACKBOX_PID on the root window instead.
# PeKWM is setting _NET_WM_PID, but on the root window instead.  IceWM
# sets it correctly on the check window.  Openbox sets _OPENBOX_PID on
# the root window.
#
	    $pid = get_NET_WM_PID($X,$check) unless $pid
		or ($name ne 'pekwm' and $check == $X->root);
	    $pid = get_BLACKBOX_PID($X,$check) unless $pid
		or ($name ne 'fluxbox' or $check != $X->root);
	    $pid = get_OPENBOX_PID($X,$check) unless $pid
		or ($name ne 'openbox' or $check != $X->root);

	    last if $pid;
	}
	foreach $check (@totest) {
	    $host = getWM_CLIENT_MACHINE($X,$check) unless $host;
	    last if $host;
	}
	if ($name) {
	    $X->{screens}[$screen]{wm}{name} = $name;
	    print STDERR "Window Manager name is $name\n";
	} else {
	    delete $X->{screens}[$screen]{wm}{name};
	    warn "Window Manager name is unknown";
	}
	if ($pid) {
	    $X->{screens}[$screen]{wm}{name} = $pid;
	    print STDERR "Window Manager pid  is $pid\n";
	} else {
	    delete $X->{screens}[$screen]{wm}{name};
	    warn "Window Manager pid  is unknown";
	}
	if ($host) {
	    $X->{screens}[$screen]{wm}{name} = $host;
	    print STDERR "Window Manager host is $host\n";
	} else {
	    delete $X->{screens}[$screen]{wm}{name};
	    warn "Window Manager host is unknown";
	}
    } else {
	for ($screen=@{$X->{screens}};$screen>=0;$screen--) {
	    $result |= wm_check($X,$screen);
	}
    }
    return $result;
}

=back

=head3 _XROOTPMAP_ID

=over

=item B<get_XROOTPMAP_ID>(I<$X>,I<$root>) => I<$pixmap>

=cut

sub get_XROOTPMAP_ID {
    return getWMRootPropertyUint($_[0],_XROOTPMAP_ID=>$_[1]);
}

=item B<set_XROOTPMAP_ID>(I<$X>,I<$pixmap>)

=cut

sub set_XROOTPMAP_ID {
    return setWMRootPropertyUint($_[0],_XROOTPMAP_ID=>PIXMAP=>$_[1]);
}

=item B<dmp_XROOTPMAP_ID>(I<$X>,I<$pixmap>)

=cut

sub dmp_XROOTPMAP_ID {
    return dmpWMRootPropertyUint($_[0],_XROOTPMAP_ID=>pixmap=>$_[1]);
}

=back

=head3 ESETROOT_PMAP_ID

=over

=item B<getESETROOT_PMAP_ID>(I<$X>,I<$root>) => I<$pixmap>

=cut

sub getESETROOT_PMAP_ID {
    return getWMRootPropertyUint($_[0],ESETROOT_PMAP_ID=>$_[1]);
}

=item B<setESETROOT_PMAP_ID>(I<$X>,I<$pixmap>)

=cut

sub setESETROOT_PMAP_ID {
    return setWMRootPropertyUint($_[0],ESETROOT_PMAP_ID=>PIXMAP=>$_[1]);
}

=item B<dmpESETROOT_PMAP_ID>(I<$X>,I<$pixmap>)

=cut

sub dmpESETROOT_PMAP_ID {
    return dmpWMRootPropertyUint($_[0],ESETROOT_PMAP_ID=>pixmap=>$_[1]);
}

=back

=head3 _XSETROOT_ID

=over

=item B<get_XSETROOT_ID>(I<$X>,I<$root>) => I<$pixmap>

=cut

sub get_XSETROOT_ID {
    return getWMRootPropertyUint($_[0],_XSETROOT_ID=>$_[1]);
}

=item B<set_XSETROOT_ID>(I<$X>,I<$pixmap>)

=cut

sub set_XSETROOT_ID {
    return setWMRootPropertyUint($_[0],_XSETROOT_ID=>PIXMAP=>$_[1]);
}

=item B<dmp_XSETROOT_ID>(I<$X>,I<$pixmap>)

=cut

sub dmp_XSETROOT_ID {
    return dmpWMRootPropertyUint($_[0],_XSETROOT_ID=>pixmap=>$_[1]);
}

=back

=head3 _DBUS_SESSION_BUS_PID, pid CARDINAL/32

=over

=item B<get_DBUS_SESSION_BUS_PID>(I<$X>,I<$window>) => I<$pid>

=cut

sub get_DBUS_SESSION_BUS_PID {
    return getWMPropertyUint(@_[0..1],_DBUS_SESSION_BUS_PID=>);
}

=item B<set_DBUS_SESSION_BUS_PID>(I<$X>,I<$window>,I<$pid>)

=cut

sub set_DBUS_SESSION_BUS_PID {
    return setWMPropertyUint(@_[0..1],_DBUS_SESSION_BUS_PID=>CARDINAL=>$_[2]);
}

=item B<dmp_DBUS_SESSION_BUS_PID>(I<$X>,I<$pid>)

=cut

sub dmp_DBUS_SESSION_BUS_PID {
    return dmpWMPropertyUint($_[0],_DBUS_SESSION_BUS_PID=>pid=>$_[1]);
}

=back

=head3 _DBUS_SESSION_BUS_ADDRESS, address STRING/8

=over

=item B<get_DBUS_SESSION_BUS_ADDRESS>(I<$X>,I<$window>) => I<$address>

=cut

sub get_DBUS_SESSION_BUS_ADDRESS {
    return getWMPropertyString(@_[0..1],_DBUS_SESSION_BUS_ADDRESS=>);
}

=item B<set_DBUS_SESSION_BUS_ADDRESS>(I<$X>,I<$window>,I<$address>)

=cut

sub set_DBUS_SESSION_BUS_ADDRESS {
    return setWMPropertyString(@_[0..1],_DBUS_SESSION_BUS_ADDRESS=>STRING=>$_[2]);
}

=item B<dmp_DBUS_SESSION_BUS_ADDRESS>(I<$X>,I<$address>)

=cut

sub dmp_DBUS_SESSION_BUS_ADDRESS {
    return dmpWMPropertyString($_[0],_DBUS_SESSION_BUS_ADDRESS=>address=>$_[1]);
}

=back

=head2 Fluxbox

Fluxbox is only ICCCM/EWMH compliant and is not WMH compliant.  It
properly sets C<_NET_SUPPORTIN_WM_CHECK> on both the root and the check
window.  On the check window, the only other thing that is sets is
C<_NET_WM_NAME> which is a proper C<UTF8_STRING> with the single word
C<Fluxbox>.

Fluxbox also sets C<_BLACKBOX_PID(CARDINAL/32)> on the root window.
(Gee, blackbox doesn't!)

Fluxbox interns the C<_BLACKBOX_ATTRIBUTES> atom and then does nothing
with it.  Fluxbox interns the C<_FLUXBOX_ACTION>,
C<_FLUXBOX_ACTION_RESULT> and C<_FLUXBOX_GROUP_LEFT> atoms.  Actions
are only possible when the C<session.session0.allowRemoteActions>
resource is set to true.  They are effected by changing the
C<_FLUXBOX_ACTION> property on the root window to reflect the new
command.  The result is communicated by Fluxbox setting the
C<_FLUXBOX_ACTION_RESULT> property on the root window with the result.

=cut

$EXPORT_TAGS{fluxbox} = [qw(
    get_BLACKBOX_PID
    set_BLACKBOX_PID
    dmp_BLACKBOX_PID
    get_FLUXBOX_ACTION
    set_FLUXBOX_ACTION
    dmp_FLUXBOX_ACTION
    get_FLUXBOX_GROUP_LEFT
    set_FLUXBOX_GROUP_LEFT
    dmp_FLUXBOX_GROUP_LEFT
)];

=head3 _BLACKBOX_ATTRIBUTES

May have been used at one time.  Now completely deprecated and unused by
L<fluxbox(1)>.

=head3 _BLACKBOX_PID

=over

=item B<get_BLACKBOX_PID>(I<$X>,I<$root>) => I<$pid> or undef

=cut

sub get_BLACKBOX_PID {
    return getWMRootPropertyUint($_[0],_BLACKBOX_PID=>$_[1]);
}

=item B<set_BLACKBOX_PID>(I<$X>,I<$pid>)

=cut

sub set_BLACKBOX_PID {
    return setWMRootPropertyUint($_[0],_BLACKBOX_PID=>CARDINAL=>$_[1]);
}

=item B<dmp_BLACKBOX_PID>(I<$X>,I<$pid>)

=cut

sub dmp_BLACKBOX_PID {
    return dmpWMRootPropertyUint($_[0],_BLACKBOX_PID=>pid=>$_[1]);
}

=back

=head3 _FLUXBOX_ACTION, command STRING/8

Defines a root window property used to request remote control of the
L<fluxbox(1)> window manager.  The L<fluxbox(1)> remote feature must be
enabled in the F<init> file, otherwise, the window manager will ignore
changes to this property.

=over

=item B<get_FLUXBOX_ACTION>(I<$X>,I<$root>) => I<$command>

=cut

sub get_FLUXBOX_ACTION {
    return getWMRootPropertyString($_[0],_FLUXBOX_ACTION=>$_[1]);
}

=item B<set_FLUXBOX_ACTION>(I<$X>,I<$command>)

=cut

sub set_FLUXBOX_ACTION {
    return setWMRootPropertyString($_[0],_FLUXBOX_ACTION=>STRING=>$_[1]);
}

=item B<dmp_FLUXBOX_ACTION>(I<$X>,I<$command>)

=cut

sub dmp_FLUXBOX_ACTION {
    return dmpWMRootPropertyString($_[0],_FLUXBOX_ACTION=>command=>$_[1]);
}

=back

=head3 _FLUXBOX_ACTION_RESULT, response STRING/8

Defines a root window property used to by L<fluxbox(1)> to respond to
remote control.  When configured to respond to remote commands,
L<fluxbox(1)> will set this property in response to a change to the
C<_FLUXBOX_ACTION> property after the action has been performed or
rejected.

=head3 _FLUXBOX_GROUP_LEFT

=over

=item B<get_FLUXBOX_GROUP_LEFT>(I<$X>,I<$window>) => I<$group> or undef

=cut

sub get_FLUXBOX_GROUP_LEFT {
    return getWMPropertyUint(@_[0..1],_FLUXBOX_GROUP_LEFT=>);
}

=item B<set_FLUXBOX_GROUP_LEFT>(I<$X>,I<$window>,I<$group>)

=cut

sub set_FLUXBOX_GROUP_LEFT {
    return setWMPropertyUint(@_[0..1],_FLUXBOX_GROUP_LEFT=>WINDOW=>$_[2]);
}

=item B<dmp_FLUXBOX_GROUP_LEFT>(I<$X>,I<$group>)

=cut

sub dmp_FLUXBOX_GROUP_LEFT {
    return dmpWMPropertyUint($_[0],_FLUXBOX_GROUP_LEFT=>group=>$_[1]);
}

=back

=head2 Blackbox

Blackbox is only ICCCM/EWMH compliant and is not WMH compliant.  It
properly sets C<_NET_SUPPORTING_WM_CHECK> on both the root and the check
window.  On the check window the only other thing that is sets is
C<_NET_WM_NAME> whis is a property C<UTF8_STRING> with the single word
C<Blackbox>.  [It now sets C<_NET_WM_PID> correctly, but still does not
set C<WM_CLIENT_MACHINE> to the fully qualified domain name as required
by NetWM/EWMH specifications.

=cut

$EXPORT_TAGS{blackbox} = [qw(
)];

=head2 Openbox

Openbox is only ICCCM/EWMH compliant and is not WMH compliant.  It
properly ses C<_NET_SUPPORTING_WM_CHECK> on both the root and the check
window.  On the check window, the only ohter thing that it sets is
C<_NET_WM_NAME> which is a proper C<UTF8_STRING> with the single word
C<Openbox>.

Openbox also sets C<_OPENBOX_PID(CARDINAL/32)> on the root window.  It
also sets C<_OB_VERSION(UTF8_STRING)> and C<_OB_THEME(UTF8_STRING)> on
the root window: will changing the C<_OB_THEME> property actually change
the theme?

=cut

$EXPORT_TAGS{openbox} = [qw(
    OB_CONTROL_RECONFIGURE
    OB_CONTROL_RESTART
    OB_CONTROL_EXIT
    req_OB_CONTROL
    get_OB_CONFIG_FILE
    set_OB_CONFIG_FILE
    dmp_OB_CONFIG_FILE
    get_OB_THEME
    set_OB_THEME
    dmp_OB_THEME
    get_OB_VERSION
    set_OB_VERSION
    dmp_OB_VERSION
    get_OPENBOX_PID
    set_OPENBOX_PID
    dmp_OPENBOX_PID
    get_OB_APP_CLASS
    set_OB_APP_CLASS
    dmp_OB_APP_CLASS
    get_OB_APP_GROUP_CLASS
    set_OB_APP_GROUP_CLASS
    dmp_OB_APP_GROUP_CLASS
    get_OB_APP_GROUP_NAME
    set_OB_APP_GROUP_NAME
    dmp_OB_APP_GROUP_NAME
    get_OB_APP_NAME
    set_OB_APP_NAME
    dmp_OB_APP_NAME
    get_OB_APP_ROLE
    set_OB_APP_ROLE
    dmp_OB_APP_ROLE
    get_OB_APP_TITLE
    set_OB_APP_TITLE
    dmp_OB_APP_TITLE
    get_OB_APP_TYPE
    set_OB_APP_TYPE
    dmp_OB_APP_TYPE
)];

=head3 _OB_CONTROL

L<openbox(1)> provides for client message control; however, it does
require the feature to be enabled by cnofiguration.  L<openbox(1)> does,
however, provide control by sending signals and sets its PID in the
C<_OPENBOX_PID(CARDINAL/32)> property on the root window; (see
L</_OPENBOX_PID>).

The client message is as follows:

 target = root
 propagate = False
 event_mask = SustructureNotifyMask|SubstructureRedirectMask
 event_type = ClientMessage
 window = root
 type = _OB_CONTROL
 format = 32
 data.l[0] = command: Reconfigure(1), Restart(2), Exit(3)
 other data.l[] members = 0

The following constants are defined:

 'Reconfigure'	OB_CONTROL_RECONFIGURE	=> 1
 'Restart'	OB_CONTROL_RESTART	=> 2
 'Exit'		OB_CONTROL_EXIT		=> 3

=cut

use constant {
    OB_CONTROL_RECONFIGURE  => 1,
    OB_CONTROL_RESTART	    => 2,
    OB_CONTROL_EXIT	    => 3,

    ObControl=>[undef, qw(
	Reconfigure
	Restart
	Exit
    )],
};

=over

=item B<req_OB_CONTROL>(I<$X>,I<$command>)

I<$command> is an interpreted argument.  The following strings and
constants are defined for use with I<$command>:

 'Reconfigure'	OB_CONTROL_RECONFIGURE	=> 1
 'Restart'	OB_CONTROL_RESTART	=> 2
 'Exit'		OB_CONTROL_EXIT		=> 3

=cut

sub req_OB_CONTROL {
    my($X,$command) = @_;
    $command = 1 unless defined $command;
    $command = name2val(ObControl=>ObControl(),$command);
    NetClientMessage($X,0,_OB_CONTROL=>[$command]);
}

=back

=head3 _OB_CONFIG_FILE

=over

=item B<get_OB_CONFIG_FILE>(I<$X>,I<$root>) => I<$file> or undef

=cut

sub get_OB_CONFIG_FILE {
    return getWMRootPropertyString($_[0],_OB_CONFIG_FILE=>$_[1]);
}

sub dmp_OB_CONFIG_FILE {
    return dmpWMRootPropertyString($_[0],_OB_CONFIG_FILE=>file=>$_[1]);
}

=item B<set_OB_CONFIG_FILE>(I<$X>,I<$file>)

=cut

sub set_OB_CONFIG_FILE {
    return setWMRootPropertyString($_[0],_OB_CONFIG_FILE=>UTF8_STRING=>$_[1]);
}

=back

=head3 _OB_THEME

=over

=item B<get_OB_THEME>(I<$X>,I<$root>) => I<$theme> or undef

=cut

sub get_OB_THEME {
    return getWMRootPropertyString($_[0],_OB_THEME=>$_[1]);
}

sub dmp_OB_THEME {
    return dmpWMRootPropertyString($_[0],_OB_THEME=>theme=>$_[1]);
}

=item B<set_OB_THEME>(I<$X>,I<$theme>)

=cut

sub set_OB_THEME {
    return setWMRootPropertyString($_[0],_OB_THEME=>UTF8_STRING=>$_[1]);
}

=back

=head3 _OB_VERSION

=over

=item B<get_OB_VERSION>(I<$X>,I<$root>) => I<$version> or undef

=cut

sub get_OB_VERSION {
    return getWMRootPropertyString($_[0],_OB_VERSION=>$_[1]);
}

sub dmp_OB_VERSION {
    return dmpWMRootPropertyString($_[0],_OB_VERSION=>version=>$_[1]);
}

=item B<set_OB_VERSION>(I<$X>,I<$version>)

=cut

sub set_OB_VERSION {
    return setWMRootPropertyString($_[0],_OB_VERSION=>UTF8_STRING=>$_[1]);
}

=back

=head3 _OPENBOX_PID

=over

=item B<get_OPENBOX_PID>(I<$X>,I<$root>) => I<$pid> or undef

=cut

sub get_OPENBOX_PID {
    return getWMRootPropertyUint($_[0],_OPENBOX_PID=>$_[1]);
}

sub dmp_OPENBOX_PID {
    return dmpWMRootPropertyUint($_[0],_OPENBOX_PID=>pid=>$_[1]);
}

=item B<set_OPENBOX_PID>(I<$X>,I<$pid>)

=cut

sub set_OPENBOX_PID {
    return setWMRootPropertyUint($_[0],_OPENBOX_PID=>CARDINAL=>$_[1]);
}

=back

=head3 _OB_APP_CLASS

=over

=item B<get_OB_APP_CLASS>(I<$X>,I<$window>) => I<$class> or undef

=cut

sub get_OB_APP_CLASS {
    return getWMPropertyString(@_[0..1],_OB_APP_CLASS=>);
}

sub dmp_OB_APP_CLASS {
    return dmpWMPropertyString($_[0],_OB_APP_CLASS=>class=>$_[1]);
}

=item B<set_OB_APP_CLASS>(I<$X>,I<$window>,I<$class>)

=cut

sub set_OB_APP_CLASS {
    return setWMPropertyString(@_[0..1],_OB_APP_CLASS=>UTF8_STRING=>$_[2]);
}

=back

=head3 _OB_APP_GROUP_CLASS

=over

=item B<get_OB_APP_GROUP_CLASS>(I<$X>,I<$window>) => I<$class> or undef

=cut

sub get_OB_APP_GROUP_CLASS {
    return getWMPropertyString(@_[0..1],_OB_APP_GROUP_CLASS=>);
}

sub dmp_OB_APP_GROUP_CLASS {
    return dmpWMPropertyString($_[0],_OB_APP_GROUP_CLASS=>group_class=>$_[1]);
}

=item B<set_OB_APP_GROUP_CLASS>(I<$X>,I<$window>,I<$class>)

=cut

sub set_OB_APP_GROUP_CLASS {
    return setWMPropertyString(@_[0..1],_OB_APP_GROUP_CLASS=>UTF8_STRING=>$_[2]);
}

=back

=head3 _OB_APP_GROUP_NAME

=over

=item B<get_OB_APP_GROUP_NAME>(I<$X>,I<$window>) => I<$name> or undef

=cut

sub get_OB_APP_GROUP_NAME {
    return getWMPropertyString(@_[0..1],_OB_APP_GROUP_NAME=>);
}

sub dmp_OB_APP_GROUP_NAME {
    return dmpWMPropertyString($_[0],_OB_APP_GROUP_NAME=>group_name=>$_[1]);
}

=item B<set_OB_APP_GROUP_NAME>(I<$X>,I<$window>,I<$name>)

=cut

sub set_OB_APP_GROUP_NAME {
    return setWMPropertyString(@_[0..1],_OB_APP_GROUP_NAME=>UTF8_STRING=>$_[2]);
}

=back

=head3 _OB_APP_NAME

=over

=item B<get_OB_APP_NAME>(I<$X>,I<$window>) => I<$name> or undef

=cut

sub get_OB_APP_NAME {
    return getWMPropertyString(@_[0..1],_OB_APP_NAME=>);
}

sub dmp_OB_APP_NAME {
    return dmpWMPropertyString($_[0],_OB_APP_NAME=>name=>$_[1]);
}

=item B<set_OB_APP_NAME>(I<$X>,I<$window>,I<$name>)

=cut

sub set_OB_APP_NAME {
    return setWMPropertyString(@_[0..1],_OB_APP_NAME=>UTF8_STRING=>$_[2]);
}

=back

=head3 _OB_APP_ROLE

=over

=item B<get_OB_APP_ROLE>(I<$X>,I<$window>) => I<$role> or undef

=cut

sub get_OB_APP_ROLE {
    return getWMPropertyString(@_[0..1],_OB_APP_ROLE=>);
}

sub dmp_OB_APP_ROLE {
    return dmpWMPropertyString($_[0],_OB_APP_ROLE=>role=>$_[1]);
}

=item B<set_OB_APP_ROLE>(I<$X>,I<$window>,I<$role>)

=cut

sub set_OB_APP_ROLE {
    return setWMPropertyString(@_[0..1],_OB_APP_ROLE=>UTF8_STRING=>$_[2]);
}

=back

=head3 _OB_APP_TITLE

=over

=item B<get_OB_APP_TITLE>(I<$X>,I<$window>) => I<$title> or undef

=cut

sub get_OB_APP_TITLE {
    return getWMPropertyString(@_[0..1],_OB_APP_TITLE=>);
}

sub dmp_OB_APP_TITLE {
    return dmpWMPropertyString($_[0],_OB_APP_TITLE=>title=>$_[1]);
}

=item B<set_OB_APP_TITLE>(I<$X>,I<$window>,I<$title>)

=cut

sub set_OB_APP_TITLE {
    return setWMPropertyString(@_[0..1],_OB_APP_TITLE=>UTF8_STRING=>$_[2]);
}

=back

=head3 _OB_APP_TYPE

=over

=item B<get_OB_APP_TYPE>(I<$X>,I<$window>) => I<$type> or undef

=cut

sub get_OB_APP_TYPE {
    return getWMPropertyString(@_[0..1],_OB_APP_TYPE=>);
}

sub dmp_OB_APP_TYPE {
    return dmpWMPropertyString($_[0],_OB_APP_TYPE=>type=>$_[1]);
}

=item B<set_OB_APP_TYPE>(I<$X>,I<$window>,I<$type>)

=cut

sub set_OB_APP_TYPE {
    return setWMPropertyString(@_[0..1],_OB_APP_TYPE=>UTF8_STRING=>$_[2]);
}

=back

=head2 IceWM

Sets C<_NET_SUPPORTING_WM_CHECK> appropriately.  Note that it sets
C<_WIN_SUPPORTING_WM_CHECK> as well.  Also, it sets both
C<_NET_SUPPORTING_WM_CHECK> and C<_WIN_SUPPORTING_WM_CHECK> to the same
window.  It sets C<_NET_WM_NAME(STRING/8)> to C<IceWM 1.3.7 (Linux
3.4.0-1-ARCH/x86_64)> or some such.  Note that C<_NET_WM_NAME> should be
C<UTF8_STRING> instead of C<STRING> [this has been fixed].  It sets
C<_NET_WM_PID> to the pid of th window manager; however, it does not set
C<WM_CLIENT_MACHINE> to the fully qualified domain name of the window
manager machine as required by the NetWM/EWMH specification.

=cut

$EXPORT_TAGS{icewm} = [qw(
    ICEWM_ACTION_NOP
    ICEWM_ACTION_PING
    ICEWM_ACTION_LOGOUT
    ICEWM_ACTION_CANCEL_LOGOUT
    ICEWM_ACTION_REBOOT
    ICEWM_ACTION_SHUTDOWN
    ICEWM_ACTION_ABOUT
    ICEWM_ACTION_WINDOWLIST
    ICEWM_ACTION_RESTARTWM
    req_ICEWM_ACTION
    WIN_TRAY_IGNORE
    WIN_TRAY_MINIMIZED
    WIN_TRAY_EXCLUSIVE
    get_ICEWM_TRAY
    dmp_ICEWM_TRAY
    set_ICEWM_TRAY
    req_ICEWM_TRAY
    got_ICEWM_TRAY
)];

=head3 _ICEWM_ACTION

L<icewm(1)> provides for client message control; however, this is broken
(and ignored, on purpose?) by some versions of L<icewm(1)>.  It is fixed
in current versions.  L<icewm(1)> does provide for control by sending
singals and sets it PID in the C<_NET_WM_PID(CARDINAL/32)> property on
the check window.

The C<_ICEWM_ACTION> client message takes a single long argument.

=cut


use constant {
    ICEWM_ACTION_NOP		=> 0,
    ICEWM_ACTION_PING		=> 1,
    ICEWM_ACTION_LOGOUT		=> 2,
    ICEWM_ACTION_CANCEL_LOGOUT	=> 3,
    ICEWM_ACTION_REBOOT		=> 4,
    ICEWM_ACTION_SHUTDOWN	=> 5,
    ICEWM_ACTION_ABOUT		=> 6,
    ICEWM_ACTION_WINDOWLIST	=> 7,
    ICEWM_ACTION_RESTARTWM	=> 8,

    IceWMAction=>[qw(
	    Nop
	    Ping
	    Logout
	    CancelLogout
	    Reboot
	    Shutdown
	    About
	    WIndowlist
	    Restart
    )],
};

=over

=item B<req_ICEWM_ACTION>(I<$X>,I<$command>)

I<$command> is an interpreted argument.  It can have one of the
following string or numeric values:

 'Nop'          ICEWM_ACTION_NOP           => 0
 'Ping'         ICEWM_ACTION_PING          => 1
 'Logout'       ICEWM_ACTION_LOGOUT        => 2
 'CancelLogout' ICEWM_ACTION_CANCEL_LOGOUT => 3
 'Reboot'       ICEWM_ACTION_REBOOT        => 4
 'Shutdown'     ICEWM_ACTION_SHUTDOWN      => 5
 'About'        ICEWM_ACTION_ABOUT         => 6
 'Windowlist'   ICEWM_ACTION_WINDOWLIST    => 7
 'Restart'      ICEWM_ACTION_RESTARTWM     => 8

=cut

sub req_ICEWM_ACTION {
    my($X,$command) = @_;
    $command = 0 unless $command;
    $command = name2val(IceWMAction=>IceWMAction(),$command);
    WinClientMessage($X,0,_ICEWM_ACTION=>[$command]);
}

=back

=head3 _ICEWM_TRAY, CARDINAL/32

The C<_ICEWM_TRAY> property contains the tray option associated with a
client window.  This property can have values as follows:

 0 - ignore     WIN_TRAY_IGNORE
 1 - minimized  WIN_TRAY_MINIMIZED
 2 - exclusive  WIN_TRAY_EXCLUSIVE

When set to I<ignore> (0) (default), the window has its window button
only on TaskPane.  When set to I<mimimized> (1), the window has its icon
on TrayPane and only has a window button on TaskPane if it is not
mimimized.  When set to I<exclusive> (2), the window only has its icon
on the TrayPane and there is no window button on TaskPane.  Note that
using the "Tray Icon" selection from the window menu, toggles from 0 to
2 and back again.  The "TrayPane" is on the IceWM panel where the system
tray is located.  The "TaskPane" is the task bar portion of the IceWM
panel.

Only the window manager sets this property.  A client wishing to change
the property must send a C<ClientMessage> to the root window with mask
C<SubstructureNotifyMask> as follows:

 window = window
 message_type = _ICEWM_TRAY
 format = 32
 data.l[0] = tray_opt
 data.l[1] = timestamp
 other data.l[] elements = 0

=head4 Methods

In the following methods, I<$option> is an interpreted scalar value of
type C<IceWMTray> that can have one of the following interpreted names
or symbolic constant values:

    Ignore      WIN_TRAY_IGNORE     => 0
    Minimized   WIN_TRAY_MINIMIZED  => 1
    Exclusive   WIN_TRAY_EXCLUSIVE  => 2


=over

=cut

use constant {
    WIN_TRAY_IGNORE	    => 0,
    WIN_TRAY_MINIMIZED	    => 1,
    WIN_TRAY_EXCLUSIVE	    => 2,

    IceWMTray => [qw(
	Ignore
	Minimized
	Exclusive
    )],
};

=item B<get_ICEWM_TRAY>(I<$X>,I<$window>) => I<$option>

Returns the C<_ICEWM_TRAY> property tray option, I<$option>, or C<undef>
when no C<_ICEWM_TRAY> property exists on the window, I<$window>.
I<$option> is an interpreted scalar value as described above under
L</_ICEWM_TRAY>.

=cut

sub get_ICEWM_TRAY {
    return getWMPropertyInterp($_[0],$_[1],_ICEWM_TRAY=>IceWMTray=>IceWMTray());
}

sub dmp_ICEWM_TRAY {
    return dmpWMPropertyInterp($_[0],_ICEWM_TRAY=>option=>$_[1]);
}

=item B<set_ICEWM_TRAY>(I<$X>,I<$window>,I<$option>)

Sets the C<_ICEWM_TRAY> property tray option, I<$option>, for a window,
I<$window>, or when I<$option> is C<undef>, deletes the C<_ICEWM_TRAY>
option from I<$window>.  Only the window manager should directly set
the property in this way.  Clients should use req_ICEWM_TRAY().

=cut

sub set_ICEWM_TRAY {
    return setWMPropertyInterp($_[0],$_[1],_ICEWM_TRAY=>CARDINAL=>IceWMTray=>IceWMTray(),$_[2]);
}

=item B<req_ICEWM_TRAY>(I<$X>,I<$window>,I<$option>,I<$timestamp>)

Sends a client message to the root window, C<$X-E<gt>root>, requesting
that the tray option for window, I<$window>, be set to the value
specified by I<$option>.  I<$timestamp> is the X server time of the
invoking user event, or C<CurrentTime>.  I<$option>, when specified, is
an interpreted scalar string as described above under L</_ICEWM_TRAY>.

=cut

sub req_ICEWM_TRAY {
    my ($X,$window,$option,$timestamp) = @_;
    return $X->robust_req(
            DeleteProperty=>$window,
            $X->atom('_ICEWM_TRAY'))
        unless defined $option;
    $option = name2val(IceWMTray=>IceWMTray(),$option);
    $timestamp = 0 unless $timestamp;
    $timestamp = 0 if $timestamp eq 'CurrentTime';
    WinClientMessage($X,$window,_ICEWM_TRAY=>[$option,$timestamp]);
}

sub got_ICEWM_TRAY {
    my($X,$window,$option,$timestamp) = @_;
    $option = val2name(IceWMTray=>IceWMTray(),$option);
    $timestamp = 'CurrentTime' unless $timestamp;
    return ($window,$option,$timestamp);
}

=back

=head2 PeKWM

PekWM is only ICCCM and NetWM/EWMH compliant and is not Gnome/WMH
compliant.  It properly sets _NET_SUPPORTING_WM_CHECK on both the root
and check windows.  It sets _NET_WM_NAME(STRING) on the check window.
Note that _NET_WM_NAME should be UTF8_STRING instead of STRING
(corrected in the I<git> version).  It does not set WM_CLIENT_MACHINE on
the check window as required by EWMH, but sets it on the root window.
It does not, however, set it to the fully qualified domain name as
required by EWMH.  Also, it sets _NET_WM_PID on the check window, but
mistakenly sets it on the root window.  It sets WM_CLASS to a null
string on the check window and does not set WM_NAME.

=cut

$EXPORT_TAGS{pekwm} = [qw(
    PEKWM_DECOR_TITLEBAR
    PEKWM_DECOR_BORDER
    get_PEKWM_FRAME_DECOR
    set_PEKWM_FRAME_DECOR
    dmp_PEKWM_FRAME_DECOR
    PEKWM_SKIP_MENUS
    PEKWM_SKIP_FOCUS_TOGGLE
    PEKWM_SKIP_SNAP
    PEKWM_SKIP_PAGER
    PEKWM_SKIP_TASKBAR
    get_PEKWM_FRAME_SKIP
    set_PEKWM_FRAME_SKIP
    dmp_PEKWM_FRAME_SKIP
    get_PEKWM_FRAME_ID
    set_PEKWM_FRAME_ID
    dmp_PEKWM_FRAME_ID
    get_PEKWM_FRAME_ACTIVE
    set_PEKWM_FRAME_ACTIVE
    dmp_PEKWM_FRAME_ACTIVE
    get_PEKWM_FRAME_ORDER
    set_PEKWM_FRAME_ORDER
    dmp_PEKWM_FRAME_ORDER
)];

=head3 _PEKWM_FRAME_DECOR

=cut

use constant {
    PEKWM_DECOR_TITLEBAR	=> (1<<1),
    PEKWM_DECOR_BORDER		=> (1<<2),

    PekWMDecor => [undef, qw(
	Titlebar
	Border
    )],
};

=over

=item B<get_PEKWM_FRAME_DECOR>(I<$X>,I<$window>) => I<$decor> or undef

=cut

sub get_PEKWM_FRAME_DECOR {
    return getWMPropertyBitnames(@_[0..1],_PEKWM_FRAME_DECOR=>PekWMDecor=>PekWMDecor());
}

sub dmp_PEKWM_FRAME_DECOR {
    return dmpWMPropertyBitnames($_[0],_PEKWM_FRAME_DECOR=>decor=>$_[1]);
}

=item B<set_PEKWM_FRAME_DECOR>(I<$X>,I<$window>,I<$decor>)

=cut

sub set_PEKWM_FRAME_DECOR {
    return setWMPropertyBitnames(@_[0..1],_PEKWM_FRAME_DECOR=>CARDINAL=>PekWMDecor=>PekWMDecor(),$_[2]);
}

=back

=head3 _PEKWM_FRAME_SKIP

=cut

use constant {
    PEKWM_SKIP_MENUS		=> (1<<1),
    PEKWM_SKIP_FOCUS_TOGGLE	=> (1<<2),
    PEKWM_SKIP_SNAP		=> (1<<3),
    PEKWM_SKIP_PAGER		=> (1<<4),
    PEKWM_SKIP_TASKBAR		=> (1<<5),

    PekWMSkip => [undef, qw(
	Menus
	FocusToggle
	Snap
	Pager
	Taskbar
    )],
};



=over

=item B<get_PEKWM_FRAME_SKIP>(I<$X>,I<$window>) => I<$skip> or undef

=cut

sub get_PEKWM_FRAME_SKIP {
    return getWMPropertyBitnames(@_[0..1],_PEKWM_FRAME_SKIP=>PekWMSkip=>PekWMSkip());
}

sub dmp_PEKWM_FRAME_SKIP {
    return dmpWMPropertyBitnames($_[0],_PEKWM_FRAME_SKIP=>skip=>$_[1]);
}

=item B<set_PEKWM_FRAME_SKIP>(I<$X>,I<$window>,I<$skip>)

=cut

sub set_PEKWM_FRAME_SKIP {
    return setWMPropertyBitnames(@_[0..1],_PEKWM_FRAME_SKIP=>CARDINAL=>PekWMSkip=>PekWMSkip(),$_[2]);
}

=back

=head3 _PEKWM_FRAME_ID

=over

=item B<get_PEKWM_FRAME_ID>(I<$X>,I<$window>) => I<$id> or undef

=cut

sub get_PEKWM_FRAME_ID {
    return getWMPropertyUint(@_[0..1],_PEKWM_FRAME_ID=>);
}

sub dmp_PEKWM_FRAME_ID {
    return dmpWMPropertyUint($_[0],_PEKWM_FRAME_ID=>id=>$_[1]);
}

=item B<set_PEKWM_FRAME_ID>(I<$X>,I<$window>,I<$id>)

=cut

sub set_PEKWM_FRAME_ID {
    return setWMPropertyUint(@_[0..1],_PEKWM_FRAME_ID=>CARDINAL=>$_[2]);
}

=back

=head3 _PEKWM_FRAME_ACTIVE

=over

=item B<get_PEKWM_FRAME_ACTIVE>(I<$X>,I<$window>) => I<$active> or undef

=cut

sub get_PEKWM_FRAME_ACTIVE {
    return getWMPropertyInterp(@_[0..1],_PEKWM_FRAME_ACTIVE=>Boolean=>[qw(False True)]);
}

sub dmp_PEKWM_FRAME_ACTIVE {
    return dmpWMPropertyInterp($_[0],_PEKWM_FRAME_ACTIVE=>active=>$_[1]);
}

=item B<set_PEKWM_FRAME_ACTIVE>(I<$X>,I<$window>,I<$active>)

=cut

sub set_PEKWM_FRAME_ACTIVE {
    return setWMPropertyInterp(@_[0..1],_PEKWM_FRAME_ACTIVE=>CARDINAL=>Boolean=>[qw(False True)],$_[2]);
}

=back

=head3 _PEKWM_FRAME_ORDER

=over

=item B<get_PEKWM_FRAME_ORDER>(I<$X>,I<$window>) => I<$order> or undef

=cut

sub get_PEKWM_FRAME_ORDER {
    return getWMPropertyUint(@_[0..1],_PEKWM_FRAME_ORDER=>);
}

sub dmp_PEKWM_FRAME_ORDER {
    return dmpWMPropertyUint($_[0],_PEKWM_FRAME_ORDER=>order=>$_[1]);
}

=item B<set_PEKWM_FRAME_ORDER>(I<$X>,I<$window>,I<$order>)

=cut

sub set_PEKWM_FRAME_ORDER {
    return setWMPropertyUint(@_[0..1],_PEKWM_FRAME_ORDER=>CARDINAL=>$_[2]);
}

=back

=head2 JWM

JWM is only ICCCM and NetWM/EWMH compliant and is not Gnome/WMH
compliant.  It properly sets _NET_SUPPORTING_WM_CHECK on both the root
and the check window.  It properly sets _NET_WM_NAME on the check window
(to C<JWM>).  It does not property set _NET_WM_PID on the check window,
or anywhere for that matter [it does now].  It does not set
WM_CLIENT_MACHINE anywhere and there is no WM_CLASS  or WM_NAME on the
check window.

L<jwm(1)> provides for client message control.  It can also be
controlled by signals and sets it process id (PID) in the
C<_NET_WM_PID(CARDINAL/32)> property on the check window in current
versions of the window manager.  Older version of L<jwm(1)> must obtain
the PID from the child process used by a session manager to launch the
window manager.

=cut

$EXPORT_TAGS{jwm} = [qw(
    req_JWM_RELOAD
    req_JWM_RESTART
    req_JWM_EXIT
)];

=head3 _JWM_RELOAD

=over

=item B<req_JWM_RELOAD>(I<$X>)

Sends a client message to the root window that causes the window manager
to reload the root menue.

=cut

sub req_JWM_RELOAD {
    NetClientMessage($_[0],0,_JWM_RELOAD=>[]);
}

=back

=head3 _JWM_RESTART

=over

=item B<req_JWM_RESTART>(I<$X>)

Sends a client message to the root window that causes the window manager
to restart, reloading all configuration from configuration files.  THis
is sufficient for resettting styles.

=cut

sub req_JWM_RESTART {
    NetClientMessage($_[0],0,_JWM_RESTART=>[]);
}

=back

=head3 _JWM_EXIT

=over

=item B<req_JWM_EXIT>(I<$X>)

Sends a client message to the root window that causes the window manager
to exit gracefully.

=cut

sub req_JWM_EXIT {
    NetClientMessage($_[0],0,_JWM_EXIT=>[]);
}

=back


=head2 WindowMaker

WindowMaker is only ICCCM and NetWM/EWMH compliant and is not Gnome/WMH
compliant.  It property sets _NET_SUPPORTING_WM_CHECK on both the root
and the check window.  It does not set the _NET_WM_NAME on the check
window.  It does, however, define a recursive
_WINDOWMAKER_NOTICEBOARD(WINDOW/32) property that shares the same window
as the check window and sets the _WINDOWMAKER_ICON_TILE(_RGBA_IMAGE)
property on this window to the icon/dock/clip tile.

=cut

$EXPORT_TAGS{wmaker} = [qw(
    GSWindowStyleAttr
    GSWindowLevelAttr
    GSMiniaturizedPixmapAttr
    GSClosePixmapAttr
    GSMiniaturizedMaskAttr
    GSCloseMaskAttr
    GSExtraFlagsAttr
    GSDocumentEditedFlag
    GSNoApplicationIconFlag
    WMBorderlessWindowMask
    WMTitledWindowMask
    WMClosableWindowMask
    WMMiniaturizableWindowMask
    WMResizableWindowMask
    WMIconWindowMask
    WMMiniWindowMask
    WMDesktopWindowLevel
    WMNormalWindowLevel
    WMFloatingWindowLevel
    WMSubmenuWindowLevel
    WMTornOffMenuWindowLevel
    WMMainMenuWindowLevel
    WMDockWindowLevel
    WMStatusWindowLevel
    WMModalPanelWindowLevel
    WMPopUpMenuWindowLevel
    WMScreenSaverWindowLevel
    get_GNUSTEP_WM_ATTR
    dmp_GNUSTEP_WM_ATTR
    req_WINDOWMAKER_COMMAND
    get_WINDOWMAKER_ICON_TILE
    set_WINDOWMAKER_ICON_TILE
    dmp_WINDOWMAKER_ICON_TILE
    get_WINDOWMAKER_MENU
    set_WINDOWMAKER_MENU
    dmp_WINDOWMAKER_MENU
    req_WINDOWMAKER_MENU
    get_WINDOWMAKER_NOTICEBOARD
    dmp_WINDOWMAKER_NOTICEBOARD
    set_WINDOWMAKER_NOTICEBOARD
    get_WINDOWMAKER_STATE
    set_WINDOWMAKER_STATE
    dmp_WINDOWMAKER_STATE
    WMF_HIDE_OTHER_APPLICATIONS
    WMF_HIDE_APPLICATION
    req_WINDOWMAKER_WM_FUNCTION
    get_WINDOWMAKER_WM_PROTOCOLS
    set_WINDOWMAKER_WM_PROTOCOLS
    dmp_WINDOWMAKER_WM_PROTOCOLS
)];

=head3 _GNUSTEP_WM_ATTR

 flags                CARD32
 window_style         CARD32
 window_level         CARD32
 reserved             CARD32
 miniaturize_pixmap   Pixmap
 close_pixmap         Pixmap
 miniaturize_mask     Pixmap
 close_mask           Pixmap
 extra_flags          CARD32

 flags:  GSWindowStyleAttr        (1<<0)
         GSWindowLevelAttr        (1<<1)
         GSMiniaturizedPixmapAttr (1<<3)
         GSClosePixmapAttr        (1<<4)
         GSMiniaturizedMaskAttr   (1<<5)
         GSCloseMaskAttr          (1<<6)
         GSExtraFlagsAttr         (1<<7)

 extra_flags:
         GSDocumentEditedFlag     (1<<0)
         GSNoApplicationIconFlag  (1<<5)

 window_style
   WMBorderlessWindowMask	=> 0
   WMTitledWindowMask		=> (1<<0)
   WMClosableWindowMask		=> (1<<1)
   WMMiniaturizableWindowMask	=> (1<<2)
   WMResizableWindowMask	=> (1<<3)
   WMIconWindowMask		=> (1<<6)
   WMMiniWindowMask		=> (1<<7)

 window_level:
   WMDesktopWindowLevel	    => -1000
   WMNormalWindowLevel	    => 0
   WMFloatingWindowLevel    => 3
   WMSubmenuWindowLevel	    => 3
   WMTornOffMenuWindowLevel => 3
   WMMainMenuWindowLevel    => 20
   WMDockWindowLevel	    => 21
   WMStatusWindowLevel	    => 21
   WMModalPanelWindowLevel  => 100
   WMPopUpMenuWindowLevel   => 101
   WMScreenSaverWindowLevel => 1000

=cut

use constant {
    GSWindowStyleAttr		=> (1<<0),
    GSWindowLevelAttr		=> (1<<1),
    GSMiniaturizedPixmapAttr	=> (1<<3),
    GSClosePixmapAttr		=> (1<<4),
    GSMiniaturizedMaskAttr	=> (1<<5),
    GSCloseMaskAttr		=> (1<<6),
    GSExtraFlagsAttr		=> (1<<7),

    GSDocumentEditedFlag	=> (1<<0),
    GSNoApplicationIconFlag	=> (1<<5),

    GSExtraFlags => [
	DocumentEdited		=>
	(undef)			x 4,
	NoApplicationIcon	=>

    ],

    WMBorderlessWindowMask	=> 0,
    WMTitledWindowMask		=> (1<<0),
    WMClosableWindowMask	=> (1<<1),
    WMMiniaturizableWindowMask	=> (1<<2),
    WMResizableWindowMask	=> (1<<3),
    WMIconWindowMask		=> (1<<6),
    WMMiniWindowMask		=> (1<<7),

    GSWindowStyle => [
	Titled			=>
	Closable		=>
	Miniaturizable		=>
	Resizable		=>
	(undef)			x 2,
	IconWindow		=>
	MiniWindow		=>
    ],

    WMDesktopWindowLevel	=> -1000,
    WMNormalWindowLevel		=> 0,
    WMFloatingWindowLevel	=> 3,
    WMSubmenuWindowLevel	=> 3,
    WMTornOffMenuWindowLevel	=> 3,
    WMMainMenuWindowLevel	=> 20,
    WMDockWindowLevel		=> 21,
    WMStatusWindowLevel		=> 21,
    WMModalPanelWindowLevel	=> 100,
    WMPopUpMenuWindowLevel	=> 101,
    WMScreenSaverWindowLevel	=> 1000,

    GSWindowLevel => [
	Normal			=>
	(undef)			x 2,
	Floating		=>
	(undef)			x 16,
	MainMenu		=>
	Dock			=>
	(undef)			x 78,
	ModalPanel		=>
	PopUpMenu		=>
    ],

};

=head4 Methods

In the methods that follow, I<$attr> is a reference to a hash containing
the following keys:

    window_style	- window style bit mask (see below)
    window_level	- Window level value (see below)
    miniaturize_pixmap	- pixmap for miniaturize button
    close_pixmap	- pixmap for close button
    miniaturize_mask	- pixmap for miniaturize button mask
    close_mask		- pixmap for close button mask
    extra_flags		- extra flags bit mask (see below)

C<window_style> is an intepreted bit mask that may contain the following
bit definitions:

    ()		   => WMBorderlessWindowMask	=> 0
    Titled	   => WMTitledWindowMask	=> (1<<0)
    Closable	   => WMClosableWindowMask	=> (1<<1)
    Miniaturizable => WMMiniaturizableWindowMask=> (1<<2)
    Resizable	   => WMResizableWindowMask	=> (1<<3)
    IconWindow	   => WMIconWindowMask		=> (1<<6)
    MiniWindow	   => WMMiniWindowMask		=> (1<<7)

C<window_level> is an interpreted value that may be one of the following
value definitions:

		    WMDesktopWindowLevel	=> -1000
    Normal	 => WMNormalWindowLevel		=> 0
    Floating	 => WMFloatingWindowLevel	=> 3
		    WMSubmenuWindowLevel	=> 3
		    WMTornOffMenuWindowLevel	=> 3
    MainMenu	 => WMMainMenuWindowLevel	=> 20
    Dock	 => WMDockWindowLevel		=> 21
		    WMStatusWindowLevel		=> 21
    ModalPanel	 => WMModalPanelWindowLevel	=> 100
    PopUpMenu	 => WMPopUpMenuWindowLevel	=> 101
		    WMScreenSaverWindowLevel	=> 1000

C<extra_flags> is an intepreted bit mask that may contain the following
bit definitions:

    DocumentEdited	=> GSDocumentEditedFlag	    => (1<<0)
    NoApplicationIcon	=> GSNoApplicationIconFlag  => (1<<5)

=over

=item B<get_GNUSTEP_WM_ATTR>(I<$X>,I<$window>) => I<$attr>

=cut

sub get_GNUSTEP_WM_ATTR {
    return getWMPropertyDecode(@_[0..1],_GNUSTEP_WM_ATTR=>sub{
	    my ($flags, $window_style, $window_level, $reserved,
		$miniaturize_pixmap, $close_pixmap, $miniaturize_mask,
		$close_mask, $extra_flags) = unpack('L*',shift);
	    my %attr = ();
	    $attr{window_style} = bits2names(GSWindowStyle=>GSWindowStyle(),$window_style)
		if $flags & &GSWindowStyleAttr;
	    $attr{window_level} = val2name(GWWindowLevel=>GSWindowLevel(),$window_level)
		if $flags & &GSWindowLevelAttr;
	    $attr{miniaturize_pixmap} = ($miniaturize_pixmap ? $miniaturize_pixmap : 'None')
		if $flags & &GSMiniaturizePixmapAttr;
	    $attr{close_pixmap} = ($close_pixmap ? $close_pixmap : 'None')
		if $flags & &GSClosePixmapAttr;
	    $attr{miniaturize_mask} = ($miniaturize_mask ?  $miniaturize_mask : 'None')
		if $flags & &GSMiniaturizePixmapAttr;
	    $attr{close_mask} = ($close_mask ? $close_mask : 'None')
		if $flags & &GSClosePixmapAttr;
	    $attr{extra_flags} = bits2names(GSExtraFlags=>GSExtraFlags(),$extra_flags)
		if $flags & &GSExtraFlagsAttr;
	    return \%attr;
    });
}

=item B<set_GNUSTEP_WM_ATTR>(I<$X>,I<$window>,I<$attr>)

=cut

=item B<dmp_GNUSTEP_WM_ATTR>(I<$X>,I<$attr>)

=cut

sub dmp_GNUSTEP_WM_ATTR {
    my($X,$attr) = @_;
    return dmpWMPropertyDisplay($X,_GNUSTEP_WM_ATTR=>sub{
	    foreach (qw(window_style window_level)) {
		next unless defined $attr->{$_};
		printf "\t%-20s: %s\n",$_,$attr->{$_};
	    }
	    foreach (qw(miniaturize_pixmap close_pixmap
		    miniaturize_mask close_mask)) {
		next unless defined $attr->{$_};
		if ($attr->{$_} =~ m{^\d+$}) {
		    printf "\t%-20s: 0x%08x\n",$_,$attr->{$_};
		} else {
		    printf "\t%-20s: %s\n",$_,$attr->{$_};
		}
	    }
	    foreach (qw(extra_flags)) {
		next unless defined $attr->{$_};
		printf "\t%-20s: %s\n",$_,$attr->{$_};
	    }
    });
}

=item B<req_GNUSTEP_WM_ATTR>(I<$X>,I<$window>,I<$attr>,I<$value>)

=cut

=back


=head3 _GNUSTEP_WM_MINIATURIZE_WINDOW

=head3 _GNUSTEP_TITLEBAR_STATE

 WMTitleBarKey    => 0
 WMTitleBarNormal => 1
 WMTitleBarMain   => 2

=head3 _WINDOWMAKER_COMMAND

L<wmaker(1)> providdes for client message control.  It also provides for
sending signals to the window manager PID; however, L<wmaker(1)> does
not set its process identifier (PID) on any window property.

=over

=item B<req_WINDOWMAKER_COMMAND>(I<$X>,I<$command>)

The C<_WINDOWMAKER_COMMAND> client message takes a single 11-character
CSTRING argument: C<Reconfigure>.  No other string argument is currently
recognized.

=cut

sub req_WINDOWMAKER_COMMAND {
    my($X,$command) = @_;
    $command = 'Reconfigure' unless $command;
    NetClientMessage($X,0,_WINDOWMAKER_COMMAND=>
	    substr(pack('(Z*)xxxxxxxxxxxxxxxxxxxx',$command),0,20));
}

=back

=head3 _WINDOWMAKER_ICON_SIZE

This atom is no longer used by L<wmaker(1)> code.

=head3 _WINDOWMAKER_ICON_TILE, width/height data[] _RGBA_IMAGE/32

Specifies the L<wmaker(1)> tile in use.  This is normally posted only on
the L<wmaker(1)> notice board.  The property is format 32, and contains
a 16-bit width and height in the first CARD32 and the RGBA pixel data in
the remaining CARD32's.

=over

=item B<get_WINDOWMAKER_ICON_TILE>(I<$X>,I<$window>) => I<$tile>

=cut

sub get_WINDOWMAKER_ICON_TILE {
    return getWMPropertyDecode(@_[0..1],_WINDOWMAKER_ICON_TILE=>sub{
	    my ($wm,$wl,$hm,$hl,@vals) = unpack('C*',shift);
	    my %tile = ();
	    $tile{width} = ($wm<<16)|$wl;
	    $tile{height} = ($hm<<16)|$hl;
	    $tile{data} = \@vals;
	    return \%tile;
    });
}

=item B<set_WINDOWMAKER_ICON_TILE>(I<$X>,I<$window>,I<$tile>)

=cut

sub set_WINDOWMAKER_ICON_TILE {
    my($X,$window,$tile) = @_;
    return setWMPropertyEncode($X,$window,_WINDOWMAKER_ICON_TILE=>sub{
	    my $wm = ($tile->{width}>>8)&0xff;
	    my $wl = ($tile->{width}>>0)&0xff;
	    my $hm = ($tile->{height}>>8)&0xff;
	    my $hl = ($tile->{height}>>0)&0xff;
	    return _RGBA_IMAGE=>8,pack('C*',$wm,$wl,$hm,$hl,@{$tile->{data}});
    });
}

=item B<dmp_WINDOWMAKER_ICON_TILE>(I<$X>,I<$tile>)

=cut

sub dmp_WINDOWMAKER_ICON_TILE {
    my($X,$tile) = @_;
    return dmpWMPropertyDisplay($X,_WINDOWMAKER_ICON_TILE=>sub{
	    printf "\t%-20s: %d\n", width=>$tile->{width};
	    printf "\t%-20s: %d\n", height=>$tile->{height};
	    my @vals = @{$tile->{data}};
	    my $row = 0;
	    my $width = $tile->{width}; $width = 64 unless $width;  # stop a runaway
	    while (@vals) {
		printf "\t%-20s: %s\n",'row('.$row.')', join('',map{sprintf('%02x',$_)}splice(@vals,0,$width*4));
		$row++;
	    }
    });
}

=back

=head3 _WINDOWMAKER_MENU

The C<_WINDOWMAKER_MENU> protocol is a mechanism by which L<wmaker(1)>
provides for GNUstep application generated window menus.
C<_WINDOWMAKER_MENU> is a text property that an application can place on
its top-level window that describes an application submenu that becomes
part of the window menu when the user clicks the right mouse button on
the titlebar.  When an item from the menu is selected, L<wmaker(1)>
sends a C<_WINDOWMAKER_MENU> client message to the window to inform it
of which item was selected.

  1 - WmSelectItem

  1 - WmBeginMenu    command code title
  2 - WmEndMenu      command
 10 - WmNormalItem   command code tag enabled label
 11 - WmDoubleItem   command code tag enabled rtext label
 12 - WmSubmenuItem  command code tag enabled ncode label
 
A menu property looks like this:

 WMMenu 0
 1 0 The Menu Title
 10 0 1 1 Item Name
 11 0 2 1 label Item Name
 12 0 3 1 0 Submenu Item Name
 1 1 The Submenu Title
 10 1 4 1 Item Name
 11 1 5 0 label Disabled Item Name
 2 1
 2 0

Each line of the menu specification

=over

=item B<get_WINDOWMAKER_MENU>(I<$X>,I<$window>) => I<$menu>

=cut

sub get_WINDOWMAKER_MENU {
    return getWMPropertyStrings(@_[0..1],_WINDOWMAKER_MENU=>);
}

=item B<set_WINDOWMAKER_MENU>(I<$X>,I<$window>,I<$menu>)

=cut

sub set_WINDOWMAKER_MENU {
    return setWMPropertyStrings(@_[0..1],_WINDOWMAKER_MENU=>STRING=>$_[2]);
}

=item B<dmp_WINDOWMAKER_MENU>(I<$X>,I<$menu>)

=cut

sub dmp_WINDOWMAKER_MENU {
    my($X,$menu) = @_;
    return dmpWMPropertyDisplay($X,_WINDOWMAKER_MENU=>sub{
	    foreach (@$menu) { printf "\t%-20s: '%s'\n",appmenu=>$_ }
    });
}


=item B<req_WINDOWMAKER_MENU>(I<$X>,I<$window>,I<$tag>,I<$time>)

    type = ClientMessage
    message_type = _WINDOWMAKER_MENU
    format = 32
    window = client window with the _WINDOWMAKER_MENU property
    data.l[0] = timestamp of button press/release
    data.l[1] = what: SelectItem(1)
    data.l[2] = tag (from the _WINDOWMAKER_MENU property item selected)
    other data.l[] members = 0

=cut

sub req_WINDOWMAKER_MENU {
    my($X,$window,$tag,$time) = @_;
    $time = 0 unless $time;
    $time = 0 if $time eq 'CurrentTime';
    my ($res) = $X->robust_req(SendEvent=>$window,0,
	    $X->pack_event_mask(),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$window,
		type=>$X->atom('_WINDOWMAKER_MENU'),
		format=>32,
		data=>pack('LLLLL',$time,1,$tag,0,0)));
    return 0 unless ref $res;
    return 1;
}

=back

=head3 _WINDOWMAKER_NOTICEBOARD

=over

=item B<get_WINDOWMAKER_NOTICEBOARD>(I<$X>,I<$root>) => I<$check>

=cut

sub get_WINDOWMAKER_NOTICEBOARD {
    return getWMRootPropertyRecursive($_[0],_WINDOWMAKER_NOTICEBOARD=>$_[1]);
}

sub dmp_WINDOWMAKER_NOTICEBOARD {
    return dmpWMRootPropertyUint($_[0],_WINDOWMAKER_NOTICEBOARD=>check=>$_[1]);
}

=item B<set_WINDOWMAKER_NOTICEBOARD>(I<$X>,I<$check>)

=cut

sub set_WINDOWMAKER_NOTICEBOARD {
    return setWMRootPropertyRecursive($_[0],_WINDOWMAKER_NOTICEBOARD=>WINDOW=>$_[1]);
}

=back

=head3 _WINDOWMAKER_STATE

Provides a property to save L<wmaker(1)> specific state information on a
client window.  The property is formatted as follows:

 workspace         CARD32   workspace number
 miniaturized      CARD32   boolean true when miniaturized
 shaded            CARD32   boolean true when shaded
 hidden            CARD32   boolean true when hidden
 maximized         CARD32   boolean true when maximized
 x,y,width,height  CARD32   unmaximized geometry
 shortcut          CARD32   n'th bit set for (n+1)'th shortcut window

=over

=item B<get_WINDOWMAKER_STATE>(I<$X>,I<$window>) => I<$state>

=cut

sub get_WINDOWMAKER_STATE {
    return getWMPropertyHashUints(@_[0..1],_WINDOWMAKER_STATE=>[qw(
		workspace miniaturized shaded hidden maximized x y width
		height shortcut)]);
}

=item B<set_WINDOWMAKER_STATE>(I<$X>,I<$window>,I<$state>)

=cut

sub set_WINDOWMAKER_STATE {
    return setWMPropertyHashUints(@_[0..1],_WINDOWMAKER_STATE=>_WINDOWMAKER_STATE=>[qw(
		workspace miniaturized shaded hidden maximized x y width
		height shortcut)],$_[2]);
}

=item B<dmp_WINDOWMAKER_STATE>(I<$X>,I<$state>)

=cut

sub dmp_WINDOWMAKER_STATE {
    return dmpWMPropertyHashUints($_[0],_WINDOWMAKER_STATE=>[qw(
		workspace miniaturized shaded hidden maximized x y width
		height shortcut)],$_[1]);
}

=back

=head3 _WINDOWMAKER_WM_FUNCTION

Provides a client message that performs one of two L<wmaker(1)> specific
window functions, as follows:

 'HideOtherApplications'    WMF_HIDE_OTHER_APPLICATIONS => 10
 'HideApplication'	    WMF_HIDE_APPLICATION	=> 12

=cut

use constant {
    WMF_HIDE_OTHER_APPLICATIONS	=> 10,
    WMF_HIDE_APPLICATION	=> 12,

    WmFunction=>[
	undef, undef, undef, undef, undef,
	undef, undef, undef, undef, undef,
	'HideOtherApplications', undef,
	'HideApplication',
    ],
};

=over

=item B<req_WINDOWMAKER_WM_FUNCTION>(I<$X>,I<$window>,I<$function>)

=cut

sub req_WINDOWMAKER_WM_FUNCTION {
    my($X,$window,$function) = @_;
    $function = 0 unless $function;
    $function = name2val(WmFunction=>WmFunction(),$function);
    WinClientMessage($X,$window,_WINDOWMAKER_WM_FUNCTION=>[$function]);
}

=back

=head3 _WINDOWMAKER_WM_PROTOCOLS

This property is set by L<wmaker(1)> on the root window and contains
atoms that indicate which protocols L<wmaker(1)> supports.  Current
versions of L<wmaker(1)> include the following atoms:

 _WINDOWMAKER_MENU
 _WINDOWMAKER_WM_FUNCTION
 _WINDOWMAKER_NOTICEBOARD

=over

=item B<get_WINDOWMAKER_WM_PROTOCOLS>(I<$X>,I<$root>) => I<$protocols>

Retrieves the window maker protocols, I<$protocols>, as a reference to a
hash whose keys are the names of the included protocols, or C<undef>
when no C<_WINDOWMAKER_WM_PROTOCOLS> property exists on I<$root>.

=cut

sub get_WINDOWMAKER_WM_PROTOCOLS {
    return getWMRootPropertyAtoms($_[0],_WINDOWMAKER_WM_PROTOCOLS=>$_[1]);
}

=item B<set_WINDOWMAKER_WM_PROTOCOLS>(I<$X>,I<$protocols>)

=cut

sub set_WINDOWMAKER_WM_PROTOCOLS {
    return setWMRootPropertyAtoms($_[0],_WINDOWMAKER_WM_PROTOCOLS=>$_[1]);
}

=item B<dmp_WINDOWMAKER_WM_PROTOCOLS>(I<$X>,I<$protocols>)

=cut

sub dmp_WINDOWMAKER_WM_PROTOCOLS {
    return dmpWMRootPropertyAtoms($_[0],_WINDOWMAKER_WM_PROTOCOLS=>protocols=>$_[1]);
}

=back

=head2 FVWM

FVWM is both ICCCM/EWMH compliant as well as Gnome/WMH compliant.  It
sets C<_NET_SUPPORTING_WM_CHECK> property on the root window and check
window.  On the check window it sets C<_NET_WM_NAME> to C<FVWM>.  It
sets C<WM_NAME> to C<fvwm> and C<WM_CLASS> to C<fvwm>, C<FVWM>.  FVWM
implements C<_WIN_SUPPORTING_WM_CHECK> in a separate window from
C<_NET_SUPPORTING_WM_CHECK>, but the same one as
C<_WIN_DESKTOP_BUTTON_PROXY>.  There are no additional properties set on
those windows.

=cut

$EXPORT_TAGS{fvwm} = [qw(
)];

=head2 KWIN/KWM

Many window managers (and in particular, L<fluxbox(1)>, L<openbox(1)>
and L<fvwm(1)>) support the KDE desktop by performing a number of the
actions and properties provided by KWin/KWM (the KDE window manager).
As these mimic KWIN, we provide them under this section.

=cut

$EXPORT_TAGS{fvwm} = [qw(
    getKWM_DOCKWINDOW
    setKWM_DOCKWINDOW
    dmpKWM_DOCKWINDOW
    get_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR
    set_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR
    dmp_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR
)];

push @{$EXPORT_TAGS{fluxbox}}, qw(
    getKWM_DOCKWINDOW
    setKWM_DOCKWINDOW
    dmpKWM_DOCKWINDOW
    get_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR
    set_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR
    dmp_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR
);

push @{$EXPORT_TAGS{openbox}}, qw(
    get_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR
    set_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR
    dmp_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR
);

=head3 _KDE_SPLASH_PROGRESS progress STRING[]/8

This atom is used to sending client messages and has no corresponding
property.

=over

=item B<req_KDE_SPLASH_PROGRESS>(I<$X>,I<$progress>)

I<$progress> defaults to C<wm started>.

=cut

sub req_KDE_SPLASH_PROGRESS {
    my($X,$progress) = @_;
    $progress = "wm started" unless $progress;
    $X->SendEvent($X->root,0,
	    $X->pack_event_mask(qw(
		    SubstructureNotify
		    SubstructureRedirect)),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$X->root,
		type=>$X->atom('_KDE_SPLASH_PROGRESS'),
		format=>8,
		data=>substr(pack('Z*xxxxxxxxxxxxxxxxxxxx',$progress),0,20)));
    return 1;
}

=back

=head3 _KDE_NET_WM_FRAME_STRUT, left right top bottom CARDINAL[4]/32

Several window managers (L<openbox(1)>, L<fvwm(1)>), set the
C<_KDE_NET_WM_FRAME_STRUT> property on client windows.  This property is
identical to C<_NET_FRAME_EXTENTS> in format and context: it contains
the breadth of decorations placed on the window, in pixels, to the left,
right, top and bottom of the client window.  An undecorated window has
all four values set to zero.

It appears that this property was necessary some time before
C<_NET_FRAME_EXTENTS> was added to the NetWM/EWMH specification.  It
exists in current versions and most window manager (even light weight
window managers) have been updated to include it.

=over

=item B<get_KDE_NET_WM_FRAME_STRUT>(I<$X>,I<$window>) => I<$strut>

=cut

sub get_KDE_NET_WM_FRAME_STRUT {
    return getWMPropertyHashUints(@_[0..1],_KDE_NET_WM_FRAME_STRUT=>[qw(left right top bottom)]);
}

=item B<set_KDE_NET_WM_FRAME_STRUT>(I<$X>,I<$window>,I<$strut>)

=cut

sub set_KDE_NET_WM_FRAME_STRUT {
    return setWMPropertyHashUints(@_[0..1],_KDE_NET_WM_FRAME_STRUT=>CARDINAL=>[qw(left right top bottom)],$_[2]);
}

=item B<dmp_KDE_NET_WM_FRAME_STRUT>(I<$X>,I<$strut>)

=cut

sub dmp_KDE_NET_WM_FRAME_STRUT {
    return dmpWMPropertyHashUints($_[0],_KDE_NET_WM_FRAME_STRUT=>[qw(left right top bottom)],$_[1]);
}

=back

=head3 _KDE_WM_CHANGE_STATE

This atom defines a client message type.  This message is sent to the
root window whenever the C<WM_STATE> changes state to and from normal
and iconic state.

 destination = root
 propagate = False
 event_mask = SubstructureNotifyMask|SubstructureRedirectMask
 type = ClientMessage
 message_type = _KDE_WM_CHANGE_STATE
 window = window changing state
 format = 32
 data.l[0] = wmstate (NormalState(1), IconicState(3))
 data.l[1] = 1
 other data.l[] elements = 0

=over

=item B<req_KDE_WM_CHANGE_STATE>(I<$X>,I<$window>,I<$state>)

=cut

sub req_KDE_WM_CHANGE_STATE {
    my($X,$window,$state) = @_;
    $state = 0 unless defined $state;
    $state = name2val(WMState=>WMState(),$state);
    NetClientMessage($X,$window,_KDE_WM_CHANGE_STATE=>[$state,1]);
}

=back

=head3 KWM_DOCKWINDOW, KWM_DOCKWINDOW/32

Provides a root window property that indicates the dock window to KDE
dock applets.  This is an older one.

=over

=item B<getKWM_DOCKWINDOW>(I<$X>,I<$root>) => I<$window>

=cut

push @{$EXPORT_TAGS{common}}, qw(wm_check);

sub getKWM_DOCKWINDOW {
    return getWMRootPropertyUint($_[0],KWM_DOCKWINDOW=>$_[1]);
}

=item B<setKWM_DOCKWINDOW>(I<$X>,I<$window>)

=cut

sub setKWM_DOCKWINDOW {
    return setWMRootPropertyUint($_[0],KWM_DOCKWINDOW=>KWM_DOCKWINDOW=>$_[1]);
}

=item B<dmpKWM_DOCKWINDOW>(I<$X>,I<$window>)

=cut

sub dmpKWM_DOCKWINDOW {
    return dmpWMRootPropertyUint($_[0],KWM_DOCKWINDOW=>window=>$_[1]);
}

=back

=head3 _KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR root WINDOW/32

Provides a root window property that indicates the dock window to KDE
dock applets.  This is a newer one.  Standard system trays now use ICCCM
2.0 C<MANAGER> selections.

When this property is set on a top-level client window that is being
mapped for the first time, the window manager adds the window to the
C<_KDE_NET_SYSTEM_TRAY_WINDOWS> root window property and does not
further manage (or map) the window.  The expectation is that the KDE
system tray will reparent and map the window as appropriate.

=over

=item B<get_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR>(I<$X>,I<$window>) => I<$bool>

=cut

sub get_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR {
    return getWMPropertyInterp(@_[0..1],_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR=>Window=>[qw(None)]);
}

=item B<set_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR>(I<$X>,I<$window>,I<$bool>)

=cut

sub set_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR {
    return setWMPropertyInterp(@_[0..1],_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR=>WINDOW=>Window=>[qw(None)],$_[2]);
}

=item B<dmp_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR>(I<$X>,I<$bool>)

=cut

sub dmp_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR {
    return dmpWMPropertyInterp($_[0],_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR=>traywindow=>$_[1]);
}

=back

=head3 _KDE_NET_SYSTEM_TRAY_WINDOWS, windows WINDOW[]/32

Defines a root window property that identifies each top-level window
that has the C<_KET_NET_WM_SYSTEM_TRAY_WINDOW_FOR> property set.  The
window manager does not reparent these windows but simply allows the KDE
system tray to do what it wants with them.

=over

=item B<get_KDE_NET_SYSTEM_TRAY_WINDOWS>(I<$X>,I<$root>) => I<$windows>

=cut

sub get_KDE_NET_SYSTEM_TRAY_WINDOWS {
    return getWMRootPropertyUints($_[0],_KDE_NET_SYSTEM_TRAY_WINDOWS=>$_[1]);
}

=item B<set_KDE_NET_SYSTEM_TRAY_WINDOWS>(I<$X>,I<$windows>)

=cut

sub set_KDE_NET_SYSTEM_TRAY_WINDOWS {
    return setWMRootPropertyUints($_[0],_KDE_NET_SYSTEM_TRAY_WINDOWS=>WINDOW=>$_[1]);
}

=item B<dmp_KDE_NET_SYSTEM_TRAY_WINDOWS>(I<$X>,I<$windows>)

=cut

sub dmp_KDE_NET_SYSTEM_TRAY_WINDOWS {
    return dmpWMRootPropertyUints($_[0],_KDE_NET_SYSTEM_TRAY_WINDOWS=>windows=>$_[1]);
}

=back

=head3 _KDE_NET_WM_WINDOW_TYPE_OVERRIDE

This is deprecated.  By setting this property on a top-level window
before it is mapped, it tells the window manager not to provide any
decorations or function for the window.  It is equivalent to setting
C<_MOTIF_WM_HINTS> indicating no decorations and no functions.

=over

=item B<get_KDE_NET_WM_WINDOW_TYPE_OVERRIDE>(I<$X>,I<$window>) => I<$bool>

=cut

sub get_KDE_NET_WM_WINDOW_TYPE_OVERRIDE {
    return getWMPropertyInterp(@_[0..1],_KDE_NET_WM_WINDOW_TYPE=>Boolean=>[qw(False True)]);
}

=item B<set_KDE_NET_WM_WINDOW_TYPE_OVERRIDE>(I<$X>,I<$window>,I<$bool>)

=cut

sub set_KDE_NET_WM_WINDOW_TYPE_OVERRIDE {
    return setWMPropertyInterp(@_[0..1],_KDE_NET_WM_WINDOW_TYPE_OVERRIDE=>CARDINAL=>Boolean=>[qw(False True)],$_[2]);
}

=item B<dmp_KDE_NET_WM_WINDOW_TYPE_OVERRIDE>(I<$X>,I<$bool>)

=cut

sub dmp_KDE_NET_WM_WINDOW_TYPE_OVERRIDE {
    return dmpWMPropertyInterp($_[0],_KDE_NET_WM_WINDOW_TYPE_OVERRIDE=>override=>$_[1]);
}

=back

=head2 MWM

=cut

$EXPORT_TAGS{mwm} = [qw(
    MWM_HINTS_FUNCTIONS
    MWM_HINTS_DECORATIONS
    MWM_HINTS_INPUT_MODE
    MWM_HINTS_STATUS
    MWM_FUNC_ALL
    MWM_FUNC_RESIZE
    MWM_FUNC_MOVE
    MWM_FUNC_MINIMIZE
    MWM_FUNC_MAXIMIZE
    MWM_FUNC_CLOSE
    MWM_DECOR_ALL
    MWM_DECOR_BORDER
    MWM_DECOR_RESIZEH
    MWM_DECOR_TITLE
    MWM_DECOR_MENU
    MWM_DECOR_MINIMIZE
    MWM_DECOR_MAXIMIZE
    MWM_INPUT_MODELESS
    MWM_INPUT_PRIMARY_APPLICATION_MODAL
    MWM_INPUT_SYSTEM_MODAL
    MWM_INPUT_FULL_APPLICATION_MODAL
    MWM_INPUT_APPLICATION_MODAL
    MWM_TEAROFF_WINDOW
    get_MOTIF_WM_HINTS
    dmp_MOTIF_WM_HINTS
    set_MOTIF_WM_HINTS
    get_MOTIF_WM_INFO
    dmp_MOTIF_WM_INFO
    set_MOTIF_WM_INFO
    get_MOTIF_DRAG_WINDOW
    dmp_MOTIF_DRAG_WINDOW
    set_MOTIF_DRAG_WINDOW
    get_MOTIF_DRAG_ATOM_PAIRS
    dmp_MOTIF_DRAG_ATOM_PAIRS
    set_MOTIF_DRAG_ATOM_PAIRS
)];

=head3 _MOTIF_BINDINGS

=head3 _MOTIF_WM_HINTS

 flags        CARD32
 functions    CARD32
 decorations  CARD32
 input_mode   INT32
 status       CARD32


=cut

use constant {
    MWM_HINTS_FUNCTIONS	    => (1<<0),
    MWM_HINTS_DECORATIONS   => (1<<1),
    MWM_HINTS_INPUT_MODE    => (1<<2),
    MWM_HINTS_STATUS	    => (1<<3),

    MWMHints => [qw(
	    Functions
	    Decorations
	    InputMode
	    STatus
    )],

    MWM_FUNC_ALL	    => (1<<0),
    MWM_FUNC_RESIZE	    => (1<<1),
    MWM_FUNC_MOVE	    => (1<<2),
    MWM_FUNC_MINIMIZE	    => (1<<3),
    MWM_FUNC_MAXIMIZE	    => (1<<4),
    MWM_FUNC_CLOSE	    => (1<<5),

    MWMFunc => [qw(
	    All
	    Resize
	    Move
	    Minimize
	    Maximize
	    Close
    )],

    MWM_DECOR_ALL	    => (1<<0),
    MWM_DECOR_BORDER	    => (1<<1),
    MWM_DECOR_RESIZEH	    => (1<<2),
    MWM_DECOR_TITLE	    => (1<<3),
    MWM_DECOR_MENU	    => (1<<4),
    MWM_DECOR_MINIMIZE	    => (1<<5),
    MWM_DECOR_MAXIMIZE	    => (1<<6),

    MWMDecor => [qw(
	    All
	    Border
	    ResizeHandles
	    Title
	    Menu
	    Minimize
	    Maximize
    )],

    MWM_INPUT_MODELESS			    => 0,
    MWM_INPUT_PRIMARY_APPLICATION_MODAL	    => 1,
    MWM_INPUT_SYSTEM_MODAL		    => 2,
    MWM_INPUT_FULL_APPLICATION_MODAL	    => 3,
    MWM_INPUT_APPLICATION_MODAL		    => 1,

    MWMInput => [qw(
	    Modeless
	    Primary
	    System
	    Full
    )],

    MWM_TEAROFF_WINDOW	    => (1<<0),

    MWMStatus => [qw(
	    TearoffWindow
    )],
};

=over

=item B<get_MOTIF_WM_HINTS>(I<$X>,I<$window>) => I<$hints> or undef

=cut

sub get_MOTIF_WM_HINTS {
    return getWMPropertyDecode(@_[0..1],_MOTIF_WM_HINTS=>sub{
	    my($flags,$functions,$decorations,$input,$status)
		= unpack('LLLLL',shift);
	    my %hints = ();
	    if ($flags & &MWM_HINTS_FUNCTIONS) {
		$hints{functions} =
		    bits2names(MWMFunc=>MWMFunc(),$functions);
	    }
	    if ($flags & &MWM_HINTS_DECORATIONS) {
		$hints{decorations} =
		    bits2names(MWMDecor=>MWMDecor(),$decorations);
	    }
	    if ($flags & &MWM_HINTS_INPUT_MODE) {
		$hints{input_mode} =
		    bits2names(MWMInput=>MWMInput(),$input);
	    }
	    if ($flags & &MWM_HINTS_STATUS) {
		$hints{status} =
		    bits2names(MWMStatus=>MWMStatus(),$status);
	    }
	    return \%hints;
    });
}

sub dmp_MOTIF_WM_HINTS {
    my($X,$hints) = @_;
    return dmpWMPropertyDisplay($X,_MOTIF_WM_HINTS=>sub{
	    foreach (qw(functions decorations input_mode status)) {
		next unless defined $hints->{$_};
		printf "\t%-20s: %s\n",$_,join(', ',@{$hints->{$_}});
	    }
    });
}

=item B<set_MOTIF_WM_HINTS>(I<$X>,I<$window>,I<$hints>)

=cut

sub set_MOTIF_WM_HINTS {
    my $hints = $_[2];
    return setWMPropertyEncode(@_[0..1],_MOTIF_WM_HINTS=>sub{
	    my ($flags,@vals) = (0,0,0,0,0);
	    if ($hints->{functions}) {
		$flags |= &MWM_HINTS_FUNCTIONS;
		$vals[0] = names2bits(MWMFunc=>MWMFunc(),$hints->{functions});
	    }
	    if ($hints->{decorations}) {
		$flags |= &MWM_HINTS_DECORATIONS;
		$vals[1] = names2bits(MWMDecor=>MWMDecor(),$hints->{decorations});
	    }
	    if ($hints->{input_mode}) {
		$flags |= &MWM_HINTS_INPUT_MODE;
		$vals[2] = names2bits(MWMInput=>MWMInput(),$hints->{input_mode});
	    }
	    if ($hints->{status}) {
		$flags |= &MWM_HINTS_STATUS;
		$vals[3] = names2bits(MWMStatus=>MWMStatus(),$hints->{status});
	    }
	    return CARDINAL=>32,pack('LLLLL',$flags,@vals);
    });
}

=back

=head3 _MOTIF_WM_MESSAGES

=head3 _MOTIF_WM_OFFSET

=head3 _MOTIF_WM_MENU

=head3 _MOTIF_WM_INFO

 flags      CARD32
 wm_window  CARD32

=cut

use constant {
    MWM_INFO_STARTUP_STANDARD	=> (1<<0),
    MWM_INFO_STARTUP_CUSTOM	=> (1<<1),

    MWMStartup => [qw(
	    Standard
	    Custom
    )],
};

=over

=item B<get_MOTIF_WM_INFO>(I<$X>,I<$root>) => I<$info> or undef

=cut

sub get_MOTIF_WM_INFO {
    return getWMRootPropertyDecode($_[0],_MOTIF_WM_INFO=>sub{
	    my($flags,$window) = unpack('LL',shift);
	    $flags = 0 unless $flags;
	    my %info = ();
	    $info{flags} = bits2names(MWMStartup=>MWMStartup(),$flags);
	    $window = 'None' unless $window;
	    $info{wm_window} = $window;
	    return \%info;
    },$_[1]);
}

sub dmp_MOTIF_WM_INFO {
    my($X,$info) = @_;
    return dmpWMRootPropertyDisplay($X,_MOTIF_WM_INFO=>sub{
	printf "\t%-20s: %s\n",flags=>join(', ',@{$info->{flags}});
	printf "\t%-20s: 0x%08x\n",wm_window=>$info->{wm_window};
    });
}

=item B<set_MOTIF_WM_INFO>(I<$X>,I<$info>)

=cut

sub set_MOTIF_WM_INFO {
    my $info = $_[1];
    return setWmRootPropertyEncode($_[0],_MOTIF_WM_INFO=>sub{
	    my($flags,$window) = (0,0);
	    $flags = names2bits(MWMStartup=>MWMStartup(),$info->{flags}) if $info->{flags};
	    $window = $info->{wm_window} if defined $info->{wm_window};
	    $window = 0 if $window eq 'None';
	    return CARDINAL=>32,pack('LL',$flags,$window);
    });
}

=back

=head3 _MOTIF_DRAG_WINDOW WINDOW/32

=over

=item B<get_MOTIF_DRAG_WINDOW>(I<$X>,I<$root>) => I<$window> or undef

=cut

sub get_MOTIF_DRAG_WINDOW {
    return getWMRootPropertyUint($_[0],_MOTIF_DRAG_WINDOW=>$_[1]);
}

sub dmp_MOTIF_DRAG_WINDOW {
    return dmpWMRootPropertyUint($_[0],_MOTIF_DRAG_WINDOW=>window=>$_[1]);
}

=item B<set_MOTIF_DRAG_WINDOW>(I<$X>,I<$window>)

=cut

sub set_MOTIF_DRAG_WINDOW {
    return setWMRootPropertyUint($_[0],_MOTIF_DRAG_WINDOW=>$_[1]);
}

=back

=head3 _MOTIF_DRAG_ATOM_PAIRS

=over

=item B<get_MOTIF_DRAG_ATOM_PAIRS>(I<$X>,I<$window>) => I<$atoms> or undef

=cut

sub get_MOTIF_DRAG_ATOM_PAIRS {
    return getWMPropertyDecode(@_[0..1],_MOTIF_DRAG_ATOM_PAIRS=>sub{
	    my $data = shift;
	    my($byte_order,$protocol_version,$protocol_style,$pad1,
		$proxy_window,$num_drop_sites,$pad2,$total_size) = 
	    unpack('CCCCLSSL',$data);
	    if ($byte_order ne 'l' and $byte_order ne 'B') {
		($pad1,$protocol_style,$protocol_version,$byte_order) =
		($byte_order,$protocol_version,$protocol_style,$pad1);
		($pad2,$num_drop_sites) =
		($num_drop_sites,$pad2);
	    }
	    my %pairs = ();
	    $pairs{protocol_version} = $protocol_version;
	    $pairs{protocol_style} = $protocol_style;
	    $pairs{proxy_window} = $proxy_window ? $proxy_window : 'None';
	    $pairs{num_drop_sites} = $num_drop_sites;
	    $pairs{total_size} = $total_size;
	    return \%pairs;
    });
}

sub dmp_MOTIF_DRAG_ATOM_PAIRS {
    return dmpWMPropertyHashUints($_[0],_MOTIF_DRAG_ATOM_PAIRS=>[qw(
		protocol_version protocol_style proxy_window
		num_drop_sites total_size)],$_[1]);
}

=item B<set_MOTIF_DRAG_ATOM_PARIS>(I<$X>,I<$window>,I<$atoms>)

=cut

sub set_MOTIF_DRAG_ATOM_PAIRS {
    my $pairs = $_[2];
    return setWMPropertyEncode(@_[0..1],_MOTIF_DRAG_ATOM_PAIRS=>sub{
	    my($byte_order,$protocol_version,$protocol_style,$pad1,
		$proxy_window,$num_drop_sites,$pad2,$total_size) =
	    (0,0,0,0,0,0,0,0);
	    $byte_order = unpack('C',pack('L',1)) ? unpack('C','l') : unpack('C','B');
	    $protocol_version = $pairs->{protocol_version} if $pairs->{protocol_version};
	    $protocol_style = $pairs->{protocol_style} if $pairs->{protocol_style};
	    $proxy_window = $pairs->{proxy_window} if $pairs->{proxy_window};
	    $proxy_window = 0 unless $proxy_window;
	    $proxy_window = 0 if $proxy_window eq 'None';
	    $num_drop_sites = $pairs->{num_drop_sites} if $pairs->{num_drop_sites};
	    $total_size = $pairs->{total_size} if $pairs->{total_size};
	    return CARDINAL=>32,pack('CCCCLSSL',
		$byte_order,$protocol_version,$protocol_style,$pad1,
		$proxy_window,$num_drop_sites,$pad2,$total_size);
    });
}

=back

=head2 Wind

Wind is largely ICCCM compliant (but does not take an ICCCM 2.0 WM_S%d
manager selection).  It provides partial NetWM/EWMH compliance and no
GNOME/WMH compliance.  Wind correctly sets _NET_SUPPORTING_WM_CHECK on
both the root and check windows.  It correctly sets _NET_WM_NAME to the
single word C<Wind>.

=head2 TWM

=head2 CTWM

=head2 VTWM

=head2 Metacity

=head2 WMX

=cut

{
    my %seen;
    push @{$EXPORT_TAGS{all}},
	grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
	    foreach keys %EXPORT_TAGS;

    foreach my $pfx (qw(get set dmp req)) {
	push @{$EXPORT_TAGS{$pfx}},
	     grep {/^$pfx/} @{$EXPORT_TAGS{all}};
    }
}

Exporter::export_tags('common');
Exporter::export_ok_tags('all');

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
