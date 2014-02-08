package XDE::Dock;
use base qw(XDE::Dual XDE::Actions);
use Linux::Inotify2;
use Glib qw(TRUE FALSE);
use Carp qw(cluck croak);
use strict;
use warnings;

=head1 NAME

XDE::Dock -- XDE Dock for WMs that do not provide one

=head1 SYNOPSIS

 my $xde = XDE::Dock->new(%OVERRIDES,ops=>\%ops);
 $xde->getenv;
 $xde->default;
 $SIG{TERM} = sub{$xde->main_quit};
 $xde->init;
 $xde->main;
 $xde->term;
 exit(0);

=head1 DESCRIPTION

A number of light-weight window managers supported by XDE provide a
WindowMaker-like Dock: L<fluxbox(1)>, L<blackbox(1)>, L<openbox(1)>,
L<pekwm(1)>, L<wmaker(1)>.  Of these, L<pekwm(1)> provides a suboptimal
dock (it does not center swallowed windows); and L<wmaker(1)>'s dock is
far too manual (it needs to launch the dock applications itself,
unavailable dock applications still show a window position.).  All of
these window managers are capable of disabling the dock functionality
through configuration.  Other window managers supported by L<XDE(3pm)>
do not provide a dock (per say): L<icewm(1)>, L<jwm(1)>, L<fvwm(1)>,
L<afterstep(1)>, L<metacity(1)>.  Of these, L<fvwm(1)> and
L<afterstep(1)> provide the ability to I<swallow> a dock application,
but this, again, requires manual configuration.

This is an application-based dock which performs much like the automatic
docks of the I<*box> window managers, however, it is standalone.

Another objective of this module is to provide increased functionality
over the I<*box> window managers as follows:

=over

=item 1.

Restore some of the more desirable WindowMaker behaviour to the dock.
This includes getting the dock to launch the dock applications when it
starts up, however, unlike WindowMaker, do not include space for dock
applications that are not available.  Drawers.  Drag and Drop
repositioning.  Drag and Drop addition and deletion.

=item 2.

Provide an XDG-based menu for adding dock apps to the dock.  That is,
provide a selection of doc apps to add and provide a way for the user to
specify arguments to the launch command.

=back

=head1 METHODS

This module provides the following methods:

=head2 Initialization Methods

This module has the following initialization methods:

=over

=cut

=item B<new> XDE::Dock I<%OVERRIDES> => $dock

Creates an instance of an XDE::Dock object.  The XDE::Dock module uses
the L<XDE::Context(3pm)> module as a base, so the C<%OVERRIDES> are
simply passed to the L<XDE::Context(3pm)> module.

=cut

sub new {
    return XDE::Context::new(@_);
}

=item $dock->B<_init>() => $dock

Performs initialization for just this module.  Called after
L<XDE::Dual(3pm)> is fully initialized.  The actions performed are as
follows:

=over

=item 1.

The L<Linux::Inotify2(3pm)> connection is established and initiated.

=item 2.

The icon search path is initialized.

=item 3.

L<X11::Protocol(3pm)> extensions are initialized.

=item 4.

The EWMH/WMH/ICCCM environment is initialized.

=item 5.

Registration is perform on the root window to receive C<PropertyChange>
and C<SubstructureNotify> events.

=item 6.

A window is created to act as the parent for toplevel windows that are
reparented that do not correspond to the dock application window itself.

=item 7.

The dock window itself is created and dock applications searched and
reparented by calling the B<create_dock> method.

=back

=cut

sub _init {
    my $self = shift;

    # set up an Inotify2 connection
    my $N = $self->{N};
    unless ($N) {
	$N = $self->{N} = Linux::Inotify2->new;
	$N->blocking(FALSE);
    }
    Glib::Source->remove(delete $self->{notify}{watcher})
	if $self->{notify}{watcher};
    $self->{notify}{watcher} = Glib::IO->add_watch($N->fileno,
	    'in',sub{ $N->poll });

    # initialize icon search path
    my $icons = $self->{icontheme} =
	Gtk2::IconTheme->get_default;
    $icons->append_search_path("$ENV{HOME}/.icons");
    $icons->append_search_path("/usr/share/pixmaps");
    undef $icons;

    # initialize extensions
    my $X = $self->{X};
    $X->init_extensions;

    # set up the EWMH/WMH environment
    $self->XDE::Actions::setup;

    # register for notifications on root
    $X->ChangeWindowAttributes($X->root,
	    event_mask=>$X->pack_event_mask(
		'PropertyChange',
		'SubstructureNotify'
		));
    my $win = $X->new_rsrc;
    $X->CreateWindow($win,$X->root,'InputOutput',
	    $X->root_depth,'CopyFromParent',
	    (-1,-1),(1,1),0);
    $X->GetScreenSaver;
    $self->{dock}{parent} = $win;

    $self->create_dock;
    return $self;
}

=item $dock->B<_term>() => $dock

Performs termination just for this module.  Called before
L<XDE::Dual(3pm)> terminates.  The proper action to take here is to
reparent any windows that we have swallowed back to the root window so
that the window manager can take control of them or at least so that the
dock apps do not terminate when we don't want them to.

We change the save set of any windows that we reparent to the
L<X11::Protocol> window, so they should be reparented back to root on
their own; however, any windows that we have added to a L<Gtk2::Socket>
needs to be reparented away from the socket and back to root.

=cut

sub _term {
    my $self = shift;
    my $X = $self->{X};
    $self->{saveset} = {} unless $self->{saveset};
    $self->{reparent} = {} unless $self->{reparent};

    my %reparent = ();
    {
	my @windows = (keys %{$self->{saveset}});
	foreach my $xid (@windows) {
	    printf STDERR "==> SAVESET: includes window 0x%x (%d)\n",
		   $xid,$xid;
	    if ($self->{reparent}{$xid}) {
		printf STDERR "==> SOCKETS: includes window 0x%x (%d)\n",
		       $xid,$xid;
	    }
	    $reparent{$xid} = 1;
	}
    }
    {
	my @windows = (keys %{$self->{reparent}});
	foreach my $xid (@windows) {
	    printf STDERR "==> SOCKETS: includes window 0x%x (%d)\n",
		   $xid,$xid;
	    $reparent{$xid} = 1;
	}
    }
    $self->{shuttingdown} = 1;
    {
	my @windows = (keys %reparent);
	foreach my $xid (@windows) {
	    printf STDERR "==> REPARENTING: window 0x%x (%d) to root\n", $xid,$xid;
	    my $remap;
	    if ($self->{dockapps}{$xid}{needsremap}) {
		print STDERR "--> dockapp needs remap\n";
		$remap = 1;
	    }
	    if ($self->{iconwins}{$xid}{needsremap}) {
		print STDERR "--> iconwin needs remap\n";
		$remap = 1;
	    }
	    unless ($remap) {
		print STDERR "--> unmapping\n";
		$X->UnmapWindow($xid);
	    }
	    print STDERR "--> reparenting\n";
	    $X->ReparentWindow($xid,$X->root,0,0);
	    $X->GetScreenSaver;
	    Gtk2->main_iteration while Gtk2->events_pending;
	    if ($remap) {
		print STDERR "--> mapping\n";
		$X->MapWindow($xid);
	    } else {
		print STDERR "--> unmapping\n";
		$X->UnmapWindow($xid);
		$X->SendEvent($X->root,0,
			$X->pack_event_mask(qw(
				SubstructureRedirect
				SubstructureNotify)),
			$X->pack_event(
			    name=>'UnmapNotify',
			    event=>$X->root,
			    window=>$xid,
			    from_configure=>0,
			    ));
		if ($self->{wmname} eq 'pekwm') {
		    $X->SendEvent($X->root,0,
			    $X->pack_event_mask(qw(
				    SubstructureRedirect
				    SubstructureNotify)),
			    $X->pack_event(
				name=>'UnmapNotify',
				event=>$xid,
				window=>$xid,
				from_configure=>0,
				));
		}
	    }
	    $X->GetScreenSaver;
	}
	$X->GetScreenSaver;
	Gtk2->main_iteration while Gtk2->events_pending;
    }
    return $self;
}

=back

=head2 General Methods

This modules has the following general methods:

=over

=item $dock->B<create_dock>() => $dock

Creates the window for the dock and then embeds the dock aps that it can
find.

=cut

sub create_dock {
    my $self = shift;
     # just make a 1x6 64x64 button table first
    my $dock = $self->{dock}{win} = Gtk2::Window->new('toplevel');
    $dock->set_type_hint('dock');
    $dock->set_default_size(64,-1);
    $dock->set_decorated(FALSE);
    $dock->set_skip_pager_hint(TRUE);
    $dock->set_skip_taskbar_hint(TRUE);
    $dock->stick;
    $dock->set_deletable(FALSE);
    $dock->set_focus_on_map(FALSE);
    $dock->set_has_frame(FALSE);
    $dock->set_keep_above(TRUE);
#   $dock->set_keep_below(TRUE);
    $dock->set_resizable(FALSE);
#   $dock->set_size_request(64,-1);
    my $vbox = $self->{dock}{vbox} = Gtk2::VBox->new(FALSE,0);
    $vbox->set_size_request(64,-1);
    $dock->add($vbox);
    $dock->realize;
#   $dock->window->set_override_redirect(TRUE);
    $self->{dock}{apps} = 0;
    $self->find_dockapp_clients;
}

=item $dock->B<withdraw_window>(I<$X>,I<$win>) => $result

This method uses the X11::Protocol::Connection, C<$X>, to withdraw the
window, C<$win>.  The purpose here is to withdraw the window so that the
window manager will cease managing the window (as is required by the
ICCCM), in preparation for reparenting the window to the dock.

This method relies on ICCCM compliance.  Window managers are supposed to
reparent back to root any top-level window that was previously mapped
and reparented when they are unmapped by the client.

=cut

sub withdraw_window {
    my ($self,$X,$win) = @_;
    my $xid = $win->{window};
    my $return = 0;
    if (ref(my $result = $X->robust_req(QueryTree=>$xid))) {
	my ($root,$parent,@kids) = @$result;
	$win->{root} = $root;
	$win->{parent} = $parent;
	printf STDERR "::: window 0x%x (%d) root 0x%x (%d) parent 0x%x (%d)\n",
	       $xid,$xid,$root,$root,$parent,$parent;
	if ($root and $parent and $root != $parent) {
	    printf STDERR "==> DEPARENTING: window 0x%x (%d) from parent 0x%x (%d)\n",$xid,$xid,$parent,$parent;
	    $win->{withdrawing} = 1;
	    $return = 1;
	}
	elsif (my $wm_state = $self->getWM_STATE($xid)) {
	    # if the window has a WM_STATE property then it is not withdrawn
	    my ($state,$icon) = @$wm_state;
	    unless ($state eq 'WithdrawnState') {
		printf STDERR "==> WITHDRAWING: window 0x%x (%d)\n",$xid,$xid;
		$win->{withdrawing} = 1;
		$return = 1;
	    }
	}
	# Always unmap it.
	printf STDERR "--> UNMAPPING: window 0x%x (%d)\n",$xid,$xid;
	$X->UnmapWindow($xid);
	$X->SendEvent($X->root,0,
		$X->pack_event_mask(qw(
			SubstructureRedirect
			SubstructureNotify)),
		$X->pack_event(
		    name=>'UnmapNotify',
		    event=>$X->root,
		    window=>$xid,
		    from_configure=>0,
		    ));
	if ($self->{wmname} eq 'pekwm') {
	    $X->SendEvent($X->root,0,
		    $X->pack_event_mask(qw(
			    SubstructureRedirect
			    SubstructureNotify)),
		    $X->pack_event(
			name=>'UnmapNotify',
			event=>$xid,
			window=>$xid,
			from_configure=>0,
			));
	}
	$X->GetScreenSaver;
    }
    return $return;
}

=item $dock->B<test_window>(I<$X>,I<$xid>) => $result

Using the X11::Protocol::Connection, C<$X>, test the window, C<$win>, to
see whether it is a dock application and whether it should be
repartented to the dock.  This method returns true (1) when the window
is a dock application and false (0) when it is not.

This is an internal methods meant to be called from an event handler or
when initially searching the window stack for currently running dock
apps.

Some variations handled:

=over

=item 1.

Some dockapps use their toplevel window as the C<icon_window> as well.

=item 2.

Some dockapps use only their toplevel window and have no C<icon_window>.

=item 3.

Some dockapps have a toplevel window with an C<icon_window> that points
to itself!

=item 4.

Some dockapps use a separate toplevel window as the C<icon_window>.

=item 5.

Some dockapps make the C<icon_window> a child of their top-level window,
presumably so that WM's will map the child with the top-level if it
doesn't understand windows being mapped in the withdrawn state.  When
the C<icon_window> is a child of the toplevel, we do not want to steal
it away from its parent because it will be reparented to root on the way
out.  Therefore, when the C<icon_window> is a child of the toplevel, we
do not want to withdraw it and we want to reparent only the toplevel.

=back

=cut

sub test_window {
    my ($self,$X,$xid) = @_;
    return 0 if $self->{shuttingdown};
    printf STDERR "--> TESTING WINDOW: window = 0x%x (%d)\n",$xid,$xid;
    if (my $win = $self->getWM_HINTS($xid)) {
	return unless $win->{initial_state} and
	    $win->{initial_state} eq 'WithdrawnState';
#	# Some dockapp use their main window as an icon window
	$win->{icon_window} = 0 unless $win->{icon_window} and $win->{icon_window} ne 'None';
#	# Some dockapp icon windows point to themselves....
	$win->{icon_window} = 0 if $win->{icon_window} and $win->{icon_window} == $xid;
	printf STDERR "==> Should swallow window 0x%x (%d) with icon 0x%x (%d)!\n",
	       $xid,$xid,$win->{icon_window},$win->{icon_window};
	$win->{window} = $xid;
	foreach (keys %$win) {
	    $self->{dockapps}{$xid}{$_} = $win->{$_};
	}
	$win = $self->{dockapps}{$xid};
	my $wait_wind = $self->withdraw_window($X,$win);
	 # A couple of problems here: some dockapps make the icon_window
	 # a child of their toplevel window, presumably so that WM's
	 # will map the child with the toplevel if it doesn't understand
	 # window being mapped in the withdrawn state.  When the
	 # icon_window is a child of the toplevel, we do not want to
	 # steal it away from its parent because it will be reparented
	 # to root on the way out.  Therefore, when the icon_window is a
	 # child of the toplevel, we do not want to withdraw it and we
	 # want to reparent only the toplevel.
	my $wait_icon = 0;
	if (my $iid = $win->{icon_window}) {
	    my $icon = $self->{iconwins}{$iid};
	    $icon = $self->{iconwins}{$iid} = {} unless $icon;
	    $icon->{owner} = $xid;
	    $icon->{window} = $iid;
	    if (ref(my $result = $X->robust_req(QueryTree=>$iid))) {
		my ($root,$parent,@kids) = @$result;
		$icon->{root} = $root;
		$icon->{parent} = $parent;
		printf STDERR "::: icon_window 0x%x (%d) root 0x%x (%d) parent 0x%x (%d)\n",
		       $iid,$iid,$root,$root,$parent,$parent;
		if ($parent == $icon->{owner}) {
		    printf STDERR "::: icon_window 0x%x (%d) is a child of toplevel 0x%x (%d)\n",
			$iid,$iid,$parent,$parent;
		} else {
		    printf STDERR "::: icon-window 0x%x (%d) is its own toplevel\n",$iid,$iid;
		    $wait_icon = $self->withdraw_window($X,$icon);
		}
	    }
	}
	$self->swallow($win) unless $wait_wind or $wait_icon;
	return 1;
    }
    return 0;
}

=item $dock->B<search_window>(I<$X>,I<$win>)

Uses the L<X11::Protocol::Connection(3pm)>, C<$X>, to search for dock
application windows in the subtree rooted at the window, C<$win>.  The
search stops when a dock application is found in the subtree.

This is an internal method intended on being called at startup.

=cut

sub search_window {
    my($self,$X,$win) = @_;
    $self->search_kids($X,$win) if not $self->test_window($X,$win);
}

=item $dock->B<search_kids>(I<$X>,I<$win>)

Uses the L<X11::Protocol::Connection(3pm)>, C<$X>, to search for dock
application windows in the children of the window, C<$win>.  The search
is executed for each child regardless of whether dock application was
found in a sibling.

This is an internal method intended on being called at startup.

=cut

sub search_kids {
    my ($self,$X,$win) = @_;
    my $result = $X->robust_req(QueryTree=>$win);
    if (ref $result eq 'ARRAY') {
	my ($root,$parent,@kids) = @$result;
	$self->search_window($X,$_) foreach (@kids);
    }
}

=item $dock->B<find_dockapps>(I<$X>)

Uses the L<X11::Protocol::Connection(3pm)>, C<$X>, to search for dock
applications below the root window.

This is an internal method intended on being called at startup: it is
called at the end of the B<create_dock> method.

=cut

sub find_dockapps {
    my $self = shift;
    my $X = $self->{X};
    $self->search_kids($X,$X->root);
}

=item $dock->B<find_dockapp_clients>()

Uses the EWMH client list to search for dock applications managed by the
window manager.  This only works for window managers that do not have a
dock of their own.  That is, this might not work for: L<fluxbox(1)>,
L<blackbox(1)>, L<openbox(1)>, L<pekwm(1)>, and L<wmaker(1)>; but, it is
intended to work for L<icewm(1)>, L<jwm(1)>, L<fvwm(1)>, L<afterstep(1)>,
L<metacity(1)>, L<wmx(1)>.

=cut

sub find_dockapp_clients {
    my $self = shift;
    my $X = $self->{X};
    if ($self->{_NET_CLIENT_LIST}) {
	foreach (@{$self->{_NET_CLIENT_LIST}}) {
	    $self->test_window($X,$_);
	}
    }
}

=item $dock->B<dock_rearrange>()

Requests that the dock rearrange itself and correct its position and the
position of its children.

This is an internal method intended on being called whenever a dock
application is added to or removed from the dock.

=cut

sub dock_rearrange {
    my $self = shift;
    my $X = $self->{X};
    my $win = $self->{dock}{win};
    my $apps = $self->{dock}{apps};
    if ($apps <= 0) {
	$win->hide;
	return;
    }
    my $pos = $self->{ops}{position};
    $pos = 'E' unless $pos;
    my $dir = $self->{ops}{direction};
    $dir = 'V' unless $dir;
    my ($left,$right,$top,$bottom,$left_start_y,$left_end_y,
	    $right_start_y,$right_end_y,$top_start_x,$top_end_x,
	    $bottom_start_x,$bottom_end_x) = (0,0,0,0,0,0,0,0,0,0,0,0);
    my ($x,$y) = (0,0);
    my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
    if ($pos eq 'N') {
	if ($dir eq 'V') {
	    $top = $apps * 64;
	    $x = $top_start_x = int(($w-64)/2);
	    $top_end_x = int(($w+64)/2);
	    $y = 0;
	} else {
	    $top = 64;
	    $x = $top_start_x = int(($w-$apps*64)/2);
	    $top_end_x = int(($w+$apps*64)/2);
	    $y = 0;
	}
    }
    elsif ($pos eq 'NW') {
	if ($dir eq 'V') {
	    $left = 64;
	    $y = $left_start_y = 0;
	    $left_end_y = $apps*64;
	    $x = 0;
	} else {
	    $top = 64;
	    $x = $top_start_x = 0;
	    $top_end_x = $apps*64;
	    $y = 0;
	}
    }
    elsif ($pos eq 'W') {
	if ($dir eq 'V') {
	    $left = 64;
	    $y = $left_start_y = int(($h-$apps*64)/2);
	    $left_end_y = int(($h+$apps*64)/2);
	    $x = 0;
	} else {
	    $left = $apps*64;
	    $y = $left_start_y = int(($h-64)/2);
	    $left_end_y = int(($h+64)/2);
	    $x = 0;
	}
    }
    elsif ($pos eq 'SW') {
	if ($dir eq 'V') {
	    $left = 64;
	    $y = $left_start_y = $h-$apps*64;
	    $left_end_y = $h;
	    $x = 0;
	} else {
	    $bottom = 64;
	    $x = $bottom_start_x = 0;
	    $bottom_end_x = $apps*64;
	    $y = $h-$bottom;
	}
    }
    elsif ($pos eq 'S') {
	if ($dir eq 'V') {
	    $bottom = $apps*64;
	    $x = $bottom_start_x = int(($h-64)/2);
	    $bottom_end_x = int(($h+64)/2);
	    $y = $h-$bottom;
	} else {
	    $bottom = 64;
	    $x = $bottom_start_x = int(($h-$apps*64)/2);
	    $bottom_end_x = int(($h+$apps*64)/2);
	    $y = $h-$bottom;
	}
    }
    elsif ($pos eq 'SE') {
	if ($dir eq 'V') {
	    $right = 64;
	    $y = $right_start_y = $h-$apps*64;
	    $right_end_y = $h;
	    $x = $w-$right;
	} else {
	    $bottom = 64;
	    $x = $bottom_start_x = $w-$apps*64;
	    $bottom_end_x = $w;
	    $y = $h-$bottom;
	}
    }
    elsif ($pos eq 'E') {
	if ($dir eq 'V') {
	    $right = 64;
	    $y = $right_start_y = int(($h-$apps*64)/2);
	    $right_end_y = int(($h+$apps*64)/2);
	    $x = $w-$right;
	} else {
	    $right = $apps*64;
	    $y = $right_start_y = int(($h-64)/2);
	    $right_end_y = int(($h+64)/2);
	    $x = $w-$right;
	}
    }
    elsif ($pos eq 'NE') {
	if ($dir eq 'V') {
	    $right = 64;
	    $y = $right_start_y = 0;
	    $right_end_y = $apps*64;
	    $x = $w-$right;
	} else {
	    $top = 64;
	    $x = $top_start_x = $w-$apps*64;
	    $top_end_x = $w;
	    $y = 0;
	}
    }
    $win->realize;
    printf STDERR "--> MOVING dock to (%d,%d)\n", $x,$y;
    $win->move($x,$y);
    $win->window->move($x,$y);
    my @geom = $win->window->get_geometry;
    printf STDERR "--> GEOMETRY now (%d,%d,%d,%d,%d)\n",
	   @geom;
    printf STDERR "--> _NET_WM_STRUT set to (%d,%d,%d,%d)\n",
	   $left,$right,$top,$bottom;
    $win->window->property_change(
	    Gtk2::Gdk::Atom->intern('_NET_WM_STRUT',undef),
	    Gtk2::Gdk::Atom->intern('CARDINAL',undef),
	    32,
	    'replace',
	    $left,$right,$top,$bottom);
    printf STDERR "--> _NET_WM_STRUT_PARTIAL set to (%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)\n",
	   $left,$right,$top,$bottom,
	   $left_start_y,$left_end_y,
	   $right_start_y,$right_end_y,
	   $top_start_x,$top_end_x,
	   $bottom_start_x,$bottom_end_x;
    $win->window->property_change(
	    Gtk2::Gdk::Atom->intern('_NET_WM_STRUT_PARTIAL',undef),
	    Gtk2::Gdk::Atom->intern('CARDINAL',undef),
	    32,
	    'replace',
	    $left,$right,$top,$bottom,
	    $left_start_y,$left_end_y,
	    $right_start_y,$right_end_y,
	    $top_start_x,$top_end_x,
	    $bottom_start_x,$bottom_end_x);
}

=item $dock->B<swallow>(I<$win>)

Swallows the window, C<$win>, by reparenting it into the dock.

Wrinkles:

=over

=item 1.

When the C<icon_window> is a child of its top-level window, we want to
reparent the top-level and not the child.

=item 2.

When the C<icon_window> is its own top-level, we might have been
withdrawing it and we just haven't received the event at this point...

=item 3.

If the C<icon_window> is its own top-level window, independent of the
toplevel for which it is the C<icon_window>, we will need to wait for
it to appear on its own before reparenting can be done.

=item 4.

In the complex case where the C<icon_window> has a different top-level
window that the withdrawn dock application window, just reparent the
icon window.

=back

Reparenting is performed using the L<Gtk2::Socket(3pm)> mechanism.

=cut

sub swallow {
    my ($self,$win) = @_;
    my $xid = $win->{window};
    unless ($xid) {
	cluck "No XID!!! {",join(',',%$win),"}";
	return;
    }
    my $iid = $win->{icon_window};
    unless ($win->{swallowed}) {
	my $X = $self->{X};
	$X->GetScreenSaver;
	printf STDERR "==> SWALLOWING window 0x%x (%d) with icon 0x%x (%d)!\n",
	       $xid,$xid,$iid,$iid;
	if (my $wm_class = $self->getWM_CLASS($xid)) {
	    my ($name,$class) = @$wm_class;
	    $name = '' unless $name;
	    $class = '' unless $class;
	    printf STDERR "--> window 0x%x (%d) '%s', '%s'\n",
		   $xid,$xid,$name,$class;
	}
	if (my $wm_cmd = $self->getWM_COMMAND($xid)) {
	    my (@args) = @$wm_cmd;
	    printf STDERR "--> window 0x%x (%d) %s\n",
		   $xid,$xid,'"'.join('", "',@args).'"';
	}
	if (ref(my $result = $X->robust_req(QueryTree=>$xid))) {
	    my ($root,$parent,@kids) = @$result;
	    printf STDERR "--> window 0x%x (%d) has root 0x%x (%d)\n",
		   $xid,$xid,$root,$root;
	    printf STDERR "--> window 0x%x (%d) has parent 0x%x (%d)\n",
		   $xid,$xid,$parent,$parent;
	    foreach my $kid (@kids) {
		printf STDERR "--> window 0x%x (%d) has child 0x%x (%d)\n",
		       $xid,$xid,$kid,$kid;
	    }
	}
	if (ref(my $result = $X->robust_req(QueryTree=>$iid))) {
	    my ($root,$parent,@kids) = @$result;
	    printf STDERR "--> icon-window 0x%x (%d) has root 0x%x (%d)\n",
		   $iid,$iid,$root,$root;
	    printf STDERR "--> icon-window 0x%x (%d) has parent 0x%x (%d)\n",
		   $iid,$iid,$parent,$parent;
	    foreach my $kid (@kids) {
		printf STDERR "--> icon-window 0x%x (%d) has child 0x%x (%d)\n",
		       $iid,$iid,$kid,$kid;
	    }
	}
	my $sid = $xid;
	if ($iid) {
	    if (ref(my $result = $X->robust_req(QueryTree=>$iid))) {
		my ($root,$parent,@kids) = @$result;
		if ($parent == $xid) {
		    # when the icon_window is a child of its toplevel
		    # window, we want to reparent the toplevel and not the
		    # child.
		    printf STDERR "::: icon_window 0x%x (%d) has owner 0x%x (%d) as parent\n",
			$iid,$iid,$xid,$xid;
		    $sid = $xid;
		}
		elsif ($parent == $root) {
		    # when the icon_window is its own toplevel, we might
		    # have been withdrawing it and we just haven't received
		    # the event yet...
		    if ($self->{iconwins}{$iid} and $self->{iconwins}{$iid}{withdrawing}) {
			# if we are an icon window that is its own toplevel
			# window, wait for it to appear on its own.
			printf STDERR "!!! icon_window 0x%x (%d) is being withdrawn\n",
			    $iid,$iid;
			return;
		    } else {
			# otherwise, make the toplevel icon window the
			# window to reparent
			printf STDERR "::: icon_window 0x%x (%d) is a toplevel window\n",
			    $iid,$iid;
			$sid = $iid;
		    }
		}
		else {
		    # the difficult situation: the icon_window has a
		    # different toplevel window than the withdrawn docapp
		    # window....  For now, just reparent the icon window.
		    printf STDERR "::: icon_window 0x%x (%d) is a child of window 0x%x (%d)\n",
			$iid,$iid,$parent,$parent;
		    $sid = $iid;
		}
	    }
	}
	$self->{dockapps}{$xid}{mapped} = 0;
	$self->{iconwins}{$iid}{mapped} = 0 if $iid;
	$self->{dockapps}{$sid}{mapped} = 1 if $self->{dockapps}{$sid};
	$self->{iconwins}{$sid}{mapped} = 1 if $self->{iconwins}{$sid};
	 # see what happens
	my ($tpad,$bpad,$lpad,$rpad);
	if (ref(my $result = $X->robust_req(GetGeometry=>$sid))) {
	    my %geom = @$result;
	    $tpad = $bpad = int((64-$geom{height})/2);
	    $lpad = $rpad = int((64-$geom{width})/2);
	} else {
	    $tpad = $bpad = 0;
	    $lpad = $rpad = 0;
	}
#	my $b = Gtk2::HBox->new(FALSE,0);
#	my $b = Gtk2::Button->new;
#	$b->set_relief('none');
#	$b->set_alignment(0.5,0.5);
	my $b = Gtk2::EventBox->new;
	$b->set_size_request(64,64);
	my $a = Gtk2::Alignment->new(0.5,0.5,1.0,1.0);
	$a->set_padding($tpad,$bpad,$lpad,$rpad);
	$b->add($a);
#	$b->pack_start($a,FALSE,FALSE,0);
	my $s = Gtk2::Socket->new;
	$s->signal_connect(plug_removed=>sub{
		printf STDERR "*** PLUG REMOVED: window = 0x%x (%d) icon_window = 0x%x (%d)\n",$xid,$xid,$iid,$iid;
		$self->{dock}{vbox}->remove($b);
		$self->{dock}{apps} -= 1;
		$self->dock_rearrange;
		delete $self->{reparent}{$win->{window}};
		delete $self->{dockapps}{$win->{window}};
		delete $self->{iconwins}{$win->{icon_window}} if $win->{icon_window};
		});
	$a->add($s);
	printf STDERR "--> PACKING SOCKET for window 0x%x (%d) into dock\n",$sid,$sid;
	$self->{dock}{vbox}->pack_start($b,FALSE,FALSE,0);
	$self->{dock}{apps} += 1;
	$self->dock_rearrange;
	$b->show_all;
	$a->show_all;
	$s->show_all;
	$self->{dock}{win}->show_all;
	printf STDERR "--> ADDING window 0x%x (%d) into socket\n",$sid,$sid;
	# We might also use $s->steal($sid) here.  I don't quite know
	# what the difference is as both appear to behave the same;
	# however, there is no way to add the window Gtk2's save set, so
	# we need to figure out how to do that.  Perhaps stealing has
	# this effect.
	$self->{reparent}{$sid} = 1;
	if (0) {
	    $s->steal($sid);
	} else {
	    $s->add_id($sid);
	}
	$win->{swallowed} = 1;
    } else {
	warn sprintf("Window 0x%x (%d) already swallowed!",$xid,$xid);
    }
}

=item $dock->B<unswallow>(I<$win>)

Unswallows the window, C<$win>, by reparenting it back to root.

=cut

sub unswallow {
    my ($self,$win) = @_;
    unless (delete $win->{swallowed}) {
	printf STDERR "==> Would UNSWALLOW window 0x%x (%d)!\n",
	       $win->{window},$win->{window};
    }
}

=item $dock->B<test_for_dockapp>(I<$win>)

Tests the window, C<$win>, to determine whether it is a dock
application.  If the window, C<$win>, is a dock application, the window
swallowing procedure is initiated; otherwise, the window unswallowing
procedure is initiated.

This is an internal function that is not currently used.

=cut

sub test_for_dockapp {
    my ($self,$win) = @_;
    my $X = $self->{X};
    unless ($win) {
	warn "will not test an unknown window";
	return;
    }
    if (my $hints = $self->getWM_HINTS($win->{window})) {
	$win->{$_} = $hints->{$_} foreach (keys %$hints);
	if (exists $win->{initial_state}) {
	    if ($win->{initial_state} eq 'WithdrawnState') {
		$self->swallow($win);
	    } else {
		$self->unswallow($win);
	    }
	} else {
	    $self->unswallow($win);
	}
    }
    return;
}

=back

=head2 Event Handlers

The XDE::Dock module has the following default event handlers:

=over

=item $dock->B<event_handler_CreateNotify>(I<$e>,I<$X>,I<$v>)

Event handler for when top-level windows are created.  Whenever a
top-level window is created we want to subscribe to property changes so
that we can determine when to check WM_HINTS for the tell-tale indicator
of a windowmaker dock application: initial_state of C<WithdrawnState>.

This handler currently does nothing!

=cut

sub event_handler_CreateNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    printf STDERR "::: CreateNotify: parent=0x%x (%d) window=0x%x (%d)\n",
	   $e->{parent},$e->{parent},$e->{window},$e->{window};
}

=item $dock->B<event_handler_DestroyNotify>(I<$e>,I<$X>,I<$v>)

Event handler for when windows are destroyed.

This handler currently does nothing!

=cut

sub event_handler_DestroyNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    printf STDERR "::: DestroyNotify: event=0x%x (%d) window=0x%x (%d)\n",
	   $e->{event},$e->{event},$e->{window},$e->{window};
}

=item $dock->B<event_handler_ReparentNotify>(I<$e>,I<$X>,I<$v>)

Detecting when a window is ready to be examined for C<WM_HINTS> to
determine whether the window wants to be mapped to the withdrawn state
is a little tricky.

=cut

sub event_handler_ReparentNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    printf STDERR "::: ReparentNotify: event=0x%x (%d) window=0x%x (%d) parent=0x%x (%d)\n",
	   $e->{event},$e->{event},$e->{window},$e->{window},$e->{parent},$e->{parent};
    return if $e->{override_redirect};
    return if $self->{shuttingdown};
    my $xid = $e->{window};
    if ($e->{parent} == $X->root) {
	 # window was parented back to the root window
	my $win;
	if (my $dock = $self->{dockapps}{$xid}) {
	    my $parent = $dock->{parent};
	    printf STDERR "::: RESTORED: dockapp = 0x%x (%d) from parent 0x%x (%d)\n",$xid,$xid,$parent,$parent;
	    if (delete $dock->{withdrawing}) {
		$dock->{needsremap} = 1;
		printf STDERR "::: ACQUIRED: dockapp = 0x%x (%d)\n",$xid,$xid;
		$win = $dock;
		if (my $iid = $dock->{icon_window}) {
		    if (my $icon = $self->{iconwins}{$iid}) {
			if ($icon->{withdrawing}) {
			    printf STDERR "... WAITING: iconwin = 0x%x (%d)\n",$iid,$iid;
			    $win = undef;
			}
		    }
		}
	    }
	}
	elsif (my $icon = $self->{iconwins}{$xid}) {
	    my $parent = $icon->{parent};
	    printf STDERR "::: RESTORED: iconwin = 0x%x (%d) from parent 0x%x (%d)\n",$xid,$xid,$parent,$parent;
	    if (delete $icon->{withdrawing}) {
		$icon->{needsremap} = 1;
		printf STDERR "::: ACQUIRED: iconwin = 0x%x (%d)\n",$xid,$xid;
		if (my $own = $icon->{owner}) {
		    if ($win = $self->{dockapps}{$own}) {
			if ($win->{withdrawing}) {
			    printf STDERR "... WAITING: dockapp = 0x%x (%d)\n",$own,$own;
			    $win = undef;
			}
		    }
		}
	    }
	}
	if ($win) {
	    printf STDERR "==> REPARENTING: window 0x%x (%d) to internal 0x%x (%d)\n",
		   $win->{window},$win->{window},$self->{dock}{parent},$self->{dock}{parent};
	    $X->ChangeSaveSet('Insert',$win->{window});
	    $self->{saveset}{$win->{window}} = 1;
	    $X->ReparentWindow($win->{window},$self->{dock}{parent},0,0);
	    $X->MapWindow($win->{window});
	    $X->GetScreenSaver;
	    $self->swallow($win);
	    if ($self->{wmname} eq 'pekwm') {
		printf STDERR "*** DESTROYING: dockapp = 0x%x (%d)\n",$win->{window},$win->{window};
		# pekwm does not clear the parent window when unmapping,
		# so make it think that the windows were destroyed, but
		# only after reparenting the windows
		$X->UnmapWindow($win->{window});
		$X->SendEvent($X->root,0,
			$X->pack_event_mask(qw(
				SubstructureNotify
				SubstructureRedirect)),
			$X->pack_event(
			    name=>'DestroyNotify',
			    event=>$X->root,
			    window=>$win->{window},
			    ));
		if ($win->{icon_window}) {
		    printf STDERR "*** DESTROYING: iconwin = 0x%x (%d)\n",$win->{icon_window},$win->{icon_window};
		    $X->UnmapWindow($win->{icon_window});
		    $X->SendEvent($X->root,0,
			    $X->pack_event_mask(qw(
				    SubstructureNotify
				    SubstructureRedirect)),
			    $X->pack_event(
				name=>'DestroyNotify',
				event=>$X->root,
				window=>$win->{icon_window},
				));
		}
		$X->GetScreenSaver;
	    }
	    # remap the window under the new parent so that it will
	    # map itself when reparented to root
	    $X->MapWindow($win->{window});
	}
    } else {
	 # window was parented away from the root window
	unless ($self->{dockapps}{$xid}) {
	     # and it wasn't just us
	     # test this window to see if it can be ours
	    $self->test_window($X,$xid);
	}
    }
}

=item $dock->B<event_handler_UnmapNotify>(I<$e>,I<$X>,I<$v>)

Event handlers for when windows are unmapped.

This handler currently does nothing!

=cut

sub event_handler_UnmapNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    printf STDERR "::: UnmapNotify: event=0x%x (%d) window=0x%x (%d) from_configure=%s\n",
	   $e->{event},$e->{event},$e->{window},$e->{window},$e->{from_configure};
}

=item $dock->B<event_handler_MapNotify>(I<$e>,I<$X>,I<$v>)

Event handler for when windows are mapped.

This handler tests when windows are mapped whether they have the
signatures of dock applications.  L<pekwm(1)> needs this.

=cut

sub event_handler_MapNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    printf STDERR "::: MapNotify: event=0x%x (%d) window=0x%x (%d) override_redirect=%s\n",
	   $e->{event},$e->{event},$e->{window},$e->{window},$e->{override_redirect};
    return if $self->{shuttingdown};
    # pekwm needs this
    my $xid = $e->{window};
    unless ($self->{dockapps}{$xid}) {
	$self->test_window($X,$xid);
    }
}

=item $dock->B<event_handler_PropertyNotifyWM_HINTS>(I<$e>,I<$X>,I<$v>)

Event handler for changes to the C<WM_HINTS> property on windows so that
we can discover the tell-tale signs of a windowmaker dock application:
being mapped in the withdrawn state.

We register for property notification on newly created windows to check
for changes to the WM_HINTS property.  We recheck the window status when
this property changes.  It can change any time between C<CreateNotify> and
this C<PropertyNotify>.

This action is currently commented out!

=cut

sub event_handler_PropertyNotifyWM_HINTS {
    my $self = shift;
    my ($e,$X,$v) = @_;
    return if $self->{shuttingdown};
#    my $xid = $e->{window};
#    unless ($self->{dockapps}{$xid}) {
#	$self->test_window($X,$xid);
#    }
}

1;

=back

=head1 WINDOW MANAGERS

Each XDE-supported window manager behaves a little differently when it
comes to dock apps as follows:

=over

=item L<fluxbox(1)>

L<fluxbox(1)> provides its own dock (called a "slit").

=over

=item *

WindowMaker and KDE dock apps are automatically swallowed to the dock
(based on being mapped in the C<WithdrawnState>).

=item *

Facility is provided to position and autohide the dock.

=item *

Styles support the dock.

=item *

Some native facility is provided for positioning dock apps.

=item *

No provision is provided for restarting dock apps startup and session
management of dock apps is unsupported and problematic.

=item *

L<fluxbox(1)> does not support X session management and improperly
failes to set the C<WM_STATE> property on swallowed dock apps (and,
therefore, session management proxies such as L<smproxy(1)> will not
save and restore dock app settings.

=back

=item L<blackbox(1)>

L<blackbox(1)> provides its own dock (called a "slit").

=over

=item *

WindowMaker dock apps are automatically swallowed to the dock.
Styles support the dock.

=item *

KDE applications are not automatically swallowed to the dock and
a separate KDE dock is necessary to support KDE dock apps.

=item *

Facility is provided for positionining and autohiding the dock.

=item *

No facility is provided to position applications within the dock.

=item *

No provision is provided for restarting dock apps; startup and session
management of dock apps is unsupported and problematic.

=item *

L<blackbox(1)> does not support X session management and improperly fails
to set the C<WM_STATE> property on swallowed dock apps (and, therefore,
session management proxies such as L<smproxy(1)> will not save and
restore dock app settings.

=back

=item L<openbox(1)>

L<openbox(1)> provides its own dock.

=over

=item *

WindowMaker dock apps are automatically swallowed to the dock.

=item *

Styles support the dock.

=item *

KDE applications are not automatically swallowed to the dock and a
separate KDE dock is necessary to support KDE dock apps.

=item *

Facility is provided for positioning and autohiding the dock.

=item *

No facility is provided for positioning applications within the dock.

=item *

No provision is provided for restarting dock apps; startup and session
managemen of dock apps is problematic.

=item *

L<openbox(1)> supports X session management; however, it improperly
fails to set the C<WM_STATE> property on swallowed dock apps (and,
therefore session management proxies such as L<smproxy(1)> will not save
and restore dock app settings.

=item *

It is questionable whether L<openbox(1)> saves the state of dock app
windows at all.

=back

=item L<icewm(1)>

IceWM does not provide a dock.  It is able to swallow applications into
its internal panel.
L<icewm(1)> treats windows with the C<WithdrawnState> as the initial
state in window hints as C<DontCareState>.

=item L<jwm(1)>

JWM does not provide a dock.  It is able to swallow applications into
its internal panel.

=item L<pekwm(1)>

PEK provides its own dock (called a "harbour").  WindowMaker dock apps
are atuomatically swallowed to the dock.

=item L<wmaker(1)>

Window Maker provides its own dock.  Applications 

=item L<fvwm(1)>

=item L<afterstep(1)>

=item L<metacity(1)>

=item L<wmx(1)>

=item L<ctwm(1)>

L<ctwm(1)> does not provide its own dock.  It does, however, support
window boxes that are capable of swallowing applications.  In general,
it should not be too difficult to extend the winbox mechanism to provide
a dock that automatically swallows dock apps.
L<ctwm(1)> treats windows with the C<WithdrawnState> as the initial
state in window hints as C<DontCareState>.

=item L<vtwm(1)>

L<vtwm(1)> does not provide its own dock.
L<vtwm(1)> treats windows with the C<WithdrawnState> as the initial
state in window hints as C<DontCareState>.

=item L<twm(1)>

L<twm(1)> treats windows with the C<WithdrawnState> as the initial
state in window hints as C<DontCareState>.


=item B<unknown>

When B<XDE::Dock> encounters a window manager that it does not directly
support, it falls back to default behaviour.  Default behavior is to
look for toplevel windows and client windows in the C<_NET_CLIENT_LIST>
that have an initial state of C<WithdrawnState> and perform ICCCM
unmapping requests on their toplevels.


=back

=head1 BUGS

Currently B<xde-dock> is not reparenting the dock applications back to
root when the program terminates:

=over

=item 1.

When the program terminates with C<SIGTERM>, we should catch the signal
and reparent all of the dock applications back to the root and request
of the window manager that they be mapped.

=item 2.

When the program terminates with C<SIGKILL>, the only way to reparent
the windows back to root and map them is by adding them to our
save-list.  Unfortunately, we are using Gdk/Gtk2 for the reparenting, so
we have to figure a way to get Gdk/Gtk2 to add the windows to its save
list.

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Desktop(3pm)>, L<XDE::Desktop::Icon(3pm)>

=cut

__END__

# vim: set sw=4 tw=72:
