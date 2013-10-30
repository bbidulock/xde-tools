package X11::SN::Launchee;
use base qw(X11::SN);
use AnyEvent;
use strict;
use warnings;

=head1 NAME

X11::SN::Launchee -- perform lauchee functions for startup notification

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

The following methods are provided:

=over

=item $sn = X11::SN->B<new>()

=item $sn = X11::SN->B<new>(I<$display_name>)

=item $sn = X11::SN->B<new>(I<$connection>)

=item $sn = X11::SN->B<new>(I<$display_name>, [I<$auth_type>, I<$auth_data>])

=item $sn = X11::SN->B<new>(I<$connection>, [I<$auth_type>, I<$auth_data>])

Opens a connection to a X server using L<X11::Protocol(3pm)> and
initializes the connection for operation for startup notification.

=cut

sub new {
    $self = X11::Protocol->new(@_);
    $self->sn_init;
    return $self;
}

sub sn_init {
    my $self = shift;
    $self->{event_handler} = sub{ $self->_x_event_handler(@_) };
    $self->{error_handler} = sub{ shift->_x_error_handler(@_) };
    $self->{sn}{watcher} = AE::io $self->fh, 0, sub{
	$self->handle_input;
	$self->sn_process_queue;
    };
    return $self;
}

sub sn_term {
    my $self = shift;
    delete $self->{sn}{watcher};
    $self->{event_handler} = sub{ };
    $self->{error_handler} = sub{ };
    $self->fh->flush();
    $self->sn_purge_queue;
    $self->fh->close();
}

sub fh {
    return shift->{connection}->fh;
}

sub fd {
    return fileno(shift->fh);
}

sub sn_discard_events {
    shift->{sn}{discard_events} += 1;
}

sub sn_process_events {
    my $self = shift;
    $self->{sn}{discard_events} -= 1;
    if ($self->{sn}{discard_events} <= 0) {
	$self->{sn}{discard_events} = 0;
	$self->sn_process_queue;
    }
}

sub sn_discard_errors {
    shift->{sn}{discard_errors} += 1;
}

sub sn_process_errors {
    my $self = shift;
    $self->{sn}{discard_errors} -= 1;
    if ($self->{sn}{discard_errors} <= 0) {
	$self->{sn}{discard_errors} = 0;
	$self->sn_process_queue;
    }
}

sub sn_purge_queue {
    my $self = shift;
    my $errors = 0;
    my $events = 0;
    while (my $e = shift @{$self->{sn}{events}}) {
	if (ref($e) eq 'HASH') {
	    $events += 1;
	} else {
	    $errors += 1;
	}
    }
    return $events + $errors unless wantarray;
    return ($events, $errors);
}

sub sn_process_queue {
    my $self = shift;
    my $errors = 0;
    my $events = 0;
    while (my $e = shift @{$self->{sn}{events}}) {
	if (ref $e eq 'HASH') {
	    next if $self->{sn}{discard_events};
	    $self->sn_event_handler(%$e);
	    $events += 1;
	} else {
	    next if $self->{sn}{discard_errors};
	    $self->sn_error_handler($e);
	    $errors += 1;
	}
    }
    return $events + $errors unless wantarray;
    return ($events, $errors);
}

sub _x_event_handler {
    my($self,$e) = @_;
    push @{$self->{sn}{events}}, \%e
	unless $self->{sn}{discard_events};
}

sub _x_error_handler {
    my($self,$e) = @_;
    print STDERR "Received error: \n",
	  $self->format_error_msg($e), "\n";
    push @{$self->{sn}{events}}, $e
	unless $self->{sn}{discard_errors};
}

=item $sn->B<sn_event_handler>(I<%event>)

Internal event handler for the X11::SN derived module.  This is an
L<X11::Protocol(3pm)> hanlder that is invoked either by direct requests
or by L<AnyEvent(3pm)> watcher when it triggers an input watcher on the
L<X11::Protocol::Connection(3pm)>.  I<%event> is the unpacked
L<X11::Protocol(3pm)> event.  This method will invoke the
C<event_handler_$e{name}> method of the derived class if such a method
exists.

=cut

sub sn_event_handler {
    my($self,%e) = @_;
    my $v = $self->{ops}{verbose};
    print STDERR "-----------------\nReceived event: ", join(',',%e), "\n" if $v;
    my $handler = "event_handler_$e{name}";
    print STDERR "Handler is: '$handler'\n" if $v;
    if ($e{name} eq $e{code}) {
	print STDERR "Uninterpreted code $e{code}\n";
	for (my $i=0;$i<@{$self->{ext_const}{Events}};$i++) {
	    my $event = $self->{ext_const}{Events}[$i];
	    if ($event) {
		print STDERR "Event[$i]: $event\n";
	    } else {
		print STDERR "Event[$i]: undef\n";
	    }
	}
    }
    if (my $sub = $self->can($handler)) {
	my $result = &$sub($self,\%e,$v);
	$self->flush;
	return $result;
    }
    print STDERR "Discarding event...\n" if $v;
}

sub sn_error_handler {
    my($self,$e) = @_;
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::SN(3pm)>,
L<X11::SN::Sequence(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
