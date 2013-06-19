package XDE::Notify;
use base qw(Linux::Inotify2);
use strict;
use warnings;

=head1 NAME

XDE::Notify - XDE wrapper module for Linux::Inotify

=head1 SYNOPSIS

my $X = XDE::Notify->new;

=head1 DESCRIPTION

XDE::Notify provides a wrapper class for integrating Linux::Inotify2
operations in an XDE::Context derived class.

=head1 METHODS

=over

=item $N = B<new> XDE::Notify I<@OPTIONS> => bless HASHREF

Creates a new Linux::Inotify2 object and connects it to the kernel.

=cut

sub new {
    return Linux::Inotify::new(@_);
}

=item $N->B<init>($xde) => $N

Initializes the XDE::Notify object.  This sets handlers and initializes
the Glib::Mainloop watchers for event-loop operation.  Initialization is
no done automatically, because the owner of this instance might want to
set other things up before initializing the mainloop.

C<$xde> is typically an L<XDE::Context> derived object, but can be any
object that implements (or not) B<notify_handler> methods.  These
methods will be called during normal operation of the Linux::Inotify2
connection and when invoked by Glib::Mainloop.

=cut

sub init {
    my ($self,$xde) = @_;
    $self->{notify_handler} = sub{ $self->xde_notify_handler(@_) };
    $self->{xde}{notify_handler} = sub{ $xde->notify_handler(@_) };
    Glib::Source->remove($self->{xde}{watcher})
	if $self->{xde}{watcher};
    $self->{xde}{watcher} = Glib::IO->add_watch($self->fileno, 'in',
	    sub { $self->poll; $self->xde_process_queue;
		  return Glib::SOURCE_CONTINUE; });
    return $self;
}

=item $N->B<term>()

Terminates the XDE::Notify object.  There are a number of circular
references that are broken by this method that are necessary to allow
perl garbage collection to collect the object.

=cut

sub term {
    my $self = shift;
    # release circular references
    Glib::Source->remove($self->{xde}{watcher})
	if $self->{xde}{watcher};
    $self->{notify_handler} = sub{ };
    delete $self->{xde}{notify_handler};
    sysclose($self->fileno);
    # buh bye
    undef $self;
}

=back

=head1 BEHAVIOUR

For XDE/XDG applications we really only need to watch several
directories.  All of XDG can normally be monitored my monitoring
F<$HOME/.config>, F<$HOME/.local/share>, F</etc/xdg>, and
F</usr/share>.



=cut

# vim: sw=4 tw=72
