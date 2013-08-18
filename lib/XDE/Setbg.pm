package XDE::Setbg;
use base qw(XDE::Dual);
use Linux::Inotify2;
use Glib qw(TRUE FALSE);
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

=item $xde->B<wmpropcheck>() => $window or undef

Internal method for checking a recursive property such as
B<_NET_SUPPORTING_WM_CHECK>.

=cut

sub wmpropcheck {
    my $self = shift;
    my ($screen,$d,$root,$n,$atom,$label) = @_;
    return undef unless $screen;
    my $result = undef;
    my $X = $self->{X};
    my $v = $self->{ops}{verbose};
    my ($val,$type) = $X->GetProperty($root,$atom,0,0,1);
    if ($type) {
	my $check = unpack('L',substr($val,0,4));
	print STDERR "found $label check on root window\n" if $v;
	($val,$type) = $X->GetProperty($check,$atom,0,0,1);
	if ($type and $check == unpack('L',substr($val,0,4))) {
	    print STDERR "found $label on check window\n" if $v;
	    unless ($screen->{$label} and $screen->{$label} == $check) {
		print STDERR "new $label check window\n" if $v;
		$screen->{$label} = $check;
		$self->{roots}{$check} = $n;
		$result = $check;
	    } else {
		print STDERR "$label check unchanged\n" if $v;
		$result = 0;
	    }
	} else {
	    print STDERR "Could not retrieve ", $X->atom_name($atom), "\n";
	}
    } else {
	print STDERR "Could not retrieve ", $X->atom_name($atom), "\n";
    }
    return $result;
}

=item $xde->B<win_wmcheck>()

Internal method to check for B<_WIN_SUPPORTING_WM_CHECK>.  Unfortunately
there is not enough information to identify the window manager.

=cut

sub win_wmcheck {
    my $self = shift;
    my $X = $self->{X};
    my $atom = $X->atom('_WIN_SUPPORTING_WM_CHECK');
    return $self->wmpropcheck(@_, $atom, 'wcheck');
}

=item $xde->B<net_wmcheck>()

Internal method to check for B<_NET_SUPPORTING_WM_CHECK> and establish
the identity of the window manager.

=cut

sub net_wmcheck {
    my $self = shift;
    my $X = $self->{X};
    my $atom = $X->atom('_NET_SUPPORTING_WM_CHECK');
    my $check = $self->wmpropcheck(@_, $atom, 'ncheck');
    if ($check) {
	my $atom = $X->atom('_NET_WM_NAME');
	my ($val,$type) = $X->GetProperty($check, $atom, 0, 0, 255);
	if ($type) {
	    my ($name) = unpack('(Z*)*',$val);
	    ($name) = split(/\s+/,$name);
	    if ($name) {
		$self->{wmname} = "\L$name\E";
		print STDERR "Window Manager name is: \L$name\E\n"
		    if $self->{ops}{verbose};
	    } else {
		print STDERR "Null name!\n";
		$self->{wmname} = '' unless $self->{wmname};
	    }
	} else {
	    print STDERR "Could not retrieve ", $X->atom_name($atom), "\n";
	    print STDERR "Guessing WindowMaker\n";
	    $self->{wmname} = 'wmaker';
	}
	# TODO: There are some other things to do here, such as
	# resetting the theme.
    }
    return $check;
}

=item $xde->B<win_bpcheck>()

Internal method to check for B<_WIN_DESKTOP_BUTTON_PROXY>.  Also,
register for C<SubstructureNotify> events when the button proxy exists
so that we can receive scroll wheel events to change the desktop.

=cut

sub win_bpcheck {
    my $self = shift;
    my ($screen,$d,$root,$n) = @_;
    my $X = $self->{X};
    my $atom = $X->atom('_WIN_DESKTOP_BUTTON_PROXY');
    my $proxy = $self->wmpropcheck(@_, $atom, 'proxy');
    if ($screen->{proxy}) {
	$X->ChangeWindowAttributes($screen->{proxy},
		event_mask=>$X->pack_event_mask('SubstructureNotify'));
    }
    return $proxy;
}

=item $xde->B<_init>()

Performs initialization for just this module.  Called after
L<XDE::Dual(3pm)> is fully initialized.  Determines the initial values
and settings of the root window on each screen of the display for later
displaying the background images.

=cut

sub _init {
    my $self = shift;
    # Set up an Inotify2 connection.
    my $N = $self->{N};
    unless ($N) {
	$N = $self->{N} = Linux::Inotify2->new;
	$N->blocking(FALSE);
    }
    Glib::Source->remove(delete $self->{notify}{watcher})
	if $self->{notify}{watcher};
    $self->{notify}{watcher} = Glib::IO->add_watch($N->fileno,
	    'in', sub{ $N->poll });
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    $X->ChangeWindowAttributes($X->root,
	    event_mask=>$X->pack_event_mask(
		'PropertyChange',
		'StructureNotify'));
    for (my $n=0;$n<@{$X->{screens}};$n++) {
	my $screen = $self->{screen}[$n];
	$screen = $self->{screen}[$n] = {index=>$n} unless $screen;
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
		$X->atom('_NET_DESKTOP_PIXMAPS'),
		$X->atom('PIXMAP'), 0, 12, 1);
	if ($type) {
	    my @pixmaps = unpack('L*',$val);
	    print STDERR "Got ",scalar(@pixmaps)," pixmaps:",join(', ',map{sprintf "0x%02x",$_}@pixmaps),"\n" if $verbose;
	    my %pixmaps = ();
	    for (my $i=0;$i<@pixmaps;$i++) {
		my $pixmap = $pixmaps[$i];
		next unless $pixmap;
		$pixmaps{$pixmap} = \$pixmap
		    unless $pixmaps{$pixmap};
		$screen->{pmids}[$i] = $pixmaps{$pixmap};
		$screen->{files}[$i] = undef;
		$screen->{pmid} = $pixmap
		    if defined $d and $d == $i;
	    }
	}
	($val,$type) = $X->GetProperty($root,
		$X->atom('_XROOTPMAP_ID'),
		$X->atom('PIXMAP'), 0, 1);
	if ($type) {
	    my $pmid = unpack('L',substr($val,0,4));
	    printf STDERR "Existing pixmap id is 0x%08x\n", $pmid
		if $verbose;
	    my $oldid = ${$screen->{pmids}[$d]}
		if $screen->{pmids}[$d];
	    if ($oldid and $oldid != $pmid) {
		$X->FreePixmap($oldid);
		${$screen->{pmids}[$d]} = 0;
		delete $screen->{files}[$d];
	    }
	    if ($pmid) {
		if ($screen->{pmids}[$d]) {
		    ${$screen->{pmids}[$d]} = $pmid;
		} else {
		    $screen->{pmids}[$d] = \$pmid;
		}
	    }
	    $screen->{pmid} = $pmid;
	}
	$self->win_bpcheck($screen,$d,$root,$n);
	$self->win_wmcheck($screen,$d,$root,$n);
	$self->net_wmcheck($screen,$d,$root,$n);
	$self->check_theme($screen,$d,$root,$n);
    }
    if ($self->{wmname} and $self->{wmname} eq 'icewm') {
	# icewmbg gets in the way, tell it to quit
	$X->SendEvent($X->root, 0,
		$X->pack_event_mask(qw(
			StructureNotify
			SubstructureNotify
			SubstructureRedirect)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$X->root,
		    format=>32,
		    type=>$X->atom('_ICEWMBG_QUIT'),
		    data=>pack('LLLLL',$$,0,0,0,0),
		));
	$X->flush;
    }
    return $self;
}

=item $xde->B<_term>()

Performs termination for just this module.  Called before
C<XDE::X11-E<gt>term()> is called.

B<XDE::Setbg> allocates pixmaps that persist on close.  This is so that
the _XROOTPMAP_ID pixmap is never deallocated while the property is set.
This method frees all of the pixmaps in the server except the one that
is currently set as _XROOTPMAP_ID.

=cut

sub remove_pixmaps {
    my ($self,$screen) = @_;
    foreach (@{$screen->{pmids}}) {
	if ($_ and $$_) {
	    if (my $file = delete $self->{pmids}{$$_}) {
		delete $self->{files}{$file};
	    }
	    $$_ = 0;
	}
    }
    $screen->{pmids} = [];
    $screen->{files} = [];
}

sub remove_images {
    my ($self,$screen) = @_;
    my $X = $self->{X};
    my $v = $self->{ops}{verbose};
    foreach (@{$screen->{pmids}}) {
	if ($_ and $$_) {
	    if (my $file = delete $self->{pmids}{$$_}) {
		delete $self->{files}{$file};
		$X->FreePixmap($$_);
	    } else {
		$X->KillClient($$_);
	    }
	    $$_ = 0;
	}
    }
    $screen->{pmids} = [];
    $screen->{files} = [];
    $X->KillClient('AllTemporary');
    $X->choose_screen(0);
    $X->DeleteProperty($X->root,$X->atom('_NET_DESKTOP_PIXMAPS'));
    $X->flush;
}

sub _term {
    my $self = shift;
    # Remove the Inotify2 connection.
    my $N = delete $self->{N};
    Glib::Source->remove(delete $self->{notify}{watcher})
	if $self->{notify}{watcher};
    foreach (keys %{$self->{notify}}) {
	if (my $w = delete $self->{notify}{$_}) {
	    $w->cancel;
	}
    }
    undef $N;
    my $X = $self->{X};
    for (my $i=0;$i<@{$X->{screens}};$i++) {
	my $screen = $self->{screen}[$i];
	for (my $d=0;$d<@{$screen->{pmids}};$d++) {
	    if ($d == $screen->{desktop}) {
		${$screen->{pmids}[$d]} = 0;
	    }
	    elsif ($screen->{pmids}[$d] and
		    my $pmid = ${$screen->{pmids}}[$d]) {
		# $X->FreePixmap($pmid);
		$X->KillClient($pmid)
		    unless delete $self->{pmids}{$pmid};
		$X->flush;
		${$screen->{pmids}[$d]} = 0;
	    }
	}
	$X->choose_screen($i);
	$X->DeleteProperty($X->root,$X->atom('_NET_DESKTOP_PIXMAPS'));
	$X->flush;
    }
}

=item $xde->B<set_pixmap>(I<$root>,I<$pmid>)

Sets the pixmap specified by pixmap id, C<$pmid>, on the root window
specified by C<$root>.  This is normally only called internally.  This
function needs to be improved to set the background color as well and to
support tiling and solid colors and gradients when there is no pixmap
specified (i.e. C<$pmid == 0>.

=cut

sub set_pixmap {
    my ($self,$root,$pmid) = @_;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    my $grab = $self->{ops}{grab};
    printf STDERR "setting root window 0x%08x to pixmap 0x%08x\n",
	   $root, $pmid if $verbose;
    $X->ChangeWindowAttributes($root,
	    background_pixmap=>$pmid);
    $X->flush;
    $X->ClearArea($root,0,0,0,0,0);
    $X->flush;
    my $data = pack('L',$pmid);
    $X->GrabServer   if $grab;
    foreach (qw(_XROOTPMAP_ID))
#   foreach (qw(_XROOTPMAP_ID ESETROOT_PMAP_ID _XSETROOT_ID _XROOTMAP_ID))
    {
	$X->ChangeProperty($root, $X->atom($_),
		$X->atom('PIXMAP'), 32, 'Replace', $data);
    }
    $X->UngrabServer if $grab;
    $X->flush;
}

sub deferred_set_pixmap {
    my ($self,$screen) = @_;
    my $X = $self->{X};
    my $n = $screen->{index};
    delete $self->{idle}{set_pixmap}[$n];
    my $i = $screen->{desktop};
    my $root = $screen->{root};
    my $pmid = ${$screen->{pmids}[$i]} if $screen->{pmids}[$i];
    return Glib::SOURCE_REMOVE unless $pmid;
    unless ($screen->{pmid}) {
	my ($val,$type) = $X->GetProperty($root,
		$X->atom('_XROOTPMAP_ID'),
		$X->atom('PIXMAP'), 0, 1);
	return Glib::SOURCE_REMOVE unless $type;
	my $pmap = unpack('L',substr($val,0,4));
	$screen->{pmid} = $pmap;
    }
    $self->set_pixmap($root,$pmid) if $pmid != $screen->{pmid};
    $screen->{pmid} = $pmid;
    return Glib::SOURCE_REMOVE;
}

sub set_deferred_pixmap {
    my ($self,$screen) = @_;
    my $n = $screen->{index};
    unless ($self->{idle}{set_pixmap}[$n]) {
	$self->{idle}{set_pixmap}[$n] =
	    Glib::Idle->add(sub{return $self->deferred_set_pixmap($screen)});
    }
}

=item $xde->B<modulate_desktops>(I<$screen>,I<$desktops>)

Internal method to modulate the defined backgrounds over the available
desktops when the number of desktops is greater than the number of
defined backgrounds.

=cut

sub modulate_desktops {
    my ($self,$screen,$k) = @_;
    my $n = $self->{defined};
    if ($k > $n) {
	# modulate the backgrounds over the available desktops
	for (my $i=0;$i<$k;$i++) {
	    next unless $i >= $n;
	    my $j = $i % $n;
	    $screen->{pmids}[$i] = $screen->{pmids}[$j];
	    $screen->{files}[$i] = $screen->{files}[$j];
	    if ($i == $screen->{desktop}) {
		#$self->set_deferred_pixmap($screen);
		$self->set_pixmap($screen->{root},${$screen->{pmids}[$i]});
	    }
	}
    }

}

=item $xde->B<create_pixmap>(I<$screen>,I<$n>,I<$w>,I<$h>,I<$pixbuf>,I<$pmid>,I<$i>)

Internal method to create a pixmap from a pixbuf.  We should avoid doing
this on every theme check because it involves transferring a lot of
information to potentially remote display. 

=cut

sub create_pixmap {
    my ($self,$screen,$n,$w,$h,$pixbuf,$pmid,$i,$file) = @_;
    my ($width,$height) = ($pixbuf->get_width,$pixbuf->get_height);
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
	$h_box = $h;
	$y_src = ($height-$h)/2;
	$y_dst = 0;
    }
    elsif ($height < $h) {
	$h_box = $height;
	$y_src = 0;
	$y_dst = ($h-$height)/2;
    }
    printf STDERR "Getting foreign pixmap id 0x%08x\n", $pmid
	if $self->{ops}{verbose};
    my $display = Gtk2::Gdk::Display->get_default;
    my $pixmap = Gtk2::Gdk::Pixmap->foreign_new($pmid);
    if (0 and $self->{ops}{verbose}) {
	printf STDERR "Drawing to pixmap id 0x%08x\n", $pmid;
	printf STDERR "\tx_src = %d\n", $x_src;
	printf STDERR "\ty_src = %d\n", $y_src;
	printf STDERR "\tx_dst = %d\n", $x_dst;
	printf STDERR "\ty_dst = %d\n", $y_dst;
	printf STDERR "\tw_box = %d\n", $w_box;
	printf STDERR "\th_box = %d\n", $h_box;
	printf STDERR "\twidth = %d\n", $width;
	printf STDERR "\theight = %d\n", $height;
	printf STDERR "\tw = %d\n", $w;
	printf STDERR "\th = %d\n", $h;
    }
    $pixmap->draw_pixbuf(undef,$pixbuf,$x_src,$y_src,$x_dst,$y_dst,$w_box,$h_box,'none',0,0);
    $display->flush;
    $display->sync;
    my $oldid = $screen->{pmids}[$i];
    $screen->{pmids}[$i] = \$pmid;
    $self->{pmids}{$pmid} = $file;
    $screen->{files}[$i] = \$file;
    $self->{files}{$file} = $pmid;
    # TODO: we should also set the background color even
    # when there is a pixmap.
    if ($i == $screen->{desktop}) {
	#$self->set_deferred_pixmap($screen);
	$self->set_pixmap($screen->{root},$pmid);
    }
    if ($oldid and $$oldid) {
	my $X = $self->{X};
	if (my $oldfile = delete $self->{pmids}{$$oldid}) {
	    delete $self->{files}{$oldfile};
	    # Free the old pixmap if it was us
	    $X->FreePixmap($$oldid);
	} else {
	    # Kill the client if it wasn't us
	     #$X->KillClient($$oldid);
	    $X->FreePixmap($$oldid);
	}
	$X->flush;
	$$oldid = 0;
    }
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
    my $v = $self->{ops}{verbose};

    my $n = $self->{defined} = scalar(@files);
    return unless $n;
    print STDERR "There are $n files\n" if $v;
    my $screens = scalar @{$X->{screens}};
    print STDERR "There are $screens screens\n" if $v;
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
	print STDERR "using mode '$mode', file '$file'\n" if $v;
	my $pixbuf;
	if ($mode eq 'fill') {
	    eval { $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_scale($file,$w,$h,FALSE); }
		or print STDERR "$!\n";
	}
	elsif ($mode eq 'full') {
	    eval { $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_scale($file,$w,$h,TRUE); }
		or print STDERR "$!\n";
	}
	elsif ($mode eq 'center') {
	    eval { $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_size($file,$w,$h); }
		or print STDERR "$!\n";
	}
	elsif ($mode eq 'tile') {
	    eval { $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($file); }
		or print STDERR "$!\n";
	}
	unless ($pixbuf) {
	    print STDERR "could not get pixbuf for file '$file'\n";
	    next;
	}
	$self->create_pixmap($screen,$n,$w,$h,$pixbuf,$pmids[$i],$i,$file);
    }
    $self->modulate_desktops($screen,$screen->{desktops});
}

=item $xde->B<get_ProprertyNotify_screen>(I<$e>,I<$X>,I<$v>) => $screen,$d,$root,$n

Internal function to identify the screen, C<$screen>, desktop, C<$d>,
root window C<$root>, and screen number, C<$n>, from X11::Protocol
C<PropertyNotify> event information.

=cut

sub get_PropertyNotify_screen {
    my ($self,$e,$X,$v) = @_;
    defined(my $n = $self->{roots}{$e->{window}}) or return;
    defined(my $screen = $self->{screen}[$n]) or return;
    my $root = $X->{screens}[$n]{root};
    return unless $e->{window} == $root;
    return ($screen,$screen->{desktop},$root,$n);
}

=item $xde->B<event_handler_PropertyNotify_XROOTPMAP_ID>(I<$screen>,I<$event>,I<$X>,I<$v>)

Internal function that handles when the B<_XROOTPMAP_ID> property
changes on the root window of any screen.  This is how XDE::Setbg
determines that another root setting tool has been used to set the
background.

=cut

sub event_handler_PropertyNotify_XROOTPMAP_ID {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my ($screen,$d,$root,$n) = $self->get_PropertyNotify_screen(@_);
    return unless $screen;
    my ($val,$type) = $X->GetProperty($root,$e->{atom},
	    $X->atom('PIXMAP'), 0, 1);
    if ($type) {
	my $pmid = unpack('L',substr($val,0,4));
	$screen->{pmid} = $pmid;
	unless ($self->{pmids}{$pmid}) {
	    if (1) {
		my $oldid = ${$screen->{pmids}[$d]}
		    if $screen->{pmids}[$d];
		if ($oldid and $oldid != $pmid) {
		    $X->FreePixmap($oldid);
		    ${$screen->{pmids}[$d]} = 0;
		    delete $self->{pmids}{$pmid};
		    delete $screen->{files}[$d];
		}
		if ($pmid) {
		    if ($screen->{pmids}[$d]) {
			${$screen->{pmids}[$d]} = $pmid
		    } else {
			$screen->{pmids}[$d] = \$pmid;
		    }
		}
		$screen->{pmid} = $pmid;
	    } else {
		my $oldid = ${$screen->{pmids}[$d]};
		if ($pmid != $oldid) {
		    # hsetroot and others free the old pixmap, kill
		    # the old client and remove all temporaries, so
		    # remove the freed pixmaps
		    $self->remove_pixmaps($screen);
		    $self->{defined} = 1;
		    ${$screen->{pmids}[0]} = \$pmid;
		    ${$screen->{files}[0]} = undef;
		    $self->modulate_desktops($screen,$screen->{desktops});
		}
	    }
	}
    } else {
	print STDERR "Could not retrieve ", $X->atom_name($e->{atom}), "\n";
    }
}

=item $xde->B<event_handler_PropertyNotifyESETROOT_PMAP_ID>(I<$screen>,I<$event>,I<$X>,I<$v>)

We do not really process this because all proper root setters now set
the B<_XROOTPMAP_ID> property which we handle above.  However, it is
used to trigger recheck of the theme needed by some window managers such
as L<blackbox(1)>.  If it means we check 3 times after a theme switch,
so be it.

=cut

#sub event_handler_PropertyNotifyESETROOT_PMAP_ID {
#    my $self = shift;
#    $self->check_theme($self->get_PropertyNotify_screen(@_));
#}

=item $xde->B<event_handler_PropertyNotify_XROOTMAP_ID>(I<$event>,I<$X>,I<$v>)

We do not really process this because all proper root setters now set
the B<_XROOTPMAP_ID> property which we handle above.  However, it is
used to trigger recheck of the theme needed by some window managers such
as L<blackbox(1)>.  If it means we check 3 times after a theme switch,
so be it.

=cut

#sub event_handler_PropertyNotify_XROOTMAP_ID {
#    my $self = shift;
#    $self->check_theme($self->get_PropertyNotify_screen(@_));
#}

=item $xde->B<event_handler_PropertyNotify_XSETROOT_ID>(I<$event>,I<$X>,I<$v>)

Internal function that handles when the B<_XSETROOT_ID> property
changes on the root window of any screen.  This is how XDE::Setbg
determines that another root setting tool has been used to set the
background.  This is for backward compatability with older root setters.

We do not really process this because all proper root setters now set
the B<_XROOTPMAP_ID> property which we handle above.  However, it is
used to trigger recheck of the theme needed by some window managers such
as L<blackbox(1)>.  If it means we check 3 times after a theme switch,
so be it.

=cut

sub event_handler_PropertyNotify_XSETROOT_ID {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my ($screen,$d,$root,$n) = $self->get_PropertyNotify_screen(@_);
    return unless $screen;
    my ($val,$type) = $X->GetProperty($root, $e->{atom},
	    $X->atom('PIXMAP'), 0, 1);
    if ($type) {
	my $pmid = unpack('L',substr($val,0,4));
	$screen->{pmid} = $pmid;
	unless ($self->{pmids}{$pmid}) {
	    my $oldid = ${$screen->{pmids}[$d]};
	    if (1) {
		my $oldid = ${$screen->{pmids}[$d]}
		    if $screen->{pmids}[$d];
		if ($oldid and $oldid != $pmid) {
		    $X->FreePixmap($oldid);
		    ${$screen->{pmids}[$d]} = 0;
		    delete $self->{pmids}{$pmid};
		    delete $screen->{files}[$d];
		}
		if ($pmid) {
		    if ($screen->{pmids}[$d]) {
			${$screen->{pmids}[$d]} = $pmid
		    } else {
			$screen->{pmids}[$d] = \$pmid;
		    }
		}
		$screen->{pmid} = $pmid;
	    } else {
		my $oldid = ${$screen->{pmids}[$d]};
		if ($pmid != $oldid) {
		    # hsetroot and others free the old pixmap, kill
		    # the old client and remove all temporaries, so
		    # remove the freed pixmaps
		    $self->remove_pixmaps($screen);
		    $self->{defined} = 1;
		    ${$screen->{pmids}[0]} = \$pmid;
		    ${$screen->{files}[0]} = undef;
		    $self->modulate_desktops($screen,$screen->{desktops});
		}
	    }
	}
    } else {
	print STDERR "Could not retrieve ", $X->atom_name($e->{atom}), "\n";
    }
}

=item $xde->B<event_handler_PropertyNotify_NET_CURRENT_DESKTOP>(I<$event>,I<$X>,I<$v>)

Internal function that handles when the B<_NET_CURRENT_DESKTOP> property
changes on the root window of any screen.  This is how XDE::Setbg
determines that the desktop has changed.

=cut

sub event_handler_PropertyNotify_NET_CURRENT_DESKTOP {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my ($screen,$d,$root,$n) = $self->get_PropertyNotify_screen(@_);
    return unless $screen;
    my ($val,$type) = $X->GetProperty($root, $e->{atom},
	    $X->atom('CARDINAL'), 0, 1);
    if ($type) {
	my $desktop = unpack('L',substr($val,0,4));
	printf STDERR "new desktop %d (was %d)\n", $desktop, $d if $v;
	if ($desktop != $d) {
	    if (defined $screen->{pmids}[$d] and
		defined $screen->{pmids}[$desktop]) {
		my $oldid = ${$screen->{pmids}[$d]};
		my $newid = ${$screen->{pmids}[$desktop]};
		printf STDERR "new pixmap 0x%08x (was 0x%08x)\n", $newid, $oldid if $v;
		if ($newid != $oldid) {
		    # need to change pixmap on root
		    $self->set_deferred_pixmap($screen);
		    #$self->set_pixmap($screen->{root},$newid);
		}
	    }
	    $screen->{desktop} = $desktop;
	}
    } else {
	print STDERR "Could not retrieve ", $X->atom_name($e->{atom}), "\n";
    }
}

=item $xde->B<event_handler_PropertyNotify_NET_NUMBER_OF_DESKTOPS>(I<$event>,I<$X>,I<$v>)

Internal function that handles when the B<_NET_NUMBER_OF_DESKTOPS>
property changes on the root window of any screen.  This is how
XDE::Setbug determines the total number of desktops.

=cut

sub event_handler_PropertyNotify_NET_NUMBER_OF_DESKTOPS {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my ($screen,$d,$root,$n) = $self->get_PropertyNotify_screen(@_);
    return unless $screen;
    my ($val,$type) = $X->GetProperty($root, $e->{atom},
	    $X->atom('CARDINAL'), 0, 1);
    if ($type) {
	my $desktops = unpack('L',substr($val,0,4));
	my $n = $screen->{desktops};
	printf STDERR "new number of desktops %d (was %d)\n", $desktops, $n if $v;
	if ($desktops != $n) {
	    $screen->{desktops} = $desktops;
	    $self->modulate_desktops($screen,$desktops);
	}
    } else {
	print STDERR "Could not retrieve ", $X->atom_name($e->{atom}), "\n";
    }
}

=item $xde->B<event_handler_PropertyNotify_WIN_WORKSPACE>(I<$event>,I<$X>,I<$v>)

Internal function that handles when the B<_WIN_WORKSPACE> property
changes on the root window of any screen.  This is how XDE::Setbg
determines that the workspace has changed.
This is for compatablity with older window managers (such as
L<wmaker(1)>).

=cut

sub event_handler_PropertyNotify_WIN_WORKSPACE {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my ($screen,$d,$root,$n) = $self->get_PropertyNotify_screen(@_);
    return unless $screen;
    my ($val,$type) = $X->GetProperty($root, $e->{atom},
	    $X->atom('CARDINAL'), 0, 1);
    if ($type) {
	my $workspace = unpack('L',substr($val,0,4));
	printf STDERR "new workspace %d (was %d)\n", $workspace, $d if $v;
	if ($workspace != $d) {
	    if (0) {
	    my $oldid = ${$screen->{pmids}[$d]};
	    my $newid = ${$screen->{pmids}[$workspace]};
	    printf STDERR "new pixmap 0x%08x (was 0x%08x)\n", $newid, $oldid if $v;
	    if ($newid != $oldid) {
		# need to change pixmap on root
		$self->set_deferred_pixmap($screen);
		#$self->set_pixmap($screen->{root},$newid);
	    }
	    }
	    $screen->{workspace} = $d;
	}
    } else {
	print STDERR "Could not retrieve ", $X->atom_name($e->{atom}), "\n";
    }
}

=item $xde->B<event_handler_PropertyNotify_WIN_WORKSPACE_COUNT>(I<$event>,I<$X>,I<$v>)

Internal function that handles when the B<_WIN_WORKSPACE_COUNT> property
changes on the root window of any screen.  This is how XDE::Setbug
determines the total number of workspaces.
This is for compatablity with older window managers (such as
L<wmaker(1)>).

=cut

sub event_handler_PropertyNotify_WIN_WORKSPACE_COUNT {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my ($screen,$d,$root,$n) = $self->get_PropertyNotify_screen(@_);
    return unless $screen;
    my ($val,$type) = $X->GetProperty($e->{window}, $e->{atom},
	    $X->atom('CARDINAL'), 0, 1);
    if ($type) {
	my $workspaces = unpack('L',substr($val,0,4));
	my $n = $screen->{workspaces};
	printf STDERR "new number of workspaces %d (was %d)\n",
	       $workspaces, $n if $v;
	if ($workspaces != $n) {
	    $screen->{workspaces} = $workspaces;
	    # $self->modulate_desktops($screen,$workspaces);
	}
    } else {
	print STDERR "Could not retrieve ", $X->atom_name($e->{atom}), "\n";
    }
}

=item $xde->B<event_handler_PropertyNotify_WIN_DESKTOP_BUTTON_PROXY>(I<$event>,I<$X>,I<$v>)

A restarting window manager (either the old one or a new one) will
change this property on the root window.  Reestablish support for
responding to the button proxy when that happens.

=cut

sub event_handler_PropertyNotify_WIN_DESKTOP_BUTTON_PROXY {
    my $self = shift;
    $self->win_bpcheck($self->get_PropertyNotify_screen(@_));
}

=item $xde->B<event_handler_PropertyNotify_WIN_SUPPORTING_WM_CHECK>(I<$event>,I<$X>,I<$v>)

A restarting window manager (either the old one or a new one) will
change this recursive property on the root window.  However, there is
not enough information to identify the window manager, so just record
the new check.

=cut

sub event_handler_PropertyNotify_WIN_SUPPORTING_WM_CHECK {
    my $self = shift;
    $self->win_wmcheck($self->get_PropertyNotify_screen(@_));
}

=item $xde->B<event_handler_PropertyNotify_NET_SUPPORTING_WM_CHECK>(I<$event>,I<$X>,I<$v>)

A restarting window manager (either the old one or a new one) will
change this recursive property on the root window.  Re-establish the
identity of the window manager and recheck the theme for that window
manager as some window managers restart when setting themes (such as
IceWM).

=cut

sub event_handler_PropertyNotify_NET_SUPPORTING_WM_CHECK {
    my $self = shift;
    $self->net_wmcheck($self->get_PropertyNotify_screen(@_));
    $self->check_theme($self->get_PropertyNotify_screen(@_));
}

=item $xde->B<event_handler_PropertyNotify_OB_THEME>(I<$event>,I<$X>,I<$v>)

Openbox signals a theme change by changing the B<_OB_THEME> property on
the root window.  Check the theme again when it changes.

=cut

sub event_handler_PropertyNotify_OB_THEME {
    my $self = shift;
    $self->check_theme($self->get_PropertyNotify_screen(@_));
}

=item $xde->B<event_handler_PropertyNotify_BB_THEME>(I<$event>,I<$X>,I<$v>)

Our blackbox theme files have a rootCommand that changes the
B<_BB_THEME> property on the root window.  Check the theme again when it
changes.

=cut

sub event_handler_PropertyNotify_BB_THEME {
    my $self = shift;
    $self->check_theme($self->get_PropertyNotify_screen(@_));
}

=item $xde->B<event_handler_PropertyNotify_BLACKBOX_PID>(I<$e>,I<$X>,I<$v>)

When fluxbox restarts, it does not change the
B<_NET_SUPPORTING_WM_CHECK> but it does change the B<_BLACKBOX_PID>,
even if its is just to replace it with the same value.  When restarting,
check the theme again.

=cut

sub event_handler_PropertyNotify_BLACKBOX_PID {
    my $self = shift;
    $self->check_theme($self->get_PropertyNotify_screen(@_));
}

=item $xde->B<event_handler_ButtonPrees>(I<$event>,I<$X>,I<$v>)

Internal method handles button proxy button-press events.  This is
used to change the desktop on window managers that provide this and
need to have the scroll wheel change desktops (IceWM and FVWM).  We
ignore the press and only process the release.

=cut

sub event_handler_ButtonPress {
    my ($self,$e,$X,$v) = @_;
    return unless exists $self->{roots}{$e->{root}};
    my $n = $self->{roots}{$e->{root}};
    my $screen = $self->{screen}[$n] or return;
    # return unless $e->{root} == $screen->{proxy};
    # we won't act on the button press, just the release
}

=item $xde->B<event_handler_ButtonRelease>(I<$event>,I<$X>,I<$v>)

Internal method handles button proxy button-release events.  This is
used to change the desktop on window managers that provide this and
need to have the scroll wheel change desktops (IceWM and FVWM).

=cut

sub event_handler_ButtonRelease {
    my ($self,$e,$X,$v) = @_;
    return unless exists $self->{roots}{$e->{root}};
    my $n = $self->{roots}{$e->{root}};
    my $screen = $self->{screen}[$n] or return;
    # return unless $e->{root} == $screen->{proxy};
    my $desktop = $screen->{desktop};
    if ($e->{detail} == 4) {
	# increase desktop number
	$desktop += 1; $desktop = 0 if $desktop >= $screen->{desktops};
    }
    elsif ($e->{detail} == 5) {
	# decrease desktop number
	$desktop -= 1; $desktop = $screen->{desktops} - 1 if $desktop < 0;
    }
    else {
	return;
    }
    if ($v) {
	print STDERR "Mouse button: $e->{detail}\n";
	print STDERR "Current desktop: $screen->{desktop}\n";
	print STDERR "Requested desktop: $desktop\n";
	print STDERR "Number of desktops: $screen->{desktops}\n";
    }
    if ($screen->{desktop} != $desktop) {
	$X->SendEvent($X->root, 0,
		$X->pack_event_mask(qw(
			StructureNotify
			SubstructureNotify
			SubstructureRedirect)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$X->root,
		    format=>32,
		    type=>$X->atom('_NET_CURRENT_DESKTOP'),
		    data=>pack('LLLLL',$desktop,0,0,0,0),
		));
	$X->flush;
    }
}

=item $xde->B<correct_theme>(I<%resources>)

Default and correct components of theme resources that have not been
specified in the theme file.

=cut

sub correct_theme {
    my ($self,%r) = @_;
    my $v = $self->{ops}{verbose};
    if ($v) {
	if (exists $r{numb}) {
	    print STDERR "There are '$r{numb}' definitions\n";
	} else {
	    print STDERR "There are no definitions!\n";
	}
    }
    if (exists $r{numb}) {
	print STDERR "Correcting mode\n" if $v;
	for (my $i=0;$i<$r{numb};$i++) {
	    my $ws = $r{workspace};
	    $ws->{$i} = $ws->{all} unless $ws->{$i};
	    if (my $b = $ws->{$i}) {
		if ($b->{pixmap}) {
		    print STDERR "Pixmap for workspace '$i' is '$b->{pixmap}'\n" if $v;
		} else {
		    print STDERR "No pixmap definition for workspace '$i'\n" if $v;
		    $b->{pixmap} = '';
		}
		if ($b->{mode}) {
		    print STDERR "Mode for workspace '$i' is '$b->{mode}'\n" if $v;
		} else {
		    print STDERR "Missing mode for workspace '$i'\n" if $v;
		    if ($b->{file}) {
			$b->{mode} = 'tiled';
		    }
		    elsif ($b->{color}) {
			$b->{mode} = 'solid';
		    }
		    else {
			$b->{mode} = 'none';
		    }
		}
		unless ($b->{color}) {
		    print STDERR "Adding color for workspace '$i'\n" if $v;
		    $b->{color} = '#000000';
		}
	    }
	}
	delete $r{workspace}{all};
    }
    elsif ($r{workspace}{all}) {
	print STDERR "Correcting single desktop\n" if $v;
	$r{workspace}{0} = delete $r{workspace}{all};
	$r{numb} = 1;
    }
    else {
	print STDERR "Correcting lack of desktop defintions\n" if $v;
	%r = ();
    }
    return %r;
}

=item $xde->B<read_anybox_theme>(I<$file>) = %resources

Read the workspace and background specification from a L<fluxbox(1)>,
L<blackbox(1)>, or L<openbox(1)> style file and return a hash of the
background specifications.

The specifications we read are:

 background(.workspace0):         => $r{workspace}{0}{mode}
 background(.workspace0).pixmap:  => $r{workspace}{0}{pixmap}
 background(.workspace0).color:   => $r{workspace}{0}{color}
 background(.workspace0).colorTo: => $r{workspace}{0}{colorTo}
 background(.workspace0).modX:    => $r{workspace}{0}{modX}
 background(.workspace0).modY:    => $r{workspace}{0}{modY}

 (highest workspace index)        => $r{numb}
 session.screen0.workspaces:      => $r{workspaces}
 session.screen0.workspaceNames:  => $r{workspaceNames}

=cut

sub read_anybox_theme {
    my ($self,$file) = @_;
    my %r = ();
    if (-f $file) {
	print STDERR "Reading $file\n" if $self->{ops}{verbose};
	if (open(my $fh,"<",$file)) {
	    while (<$fh>) { chomp;
		if (m{^background(\.(workspace)?(\d+))?\.?(|pixmap|color|colorTo|modX|modY)\s*:\s*(.*)}) {
		    my $spec = $1 ? $3 : 'all';
		    my $part = $4 ? $4 : 'mode';
		    my $valu = $5; $valu =~ s{\s+$}{};
		    $r{workspace}{$spec}{$part} = $valu;
		    $r{numb} = $spec+1 if $spec ne 'all' and
			(not defined $r{numb} or $spec >= $r{numb});
		}
		elsif (m{^session\.screen(\d+)\.(workspaces):\s*(\d+)}) {
		    $r{$2} = $3;
		}
		elsif (m{^session\.screen(\d+)\.(workspaceNames):\s*(.*)$}) {
		    my $screen = $1;
		    my $tag = $2;
		    my $names = $3; $names =~ s{,?\s*$}{};
		    my @names = split(/,/,$names);
		    $r{$tag} = \@names;
		    $r{workspaces} = scalar(@names) unless exists $r{workspaces};
		}
	    }
	    close($fh);
	    %r = $self->correct_theme(%r);
	}
    } else {
	print STDERR "ERROR: file '$file' does not exist\n";
    }
    return %r;
}

=item $xde->B<read_icewm_theme>(I<$file>) => %resources

IceWM supports the following preferences:

 DesktopBackgroundColor="rgb:00/20/40"
 DesktopBackgroundCenter=0 # 0/1
 DesktopBackgroundScaled=0 # 0/1
 DesktopBackgroundImage=""
 SupportSemitransparency=1 # 0/1
 DesktopTransparencyColor=0
 DesktopTransparencyImage=0

We are only concerned with the C<DesktopBackground*> ones.
We add resources that are per desktop such as:

 Desktop0BackgroundColor="rgb:00/20/40"
 Desktop0BackgroundCenter=0
 Desktop0BackgroundScaled=1
 Desktop0BackgroundImage=penguins_jumping

We also add:

 DesktopBackgroundFull=0 # 0/1

Also the image name can be relative, with or without the trailing suffix
(e.g. F<.jpg> or F<.png>) we will find them.  The method returns a hash
that is primarily indexed on the desktop number ot C<all> for the default
definitions, and C<numb> for the maximum desktop index specified plus
one.  The secondary index is C<Color>, C<Image>, C<Center>, C<Scaled>
and has the unquoted value from the file.  When a desktop is missing in
the sequence from c<0> to C<numb-1>, it will be filled in with the C<all>
definition.

=cut

sub read_icewm_theme {
    my ($self,$file) = @_;
    my %r = ();
    if (-f $file) {
	if (open(my $fh,"<",$file)) {
	    while (<$fh>) { chomp;
		if (m{^Desktop(\d+)?Background(Color|Image|Center|Scaled|Full)\s*=\s*"?([^"]*)"?}) {
		    my $spec = $1 ? $1 : 'all';
		    my $part = $2;
		    my $valu = $3; $valu =~ s{\s+$}{};
		    $r{workspace}{$spec}{mode} = 'tiled' unless $r{workspace}{$spec}{mode};
		    $r{numb} = $spec+1 if $spec ne 'all' and
			(not defined $r{numb} or $spec >= $r{numb});
		    if ($part eq 'Image') {
			$r{workspace}{$spec}{pixmap} = $valu;
		    }
		    elsif ($part eq 'Color') {
			$r{workspace}{$spec}{color} = $valu;
		    }
		    elsif ($part eq 'Center') {
			$r{workspace}{$spec}{mode} = 'centered' if $valu =~ m{^1};
		    }
		    elsif ($part eq 'Scaled') {
			$r{workspace}{$spec}{mode} = 'aspect' if $valu =~ m{^1};
		    }
		    elsif ($part eq 'Full') {
			$r{workspace}{$spec}{mode} = 'fullscreen' if $valu =~ m{^1};
		    }
		}
		elsif (m{^WorkspaceNames\s*=\s*(.*)$}) {
		    my $names = $1;
		    $names =~ s{^\s*"}{};
		    $names =~ s{"\s*$}{};
		    my @names = split(/"\s*,\s*"/,$names);
		    $r{workspaces} = scalar(@names);
		    $r{workspaceNames} = \@names;
		}
	    }
	    close($fh);
	    %r = $self->correct_theme(%r);
	} else {
	    warn $!;
	}
    }
    return %r;
}

=item $xde->B<read_jwm_theme>(I<$file>) => %resources

JWM has a way of specifying backgrounds, but we don't expect to use it
because it cannot fill the background (only aspect-scales); therefore,
this function always returnes an empty set of resources.

=cut

sub read_jwm_theme {
    my ($self,$file) = @_;
    my %r = ();
    return %r;
}

=item $xde->B<read_pekwm_theme>(I<$file>) => %resources

PekWM does not have a way of specifying backgrounds; therefore, this
function always returns an empty set of resources.

=cut

sub read_pekwm_theme {
    my ($self,$file) = @_;
    my %r = ();
    return %r;
}

=item $xde->B<read_anybox_style>(I<$file>) => $stylefile

Reads the init or rc file specified by C<$file> and obtains the file
name specified against the C<session.styleFile> resource.  This works
for L<fluxbox(1)> and L<blackbox(1)> but not L<openbox(1)> any more, but
we use the B<_OB_THEME> root window property for L<openbox(1)> anyway.

=cut

sub read_anybox_style {
    my ($self,$file) = @_;
    my $style = undef;
    if (-f $file) {
	print STDERR "Reading $file\n" if $self->{ops}{verbose};
	if (open(my $fh,"<",$file)) {
	    while (<$fh>) { chomp;
		next unless m{^session.styleFile:\s+(.*)};
		$style = $1; $style =~ s{\s+$}{};
		print STDERR "Anybox style file is: $style\n"
		    if $self->{ops}{verbose};
		last;
	    }
	    close($fh);
	} else {
	    warn $!;
	}
    } else {
	print STDERR "File '$file' does not exist\n";
    }
    return $style;
}

=item $xde->B<read_icewm_style>(I<$file>) => @stylefiles

Reads the theme file in the IceWM configuration directory and obtains
the list of current and recent theme names under the C<Theme> field.

=cut

sub read_icewm_style {
    my ($self,$file) = @_;
    my @styles = ();
    if (-f $file) {
	print STDERR "Reading $file\n" if $self->{ops}{verbose};
	if (open(my $fh,"<",$file)) {
	    while (<$fh>) { chomp;
		next unless m{^[#]*Theme="([^"]*)"};
		push @styles, $1;
	    }
	    close($fh);
	} else {
	    warn $!;
	}
    } else {
	print STDERR "File '$file' does not exist\n";
    }
    return @styles;
}

=item $xde->B<read_jwm_style>(I<$file>) => $stylefiles

Reads the ~/.jwm/style file specified by C<$file> and obtains the file
name in the <Include> tag.

=cut

sub read_jwm_style {
    my ($self,$file) = @_;
    my $style = undef;
    if (-f $file) {
	if (open(my $fh,"<",$file)) {
	    while (<$fh>) { chomp;
		next unless m{<Include>([^<]*)</Include>};
		$style = $1;
		print STDERR "JWM style file is: $style\n"
		    if $self->{ops}{verbose};
		last;
	    }
	} else {
	    warn $!;
	}
    } else {
	print STDERR "File '$file' does not exist\n";
    }
    return $style;
}

=item $xde->B<read_pekwm_style>(I<$file>) => $stylefiles

Reads the config file specified by C<$file> and obtains the file name
specified against the C<Theme> resource.

=cut

sub read_pekwm_style {
    my ($self,$file) = @_;
    my $style = undef;
    if (-f $file) {
	if (open(my $fh,"<",$file)) {
	    while (<$fh>) { chomp;
		next unless m{^\s*Theme\s*=\s*"([^"]*)"};
		$style = $1;
		print STDERR "PekWM style file is: $style\n"
		    if $self->{ops}{verbose};
		last;
	    }
	} else {
	    warn $!;
	}
    } else {
	print STDERR "File '$file' does not exist\n";
    }
    return $style
}

=item $xde->B<_find_image>(I<$img>,I<\@dirs>) => $filename

Like B<find_image> below, but does not attempt to modify or interpret
C<$img>.

=cut

sub _find_image {
    my ($self,$img,$dirs) = @_;
    foreach (map{"$_/$img"}@$dirs) { return $_ if -f $_; }
    return undef;
}

=item $xde->B<find_image>(I<$img>,I<\@dirs>) => $filename

Go looking for the image.  C<$img> is the absolute or relative
pathname to the image file.  Also, the name may be missing the
extension, in which case F<.jpg>, F<.png>, F<.xpm> are searched in that
order.  C<\@dirs> are the directories to search with the first directory
being more important that subsequent directories.

The search is attempted with the full pathname, relative pathname,
basename, basename minus extension with F<.jpg>, F<.png> and F<.xpm>
added.

=cut

sub find_image {
    my ($self,$img,$dirs) = @_;
    if ($img =~ m{^/}) {
	return $img if -f $img;
	$img =~ s{.*/}{};
    }
    my $result = $self->_find_image($img,$dirs);
    return $result if $result;
    if ($img =~ s{.*/}{}) {
	$result = $self->_find_image($img,$dirs);
	return $result if $result;
    }
    return $result if $img =~ m{\.(jpg|png|xpm)$};
    $img =~ s/\.[a-z]{3,4}$//;
    foreach (qw(.jpg .png .xpm)) {
	$result = $self->_find_image("$img$_",$dirs);
	return $result if $result;
    }
    return $result;
}

sub find_images {
    my ($self,$r,$dirs) = @_;
    push @$dirs,
	 (map{"$_/images"}$self->XDG_DATA_ARRAY),
	 (map{"$_/$self->{wmname}/backgrounds"}$self->XDG_DATA_ARRAY),
	 (map{"$_/backgrounds/$self->{wmname}"}$self->XDG_DATA_ARRAY),
	 (map{"$_/pixmaps/backgrounds"}$self->XDG_DATA_ARRAY),
	 "/usr/share/fluxbox/backgrounds";
    my $missing;
    my $ws = $r->{workspace};
    foreach (sort keys %$ws) {
	my $b = $ws->{$_};
	my $img  = $b->{pixmap} or next;
	print STDERR "Looking for image '$img' for workspace '$_'\n"
	    if $self->{ops}{verbose};
	$b->{file} = $self->find_image($img,$dirs) and next;
	print STDERR "Could not find image '$img'\n";
	print STDERR "Searched:\n";
	foreach (@$dirs) {
	    print STDERR "\t'$_'\n";
	}
	$b->{missing} = 1;
	$missing = 1;
    }
    if ($missing) {
	my $n = $r->{numb};
	my $file = undef;
	foreach (0 .. $n-1) {
	    my $b = $ws->{$_};
	    next unless $b->{pixmap};
	    $b->{file} = $file unless $b->{file};
	    $file = $b->{file} if $b->{file};
	    delete $b->{missing} if $file;
	}
	foreach ($n-1 .. 0) {
	    my $b = $ws->{$_};
	    next unless $b->{pixmap};
	    $b->{file} = $file unless $b->{file};
	    $file = $b->{file} if $b->{file};
	    delete $b->{missing} if $file;
	}
	foreach (0 .. $n-1) {
	    return 0 if $ws->{$_}{missing};
	}
    }
    return 1; # successful
}

=item $xde->B<set_desktops>(I<\%r>)

Internal method to set the number of desktops and the desktop names from
the theme file. C<\%r> is a hash reference that points to a hash that
was generated by reading the theme file.  This uses NetWH/EWMH commands
to ask the window manager to change the number of desktops and their
names.  The current number of desktops is not changed until the window
manager actually changes the property in response to the client message.

Note that the window managers that actually support this (respond to the
message by changing the number of desktops) are: L<fluxbox(1)>,
L<pekwm(1)>, L<blackbox(1)>, L<openbox(1)>, L<wmaker(1)>.  The window
managers that report support but do not change the number of desktops in
response to this message are: L<jwm(1)>, L<icewm(1)>, L<fvwm(1)>.  I
don't know about L<afterstep(1)>.

=cut

sub set_desktops {
    my ($self,$r) = @_;
    my $X = $self->{X};
    my $v = $self->{ops}{verbose};
    $r->{workspaces} = scalar @{$r->{workspaceNames}}
	if $r->{workspaceNames} and not $r->{workspaces};
    # blackbox needs names first
    if (defined $r->{workspaceNames}) {
	print STDERR "Setting workspace names to ",
	      join(',',@{$r->{workspaceNames}}), "\n" if $v;
	my $data = pack('(Z*)*',@{$r->{workspaceNames}});
	$X->ChangeProperty($X->root,
		$X->atom('_NET_DESKTOP_NAMES'),
		$X->atom('UTF8_STRING'),
		8, 'Replace', $data);
	$X->flush;
    } else {
	print STDERR "There are no workspace names!\n";
    }
    if (defined $r->{workspaces}) {
	print STDERR "Setting desktop number to ", $r->{workspaces},
	      "\n" if $v;
	$X->SendEvent($X->root, 0,
		$X->pack_event_mask(qw(
			StructureNotify
			SubstructureNotify
			SubstructureRedirect)),
		$X->pack_event(
		    name=>'ClientMessage',
		    window=>$X->root,
		    format=>32,
		    type=>$X->atom('_NET_NUMBER_OF_DESKTOPS'),
		    data=>pack('LLLLL',$r->{workspaces},0,0,0,0),
		));
	$X->flush;
    } else {
	print STDERR "There are no workspaces!\n";
    }
    # we want to process the main event loop so that any responses are
    # processed before we continue.
    # Gtk2->main_iteration while Gtk2->events_pending;
}

=item $xde->B<set_images>(I<\%r>)

Internal method to set the backgrounds for each desktop from the theme
file.  C<\%r> is a hash reference that points to a hash that was
generated by reading the theme file.  This uses direct access to the X
Display to change the backgrounds.  Because this is called repeatedly,
it must handle any existing pixmap definitions before creating new ones.

Pixmaps are allocated C<RetainPermanent> so that L<hsetroot(1)> and
others do not free them.  Another background setter only affects the
current desktop (and any desktops using the same pixmap).  In case we
crash, we do not want to leak pixmap memory, so we set the pixmap
numbers against the root window resource B<_NET_DESKTOP_PIXMAPS> where
they can be freed next time we start up.

=cut

sub set_images {
    my ($self,$r) = @_;
    my $X = $self->{X};
    my $v = $self->{ops}{verbose};

    my $n = $self->{defined} = $r->{numb};
    print STDERR "There are $n images\n" if $v;
    $X->choose_screen(0);
    my $screen = $self->{screen}[0];
    my ($w,$h,$d) = (
	    $X->width_in_pixels,
	    $X->height_in_pixels,
	    $X->root_depth,
    );
    # Remove any existing pixmaps.
    $self->remove_images($screen);
    # Create the pixmaps first so that they are available when it comes
    # time to use them under Gtk2.
    my @pixmaps = ();
    my $ws = $r->{workspace};
    for (my $i=0;$i<$n;$i++) {
	my $b = $ws->{$i};
	next unless $b->{file} and not $b->{pmid};
	# need to generate a new client each time because hsetroot(1)
	# does a XKillClient on the pixmap id.
	my $T = X11::Protocol->new;
	$T->SetCloseDownMode('RetainPermanent');
	$T->choose_screen(0);
	my $pmid = $T->new_rsrc;
	$T->CreatePixmap($pmid,$T->root,$d,$w,$h);
	$T->flush;
	close($T->{connection}->fh);
	undef $T;
	$b->{pmid} = $pmid;
	push @pixmaps, $pmid;
    }
    print STDERR "There are ",scalar(@pixmaps)," pixmaps to set\n" if $v;
    print STDERR "Setting _NET_DESKTOP_PIXMAPS to ",join(', ',map{sprintf "0x%02x",$_}@pixmaps),"\n" if $v;
    $X->ChangeProperty($X->root,
	    $X->atom('_NET_DESKTOP_PIXMAPS'),
	    $X->atom('PIXMAP'),
	    32, 'Replace',
	    pack('L*',@pixmaps)) if @pixmaps;
    $X->flush;
    for (my $i=0;$i<$n;$i++) {
	my $b = $ws->{$i};
	my $file = $b->{file};
	$file = '' unless $file;
	my $mode = $b->{mode};
	$mode = 'solid' unless $file or $mode;
	$mode = 'fullscreen' unless $mode;
	my $needed = ($mode =~ m{centered|aspect|fullscreen|tiled}) ? 1 : 0;
	$file = '' unless $needed;
	if ($file) {
	    print STDERR "Using mode '$mode', file '$file'\n" if $v;
	}
	elsif ($needed) {
	    print STDERR "Could not find image\n";
	    next;
	}
	else {
	    print STDERR "Non-file-based backgrounds not yet supported\n";
	    next;
	}
	my $pixbuf;
	if ($mode eq 'fullscreen') {
	    eval { $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_scale($file,$w,$h,FALSE); }
		or print STDERR "$!\n";
	}
	elsif ($mode eq 'aspect') {
	    eval { $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_scale($file,$w,$h,TRUE); }
		or print STDERR "$!\n";
	}
	elsif ($mode eq 'centered') {
	    eval { $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_size($file,$w,$h); }
		or print STDERR "$!\n";
	}
	elsif ($mode eq 'tiled') {
	    eval { $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($file); }
		or print STDERR "$!\n";
	}
	if ($needed) {
	    if ($pixbuf) {
		$self->create_pixmap($screen,$n,$w,$h,$pixbuf,$b->{pmid},$i,$file);
	    }
	    else {
		print STDERR "could not get pixbuf for file '$file'\n";
		$needed = 0;
	    }
	}
	unless ($needed) {
	    # TODO: process non-file-based background options.
	}
    }
    $self->modulate_desktops($screen,$screen->{desktops});
}

sub watch_theme_file {
    my ($self,$label,$file) = @_;
    return 0 if $self->{$label} and $self->{$label} eq $file;
    $self->{$label} = $file;
    my $N = $self->{N};
    delete($self->{notify}{$label})->cancel
	if $self->{notify}{$label};
    $self->{notify}{$label} = $N->watch($file, IN_MODIFY, sub{
	    my $e = shift;
	    if ($self->{ops}{verbose}) {
		print STDERR "----------------------\n";
		print STDERR "$e->{w}{name} was modified\n"
		    if $e->IN_MODIFY;
		print STDERR "Rechecking theme\n";
	    }
	    $self->check_theme
    }) if $file;
    return 1;
}

=item $xde->B<get_theme_by_name>(I<$name>) => %e

Search out in XDG theme directories an XDE theme with the name,
C<$name>, and collect the sections and fields into a hash reference.
The keys of the hash reference are the sections in the file with subkeys
representing fields in the section.  An empty hash is returned when no
file of the appropriate name could be found or if the file was empty.
When successful, C<$e{file}> contains the filename read.

Because the theme name is derived from the window maanger specific style
file or directory, it is possible to symbolicly link an arbitrary style
to a window manager specific style file or directory to associate it
with an XDE theme.  In this way, different XDE themes can use the same
window manager style.

Themes consist of a C<[Theme]> section that contains definitions that
apply to all window managers.  A window-manager-specific section can be
included, (e.g. C<[fluxbox]>) that provides overrides for that window
manager.

Themefiles are named F<theme.ini> and contain the following fields in
the C<[Theme]> section.  Any fields may be overridden by a
window manager specific section (e.g. C<[fluxbox]>).

 [Theme]
 Name=Airforce
 Style=Squared-green

 WorkspaceColor=rgb:00/20/40   (or #002040 or color name)
 WorkspaceCenter=0
 WorkspaceScaled=0
 WorkspaceTiled=0
 WorkspaceFull=1
 WorkspaceImage=aviation/emeraldcoast.jpg

 Workspace0Image=aviation/emeraldcoast.jpg
 Workspace1Image=aviation/squad.jpg
 Workspace2Image=aviation/thunderbird.jpg
 Workspace3Image=aviation/overalaska.jpg

 Workspaces=4
 WorkspaceNames= 1 , 2 , 3 , 4 , 5 , 6 , 7 , 8 

 [Xsettings]
 sXde/ThemeName=Airforce
 sXde/StyleName=Squared-green
 sGtk/ColorScheme=
 sGtk/CursorThemeName=

 [fluxbox]
 Style=Squared_green

 [blackbox]
 WorkspaceNames=Workspace 1,Workspace 2,Workspace 3,\
		Workspace 4,Workspace 5,Workspace 5,\
		Workspace 7,Workspace 8

=cut

sub get_theme_by_name {
    my ($self,$name) = @_;
    my $v = $self->{ops}{verbose};
    print STDERR "Getting theme for '$name'\n" if $v;
    foreach my $d (map{"$_/themes/$name"}@{$self->{XDG_DATA_ARRAY}}) {
	print STDERR "Checking directory '$d'\n" if $v;
	next unless -d $d;
	my $f = "$d/xde/theme.ini";
	print STDERR "Checking file '$f'\n" if $v;
	next unless -f $f;
	print STDERR "Found file '$f'\n" if $v;
	open (my $fh,"<",$f) or next;
	print STDERR "Reading file '$f'\n" if $v;
	my %e = (file=>$f,theme=>$name);
	my $section;
	while (<$fh>) { chomp;
	    next if m{^\s*\#}; # comment
	    if (m{^\[([^]]*)\]}) {
		$section = $1;
		print STDERR "Starting section '$section'\n" if $v;
	    }
	    elsif ($section and m{^([^=]*)=([^[:cntrl:]]*)}) {
		$e{$section}{$1} = $2;
		print STDERR "Reading field $1=$2\n" if $v;
	    }
	}
	close($fh);
	my $short = $1 if $self->{ops}{lang} =~ m{^(..)};
	$e{Theme}{Name} = $name unless $e{Theme}{Name};
	$e{Xsettings}{'Xde/ThemeName'} = $e{Theme}{Name}
	    unless $e{Xsettings}{'Xde/ThemeName'};
	foreach my $wm (qw(fluxbox blackbox openbox icewm jwm pekwm fvwm wmaker)) {
	    foreach (keys %{$e{Theme}}) {
		$e{$wm}{$_} = $e{Theme}{$_} unless exists $e{$wm}{$_};
	    }
	}
	my %r = ();
	my $theme = 'Theme';
	$theme = $self->{wmname} if $self->{wmname};
	foreach (keys %{$e{$self->{wmname}}}) {
	    my $valu = $e{$self->{wmname}}{$_};
	    if (m{^Workspace(\d+)?(Color|Image|Center|Scaled|Tiled|Full)}) {
		my $spec = (defined $1 and $1 ne '') ? $1 : 'all';
		my $part = $2;
#		$r{workspace}{$spec}{mode} = $r{workspace}{all}{mode}
#		    unless $r{workspace}{$spec}{mode};
#		$r{workspace}{$spec}{mode} = 'tiled'
#		    unless $r{workspace}{$spec}{mode};
		$r{numb} = $spec+1 if $spec ne 'all' and
		    (not defined $r{numb} or $spec >= $r{numb});
		if ($part eq 'Image') {
		    $r{workspace}{$spec}{pixmap} = $valu;
		}
		elsif ($part eq 'Color') {
		    $r{workspace}{$spec}{color} = $valu;
		}
		elsif ($part eq 'Center') {
		    $r{workspace}{$spec}{mode} = 'centered' if $valu =~ m{yes|true|1}i;
		}
		elsif ($part eq 'Scaled') {
		    $r{workspace}{$spec}{mode} = 'aspect' if $valu =~ m{yes|true|1}i;
		}
		elsif ($part eq 'Full') {
		    $r{workspace}{$spec}{mode} = 'fullscreen' if $valu =~ m{yes|true|1}i;
		}
	    }
	    elsif ($_ eq 'Workspaces') {
		$r{workspaces} = $valu;
	    }
	    elsif ($_ eq 'WorkspaceNames') {
		my $names = $valu;
		my @names = split(/,/,$names);
		$r{workspaces} = scalar(@names) unless $r{workspaces};
		$r{workspaceNames} = \@names;
	    }
	}
	$r{workspace}{all}{mode} = 'tiled'
	    unless $r{workspace}{all}{mode};
	if ($r{numb}) {
	    for (my $i=0;$i<$r{numb};$i++) {
		$r{workspace}{$i}{mode} = $r{workspace}{all}{mode}
		    unless $r{workspace}{$i}{mode};
	    }
	}
	%r = $self->correct_theme(%r);
	return %r;
    }
    return ();
}

=item $xde->B<check_theme_FLUXBOX>() $new_theme or 0 or undef

Called to check whether L<fluxbox(1)> has changed the theme or when the
L<fluxbox(1)> window manager starts or restarts.  When L<fluxbox(1)>
changes its style, it writes the new style in the C<sessionStyle>
resource in the init file.  We might use Linux::Inotify2 to help us
here.  Note that when B<XDE_CONFIG_DIR> and B<XDE_CONFIG_FILE> are set
in the environment, it may be necessary to look in
F<$XDE_CONFIG_DIR/$XDE_CONFIG_FILE> instead of F<$HOME/.fluxbox/init>.
There is a way of using L<fluxbox-remote(1)> to get L<fluxbox(1)> to
give up its initialization file that may be more reliable.

Backgrounds are normally specified as in L<fluxbox-style(5)> as follows:

 background: centered|aspect|tiled|fullscreen|random|solid|
	     gradient <texture>|mod|none|unset
 background.pixmap: <file or directory>
 background.color: <color>
 background.colorTo: <color>
 background.modX: <integer>
 background.modY: <integer>

XDE::Setbg adds the same resources with a desktop index (starting at 0)
to the file, e.g.:

 background.desktop0: fullscreen
 background.desktop0.pixmap: tower_bluesky4.jpg
 background.desktop0.color: black
 background.desktop1: fullscreen
 background.desktop1.pixmap: tower_bluesky2.jpg

=cut

sub check_theme_FLUXBOX {
    my $self = shift;
    my $v = $self->{ops}{verbose};
    print STDERR "Checking FLUXBOX theme\n" if $v;
    my $config = "$ENV{HOME}/.fluxbox/init"; # for now
    $self->watch_theme_file(config=>$config);
    my $style = $self->read_anybox_style($config) or return;
    $style = "$style/theme.cfg" if -d $style;
    return 0 if $self->{style} and $self->{style} eq $style;
#   THEME CHANGED
    my %r;
    my $theme = $style; $theme =~ s{/theme\.cfg$}{}; $theme =~ s{.*/}{};
    %r = $self->get_theme_by_name($theme);
    %r = $self->read_anybox_theme($style) unless %r;
    return unless %r;
    $self->{style} = $style;
    my $styledir = $style; $styledir =~ s{/[^/]*$}{};
    # where to go looking for background images
    return unless $self->find_images(\%r,
	    [$styledir, "$ENV{HOME}/.fluxbox/backgrounds"]);
    $self->set_desktops(\%r);
    $self->set_images(\%r);
    return 1;
}

=item $xde->B<check_theme_BLACKBOX>() $new_theme or 0 or undef

L<blackbox(1)> is similar to L<fluxbox(1)>: it sets the theme in the
F<.blackboxrc> file when changing themes; however, L<blackbox(1)>
normally changes the background with every theme change, therefore, a
change in the background image should also trigger a recheck.

Backgrounds are normally specified as in L<blackbox(1)> as follows:

 rootCommand: bsetbg -full /usr/share/images/telecom/tower_bluesky4.jpg

Note that the bsetbg command requires a full path to the image file.

To maintain some consistency, we can change the rootCommand to a small
program to change a property setting on the default root (screen 0) of
the X Display, such as:

 rootCommand: xprop -f _BB_THEME 8s -root -set _BB_THEME Squared-blue

This will trigger XDE::Setbg to read the theme file for background
specification.  We use the same background specification as
L<fluxbox(1)>, e.g.:

 background: fullscreen
 background.pixmap: /usr/share/images/telecom/tower_bluesky4.jpg
 background.desktop0: fullscreen
 background.desktop0.pixmap: telecom/tower_bluesky4.jpg
 background.desktop1: fullscreen
 background.desktop1.pixmap: telecom/tower_bluesky2.jpg

Blackbox themes (other than ones modified as above) invariably attempt
to set the root image with L<bsetroot(1)> or L<bsetbg(1)>, which will
usually change the B<_XROOTPMAP_ID> and B<ESETROOT_PMAP_ID> properties
on the root window, so these should trigger a reread of the rc file and
style file.

=cut

sub check_theme_BLACKBOX {
    my $self = shift;
    my $config = "$ENV{HOME}/.blackboxrc"; # for now
    $self->watch_theme_file(config=>$config);
    my $style = $self->read_anybox_style($config) or return;
    return 0 if $self->{style} and $self->{style} eq $style;
#   THEME CHANGED
    my %r;
    my $theme = $style; $theme =~ s{.*/}{};
    %r = $self->get_theme_by_name($theme);
    %r = $self->read_anybox_theme($style) unless %r;
    return unless %r;
    $self->{style} = $style;
    my $styledir = $style; $styledir =~ s{/[^/]*$}{};
    # where to go looking for background images
    return unless $self->find_images(\%r,
	    [$styledir, "$ENV{HOME}/.blackbox/backgrounds"]);
    $self->set_desktops(\%r);
    $self->set_images(\%r);
    return 1;
}

=item $xde->B<check_theme_OPENBOX>() $new_theme or 0 or undef

L<openbox(1)> will change the B<_OB_THEME> property on the root window
when its theme changes: so a simple PropertyNotify on this property
should trigger the recheck.  Note that L<openbox(1)> also sets
B<_OB_CONFIG_FILE> on the root window when the configuration file
differs from the default (but not otherwise).  Note that L<openbox(1)>
also changes the C<theme> section in F<rc.xml> and writes the file, but
we don't need that.

Openbox theme files have no provisions for backgrounds whatsoever.
Therefore, we will use the same format as L<fluxbox(1)>, e.g.:

 background: fullscreen
 background.pixmap: /usr/share/images/telecom/tower_bluesky4.jpg
 background.desktop0: fullscreen
 background.desktop0.pixmap: telecom/tower_bluesky4.jpg
 background.desktop1: fullscreen
 background.desktop1.pixmap: telecom/tower_bluesky2.jpg

=cut

sub check_theme_OPENBOX {
    my $self = shift;
    $self->watch_theme_file(config=>'');
    my ($screen,$d,$root,$n) = @_;
    return unless $screen;
    my $X = $self->{X};
    my $v = $self->{ops}{verbose};
    my $atom = $X->atom('_OB_THEME');
    my $theme = undef;
    my ($val,$type) = $X->GetProperty($root,$atom,0,0,255);
    if ($type) {
	($theme) = unpack('(Z*)*',$val);
	print STDERR "Openbox theme is: $theme\n" if $v;
    } else {
	print STDERR "Could not retrieve ", $X->atom_name($atom), "\n";
    }
    return unless $theme;
    # go looking for the theme file.  openbox-3 themes are XDG compliant
    # and can be searched for in the usual fashion.
    my $style = undef;
    foreach (map {"$_/themes/$theme/openbox-3/themerc"} $self->XDG_DATA_ARRAY) {
	if (-f $_) { $style = $_; last; }
    }
    return unless $style;
    return 0 if $self->{style} and $self->{style} eq $style;
#   THEME CHANGED
    my %r;
    %r = $self->get_theme_by_name($theme);
    %r = $self->read_anybox_theme($style) unless %r;
    return unless %r;
    $self->{style} = $style;
    my $styledir = $style; $styledir =~ s{/[^/]*$}{};
    # where to go looking for background images
    return unless $self->find_images(\%r,
	    [$styledir]);
    $self->set_desktops(\%r);
    $self->set_images(\%r);
    return 1;
}

=item $xde->B<check_theme_LXDE>() $new_theme or 0 or undef

Same as L<openbox(1)>.

=cut

sub check_theme_LXDE {
    my $self = shift;
    return $self->check_theme_OPENBOX(@_);
}

=item $xde->B<check_theme_ICEWM>() $new_theme or 0 or undef

Called when the IceWM restarts.  When IceWM changes its theme, it
restarts, which results in a new _NET_SUPPORTING_WM_CHECK window, which
invokes this internal function.  IceWM changes the setting for the theme
in its ~/.icewm/theme or $ICEWM_PRIVCFG/theme file.

=cut

sub check_theme_ICEWM {
    my $self = shift;
    my $ICEWM_PRIVCFG = $ENV{ICEWM_PRIVCFG} if $ENV{ICEWM_PRIVCFG};
    $ICEWM_PRIVCFG = "$ENV{HOME}/.icewm" unless $ICEWM_PRIVCFG;
    my $config = "$ICEWM_PRIVCFG/theme";
    $self->watch_theme_file(config=>$config);
    my @themes = $self->read_icewm_style($config) or return;
    #
    # each @themes is a relative path that can be in two places:
    # @XDG_DATA_DIRS/icewm/themes or $ICEWM_PRIVCFG/themes.  User themes
    # override system themes.  When a theme cannot be found, try an
    # older theme in the list.
    #
    my ($style,$theme);
    foreach my $t (@themes) {
	foreach my $dir ($ICEWM_PRIVCFG, "$ENV{HOME}/.icewm",
		map{"$_/icewm"} $self->XDG_DATA_ARRAY) {
	    if ($self->{ops}{verbose}) {
		print STDERR "Directory: '$dir'\n";
		print STDERR "Theme: '$t'\n";
	    }
	    my $file = "$dir/themes/$t";
	    if (-f $file) {
		$theme = $t;
		$style = $file;
		last;
	    }
	}
	last if $style;
    }
    return 0 if $self->{style} and $self->{style} eq $style;
#   THEME CHANGED
    my %r;
    if ($theme) {
	$theme =~ s{/default\.theme$}{};
	$theme =~ s{\.theme$}{};
	%r = $self->get_theme_by_name($theme);
    }
    if ($style) {
	%r = $self->read_icewm_theme($style) unless %r;
    }
    return unless %r;
    $self->{style} = $style;
    my $styledir = $style; $styledir =~ s{/[^/]*$}{};
    # where to go looking for background images
    return unless $self->find_images(\%r,
	    [$styledir]);
    $self->set_desktops(\%r);
    $self->set_images(\%r);
    return 1;
}

=item $xde->B<check_theme_JWM>() $new_theme or 0 or undef

Called to check whether L<jwm(1)> has changed the theme or when the
L<jwm(1)> window manager starts and restarts.  When L<jwm(1)> changes
its style, it rewrites ~/.jwm/style to include a new file and restarts.
JWM can perform its own per-desktop background setting; however, it does
not fill the screen with the image (doesn't fully scale) leaving black
bars.  So, we do it ourselves here.

The ~/.jwm/style file looks like:

 <?xml version="1.0"?>
 <JWM>
    <Include>/usr/share/jwm/styles/Squared-blue</Include>
 </JWM>

The last component of the path is the theme name.

=cut

sub check_theme_JWM {
    my $self = shift;
    my $config = "$ENV{HOME}/.jwm/style";
    $self->watch_theme_file(config=>$config);
    my $style = $self->read_jwm_style($config) or return;
    return 0 if $self->{style} and $self->{style} eq $style;
#   THEME CHANGED
    my %r;
    my $theme = $style; $theme =~ s{.*/}{};
    %r = $self->get_theme_by_name($theme);
    %r = $self->read_jwm_theme($style) unless %r;
    return unless %r;
    $self->{style} = $style;
    my $styledir = $style; $styledir =~ s{/[^/]*$}{};
    # where to go looking for background images
    return unless $self->find_images(\%r,
	    [$styledir]);
    $self->set_desktops(\%r);
    $self->set_images(\%r);
    return 1;
}

=item $xde->B<check_theme_PEKWM>() $new_theme or 0 or undef

Called to check whether L<pekwm(1)> has changed the theme or when the
L<pekwm(1)> window manager starts and restarts.  When L<pekwm(1)>
changes its style, it places the theme directory into the
~/.pekwm/config file.  This normally has the form:

 Files {
     Theme = "/usr/share/pekwm/themes/Airforce"
 }

The last component of the path is the theme name.

=cut

sub check_theme_PEKWM {
    my $self = shift;
    my $config = "$ENV{HOME}/.pekwm/config";
    $self->watch_theme_file(config=>$config);
    my $style = $self->read_pekwm_style($config) or return;
    return 0 if $self->{style} and $self->{style} eq $style;
#   THEME CHANGED
    my %r;
    my $theme = $style; $theme =~ s{.*/}{};
    %r = $self->get_theme_by_name($theme);
    %r = $self->read_pekwm_theme($style) unless %r;
    return unless %r;
    $self->{style} = $style;
    my $styledir = $style; $styledir =~ s{/[^/]*$}{};
    # where to go looking for background images
    return unless $self->find_images(\%r,
	    [$styledir]);
    $self->set_desktops(\%r);
    $self->set_images(\%r);
    return 1;
}

=item $xde->B<check_theme>()

Used to check the theme.  This method is further specialized by window
manager.

=cut

sub check_theme {
    my $self = shift;
    print STDERR "Checking theme\n" if $self->{ops}{verbose};
    my ($screen,$d,$root,$n) = @_;
    my $wm = "\U$self->{wmname}\E" if $self->{wmname};
    return unless $wm;
    my $checker = "check_theme_$wm";
    print STDERR "Checker: $checker\n" if $self->{ops}{verbose};
    my $sub = $self->can($checker);
    my $result = &$sub($self,@_) if $sub;
    return $result;
}

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

1;

# vim: sw=4 tw=72
