package XDE::Autostart::Command;
require XDE::Autostart;
use POSIX qw(setsid getpid :sys_wait_h);
use Glib qw(TRUE FALSE);
use Gtk2;
use Time::HiRes;
use strict;
use warnings;

=head1 NAME

XDE::Autostart::Command - an instance of an autostart command

=head1 DESCRIPTION

This modules is responsible for representing a single autostart command,
including its current state and options associated with the command.

=head1 METHODS

The following methods are provided:

=over

=item B<new> XDE::Autostart::Command I<$xde>,I<$command>,I<$restart> => $cmd

Create a new instance of an autostart command for the
L<XDE::Context(3pm)> object, C<$xde>, with the command line to execute,
I<$command>, and a boolean value indicating whether to restart the
command on abnormal termination, I<$restart>.

=cut

sub new {
    my ($type,$xde,$command,$restart) = @_;
    if ($command =~ s{^\@}{}) { $restart = 1 }
    my $self = bless {
	cmd=>$command,
	restart=>$restart,
	verbose=>$xde->{ops}{verbose};
    }, $type;
    # we should probably check executability
    return $self;
}

=item $cmd->B<startup>(I<$xde>) => $pid

Starts the command and returns the C<$pid> of the child process.  The
child process is monitored for exit and a 2 second startup timer is
established.

=cut

sub startup {
    my ($self,$xde) = @_;
    my $pid = fork();
    unless (defined $pid) {
	warn "Cannot fork!";
	return;
    }
    if ($pid) {
	# we are the parent
	print STDERR "Child $pid started...\n" if $self->{verbose};
	$self->{pid} = $pid;
	$self->{time} = Time::HiRes::time;
	$self->{count} += 1;
	$xde->{children}{$pid} = $self;
	$xde->{starting}{$pid} = $self;
	$self->{watcher} = Glib::Child->watch_add($pid,
		sub{ $self->exited(@_) }, $xde);
	$self->{timeout} = Glib::Timeout->add(2000,sub{
		delete $self->{timeout};
		delete $xde->{starting}{$self->{pid}};
		$self->{state} = 'starting';
		return Glib::SOURCE_REMOVE;
	});
	return $pid;
    }
    else {
	# we are the child
	exec "$self->{cmd}" or exit 1;
    }
}

=item $cmd->B<restart>(I<$xde>) => {0|1|$pid}

Internal function called to restart the command when the command is
marked as restartable.  A comparison is made between the time that the
command was last started and the current time to determine whether the
command is restarting too fast.  We only allow 3 restarts per second and
only allow a maximum of 10 restarts.

=cut

sub restart {
    my ($self,$xde) = @_;
    if ($self->{count} >= 10) {
	print STDERR "Command $self->{cmd} restarted 10 times...\n";
	return 0;
    }
    my $time = Time::HiRes::time;
    my $rate = 1.0/($time - $self->{time});
    if ($rate >= 3.0) {
	print STDERR "Command $self->{cmd} restarting $rate times a second...\n";
	print STDERR "Not restarting for 2 seconds...\n";
	$self->{throttle} = Glib::Timeout->add(2000,sub{
		delete $self->{throttle};
		$self->restart($xde);
		return Glib::SOURCE_REMOVE;
	});
	return 1;
    }
    return $self->startup($xde);
}

=item $cmd->B<shutdown>(I<$xde>)

This method shuts down the command.  If the command is being throttled
due to too rapid restarts, the restart timer is simply stopped.  When
the command is running, we send it a C<SIGTERM> and if it does not shut
down in 2 seconds, we will send it a C<SIGKILL> signal.

=cut

sub shutdown {
    my $self = shift;
    if ($self->{throttle}) {
	Glib::Source->remove($self->{throttle});
	return;
    }
    if ($self->{pid}) {
	# we have 2 seconds to shutdown or get killed with prejudice
	$self->{shutdown} = Glib::Timeout->add(2000,sub{
		delete $self->{shutdown};
		if ($self->{pid}) {
		    kill -KILL $self->{pid};
		}
		return Glib::SOURCE_REMOVE;
	});
	kill -TERM $self->{pid};
	return;
    }
    print STDERR "Command $self->{cmd} is not running...\n";
}

=back

=head2  Event handlers

The following are internal event handlers that are not meant to be
called directly by the module user.

=over

=item $cmd->B<exited>(I<$xde>)

Internal function called by the Glib::Child watcher when the child
process exits.

=cut

sub exited {
    my ($self,$pid,$waitstatus,$xde) = @_;
    delete $self->{watcher};
    delete $xde->{children}{$pid};
    if (WIFEXITED($waitstatus)) {
	if (my $status = WEXITSTATUS($waitstatus)) {
	    warn "child $pid exited with status $status" if $status;
	}
	elsif ($self->{windowmanager}) {
	    print STDERR "Window manager exited normally\n";
	    # NOTE: this is the point at which we should invoke
	    #	    XDE::Logout instead of invoking an external
	    #	    program.
	    if (-x "/usr/bin/xde-logout") {
		system("/usr/bin/xde-logout");
	    }
	    else {
		Gtk2->main_quit;
	    }
	}
    }
    elsif (WIFSIGNALED($waitstatus)) {
	my $signal = WTERMSIG($waitstatus);
	warn "child $pid exited on signal $signal" if $signal;
    }
    elsif (WIFSTOPPED($waitstatus)) {
	warn "child $pid stopped";
	kill -TERM $pid;
    }
    if ($self->{restart}) {
	print STDERR "restarting $pid with $self->{cmd}\n";
	$self->restart($xde);
    }
    else {
	if (scalar(keys %{$xde->{children}}) == 0) {
	    print STDERR "there goes our last female...\n";
	    Gtk2->main_quit;
	}
    }
}

=item $cmd->B<started>(I<$xde>)

Internal function called by the event loop once it has detected that the
child process has started.  This is either because of startup
notification, mapping of a window with WM_CLASS(name,class); or
expiration of the 2-second guard timer.

=cut

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<POSIX(3pm)>.

=cut

# vim: sw=4 tw=72
