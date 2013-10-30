package XDE::Dual;
use base qw(XDE::Gtk2);
use XDE::X11;
use strict;
use warnings;

=head1 NAME

XDE::Dual - a dual Gtk2 and X11::Protocol object for an XDE context

=head1 SYNOPSIS

 use XDE::Dual;

 my $xde = XDE::Dual->new(%OVERRIDES,ops=>\%ops);

 $xde->getenv;
 $xde->init;
 $SIG{TERM} = sub{ $xde->main_quit($result); };
 # perform some actions on the derived class
 my $result = $xde->main;
 $xde->term;

=head1 DESCRIPTION

XDE::Dual is an abstract base for derived classes that wish to run both
Gtk2 and X11::Protocol in the same event loop.  It uses
L<X11::Gtk2(3pm)> as a base class and initializes L<XDE::X11(3pm)> for
L<X11::Protocol(3pm)> connections.

=head1 METHODS

B<XDE::Dual> provides the following methods:

=over

=item $xde = XDE::Dual->B<new>(I<%OVERRIDES>,\I<%ops>)

Obtains a new B<XDE::Dual> instance.  For the use of I<%OVERRIDES>
and I<%ops>, see L<XDE::Context(3pm)>.

=cut

sub new {
    return XDE::Gtk2::new(@_);
}

=item $xde->B<init>() => $xde

Use this function instead of C<XDE::Gtk2-E<gt>init> and
C<XDE::X11-E<gt>new> to initialize both the Gtk2 toolkit environment and
an X11::Protocol connection from the underlying L<XDE::Context(3pm)>
object.  The client must call C<$xde-E<gt>setenv()> before calling this
method.  This method will invoke the C<_init> function of the derived
class if such a method exists.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    my $X = $self->{X} = XDE::X11->new();
    $X->init($self);
    # create a window to be used for communications
    my $win = $self->{win} = $X->new_rsrc;
    $X->CreateWindow($win, $X->root, 'InputOutput',
	    $X->root_depth, 'CopyFromParent', (0, 0),
	    1, 1, 0, event_mask=>$X->pack_event_mask(
		'StructureNotify',
		'PropertyChange',
		'SubstructureNotify'));
    # execute the derived class init function if it exists
    $self->_init(@_) if $self->can('_init');
    return $self;
}

=item $xde->B<term>() => $xde

Process events that should occur on graceful termination of the process.
Must be called by the creator of this instance and should be called from
C<$SIG{TERM}> procedures or other signal handler.  This method will
invoke the C<_term> function of the derived class if such a method
exists.

=cut

sub term {
    my $self = shift;
    # execute the derived class term function if it exists
    $self->_term(@_) if $self->can('_term');
    my $X = $self->{X};
    $X->term if $X;
    return $self;
}

=item $xde->B<wmcheck>() => $name or undef

Performs a window manager check and returns the name of the window
manager, or C<undef> when there is no window manager active.

=cut

sub wmcheck {
    my $self = @_;
    my $result = undef;
    my $X = $self->{X};
    my $screen = $X->{screens}[0];
    my $root = $screen->{root};
    my ($val, $type);
    ($val,$type) = $X->GetProperty($root,
	    $X->atom('_NET_SUPPORTING_WM_CHECK'),
	    $X->atom('WINDOW'), 0, 1);
    if ($type) {
	my $win = unpack('L',substr($val,0,4));
	($val,$type) = $X->GetProperty($win,
		$X->atom('_NET_SUPPORTING_WM_CHECK'),
		$X->atom('WINDOW'), 0, 1);
	if ($type and $win == unpack('L',substr($val,0,4))) {
	}
    }
    else {
	($val,$type) = $X->GetProperty($root,
		$X->atom('_WIN_SUPPORTING_WM_CHECK'),
		$X->atom('WINDOW'), 0, 1);
	if ($type) {
	    my $win = unpack('L',substr($val,0,4));
	    ($val,$type) = $X->GetProperty($win,
		    $X->atom('_WIN_SUPPORTING_WM_CHECK'),
		    $X->atom('WINDOW'), 0, 1);
	    if ($type and $win == unpack('L',substr($val,0,4))) {
		$result = '';
	    }
	}
    }
    return $result;
}

=item $xde->B<main>() => $xde

Use this function instead of C<Gtk2->main> or C<Glib::mainloop> to run
the event loop.

=cut

sub main {
    my $self = shift;
    if (my $X = $self->{X}) {
	$X->GetScreenSaver;
	$X->xde_process_queue;
    }
    return $self->SUPER::main;
}

=item $xde->B<event_handler_PropertyNotify>(I<$e>,I<$X>,I<$v>)

Internal event handler used to demultiplex C<PropertyNotify> events.
This method, when not overridden by the derived class, will call the
B<event_handler_PropertyNotify>I<$atom> method of the derived class when
a notification for property I<$atom> arrives.

=cut

sub event_handler_PropertyNotify {
    my ($self,$e,$X,$v) = @_;
    unless ($e->{atom} and $e->{atom} ne 'None') {
	warn "No atom '$e->{atom}'";
	return;
    }
    my $atom = $X->GetAtomName($e->{atom});
    unless ($atom and $atom ne 'None') {
	warn "No atom name '$atom'";
	return;
    }
    my $handler = "event_handler_PropertyNotify$atom";
    print STDERR "Handler is: $handler\n" if $v;
    my $sub = $self->can($handler);
    return &$sub($self,$e,$X,$v) if $sub;
    print STDERR "Discarding PropertyNotify event...\n" if $v;
}

=item $xde->B<event_handler_ClientMessage>(I<$e>,I<$X>,I<$v>)

Internal event handler use to demultiplex C<ClientMessage> events.  This
method, when not overridden by the derived class, will call the
B<event_handler_ClientMessage>I<$type> method of the derived class when
a client message I<$type> arrives.

=cut

sub event_handler_ClientMessage {
    my ($self,$e,$X,$v) = @_;
    my $type = $X->GetAtomName($e->{type});
    unless ($type and $type ne 'None') {
	warn "No type '$type'";
	return;
    }
    if ($v) {
	printf STDERR "\tname   => %s\n", $e->{name};
	printf STDERR "\twindow => 0x%08x\n", $e->{window};
	printf STDERR "\ttype   => %s\n", $type;
	printf STDERR "\tformat => %d\n", $e->{format};
	printf STDERR "\tdata   => %s\n",join(' ',map{sprintf "%02X", $_}unpack('C*',$e->{data}));
    }
    my $handler = "event_handler_ClientMessage$type";
    print STDERR "Handler is: '$handler'\n" if $v;
    my $sub = $self->can($handler);
    return &$sub($self,$e,$X,$v) if $sub;
    print STDERR "Discarding ClientMessage event...\n" if $v;
}

=item $xde->B<event_handler>(I<%event>)

Internal event handler for the XDE::Dual derived module.  This is an
L<X11::Protocol(3pm)> handler that is invoked either by direct requests
made of the L<X11::Protocol(3pm)> object ($self->{X}) or by
L<Glib::Mainloop(3pm)> when it triggers an input watcher on the
L<X11::Protocol::Connection(3pm)>.  C<$event> is the unpacked
L<X11::Protocol(3pm)> event.  This method will invoke the
C<event_handler_$e{name}> method of the derived class if such a method
exists.

=cut

sub event_handler {
    my ($self,%e) = @_;
    my $X = $self->{X};
    my $v = $self->{ops}{verbose};
    print STDERR "-----------------\nReceived event: ", join(',',%e), "\n" if $v;
    my $handler = "event_handler_$e{name}";
    print STDERR "Handler is: '$handler'\n" if $v;
    if ($e{name} eq $e{code}) {
	print STDERR "Uninterpreted code $e{code}\n";
	for (my $i=0;$i<@{$X->{ext_const}{Events}};$i++) {
	    my $event = $X->{ext_const}{Events}[$i];
	    if ($event) {
		print STDERR "Event[$i]: $event\n";
	    } else {
		print STDERR "Event[$i]: undef\n";
	    }
	}
    }
    my $sub = $self->can($handler);
    if ($sub) {
	my $result = &$sub($self,\%e,$X,$v);
	$X->flush;
	return $result;
    }
    print STDERR "Discarding event...\n" if $v;
}

=item $xde->B<error_handler>(I<$X>,I<$error>)

Internal error handler for the XDE::Dual derived module.  This is an
L<X11::Protocol(3pm)> handler that is invoked either by direct requests
made of the LX11::Protocol(3pm)> object ($self->{X}) or by
L<Glib::Mainloop(3pm)> when it triggers an input watcher on the
L<X11::Protocol::Connection(3pm)>.  C<$error> is the packed error
message.  This method will invoke the C<_error_handler> method of the
derived class if such a method exists.

=cut

sub error_handler {
    my ($self,$e) = @_;
    my $v = $self->{ops}{verbose};
    print STDERR "Received error: \n",
	  $self->{X}->format_error_msg($e), "\n" if $self->{ops}{verbose};
    my $sub = $self->can('_error_handler');
    return &$sub(@_) if $sub;
    print STDERR "Discarding error...\n" if $v;
}

1;

__END__

=back

=head1 USAGE

This package is intended on being used as a base for derived packages.
Instead of callbacks, this base package delivers events by testing
whether the implementation class has an appropriate handler method.

The default event handler concatenates C<event_handler_> with the name
of the event (e.g. C<PropertyNotify>, C<ClientMessage>) and calls the
corresponding method of the implementation class, if one exists, with
the arguments C<$e>, C<$X> and C<$v>.  C<$e> is a reference to the event
hash provided by L<X11::Protocol(3pm)>, C<$X> is a reference to the
L<X11::Protocol::Connection(3pm)> object, and C<$v> is true when verbose
messages should be provided; false, otherwise.

A default C<event_handler_PropertyNotify> and
C<event_handler_ClientMessage> method are provided in the base class.
These methods deliver to the B<event_handler_PropertyNotify>I<$atom>
method, and B<event_handler_ClientMessage>I<$type> methods respectively.

So, for example, an implementation package using this package as a base
may provide a C<event_handler_PropertyNotifyWM_CLASS> method that will
be called whenever there is a property notification for atom
C<WM_CLASS>.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>,
L<XDE::X11(3pm)>,
L<XDE::Gtk2(3pm)>,
L<X11::Protocol(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
