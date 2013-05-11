package XDE::Xsettings;
use base qw(XDE::Gtk2);
use Glib qw(TRUE FALSE);
use Gtk2;
use XDE::X11;
use strict;
use warnings;

=head1 NAME

XDE::Xsettings -- manage XSETTINGS for the XDE desktop

=head1 SYNOPSIS

 use XDE::Xsettings;

 my $xde = XDE::Xsettings->new();
 $xde->init;
 $xde->set_settings(%hash);
 $xde->main;

=head1 DESCRIPTION

Provides a module that runs out of the Glib::Mainloop that will manage
the XSETTINGS on a lightweight destop and monitor for changes.

=head1 METHODS

=over

=cut

=item $xde = XDE::Xsettings->B<new>(I<%OVERRIDES>)

Creates an instance of an XDE::Xsettings object.  The XDE::Xsettings
modules uses the L<XDE::Context(3pm)> module as a base, so the
C<%OVERRIDES> are simply passed to the L<XDE::Context(3pm)> module.

=cut

sub new {
    return XDE::Context::new(@_);
}

=item $xde->B<setup>(I<%OVERRIDES>) => $xde

Provides the setup method that is called by L<XDE::Context(3pm)> when
the instance is created.  This examines environment variables and
initializes the L<XDE::Context(3pm)> in accordance with those
environment variables and I<%OVERRIDES>.

=cut

sub setup {
    my $self = shift;
    $self->SUPER::setup(@_);
    $self->getenv();
    return $self;
}

=item $xde->B<init>()

Initialization routine that is called like Gtk2->init.  It establishes
the X11::Protocol connection to the X Server and determines the initial
values and settings for the root window of each screen of the display
for later management of XSETTINGS.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init();
    my $X = $self->{X} = XDE::X11->new();
    my %ops = %{$self->{ops}};
    my $emask = $X->pack_event_mask('StructureNotify','PropertyChange');
    my $smask = $X->pack_event_mask('StructureNotify');
    my $pmask = $X->pack_event_mask('PropertyChange');
    my $manager = $X->atom('MANAGER');
    my $screens = scalar(@{$X->{screens}});
    my $time = 0;
    $self->{owns} = 0;
    for (my $n=0;$n<$screens;$n++) {
	my $screen = $X->{screens}[$n];
	my $win = $self->{windows}[$n] = $X->new_rsrc;
	$X->CreateWindow($win, $screen->{root}, 'InputOutput',
		$screen->{root_depth}, 'CopyFromParent', (0, 0),
		1, 1, 0, event_mask=>$smask);
	$X->ChangeWindowAttributes($screen->{root}, event_mask=>$emask);
	my $name = "_XSETTINGS_S$n";
	my $selection = $X->atom($name);
	my $owner = $self->{owners}[$n] = $X->GetSelectionOwner($selection);
	warn sprintf("Selection %s has owner 0x%08x",$name,$owner) if $owner;
	if ($owner == 0 or ($ops->{takeover} and $owner != $win)) {
	    $X->SetSelectionOwner($selection,$win,$time);
	    $owner = $self->{owners}[$n] = $X->GetSelectionOwner($selection);
	}
	if ($owner == $win) {
	    $self->{owns} += 1;
	    $X->SendEvent($X->root,FALSE,$smask,$X->pack_event(
		    name=>'ClientMessage', type=>$manager, format=>32,
		    data=>pack('LLLLL',$time,$selection,$win,0,0)));
	}
	elsif ($owner == 0) {
	    warn sprintf("Selection %s ownership failed",$name);
	}
	else {
	    warn sprintf("Selection %s ownership failed to 0x%08x",$name,$owner) if $ops->{takeover};
	    $X->ChangeWindowAttributes($owner, event_mask=>$pmask);
	}
    }
}

sub _handle_event_PropertyNotify {
    my ($self,$X,%e) = @_;
    my $v = $self->{ops}{verbose};
    if ($v) {
    }
}
sub _handle_event_SelectionClear {
    my ($self,$X,%e) = @_;
    my $v = $self->{ops}{verbose};
    if ($v) {
    }
}
sub _handle_event_SelectionRequest {
    my ($self,$X,%e) = @_;
    my $v = $self->{ops}{verbose};
    if ($v) {
	printf STDERR "\tname => '%s'\n", $e{name};
	printf STDERR "\ttime => %d\n", $e{time};
	printf STDERR "\towner => 0x%08x\n", $e{owner};
	printf STDERR "\trequestor => 0x%08x\n", $e{requestor};
	printf STDERR "\tselection => %s\n", $X->atom_name($e{selection});
	printf STDERR "\ttarget => %s\n", $e{target} eq 'None' ? 'None' : $X->atom_name($e{target});
	printf STDERR "\tproperty => %s\n", $e{property} eq 'None' ?  'None' : $X->atom_name($e{property});
    }
}
sub _handle_event_SelectionNotify {
    my ($self,$X,%e) = @_;
    my $v = $self->{ops}{verbose};
    if ($v) {
	printf STDERR "\tname => %s\n", $e{name};
	printf STDERR "\ttime => %d\n", $e{time};
	printf STDERR "\trequestor => 0x%08x\n", $e{requestor};
	printf STDERR "\tselection => %s\n", $X->atom_name($e{selection});
	printf STDERR "\ttarget => %s\n", $e{target} eq 'None' ? 'None' : $X->atom_name($e{target});
	printf STDERR "\tproperty => %s\n", $e{property} eq 'None' ?  'None' : $X->atom_name($e{property});
    }
}
sub _handle_event_CreateNotify {
    my ($self,$X,%e) = @_;
    my $v = $self->{ops}{verbose};
    if ($v) {
	printf STDERR "\tname => %s\n", $e{name};
	printf STDERR "\tparent => 0x%08x\n", $e{parent};
	printf STDERR "\twindow => 0x%08x\n", $e{window};
	printf STDERR "\tx => %d\n", $e{x};
	printf STDERR "\ty => %d\n", $e{y};
	printf STDERR "\twidth => %d\n", $e{width};
	printf STDERR "\theight => %d\n", $e{height};
	printf STDERR "\tborder-width => %d\n", $e{border_width};
	printf STDERR "\toverride-redirect => %s\n", $e{override_redirect};
    }
}
sub _handle_event_DestroyNotify {
    my ($self,$X,%e) = @_;
    my $v = $self->{ops}{verbose};
    if ($v) {
	print STDERR "\tname => %s\n", $e{name};
	print STDERR "\tevent => 0x%08x\n", $e{event};
	print STDERR "\twindow => 0x%08x\n", $e{window};
    }
}

sub _handle_event {
    my ($self,%e) = @_;
    return if $self->{discard_events};
    my $X = $self->{X};
    my $v = $self->{ops}{verbose};
    print STDERR "------------------\nReceived event: ",
	  join(',',%e), "\n" if $v;
    my $handler = "_handle_event_$e{name}";
    print STDERR "Handler is '$handler'\n" if $v;
    if ($self->can($handler)) {
	$self->$handler($X,%e);
	return;
    }
    print STDERR "Discarding event...\n" if $v;
}

sub _handle_error {
    my ($self,$X,$e) = @_;
    print STDERR "Received error: \n",
	$X->format_error_msg($e), "\n";
    return if $self->{ignore_errors};
}


=back

=cut

1;

# vim: sw=4 tw=72
