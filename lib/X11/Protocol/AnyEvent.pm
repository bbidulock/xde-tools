package X11::Protocol::AnyEvent;
use base qw(X11::Protocol);
use AnyEvent;
use strict;
use warnings;

=head1 NAME

X11::Protocol::AnyEvent - event loop for X11::Protocol

=head1 SYNOPSIS

 use AnyEvent;
 use X11::Protocol::AnyEvent;

 package MyX11Protocol;
 use base qw(X11::Protocol::AnyEvent);
 sub event_handler { shift->main_quit }

 package main;

 my $X = MyX11Protocol->new();

 $X->main;
 $X->destroy;
 undef $X;

=head1 DESCRIPTION

This module provides an event loop and base dispatcher for
L<X11::Protocol(3pm)>.

=head1 METHODS

The following methods are provided:

=over

=item $X = X11::Protocol::AnyEvent->B<new>(I<@args>)

Creates a new X11::Protocol::AnyEvent instance.  I<@args> are passed
directly to X11::Protocol::new().

=cut

sub new {
    my $X = X11::Protocol::new(@_);
    if ($X) {
	$X->{event_handler} = sub{
	    my($X,$e) = @_;
	    push @{$X->{ae}{events}}, \%e
		unless $X->{ae}{discard_events};
	};
	$X->{error_handler} = sub{
	    my($X,$e) = @_;
	    print STDERR "Received error: \n",
		  $X->format_error_msg($e), "\n";
	    push @{$X->{ae}{events}}, $e
		unless $X->{ae}{discard_errors};
	};
	$X->{ae}{watcher} = AE::io $X->fh, 0, sub{
	    $X->handle_input;
	    $X->process_queue;
	};
	$X->{ae}{quit} = AE::cv;
    }
    return $X;
}

=item $X->B<destroy>()

Shuts down the X11::Protocol connection and removes circular references
so that the object can be garbage collected.

=cut

sub destroy {
    my $X = shift;
    # remove circular references
    delete $X->{ae}{quit};
    delete $X->{ae}{watcher};
    $X->{event_handler} = sub{ };
    $X->{error_handler} = sub{ };
    $X->fh->flush;
    $X->purge_queue;
    $X->fh->close;
    return $X;
}

=item $X->B<fh>() => $fh

Returns the file handle of the X11::Protocol::Connection that is used to
communicate with the X Server.  This file handle can be used in IO
watchers.

=cut

sub fh {
    return shift->{connection}->fh;
}

=item $X->B<fd> => $fd

Returns the file number of the X11::Protocol::Connection that is used to
communicate with the X Server.  This file descriptor can be used in IO
watchers.

=cut

sub fd {
    return fileno(shift->fh);
}

=item $X->B<main>

Convenience function for running the event loop until some callback
calls main_quit().  This function synchronizes the X event queue and
processes any pending messages before entering the event loop for the
first time.

=cut

sub main {
    my $X = shift;
    $X->GetScreenSaver;
    $X->process_queue;
    shift->{ae}{quit}->recv;
}

=item $X->B<main_quit>

Convenience function for exiting the event loop invoked by main().

=cut

sub main_quit {
    shift->{ae}{quit}->send;
}

=item $X->B<discard_events>()

Causes all events received after the call to be discarded:
process_events() must be called to undo the actions of discard_events().
The calls can be nested.
This does not discard events from the queue until they are removed for
processing.

=cut

sub discard_events {
    shift->{ae}{discard_events} += 1;
}

=item $X->B<process_events>()

Process events after the call, cancelling a nested discard_events()
call.  This does not affect events already in queue.
The queue should be purged with process_queue() before calling this
method.

=cut

sub process_events {
    my $X = shift;
    if ($X->{ae}{discard_events} <= 1) {
	$X->process_queue;
    } else {
	$X->{ae}{discard_events} -= 1;
    }
}

=item $X->B<discard_errors>()

Causeds all errors received after the call to be discarded:
process_errors() must be called to undo the actions of discard_errors().
The calls can be nested.
This does not discard errors from the queue until they are removed for
processing.

=cut

sub discard_errors {
    shift->{ae}{discard_errors} += 1;
}

=item $X->B<process_errors>()

Process errors after the call, cancelling a nested discard_errors()
call.  This does not affect errors already in queue.
The queue should be purged with process_queue() before calling this
method.

=cut

sub process_errors {
    my $X = shift;
    if ($X->{ae}{discard_errors} <= 1) {
	$X->process_queue;
    } else {
	$X->{ae}{discard_errors} -= 1;
    }
}

=item $X->B<purge_queue>() => $total or ($events, $errors)

Purges all pending events and errors from the event queue.  In scalar
context, returns the total number of messages purged.  Ih list context,
returns the number of events discarded and the number of errors
discarded.

=cut

sub purge_queue {
    my $X = shift;
    my $errors = 0;
    my $events = 0;
    while (my $e = shift @{$X->{ae}{events}}) {
	if (ref $e eq 'HASH') {
	    $events += 1;
	} else {
	    $errors += 1;
	}
    }
    return $events + $errors unless wantarray;
    return ($events, $errors);
}

=item $X->B<process_queue>() => $total or ($events, $errors)

Process queued events and errors.  This method is called internally
before entering the main event loop.  It also may be called

=cut

sub process_queue {
    my $X = shift;
    my $errors = 0;
    my $events = 0;
    while (my $e = shift @{$X->{ae}{events}}) {
	if (ref $e eq 'HASH') {
	    next if $X->{ae}{discard_events};
	    $events += 1;
	    $X->event_handler($e);
	} else {
	    next if $X->{ae}{discard_errors};
	    $errors += 1;
	    $X->error_handler($e);
	}
    }
    return $events + $errors unless wantarray;
    return ($events, $errors);
}

=item $X->B<event_handler>(I<$e>)

Internal event handler used by the X11::Protocol::AnyEvent module.  The
default behaviour is to call a method named
C<event_handler_$e-E<gt>{name}> if it exists.

=cut

sub event_handler {
    my($X,$e) = @_;
    my $sub = $X->can("event_handler_$e->{name}");
    return &$sub($X,$e) if $sub;
    warn "Discarding unwanted $e->{name} event"
	if $X->{ops}{verbose};
}

=item $X->B<error_handler>(I<$e>)

Internal error handler used by the X11::Protocol::AnyEvent module.  The
defulat behaviour is to warn about the error.  This method may be
overridden by the module using this module as a base.

=cut

sub error_handler {
    my($X,$e) = @_;
    warn "Received error: \n", $X->format_error_msg($e);
}

sub _time_less_than {
    my($one,$two) = @_;
    return 0 unless $two;
    return 0 if $two eq 'CurrentTime';
    return 1 unless $one;
    return 1 if $one eq 'CurrentTime';
    return unpack('l',pack('l',$one-$two)) < 0;
}

sub _update_current_time {
    my($X,$e) = @_;
    $X->{current_time} = $e->{time}
	if _time_less_than($X->{current_time},$e->{time});
}


=item $X->B<event_handler_PropertyNotify>(I<$e>)

Internal event handler used to dispatch C<PropertyNotify> events.  This
method, when not overridden by the module using this module as a base,
will call the C<event_handler_PropertyNotify${atom}> method of the
derived class when a notification for property I<$atom> arrives.

This method also automatically updates properties named I<$atom> for any
window that has C<PropertyNotify> events selected and a corresponding
C<get$atom> method exists.  The results of the corresponding C<get$atom>
operations are stored in
C<$X-E<gt>{windows}{$win}{$atom}>, where I<$win> is the window for which
the property named I<$atom> has changed or been deleted.
C<$X-E<gt>{windows}{$win}{proptimes}{$atom}> is updated with the time of
the last change.

This method updates C<$X-E<gt>{current_time}> with the current X server
time.

=cut

sub event_handler_PropertyNotify {
    $_[0]->_update_current_time($_[1]);
    my($X,$e) = @_;
    my $atom = $X->atom_name($e->{atom});

    # automatically update properties
    my $win = $e->{window};
    if (_time_less_than($X->{windows}{$win}{proptimes}{$atom},$e->{time})) {
	$X->{windows}{$win}{proptimes}{$atom} = $e->{time};
	if ($e->{state} eq 'NewValue') {
	    if (my $sub = $X->can("get$atom")) {
		if (defined(my $result = &$sub($X,$e->{window}))) {
		    $X->{windows}{$win}{$atom} = $result;
		} else {
		    delete $X->{windows}{$win}{$atom};
		}
	    }
	}
	elsif ($e->{state} eq 'Deleted') {
	    delete $X->{windows}{$win}{$atom};
	}
    }

    my $sub = $X->can("event_handler_$e->{name}$atom");
    return &$sub($X,$e) if $sub;
    warn "Discarding unwanted $e->{name} for $atom event"
	if $X->{ops}{verbose};
}

=item $X->B<event_handler_ClientMessage>(I<$e>)

Internal event handler used to dispatch C<ClientMessage> events.  This
method, when not overridden by the derived class, will call the
C<event_handler_ClientMessage$type> method of the derived class when a
client message with type I<$type> arrives.

This method updates C<$X-E<gt>{current_time}> with the current X server
time.

=cut

sub event_handler_ClientMessage {
    $_[0]->_update_current_time($_[1]);
    my($X,$e) = @_;
    my $atom = $X->atom_name($e->{type});
    my $sub = $X->can("event_handler_$e->{name}$atom");
    return &$sub($X,$e) if $sub;
    warn "Discarding unwanted $e->{name} for $atom event"
	if $X->{ops}{verbose};
}

=item $X->B<event_handler_SelectionRequest>(I<$e>)

Internal event handler used to dispatch C<SelectionRequest> events.
This method, when not overridden by the derived class, will call the
C<event_handler_SelectionRequest$selection> method of the derived class
when a client message with selection I<$selection> arrives.

This method updates C<$X-E<gt>{current_time}> with the current X server
time.

=cut

sub event_handler_SelectionRequest {
    $_[0]->_update_current_time($_[1]);
    my($X,$e) = @_;
    my $atom = $X->atom_name($e->{selection});
    my $sub = $X->can("event_handler_$e->{name}$atom");
    return &$sub($X,$e) if $sub;
    warn "Discarding unwanted $e->{name} for $atom event"
	if $X->{ops}{verbose};
}

=item $X->B<event_handler_SelectionClear>(I<$e>)

Internal event handler used to dispatch C<SelectionClear> events.  This
method, when not overridden by the derived class, will call the
C<event_handler_SelectionClear$selection> method of the derived class
when a client message with selection I<$selection> arrives.

This method updates C<$X-E<gt>{current_time}> with the current X server
time.

=cut

sub event_handler_SelectionClear {
    $_[0]->_update_current_time($_[1]);
    my($X,$e) = @_;
    my $atom = $X->atom_name($e->{selection});
    my $sub = $X->can("event_handler_$e->{name}$atom");
    return &$sub($X,$e) if $sub;
    warn "Discarding unwanted $e->{name} for $atom event"
	if $X->{ops}{verbose};
}

=item $X->B<event_handler_SelectionNotify>(I<$e>)

Internal event handler used to dispatch C<SelectionNotify> events.  This
method, when not overridden by the derived class, will call the
C<event_handler_SelectionNotify$selection> method of the derived class
when a client message with selection I<$selection> arrives.

This method updates C<$X-E<gt>{current_time}> with the current X server
time.

=cut

sub event_handler_SelectionNotify {
    $_[0]->_update_current_time($_[1]);
    my($X,$e) = @_;
    my $atom = $X->atom_name($e->{selection});
    my $sub = $X->can("event_handler_$e->{name}$atom");
    return &$sub($X,$e) if $sub;
    warn "Discarding unwanted $e->{name} for $atom event"
	if $X->{ops}{verbose};
}

=item $X->B<event_handler_KeyPress>(I<$e>)

This method simply updates C<$X-E<gt>{current_time}> with the current X
server time.

=cut

sub event_handler_KeyPress {
    $_[0]->_update_current_time($_[1]);
}

=item $X->B<event_handler_KeyRelease>(I<$e>)

This method simply updates C<$X-E<gt>{current_time}> with the current X
server time.

=cut

sub event_handler_KeyRelease {
    $_[0]->_update_current_time($_[1]);
}

=item $X->B<event_handler_ButtonPress>(I<$e>)

This method simply updates C<$X-E<gt>{current_time}> with the current X
server time.

=cut

sub event_handler_ButtonPress {
    $_[0]->_update_current_time($_[1]);
}

=item $X->B<event_handler_ButtonRelease>(I<$e>)

This method simply updates C<$X-E<gt>{current_time}> with the current X
server time.

=cut

sub event_handler_ButtonRelease {
    $_[0]->_update_current_time($_[1]);
}

=item $X->B<event_handler_EntryNotify>(I<$e>)

This method simply updates C<$X-E<gt>{current_time}> with the current X
server time.

=cut

sub event_handler_EntryNotify {
    $_[0]->_update_current_time($_[1]);
}

=item $X->B<event_handler_LeaveNotify>(I<$e>)

This method simply updates C<$X-E<gt>{current_time}> with the current X
server time.

=cut

sub event_handler_LeaveNotify {
    $_[0]->_update_current_time($_[1]);
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::Protocol(3pm)>,
L<AnyEvent(3pm)>,
L<AE(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
