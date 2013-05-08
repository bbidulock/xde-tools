package XDE::Setbg;
require XDE::Context;
use Glib qw(TRUE FALSE);
use Gtk2;
use AnyEvent;
use Coro;
use Coro::Handle;
use X11::Protocol;
use strict;
use warnings;

use constant {
    ATOMS => [qw(
	    ESETROOT_PMAP_ID
	    _XROOTPMAP_ID
	    _XSETROOT_ID
	    _XROOTMAP_ID
	    _NET_NUMBER_OF_DESKTOPS
	    _NET_CURRENT_DESKTOP
	    PIXMAP
    )],
};

sub new {
    my ($type,$xde,$ops) = @_;
    die 'usage: XDE::Setbg->new($xde,$ops)'
	unless $xde and $xde->isa('XDE::Context') and
	       $ops and ref($ops) =~ /HASH/;
    my $X = X11::Protocol->new();
    $X->SetCloseDownMode('RetainTemporary');
    my $self = bless {
	xde=>$xde,
	ops=>$ops,
	X=>$X,
	atoms=>{},
	props=>{},
	pmids=>[],
	fh=>unblock $X->{connection}->fh,
    }, $type;
    {
	# this should maybe be in the XDE::Context object
	Gtk2->init;
	my $mgr = $self->{mgr} = Gtk2::Gdk::DisplayManager->get;
	my $dpy = $self->{dpy} = $mgr->get_default_display;
	my $scr = $self->{scr} = $dpy->get_default_screen;
	my $win = $self->{win} = $scr->get_root_window;
	my $xid = $self->{xid} = $win->XID;
    }
    $self->get_atoms;
    $self->get_props;
    return $self;
}

# just prime the atom cache on $X
sub get_atoms {
    my $X = shift->{X};
    foreach (@{&ATOMS}) { $X->atom($_) }
}
sub GetProperty {
    my ($self,$name) = @_;
    my $X = $self->{X};
    my $xid = $self->{xid};
    my $atom = $X->atom($name);
    my ($result) = $X->robust_req(GetProperty=>$xid,$atom,'AnyPropertyType',0,1,FALSE);
    if (ref $result eq 'ARRAY') {
	return @$result;
    }
    else {
	$self->{error} = $result;
	return ();
    }
}
sub get_pixmap {
    my $self = shift;
    my ($value) = $self->GetProperty('_XROOTPMAP_ID');
    if (defined $value) {
	printf STDERR "%s changed to 0x%08x\n",
	       $name, $value if $ops{verbose};
	$self->{pmids}[$self->{current}] = $value;
    }
}
sub get_current {
}
sub get_desktops {
}
sub get_props {
    my $self = shift;
    ($self->{pixmap})   = $self->GetProperty('_XROOTPMAP_ID');
     $self->{pixmap}    = 0 unless $self->{pixmap};
    ($self->{current})  = $self->GetProperty('_NET_CURRENT_DESKTOP');
     $self->{current}   = 0 unless $self->{current};
    ($self->{desktops}) = $self->GetProperty('_NET_NUMBER_OF_DESKTOPS');
     $self->{desktops}  = 1 unless $self->{desktops};
}
sub new_pixmap {
    my ($self,$w,$h,$d) = @_;
    my $pid = $self->{X}->new_rsrc;
    $self->{X}->CreatePixmap($pid,$self->{xid},$d,$w,$h);
    return Gtk2::Gdk::Pixmap->foreign_new($pid);
}

=pod

A problem with using Gtk2::Gdk::Event->handler_set to intercept
appropriate events,

=cut

sub event_handler {
    my ($self,$event) = @_;
    my $X = $self->{X};
    if ($event->{type} eq 'PropertyNotify') {
	if ($event->{window} == $self->{xid}) {
	    if ($event->{atom} == $X->atom('_XROOTPMAP_ID')) {
		if ($event->{state} eq 'NewValue') {
		    my ($value) = $self->GetProperty('_XROOTPMAP_ID');
		    if (defined $value) {
			printf STDERR "%s changed to 0x%08x\n",
			       $name, $value if $ops{verbose};
			$self->{pmids}[$self->{current}] = $value;
		    }
		}
		elsif ($event->{state} eq 'Deleted') {
		    printf STDERR "%s deleted\n",
			   $name if $ops{verbose};
		    $self->{pmids}[$self->{current}] = undef;
		}
	    }
	    elsif ($event->{atom} == $X->atom('_NET_CURRENT_DESKTOP')) {
		if ($event->{state} eq 'NewValue') {
		    my ($value) = $self->GetProperty('_NET_CURRENT_DESKTOP');
		    if (defined $value) {
			printf STDERR "%s changed to %d\n",
			      $name, $value if $ops{verbose};
			if ($value != $self->{current}) {
			    $self->{current} = $value;
			}
		    }
		}
		elsif ($event->{state} eq 'Deleted') {
		    printf STDERR "%s deleted\n",
			   $name if $ops{verbose};
		    $self->{current} = 0;
		}
	    }
	    elsif ($event->{atom} == $X->atom('_NET_NUMBER_OF_DESKTOPS')) {
		if ($event->{state} eq 'NewValue') {
		    my ($value) = $self->GetProperty('_NET_NUMBER_OF_DESKTOPS');
		    if (defined $value) {
			printf STDERR "%s changed to %d\n",
			      $name, $value if $ops{verbose};
			if ($value > $self->{desktops}) {
			    # TODO: need to populate pmids for the new
			    #	desktops.
			    $self->{desktops} = $value;
			}
		    }
		}
		elsif ($event->{state} eq 'Deleted') {
		    printf STDERR "%s deleted\n",
			   $name if $ops{verbose};
		    $self->{desktops} = 1;
		}
	    }
	}
    }
}

# vim: set sw=4 tw=72
