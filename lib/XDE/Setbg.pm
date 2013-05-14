package XDE::Setbg;
use base qw(XDE::Gtk2);
use Glib qw(TRUE FALSE);
use Gtk2;
use XDE::X11;
use strict;
use warnings;

=head1 NAME

XDE::Setbg -- set backgrounds on multiple desktops or workspaces

=head1 SYNOPSIS

 use XDE::Setbg;

 my $xde = XDE::Setbg->new();
 $xde->init;
 $xde->set_backgrounds(qw(
    /usr/share/fluxbox/backgrounds/fighter_jets.jpg
    /usr/share/fluxbox/backgrounds/emerald_coast.jpg
    /usr/share/fluxbox/backgrounds/blackbird.jpg));
 $xde->main;

=head1 DESCRIPTION

Provides a module that runs out of the Glib::Mainloop that will set the
backgrounds on a lightweight desktop and monitor for desktop changes.
When the desktop changes, the modules will set the image for that
desktop against the root window.  It basically provides a wallpaper per
desktop.  It also remembers the image for a desktop when L<hsetroot(1)>
or some other tool is used to set the background.

=head1 METHODS

=over

=cut

=item $xde = XDE::Setbg->B<new>(I<%OVERRIDES>)

Creates an instance of an XDE::Setbg object.  The XDE::Setbg module
uses the L<XDE::Context(3pm)> module as a base, so the C<%OVERRIDES> are
simply passed to the L<XDE::Context(3pm)> module.

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

Initialization routine that is called like Gtk->init.  It establishes
the X11::Protocol connection to the X Server and determines the initial
values and settings of the root window on each screen of the display for
later displaying the background images.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    my $X = $self->{X} = XDE::X11->new();
    my $verbose = $self->{ops}{verbose};
    $X->init($self);
    $X->SetCloseDownMode('RetainTemporary');
    my $emask = $X->pack_event_mask('PropertyChange');
    my $smask = $X->pack_event_mask('PropertyChange','StructureNotify');
    $X->ChangeWindowAttributes($X->root, event_mask=>$emask);
    for (my $n=0;$n<@{$X->{screens}};$n++) {
	my $screen = $self->{screen}[$n];
	$screen = $self->{screen}[$n] = {} unless $screen;
	my $root = $screen->{root} = $X->{screens}[$n]{root};
	$self->{roots}{$root} = $n;
	my ($val,$type);
	($val,$type) = $X->GetProperty($root,
		$X->atom('_NET_NUMBER_OF_DESKTOPS'),
		$X->atom('CARDINAL'), 0, 1);
	$screen->{desktops} = $type ?  unpack('L',substr($val,0,4)) : 1;
	printf STDERR "Number of desktops is %d\n", $screen->{desktops}
	    if $verbose;
	($val,$type) = $X->GetProperty($root,
		$X->atom('_NET_CURRENT_DESKTOP'),
		$X->atom('CARDINAL'), 0, 1);
	$screen->{desktop} = $type ?  unpack('L',substr($val,0,4)) : 0;
	printf STDERR "Current desktop is %d\n", $screen->{desktop}
	    if $verbose;
	($val,$type) = $X->GetProperty($root,
		$X->atom('_WIN_WORKSPACE_COUNT'),
		$X->atom('CARDINAL'), 0, 1);
	$screen->{workspaces} = $type ? unpack('L',substr($val,0,4)) : 1;
	printf STDERR "Number of workspaces is %d\n", $screen->{workspaces}
	    if $verbose;
	($val,$type) = $X->GetProperty($root,
		$X->atom('_WIN_WORKSPACE'),
		$X->atom('CARDINAL'), 0, 1);
	$screen->{workspace} = $type ? unpack('L',substr($val,0,4)) : 0;
	printf STDERR "Current workspace is %d\n", $screen->{workspace}
	    if $verbose;
	my $d = $screen->{desktop};
	($val,$type) = $X->GetProperty($root,
		$X->atom('_XROOTPMAP_ID'),
		$X->atom('PIXMAP'), 0, 1);
	my $pmid = $type ?  unpack('L',substr($val,0,4)) : 0;
	printf STDERR "Existing pixmap id is 0x%08x\n", $pmid
	    if $verbose;
	for (my $i=0;$i<$screen->{desktops};$i++) {
	    $screen->{pmids}[$i] = \$pmid;
	}
	# test for a button proxy
	($val,$type) = $X->GetProperty($root,
		$X->atom('_WIN_DESKTOP_BUTTON_PROXY'),
		$X->atom('WINDOW'), 0, 1);
	my $proxy = $screen->{proxy} = $type ? unpack('L',substr($val,0,4)) : 0;
	unless ($proxy) {
	    my $win = $screen->{win} = $X->new_rsrc;
	    $proxy = $screen->{proxy} = $win;
	    $X->CreateWindow($win,$root,'InputOutput',$X->root_depth,
		    'CopyFromParent',(0,0),1,1,0);
	    $X->ChangeProperty($win,
		    $X->atom('_WIN_DESKTOP_BUTTON_PROXY'),
		    $X->atom('WINDOW'), 32, 'Replace', pack('L',$win));
	    $X->ChangeProperty($root,
		    $X->atom('_WIN_DESKTOP_BUTTON_PROXY'),
		    $X->atom('WINDOW'), 32, 'Replace', pack('L',$win));
	}
	$X->ChangeWindowAttributes($proxy, event_mask=>$smask);
	$self->{roots}{$proxy} = $n;
    }
}

=item $xde->B<term>()

Processes events that should occur on graceful termination of the
process.  Must be called by the creator of this instance and should be
called from a $SIG{TERM} procedure or other signal handler.
B<XDE::Setbg> allocates pixmaps that persist on close.  This is so that
the _XROOTPMAP_ID pixmap is never deallocated while the property is set.
This method frees all of the pixmaps in the server except the one that
is currently set as _XROOTPMAP_ID.

=cut

sub term {
    my $self = shift;
    my $X = $self->{X};
    for (my $i=0;$i<$self->{screens};$i++) {
	my $screen = $self->{screen}[$i];
	for (my $d=0;$d<@{$screen->{pmids}};$d++) {
	    if ($screen->{win} and $screen->{proxy} == $screen->{win}) {
		$X->DeleteProperty($screen->{root},
			$X->atom('_WIN_DESKTOP_BUTTON_PROXY'));
	    }
	    if ($d == $screen->{desktop}) {
		${$screen->{pmids}[$d]} = 0;
	    }
	    elsif ($screen->{pmids}[$d] and
		    my $pmid = ${$screen->{pmids}}[$d]) {
		$X->FreePixmap($pmid);
		$X->flush;
		${$screen->{pmids}[$d]} = 0;
	    }
	}
    }
    $X->term();
}

=item $xde->B<main>()

Run the main loop and wait for events, detecting when backgrounds are
changed or when desktops or workspaces are changed.

=cut

sub main {
    my $self = shift;
    my $X = $self->{X};
    $X->xde_process_errors;
    $X->xde_process_events;
    return $self->SUPER::main;
}

=item $xde->B<set_pixmap>(I<$root>,I<$pmid>)

Sets the pixmap specified by pixmap id, C<$pmid>, on the root window
specified by C<$root>.  This is normally only called internally.

=cut

sub set_pixmap {
    my ($self,$root,$pmid) = @_;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    my $grab = $self->{ops}{grab};
    printf STDERR "setting root window 0x%08x to pixmap 0x%08x\n",
	   $root, $pmid if $verbose;
    $X->GrabServer   if $grab;
    $X->ChangeWindowAttributes($root,
	    background_pixmap=>$pmid);
    $X->ClearArea($root,0,0,0,0,'True');
    my $data = pack('L',$pmid);
    foreach (qw(_XROOTPMAP_ID ESETROOT_PMAP_ID _XSETROOT_ID
		_XROOTMAP_ID)) {
	$X->ChangeProperty($root, $X->atom($_),
		$X->atom('PIXMAP'), 32, 'Replace', $data);
    }
    $X->flush;
    $X->UngrabServer if $grab;
}

=item $xde->B<set_backgrounds>(I<@files>)

Sets the backgrounds for the desktops according to the list of files
specified with C<@files>.  Each filename may be prefixed by a display
type and a colon, where the display type is one of C<center>, C<tile>,
C<full> or C<fill>.  If a display type is not specified, it will be
automatically determined from the size and aspect of the image and the
size and aspect of the display.  Filenames may be specified as relative
paths from the current working directory, absolute paths, or simply base
file names (with or without the suffix).  Base file names will be
searched in the background directories of the XDE::Context.

=cut

sub set_backgrounds {
    my ($self,@files) = @_;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};

    my $n = $self->{defined} = scalar(@files);
    return unless $n;
    print STDERR "There are $n files\n" if $verbose;
    my $screens = scalar @{$X->{screens}};
    print STDERR "There are $screens screens\n" if $verbose;
    $X->choose_screen(0);
    my $screen = $self->{screen}[0];
    my ($w,$h,$d) = (
	$X->width_in_pixels,
	$X->height_in_pixels,
	$X->root_depth,
    );
    my @pmids = ();
    # Create the pixmaps first so that they are available when it comes
    # time to use them under Gtk2.
    foreach (@files) {
	my $pmid = $X->new_rsrc;
	$X->CreatePixmap($pmid,$X->root,$d,$w,$h);
	$X->flush;
	push @pmids, $pmid;
    }
    for (my $i=0;$i<$n;$i++) {
	my $file = $files[$i];
	my $mode = 'fill';
	if ($file =~ m{^(center|tile|full|fill):(.*)$}) {
	    $mode = $1; $file = $2;
	}
	# Ultimately what we want to do is search out backgound file in
	# XDG directories and index them by name.  That way we can
	# specify them by name only, or we can look for them by name if
	# we cannot find a  full path.  But this is enough for testing.
	unless (-f $file) {
	    print STDERR "could not find file '$file'\n";
	    next;
	}
	print STDERR "using file '$file'\n" if $verbose;
	my $pixbuf;
	if ($mode eq 'fill') {
	     eval {
		$pixbuf =
		    Gtk2::Gdk::Pixbuf->new_from_file_at_scale($file,$w,$h,FALSE);
	     } or print STDERR "$!\n";
	}
	elsif ($mode eq 'full') {
	     eval {
		$pixbuf =
		    Gtk2::Gdk::Pixbuf->new_from_file_at_size($file,$w,$h);
	     } or print STDERR "$!\n";
	}
	unless ($pixbuf) {
	    print STDERR "could not get pixbuf for file '$file'\n";
	    next;
	}
	my ($width,$height) = ($pixbuf->get_width, $pixbuf->get_height);
	my ($x_src,$y_src,$x_dst,$y_dst,$w_box,$h_box) =
	    (0,0,0,0,$w,$h);
	if ($width > $w) {
	    $w_box = $w;
	    $x_src = ($width-$w)/2;
	    $x_dst = 0;
	}
	elsif ($width < $w) {
	    $w_box = $width;
	    $x_src = 0;
	    $x_dst = ($w-$width)/2;
	}
	if ($height > $h) {
	    $h_box = $height;
	    $y_src = ($height-$h)/2;
	    $y_dst = 0;
	}
	elsif ($height < $h) {
	    $h_box = $h;
	    $y_src = 0;
	    $y_dst = ($h-$height)/2;
	}
	my $pmid = $pmids[$i];
	 #my $pmid = $X->new_rsrc;
	 #$X->CreatePixmap($pmid,$X->root,$d,$w,$h);
	 #$X->flush;
	printf STDERR "Getting foreign pixmap id 0x%08x\n", $pmid
	    if $verbose;
	my $display = Gtk2::Gdk::Display->get_default;
	 #my $gtkscrn = $display->get_screen(0);
	 #my $gtkroot = $gtkscrn->get_root_window;
	 #my $pixmap = Gtk2::Gdk::Pixmap->lookup($pmid);
	my $pixmap = Gtk2::Gdk::Pixmap->foreign_new($pmid);
	 #my $pixmap = Gtk2::Gdk::Pixmap->foreign_new_for_screen($gtkscrn, $pmid, $w, $h, $d);
	 #my $pixmap = Gtk2::Gdk::Pixmap->new($gtkroot,$w,$h,$d);
	printf STDERR "Drawing to pixmap id 0x%08x\n", $pmid
	    if $verbose;
	$pixmap->draw_pixbuf(undef,$pixbuf,$x_src,$y_src,$x_dst,$y_dst,$w_box,$h_box,'none',0,0);
	$display->flush;
	$display->sync;
	$screen->{pmids}[$i] = \$pmid;
	if ($i == $screen->{desktop}) {
	    $self->set_pixmap($screen->{root},$pmid);
	}
    }
    my $k = $screen->{desktops};
    if ($k > $n) {
	# modulate the backgrounds over the available desktops
	for (my $i=0;$i<$k;$i++) {
	    next unless $i >= $n;
	    my $j = $i % $n;
	    $screen->{pmids}[$i] = $screen->{pmids}[$j];
	    if ($i == $screen->{desktop}) {
		$self->set_pixmap($screen->{root},${$screen->{pmids}[$i]});
	    }
	}
    }
}

=item $xde->B<changed_XROOTPMAP_ID>(I<$screen>,I<$event>)

Internal function that handles when the B<_XROOTPMAP_ID> property
changes on the root window of any screen.  This is how XDE::Setbg
determines that another root setting tool has been used to set the
background.

=cut

sub changed_XROOTPMAP_ID {
    my ($self,$screen,$e) = @_;
    my $X = $self->{X};
    my $d = $screen->{desktop};
    my ($val,$type) = $X->GetProperty($e->{window}, $e->{atom},
	    $X->atom('PIXMAP'), 0, 1);
    my $pmid = $type ? unpack('L',substr($val,0,4)) : 0;
    my $oldid = ${$screen->{pmids}[$d]};
    if ($pmid != $oldid) {
	# hsetroot and others free the old pixmap
	${$screen->{pmids}[$d]} = $pmid;
    }
}

=item $xde->B<changed_XSETROOT_ID>(I<$screen>,I<$event>)

Internal function that handles when the B<_XSETROOT_ID> property
changes on the root window of any screen.  This is how XDE::Setbg
determines that another root setting tool has been used to set the
background.  This is for backward compatability with older root setters.

=cut

sub changed_XSETROOT_ID {
    my ($self,$screen,$e) = @_;
    my $X = $self->{X};
    my $d = $screen->{desktop};
    my ($val,$type) = $X->GetProperty($e->{window}, $e->{atom},
	    $X->atom('PIXMAP'), 0, 1);
    my $pmid = $type ? unpack('L',substr($val,0,4)) : 0;
    my $oldid = ${$screen->{pmids}[$d]};
    if ($pmid != $oldid) {
	# hsetroot and others free the old pixmap
	${$screen->{pmids}[$d]} = $pmid;
    }
}

=item $xde->B<changed_NET_CURRENT_DESKTOP>(I<$screen>,I<$event>)

Internal function that handles when the B<_NET_CURRENT_DESKTOP> property
changes on the root window of any screen.  This is how XDE::Setbg
determines that the desktop has changed.

=cut

sub changed_NET_CURRENT_DESKTOP {
    my ($self,$screen,$e) = @_;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    my ($val,$type) = $X->GetProperty($e->{window}, $e->{atom},
	    $X->atom('CARDINAL'), 0, 1);
    my $desktop = $type ? unpack('L',substr($val,0,4)) : 0;
    my $d = $screen->{desktop};
    printf STDERR "new desktop %d (was %d)\n", $desktop, $d if $verbose;
    if ($desktop != $d) {
	my $oldid = ${$screen->{pmids}[$d]};
	my $newid = ${$screen->{pmids}[$desktop]};
	printf STDERR "new pixmap 0x%08x (was 0x%08x)\n", $newid, $oldid if $verbose;
	if ($newid != $oldid) {
	    # need to change pixmap on root
	    $self->set_pixmap($screen->{root},$newid);
	}
	$screen->{desktop} = $desktop;
    }
}

=item $xde->B<changed_NET_NUMBER_OF_DESKTOPS>(I<$screen>,I<$event>)

Internal function that handles when the B<_NET_NUMBER_OF_DESKTOPS>
property changes on the root window of any screen.  This is how
XDE::Setbug determines the total number of desktops.

=cut

sub changed_NET_NUMBER_OF_DESKTOPS {
    my ($self,$screen,$e) = @_;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    my ($val,$type) = $X->GetProperty($e->{window}, $e->{atom},
	    $X->atom('CARDINAL'), 0, 1);
    my $desktops = $type ? unpack('L',substr($val,0,4)) : 1;
    my $n = $screen->{desktops};
    printf STDERR "new number of desktops %d (was %d)\n", $desktops, $n if $verbose;
    if ($desktops != $n) {
	if ($desktops > $n) {
	    # modulate the backgrounds over the new desktops
	    for (my $i=0;$i<$desktops;$i++) {
		next unless $i >= $n;
		my $d = $i % $n;
		$screen->{pmids}[$i] = $screen->{pmids}[$d];
	    }
	}
	$screen->{desktops} = $desktops;
    }
}

=item $xde->B<changed_WIN_WORKSPACE>(I<$screen>,I<$event>)

Internal function that handles when the B<_WIN_WORKSPACE> property
changes on the root window of any screen.  This is how XDE::Setbg
determines that the workspace has changed.
This is for compatablity with older window managers (such as
L<wmaker(1)>).

=cut

sub changed_WIN_WORKSPACE {
    my ($self,$screen,$e) = @_;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    my ($val,$type) = $X->GetProperty($e->{window}, $e->{atom},
	    $X->atom('CARDINAL'), 0, 1);
    my $workspace = $type ? unpack('L',substr($val,0,4)) : 0;
    my $d = $screen->{workspace};
    printf STDERR "new workspace %d (was %d)\n", $workspace, $d
        if $verbose;
    if ($workspace != $d) {
	if (0) {
	my $oldid = ${$screen->{pmids}[$d]};
	my $newid = ${$screen->{pmids}[$workspace]};
	printf STDERR "new pixmap 0x%08x (was 0x%08x)\n", $newid, $oldid
            if $verbose;
	if ($newid != $oldid) {
	    # need to change pixmap on root
	    $self->set_pixmap($screen->{root},$newid);
	}
	}
	$screen->{workspace} = $d;
    }
}

=item $xde->B<changed_WIN_WORKSPACE_COUNT>(I<$screen>,I<$event>)

Internal function that handles when the B<_WIN_WORKSPACE_COUNT> property
changes on the root window of any screen.  This is how XDE::Setbug
determines the total number of workspaces.
This is for compatablity with older window managers (such as
L<wmaker(1)>).

=cut

sub changed_WIN_WORKSPACE_COUNT {
    my ($self,$screen,$e) = @_;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    my ($val,$type) = $X->GetProperty($e->{window}, $e->{atom},
	    $X->atom('CARDINAL'), 0, 1);
    my $workspaces = $type ? unpack('L',substr($val,0,4)) : 1;
    my $n = $screen->{workspaces};
    printf STDERR "new number of workspaces %d (was %d)\n",
	   $workspaces, $n if $verbose;
    if ($workspaces != $n) {
	if ($workspaces > $n) {
	    if (0) {
	    # modulate the backgrounds over the new workspaces
	    for (my $i=0;$i<$workspaces;$i++) {
		next unless $i >= $n;
		my $d = $i % $n;
		$screen->{pmids}[$i] = $screen->{pmids}[$d];
	    }
	    }
	}
	$screen->{workspaces} = $workspaces;
    }
}

sub _handle_event_PropertyNotify {
    my ($self,$e) = @_;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    print STDERR "getting atom name...\n" if $verbose;
    my $name = $X->GetAtomName($e->{atom});
    print STDERR "got name $name\n" if $verbose;
    print STDERR "atom: ",$X->atom_name($e->{atom}),"\n" if $verbose;
    return unless exists $self->{roots}{$e->{window}};
    my $n = $self->{roots}{$e->{window}};
    my $screen = $self->{screen}[$n] or return;
    return unless $e->{window} == $X->{screens}[$n]{root};
    my $action = "changed".$X->atom_name($e->{atom});
    print STDERR "Action is: '$action'\n" if $verbose;
    return $self->$action($screen,$e) if $self->can($action);
}

sub _handle_event_ButtonPress {
    my ($self,$e) = @_;
    my $X = $self->{X};
    return unless exists $self->{roots}{$e->{window}};
    my $n = $self->{roots}{$e->{window}};
    my $screen = $self->{screen}[$n] or return;
    return unless $e->{window} == $screen->{proxy};
}

sub _handle_event_ButtonRelease {
    my ($self,$e) = @_;
    my $X = $self->{X};
    return unless exists $self->{roots}{$e->{window}};
    my $n = $self->{roots}{$e->{window}};
    my $screen = $self->{screen}[$n] or return;
    return unless $e->{window} == $screen->{proxy};
    if ($e->{detail} == 4) {
	# increase desktop number
    }
    elsif ($e->{detail} == 5) {
	# decrease desktop number
    }
}

=item $xde->B<event_handler>(I<$event>)

Internal event handler for the XDE::Setbg module.  This is an
L<X11::Protocol(3pm)> handler that is invoked either by direct requests
made of the X11::Protocol object ($self->{X}) or by Glib::Mainloop when
it triggers an input watcher on the X11::Protocol::Connection.
C<$event> is the unpacked X11::Protocol event.

=cut

sub event_handler {
    my ($self,%e) = @_;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    print STDERR "-----------------\nReceived event: ", join(',',%e), "\n" if $verbose;
    my $handler = "_handle_event_$e{name}";
    print STDERR "Handler is: '$handler'\n" if $verbose;
    if ($self->can($handler)) {
	$self->$handler(\%e);
	return;
    }
    print STDERR "Discarding event...\n" if $verbose;
}

=item $xde->B<error_handler>(I<$X>,I<$error>)

Internal error handler for the XDE::Setbg module.  This is an
L<X11::Protocol(3pm)> handler that is invoked either by direct requests
made of the X11::Protocol object ($self->{X}) or by Glib::Mainloop when
it triggers an input watcher on the X11::Protocol::Connection.
C<$error> is the packed error message.

=cut

sub error_handler {
    my ($self,$e) = @_;
    my $X = $self->{X};
    print STDERR "Received error: \n",
	  $X->format_error_msg($e), "\n";
}

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

1;

# vim: sw=4 tw=72
