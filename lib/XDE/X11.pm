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
object that implements (or not) B<_handle_event> or B<_handle_error>
methods.  These methods will be called during normal operation of the
X11::Protocol connection and when invoked by Glib::Mainloop.

=cut

sub init {
    my ($self,$xde) = @_;
    $self->_set_handlers($xde);
    $self->_set_watcher;
    return $self;
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

=item $X->B<_unset_watcher>() => $tag

Unsets a L<Glib::Mainloop(3pm)> B<Glib::IO::add_watch> handler for the
L<X11::Protocol::Connection(3pm)> associated with the X client.
Returns the removed Glib::Source tag.

=cut

sub _unset_watcher {
    my $self = shift;
    my $tag = delete $self->{watcher};
    Glib::Source->remove($tag) if $tag;
    return $tag;
}

=item $X->B<_set_watcher>() => $tag

Sets a L<Glib::Mainloop(3pm)> B<Glib::IO::add_watch> handler for the
L<X11::Protocol::Connection(3pm)> associated with the X client.
Returns the established Glib::Source tag.

=cut

sub _set_watcher {
    my $self = shift;
    $self->_unset_watcher;
    my $tag = $self->{watcher} = Glib::IO->add_watch($self->fd, 'in',
	    sub{$self->handle_input; return Glib::SOURCE_CONTINUE;});
    return $tag;
}

=item $X->B<_set_handlers>($xde)

Internal routine that sets event and error handlers.  When an object
passed as C<$xde>, the event handler will be set to $xde->_handle_event
and the error handler will be set to $xde->_handle_error when the object
has these methods.  Otherwise, they will be set to the default internal
$X->_handle_event and $X->_handle_error methods.

=cut

sub _set_handlers {
    my ($self,$xde) = @_;
    $xde = $self unless $xde;
    if ($xde->can('_handle_event')) {
	$self->{event_handler} = sub{ $xde->_handle_event(@_) };
    } else {
	$self->{event_handler} = sub{ $self->_handle_event(@_) };
    }
    if ($xde->can('_handle_error')) {
	$self->{error_handler} = sub{ $xde->_handle_event(@_) };
    } else {
	$self->{error_handler} = sub{ $self->_handle_event(@_) };
    }
}

=item $X->B<_handle_event>($error)

Default internal routine for handling events.  This callback is invoked
directly by L<X11::Protocol(3pm)>.  This should be overridden by a
derived class.  This default simply discards all events.

=cut

sub _handle_event {
    my ($self,%e) = @_;
    print STDERR "Discarding event: $e{name}\n";
}

=item $X->B<_handle_error>($error)

Default internal routine for handling errors.  This callback is invoked
directly by L<X11::Protocol(3pm)>.  This should be overridden by a
derived class.  This default simply discards all errors.

=cut

sub _handle_error {
    my ($self,$X,$e) = @_;
    print STDERR "Discarding error: \n",
	  $X->format_error_msg($e), "\n";
}

=item $X->B<_queue_events>()

Can be called by the X11::Protocol user to temporarily queue events
until the B<_process_queue> method is called.  Each call to
B<_queue_events> must be matched by a corresponding call to
B<_process_queue>.  No checks are made to enforce this.  Calls to
B<_queue_events> can be nested.

=cut

sub _queue_events {
    my $self = shift;
    unshift @{$self->{_handlers}}, $self->{event_handler};
    $self->{event_handler} = 'queue';
}

=item $X->B<_process_queue>()

Process queued events since the corresponding call to B<_queue_events>.
Each call to B<_process_queue> must be matched by a corresponding call
to B<_queue_events>.  No checks are made to enforce this.  Call to
B<_queue_events> and B<_process_queue> can be nested.  Only the
outermost call to B<_process_queue> will release the queued events.


=cut

sub _process_queue {
    my $self = shift;
    my $handler = shift @{$self->{_handlers}};
    return unless $handler; # this is an error
    return if $handler eq 'queue';
    my(%e);
    &$handler(%e) while %e = $self->dequeue_event;
    $self->{event_handler} = $handler;
}

=back

=cut

# vim: sw=4 tw=72
