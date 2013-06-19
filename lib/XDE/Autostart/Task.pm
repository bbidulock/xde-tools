package XDE::Autostart::Task;
require XDE::Autostart;
use POSIX qw(setsid getpid :sys_wait_h);
use Glib qw(TRUE FALSE);
use Gtk2;
use Time::HiRes;
use strict;
use warnings;

our %wmclass = ();

=head1 NAME

XDE::Autostart::Task - an instance of an autostart task

=head1 SYNOPSIS

 require XDE::Autostart;
 require XDE::Autostart::Task;

 my $xde = XDE::Autostart->new(%OVERRIDES,ops=>\%ops);
 $xde->getenv();
 my $task = XDE::Autostart::Task->new($xde,$entry);
 $xde->init();
 $task->startup($xde);
 $task->shutdown($xde);
 $xde->main();
 $xde->term();

=head1 DESCRIPTION

The B<XDE::Autostart::Task> module provides an object-oriented approach
to XDG autostart.

=head1 METHODS

=over

=item $task = XDE::Autostart::Task->B<new>(I<$xde>,I<$entry>)

Creates a new autostart task entry using the F<.desktop> C<$entry> hash.
The C<$entry> is a simple hash that has a key-value pair for each of the
F<.desktop> entry fields that were read from the F<.desktop> file.  If
the entry passed is of I<Type> C<XSession> instead of C<Application> it
will be treated as the window manager.  Commands to be executed before
the window manager starts are not true F<.desktop> entries and require
only an I<Exec> field.  Nothing is created at this point, just the
instance is established: B<startup> must be called to actually start
anything going.

It is expected that the C<$entry> has been completed by
XDG::Context::get_autostart() which fills out the I<X-Disable> and
I<X-Disable-Reason> fields when the item should not be autostarted.
Window manager and Execute entries will not have these fields.
Restartable execute commands should have their I<X-Restart> fields set
to C<true>; however, the method checks if the command starts with C<@>
and sets this field when that is the case.

=cut

sub new {
    my ($type,$xde,$entry) = @_;
    my $self = bless $entry, $type;
    $self->{cmd} = $self->{Exec} unless $self->{cmd};
    $self->{cmd} = '' unless $self->{cmd};
    if ($self->{cmd} =~ s{^\@}{}) {
	$self->{'X-Restart'} = 'true';
    }
    $self->{verbose} = $xde->{ops}{verbose};
    $self->{count} = 0;
    return $self;
}

=item $task->B<new_button>(I<$autostart>)

Creates a new button on the autostart display for this task.  The button
will be available in C<$self-E<gt>{button}>.

=cut

sub new_button {
    my ($self,$xde) = @_;
    return $self if $self->{button};  # indempotent
    my ($name,$icon,$b,$t,$c,$r);
    $name = $self->{Icon};
    $name =~ s{\.{xpm|svg|png|tif|tiff|jpg}$}{};
    if ($name) {
	my $theme = Gtk2::IconTheme->get_default;
	if ($theme->has_icon($name)) {
	    $icon = Gtk2::Image->new_from_icon_name($name,'dialog');
	}
    }
    unless ($icon) {
	$icon = Gtk2::Image->new_from_stock('gtk-execute','dialog');
    }
    $b = Gtk2::Button->new;
    $b->set_image_position('top');
    $b->set_image($icon);
    if ($self->{Name}) {
	#$b->set_label($self->{Name});
	$b->set_tooltip_text($self->{Name});
    }
    $t = $xde->{table};
    $r = $xde->{row};
    $c = $xde->{col};
    $t->attach_defaults($b,$c,$c+1,$r,$r+1);
    $b->set_sensitive(FALSE);
    $b->show_all;
    $b->show_now;
    if ($c > $xde->{cols}) {
	$c = 0; $r = $r+1;
	$xde->{row} = $r;
    }
    $xde->{col} = $c;
    unless ($self->{'X-Disable'} and $self->{'X-Disable'} =~ m{true|yes|1}i) {
	$b->set_sensitive(TRUE);
	$b->show_now;
    }
    $self->{button} = $b;
    return $self;
}

=item $task->B<startup_timeout>(I<$xde>)

Internal method called when the 2-second startup timer expires.
Depending whether startup notification was expected, this procedure may
warn that the startup notification was incorrect (this timer would not
fire unless the notification was correct).

=cut

sub startup_timeout {
    my ($self,$xde) = @_;
    delete $self->{timeout};
    if (my $pid = $self->{pid}) {
	delete $xde->{starting}{$pid};
    }
    if (my $name = $self->{StartupWMClass}) {
	delete $xde->{wmclass}{$name}
	    if $xde->{wmclass}{$name} and $xde->{wmclass}{$name} eq $self;
	warn "child did not map window '$name': $self->{cmd}";
    }
    if (my $id = $self->{DESKTOP_STARTUP_ID}) {
	delete $xde->{startnotify}{$id};
    }
    if ($self->{StartupNotify} and $self->{StartupNotify} =~ m{true|yes|1}i) {
	warn "child did not notify: $self->{cmd}";
    }
    $self->{state} = 'running';
    $self->{status} = 'startup timeout expired';
    if (my $b = $self->{button}) {
	$b->set_sensitive(TRUE);
	$b->show_now;
    }
    if (scalar(%{$xde->{starting}}) == 0) {
	if (my $sub = $xde->can("autostart_done_$xde->{phase}")) {
	    &$sub($xde);
	}
    }
    return Glib::SOURCE_REMOVE;
}

=item $task->B<startup>(I<$xde>)

Starts up and autostart task under the task owner provided in the
I<$xde> argument.

This method is a little more complex than that provided by the base
class XDE::Autostart::Command.  This is because we have more information
and can perform proper startup notification.  We can also monitor for
the appearance of a window of a given name or class.  We can also
provide a range of information on task failure and provide the user with
the option to restart the task via notification.

=cut

sub startup {
    my ($self,$xde) = @_;
    $self->new_button unless $self->{button};
    if ($self->{'X-Disable'} and $self->{'X-Disable'} =~ m{true|yes|1}i) {
	$self->{state} = 'disabled';
	return;
    }
    my $id = $self->{DESKTOP_STARTUP_ID} = $xde->newsnid();
    $xde->send_sn_new($id,{
	ID=>$id,
	NAME=>$self->{Name},
	SCREEN=>$xde->{screen}->get_number,
	BIN=>$self->{TryExec},
	ICON=>$self->{Icon},
	DESKTOP=>0,
	TIMESTAMP=>Gtk2::Gdk::X11->get_server_time($xde->{root}),
	DESCRIPTION=>$self->{Comment},
	WMCLASS=>$self->{StartupWMClass},
	SILENT=>(($self->{StartupNotify} and $self->{StartupNotify} =~ m{true|yes|1}i) or $self->{StartupWMClass}) ? 0 : 1,
    });
    if (my $name = $self->{StartupWMClass}) {
	# We are expecting a window with name or class strings equal to
	# $name to be mapped on startup.
	$xde->{wmclass}{$name} = $self;
    }
    if ($self->{StartupNotify} and $self->{StartupNotify} =~ m{true|yes|1}i) {
        # We are expecting the task to perform startup notification when
	# it is ready.
	$xde->{startnotify}{$id} = $self;
    }
    $ENV{DESKTOP_STARTUP_ID} = $id;
    my $pid = fork();
    unless (defined $pid) {
	warn "cannot fork!";
	return;
    }
    if ($pid) {
	# we are the parent
	delete $ENV{DESKTOP_STARTUP_ID};
	print STDERR "Child $pid started...\n" if $self->{verbose};
	$self->{pid} = $pid;
	$self->{time} = Time::HiRes::time;
	$self->{count} += 1;
	$xde->{children}{$pid} = $self;
	$xde->{starting}{$pid} = $self;
	$self->{state} = 'starting';
	$self->{watcher} = Glib::Child->watch_add($pid,
		sub { $self->child_exited(@_) }, $xde);
	$self->{timeout} = Glib::Timeout->add(2000,
		sub { $self->startup_timeout($xde) });
	return $pid;
    }
    else {
	# we are the child
	$ENV{DESKTOP_STARTUP_ID} = $id;
    }
}

=item $task->B<restart>(I<$xde>) => {0|1|$pid}

Internal function called to restart the command when the command is
marked as restartable.  A comparison is made between the time that the
command was last started and the current time to determine whether the
command is restarting too fast.  We only allow 3 restarts per second and
only allow a maximum of 10 restarts.

=cut

sub restart {
    return SUPER::restart(@_);
}

=item $task->B<shutdown>(I<$xde>)

This method is responsible for shutting down an autostart task.  If the
command is being throttled due to too rapid restarts, the restart time
is simply stopped.  When the command is running, we send it a C<SIGTERM>
and if it does not shut down in 2 seconds, we will send it a C<SIGKILL>
signal.

=cut

# FIXME: we should really check whether we are in the startup state.

sub shutdown {
    my ($self,$xde) = @_;
    if ($self->{throttle}) {
	Glib::Source->remove(delete $self->{throttle});
	return;
    }
    if ($self->{pid}) {
	# tasks have 2 seconds to shutdown or get killed with prejudice
	$self->{shutdown} = Glib::Timeout->add(2000,sub{
		delete $self->{shutdown};
		kill -KILL $self->{pid} if $self->{pid};
		return Glib::SOURCE_REMOVE;
	});
	kill -TERM $self->{pid};
	return;
    }
    print STDERR "Command $self->{cmd} is not running...\n";
    return;
}

=item $task->B<cleanup>(I<$xde>,I<$state>)

This internal method cleans up the state of the task once it has exited.
It sets the exit state and removes any startup or running watchers and
removes it from any lists.

=cut

sub cleanup {
    my ($self,$xde,$state,$status) = @_;
    $self->{state} = $state;
    $self->{status} = $status;
    if (my $pid = delete $self->{pid}) {
	delete $xde->{children}{$pid};
	delete $xde->{starting}{$pid};
    }
    if (my $name = $self->{StartupWMClass}) {
	delete $xde->{wmclass}{$name};
    }
    if (my $id = $self->{DESKTOP_STARTUP_ID}) {
	delete $xde->{startnotify}{$id};
    }
    foreach (qw(watcher starting timeout shutdown)) {
	if (my $tag = delete $self->{$_}) {
	    Glib::Source->remove($tag);
	}
    }
}

=item $task->B<child_exited>(I<$pid>,I<$waitstatus>,I<$xde>)

This method is called internally by a child watcher when the child
exits or receives a signal.

=cut

sub child_exited {
    my ($self,$pid,$waitstatus,$xde) = @_;
    delete $self->{watcher};
    delete $xde->{children}{$pid};
    if (WIFEXITED($waitstatus)) {
	my $status = WEXITSTATUS($waitstatus);
	if ($status) {
	    warn "child $pid exited with status $status" if $status;
	    $self->cleanup($xde,'abnormal',"exited with status $status");
	}
	elsif ($self->{Type} eq 'XSession') {
	    print STDERR "Window manager exited normally\n";
	    $xde->wmexited($self,$pid,$waitstatus);
	    $self->cleanup($xde,'exited',"WM exited normally");
	}
	else {
	    print STDERR "child $pid exited normally\n";
	    $self->cleanup($xde,'exited',"exited normally");
	}
    }
    elsif (WIFSIGNALED($waitstatus)) {
	my $signal = WTERMSIG($waitstatus);
	warn "child $pid exited on signal $signal" if $signal;
	$self->cleanup($xde,'signal',"terminated on signal $signal");
    }
    elsif (WIFSTOPPED($waitstatus)) {
	warn "child $pid stopped";
	$self->shutdown($xde);
	return;
    }
    if ($self->{state} ne 'exited' and
	    $self->{'X-Restart'} and
	    $self->{'X-Restart'} =~ m{true|yes|1}i) {
	print STDERR "restarting $pid with $self->{cmd}\n";
	$self->restart($xde);
    }
    else {
	if (scalar(keys %{$xde->{children}}) == 0) {
	    print STDERR "there goes our last female...\n";
	    $xde->shutdown_complete();
	}
    }
}

=item $task->B<mapnotify>(I<$xde>,I<$name>,I<$class>,I<$wpid>,I<$wid>)

Called by the task manager when it is detected that the task has mapped
a window.  This can be called for two reasons:

=over

=item 1.

The task has mapped a window that matches the I<StartupWMClass> field of
the task and the window may or may not have a B<_NET_WM_PID> property
that matches the C<$wpid> of the task.  This is a normal startup case.
WHen the C<$wpid> does not match the C<$wpid> of the task and the task has
exitted with a zero status, it may have daemonized itself and the
C<$wpid> is the pid of the daemon process.  It should perhaps be recorded
and used to kill the task later.

=item 2.

The task has mapped a window with a B<_NET_WM_PID> property that matches
the C<$wpid> of the task.  When there is no I<StartupWMClass> field and
I<StartupNotify> is C<false> or missing, this is an indication that the
F<.desktop> specification needs a I<StartupWMClass> defined.  Perhaps a
notification is worthwhile.

=back

Note that C<$wid> is the value of the B<_NET_STARTUP_ID> property on the
mapped window.  When available, this should always match
C<$xde-E<gt>{DESKTOP_STARTUP_ID}>, otherwise the window is invalid.

Quite frankly all that we care is that if the window manager maps a
window that we can recognize (_WM_CLASS, _NET_WM_PID or _NET_STARTUP_ID)
we will consider it started.  Because we only get called in that case
(we cannot find the task for any other window), simply mark the task as
running.

=cut

sub mapnotify {
    my ($self,$xde) = @_;
    if (my $name = $self->{StartupWMClass}) {
	delete $xde->{wmclass}{$name};
    }
    if (my $id = $self->{DESKTOP_STARTUP_ID}) {
	delete $xde->{startnotify}{$id};
    }
    if (my $pid = $self->{pid}) {
	delete $xde->{starting}{$pid};
	$xde->{running}{$pid} = $self;
    }
    if (my $tag = delete $self->{timeout}) {
	Glib::Source->remove($tag);
    }
    $self->{state} = 'running';
    $self->{status} = 'mapped window';
}

=back

=head1 HISTORY

Unfortunately, XDG autostart has a number of basic deficiencies:

=over

=item 1.

There is no (standard) way of specifying what needs to be started before
a window manager and what needs to be started after a window manager.

=item 2.

There is no (standard) way of specifying the order of startup.

=back

Nevertheless, we separate XDG autostart tasks into three classes:

=over

=item 1.

Entries that are started before the window manager.  These are
entries that do not depend upon the window manager being present.  This
is the default when it cannot be determined into which class the entry
belongs.

=item 2.

The window manager itself.

=item 3.

Entries that need to be started after the window manager.  This is
normally so that the window manager will not mess with these
applications during its startup.  An example is DockApps, TrayIcon, and
desktop applications such as L<idesk(1)>.  XDE determines these by
looking in the C<Category> field of the entry.  DockApps and TrayIcons
are started after the window manager.  Any entries with the field
C<X-After-WM> set to C<true> will be started after the window manager
has confirmed to be started.

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

1;

# vim: sw=4 tw=72
