package XDE::Xsettings;
require XDE::Context;
use X11::Protocol;

sub new {
    my $self = bless { }, shift;
    my $X = $self->{X} = shift;
    unless ($X) {
	$X = $self->{X} = X11::Protocol->new();
	my $fh = $X->{connection}->fh;
	$self->{watcher} = Glib::IO->add_watch(fileno($fh), 'in',
		sub{$self->handle_input(@_)});
    }
    $self->create_windows;
    $self->listen_to_roots;
    $self->become_owner;
    return $self;
}

sub input {
    my $self = shift;

}

sub create_windows {
    my $self = shift;
    my $X = $self->{X};
    my $screens = $self->{screens} = scalar(@{$X->{screens}});
    my $mask = $X->pack_event_mask('StructureNotify','PropertyChange');
    for (my $n; $n < $screens; $n++) {
	$X->choose_screen($n);
	my $win = $self->{windows}[$n] = $X->new_rsrc;
	$X->CreateWindow(
		$win,
		$X->root,
		'InputOutput',
		$X->root_depth,
		'CopyFromParent',
		(0,0),1,1,0,
		event_mask=>$mask);
    }
    $X->choose_screen(0);
}

sub listen_to_roots {
    my $self = shift;
    my $X = $self->{X};
    my $screens = scalar(@{$X->{screens}});
    for (my $n = 0; $n < $screens; $n++) {
	$X->choose_screen($n);
	$X->ChangeWindowAttributes(
		$X->root,
		event_mask=>$X->pack_event_mask(
		    'StructureNotify',
		    'PropertyChange')
		);
    }
    $X->choose_screen(0);
    return $screens;
}

sub become_owner {
    my $self = shift;
    my $X = $self->{X};
    my $win = $self->{win};
    my $owns = 0;
    my $screens = scalar(@{$X->{screens}});
    for (my $n = 0; $n < $screens; $n++) {
	$X->choose_screen($n);
	my $name = "_XSETTING_S$n";
	my $atom = $X->atom($name);
	my $owner = $X->GetSelectionOwner($atom);
	$self->{selections}[$n] = $owner;
	warn sprintf("selection %s has owner 0x%08x",$name,$owner) if $owner;
	unless ($owner == $win) {
	    $X->SetSelectionOwner($atom,$win,$self->{ts});
	    $owner = $X->GetSelectionOwner($atom);
	}
	$self->{selections}[$n] = $owner;
	unless ($owner == $win) {
	    warn sprintf("selection %s ownership failed",$name);
	    next;
	}
	$owns += 1;
	$X->SendEvent(
		$X->root,
		FALSE,
		$X->pack_event_mask('StructureNotify'),
		$mask,
		$X->pack_event({
		    name=>'ClientMessage',
		    type=>$X->atom('MANAGER'),
		    format=>32,
		    data=>pack("LLLLL",$self->{ts},$atom,$win,0,0)})
		);
    }
    $X->choose_screen(0);
    return $owns;
}

sub event {
    my ($self,$event) = @_;
    my $handler = "event_$event->{name}";
    $self->$handler($event) if $self->can($handler);
}
sub event_PropertyNotify {
    my ($self,$event) = @_;
    my $X = $self->{X};
    my $win = $self->{win};
    my $root = $X->root;
}
sub event_SelectionClear {
    my ($self,$event) = @_;
    my $X = $self->{X};
    my $win = $self->{win};
    my $root = $X->root;
    my $time = $event->{time};
    my $owner = $event->{owner};
    my $selection = $event->{selection};
}
sub event_SelectionRequest {
    my ($self,$event) = @_;
    my $X = $self->{X};
    my $win = $self->{win};
    my $root = $X->root;
    my $time = $event->{time};
    my $owner = $event->{owner};
    my $requestor = $event->{requestor};
    my $selection = $event->{selection};
    my $target = $event->{target};
    my $property = $event->{property};
}
sub event_SelectionNotify {
    my ($self,$event) = @_;
    my $X = $self->{X};
    my $win = $self->{win};
    my $root = $X->root;
}
sub event_ClientMessage {
    my ($self,$event) = @_;
    my $X = $self->{X};
    my $win = $self->{win};
    my $root = $X->root;
}

