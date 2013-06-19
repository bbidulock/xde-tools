package XDE::Autostart;
use base qw(XDE::Dual);
use POSIX qw(setsid getpid :sys_wait_h);
use Glib qw(TRUE FALSE);
use Gtk2;
use Time::HiRes;
use strict;
use warnings;

=head1 NAME

XDE::Autostart - perform XDG autostart functions

=head1 SYNOPSIS

 my $xde = XDE::Autostart->new(%OVERRIDES);
 $xde->getenv();
 $xde->run();

=cut

use constant {
    MYENV => [qw(
	_FBSESSION_PID
	XDG_SESSION_PID
	_LXSESSION_PID
	DBUS_SESSION_BUS_ADDRESS
	DBUS_SESSION_BUS_PID
    )],
};

=head1 DESCRIPTION

The B<XDE::Autostart> module provides the ability to perform XDG
autostart functions for the X Desktop Environment.

=head1 METHODS

=over

=item $xde = XDE::Autostart->B<new>(I<%OVERRIDES>,\I<%ops>) => blessed HASHREF

Creates a new XDE::Autostart instance.
The XDE::Autostart module uses the L<XDE::Context(3pm)> module as a
base, so the C<%OVERRIDES> are simply passed to the L<XDE::Context(3pm)>
module.
When an options hash, I<%ops>, is passed to the method, it is
initialized with default option values.

See L<XDE::Context(3pm)> for options recognized by the base module.

=cut

sub new {
    return XDE::Dual::new(@_);
}

=item $xde->B<defaults>() => $xde

Apply our specific defaults from environment variables and set defaults
in options.  This is not indempotent.  The first pass will assign
defaults to options from environment variables.  The second pass will
assign assign settings from set option variables.  This internal method
is invoked from L<XDE::Context(3pm)> on startup and again after options
processing directly by the user of this module.

=cut

sub defaults {
    my $self = shift;
    if (my $pid = $self->{ops}{pid}) {
	$self->{XDG_SESSION_PID} = $pid;
	$self->{_LXSESSION_PID} = $pid;
	$self->{_FBSESSION_PID} = $pid;
    }
    else {
	$pid = getpid();
	open(STDIN, "</dev/null") or die "cannot redirect standard input";
	open(STDOUT,">/dev/null") or die "cannot redirect standard output";
	my $sid = setsid();
	$sid = $pid if $sid == -1;
	$self->{XDG_SESSION_PID} = $sid;
	$self->{_LXSESSION_PID} = $sid;
	$self->{_FBSESSION_PID} = $sid;
	$self->{ops}{pid} = $sid;
    }
    unless ($self->{DBUS_SESSION_BUS_ADDRESS}) {
	if (-x "/usr/bin/dbus-launch") {
	    foreach (`/usr/bin/dbus-launch --sh-syntax --exit-with-session`) {
		if (m{(DBUS_SESSION_BUS_ADDRESS)='(.*)';}) {
		    $self->{$1} = $2;
		}
		elsif (m{(DBUS_SESSION_BUS_PID)=(\d+);}) {
		    $self->{$1} = $2;
		}
	    }
	}
    }
}

=item $xde->B<_getenv>() => $xde

Obtain our specific environment variables if they are set.  This doe not
include startup id environment variables passed to us.

=cut

sub _getenv {
    my $self = shift;
    foreach (@{&MYENV}) { $self->{$_} = $ENV{$_} }
    return $self;
}

=item $xde->B<_setenv>() => $xde

Set our specific environment variables.  This does not include
startup id environment variables passed to a child.

=cut

sub _setenv {
    my $self = shift;
    foreach (@{&MYENV}) { delete $ENV{$_}; $ENV{$_} = $self->{$_} if $self->{$_}; }
    return $self;
}

=item $xde->B<_init>() => $xde

Internal initialization method.  Called when the XDE::Dual object is
initialized, after the X11::Protocol conection is made and Gtk2 is
initialized.  The things that we do here are as follows:

=over

=item

Register for SubstructureNotify events on the root window of the active
screen.  This is for startup notification so that we can tell when a
started task maps a window.

=item

Register for StructureNotify events on the root window of the active
screen.  This is so that we can received broadcast client messages for
full startup notification.

=item

Register for property changes on the root window so that we can detect
when a window manager becomes active, if one is not active already.
Also, startup notification client messages are sent with a
PropertyChanged mask.

=back

=cut

sub _init {
    my $self = shift;
    my $X = $self->{X};
    my $xid = $self->{xid} = $X->new_rsrc;
    my $screen = $X->{screens}[0];
    $X->CreateWindow($xid,$screen->{root},'InputOutput',
	    $screen->{root_depth}, 'CopyFromParent', (0, 0),
	    1, 1, 0, event_mask=>$X->pack_event_mask(qw(
		    StructureNotify PropertyChange)));
    # make sure that our events are being delivered
    my (%attrs) = $X->GetWindowAttributes($screen->{root});
    my $mask = $attrs{your_event_mask};
    my (%mask) = (map{$_=>1}$X->unpack_event_mask($mask));
    $mask{StructureNotify} = 1;
    $mask{SubstructureNotify} = 1;
    $mask{PropertyChange} = 1;
    $mask = $X->pack_event_mask(keys %mask);
    $X->ChangeWindowAttributes($screen->{root}, event_mask=>$mask);
    return $self;
}

=item $xde->B<_term>() => $xde

=cut

sub _term {
    my $self = shift;
    my $X = $self->{X};
    if (my $xid = $self->{xid}) {
	$X->DestroyWindow($xid);
    }
    return $self;
}

=item $xde->B<newsnid>() => SCALAR

Obtains a new unique startup notification id.

=cut

sub newsnid {
    my $self = shift;
    my $now = Time::HiRes::time;
    $now = $now + 1 if $self->{ts} == $now;
    $self->{ts} = $now;
    return "$self->{hostname}+$self->{pid}+$self->{ts}";
}

=item $xde->B<send_sn>(I<$msg>)

Internal method to
send a packed startup notification message.

=cut

sub send_sn {
    my ($self,$msg) = @_;
    my $X = $self->{X};
    my $pad = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";
    {
	$X->SendEvent($X->root,FALSE,
		$X->pack_event_mask(q(PropertyChange)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$self->{xid},
		    type=>$X->atom('_NET_STARTUP_INFO_BEGIN'),
		    format=>8,
		    data=>substr($msg.$pad,0,20)));
	$msg = length($msg) <= 20 ? '' : substr($msg,20);
    }
    while (length($msg)) {
	$X->SendEvent($X->root,FALSE,
		$X->pack_event_mask('PropertyChange'),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$self->{xid},
		    type=>$X->atom('_NET_STARTUP_INFO'),
		    format=>8,
		    data=>substr($msg.$pad,0,20)));
	$msg = length($msg) <= 20 ? '' : substr($msg,20);
    }
    $X->flush;
}

sub send_sn_old {
    my ($self,$msg) = @_;
    my $xid = $self->{xid};
    my $pad = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";
    my $xevent = Gtk2::Gdk::Event->new('client-event');
    $xevent->message_type($self->{atom_begin});
    $xevent->data_format(Gtk2::Gdk::CHARS);
    $xevent->data(substr($msg.$pad,0,20));
    Gtk2::Gdk::Event->send_client_message($xevent,$xid);
    $msg = length($msg) <= 20 ? '' : substr($msg,20);
    while (length($msg)) {
	$xevent = Gtk2::Gdk::Event->new('client-event');
	$xevent->message_type($self->{atom_more});
	$xevent->data_format(Gtk2::Gdk::CHARS);
	$xevent->data(substr($msg.$pad,0,20));
	Gtk2::Gdk::Event->send_client_message($xevent,$xid);
	$msg = length($msg) <= 20 ? '' : substr($msg,20);
    }
}

=item B<sn_quote>($txt) => $quoted_txt

Internal method to
quote parameter C<$txt> according to XDG startup notification rules.

=cut

sub sn_quote {
    my $txt = shift;
    $txt =~ s{\\}{\\\\}g if $txt =~ m{\\};
    $txt =~ s{"}{\\"}g   if $txt =~ m{"};
    $txt =~ "\"$txt\""   if $txt =~ m{ };
    return $txt;
}

=item $xde->B<send_sn_new>(I<$id>,{I<%msg_hash>})

Internal method to
send a startup notification C<new> message.  C<%msg_hash> contains a
hash of the valid startup notification fields.  The C<new> message
requires the C<ID>, C<NAME> and C<SCREEN> fields, and may optionally
contain the C<BIN>, C<ICON>, C<DESKTOP>, C<TIMESTAMP>, C<DESCRIPTION>,
C<WMCLASS> and C<SILENT> fields.

=cut

sub send_sn_new {
    my ($self,$id,$msg) = @_;
    my $txt = 'new:';
    $txt .= ' ID='.sn_quote($id);
    $txt .= ' NAME='.sn_quote($msg->{NAME});
    $txt .= ' SCREEN='.sn_quote($msg->{SCREEN});
    foreach (qw(BIN ICON DESKTOP TIMESTAMP DESCRIPTION WMCLASS SILENT)) {
	$txt .= " $_=".sn_quote($msg->{$_}) if $msg->{$_};
    }
    $txt .= "\0";
    $self->send_sn($txt);
}

=item $xde->B<send_sn_change>(I<$id>,{I<%msg_hash>})

Internal method to
send a startup notification C<change> message.  C<%msg_hash> contains a
hash of the valid startup notification fields.  The C<change> message
requires the C<ID> field, and may optionally contain the C<NAME>,
C<SCREEN>, C<BIN>, C<ICON>, C<DESKTOP>, C<TIMESTAMP>, C<DESCRIPTION>,
C<WMCLASS> and C<SILENT> fields.

=cut

sub send_sn_change {
    my ($self,$id,$msg) = @_;
    my $txt = 'change:';
    $txt .= ' ID='.sn_quote($id);
    foreach (qw(NAME SCREEN BIN ICON DESKTOP TIMESTAMP DESCRIPTION WMCLASS SILENT)) {
	$txt .= " $_=".sn_quote($msg->{$_}) if $msg->{$_};
    }
    $txt .= "\0";
    $self->send_sn($txt);
}

=item $xde->B<send_sn_remove>(I<$id>)

Internal method to
send a startup notification C<remove> message.  C<$id> is the startup
notification identifier.  The task manager sends a startup-notification
remove command when the application fails to.

=cut

sub send_sn_remove {
    my ($self,$id) = @_;
    my $txt = 'remove:';
    $txt .= ' ID='.sn_quote($id);
    $txt .= "\0";
    $self->send_sn($txt);
}

sub autostart {
    my $self = shift;
    my $xde = $self->{xde};
    my %ops = %{$self->{ops}};
    my $autostart = $self->{autostart} = $xde->get_autostart();
    my @autostart = sort {$a->{Label} cmp $b->{Label}} values %$autostart;
    $self->{tasks} = \@autostart;

    if ($ops{verbose}) {
	foreach (@autostart) {
	    print STDERR "----------------------\n";
	    print STDERR "Label: ",$_->{Label},"\n";
	    print STDERR "Autostart: ",$_->{Name},"\n";
	    print STDERR "Comment: ",$_->{Comment},"\n";
	    print STDERR "Exec: ",$_->{Exec},"\n";
	    print STDERR "TryExec: ",$_->{TryExec},"\n";
	    print STDERR "File: ",$_->{file},"\n";
	    print STDERR "Icon: ",$_->{Icon},"\n";
	    print STDERR "Disable: ",$_->{'X-Disable'},"\n"
		if $_->{'X-Disable'};
	    print STDERR "Reason: ",$_->{'X-Disable-Reason'},"\n"
		if $_->{'X-Disable-Reason'};
	}
    }
}

=item $xde->B<create_splash>() => $xde

Internal method to create the splash window for auto startup.
C<$xde-E<gt>init> must be called before this function.  The window is
available in C<$xde-E<gt>{splash}>, the table in C<$xde-E<gt>{table}>,
the current row in C<$xde-E<gt>{row}>; col, C<$xde-E<gt>{col}> and the
total number of columns in C<$xde-E<gt>{cols}>.  The splash window is
shown immediately.

=cut

sub create_splash {
    my $self = shift;
    my ($w,$h,$v,$f,$s,$sw,$t);
    $w = Gtk2::Window->new('toplevel');
    $w->set_wmclass('xde-autostart','Xde-autostart');
    $w->set_title('Autostarting Applications');
    $w->set_gravity('center');
    $w->set_type_hint('splashscreen');
    $w->set_border_width(20);
    $w->set_skip_pager_hint(TRUE);
    $w->set_skip_taskbar_hint(TRUE);
    $w->set_position('center-always');
    $w->signal_connect(delete_event=>\&Gtk2::Widget::hide_on_delete);
    my $cols = 7;
    $h = Gtk2::HBox->new(FALSE,5);
    $w->add($h);
    $v = Gtk2::VBox->new(FALSE,5);
    if ($self->{ops}{banner} and -f $self->{ops}{banner}) {
	$f = Gtk2::Frame->new;
	$f->set_shadow_type('etched-in');
	$v->pack_start($f,FALSE,FALSE,0);
	$h = Gtk2::HBox->new(FALSE,5);
	$h->set_border_width(10);
	$f->add($h);
	$s = Gtk2::Image->new_from_file($self->{ops}{banner});
	$h->add($s);
    }
    $f = Gtk2::Frame->new;
    $f->set_shadow_type('etched-in');
    $v->pack_start($f,TRUE,TRUE,0);
    $h = Gtk2::HBox->new(FALSE,5);
    $h->set_border_width(10);
    $f->add($h);
    $sw = Gtk2::ScrolledWindow->new;
    $sw->set_shadow_type('etched-in');
    $sw->set_policy('never','automatic');
    $sw->set_border_width(3);
    $h->pack_start($sw,TRUE,TRUE,0);
    $t = Gtk2::Table->new(1,$cols,TRUE);
    $t->set_col_spacings(1);
    $t->set_row_spacings(1);
    $t->set_homogeneous(TRUE);
    $t->set_size_request(750,-1);
    $sw->add_with_viewport($t);
    $w->set_default_size(-1,600);
    $w->show_all;
    $w->show_now;

    $self->{splash} = $w;
    $self->{table} = $t;
    $self->{row} = 0;
    $self->{col} = 0;
    $self->{cols} = $cols;
    return $self;
}

=item $xde->B<task_startup>(I<$task>) => $pid

Internal method to start a task.  Run out of an idle watcher on the
event loop.

=cut

sub task_startup {
    my ($self,$task) = @_;
    $task->{cmd} = $task->{Exec} unless $task->{cmd};
    $task->{restart} = ($task->{cmd} =~ s{^\@}{});
    $task->{restart} = $task->{'X-Restart'} if $task->{'X-Restart'};
    $task->{button} = $self->new_button($task) unless $task->{button};
    if ($task->{'X-Disable'} and $task->{'X-Disable'} =~ m{true|yes|1}i) {
	$task->{state} = 'disabled';
	$task->{status} = 'disabled';
	return;
    }
    my $notify = ($task->{StartupNotify} and $task->{StartupNotify} =~ m{true|yes|1}i) ? 1 : 0;
    my $id = $task->{DESKTOP_STARTUP_ID} = $self->newsnid;
    $self->send_sn_new($id,{
	ID=>$id,
	NAME=>$task->{Name},
	SCREEN=>$self->{screen}->get_number,
	BIN=>$task->{TryExec},
	ICON=>$task->{Icon},
	DESKTOP=>0,
	TIMESTAMP=>Gtk2::Gdk::X11->get_server_time($self->{root}),
	DESCRIPTION=>$task->{Comment},
	WMCLASS=>$task->{StartupWMClass},
	SILENT=>($notify or $self->{StartupWMClass}) ? 0 : 1,
    });
    if (my $name = $task->{StartupWMClass}) {
	$self->{wmclass}{$name} = $task;
    }
    if ($notify) {
	$self->{startnotify}{$id} = $task;
    }
    my $pid = fork();
    unless (defined $pid) {
	warn "cannot fork";
	return;
    }
    if ($pid) {
	# we are the parent
	print STDERR "Child $pid started...\n" if $self->{ops}{verbose};
	$task->{pid} = $pid;
	$task->{time} = Time::HiRes::time;
	$task->{count} += 1;
	$self->{children}{$pid} = $task;
	$self->{starting}{$pid} = $task;
	$task->{state} = 'starting';
	$task->{status} = 'forked';
	$task->{watcher} = Glib::Child->watch_add($pid,
		sub { $self->task_exited(@_) }, $task);
	$task->{timeout} = Glib::Timeout->add(200,
		sub { $self->task_timeout($task) });
	return $pid;
    }
    else {
	# we are the child
	$ENV{DESKTOP_STARTUP_ID} = $id;
	exec "$task->{cmd}" or exit 255;
    }
}

sub task_restart {
    my ($self,$task) = @_;
    if ($task->{count} >= 3) {
	print STDERR "Command $task->{cmd} restarted 3 times...\n";
	return 0;
    }
    my $time = Time::HiRes::time;
    my $rate = 1.0/($time - $task->{time});
    if ($rate >= 3.0) {
	print STDERR "Command $task->{cmd} restarting $rate times a second...\n";
	print STDERR "Not restarting for 2 seconds...\n";
	$task->{state} = 'throttled';
	$task->{status} = "restarting $rate times a second";
	$self->{throttled}{$task->{id}} = $task;
	$task->{throttle} = Glib::Timeout->add(2000, sub {
		delete $task->{throttle};
		$self->task_restart($task);
		return Glib::SOURCE_REMOVE;
	});
	return 1;
    }
    return $self->task_startup($task);
}

=item $xde->task_shutdown(I<$task>)

Internal method to shut down a running task.  The task has two seconds
to respond to a C<SIGTERM> and exit before being sent a C<SIGKILL>.

=cut

sub task_shutdown {
    my ($self,$task) = @_;
    if (my $tag = delete $task->{throttle}) {
	Glib::Source->remove($tag);
	delete $self->{throttled}{$task->{id}};
	return;
    }
    if (my $pid = $task->{pid}) {
	# task has 2 seconds to shutdown or get killed with prejudice
	$task->{shutdown} = Glib::Timeout->add(2000,sub {
		delete $task->{shutdown};
		if ($task->{pid}) {
		    kill -KILL $task->{pid};
		}
		return Glib::SOURCE_REMOVE;
	});
	kill -TERM $pid;
	return;
    }
    print STDERR "Command $task->{cmd} is not running...\n";
}

=item $xde->B<autostart_execs>() => \@execs

Locate the autostart files and parse them for commands.  Prepare a list
of pseudo F<.desktop> entries suitable for passing to B<do_autostart>().
Returns an array reference to the exec commands.  Autostart exec
commands are taken from three places: the system F<autostart> file, the
user F<autostart> file and the B<--exec> options from the command line
in the array reference in C<$xde-E<gt>{ops}{exec}>.

=cut

sub autostart_execs {
    my $self = shift;
    my $desktop = $self->{XDG_CURRENT_DESKTOP};
    $desktop = 'default' unless $desktop;
    my @files = ();
    foreach (map{"$_/xde-session/$desktop"}$self->XDG_CONFIG_ARRAY) {
	next unless -f "$_/autostart";
	push @files, "$_/autostart";
	last;
    }
    $_ = "$self->{XDG_CONFIG_HOME}/xde/$desktop";
    push @files, "$_/autostart" if -f "$_/autostart";
    my @execs = ();
    foreach my $file (@files) {
	if (open(my $fh,"<",$file)) {
	    while (<$fh>) { chomp;
		next if m{^\s*$};
		next if m{^\s*\#};
		my $restart = s{^\@}{} ? 'true' : 'false';
		push @execs, {
		    Exec=>$_,
		    'X-Restart'=>$restart,
		    Type=>'Execute',
		    id=>'autostart',
		    file=>$file,
		};
	    }
	    close($fh);
	}
    }
    foreach (@{$self->{ops}{exec}}) {
	my $restart = s{^\@}{} ? 'true' : 'false';
	push @execs, {
	    Exec=>$_,
	    'X-Restart'=>$restart,
	    Type=>'Execute',
	    id=>'commandline',
	    file=>'/dev/stdin',
	};
    }
    return \@execs;
}

=item $xde->B<do_startup>(I<$wment>) => $xde

Perform startup actions.  This method calls
XDE::Autostart::B<autostart_execs> to obtain the list of executable
statements to execute on startup and calls
XDG::Context::B<get_autostart> to obtain a hash of autostartable
F<.desktop> entries.  The window manager I<XSession> F<.desktop> entry
must be provided as an argument, C<$wment>.

=cut

sub do_startup {
    my $self = shift;
    my @wment = @_;
    my @execs = (@{$self->autostart_execs});
    my @start = (sort {$a->{id} cmp $b->{id}} values %{$self->get_autostart});
    my @tasks = (@execs,$wment,@start);
    $self->{execs} = \@execs;
    $self->{wment} = \@wment;
    $self->{start} = \@start;
    $self->{tasks} = [ @execs, @wment, @start ];
    $self->{toexecs} = [ @execs ];
    $self->{towment} = [ @wment ];
    $self->{tostart} = [ @start ];

    # mask sure $wment is set up correctly
    $wment->{Type} = 'XSession';

    $self->create_splash();

    # tell the task manager what phase we are in
    $self->{phase} = 'init';

    $self->{idletask}  = Glib::Idle->add(sub{$self->autostart_idle_execs});
    $self->{guardtime} =
	Glib::Timeout->add(1000,sub{$self->autostart_guard_execs});
    $self->{animation} = Glib::Timeout->add(400,sub{$self->window_animation});
    # tasks will be started one by one as the mainloop idles.
    return $self;
}

=item $xde->B<window_animation>()

This method can be called from an interval timer (of about 300-500
milliseconds) to blink the buttons (sensitize, desensitize) for tasks
that are starting.

=cut

sub window_animation {
    my $self = shift;
    $self->{animstate} = FALSE unless exists $self->{animstate};
    my $state = $self->{animstate} = $self->{animstate} ? FALSE : TRUE;
    foreach (values %{$self->{starting}}) {
	if (my $b = $_->{button}) {
	    $b->set_sensitive($state);
	    $b->show_now;
	}
    }
    if (@{$self->{starting}} == 0 and @{$self->{tostart}} == 0) {
	delete $self->{animation};
	return Glib::SOURCE_REMOVE;
    }
    return Glib::SOURCE_CONTINUE;
}

=item $xde-B<window_manager_check>() => $name or undef

Performs a window manager check.  Invoked by a changed
_NET_SUPPORTING_WM_CHECK property on the root window but can be called
at any time.  Note that in the final meta script we might want to
shutdown and restart XDG autostart tasks if a new window manager takes
over for the old one.

=cut

sub window_manager_check {
    my ($self,$task) = @_;
    my $self = shift;
    my $X = $self->{X};
    my $screen = $X->{screens}[0];
    my $root = $screen->{root};
    my ($val,$type);
    ($val,$type) = $X->GetProperty($root,
	    $X->atom('_NET_SUPPORTING_WM_CHECK'),
	    $X->atom('WINDOW'), 0, 1);
    if ($type and $X->atom_name($type) eq 'WINDOW') {
	my $win = unpack('L',substr($val,0,4));
	($val,$type) = $X->GetProperty($win,
		$X->atom('_NET_SUPPORTING_WM_CHECK'),
		$X->atom('WINDOW'), 0, 1);
	if ($type and $X->atom_name($type) eq 'WINDOW') {
	    # ok this is the window manager, check others
	    $task->{_NET_SUPPORTING_WM_CHECK} = $win;
	}
    }
    ($val,$type) = $X->GetProperty($root,
	    $x->atom('_WIN_SUPPORTING_WM_CHECK'),
	    $X->atom('WINDOW'), 0, 1);
    if ($type and $X->atom_name($type) eq 'WINDOW') {
	my $win = unpack('L',substr($val,0,4));
	($val,$type) = $X->GetProperty($win,
		$x->atom('_WIN_SUPPORTING_WM_CHECK'),
		$X->atom('WINDOW'), 0, 1);
	if ($type and $X->atom_name($type) eq 'WINDOW') {
	    # ok this is the window manager, check others
	    $task->{_WIN_SUPPORTING_WM_CHECK} = $win;
	}
    }
}

=item $xde->B<autostart_begin_execs>()

Internal method to launch the execs autostart phase.

=cut

sub autostart_begin_execs {
    my $self = shift;
    $self->{phase} = 'execs';
    $self->{guardtime} =
	Glib::Timeout->add(1000,sub{$self->autostart_guard_execs});
    $self->{idletask} =
	Glib::Idle->add(sub{$self->autostart_idle_execs});
    unless (@{$self->{toexecs}}) {
	$self->autostart_done_execs;
	return;
    }
    return;
}

=item $xde->B<autostart_idle_execs>()

Internal method for starting exec tasks.  When the list of autostart
exec tasks is set up, this method is run out of an Glib::Idle watcher,
that continues starting exec tasks until the remaining exec tasks to
start have been completed.  The task manager then proceeds to starting
the window manager and detecting its presence, or moves on to autostart
tasks.  A guard timer protects this phase and limits it to 1 second.

=cut

sub autostart_idle_execs {
    my $self = shift;
    if (my $task = shift @{$self->{toexecs}}) {
	$self->task_startup($task);
	return Glib::SOURCE_CONTINUE;
    }
    else {
	delete $self->{idletask};
	return Glib::SOURCE_REMOVE;
    }
}

=item $xde->B<autostart_done_execs>()

Internal method for handling completion of the execs startup phase.
This method is called by the last exec task that completes startup.  The
task manager does not know; however, about tasks which are yet to be
started, so the XDE::Autostart instance must check that before assuming
the phase is complete.  The normal thing to do here is to move on to the
window manager startup phase.

=cut

sub autostart_done_execs {
    my $self = shift;
    return if @{$self->{toexecs}};
    foreach (qw(guardtime idletask)) {
	if (my $tag = delete $self->{$_}) {
	    Glib::Source->remove($tag);
	}
    }
    $self->autostart_begin_wment;
}

=item $xde->B<autostart_guard_execs>()

Internal method for guarding the exec startup phase.  The exec autostart
phase has 1 second to complete.

=cut

sub autostart_guard_execs {
    my $self = shift;
    if (@{$self->{toexecs}} == 0) {
	# we are done
	$self->{guardtime} =
	    Glib::Timeout->add(2000,sub{$self->autostart_guard_wment});
	if (my $wment = $self->{wment}) {
	    $self->task_startup($wment);
	}
	if (my $tag = delete $self->{idletask}) {
	    Glib::Source->remove($tag);
	}
	return Glib::SOURCE_REMOVE;
    }
    print STDERR "Exec tasks did not start in 1 second...";
    print STDERR " ...waiting another second.\n";
    return Glib::SOURCE_CONTINUE; # one more second
}

=item $xde->B<autostart_begin_wment>()

Internal method to launch the wment autostart phase.

=cut

sub autostart_begin_wment {
    my $self = shift;
    $self->{phase} = 'wment';
    $self->{guardtime} =
	Glib::Timeout->add(2000,sub{$self->autostart_guard_wment});
    $self->{idletask} =
	Glib::Idle->add(sub{$self->autostart_idle_wment});
    unless (@{$self->{wment}}) {
	$self->autostart_done_wment;
	return;
    }
    return;
}

=item $xde->B<autostart_idle_wment>()

Internal method for starting the window manager.  When the window
manager command is set up, this taks is run out of a Glib::Idle watcher,
that starts the window manager when idle.  The taks manager then
proceeds to detection of the window manager.  A guard timer protects
this phase and limits it to 2 seconds.

=cut

sub autostart_idle_wment {
    my $self = shift;
    if (my $task = shift @{$self->{towment}}) {
	$self->task_startup($task);
	return Glib::SOURCE_CONTINUE;
    }
    else {
	delete $self->{idletask};
	return Glib::SOURCE_REMOVE;
    }
}

=item $xde->B<autostart_done_wment>()

Internal method for handling completion of the wment startup phase.
This method is called when the appearance of a window manager is
detected.  The normal thing to do here is to move on to the autostart
startup phase.

=cut

sub autostart_done_wment {
    my $self = shift;
    return if @{$self->{towment}};
    foreach (qw(guardtime idletask)) {
	if (my $tag = delete $self->{$_}) {
	    Glib::Source->remove($tag);
	}
    }
    $self->autostart_begin_start;
    return;
}

=item $xde->B<autostart_guard_wment>()

Internal method for guarding the window manager startup phase.  The wm
autostart phase has 2 seconds to complete.

=cut

sub autostart_guard_wment {
    my $self = shift;
    my $wment = $self->{wment};
    if (not $wment or $wment->{state} eq 'running') {
	# we are done
	$self->{idletask}  = Glib::Idle->add(sub{$self->autostart_idle_start});
	$self->{guardtime} = Glib::Timeout->add(5000,sub{$self->autostart_guard_start});
	if (my $tag = delete $self->{idletask}) {
	    Glib::Source->remove($tag);
	}
	return GLib::SOURCE_REMOVE;
    }
    print STDERR "Window manager did not start in 2 seconds...";
    print STDERR " ...waiting another 2 seconds.\n";
    return Glib::SOURCE_CONTINUE;
}

=item $xde->B<autostart_idle_start>()

Internal method for starting autostart tasks.  When the list of
autostart tasks is set up, this method is run out of a Glib::Idle
watcher, that continue starting autostart tasks until the remaining
autostart tasks to start have been completed.  A guard timer protects
this phase an limits it to 5 seconds.

=cut

sub autostart_idle_start {
    my $self = shift;
    if (my $task = shift @{$self->{tostart}}) {
	$self->task_startup($task);
	return Glib::SOURCE_CONTINUE;
    }
    else {
	delete $self->{idletask};
	return Glib::SOURCE_REMOVE;
    }
}

=item $xde->B<autostart_guard_start>()

Internal method for guarding the autostart startup phase.  The autostart
statup phase has 5 seconds to complete.

=cut

sub autostart_guard_start {
    my $self = shift;
    if (@{$self->{tostart}} == 0) {
	# we are done
	$self->startup_complete;
	delete $self->{guardtime}
	return Glib::SOURCE_REMOVE;
    }
    print STDERR "Autostart tasks did not start in 5 seconds...";
    print STDERR " ...waiting another 5 seconds.\n";
    return Glib::SOURCE_CONTINUE:
}

=item $xde->B<autostart_done_start>()

Internal method for handling completion of the autostart startup phase.
This method is called by the last autostart task that completes startup.
The task manager does not know; however, about tasks which are yet to be
started, so the XDE::Autostart instance must check that before assuming
the phase is complete.  The normal thing to do here is to drop or
destroy the splash window.

=cut

sub autostart_done_start {
    my $self = shift;
    return if @{$self->{tostart}};
    foreach (qw(guardtime idletask animate)) {
	if (my $tag = delete $self->{$_}) {
	    Glib::Source->remove($tag);
	}
    }
    if (my $window = $self->{splash}) {
	$window->hide_all;
    }
    $self->main_quit('done');
}

sub autostart_done {
    my $self = shift;
    if (scalar(%{$self->{starting}}) == 0) {
	if (my $sub = $self->can("autostart_done_$self->{phase}")) {
	    &$sub($self);
	}
    }
}

=item $xde->B<wmexited>(I<$task>,I<$pid>,I<$status>)

This method must be implemented.  This is called by the task manager
whenever the window manager exits normally (it is automatically
restarted otherwise).  Normally this should create a logout window and
prompt the user what to do.  The simple thing to do is to exit the main
loop with parameter C<wmexited>.

=cut

sub wmexited {
    my ($self,$task,$pid,$status) = @_;
    $self->main_quit('wmexited');
    return;
}

=item $xde->B<shutdown_complete>()

This method must be implemented.  This is called by the task manager
whenever the last, non-restartable task exits.

=cut

sub shutdown_complete {
    my $self = shift;
    $self->main_quit('shutdown');
    return;
}

=item $xde->B<task_running>(I<$task>,I<$reason>)

=cut

sub task_running {
    my ($self,$task) = @_;
    return unless $task->{state} eq 'starting';
    if (my $tag = delete $task->{timeout}) {
	Glib::Source->remove($tag);
    }
    if (my $name = $task->{StartupWMCLass}) {
	delete $self->{wmclass}{$name};
    }
    if (my $id = $task->{DESKTOP_STARTUP_ID}) {
	delete $self->{startnotify}{$id};
    }
    if (my $pid = $task->{pid}) {
	delete $self->{starting}{$pid};
	$self->{running}{$pid} = $task;
    }
    $task->{state} = 'running';
    $task->{status} = $reason;
    if (my $b = $task->{button}) {
	$b->set_sensitive(TRUE);
	$b->show_now;
    }
    $self->autostart_done;
}

=back

=head1 EVENTS

The following methods are internal event handlers:

=over

=cut

=item $xde->B<task_exited>(I<$pid>,I<$status>,I<$task>) => {TRUE|FALSE}

A child process, C<$task>, with pid, C<$pid>, has exited or stopped as
specified by status, C<$status>.  Restartable processes that exit with a
non-zero exit status or exit on a signal are restarted unless it was
being shut down by us.

=cut

sub task_exited {
    my ($self,$pid,$waitstatus,$task) = @_;
    delete $task->{watcher};
    delete $self->{children}{$pid};
    if (WIFEXITED($waitstatus)) {
	if (my $status = WEXITSTATUS($waitstatus)) {
	    warn "child $pid exited with status $status" if $status;
	    $task->{state} = 'exited';
	    $task->{status} = "exited with status $status";
	    $task->{pid} = 0 if $task->{pid} == $pid;
	    delete $self->{children}{$pid};
	    delete $self->{starting}{$pid};
	    # eligible for restart
	}
	elsif ($task->{Type} eq 'XSession') {
	    print STDERR "Window manager exited normally\n";
	    $task->{state} = 'exited';
	    $task->{status} = 'exited with zero exit status';
	    $task->{pid} = 0 if $task->{pid} == $pid;
	    delete $self->{children}{$pid};
	    delete $self->{starting}{$pid};
	    # not eligible for restart
	    $self->main_quit('wmexited');
	    return Glib::SOURCE_REMOVE;
	}
	else {
	    $task->{state} = 'exited';
	    $task->{status} = 'exited with zero exit status';
	    $task->{pid} = if $task->{pid} == $pid;
	    delete $self->{children}{$pid};
	    delete $self->{starting}{$pid};
	    # eligible for restart
	}
    }
    elsif (WIFSIGNALED($waitstatus)) {
	my $signal = WTERMSIG($waitstatus);
	warn "child $pid exited on signal $signal" if $signal;
	$task->{state} = 'exited';
	$task->{status} = "exited on signal $signal";
	$task->{pid} = 0 if $task->{pid} == $pid;
	delete $self->{children}{$pid};
	delete $self->{starting}{$pid};
	# eligible for restart
    }
    elsif (WIFSTOPPED($waitstatus)) {
	warn "child $pid stopped: killing";
	$task->{state} = 'stopped';
	$task->{status} = 'stopped';
	kill -TERM $pid;
	# will reenter on exit
	return Glib::SOURCE_CONTINUE;
    }
    if ($task->{restart} and $task->{state} ne 'shutdown') {
	print STDERR "restarting $pid with $task->{cmd}\n";
	$self->task_restart($task);
    }
    else {
	if (scalar(keys %{$self->{children}}) == 0) {
	    print STDERR "there goes our last female...\n";
	    $self->main_quit('shutdown');
	    return Glib::SOURCE_REMOVE;
	}
    }

}

=item $xde->B<task_timeout>(I<$task>) => {TRUE|FALSE}

A per-task timeout has expired indicating that the task has been
starting for the entire timeout interval and should now be considered
running.

=cut

sub task_timeout {
    my ($self,$task) = @_;
    delete $task->{timeout};
    $self->task_running($task,'startup timeout expired');
    return Glib::SOURCE_REMOVE;
}

#sub event_handler_PropertyNotify {
#    my ($self,$e,$X,$v) = @_;
#}

=item $xde->B<event_handler_ClientMessage_NET_STARTUP_INFO_BEGIN>(I<$e>,I<$X>,I<$v>)

Internal method handles the first message in a sequence of messages that
make us a startup notification message.

=cut

sub event_handler_ClientMessage_NET_STARTUP_INFO_BEGIN {
    my ($self,$e,$X,$v) = @_;
}

=item $xde->B<event_handler_ClientMessage_NET_STARTUP_INFO>(I<$e>,I<$X>,I<$v>)

Internal method handles the first message

=cut

sub event_handler_ClientMessage_NET_STARTUP_INFO {
    my ($self,$e,$X,$v) = @_;
}

#sub event_handler_ClientMessage {
#    my ($self,$e,$X,$v) = @_;
#}

=item $xde->B<event_handler_MapNotify>(I<$e>,I<$X>,I<$v>)

A map notify event has been received: used to detect when a window is
mapped by a starting task and mark it a running instead of starting.

=cut

sub event_handler_MapNotify {
    my ($self,$e,$X,$v) = @_;
    if ($v) {
	printf STDERR "event => 0x%08x\n", $e->{event};
	printf STDERR "window => 0x%08x\n", $e->{window};
	printf STDERR "override-redirect => %s\n", $e->{override_redirect};
    }
    my ($task,$val,$type);
    my $win = $e->{window};
    ($val,$type) = $X->GetProperty($win,
	    $X->atom('WM_CLASS'),
	    $X->atom('STRING'),
	    0, 255);
    if ($type and $X->atom_name($type) eq 'STRING') {
	my ($name,$clas) = unpack('(Z*)*',$val);
	$task = delete $self->{wmclass}{$name} unless $task;
	$task = delete $self->{wmclass}{$clas} unless $task;
	$task->{WM_CLASS} = [ $name, $clas ] if $task;
    }
    ($val,$type) = $X->GetProperty($win,
	    $X->atom('_NET_WM_PID'),
	    $X->atom('CARDINAL'),
	    0, 1);
    if ($type and $X->atom_name($type) eq 'CARDINAL') {
	my $pid = unpack('L',$val);
	$task = delete $self->{starting}{$pid} unless $task;
	$task->{_NET_WM_PID} = $pid if $task;
	$task->{pid} = $pid if $task and not $task->{pid};
    }
    ($val,$type) = $X->GetProperty($win,
	    $X->atom('_NET_STARTUP_ID'),
	    $x->atom('UTF8_STRING'),
	    0, 1);
    if ($type and $x->atom_name($type) eq 'UTF8_STRING') {
	my $id = unpack('Z*',$val);
	$task = delete $self->{startnotify}{$id} unless $task;
	$task->{_NET_STARTUP_ID} = $id if $task;
	$self->send_sn_remove($id);
    }
    $self->task_running($task,'mapped window');
    return;
}

sub event_handler_UnmapNotify {
    my ($self,$e,$X,$v) = @_;
}

sub event_handler_CreateNotify {
    my ($self,$e,$X,$v) = @_;
}

sub event_handler_DestroyNotify {
    my ($self,$e,$X,$v) = @_;
}


=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

1;

# vim: sw=4 tw=72
