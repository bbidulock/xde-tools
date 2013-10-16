package XDE::Actions;
use base qw(XDE::WMH XDE::EWMH);
use strict;
use warnings;

=head1 NAME

XDE::Actions -- provides methods for controlling window manager behaviour.

=head1 DESCRIPTION

Provides a module with methods that can be used to control a window manager.
This module is meant to be used as a base for other modules.  It
supports actions performable using either EWMH or WMH specifications.

=head1 METHODS

This module provides the following methods:

=over

=cut

=item $ewmh->B<setup>

Called to set up this module.  Setting up the module consists of
registering for the proper events on the root window and establishing
root window properties.  If no window manager yet exists, root window
properties for WMH and EWMH will be obtained when one appears.

=cut

sub setup {
    my $self = shift;
    {
	# register for events on the root window
	my $X = $self->{X};
	my $root = $X->root;
	my (%attrs) = $X->GetWindowAttributes($root);
	my $mask = $attrs{your_event_mask};
	my (%mask) = (map{$_=>1}$X->unpack_event_mask($mask));
	$mask{StructureNotify} = 1;
	$mask{SubstructureNotify} = 1;
	$mask{PropertyChange} = 1;
	$mask = $X->pack_event_mask(keys %mask);
	$X->ChangeWindowAttributes($root,event_mask=>$mask);
    }

    if (defined($self->get_NET_SUPPORTING_WM_CHECK)) {
	$self->get_NET_SUPPORTED;

	$self->get_NET_ACTIVE_WINDOW;
	$self->get_NET_CLIENT_LIST;
	$self->get_NET_CLIENT_LIST_STACKING;
	$self->get_NET_CURRENT_DESKTOP;
	$self->get_NET_DESKTOP_GEOMETRY;
	$self->get_NET_DESKTOP_LAYOUT;
	$self->get_NET_DESKTOP_NAMES;
	$self->get_NET_DESKTOP_VIEWPORT;
	$self->get_NET_NUMBER_OF_DESKTOPS;
	$self->get_NET_SHOWING_DESKTOP;
	$self->get_NET_VIRTUAL_ROOTS;
	$self->get_NET_WORKAREA;
    } else {
	warn "==> No support for EWMH!";
    }

    if (defined($self->get_WIN_SUPPORTING_WM_CHECK)) {
	$self->get_WIN_PROTOCOLS;

	$self->get_WIN_AREA;
	$self->get_WIN_AREA_COUNT;
	$self->get_WIN_CLIENT_LIST;
	$self->get_WIN_DESKTOP_BUTTON_PROXY;
	$self->get_WIN_WORKAREA;
	$self->get_WIN_WORKSPACE;
	$self->get_WIN_WORKSPACE_COUNT;
	$self->get_WIN_WORKSPACE_NAMES;
    } else {
	warn "==> No support for WMH!";
    }
}

=back

=head2 Getting the window manager PID

=over

=item $ewmh->B<get_pid>() => $pid

Gets the PID (process identifier) associated with the window manager.
This should only be called after get_NET_SUPPORTING_WM_CHECK().  It uses
the window manager name to choose the method to use to determine the
window manager process id.

=cut

sub get_pid {
    my $self = shift;
    my $wmname = $self->{wmname};
    $wmname = 'unknown' unless $wmname;
    my $sub = $self->can("get_pid_\U$wmname\E");
    $self->{wmpid} = undef;
    $self->{wmpid} = &$sub($self) if $sub;
    return $self->{wmpid};
}

=item $ewmh->B<get_pid_FLUXBOX>() => $pid

L<fluxbox(1)> does not set C<_NET_WM_PID> on the support window, but
does set C<_BLACKBOX_PID(CARDINAL)> on the root window to the pid of the
window manager process.  C<_BLACKBOX_PID(CARDINAL)> should only be
checked after a successful call to get_NET_SUPPORTING_WM_CHECK(),
because, otherwise, the C<_BLACKBOX_PID> property might be hanging
around from a crashed L<fluxbox(1)> process.

=cut

sub get_pid_FLUXBOX {
    my $self = shift;
    return $self->{wmpid} if $self->{wmpid};
    $self->{wmpid} = $self->getWMRootPropertyInt('_BLACKBOX_PID');
    return $self->{wmpid};
}

=item $ewmh->B<get_pid_BLACKBOX>() => $pid

Older versions of L<blackbox(1)> did not set a pid anywhere.  For older
versions, it would therefore be the session manager's responsible to set
the child process PID associated with the window manager, either as an
X-display property or as an environment variable.  Recent versions of
L<blackbox(1)> set the C<_NET_WM_PID(CARDINAL)> property against the
C<_NET_SUPPORTING_WM_CHECK(WINDOW)> window.

=cut

sub get_pid_BLACKBOX {
    return shift->{wmpid};
}

=item $ewmh->B<get_pid_OPENBOX>() => $pid

L<openbox(1)> does not set C<_NET_WM_PID> on the check window, but does
set C<_OPENBOX_PID> on the root window.

=cut

sub get_pid_OPENBOX {
    my $self = shift;
    return $self->{wmpid} if $self->{wmpid};
    $self->{wmpid} = $self->getWMRootPropertyInt('_OPENBOX_PID');
    return $self->{wmpid};
}

=item $ewmh->B<get_pid_ICEWM>() => $pid

All versions of L<icewm(1)> correctly set C<_NET_WM_PID> on the check
window.

=cut

sub get_pid_ICEWM {
    return shift->{wmpid};
}

=item $ewmh->B<get_pid_JWM>() => $pid

Current versions of L<jwm(1)> set the C<_NET_WM_PID(CARDINAL)> property
on the check window.  Previous versions did not set the pid anywhere.

=cut

sub get_pid_JWM {
    return shift->{wmpid};
}

=item $ewmh->B<get_pid_PEKWM>() => $pid

L<pekwm(1)> is setting C<_NET_WM_PID(CARDINAL)>, but it is setting it on
the root window instead of the check window.

=cut

sub get_pid_PEKWM {
    my $self = shift;
    return $self->{wmpid} if $self->{wmpid};
    $self->{wmpid} = $self->getWMRootPropertyInt('_NET_WM_PID');
    return $self->{wmpid};
}

=item $ewmh->B<get_pid_FVWM>() => $pid

L<fvwm(1)> is not setting its process identifier anywhere: not on the
root window and not on the check window.

=cut

sub get_pid_FVWM {
    return undef;
}

=item $ewmh->B<get_pid_WMAKER>() => $pid

L<wmaker(1)> is not setting its process identifier anywhere: not on the
root window and not on the check window.

=cut

sub get_pid_WMAKER {
    return undef;
}

=item $ewmh->B<get_pid_AFTERSTEP>() => $pid

L<afterstep(1). is not settings its process identifier anywhere: not on
the root window and not on the check window.

=cut

=item $ewmh->B<get_pid_METACITY>() => $pid

L<metacity(1)> is not setting its process identifier anywhere: not on
the root window and not on the check window.

=cut

sub get_pid_METACITY {
    return undef;
}

=item $ewmh->B<get_pid_WMX>() => $pid

L<wmx(1)> is not setting its process identifier anywhere: not on the
root window and not on the check window.  Strange, because sending a
C<SIGTERM> or C<SIGINT> will cause L<wmx(1)> to exit, and sending a
C<SIGHUP> will cause it to restart.  Not providing any PID is rather odd
considering that L<wmx(1)> does not accept any root window messages for
restart or reload and can only be controlled (restarted) with signals.

=cut

sub get_pid_WMX {
    return undef;
}

=item $ewmh->B<get_pid_UNKNOWN>() => $pid

Just assume that it might be setting its pid in the
C<_NET_WM_PID(CARDINAL)> property on the check window.

=cut

sub get_pid_UNKNOWN {
    return shift->{wmpid};
}

=back

=head2 Viewport Actions

The following methods provide control over the viewport.  These methods
have no effect unless the virtual desktop is larger than the screen.

=over

=cut

=item $ewmh->B<ViewportLast>(I<$time>) => $status

Move the viewport to the last position if defined.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub ViewportLast {
    my ($self,$time) = @_;
    $time = 0 unless $time;
    if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
	if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
	    my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
	    if (defined(my $last = $self->{lastviewport})) {
		$self->set_NET_DESKTOP_VIEWPORT(@$last)
		    if $x != $last->[0] or $y != $last->[1];
	    }
	    $self->{lastviewport} = [ $x, $y ];
	}
    }
}

=item $ewmh->B<ViewportRight>(I<$time>,I<$incr>) => $status

Move the viewport to the right by C<$incr> pixels.  The default
C<$incr> is 5.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub ViewportRight {
    my ($self,$time,$incr) = @_;
    $time = 0 unless $time;
    $incr = 5 unless $incr;
    if (defined(my $geom = $self->{_NET_DESKTOP_GEOMETRY})) {
	if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
	    if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
		my $X = $self->{X};
		my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
		my ($W,$H) = @$geom;
		my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
		$x = $x + $incr;
		if ($x > $W - $w) {
		    $x = $W - $w;
		}
		$self->set_NET_DESKTOP_VIEWPORT($x,$y)
		    unless $x == $port->[0];
	    }
	}
    }
}

=item $ewmh->B<ViewportLeft>(I<$time>,I<$incr>) => $status

Move the viewport to the left by C<$incr> pixels.  The default
C<$incr> is 5.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub ViewportLeft {
    my ($self,$time,$incr) = @_;
    $time = 0 unless $time;
    $incr = 5 unless defined $incr;
    if (defined(my $geom = $self->{_NET_DESKTOP_GEOMETRY})) {
	if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
	    if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
		my $X = $self->{X};
		my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
		my ($W,$H) = @$geom;
		my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
		$x = $x - $incr;
		if ($x < 0) {
		    $x = 0;
		}
		$self->set_NET_DESKTOP_VIEWPORT($x,$y)
		    unless $x == $port->[0];
	    }
	}
    }
}

=item $ewmh->B<ViewportUp>(I<$time>,I<$incr>) => $status

Move the viewport up by C<$incr> pixels.  The default C<$incr>
is 5.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub ViewportUp {
    my ($self,$time,$incr) = @_;
    $time = 0 unless $time;
    $incr = 5 unless defined $incr;
    if (defined(my $geom = $self->{_NET_DESKTOP_GEOMETRY})) {
	if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
	    if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
		my $X = $self->{X};
		my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
		my ($W,$H) = @$geom;
		my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
		$y = $y + $incr;
		if ($y < 0) {
		    $y = 0;
		}
		$self->set_NET_DESKTOP_VIEWPORT($x,$y)
		    unless $y == $port->[1];
	    }
	}
    }
}

=item $ewmh->B<ViewportDown>(I<$time>,I<$incr>) => $status

Move the viewport down by C<$incr> pixels.  The default
C<$incr> is 5.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub ViewportDown {
    my ($self,$time,$incr) = @_;
    $time = 0 unless $time;
    $incr = 5 unless defined $incr;
    if (defined(my $geom = $self->{_NET_DESKTOP_GEOMETRY})) {
	if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
	    if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
		my $X = $self->{X};
		my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
		my ($W,$H) = @$geom;
		my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
		$y = $y + $incr;
		if ($y > $H - $h) {
		    $y = $H - $h;
		}
		$self->set_NET_DESKTOP_VIEWPORT($x,$y)
		    unless $y == $port->[1];
	    }
	}
    }
}

=back

=head2 Work Area Actions

The following methods control the work area within the desktop at which
the viewport is positioned.  These methods have no effect unless the
virtual desktop is larger than the screen.

=over

=cut

=item $ewmh->B<WorkareaLast>(I<$time>) => $status

Move the viewport to the last viewed viewport if defined.
This uses _NET_DESKTOP_VIEWPORT or _WIN_AREA, whichever is available.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub WorkareaLast {
    my ($self,$time) = @_;
    $time = 0 unless $time;
    if (defined(my $last = $self->{lastworkarea})) {
	if (defined $self->{_WIN_PROTOCOLS}) {
	    if (defined(my $port = $self->{_WIN_AREA})) {
		if (defined(my $geom = $self->{_WIN_AREA_COUNT})) {
		    $self->set_WIN_AREA(@$last);
		    $self->{lastworkarea} = $port;
		}
	    }
	}
	elsif (defined $self->{_NET_SUPPORTED}) {
	    if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
		if (defined(my $geom = $self->{_NET_DESKTOP_GEOMETRY})) {
		    if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
			my $X = $self->{X};
			my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
			my ($W,$H) = @$geom;
			my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
			my ($c,$r) = (int(($x+($w>>1))/$w),int(($y+($h>>1))/$h));
			$self->set_NET_DESKTOP_VIEWPORT($last->[0]*$w,$last->[1]*$h);
			$self->{lastworkarea} = [$c,$r];
		    }
		}
	    }
	}
    }
}

=item $ewmh->B<WorkareaNext>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the viewport to the work area C<$incr> steps next (left to
right, top to bottom).  When C<$wrap> is true, wrap to the first work
area from the last.  This uses _NET_DESKTOP_VIEWPORT or _WIN_AREA,
whichever is available.  The default C<$incr> is 1.  The default
C<$wrap> is true.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub WorkareaNext {
    my ($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr;
    $wrap = 1 unless defined $wrap;
    my $geom;
    if (defined($geom = $self->{_WIN_AREA_COUNT})) {
	if (defined(my $port = $self->{_WIN_AREA})) {
	    my ($cols,$rows) = @$geom;
	    my ($c,$r) = @$port;
	    my $last = [ $c, $r ];
	    $c += $incr;
	    while ($c >= $cols) {
		$c -= $cols;
		$r += 1;
	    }
	    if ($r < $rows or $wrap) {
		while ($r >= $rows) {
		    $r -= $rows;
		}
		$self->{lastworkarea} = $last;
		$self->set_WIN_AREA($c,$r);
	    }
	}
    }
    elsif (defined($geom = $self->{_NET_DESKTOP_GEOMETRY})) {
	if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
	    if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
		my $X = $self->{X};
		my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
		my ($W,$H) = @$geom;
		my ($cols,$rows) = (int(($W+$w-1)/$w),int(($H+$h-1)/$h));
		my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
		my ($c,$r) = (int(($x+($w>>1))/$w),int(($y+($h>>1))/$h));
		my $last = [ $c, $r ];
		$c += $incr;
		while ($c >= $cols) {
		    $c -= $cols;
		    $r += 1;
		}
		if ($r < $rows or $wrap) {
		    while ($r >= $rows) {
			$r -= $rows;
		    }
		    $x = $c*$w; $x=0 if $x<0; $x=$W-$w if $x>$W-$w;
		    $y = $r*$h; $y=0 if $y<0; $y=$H-$h if $y>$H-$h;
		    $self->{lastworkarea} = $last;
		    $self->set_NET_DESKTOP_VIEWPORT($x,$y);
		}
	    }
	}
    }
}

=item $ewmh->B<WorkareaPrev>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the viewport to the work area C<$incr> steps previous (left to
right, top to bottom).  When C<$wrap> is true, wrap to the last work
area from the first.  This uses _NET_DESKTOP_VIEWPORT or _WIN_AREA,
whichever is available.  The default C<$incr> is 1.  The default
C<$wrap> is true.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub WorkareaPrev {
    my ($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr;
    $wrap = 1 unless defined $wrap;
    my $geom;
    if (defined($geom = $self->{_WIN_AREA_COUNT})) {
	if (defined(my $port = $self->{_WIN_AREA})) {
	    my ($cols,$rows) = @$geom;
	    my ($c,$r) = @$port;
	    my $last = [ $c, $r ];
	    $c -= $incr;
	    while ($c < 0) {
		$c += $cols;
		$r -= 1;
	    }
	    if ($r >= 0 or $wrap) {
		while ($r < 0) {
		    $r += $rows;
		}
		$self->{lastworkarea} = $last;
		$self->set_WIN_AREA($c,$r);
	    }
	}
    }
    elsif (defined($geom = $self->{_NET_DESKTOP_GEOMETRY})) {
	if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
	    if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
		my $X = $self->{X};
		my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
		my ($W,$H) = @$geom;
		my ($cols,$rows) = (int(($W+$w-1)/$w),int(($H+$h-1)/$h));
		my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
		my ($c,$r) = (int(($x+($w>>1))/$w),int(($y+($h>>1))/$h));
		my $last = [ $c, $r ];
		$c -= $incr;
		while ($c < 0) {
		    $c += $cols;
		    $r -= 1;
		}
		if ($r >= 0 or $wrap) {
		    while ($r < 0) {
			$r += $rows;
		    }
		    $x = $c*$w; $x=0 if $x<0; $x=$W-$w if $x>$W-$w;
		    $y = $r*$h; $y=0 if $y<0; $y=$H-$h if $y>$H-$h;
		    $self->set_NET_DESKTOP_VIEWPORT($x,$y);
		}
	    }
	}
    }
}

=item $ewmh->B<WorkareaRight>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the viewport to the area C<$incr> steps right of the current
area (if such an area exists).  When C<$wrap> is true, wrap to the left
upon passing the rightmost workarea.  The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

This uses _NET_DESKTOP_VIEWPORT or _WIN_AREA, whichever is available.

=cut

sub WorkareaRight {
    my ($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr;
    $wrap = 0 unless defined $wrap;
    my $geom;
    if (defined($geom = $self->{_WIN_AREA_COUNT})) {
	if (defined(my $port = $self->{_WIN_AREA})) {
	    my ($cols,$rows) = @$geom;
	    my ($c,$r) = @$port;
	    my $last = [ $c, $r ];
	    $c += $incr;
	    if ($c < $cols or $wrap) {
		while ($c >= $cols) {
		    $c -= $cols;
		}
		if ($c != $last->[0]) {
		    $self->set_WIN_AREA($c,$r);
		    $self->{lastworkarea} = $last;
		}
	    }
	}
    }
    elsif (defined($geom = $self->{_NET_DESKTOP_GEOMETRY})) {
	if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
	    if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
		my $X = $self->{X};
		my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
		my ($W,$H) = @$geom;
		my ($cols,$rows) = (int(($W+$w-1)/$w),int(($H+$h-1)/$h));
		my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
		my ($c,$r) = (int(($x+($w>>1))/$w),int(($y+($h>>1))/$h));
		my $last = [ $c, $r ];
		$c += $incr;
		if ($c < $cols or $wrap) {
		    while ($c >= $cols) {
			$c -= $cols;
		    }
		    if ($c != $last->[0]) {
			$x = $c*$w; $x=0 if $x<0; $x=$W-$w if $x>$W-$w;
			$self->{lastworkarea} = $last;
			$self->set_NET_DESKTOP_VIEWPORT($x,$y);
		    }
		}
	    }
	}
    }
}

=item $ewmh->B<WorkareaLeft>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the viewport to the area C<$incr> steps left of the current
area (if such an area exists).  When C<$wrap> is true, wrap to the rigth
upon passing the leftmost workarea.  The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

This uses _NET_DESKTOP_VIEWPORT or _WIN_AREA, whichever is available.

=cut

sub WorkareaLeft {
    my ($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr;
    $wrap = 0 unless defined $wrap;
    my $geom;
    if (defined($geom = $self->{_WIN_AREA_COUNT})) {
	if (defined(my $port = $self->{_WIN_AREA})) {
	    my ($cols,$rows) = @$geom;
	    my ($c,$r) = @$port;
	    my $last = [ $c, $r ];
	    $c -= $incr;
	    if ($c >= 0 or $wrap) {
		while ($c < 0) {
		    $c += $cols;
		}
		if ($c != $last->[0]) {
		    $self->{lastworkarea} = $last;
		    $self->set_WIN_AREA($c,$r);
		}
	    }
	}
    }
    elsif (defined($geom = $self->{_NET_DESKTOP_GEOMETRY})) {
	if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
	    if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
		my $X = $self->{X};
		my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
		my ($W,$H) = @$geom;
		my ($cols,$rows) = (int(($W+$w-1)/$w),int(($H+$h-1)/$h));
		my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
		my ($c,$r) = (int(($x+($w>>1))/$w),int(($y+($h>>1))/$h));
		my $last = [ $c, $r ];
		$c -= $incr;
		if ($c >= 0 or $wrap) {
		    while ($c < 0) {
			$c += $cols;
		    }
		    if ($c != $last->[0]) {
			$x = $c*$w; $x=0 if $x<0; $x=$W-$w if $x>$W-$w;
			$self->{lastworkarea} = $last;
			$self->set_NET_DESKTOP_VIEWPORT($x,$y);
		    }
		}
	    }
	}
    }
}

=item $ewmh->B<WorkareaUp>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the viewport to the area C<$incr> stops above the current area
(if such an area exists).  When C<$wrap> is true, wrap to the bottom
upon passing the uppermost workarea.  The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

This uses _NET_DESKTOP_VIEWPORT or _WIN_AREA, whichever is available.

=cut

sub WorkareaUp {
    my ($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr;
    $wrap = 0 unless defined $wrap;
    my $geom;
    if (defined($geom = $self->{_NET_DESKTOP_GEOMETRY})) {
	if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
	    if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
		my $X = $self->{X};
		my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
		my ($W,$H) = @$geom;
		my ($cols,$rows) = (int(($W+$w-1)/$w),int(($H+$h-1)/$h));
		my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
		my ($c,$r) = (int(($x+($w>>1))/$w),int(($y+($h>>1))/$h));
		my $last = [ $c, $r ];
		if ($r > 0) {
		    $x = ($r-1)*$h;
		    $self->set_NET_DESKTOP_VIEWPORT($x,$y);
		}
	    }
	}
    }
    elsif (defined($geom = $self->{_WIN_AREA_COUNT})) {
	if (defined(my $port = $self->{_WIN_AREA})) {
	    my ($cols,$rows) = @$geom;
	    my ($c,$r) = @$port;
	    if ($c > 0) {
		$self->set_WIN_AREA($c-1,$r);
	    }
	}
    }
}

=item $ewmh->B<WorkareaDown>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the viewport to the area C<$incr> steps below the current area
(if such an area exists).  When C<$wrap> is true, wrap to the top upon
passing the bottommost workarea.  The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

This uses _NET_DESKTOP_VIEWPORT or _WIN_AREA, whichever is available.

=cut

sub WorkareaDown {
    my ($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr;
    $wrap = 0 unless defined $wrap;
    my $geom;
    if (defined($geom = $self->{_NET_DESKTOP_GEOMETRY})) {
	if (defined(my $port = $self->{_NET_DESKTOP_VIEWPORT})) {
	    if (defined(my $desk = $self->{_NET_CURRENT_DESKTOP})) {
		my $X = $self->{X};
		my ($w,$h) = ($X->width_in_pixels,$X->height_in_pixels);
		my ($W,$H) = @$geom;
		my ($cols,$rows) = (int(($W+$w-1)/$w),int(($H+$h-1)/$h));
		my ($x,$y) = ($port->[($desk<<1)+0],$port->[($desk<<1)+1]);
		my ($c,$r) = (int(($x+($w>>1))/$w),int(($y+($h>>1))/$h));
		my $last = [ $c, $r ];
		if ($c > 0) {
		    $x = ($c-1)*$w;
		    $self->set_NET_DESKTOP_VIEWPORT($x,$y);
		}
	    }
	}
    }
    elsif (defined($geom = $self->{_WIN_AREA_COUNT})) {
	if (defined(my $port = $self->{_WIN_AREA})) {
	    my ($cols,$rows) = @$geom;
	    my ($c,$r) = @$port;
	    if ($c > 0) {
		$self->set_WIN_AREA($c-1,$r);
	    }
	}
    }
}

=back

=head2 Desktop Actions

The following methods control the desktop.  These functions are normally
supported by all EWMH/WMH compliant window managers.

=over

=cut

=item $ewmh->B<DesktopLast>(I<$time>) => $status

Move the desktop to the last viewed desktop if defined.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopLast {
    my($self,$time) = @_;
    $time = 0 unless $time;
    if (defined(my $last = $self->{lastdesktop})) {
	if (defined(my $numb = $self->{_NET_NUMBER_OF_DESKTOPS})) {
	    if (defined(my $indx = $self->{_NET_CURRENT_DESKTOP})) {
		$self->{lastdesktop} = $indx;
		$self->set_NET_CURRENT_DESKTOP($last,$time);
		return 1;
	    }
	}
    }
    return 0;
}

=item $ewmh->B<DesktopNext>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the desktop to the next desktop, wrapping from the last desktop to
the first desktop.
When C<$wrap> is true, wrap to the first desktop from the last when
necessary.
The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopNext {
    my($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr and $incr > 0;
    if (defined(my $numb = $self->{_NET_NUMBER_OF_DESKTOPS})) {
	if (defined(my $indx = $self->{_NET_CURRENT_DESKTOP})) {
	    my $last = $indx;
	    $indx += $incr;
	    if ($indx < $numb or $wrap) {
		while ($indx >= $numb) { $indx -= $numb }
		$self->{lastdesktop} = $last;
		$self->set_NET_CURRENT_DESKTOP($indx,$time);
		return 1;
	    }
	}
    }
    return 0;
}

=item $ewmh->B<DesktopPrev>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the desktop to the previous desktop, wrapping from the first
desktop to the last desktop.
When C<$wrap> is true, wrap to the last desktop from the first when
necessary.
The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopPrev {
    my($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr and $incr > 0;
    if (defined(my $numb = $self->{_NET_NUMBER_OF_DESKTOPS})) {
	if (defined(my $indx = $self->{_NET_CURRENT_DESKTOP})) {
	    my $last = $indx;
	    $indx -= $incr;
	    if ($indx >= 0 or $wrap) {
		while ($indx < 0) { $indx += $numb }
		$self->{lastdesktop} = $last;
		$self->set_NET_CURRENT_DESKTOP($indx,$time);
		return 1;
	    }
	}
    }
    return 0;
}

=item $ewmh->B<DesktopMove>(I<$time>,I<$cinc>,I<$rinc>,I<$wrap>) => $status

C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopMove {
    my ($self,$time,$cinc,$rinc,$wrap) = @_;
    $time = 0 unless $time;
    if (defined(my $numb = $self->{_NET_NUMBER_OF_DESKTOPS})) {
	if (defined(my $layo = $self->{_NET_DESKTOP_LAYOUT})) {
	    if (defined(my $indx = $self->{_NET_CURRENT_DESKTOP})) {
		my $last = $indx;

		my ($dir,$cols,$rows,$start) = @$layo;
		$cols = int(($numb + ($rows-1))/$rows) if $cols == 0;
		$rows = int(($numb + ($cols-1))/$cols) if $rows == 0;
		my $total = $cols*$rows;

		my ($col,$row,$num);
		$num = $indx;
		warn "Direction is $dir";
		while (1) {
		    print STDERR "starting at $num\n";
		    print STDERR "incrementing cinc = $cinc, rinc = $rinc\n";
		    if ($dir) {
			# laid out by columns
			if ($start == &XDE::EWMH::_NET_WM_BOTTOMLEFT) {
			    $col = int($num/$rows);
			    $row = $rinc + ($rows-1)-($num-$col*$rows);
			    $col = $cinc + 0+$col;
			}
			elsif ($start == &XDE::EWMH::_NET_WM_BOTTOMRIGHT) {
			    $col = int($num/$rows);
			    $row = $rinc + ($rows-1)-($num-$col*$rows);
			    $col = $cinc + ($cols-1)-$col;
			}
			elsif ($start == &XDE::EWMH::_NET_WM_TOPRIGHT) {
			    $col = int($num/$rows);
			    $row = $rinc + 0+($num-$col*$rows);
			    $col = $cinc + ($cols-1)-$col;
			}
			else { # ($start == &XDE::EWMH::_NET_WM_TOPLEFT)
			    $col = int($num/$rows);
			    $row = $rinc + 0+($num-$col*$rows);
			    $col = $cinc + 0+$col;
			}
		    } else {
			# laid out by rows
			if ($start == &XDE::EWMH::_NET_WM_BOTTOMLEFT) {
			    $row = int($num/$cols);
			    $col = $cinc + ($cols-1)-($num-$row*$cols);
			    $row = $rinc + ($rows-1)-$row;
			}
			elsif ($start == &XDE::EWMH::_NET_WM_BOTTOMRIGHT) {
			    $row = int($num/$cols);
			    $col = $cinc + 0+($num-$row*$cols);
			    $row = $rinc + ($rows-1)-$row;
			}
			elsif ($start == &XDE::EWMH::_NET_WM_TOPRIGHT) {
			    $row = int($num/$cols);
			    $col = $cinc + ($cols-1)-($num-$row*$cols);
			    $row = $rinc + 0+$row;
			}
			else { # ($start == &XDE::EWMH::_NET_WM_TOPLEFT)
			    $row = int($num/$cols);
			    $col = $cinc + 0+($num-$row*$cols);
			    $row = $rinc + 0+$row;
			}
		    }
		    if ($col >= 0 or $wrap) { while ($col < 0) { $col += $cols } }
		    if ($col < $cols or $wrap) { while ($col >= $cols) { $col -= $cols } }
		    if ($row >= 0 or $wrap) { while ($row < 0) { $row += $rows } }
		    if ($row < $rows or $wrap) { while ($row >= $rows) { $row -= $rows } }
		    return 0 if ($col < 0 or $col >= $cols or $row < 0 or $row >= $rows);
		    if ($dir) {
			# laid out by columns
			if ($start == &XDE::EWMH::_NET_WM_BOTTOMLEFT) {
			    $num = $col*$rows+($rows-1)-$row;
			}
			elsif ($start == &XDE::EWMH::_NET_WM_BOTTOMRIGHT) {
			    $num = (($cols-1)-$col)*$rows+($rows-1)-$row;
			}
			elsif ($start == &XDE::EWMH::_NET_WM_TOPRIGHT) {
			    $num = (($cols-1)-$col)*$rows+$row;
			}
			else { # ($start == &XDE::EWMH::_NET_WM_TOPLEFT)
			    $num = $col*$rows+$row;
			}
		    } else {
			# laid out by rows
			if ($start == &XDE::EWMH::_NET_WM_BOTTOMLEFT) {
			    $num = (($rows-1)-$row)*$cols+$col;
			}
			elsif ($start == &XDE::EWMH::_NET_WM_BOTTOMRIGHT) {
			    $num = (($rows-1)-$row)*$cols+(($cols-1)-$col);
			}
			elsif ($start == &XDE::EWMH::_NET_WM_TOPRIGHT) {
			    $num = $row*$cols+(($cols-1)-$col);
			}
			else { # ($start == &XDE::EWMH::_NET_WM_TOPLEFT)
			    $num = $row*$cols+$col;
			}
		    }
		    print STDERR "calculated col = $col, row = $row, num = $num\n";
		    if ($num < $numb or $wrap) {
			if ($num >= $numb) {
			    $cinc = $cinc < 0 ? -1 : 1 if $cinc;
			    $rinc = $rinc < 0 ? -1 : 1 if $rinc;
			    print STDERR "num = $num >= numb = $numb\n";
			    next;
			}
			$indx = $num;
		    }
		    last;
		}
		if ($indx != $last) {
		    $self->{lastdesktop} = $last;
		    $self->set_NET_CURRENT_DESKTOP($indx,$time);
		    return 1;
		}
	    }
	}
    }
    return 0;

}

=item $ewmh->B<DesktopUp>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the desktop to the desktop above the current desktop, if such a
desktop exists.
When C<$wrap> is true, wrap to the bottom when necessary.
The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopUp {
    my($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr and $incr > 0;
    return $self->DesktopMove($time,0,-$incr,$wrap);
}

=item $ewmh->B<DesktopDown>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the desktop to the desktop below the current desktop, if such a
desktop exists.
When C<$wrap> is true, wrap to the top when necessary.
The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopDown {
    my($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr and $incr > 0;
    return $self->DesktopMove($time,0,$incr,$wrap);
}

=item $ewmh->B<DesktopLeft>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the desktop to the desktop to the left of the current desktop, if
such a desktop exists.
When C<$wrap> is true, wrap to the right when necessary.
The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopLeft {
    my($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr and $incr > 0;
    return $self->DesktopMove($time,-$incr,0,$wrap);
}

=item $ewmh->B<DesktopRight>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the desktop to the desktop to the right of the current desktop, if
such a desktop exists.
When C<$wrap> is true, wrap to the left when necessary.
The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopRight {
    my($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr and $incr > 0;
    return $self->DesktopMove($time,$incr,0,$wrap);
}

=item $ewmh->B<DesktopUpLeft>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the desktop to the desktop above and to the left of the current
desktop, if such a desktop exists.
When C<$wrap> is true, wrap to the bottom right when necessary.
The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopUpLeft {
    my($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr and $incr > 0;
    return $self->DesktopMove($time,-$incr,-$incr,$wrap);
}

=item $ewmh->B<DesktopUpRight>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the desktop to the desktop above and to the right of the current
desktop, if such a desktop exists.
When C<$wrap> is true, wrap to the bottom left when necessary.
The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopUpRight {
    my($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr and $incr > 0;
    return $self->DesktopMove($time,$incr,-$incr,$wrap);
}

=item $ewmh->B<DesktopDownLeft>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the desktop to the desktop below and to the left of the current
desktop, if such a desktop exists.
When C<$wrap> is true, wrap to the top right when necessary.
The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopDownLeft {
    my($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr and $incr > 0;
    return $self->DesktopMove($time,-$incr,$incr,$wrap);
}

=item $ewmh->B<DesktopDownRight>(I<$time>,I<$incr>,I<$wrap>) => $status

Move the desktop to the desktop below and to the right of the current
desktop, if such a desktop exists.
When C<$wrap> is true, wrap to the top left when necessary.
The default C<$incr> is 1.
The default C<$wrap> is false.
C<$time> is the X-Server time of the keystroke or button press
initiating the action, or 0 to indicate current time.

=cut

sub DesktopDownRight {
    my($self,$time,$incr,$wrap) = @_;
    $time = 0 unless $time;
    $incr = 1 unless $incr and $incr > 0;
    return $self->DesktopMove($time,$incr,$incr,$wrap);
}

=back

=head2 Window Manager Actions

Most window managers will reload or restart when sent a C<SIGHUP>
signal.  Most will exit gracefully when sent a C<SIGTERM> or C<SIGINT>
signal.  Some respond in various ways to C<SIGUSR1> or C<SIGUSR2>
signals.  Many window managers; however, do not set the PID of the
resource against any X-display property and therefore cannot be
signalled by a program that did not start the window manager as a child
process.

L<fvwm(1)>, L<wmaker(1)>, L<afterstep(1)>, L<metacity(1)> and L<wmx(1)>
do not set the process id of the window manager on any X-display
resource.  It is impossible to signal these window managers without them
having been launched directly as a child of the controlling process.

Some window managers provide client message definitions that allow a
C<ClientMessage> to be sent to the root window to control the window
manager.  These messages can normally perform reconfiguration, restart
and exit.  Some window managers provide more advanced or finer controls.

=over

=item L<fluxbox(1)>

L<fluxbox(1)> provides for client message control; however, the
fluxbox-remote feature must be enabled.  L<fluxbox(1)> does, however,
provide good control by sending signals and sets its PID in the
C<_BLACKBOX_PID(CARDINAL)> property on the root window.

The following client messages are defined:

=over

=back

The following signals are acted upon:

=over

=item C<SIGTERM> or C<SIGINT>

Gracefully exits the window manager.

=item C<SIGHUP>

Restarts the window manager.

=item C<SIGUSR1>

Reloads the configuration file.  The difference from C<SIGUSR2> is that
C<SIGUSR1> does not overwrite the internal style with that of the
configuration file; C<SIGUSR2> does.

=item C<SIGUSR2>

Reconfigures the window manager.

=back

=item L<blackbox(1)>

L<blackbox(1)> does not provide client message control; however, it does
provide good control by sending signals and sets its PID in the
C<_NET_WM_PID(CARDINAL)> property on the check window.

The following client messages are defined:

=over

=back

The following signals are acted upon:

=over

=item C<SIGTERM> or C<SIGINT>

Gracefully exits the window manager.

=item C<SIGHUP>

Restarts the window manager.

=item C<SIGUSR1>

Reconfigures the window manager.

=item C<SIGUSR2>

=back

=item L<openbox(1)>

L<openbox(1)> provides for client message control; however, it does
required the feature to be enabled by configuration.  L<openbox(1)>
does, however, provide good control by sending signals and sets its PID
in the C<_OPENBOX_PID(CARDINAL)> property on the root window.

The following client messages are defined:

=over

=item C<_OB_CONTROL>

This client message defines one long argument which can have once of the
following values:

=over

=item C<OB_CONTROL_RECONFIGURE> => 1

Reconfigures the L<openbox(1)> window manager.  This is sufficient for
altering styles.

=item C<OB_CONTROL_RESTART> => 2

Restarts the L<openbox(1)> window manager.  This too is sufficient for
altering styles.

=item C<OB_CONTROL_EXIT> => 3

Causes a graceful exit of the window manager.

=back

=back

The following signals are acted upon:

=over

=item C<SIGTERM> or C<SIGINT>

Gracefully exits the window manager.

=item C<SIGHUP>

Restarts the window manager.

=item C<SIGUSR1>

=item C<SIGUSR2>

=back

=item L<icewm(1)>

L<icewm(1)> provides for client message control; however, in some
versions the controls were broken.  L<icewm(1)> does provide some
control by sending signals and sets its PID in the
C<_NET_WM_PID(CARDINAL)> property on the check window.

The following client messages are defined:

=over

=item C<_ICEWM_ACTION>

This client messages has defines one long argument which can have one of
the following values:

=over

=item C<ICEWM_ACTION_NOP> => 0

Performs no funciton.

=item C<ICEWM_ACTION_PING> => 1

Was used at one time the perform a ping protocol with the window
manager; ignored now.

=item C<ICEWM_ACTION_LOGOUT> => 2

Initiates a logout from the window manager.

=item C<ICEWM_ACTION_CANCEL_LOGOUT> => 3

Cancels a logout from the window manager.

=item C<ICEWM_ACTION_REBOOT> => 4

Reboots the system.

=item C<ICEWM_ACTION_SHUTDOWN> => 5

Shuts down the system.

=item C<ICEWM_ACTION_ABOUT> => 6

Causes the I<about> window to be displayed by the window manager.

=item C<ICEWM_ACTION_WINDOWLIST> => 7

Causes the I<window list> window to be displayed by the window manager.

=item C<ICEWM_ACTION_RESTARTWM> => 8

Restarts the window manager.

=back

=back

The following signals are acted upon:

=over

=item C<SIGTERM> or C<SIGINT>

Gracefully exits the window manager.

=item C<SIGHUP>

Restarts the window manager.

=item C<SIGUSR1>

=item C<SIGUSR2>

=back

=back

The following methods control the window manager.  These functions are
specific to the window manager as there are no EWMH defined actions
associated with them; however, most window managers provide a mechanism
to perform these functions, either by sending a C<ClientMessage> to the
root window, or by sending a signal to the window manager process.

=over

=item $ewmh->B<wm_about>

Causes the window manager to display an I<about> window that describes
the window manager, its software version, and other source information.

=cut

=item $ewmh->B<wm_winlist>

Causes the window manager to display a window that describes the
available managed client windows and allows the user to select and/or
perform actions on those windows.

=cut

=item $ewmh->B<wm_reload>

Causes the window manager to reload the root menu and any other menu
specifications.

=cut

=item $ewmh->B<wm_reconfigure>

Causes the window manager to reconfigure itself from configuration files
as though it has just started.  In particular, this function affect a
style change if the style provided in configuration files has changed.

=cut

=item $ewmh->B<wm_restart>

Cauess the window manager to perform all of the actions for a shutdown
or exit, but restarts the window manager from scratch rather than
exitting to the calling process.

=cut

=item $ewmh->B<wm_exit>

Causes the window manager to unmanage all client windows and make any
perperations for shutdown, and then the process exits with a zero exit
status.

Most window managers will exit gracefully when they receive a C<SIGTERM>
or C<SIGINT> signal; however, many do not set the PID of the window
manager against any X-display resource and therefore cannot be signalled
by a program that did not start them as a child process.

Some window managers provide client message definitions that allow a
C<ClientMessage> to be sent to the root window to control the window
manager.  
=cut

=item $ewmh->B<wm_setstyle>(I<style>)

Causes the window manager to set the new style, I<style>, and then
reconfigures the window manager.

=cut

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::X11(3pm)>, L<XDE::EWMH(3pm)>, L<XDE::WMH(3pm)>.

=cut

# vim: sw=4 tw=72
