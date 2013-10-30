package X11::SN;
use base qw(X11::Protocol::AnyEvent);
use AnyEvent;
use strict;
use warnings;

=head1 NAME

X11::SN -- startup notification base module

=head1 SYNOPSIS

 use X11::SN;

=head1 DESCRIPTION

This module is not intended on being instantiated directly but is an
abstract base module for the L<X11::SN::Launcher(3pm)>,
L<X11::SN::Launchee(3pm)> and L<X11::SN::Monitor(3pm)> modules.

=head1 METHODS

This module provides the following methods:

=head2 INSTANTIATION

=over

=item $sn = X11::SN->B<new>(I<@args>) => blessed HASHREF

I<@args> are passed directly to L<X11::Protocol(3pm)/new()>.  This
method establishes a window for communications with other clients in
accordance with the startup notification specification.

=cut

sub new {
    my $X = X11::Protocol::AnyEvent::new(@_);
    my $window = $X->{sn}{window} = $X->new_rsrc;
    $X->CreateWindow($window,$X->root,'InputOutput',
	    $X->root_depth,'CopyFromParent',
	    (0, 0), (1, 1), 0);
    my $mask = $X->pack_event_mask(qw(
	    StructureNotify
	    SubstructureNotify
	    PropertyChange));
    $X->ChangeWindowAttributes($X->root,
	    event_mask=>$X->pack_event_mask(qw(
		    StructureNotify
		    SubstructureNotify
		    PropertyChange
	    )));
    return $X;
}

=item $sn->B<destroy>()

Removes any circular references and prepares the instance for garbage
collection.

=cut

sub destroy {
    my $X = shift;
    my $window = delete $X->{sn}{window};
    $X->DestroyWindow($window) if $window;
    $X->SUPER::destroy(@_);
}

=back

=head2 EVENT HANDLERS

=over

=item $sn->B<event_handler_CreateNotify>(I<$e>)

When a window is created, we want to select for propert changes on the
window so that we can track a few properties.

=cut

=item $sn->B<event_handler_DestroyNotify(I<$e>)

When a window is destroyed, we want to remove it from memory.

=cut

=item $sn->B<event_handler_UnmapNotify(I<$e>)

=cut

=item $sn->B<event_handler_MapNotify(I<$e>)

When a window is mapped, we want to check it for whether it forms a
completion of startup notification.

=cut

=item $sn->B<updateWM_STATE>(I<$window>)

When the C<WM_STATE> property is replaced or deleted we want to check
the status of the window.

=cut

=item $sn->B<event_handler_PropertyNotifyWM_STATE(I<$e>)

When an ICCCM compliant window manager starts managing a top-level
client window, it places the C<WM_STATE> property on the window.  The
window manager only performs these functions when a request has been
made to map the window.  When we receive a C<CreateNotify> for a
top-level window, we start tracking it; however, once it has been
mapped by the window manager, we 

=cut

=item $sn->B<updateWM_CLASS>(I<$window>)

=cut

=item $sn->B<event_handler_PropertyNotifyWM_CLASS(I<$e>)

=cut

=item $sn->B<updateWM_NAME>(I<$window>)

=cut

=item $sn->B<event_handler_PropertyNotifyWM_NAME(I<$e>)

=cut

=item $sn->B<update_NET_STARTUP_ID>(I<$window>)

=cut

=item $sn->B<event_handler_PropertyNotify_NET_STARTUP_ID>(I<$e>)

=cut

=item $sn->B<event_handler_ClientMessage_NET_STARTUP_INFO_BEGIN>(I<$e>)

Internal event handler for the C<_NET_STARTUP_INFO_BEGIN>
C<ClientMessage>.  This message is the first message in a sequence of
messages sent from the same window (belonging to launcher, launchee or
monitor) comprising the complete message.

The handler calls sn_process_message() with the text when the series of
messages is complete.  Messages accumulated from a previously incomplete
message sequence will be discarded.

=cut

sub event_handler_ClientMessage_NET_STARTUP_INFO_BEGIN {
    my($X,$e) = @_;
    return unless $e->{event} = $X->root;
    my $xid = $e->{window};
    my $window = $X->{sn}{windows}{$xid};
    $window = $X->{sn}{windows}{$xid} = {xid=>$xid} unless $window;
    my $data = $e->{data}; $data =~ s/\0.*$//;
    $window->{text} = $data;
    $self->sn_process_message(%$window) if length($data) < 20;
}

=item $sn->B<event_handler_ClientMessage_NET_STARTUP_INFO>(I<$e>)

Internal event handler for the C<_NET_STARTUP_INFO> C<ClientMessage>.
This mess is a subsequence or last message in a squence of messages sent
from the same window (belonging to launcher, launchee or monitor)
comprising the complete message.

The handler calls sn_process_message() with the text when the series of
messages is complete.  Messages for which there is no outstanding
C<_NET_STARTUP_INFO_BEGIN> message will be discarded.

=cut

sub event_handler_ClientMessage_NET_STARTUP_INFO {
    my($X,$e) = @_;
    return unless $e->{event} = $X->root;
    my $xid = $e->{window};
    my $window = $X->{sn}{windows}{$xid};
    return unless $window and $window->{text};
    my $data = $e->{data}; $data =~ s/\0.*$//;
    $window->{text} .= $data;
    $self->sn_process_message(%$window) if length($data) < 20;
}

=back

=head2 MESSAGE PROCESSING

=over

=item $sn->B<sn_process_message>(text=>I<$text>, xid=>I<$xid>)

Processes the message text of a completely and correctly received
startup notification messsage.  This method parses the message and acts
upon it.

=cut

sub sn_process_message {
    my ($self,%msg) = @_;
    my $text = $msg{text};
    $text =~ m{(^[a-z]+):[ ]*};
    my $cmd = $1;
    return unless $cmd eq 'new' or $cmd eq 'change' or $cmd = 'remove';
    $text =~ s{^[a-z]+:[ ]*}{};
    my %parms = ();
    while ($text =~ m{^([^=]+)=}) {
	my $key = $1;
	my $val = '';
	$text =~ s{^[^=]+=}{};
	my($escaped,$quoted) = (0,0);
	while(length($text)) {
	    my $c = substr($text,0,1);
	    $text = substr($text,1);
	    if ($escaped and $quoted) {
		$val .= $c;
		$escaped = 0;
	    }
	    elsif ($escaped and not $quoted) {
		if ($c eq '"') { $quoted = 1; }
		elsif ($c eq "\\") { $escaped = 1; }
		elsif ($c eq " ") { last; }
		else { $val .= $c; }
	    }
	    elsif (not $escaped and not $quoted) {
		if ($c eq '"') { $quoted = 1; }
		elsif ($c eq "\\") { $escaped = 1; }
		elsif ($c eq " ") { last; }
		else { $val .= $c; }
	    }
	    elsif (not $escaped and $quoted) {
		if ($c eq '"') { $quoted = 0; }
		elsif ($c eq "\\") { $escaped = 1; }
		else { $val .= $c; }
	    }
	}
	 # bad quoting
	return if length($text) == 0 and $escaped or $quoted;
	$parms{$key} = $val;
	$text =~ s{^[ ]+}{};
    }
     # garbage at end of text
    return unless length($text) == 0;
    my $id = $parms{ID};
    return unless $id;
    my $seq = $self->{sn}{sequences}{$id};
    if ($seq) {
	return if $cmd eq 'new';
	return if $seq->get_completed;
	if ($cmd eq 'change') {
	    foreach (keys %parms) {
		$seq->set_extra_property($_,$parms{$_});
	    }
	}
    } else {
	return if $cmd ne 'new';
	$seq = $self->{sn}{sequences}{$id} =
	    X11::SN::Sequence->new($self,%parms);
    }

}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::SN::Launcher(3pm)>,
L<X11::SN::Launchee(3pm)>,
L<X11::SN::Monitor(3pm)>,
L<X11::SN::Sequence(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
