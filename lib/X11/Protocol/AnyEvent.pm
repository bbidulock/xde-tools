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
    my $self = X11::Protocol::new(@_);
    if ($self) {
	$self->{event_handler} = sub{
	    my($self,$e) = @_;
	    push @{$self->{ae}{events}}, \%e
		unless $self->{ae}{discard_events};
	};
	$self->{error_handler} = sub{
	    my($self,$e) = @_;
	    print STDERR "Received error: \n",
		  $self->format_error_msg($e), "\n";
	    push @{$self->{ae}{events}}, $e
		unless $self->{ae}{discard_errors};
	};
	$self->{ae}{watcher} = AE::io $self->fh, 0, sub{
	    $self->handle_input;
	    $self->process_queue;
	};
	$self->{ae}{quit} = AE::cv;
    }
    return $self;
}

=item $X->B<destroy>()

Shuts down the X11::Protocol connection and removes circular references
so that the object can be garbage collected.

=cut

sub destroy {
    my $self = shift;
    # remove circular references
    delete $self->{ae}{quit};
    delete $self->{ae}{watcher};
    $self->{event_handler} = sub{ };
    $self->{error_handler} = sub{ };
    $self->fh->flush;
    $self->purge_queue;
    $self->fh->close;
    return $self;
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
    my $self = shift;
    $self->GetScreenSaver;
    $self->process_queue;
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
    my $self = shift;
    if ($self->{ae}{discard_events} <= 1) {
	$self->process_queue;
    } else {
	$self->{ae}{discard_events} -= 1;
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
    my $self = shift;
    if ($self->{ae}{discard_errors} <= 1) {
	$self->process_queue;
    } else {
	$self->{ae}{discard_errors} -= 1;
    }
}

=item $X->B<purge_queue>() => $total or ($events, $errors)

Purges all pending events and errors from the event queue.  In scalar
context, returns the total number of messages purged.  Ih list context,
returns the number of events discarded and the number of errors
discarded.

=cut

sub purge_queue {
    my $self = shift;
    my $errors = 0;
    my $events = 0;
    while (my $e = shift @{$self->{ae}{events}}) {
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
    my $self = shift;
    my $errors = 0;
    my $events = 0;
    while (my $e = shift @{$self->{ae}{events}}) {
	if (ref $e eq 'HASH') {
	    next if $self->{ae}{discard_events};
	    $events += 1;
	    $self->event_handler($e);
	} else {
	    next if $self->{ae}{discard_errors};
	    $errors += 1;
	    $self->error_handler($e);
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
    my($self,$e) = @_;
    my $sub = $self->can("event_handler_$e->{name}");
    return &$sub($self,$e) if $sub;
    warn "Discarding unwanted $e->{name} event"
	if $self->{ops}{verbose};
}

=item $X->B<error_handler>(I<$e>)

Internal error handler used by the X11::Protocol::AnyEvent module.  The
defulat behaviour is to warn about the error.  This method may be
overridden by the module using this module as a base.

=cut

sub error_handler {
    my($self,$e) = @_;
    warn "Received error: \n", $self->format_error_msg($e);
}


=item $X->B<event_handler_PropertyNotify>(I<$e>)

Internal event handler used to dispatch C<PropertyNotify> enents.  this
method, when not overridden by the module using this module as a base,
will call the C<event_handler_PropertyNotify${atom}> method of the
derived class when a notification for property I<$atom> arrives.

=cut

sub event_handler_PropertyNotify {
    my($self,$e) = @_;
    my $atom = $self->GetAtomName($e->{atom});
    my $sub = $self->can("event_handler_PropertyNotify$atom");
    return &$sub($self,$e) if $sub;
    warn "Discarding unwanted $e->{name} for $atom event"
	if $self->{ops}{verbose};
}

=item $X->B<event_handler_ClientMessage>(I<$e>)

Internal event handler used to dispatch C<ClientMessage> events.  This
method, when not overridden by the derived class, will call the
C<event_handler_ClientMessage$type> method of the derived class when a
client message with type I<$type> arrives.

=cut

sub event_handler_ClientMessage {
    my($self,$e) = @_;
    my $type = $self->GetAtomName($e->{type});
    my $sub = $self->can("event_handler_ClientMessage$type");
    return &$sub($self,$e) if $sub;
    warn "Discarding unwanted $e->{name} for $type event"
	if $self->{ops}{verbose};
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
