package XDE::X11;
require X11::Protocol;
use base qw(X11::Protocol);
use Glib;
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::X11 - XDE wrapper module for X11::Protocol

=head1 SYNOPSIS

 my $X = XDE::X11->new();

=head1 DESCRIPTION

=head1 METHODS

=over

=item $X = B<new> XDE::X11 I<@OPTIONS> => blessed HASH

Creates a new X11::Protocol object and connects it to the X11 server.

=cut

sub new {
    return X11::Protocol::new(@_);
}

=item $X->B<init>($xde) => $X

Initializes the XDE::X11 protocol object.  This sets handlers and
initializes the Glib::Mainloop watchers for event-loop operation.
Initialization is not done automatically, because the owner of this
instance might want to set other things up before initializing the
mainloop.

C<$xde> is typically an L<XDE::Context> derived object, but can be any
object that implements (or not) B<event_handler> or B<_handle_error>
methods.  These methods will be called during normal operation of the
X11::Protocol connection and when invoked by Glib::Mainloop.

=cut

sub init {
    my ($self,$xde) = @_;
    $self->{event_handler} = sub{ $self->xde_event_handler(@_) };
    $self->{error_handler} = sub{ shift->xde_error_handler(@_) };
    $self->{xde}{event_handler} = sub{ $xde->event_handler(@_) };
    $self->{xde}{error_handler} = sub{ $xde->error_handler(@_) };
    Glib::Source->remove($self->{xde}{watcher})
	if $self->{xde}{watcher};
    $self->{xde}{watcher} = Glib::IO->add_watch($self->fd, 'in',
	    sub { $self->handle_input; $self->xde_process_queue;
		  return Glib::SOURCE_CONTINUE; });
    return $self;
}

sub term {
    my $self = shift;
    # release circular references
    Glib::Source->remove($self->{xde}{watcher})
	if $self->{xde}{watcher};
    $self->{event_handler} = sub{ };
    $self->{error_handler} = sub{ };
    delete $self->{xde}{event_handler};
    delete $self->{xde}{error_handler};
    $self->fh->flush();
    $self->xde_purge_queue;
    $self->fh->close();
}

=item $X->B<fh>() => IO::Handle

Returns the perl filehandle associated with the
L<X11::Protocol::Connection(3pm)> object.

=cut

sub fh {
    my $self = shift;
    return $self->{connection}->fh;
}

=item $X->B<fd>() => integer

Returns the UNIX file descriptor (number) associated with the
L<X11::Protocol::Connection(3pm)> object.

=cut


sub fd {
    my $self = shift;
    return fileno($self->fh);
}

=item $X->B<xde_discard_events>()

Asks the XDE::X11 module to discard events for the X connection until
a matching call to B<xde_process_events>.  Can be nested.

=cut

sub xde_discard_events {
    my $self = shift;
    $self->{xde}{discard_events} += 1;
}

=item $X->B<xde_process_events>

When matched by the outermost call to B<xde_discard_events> or when
called with no matching B<xde_discard_events>, marks that events are now
accepted and processes any queued events.  The queue should be purged
with B<xde_process_queue> before executing this method.

=cut

sub xde_process_events {
    my $self = shift;
    $self->{xde}{discard_events} -= 1;
    if ($self->{xde}{discard_events} <= 0) {
	$self->{xde}{discard_events} = 0;
	$self->xde_process_queue;
    }
}

=item $X->B<xde_discard_errors>()

Asks the XDE::X11 module to discard errors for the X connection until a
matching call to B<xde_process_errors>.  Can be nested.

=cut

sub xde_discard_errors {
    my $self = shift;
    $self->{xde}{discard_errors} += 1;
}

=item $X->B<xde_process_errors>()

When matched by the outermost call to B<xde_discard_errors> or when
called with no matching B<xde_discard_errors>, marks that errors are now
accepted and processes any queued events.  The queue should be purged
with B<xde_process_queue> before executing this method.

=cut

sub xde_process_errors {
    my $self = shift;
    $self->{xde}{discard_errors} -= 1;
    if ($self->{xde}{discard_errors} <= 0) {
	$self->{xde}{discard_errors} = 0;
	$self->xde_process_queue;
    }
}

=item $X->B<xde_purge_queue>() => $total or ($events,$errors)

Purges any pending events or errors from the event queue.  In scalar
context, returns the total number of messages purged.  In list context,
returns the number of events discarded and the number of errors
discarded.

=cut

sub xde_purge_queue {
    my $self = shift;
    my $errors = 0;
    my $events = 0;
    while (my $e = shift @{$self->{xde}{events}}) {
	if (ref($e) eq 'HASH') {
	    $events += 1;
	} else {
	    $errors += 1;
	}
    }
    return $events + $errors unless wantarray;
    return ($events, $errors);
}

=item $X->B<xde_process_queue>() => $total or ($events,$errors)

Process queued events and errors.  This method is called internally
before entering the main event loop.  It also may be called directly by
the user of this module at any time to process queued events.  In scalar
context, returns the total number of messages processed.  In list
context, returns the number of events and number of errors processed.

=cut

sub xde_process_queue {
    my $self = shift;
    my $errors = 0;
    my $events = 0;
    while (my $e = shift @{$self->{xde}{events}}) {
	if (ref $e eq 'HASH') {
	    next if $self->{xde}{discard_events};
	    $self->{xde}{event_handler}->(%$e) if
	    $self->{xde}{event_handler};
	    $events += 1;
	} else {
	    next if $self->{xde}{discard_errors};
	    $self->{xde}{error_handler}->($e) if
	    $self->{xde}{error_handler};
	    $errors += 1;
	}
    }
    return $events + $errors unless wantarray;
    return ($events, $errors);
}

=item $X->B<xde_event_handler>(I<%e>)

Internal event handler used by XDE::X11 on the X11::Protocol connection. 

=cut

sub xde_event_handler {
    my ($self,%e) = @_;
    push @{$self->{xde}{events}}, \%e
	unless $self->{xde}{discard_events};
}

=item $X->B<xde_error_handler>(I<$e>)

Internal error handler used by XDE::X11 on the X11::protocol connection.

=cut

sub xde_error_handler {
    my ($self,$e) = @_;
    print STDERR "Received error: \n",
        $self->format_error_msg($e);
    push @{$self->{xde}{events}}, $e
	unless $self->{xde}{discard_errors};
}

=back

=cut

1;
__END__

# vim: sw=4 tw=72
