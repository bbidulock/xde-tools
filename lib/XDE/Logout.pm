package XDE::Logout;
use base qw(XDE::Gtk2);
use Glib qw(TRUE FALSE);
use Gtk2;
use Net::DBus;
#use Net::DBus::GLib;
use strict;
use warnings;

=head1 NAME

XDE::Logout - log out of an XDE session or boot computer

=head1 SYNOPSIS

 use XDE::Logout;

 my $xde = XDE::Logout->new(%OVERRIDES,\%ops);

 $xde->getenv;
 $xde->init;

 my $choice = $xde->logout;
 exit(0) if $choice eq 'Cancel';
 my $action = "action_$choice";
 my $sub = $xde->can($action)
     or die "Cannot grok response '$choice'";
 &sub($xde);
 exit(0);

=head1 DESCRIPTION

B<XDE::Logout> provides a module to perform logout functions for the X
Desktop Environment.  When invoked, it presents the user with a dialog
that provides options such a rebooting, logging out and shutting down.

XDE::Logout used the C<login1> service provided by L<systemd(1)> on the
Dbus to determine whether power functions are available and presents a
modal window for user selection.  Upon selection either the C<login1>
service is invoked for a power function, the user is logged out, or the
logout procedure is cancelled.

=head1 METHODS

XDE::Logout provides the following methods:

=over

=item $xde = XDE::Logout->B<new>(I<%OVERRIDES>,\I<%ops>)

Creates a new XDE::Logout instance and returns a blessed reference.  The
XDE::Logout module uses L<XDE::Context(3pm)> at a base, and the
I<%OVERRIDES> are simply passed to the L<XDE::Context(3pm)> module.
When an option hash, I<%ops>, is passed to the method, it is initialized
with default option values.
See L</OPTIONS> for details.

=over

=back

=cut

sub new {
    return XDE::Gtk2::new(@_);
}

=item $xde->B<defaults>()

Sets the defaults for this module only.  This method determines the
default value of the C<prompt> option.  The default for the C<banner>
option is determined by L<XDE::Context(3pm)>.

=cut

sub defaults {
    my $self = shift;
    $self->{XDE_LOGOUT_PROMPT} = $self->{ops}{prompt};
    unless ($self->{XDE_LOGOUT_PROMPT}) {
	my $session;
	$session = "\U$self->{XDG_VENDOR_ID}\E" if $self->{XDG_VENDOR_ID};
	$session = $self->{XDG_CURRENT_DESKTOP} unless $session;
	$session = 'XDE' unless $session;
	$self->{XDE_LOGOUT_PROMPT} = "Logout of <b>$session</b> session?";
    }
    $self->{ops}{prompt} = $self->{XDE_LOGOUT_PROMPT}
	unless $self->{ops}{prompt};
}

# =item $xde->B<lxsession_check>()
# 
# An internal method to determine whether we have been invoked under a
# session running L<lxsession(1)>.  When that is the case, we simply
# execute L<lxsession-logout(1)> with the appropriate parameters for
# branding.  In that case, this method does not return (executes
# L<lxsession-logout(1)> directly).  Otherwise the method returns.
# This method is currently unused and is deprecated.  C<$xde-E<gt>init>
# must be called before this method.
# 
# =cut

sub lxsession_check {
    my $self = shift;
    my %ops = %{$self->{ops}};
    if ($ENV{_LXSESSION_PID}) {
        # we might have mistakenly been called by an lxpanel that is running
        # under lxsession(1).  If that is the case, we can do the right
        # thing.
        $ops{desktop} = $ENV{XDG_CURRENT_DESKTOP} if $ENV{XDG_CURRENT_DESKTOP};
        $ops{desktop} = 'LXDE' unless $ops{desktop};

        # Let's really check if there is a true _LXSESSION running:
        if (my $atom = Gtk2::Gdk::Atom->new(_LXSESSION=>TRUE)) {
            if (my $window = Gtk2::Gdk::Selection->owner_get($atom)) {
                # just call lxsession-logout directly
                my @args = ('lxsession-logout');
                push @args, '--banner', $ops{banner} if $ops{banner};
                push @args, '--side',   $ops{side}   if $ops{side};
                push @args, '--prompt', $ops{prompt} if $ops{prompt};
                exec(@args) or exit(2);
            }
        }
    }
    return;
}

sub test_lock_screen_program {
    my $self = shift;
    unless ($self->{ops}{lockscreen}) {
	foreach my $prog (qw(xlock slock)) {
	    foreach my $dir (split(/:/,$ENV{PATH})) {
		my $locker = "$dir/$prog";
		if (-x $locker) {
		    if ($prog eq 'xlock') {
			$self->{ops}{lockscreen} = "$locker -mode blank";
		    } else {
			$self->{ops}{lockscreen} = $locker;
		    }
		    $self->{can}{LockScreen} = 'yes';
		    print STDERR "Got $self->{ops}{lockscreen}\n"
			if $self->{ops}{verbose};
		    return;
		} else {
		    print STDERR "No $locker\n"
			if $self->{ops}{verbose};
		}
	    }
	}
    }
    $self->{can}{LockScreen} = 'yes';
    return;
}

# =item $xde->B<test_power_functions>()
# 
# Internal method that uses Net::DBus and the C<login1> service to test
# for available power functions.  The results of the test are stored in
# a hashref, C<$xde-E<gt>{can}>, indexed by power function name:
# PowerOff, Reboot, Suspend, Hibernate and HybridSleep.
# 
# =cut

sub test_power_functions {
    my $self = shift;
    $self->{dbus}{bus} = Net::DBus->system();
    $self->{dbus}{srv} = $self->{dbus}{bus}->get_service('org.freedesktop.login1');
    $self->{dbus}{obj} = $self->{dbus}{srv}->get_object('/org/freedesktop/login1',
							 'org.freedesktop.login1.Manager');
    my $result;
    $self->{can}{PowerOff}    = $result if $result = $self->{dbus}{obj}->CanPowerOff();
    $self->{can}{Reboot}      = $result if $result = $self->{dbus}{obj}->CanReboot();
    $self->{can}{Suspend}     = $result if $result = $self->{dbus}{obj}->CanSuspend();
    $self->{can}{Hibernate}   = $result if $result = $self->{dbus}{obj}->CanHibernate();
    $self->{can}{HybridSleep} = $result if $result = $self->{dbus}{obj}->CanHybridSleep();
}

# =item $xde->B<grabbed_window>(I<$window>)
# 
# Internal method to transform window, I<$window>, into a window that has
# a grab on the pointer on a Gtk2 window and restricts pointer movement to
# the window boundary.  I<$window> is a L<Gtk2::Window(3pm)>.
# 
# =cut

sub grabbed_window {
    my $self = shift;
    my $w = shift;
    my $win = $w->window;
    $win->set_override_redirect(TRUE);
    $win->set_focus_on_map(TRUE);
    $win->set_accept_focus(TRUE);
    $win->set_keep_above(TRUE);
    $win->set_modal_hint(TRUE);
    $win->stick;
    $win->deiconify;
    $win->show;
    $win->focus(Gtk2::GDK_CURRENT_TIME);
    Gtk2::Gdk->keyboard_grab($win,TRUE,Gtk2::GDK_CURRENT_TIME);
    Gtk2::Gdk->pointer_grab($win,TRUE, [
	'pointer-motion-mask',
	'pointer-motion-hint-mask',
	#'button-motion-mask',
	#'button1-motion-mask',
	#'button2-motion-mask',
	#'button3-motion-mask',
	#'button-press-mask',
	#'button-release-mask',
	#'enter-notify-mask',
	#'leave-notify-mask',
    ], $win,undef,Gtk2::GDK_CURRENT_TIME);
    unless (Gtk2::Gdk::Display->get_default->pointer_is_grabbed) {
	print STDERR "pointer is NOT grabbed\n";
    }
    unless (Gtk2::Gdk->pointer_is_grabbed) {
	print STDERR "pointer is NOT grabbed\n";
    }
}

# =item $xde->B<ungrabbed_window>(I<$window>)
# 
# Internal method to tranform window, I<$window>, back into a regular
# window, releasing the pointer and keyboard grab and motion restriction.
# I<$window> is a L<Gtk2::Window(3pm)> that previously had the
# B<grabbed_window> method called on it.
# 
# =cut

sub ungrabbed_window {
    my $self = shift;
    my $w = shift;
    my $win = $w->window;
    Gtk2::Gdk->pointer_ungrab(Gtk2::GDK_CURRENT_TIME);
    Gtk2::Gdk->keyboard_ungrab(Gtk2::GDK_CURRENT_TIME);
    $win->hide;
}

# =item $xde->B<areyousure>(I<$window>,I<$message>) => $result {yes|no}
# 
# Simply dialog prompting the user with a yes/no question; however, the
# window, I<$window>, is one that was previously grabbed using
# B<grabbed_window>.  This method hands the focus grab to the dialog and
# back to the window on exit.  Returns the response to the dialog.
# 
# =cut

sub areyousure {
    my $self = shift;
    my ($w,$msg) = @_;
    $self->ungrabbed_window($w);
    my $d = Gtk2::MessageDialog->new($w,'modal','question','yes-no',$msg);
    $d->set_title('Are you sure?');
    $d->set_modal(TRUE);
    $d->set_gravity('center');
    $d->set_type_hint('splashscreen');
    $d->set_skip_pager_hint(TRUE);
    $d->set_skip_taskbar_hint(TRUE);
    $d->set_position('center-always');
    $d->show_all;
    $d->show_now;
    $self->grabbed_window($d);
    my $result = $d->run;
    $self->ungrabbed_window($d);
    $d->destroy;
    $self->grabbed_window($w) unless $result eq 'yes';
    return $result;
}

# =item $xde->B<PowerOff>(I<$window>)
# 
# =cut

sub PowerOff {
    my $self = shift;
    my $w = shift;
    print STDERR "Power Off clicked!\n" if $self->{ops}{verbose};
    my $result = $self->areyousure($w, "Are you sure you want to power off the computer?");
    $self->main_quit('PowerOff') if $result eq 'yes';
    return Gtk2::EVENT_PROPAGATE;
}

# =item $xde->B<Reboot>(I<$window>)
# 
# =cut

sub Reboot {
    my $self = shift;
    my $w = shift;
    print STDERR "Reboot clicked!\n" if $self->{ops}{verbose};
    my $result = $self->areyousure($w, "Are you sure you want to reboot the computer?");
    $self->main_quit('Reboot') if $result eq 'yes';
    return Gtk2::EVENT_PROPAGATE;
}

# =item $xde->B<Suspend>(I<$window>)
# 
# =cut

sub Suspend {
    my $self = shift;
    my $w = shift;
    print STDERR "Suspend clicked!\n" if $self->{ops}{verbose};
    my $result = $self->areyousure($w, "Are you sure you want to suspend the computer?");
    $self->main_quit('Suspend') if $result eq 'yes';
    return Gtk2::EVENT_PROPAGATE;
}

# =item $xde->B<Hibernate>(I<$window>)
# 
# =cut

sub Hibernate {
    my $self = shift;
    my $w = shift;
    print STDERR "Hibernate clicked!\n" if $self->{ops}{verbose};
    my $result = $self->areyousure($w, "Are you sure you want to hibernate the computer?");
    $self->main_quit('Hibernate') if $result eq 'yes';
    return Gtk2::EVENT_PROPAGATE;
}

# =item $xde->B<HybridSleep>(I<$window>)
# 
# =cut

sub HybridSleep {
    my $self = shift;
    my $w = shift;
    print STDERR "Hybrid Sleep clicked!\n" if $self->{ops}{verbose};
    my $result = $self->areyousure($w, "Are you sure you want to hybrid sleep the computer?");
    $self->main_quit('HybridSleep') if $result eq 'yes';
    return Gtk2::EVENT_PROPAGATE;
}

# =item $xde->B<SwitchUser>(I<$window>)
# 
# =cut

sub SwitchUser {
    my $self = shift;
    my $w = shift;
    print STDERR "Switch User clicked!\n" if $self->{ops}{verbose};
    $self->main_quit('SwitchUser');
    return Gtk2::EVENT_PROPAGATE;
}

# =item $xde->B<SwitchDesk>(I<$window>)
# 
# =cut

sub SwitchDesk {
    my $self = shift;
    my $w = shift;
    print STDERR "Switch Desktop clicked!\n" if $self->{ops}{verbose};
    $self->main_quit('SwitchDesk');
    return Gtk2::EVENT_PROPAGATE;
}

# =item $xde->B<LockScreen>(I<$window>)
# 
# =cut

sub LockScreen {
    my $self = shift;
    my $w = shift;
    print STDERR "Lock Screen clicked!\n" if $self->{ops}{verbose};
    $self->main_quit('LockScreen');
    return Gtk2::EVENT_PROPAGATE;
}

# =item $xde->B<Logout>(I<$window>)
# 
# =cut

sub Logout {
    my $self = shift;
    my $w = shift;
    print STDERR "Logout clicked!\n" if $self->{ops}{verbose};
    $self->main_quit('Logout');
    return Gtk2::EVENT_PROPAGATE;
}

# =item $xde->B<Restart>(I<$window>)
# 
# =cut

sub Restart {
    my $self = shift;
    my $w = shift;
    print STDERR "Restart clicked!\n" if $self->{ops}{verbose};
    $self->main_quit('Restart');
    return Gtk2::EVENT_PROPAGATE;
}

# =item $xde->B<Cancel>(I<$window>)
# 
# =cut

sub Cancel {
    my $self = shift;
    my $w = shift;
    print STDERR "Cancel clicked!\n" if $self->{ops}{verbose};
    $self->main_quit('Cancel');
    return Gtk2::EVENT_PROPAGATE;
}

=item $xde->B<logout>() => $choice

Provides a modal choice window of the available logout and power
selections and returns the scalar choice made by the operator.
This method does not invoke the choice.  The B<action_$choice>
methods provide a mechanism to actuate the choice.

=cut

sub logout {
    my ($self) = @_;
    my %ops = %{$self->{ops}};

    my $can = $self->{can} = {
	PowerOff    => 'na',
	Reboot	    => 'na',
	Suspend	    => 'na',
	Hibernate   => 'na',
	HybridSleep => 'na',
	SwitchUser  => 'na',
	SwitchDesk  => 'na',
	LockScreen  => 'na',
	Logout	    => 'yes',
	Restart	    => 'na',
	Cancel	    => 'yes',
    };
    my $tip = $self->{tip} = {
	PowerOff    => 'Shutdown the computer.',
	Reboot	    => 'Reboot the computer.',
	Suspend	    => 'Place computer in suspend mode.',
	Hibernate   => 'Place computer in hibernation mode.',
	HybridSleep => 'Place computer in hybrid sleep mode.',
	SwitchUser  => 'Switch users.',
	SwitchDesk  => 'Switch the current desktop session.',
	LockScreen  => 'Lock the screen.',
	Logout	    => 'Log out of the current session.',
	Restart	    => 'Restart current desktop session.',
	Cancel	    => 'Cancel and return to current session.',
    };
    eval { $self->test_power_functions(); };
    eval { $self->test_lock_screen_program(); };

    foreach (keys %$can) {
	if ($can->{$_} eq 'na') {
	    $tip->{$_} .= "\nFunction not available.";
	    $tip->{$_} .= "\nCan value was '$can->{$_}'."
		if $ops{verbose};
	}
	elsif ($can->{$_} eq 'challenge') {
	    #$tip->{$_} .= "\nFunction not permitted.";
	    $tip->{$_} .= "\nCan value was '$can->{$_}'."
		if $ops{verbose};
	}
	else {
	    $tip->{$_} .= "\nCan value was '$can->{$_}'."
		if $ops{verbose};
	}
    }
    if ($self->{ops}{verbose}) {
	foreach (qw(PowerOff Reboot Suspend Hibernate HybridSleep)) {
	    print STDERR "$_: $can->{$_}\n";
	}
    }
    return $self->make_logout_choice;
}

sub make_logout_choice {
    my $self = shift;
    my %ops = %{$self->{ops}};
    my ($w,$h,$f,$v,$s,$l,$bb);
    $w = Gtk2::Window->new('toplevel');
    $w->signal_connect(delete_event=>sub{
	    $self->main_quit('Cancel');
	    Gtk2::EVENT_STOP;
    });
    $w->set_wmclass('xde-logout','Xdg-logout');
    $w->set_title('XDG Session Logout');
    $w->set_modal(TRUE);
    $w->set_gravity('center');
    $w->set_type_hint('splashscreen');
    $w->set_icon_name('xdm');
    $w->set_border_width(15);
    $w->set_skip_pager_hint(TRUE);
    $w->set_skip_taskbar_hint(TRUE);
    $w->set_position('center-always');
# =======================
    $w->fullscreen;
    $w->set_decorated(FALSE);
    my $screen = Gtk2::Gdk::Screen->get_default;
    my ($width,$height) = ($screen->get_width,$screen->get_height);
    $w->set_default_size($width,$height);
    $w->set_app_paintable(TRUE);
    my $pixbuf = Gtk2::Gdk::Pixbuf->get_from_drawable(
	    Gtk2::Gdk->get_default_root_window,
	    undef, 0, 0, 0, 0, $width, $height);
    my $a = Gtk2::Alignment->new(0.5,0.5,0.0,0.0);
    $w->add($a);
    my $e = Gtk2::EventBox->new;
    $a->add($e);
    $e->set_size_request(-1,-1);
    $w->signal_connect(expose_event=>sub{
	    my ($w,$e,$p) = @_;
	    my $cr = Gtk2::Gdk::Cairo::Context->create($w->window);
	    $cr->set_source_pixbuf($p,0,0);
	    $cr->paint;
	    my $color;
#	    $color = Gtk2::Gdk::Color->new(0x72*257,0x9f*257,0xcf*257,0);
#	    $cr->set_source_color($color);
#	    $cr->paint_with_alpha(0.6);
	    $color = Gtk2::Gdk::Color->new(0,0,0,0);
	    $cr->set_source_color($color);
	    $cr->paint_with_alpha(0.7);
    },$pixbuf);
    $v = Gtk2::VBox->new(FALSE,0);
    $v->set_border_width(15);
    $e->add($v);
# =======================
    $h = Gtk2::HBox->new(FALSE,5);
    $v->add($h);
    if ($ops{banner}) {
	$f = Gtk2::Frame->new;
	$f->set_shadow_type('etched-in');
	$h->pack_start($f,FALSE,FALSE,0);
	$v = Gtk2::VBox->new(FALSE,5);
	$v->set_border_width(10);
	$f->add($v);
	$s = Gtk2::Image->new_from_file($ops{banner});
	$v->add($s);
    }
    $f = Gtk2::Frame->new;
    $f->set_shadow_type('etched-in');
    $h->pack_start($f,TRUE,TRUE,0);
    $v = Gtk2::VBox->new(FALSE,5);
    $v->set_border_width(10);
    $f->add($v);
    $l = Gtk2::Label->new;
    $l->set_markup($ops{prompt});
    $v->pack_start($l,FALSE,TRUE,0);
    $bb = Gtk2::VButtonBox->new;
    $bb->set_border_width(5);
    $bb->set_layout_default('spread');
    $bb->set_spacing_default(5);
    $v->pack_end($bb,FALSE,TRUE,0);
    my (@b,$b,$i);
    my @data = (
	[ 'system-shutdown', 'gnome-session-halt', 'gtk-stop', 'Power Off',
	  sub{ $self->PowerOff($w) }, $self->{can}{PowerOff}, $self->{tip}{PowerOff},
	],
	[ 'system-reboot', 'gnome-session-reboot', 'gtk-refresh', 'Reboot',
	  sub{ $self->Reboot($w) }, $self->{can}{Reboot}, $self->{tip}{Reboot},
	],
	[ 'system-suspend', 'gnome-session-suspend', 'gtk-save', 'Suspend',
	  sub{ $self->Suspend($w) }, $self->{can}{Suspend}, $self->{tip}{Suspend},
	],
	[ 'system-suspend-hibernate', 'gnome-session-hibernate', 'gtk-save-as', 'Hibernate',
	  sub{ $self->Hibernate($w) }, $self->{can}{Hibernate}, $self->{tip}{Hibernate},
	],
	[ 'system-suspend-hibernate', 'gnome-session-hibernate', 'gtk-revert-to-saved', 'Hybrid Sleep',
	  sub{ $self->HybridSleep($w) }, $self->{can}{HybridSleep}, $self->{tip}{HybridSleep},
	],
	[ 'system-switch-user', 'gnome-session-switch', 'gtk-quit', 'Switch User',
	  sub{ $self->SwitchUser($w) }, $self->{can}{SwitchUser}, $self->{tip}{SwitchUser},
	],
	[ 'system-switch-user', 'gnome-session-switch', 'gtk-quit', 'Switch Desktop',
	  sub{ $self->SwitchDesk($w) }, $self->{can}{SwitchDesk}, $self->{tip}{SwitchDesk},
	],
	[ 'gtk-refresh', 'gtk-refresh', 'gtk-redo', 'Restart',
	  sub{ $self->Restart($w) }, $self->{can}{Restart}, $self->{tip}{Restart},
	],
	[ 'system-lock-screen', 'gnome-lock-screen', 'gtk-missing-image', 'Lock Screen',
	  sub{ $self->LockScreen($w) }, $self->{can}{LockScreen}, $self->{tip}{LockScreen},
	],
	[ 'system-log-out', 'gnome-logout', 'gtk-quit', 'Logout',
	  sub{ $self->Logout($w) }, $self->{can}{Logout}, $self->{tip}{Logout},
	],
	[ 'gtk-cancel', 'gtk-cancel', 'gtk-cancel', 'Cancel',
	  sub{ $self->Cancel($w) }, $self->{can}{Cancel}, $self->{tip}{Cancel},
	],
    );

    foreach (@data) {
	 #next unless $_->[5] eq 'yes';
	$b = Gtk2::Button->new;
	$b->set_border_width(2);
	$b->set_image_position('left');
	$b->set_alignment(0.0,0.5);
	$i = $self->get_icon('button',$_->[2],$_->[0],$_->[1]);
	$b->set_image($i);
	$b->set_label($_->[3]);
	$b->signal_connect(clicked=>$_->[4]);
	$b->set_sensitive(FALSE) unless $_->[5] =~ m{^(yes|challenge)$};
	$b->set_tooltip_text($_->[6]) if $_->[6];
	$bb->pack_start($b,TRUE,TRUE,5); push @b,$b;
    }
#   $w->set_default_size(-1,350);
    $w->show_all;
    $w->show_now;
    $w->signal_connect('grab-broken-event'=>sub{
	    my ($w,$ev) = @_;
	    print STDERR "Grab broken event!\n";
    });

    #$w->grab_focus;
    #$w->has_grab(TRUE);

    #$b[-1]->grab_focus;

    $self->grabbed_window($w);
    my $return = $self->main;
    $w->destroy;
    return $return;
}

=item $xde->B<action_PowerOff>()

Requests that the C<login1> service power off the computer.  B<logout>
must be called first to establish the DBus connection.

=cut

sub action_PowerOff {
    shift->{dbus}{obj}->PowerOff(TRUE);
}

=item $xde->B<action_Reboot>()

Requests that the C<login1> service reboot the computer.  B<logout> must
be called first to establish the DBus connection.

=cut

sub action_Reboot {
    shift->{dbus}{obj}->Reboot(TRUE);
}

=item $xde->B<action_Suspend>()

Requests that the C<login1> service suspend the computer.  B<logout>
must be called first to establish the DBus connection.

=cut

sub action_Suspend {
    shift->{dbus}{obj}->Suspend(TRUE);
}

=item $xde->B<action_Hibernate>()

Requests that the C<login1> service hibernate the computer.  B<logout>
must be called first to establish the DBus connection.

=cut

sub action_Hibernate {
    shift->{dbus}{obj}->Hibernate(TRUE);
}

=item $xde->B<action_HybridSleep>()

Requests that the C<login1> service hybrid sleep the computer.
B<logout> must be called first to establish the DBus connection.

=cut

sub action_HybridSleep {
    shift->{dbus}{obj}->HybridSleep(TRUE);
}

=item $xde->B<action_SwitchUser>()

Currently unimplemented.

=cut

sub action_SwitchUser {
    print STDERR "Unimplemented DoSwitchUser\n";
}

=item $xde->B<action_SwitchDesk>()

Currently unimplemented.

=cut

sub action_SwitchDesk {
    print STDERR "Unimplemented DoSwitchDesk\n";
}

=item $xde->B<action_LockScreen>()

Currently unimplemented.

=cut

sub action_LockScreen {
    my $self = shift;
    if ($self->{ops}{lockscreen}) {
	system("$self->{ops}{lockscreen} &");
    } else {
	warn "No screen locking program defined";
    }
}

=item $xde->B<action_Logout>()

Performs a complicated sequence of checks to log out of the current
session.  This method supports more than just XDE sessions
(L<lxsession(1)> and other sessions are supported).

See L</BEHAVIOUR> for details.

=cut

sub action_Logout {
    my $self = shift;
    # check for _LXSESSION_PID _FBSESSION_PID XDG_SESSION_PID
    #   when one of these exists, logging out of the session consists of
    #   sending a TERM signal to the PID concerned.  When none of these
    #   exist, then we can check to see if there is information on the
    #   root window.
    if ($ENV{XDG_SESSION_PID}) {
	# NOTE: we might actually be killing ourselves here
	kill 15, $ENV{XDG_SESSION_PID};
	return;
    }
    if ($ENV{_FBSESSION_PID}) {
	# NOTE: we might actually be killing ourselves here
	kill 15, $ENV{_FBSESSION_PID};
	return;
    }
    if ($ENV{_LXSESSION_PID}) {
	# NOTE: we might actually be killing ourselves here
	kill 15, $ENV{_LXSESSION_PID};
	return;
    }

    my $mgr = Gtk2::Gdk::DisplayManager->get;
    my $dpy = $mgr->get_default_display;
    my $scn = $dpy->get_default_screen;
    my $root = $scn->get_root_window;

    # When the _BLACKBOX_PID atom is set on the desktop, that is the PID
    #	of the FLUXBOX window manager: yeah, I know, fluxbox sets
    #	_BLACKBOX_PID an nobody else does.
    if (my $atom = Gtk2::Gdk::Atom->new(_BLACKBOX_PID=>TRUE)) {
	my ($type,$format,$data) = $root->property_get($atom,undef,0,1,FALSE);
	if (defined $type) {
	    print STDERR "_BLACKBOX_PID(",$type->name,") = ($format) $data\n" if $self->{ops}{verbose};
	    # NOTE: we might actually be killing ourselves here
	    kill 15, $data;
	    return;
	}
    }
    # Openbox sets _OPENBOX_PID atom the the desktop.  It also sets
    #   _OB_THEME to the theme name, _OB_CONFIG_FILE to the
    #   configuration file in use, and _OB_VERSION to the version of
    #   openbox. _NET_SUPPORTING_WM_CHECK is set to the WM window,
    #   which has a _NET_WM_NAME set to "Openbox".
    if (my $atom = Gtk2::Gdk::Atom->new(_OPENBOX_PID=>TRUE)) {
	my ($type,$format,$data) = $root->property_get($atom,undef,0,1,FALSE);
	if (defined $type) {
	    print STDERR "_OPENBOX_PID(",$type->name,") = ($format) $data\n" if $self->{ops}{verbose};
	    # NOTE: we might actually be killing ourselves here
	    kill 15, $data;
	    return;
	}
    }
    # IceWM-Session does not set environment variables nor elements on
    #   the root.  _NET_SUPPORTING_WM_CHECK is set to the WM window,
    #   which has a _NET_WM_NAME set to "IceWM 1.3.7 (Linux 3.4.0-1-ARCH/x86_64)"
    #   but also has _NET_WM_PID set to the pid of "icewm".  Note that
    #   this is not the pid of icewm-session when that is running.
    if (my $atom = Gtk2::Gdk::Atom->new(_NET_SUPPORTING_WM_CHECK=>TRUE)) {
	my ($type,$format,$data) = $root->property_get($atom,undef,0,1,FALSE);
	if (defined $type) {
	    printf STDERR "_NET_SUPPORTING_WM_CHECK(",$type->name,") = ($format) 0x%08x\n", $data if $self->{ops}{verbose};
	    if (my $win = Gtk2::Gdk::Window->foreign_new($data)) {
		if ($atom = Gtk2::Gdk::Atom->new(_NET_WM_NAME=>TRUE)) {
		    ($type,$format,$data) = $win->property_get($atom,undef,0,4096,FALSE);
		    if (defined $type) {
			my @text = Gtk2::Gdk->text_property_to_utf8_list($type,$format,$data);
			print STDERR "_NET_WM_NAME(",$type->name,") = ($format) ",join(',',@text),"\n" if $self->{ops}{verbose};
		    }
		}
		if ($atom = Gtk2::Gdk::Atom->new(_NET_WM_PID=>TRUE)) {
		    ($type,$format,$data) = $win->property_get($atom,undef,0,1,FALSE);
		    if (defined $type) {
			print STDERR "_NET_WM_PID(",$type->name,") = ($format) $data\n" if $self->{ops}{verbose};
			kill 15, $data;
			return;
		    }
		}
	    }
	}
    }
    print STDERR "Cannot find session or window manager PID!\n";
    # Blackbox does not set _BLACKBOX_PID on the desktop.
    #	_NET_SUPPORTING_WM_CHECK is set to the WM window, which has a
    #	_NET_WM_NAME set to "Blackbox".
    # WindowMaker sets _WINDOWMAKER_WM_PROTOCOLS to atoms.  It sets
    #   environment variables: WMAKER_BIN_NAME to /usr/bin/wmaker, it
    #   sets WINDOWID and WINDOWPATH as well as
    #   WRASTER_COLOR_RESOLUTION0.  It does set on the root the
    #   _NET_SUPPORTING_WM_CHECK to the WM window, which does not
    #   provide the pid or even the _NET_WM_NAME.
    #
    return;
}

=back

=cut

1;

__END__

=head1 OPTIONS

XDE::Logout recognizes the following options passed to B<new>:

=over

=item banner => $banner

Specifies the logo to display as a banner.  When unspecified, defaults
to the banner determined using XDG environment variables.

=item prompt => $prompt

Specifies the logout prompt to display (e.g. 'Logout of FLUXBOX
session?').  When unspecified, the default is determined using XDG
environment variables.  This string can use pango markup.

=back

See also L<XDE::Context(3pm)> for additional options interpreted by the
base class.

=head1 BEHAVIOUR

The behaviour of the B<action_Logout>() method is as follows:

=over

=item 1.

Check for B<XDG_SESSION_PID>, B<_FBSESSION_PID>, B<_LXSESSION_PID>
environment variables.

When any of these environment variables exist, the PID is sent a
C<SIGTERM> and the logout is considered complete.  This will normally
terminate an XDE session or an L<lxsession(1)>.

=item 2.

Check for B<_BLACKBOX_PID> and B<_OPENBOX_PID> display properties.

When any of these properties exist, the PID is sent a C<SIGTERM> and the
logout is considered complete.  (The B<_BLACKBOX_PID> is actually for
L<fluxbox(1)> not L<blackbox(1)>).

=item 3.

Find the window manager using the B<_NET_SUPPORTING_WM_CHECK> property
and locate the B<_NET_WM_PID> property of the window manager.

When this property is found, the PID is sent a C<SIGTERM> and the logout
is considered complete.

=back

Otherwise, the logout procedure will fail and a diagnostic message is
displayed on standard output.

The procedure can be used to exit a L<fluxbox(1)>, L<blackbox(1)>,
L<openbox(1)> or L<icewm(1)> window manager when no session is
available.

Note that this procedure has little chance of operating successfully
when this method is invoked on a host other than the one on which the
session or window manager was launched.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72
