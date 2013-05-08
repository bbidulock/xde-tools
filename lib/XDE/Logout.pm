package XDE::Logout;
require XDE::Context;
use base qw(XDE::Context);
use Glib qw(TRUE FALSE);
use Gtk2;
use Net::DBus;
#use Net::DBus::GLib;
use strict;
use warnings;

=head1 NAME

XDE::Logout - log out of an XDE session or boot computer

=head1 SYNOPSIS

 require XDE::Logout;

 my $xde = XDE::Logout->new();
 my $choice = $xde->logout(%ops);
 exit(0) if $choice eq 'Cancel';
 my $action = "Do$choice";
 if ($xde->can($action)) {
	 $xde->$action();
	 exit(0);
 }
 die "Cannot grok response '$choice'";

=head1 DESCRIPTION

=cut

sub new {
    my $self = XDE::Context::new(@_);
    $self->getenv() if $self;
    return $self;
}

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

sub ungrabbed_window {
    my $self = shift;
    my $w = shift;
    my $win = $w->window;
    Gtk2::Gdk->pointer_ungrab(Gtk2::GDK_CURRENT_TIME);
    Gtk2::Gdk->keyboard_ungrab(Gtk2::GDK_CURRENT_TIME);
    $win->hide;
}

sub areyousure {
    my $self = shift;
    my ($w,$msg) = @_;
    ungrabbed_window($w);
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

sub PowerOff {
    my $self = shift;
    my $w = shift;
    print STDERR "Power Off clicked!\n" if $self->{ops}{verbose};
    my $result = $self->areyousure($w, "Are you sure you want to power off the computer?");
    if ($result eq 'yes') {
	$self->{ops}{choice} = 'PowerOff';
	Gtk2::main_quit;
    }
    return Gtk2::EVENT_PROPAGATE;
}
sub Reboot {
    my $self = shift;
    my $w = shift;
    print STDERR "Reboot clicked!\n" if $self->{ops}{verbose};
    my $result = $self->areyousure($w, "Are you sure you want to reboot the computer?");
    if ($result eq 'yes') {
	$self->{ops}{choice} = 'Reboot';
	Gtk2::main_quit;
    }
    return Gtk2::EVENT_PROPAGATE;
}
sub Suspend {
    my $self = shift;
    my $w = shift;
    print STDERR "Suspend clicked!\n" if $self->{ops}{verbose};
    my $result = $self->areyousure($w, "Are you sure you want to suspend the computer?");
    if ($result eq 'yes') {
	$self->{ops}{choice} = 'Suspend';
	Gtk2::main_quit;
    }
    return Gtk2::EVENT_PROPAGATE;
}
sub Hibernate {
    my $self = shift;
    my $w = shift;
    print STDERR "Hibernate clicked!\n" if $self->{ops}{verbose};
    my $result = $self->areyousure($w, "Are you sure you want to hibernate the computer?");
    if ($result eq 'yes') {
	$self->{ops}{choice} = 'Hibernate';
	Gtk2::main_quit;
    }
    return Gtk2::EVENT_PROPAGATE;
}
sub HybridSleep {
    my $self = shift;
    my $w = shift;
    print STDERR "Hybrid Sleep clicked!\n" if $self->{ops}{verbose};
    my $result = $self->areyousure($w, "Are you sure you want to hybrid sleep the computer?");
    if ($result eq 'yes') {
	$self->{ops}{choice} = 'HybridSleep';
	Gtk2::main_quit;
    }
    return Gtk2::EVENT_PROPAGATE;
}
sub SwitchUser {
    my $self = shift;
    my $w = shift;
    print STDERR "Switch User clicked!\n" if $self->{ops}{verbose};
    $self->{ops}{choice} = 'SwitchUser';
    return Gtk2::EVENT_PROPAGATE;
}
sub SwitchDesk {
    my $self = shift;
    my $w = shift;
    print STDERR "Switch Desktop clicked!\n" if $self->{ops}{verbose};
    $self->{ops}{choice} = 'SwitchDesk';
    return Gtk2::EVENT_PROPAGATE;
}
sub LockScreen {
    my $self = shift;
    my $w = shift;
    print STDERR "Lock Screen clicked!\n" if $self->{ops}{verbose};
    $self->{ops}{choice} = 'LockScreen';
    return Gtk2::EVENT_PROPAGATE;
}
sub Logout {
    my $self = shift;
    my $w = shift;
    print STDERR "Logout clicked!\n" if $self->{ops}{verbose};
    $self->{ops}{choice} = 'Logout';
    Gtk2->main_quit;
    return Gtk2::EVENT_PROPAGATE;
}
sub Restart {
    my $self = shift;
    my $w = shift;
    print STDERR "Restart clicked!\n" if $self->{ops}{verbose};
    $self->{ops}{choice} = 'Restart';
    Gtk2->main_quit;
    return Gtk2::EVENT_PROPAGATE;
}
sub Cancel {
    my $self = shift;
    my $w = shift;
    print STDERR "Cancel clicked!\n" if $self->{ops}{verbose};
    $self->{ops}{choice} = 'Cancel';
    Gtk2->main_quit;
    return Gtk2::EVENT_PROPAGATE;
}

sub logout {
    my ($self,%ops) = @_;
    $self->{ops} = \%ops;
    # XDE::Context expects these on the main object
    foreach (qw/verbose lang language charset/) {
	$self->{$_} = $ops{$_} if $ops{$_};
    }
    $self->set_vendor($ops{vendor}) if $ops{vendor};

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
    Gtk2->init;
    if ($self->{XDG_ICON_PREPEND} or $self->{XDG_ICON_APPEND})
    {
	my $theme = Gtk2::IconTheme->get_default;
	if ($self->{XDG_ICON_PREPEND}) {
	    foreach (reverse split(/:/,$self->{XDG_ICON_PREPEND})) {
		$theme->prepend_search_path($_);
	    }
	}
	if ($self->{XDG_ICON_APPEND}) {
	    foreach (split(/:/,$self->{XDG_ICON_APPEND})) {
		$theme->append_search_path($_);
	    }
	}
    }
    my ($w,$h,$f,$v,$s,$l,$bb);
    $w = Gtk2::Window->new('toplevel');
    $w->signal_connect(delete_event=>sub{
	    Gtk2->main_quit;
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
    $h = Gtk2::HBox->new(FALSE,5);
    $w->add($h);
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
    $v->pack_end($bb,TRUE,TRUE,0);
    my (@b,$b,$i);
    my @data = (
	[ 'system-shutdown', 'gnome-session-halt', 'gtk-quit', 'Power Off',
	  sub{ $self->PowerOff($w) }, $self->{can}{PowerOff}, $self->{tip}{PowerOff},
	],
	[ 'system-reboot', 'gnome-session-reboot', 'gtk-quit', 'Reboot',
	  sub{ $self->Reboot($w) }, $self->{can}{Reboot}, $self->{tip}{Reboot},
	],
	[ 'system-suspend', 'gnome-session-suspend', 'gtk-quit', 'Suspend',
	  sub{ $self->Suspend($w) }, $self->{can}{Suspend}, $self->{tip}{Suspend},
	],
	[ 'system-suspend-hibernate', 'gnome-session-hibernate', 'gtk-quit', 'Hibernate',
	  sub{ $self->Hibernate($w) }, $self->{can}{Hibernate}, $self->{tip}{Hibernate},
	],
	[ 'system-suspend-hibernate', 'gnome-session-hibernate', 'gtk-quit', 'Hybrid Sleep',
	  sub{ $self->HybridSleep($w) }, $self->{can}{HybridSleep}, $self->{tip}{HybridSleep},
	],
	[ 'system-switch-user', 'gnome-session-switch', 'gtk-quit', 'Switch User',
	  sub{ $self->SwitchUser($w) }, $self->{can}{SwitchUser}, $self->{tip}{SwitchUser},
	],
	[ 'system-switch-user', 'gnome-session-switch', 'gtk-quit', 'Switch Desktop',
	  sub{ $self->SwitchDesk($w) }, $self->{can}{SwitchDesk}, $self->{tip}{SwitchDesk},
	],
	[ 'gtk-refresh', 'gtk-refresh', 'gtk-refres', 'Restart',
	  sub{ $self->Restart($w) }, $self->{can}{Restart}, $self->{tip}{Restart},
	],
	[ 'system-lock-screen', 'gnome-lock-screen', 'gtk-quit', 'Lock Screen',
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
	$i = Gtk2::Image->new_from_icon_name($_->[0],'button');
	$i = Gtk2::Image->new_from_icon_name($_->[1],'button') unless $i;
	$i = Gtk2::Image->new_from_stock($_->[2],'button') unless $i;
	$b->set_image($i);
	$b->set_label($_->[3]);
	$b->signal_connect(clicked=>$_->[4]);
	$b->set_sensitive(FALSE) unless $_->[5] =~ m{^(yes|challenge)$};
	$b->set_tooltip_text($_->[6]) if $_->[6];
	$bb->pack_start($b,TRUE,TRUE,5); push @b,$b;
    }
    $w->set_default_size(-1,350);
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
    Gtk2->main;
    $w->destroy;
    return $self->{ops}{choice};
}

sub DoPowerOff {
    shift->{dbus}{obj}->PowerOff(TRUE);
}
sub DoReboot {
    shift->{dbus}{obj}->Reboot(TRUE);
}
sub DoSuspend {
    shift->{dbus}{obj}->Suspend(TRUE);
}
sub DoHibernate {
    shift->{dbus}{obj}->Hibernate(TRUE);
}
sub DoHybridSleep {
    shift->{dbus}{obj}->HybridSleep(TRUE);
}
sub DoSwitchUser {
    print STDERR "Unimplemented DoSwitchUser\n";
}
sub DoSwitchDesk {
    print STDERR "Unimplemented DoSwitchDesk\n";
}
sub DoLockScreen {
    print STDERR "Unimplemented DoLockScreen\n";
}
sub DoLogout {
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

1;

