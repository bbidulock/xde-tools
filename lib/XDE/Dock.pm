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

=head1 DESCRIPTION

A number of light-weigth window managers supported by XDE provide a
WindowMaker-like Dock: L<fluxbox(1)>, L<blackbox(1)>, L<openbox(1)>,
L<pekwm(1)>, L<wmaker(1)>.  Of these, L<pekwm(1)> provides a suboptimal
dock (it does not center swallowed windows); and L<wmaker(1)>'s dock is
far too manual (it needs to launch the dock apps itself, unavailable
dock apps still show a window position.).  All of these window managers
are capapble of disabling the dock functionality through configuraiton.
Other window managers supported by XDE do not provide a dock (per say):
L<icewm(1)>, L<jwm(1)>, L<fvwm(1)>, L<afterstep(1)>.  Of these,
L<fvwm(1)> and L<afterstep(1)> provide the ability to I<swallow> a dock
app, but this, again, requires manual configuration.

This is an applicaiton-based dock which performs much like the automatic
docks of the I<*box> window managers, however, it is standalone.

Another objective of this module is to provide increased functionality
over the I<*box> window managers as follows:

=over

=item 1.

Restore some of the more desirable WindowMaker behaviour to the dock.
This includes getting the dock to launch the dock apps when it starts
up, however, unlike WindowMaker, do not include space for dock apps that
are not available.  Drawers.  Drag and Drop repositioning.  Drag and
Drop addition and deletion.

=item 2.

Provide an XDG-based menu for adding dock apps to the dock.  That is,
provide a selection of doc apps to add and provide a way for the user to
specify arguments to the launch command.

=back

=head1 METHODS

This module provides the following methods:

=over

=cut

=item XDE::Dock->new(I<%OVERRIDES>) => $dock

Creates an instance of an XDE::Dock object.  The XDE::Dock module uses
the L<XDE::Context(3pm)> module as a base, so the C<%OVERRIDES> are
simply passed to the L<XDE::Context(3pm)> module.

=cut

sub new {
    return XDE::Context::new(@_);
}

=item $dock->B<_init>() => $dock

Performs initialization for just this module.  Called after
L<XDE::Dual(3pm)> is fully initialized.

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
L<XDE::Dual(3pm)> terminates.

=cut

sub _term {
    my $self = shift;
    return $self;
}

=item $dock->B<create_dock>() => $dock

Creates the windows for the dock and embeds the dock aps that it can
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
    $self->find_dockapps;
}

sub withdraw_window {
    my ($self,$X,$win) = @_;
    my $xid = $win->{window};
    my $return = 0;
    if (ref(my $result = $X->robust_req(QueryTree=>$xid))) {
	my ($root,$parent,@kids) = @$result;
	$win->{root} = $root;
	$win->{parent} = $parent;
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

sub test_window {
    my ($self,$X,$xid) = @_;
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

sub search_window {
    my($self,$X,$win) = @_;
    $self->search_kids($X,$win) if not $self->test_window($X,$win);
}

sub search_kids {
    my ($self,$X,$win) = @_;
    my $result = $X->robust_req(QueryTree=>$win);
    if (ref $result eq 'ARRAY') {
	my ($root,$parent,@kids) = @$result;
	$self->search_window($X,$_) foreach (@kids);
    }
}

sub find_dockapps {
    my $self = shift;
    my $X = $self->{X};
    $self->search_kids($X,$X->root);
}

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
	$s->add_id($sid);
	$win->{swallowed} = 1;
    } else {
	warn sprintf("Window 0x%x (%d) already swallowed!",$xid,$xid);
    }
}

sub unswallow {
    my ($self,$win) = @_;
    unless (delete $win->{swallowed}) {
	printf STDERR "==> Would UNSWALLOW window 0x%x (%d)!\n",
	       $win->{window},$win->{window};
    }
}

=item $dock->B<event_handler_CreateNotify>(I<$e>,I<$X>,I<$v>)

Event handler for when toplevel windows are created.  Whenever a
toplevel window is created we want to subscribe to property changes so
that we can determine when to check WM_HINTS for the tell-tale indicator
of a windowmaker dockapp: initial_state of WithdrawnState.

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

sub event_handler_CreateNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    printf STDERR "::: CreateNotify: parent=0x%x (%d) window=0x%x (%d)\n",
	   $e->{parent},$e->{parent},$e->{window},$e->{window};
}

=item $dock->B<event_handler_DestroyNotify>(I<$e>,I<$X>,I<$v>)

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
    my $xid = $e->{window};
    if ($e->{parent} == $X->root) {
	 # window was parented back to the root window
	my $win;
	if (my $dock = $self->{dockapps}{$xid}) {
	    my $parent = $dock->{parent};
	    printf STDERR "::: RESTORED: dockapp = 0x%x (%d) from parent 0x%x (%d)\n",$xid,$xid,$parent,$parent;
	    if (delete $dock->{withdrawing}) {
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
	    $X->ReparentWindow($win->{window},$self->{dock}{parent},0,0);
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

sub event_handler_UnmapNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    printf STDERR "::: UnmapNotify: event=0x%x (%d) window=0x%x (%d) from_configure=%s\n",
	   $e->{event},$e->{event},$e->{window},$e->{window},$e->{from_configure};
}

sub event_handler_MapNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    printf STDERR "::: MapNotify: event=0x%x (%d) window=0x%x (%d) override_redirect=%s\n",
	   $e->{event},$e->{event},$e->{window},$e->{window},$e->{override_redirect};
    # pekwm needs this
    my $xid = $e->{window};
    unless ($self->{dockapps}{$xid}) {
	$self->test_window($X,$xid);
    }
}

=item $dock->B<event_handler_PropertyNotifyWM_HINTS>(I<$e>,I<$X>,I<$v>)

We register for property notification on newly created windows to check
for changes to the WM_HINTS property.  We recheck the window status when
this property changes.  It can change any time between CreateNotify and
this PropertyNotify.

=cut

sub event_handler_PropertyNotifyWM_HINTS {
    my $self = shift;
    my ($e,$X,$v) = @_;
#    my $xid = $e->{window};
#    unless ($self->{dockapps}{$xid}) {
#	$self->test_window($X,$xid);
#    }
}

1;

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Desktop(3pm)>, L<XDE::Desktop::Icon(3pm)>

=cut

__END__

# vim: set sw=4 tw=72:
