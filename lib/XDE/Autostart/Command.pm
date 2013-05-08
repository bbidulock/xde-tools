package XDE::Autostart::Command;
require XDE::Autostart;
use POSIX qw(setsid getpid :sys_wait_h);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Autostart::Command - an instance of an autostart command

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=item $cmd = XDE::Autostart::Command->B<new>(I<$autostart>,I<$command>)

=cut

sub new {
    my ($type,$owner,$command,$restart) = @_;
    if ($command =~ s{^\@}{}) {
	$restart = 1;
    }
    my $self = bless {
	cmd=>$command,
	restart=>$restart,
    }, $type;
    # we should probably check executability
    return $self;
}

=item $cmd->B<startup>(I<$autostart>)

=cut

sub startup {
    my ($self,$owner) = @_;
    my $pid = fork();
    unless (defined $pid) {
	warn "Cannot fork!";
	return;
    }
    if ($pid) {
	# we are the parent
	print STDERR "Child $pid started...\n"
	    if $owner->{ops}{verbose};
	$self->{pid} = $pid;
	$owner->{children}{$pid} = $self;
	$self->{watcher} = Glib::Child->watch_add($pid,
		sub{ $self->exited(@_) }, $owner);
    }
    else {
	# we are the child
	exec "$self->{cmd}" or exit 1;
    }
}

=item $cmd->B<shutdown>(I<$autostart>)

=cut

=item $cmd->B<exited>(I<$autostart>)

=cut

sub exited {
    my ($self,$pid,$waitstatus,$owner) = @_;
    delete $self->{watcher};
    delete $owner->{children}{$pid};
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
	$self->startup($owner);
    }
    else {
	if (scalar(keys %{$owner->{children}}) == 0) {
	    print STDERR "there goes our last female...\n";
	    Gtk2->main_quit;
	}
    }
}

=back

=cut

1;

