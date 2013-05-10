package XDE::X11::Setbg;
use base qw(XDE::X11);
use Glib qw(TRUE FALSE);
use strict;
use warnings;


=head1 NAME

XDE::X11::Setbg -- set backgrounds using X11::Protocol

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

sub new {
    my ($type,$ops) = (shift,shift);
    my $self = XDE::X11::new($type,@_);
    my $setbg = $self->{setbg} = {};
    $ops = {} unless $ops;
    $setbg->{ops} = $ops;
    $self->setup_setbg;
    return $self;
}

sub setup_setbg {
    my $self = shift;
    my $setbg = $self->{setbg};
    $self->SetCloseDownMode('RetainTemporary');
    my $emask = pack_event_mask('PropertyChange');
    $self->ChangeWindowAttributes($self->root,
	    event_mask=>$mask);
    for (my $n=0;$n<@{$self->{screens}};$n++) {
	my $screen = $setbg->{screen}[$n];
	$screen = $setbg->{screen}[$n] = {} unless $screen;
	$self->choose_screen($n);
	$screen->{roots} = $self->root;
	$setbg->{screens}{$self->root} = $n;
	my ($value,$type);
	($value,$type) = $self->GetProperty($self->root,
		$self->atom('_NET_NUMBER_OF_DESKTOPS'),
		'AnyPropertyType', 0, 1);
	$screen->{desktops} = $type ? unpack('L',substr($value,0,4)) : 1;
	($value,$type) = $self->GetProperty($self->root,
		$self->atom('_NET_CURRENT_DESKTOP'),
		'AnyPropertyType', 0, 1);
	$screen->{current} = $type ? unpack('L',substr($value,0,4)) : 0;
	($value,$type) = $self->GetProperty($self->root,
		$self->atom('_XROOTPMAP_ID'),
		'AnyPropertyType', 0, 1);
	my $d = $screen->{current};
	$screen->{pmids}[$d] = $type ? unpack('L',substr($value,0,4)) : 0;
    }
}

sub change_XROOTPMAP_ID {
    my ($self,$screen,$window,$atom,$time) = @_;
    my ($value,$type) = $self->GetProperty($window, $atom, 'AnyPropertyType', 0, 1);
    my $pixmap = $type ? unpack('L',substr($value,0,4)) : 0;
    my $d = $screen->{current};
    if ($pixmap != $screen->{pmids}[$d]) {
	unless (exists $self->{setbg}{pixmaps}{$pixmap}) {
	    # we have no idea what filename is used for the pixmap
	    $self->{setbg}{pixmaps}{$pixmap} = '';
	}
	# FIXME: change the current pixmap definition
	$screen->{pmids}[$d] = $pixmap;
    }
}
sub change_NET_CURRENT_DESKTOP {
    my ($self,$screen,$window,$atom,$time) = @_;
    my ($value,$type) = $self->GetProperty($window, $atom, 'AnyPropertyType', 0, 1);
    my $c = $type ? unpack('L',substr($value,0,4)) : 0;
    my $d = $screen->{current};
    if ($c != $d) {
	my $pmids = $self->{setbg}{pmids};
	$pmids = $self->{setbg}{pmids} = {} unless $pmids;
	if ($pmids->[$c] and (not $pmids->[$d] or $pmids->[$c] != $pmids[$d]) {
	    my $pixmap = $pmids->[$c];
	    $self->ChangeWindowAttributes($self->root,background_pixmap=>$pixmap);
	    $self->flush;
	    $self->sync;
	}
	$screen->{current} = $c;
    }
}
sub changed_NET_NUMBER_OF_DESKTOPS {
    my ($self,$screen,$window,$atom,$time) = @_;
    my ($value,$type) = $self->GetProperty($window, $atom, 'AnyPropertyType', 0, 1);
    my $desktops = $type ? unpack('L',substr($value,0,4)) : 1;
    if ($desktops != $screen->{desktops}) {
	# FIXME: change the desktop definitions
	#	well, we fill out for 12 desktops anyway
	$screen->{desktops} = $desktops;
    }
}

=item $setbg->B<_handle_event>($event)

Internal routine for handling events.  Called direclty by X11::Protocol
whenever the connection receives an event that is not a reply.

=cut

sub _handle_event {
    my ($self,$event) = @_;
    return unless $event->{name} eq 'PropertyNotify';
    my $setbg = $self->{setbg};
    return unless exists $setbg->{screens}{$event->{window}};
    my $n = $setbg->{screens}{$event->{window}};
    my $screen = $setbg->{screen}[$n] or return;
    $self->choose_screen($n);
    return unless $event->{window} == $self->root;
    my $action = "changed".$self->atom_name($event->{atom});
    return $self->$action($screen,$event->{window},$event->{atom},$event->{time})
	if $self->can($action);
    return;
}

=item $setbg->B<_handle_error>($error)

Internal routine for handling errors.  Called directly by X11::Protocol
whenever the connection receives an error that is not a reply.

=cut

sub _handle_error {
    my ($self,$error) = @_;
}

=back

=cut

1;

# vim: sw=4 tw=72
