package XDE::Setbg;
use base qw(XDE::Gtk2);
use Glib qw(TRUE FALSE);
use Gtk2;
use XDE::X11;
use strict;
use warnings;

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

=item $xde = XDE::Setbg->B<new>(I<%OVERRIDES>)

=cut

sub new {
    return XDE::Context::new(@_);
}

sub setup {
    my $self = shift;
    $self->SUPER::setup(@_);
    $self->getenv();
    return $self;
}

sub init {
    my $self = shift;
    $self->SUPER::init();
    my $X = $self->{X} = XDE::X11->new();
    my %ops = %{$self->{ops}};
    $X->init($self);
    $X->SetCloseDownMode('RetainTemporary');
    my $emask = $X->pack_event_mask('PropertyChange');
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
	    if $ops{verbose};
	($val,$type) = $X->GetProperty($root,
		$X->atom('_NET_CURRENT_DESKTOP'),
		$X->atom('CARDINAL'), 0, 1);
	$screen->{current} = $type ?  unpack('L',substr($val,0,4)) : 0;
	printf STDERR "Current desktop is %d\n", $screen->{current}
	    if $ops{verbose};
	my $d = $screen->{current};
	($val,$type) = $X->GetProperty($root,
		$X->atom('_XROOTPMAP_ID'),
		$X->atom('PIXMAP'), 0, 1);
	my $pmid = $type ?  unpack('L',substr($val,0,4)) : 0;
	printf STDERR "Existing pixmap id is 0x%08x\n", $pmid
	    if $ops{verbose};
	for (my $i=0;$i<$screen->{desktops};$i++) {
	    $screen->{pmids}[$i] = \$pmid;
	}
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
}

sub set_pixmap {
    my ($self,$screen,$pmid) = @_;
    my $X = $self->{X};
    my %ops = %{$self->{ops}};
    printf STDERR "setting root window 0x%08x to pixmap 0x%08x\n",
	   $screen->{root}, $pmid if $ops{verbose};
    $X->GrabServer   if $self->{ops}{grab};
    $X->ChangeWindowAttributes($screen->{root},
	    background_pixmap=>$pmid);
    my $data = pack('L',$pmid);
    foreach (qw(_XROOTPMAP_ID ESETROOT_PMAP_ID _XSETROOT_ID
		_XROOTMAP_ID)) {
	$X->ChangeProperty($screen->{root}, $X->atom($_),
		$X->atom('PIXMAP'), 32, 'Replace', $data);
    }
    $X->flush;
    $X->UngrabServer if $self->{ops}{grab};
}

sub set_backgrounds {
    my ($self,@files) = @_;
    my $X = $self->{X};
    my %ops = %{$self->{ops}};

    my $n = $self->{defined} = scalar(@files);
    return unless $n;
    $X->_queue_events;
    print STDERR "There are $n files\n" if $ops{verbose};
    my $screens = scalar @{$X->{screens}};
    print STDERR "There are $screens screens\n" if $ops{verbose};
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
	print STDERR "using file '$file'\n" if $ops{verbose};
	my $pixbuf;
	if ($mode eq 'fill') {
	    eval {
		$pixbuf =
		    Gtk2::Gdk::Pixbuf->new_from_file_at_scale($file,$w,$h,FALSE);
	    };
	}
	elsif ($mode eq 'full') {
	    eval {
		$pixbuf =
		    Gtk2::Gdk::Pixbuf->new_from_file_at_size($file,$w,$h,FALSE);
	    };
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
	    if $ops{verbose};
	my $display = Gtk2::Gdk::Display->get_default;
	 #my $gtkscrn = $display->get_screen(0);
	 #my $gtkroot = $gtkscrn->get_root_window;
	 #my $pixmap = Gtk2::Gdk::Pixmap->lookup($pmid);
	my $pixmap = Gtk2::Gdk::Pixmap->foreign_new($pmid);
	 #my $pixmap = Gtk2::Gdk::Pixmap->foreign_new_for_screen($gtkscrn, $pmid, $w, $h, $d);
	 #my $pixmap = Gtk2::Gdk::Pixmap->new($gtkroot,$w,$h,$d);
	printf STDERR "Drawing to pixmap id 0x%08x\n", $pmid
	    if $ops{verbose};
	$pixmap->draw_pixbuf(undef,$pixbuf,$x_src,$y_src,$x_dst,$y_dst,$w_box,$h_box,'none',0,0);
	$display->flush;
	$display->sync;
	$screen->{pmids}[$i] = \$pmid;
	if ($i == $screen->{current}) {
	    $self->set_pixmap($screen,$pmid);
	}
    }
    my $k = $screen->{desktops};
    if ($k > $n) {
	# modulate the backgrounds over the available desktops
	for (my $i=0;$i<$k;$i++) {
	    next unless $i >= $n;
	    my $j = $i % $n;
	    $screen->{pmids}[$i] = $screen->{pmids}[$j];
	    if ($i == $screen->{current}) {
		$self->set_pixmap($screen,${$screen->{pmids}[$i]});
	    }
	}
    }
    $self->{ignore_xrootpmap_id_change} = 1;
    $X->_process_queue;
    delete $self->{ignore_xrootpmap_id_change};
}

=item $xde->B<changed_XROOTPMAP_ID>(I<$screen>,I<$event>)

=cut

sub changed_XROOTPMAP_ID {
    my ($self,$screen,$e) = @_;
    return if $self->{ignore_xrootpmap_id_change};
    my $X = $self->{X};
    my $d = $screen->{current};
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

=cut

sub changed_NET_CURRENT_DESKTOP {
    my ($self,$screen,$e) = @_;
    my $X = $self->{X};
    my %ops = %{$self->{ops}};
    my ($val,$type) = $X->GetProperty($e->{window}, $e->{atom},
	    $X->atom('CARDINAL'), 0, 1);
    my $current = $type ? unpack('L',substr($val,0,4)) : 0;
    my $d = $screen->{current};
    printf STDERR "new desktop %d (was %d)\n", $current, $d
	if $ops{verbose};
    if ($current != $d) {
	my $oldid = ${$screen->{pmids}[$d]};
	my $newid = ${$screen->{pmids}[$current]};
	printf STDERR "new pixmap 0x%08x (was 0x%08x)\n", $newid, $oldid
	    if $ops{verbose};
	if ($newid != $oldid) {
	    # need to change pixmap on root
	    $self->set_pixmap($screen,$newid);
	}
    }
}

=item $xde->B<changed_NET_NUMBER_OF_DESKTOPS>(I<$screen>,I<$event>)

=cut

sub changed_NET_NUMBER_OF_DESKTOPS {
    my ($self,$screen,$e) = @_;
    my $X = $self->{X};
    my ($val,$type) = $X->GetProperty($e->{window}, $e->{atom},
	    $X->atom('CARDINAL'), 0, 1);
    my $desktops = $type ? unpack('L',substr($val,0,4)) : 1;
    my $n = $screen->{desktops};
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

=item $xde->B<_handle_event>(I<$event>)

Internal event handler for the XDE::Setbg module.  This is an
L<X11::Protocol(3pm)> handler that is invoked either by direct requests
made of the X11::Protocol object ($self->{X}) or by Glib::Mainloop when
it triggers an input watcher on the X11::Protocol::Connection.
C<$event> is the unpacked X11::Protocol event.

=cut

sub _handle_event {
    my ($self,%e) = @_;
    my $X = $self->{X};
    my %ops = %{$self->{ops}};
    print STDERR "Received event: ", join(',',%e), "\n"
	if $ops{verbose};
    return unless $e{name} eq 'PropertyNotify';
    print STDERR "atom: ",$X->atom_name($e{atom}),"\n" if $ops{verbose};
    return unless exists $self->{roots}{$e{window}};
    my $n = $self->{roots}{$e{window}};
    my $screen = $self->{screen}[$n] or return;
    return unless $e{window} == $X->{screens}[$n]{root};
    my $action = "changed".$X->atom_name($e{atom});
    print STDERR "Action is: '$action'\n" if $ops{verbose};
    return $self->$action($screen,\%e) if $self->can($action);
    return;
}

sub _handle_error {
    my ($self,$X,$e) = @_;
    print STDERR "Received error: \n",
	  $X->format_error_msg($e), "\n";
}

=back

=cut

1;

# vim: sw=4 tw=72
