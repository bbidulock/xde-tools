package XDE::Desktop::Icon;
use X11::Protocol;
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Icon -- base class for desktop icons

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

my $ARGB32 = undef;
my $FORMAT = undef;

sub get_format {
    my $self = shift;
    unless (defined $FORMAT and defined $ARGB32) {
	my $X = $self->{X};
	my ($formats,$screens) = $X->RenderQueryPictFormats();
	for my $f (@$formats) {
	    $ARGB32 = $f->[0] if
		$f->[2] == 32 and # depth
		$f->[3] == 16 and # red bit
		$f->[5] ==  8 and # grn bit
		$f->[7] ==  0 and # blu bit
		$f->[9] == 24;    # alp bit
	}
	die "Cannot find ARGB32 format!" unless defined $ARGB32;
	printf STDERR "ARGB32 = 0x%x\n", $ARGB32;
	for my $s (@$screens) {
	    my @s = @$s;
	    shift @s; # discard fallback
	    for my $d (@s) {
		my @d = @$d;
		next unless shift(@d) == $X->root_depth;
		for my $v (@d) {
		    if ($v->[0] == $X->root_visual) {
			$FORMAT = $v->[1];
		    }
		}
	    }
	}
	die "Cannot find root visual format!" unless defined $FORMAT;
	printf STDERR "FORMAT = 0x%x\n", $FORMAT;
    }
}

=item XDE::Desktop::Icon->B<new>(I<$desktop>,I<$icon_name>,I<$label>) => $Icon

Create a new instance of an XDE::Desktop::Icon.  This base class
constructor is meant to be called only from the derived classes
L<XDE::Desktop::Icon::Shortcut(3pm)>,
L<XDE::Desktop::Icon::Directory(3pm)> and
L<XDE::Desktop::Icon::File(3pm)>.  C<$desktop> is an instance of an
L<XDE::Desktop(3pm)> providing the content for the icon, C<$icon_name>,
which is the icon name to provide, and I<$label> is the label to use for
the desktop icon.

=cut

sub new {
    my ($type,$desktop,$name,$label) = @_;
    print STDERR "-> Creating desktop icon for '$name' and '$label'\n";
    my $theme = Gtk2::IconTheme->get_default;
    my $self = bless {
	X=>$desktop->{X},
	icon=>$name,
	label=>$label,
	theme=>$theme,
    }, $type;
    $self->get_format;
    my $X = $self->{X};
    if ($theme->has_icon($name)) {
	$self->{pixbuf} = 
	    $theme->load_icon($name,48,['generic-fallback','use-builtin']);
    } else {
	my $image = Gtk2::Image->new_from_stock('gtk-missing-image','dialog');
	$self->{pixbuf} =
	    $image->render_icon('gtk-missing-image','dialog');
    }
    $self->{pixmap} = $X->new_rsrc;
    $X->CreatePixmap($self->{pixmap},$X->root,32,48,48);
    $self->{buffer} = $X->new_rsrc;
    $X->CreatePixmap($self->{buffer},$X->root,$X->root_depth,32,72,72);
    my $bpict = $self->{bpict} = $X->new_rsrc;
    printf STDERR "RenderCreatePicture(0x%x,0x%x,0x%x);\n",$bpict,$self->{buffer},$FORMAT;
    $X->RenderCreatePicture($bpict,$self->{buffer},$FORMAT);
    $X->GetGeometry($self->{pixmap});
    my $root = Gtk2::Gdk->get_default_root_window;
    $self->{mask} = Gtk2::Gdk::Pixmap->new($root,48,48,1);
    $self->{bitmap} = $self->{mask}->get_xid;
    $self->{pixbuf}->render_threshold_alpha($self->{mask},(0,0),(0,0),(48,48),1);
    $self->{image} = Gtk2::Gdk::Pixmap->foreign_new($self->{pixmap});
#   $self->{image} = Gtk2::Gdk::Pixmap->new($root,48,48,32);
    my $screen = Gtk2::Gdk::Screen->get_default;
    my $colormap = $screen->get_rgba_colormap;
    $self->{image}->set_colormap($colormap);
#   $self->{image}->draw_pixbuf(undef,$self->{pixbuf},(0,0),(0,0),(48,48),'none',0,0);
#   my $visual = $root->get_visual;
#   my $colormap = Gtk2::Gdk::Colormap->new($visual,FALSE);
#   $self->{image}->set_colormap($colormap);
    $self->{pixbuf}->render_to_drawable_alpha($self->{image},
     (0,0),(0,0),(48,48),'full',1,'none',0,0);
#    $self->{image} = $self->{pixbuf}->render_pixmap_and_mask(1);
#    $self->{pixmap} = $self->{image}->get_xid;
    print STDERR "-> PIXMAP depth = ", $self->{image}->get_depth, "\n";
    my $ipict = $self->{ipict} = $X->new_rsrc;
    printf STDERR "RenderCreatePicture(0x%x,0x%x,0x%x);\n",$ipict,$self->{pixmap},$ARGB32;
    $X->RenderCreatePicture($ipict,$self->{pixmap},$ARGB32);
#    $X->GetGeometry($self->{pixmap});
#	    clip_x_origin=>0,
#	    clip_y_origin=>0,
#	    clip_mask=>$self->{bitmap});
    return $self;
}

=item $icon->B<create>() => $xid

Create a window for the desktop icon.  Returns the XID of the window,
C<$xid>, which is also accesible as C<$icon-E<gt>{window}>.

=cut

sub create {
    my $self = shift;
    return $self->{window} if $self->{window};
    my $X = $self->{X};
    my $win = $self->{window} = $X->new_rsrc;
    printf STDERR "-> Allocated window 0x%x\n", $win;
    my $gc = $self->{gc} = $X->new_rsrc;
    printf STDERR "-> Allocated graphics context 0x%x\n", $gc;
#   my $wpict = $self->{wpict} = $X->new_rsrc;
    my $x = $self->{x} = -1;
    my $y = $self->{y} = -1;
    $X->CreateWindow($win,$X->root,'InputOutput',
	    $X->root_depth,'CopyFromParent',
	    $x,$y,72,72,2,
	    background_pixmap=>'ParentRelative',
#	    background_pixmap=>'None',
#	    background_pixel=>0,
#	    border_pixmap=>'CopyFromParent',
#	    border_pixex=>0,
#	    bit_gravity=>'Static',
#	    win_gravity=>'Static',
	    backing_store=>'Always',
#	    backing_store=>'WhenMapped',
#	    backing_store=>'NotUseful',
#	    backing_panels=>-1,
#	    backing_pixel=>0,
	    override_redirect=>1,
#	    save_under=>1,
	    save_under=>0,
	    event_mask=>$X->pack_event_mask(qw(
		    ButtonPress
		    EnterWindow LeaveWindow
		    Exposure FocusChange
	    )),
	    do_not_propagate_mask=>0,
	    colormap=>'CopyFromParent',
#	    cursor=>'None',
	);
    $X->CreateGC($gc,$win,
	    function=>'Copy',
	    clip_x_origin=>12,
	    clip_y_origin=>12,
	    clip_mask=>$self->{bitmap},
	    );
    $X->ShapeMask($win,'Boundary','Set',12,12,$self->{bitmap});
#    printf STDERR "RenderCreatePicture(0x%x,0x%x,0x%x);\n",$wpict,$win,$FORMAT;
#    $X->RenderCreatePicture($wpict,$win,$FORMAT);
#    $X->GetGeometry($win);
#   my $gtk = $self->{gtk} = Gtk2::Gdk::Window->foreign_new($win);
#   print STDERR "-> WINDOW depth = ", $gtk->get_depth, "\n";
#   #$gtk->shape_combine_mask($self->{mask},12,12);
#    $self->{cr} = Gtk2::Gdk::Cairo::Context->create($gtk);
    return $win;
}

=item $icon->B<DESTROY>()

Destroy a desktop icon.  This must destroy the X window resource.

=cut

sub DESTROY {
    my $self = shift;
#   delete $self->{gtk};
#   delete $self->{cr};
    if (my $win = delete $self->{window}) {
	my $X = delete $self->{X};
	$X->DestroyWindow($win) if $X and $win;
    }
}

=item $icon->B<update>(I<$pixmap>)

Updates the display of the icon on the screen considering the background
specified by the Gtk2::Gdk::Pixmap, C<$pixmap>.  This is because we only
support pseudo transparency, so, when the desktop background changes, we
need to update the icon.  This method has no effect unless the window is
visible.

=cut

sub update {
    my ($self,$pixmap) = @_;
    if ($self->{visible}) {
	if (0) {
	    if (0) {
		if (0) {
		    my $cr = $self->{cr};
		    if (0) {
			if ($pixmap) {
			    $cr->set_source_pixmap($pixmap,-$self->{x},-$self->{y});
			    $cr->paint;
			} else {
			    # FIXME: we should really paint the background pixel when there
			    # is no pixmap
			     #$self->{gtk}->clear_area(0,0,72,72);
			}
		    } else {
			  $$self->{gtk}->clear_area(0,0,72,72);
		    }
		    $cr->set_source_pixbuf($self->{pixbuf},12,12);
		    $cr->paint;
		    #$cr->paint_with_alpha(0.9);
		} else {
		    # we could try this too....
		    $self->{gtk}->clear_area(0,0,72,72);
		    $self->{pixbuf}->render_to_drawable_alpha($self->{gtk},
			    -12,-12,0,0,72,72,'full',1,'none',0,0);
		}
	    } else {
		# This approach uses a server-side pixmap to hold the icon
		# (and we only need one per icon type).
		my ($X,$win,$gc,$icon) = ($self->{X},$self->{window},$self->{gc},$self->{pixmap});
		$X->ClearArea($win,12,12,48,48,0);
		$$X->CopyArea($icon,$win,$gc,(0,0),(48,48),(12,12));
		$X->flush;
	    }
	} else {
	    if (0) {
		# This approach uses XRender directly.
		my $X = $self->{X};
		my $wpict = $self->{wpict};
		my $ipict = $self->{ipict};
		$X->ClearArea($self->{window},(12,12),(48,48),0);
		printf STDERR "RenderComposite('Over',0x%x,'None',0x%x,...);\n", $ipict,$wpict;
		$X->RenderComposite('Over',$ipict,'None',$wpict,(0,0),(0,0),(12,12),(48,48));
		$X->GetGeometry($self->{window});
	    } else {
		# This is a double buffered approach.
		my ($X,$win,$buffer,$gc) = ($self->{X},$self->{window},$self->{buffer},$self->{gc});
#		printf STDERR "-> CopyArea(buffer=0x%x,0x%x,0x%x,(%d,%d),(%d,%d),(%d,%d));\n",
#		    $buffer,$win,$gc,(-12,-12),(48,48),(0,0);
		$X->ClearArea($win,0,0,0,0,0);
		$X->CopyArea($buffer,$win,$gc,(0,0),(72,72),(0,0));
#		$X->GetGeometry($buffer);
	    }
	}
    }
}

sub remap {
    my ($self,$pixmap) = @_;
    my $X = $self->{X};
}

sub expose {
    my ($self,$e,$pixmap) = @_;
    my ($x,$y,$w,$h) = ($e->{x},$e->{y},$e->{width},$e->{height});
    #$self->{gtk}->clear_area($e->{x},$e->{y},$e->{width},$e->{height});
    if (0) {
	if (0) {
	    if (0) {
		#my $rect = Gtk2::Gdk::Rectangle->new($x,$y,$w,$h);
		my $cr = $self->{cr};
		#$cr->set_source_pixmap($pixmap,-$self->{x},-$self->{y});
		#$cr->paint;
		$cr->set_source_pixbuf($self->{pixbuf},12,12);
		$cr->paint;
	    } else {
		$self->{pixbuf}->render_to_drawable_alpha($self->{gtk},
			($x-12,$y-12),($x,$y),($w,$h),'full',1,'none',0,0);
	    }
	} else {
	    # This approach uses a pixmap to contain the icon and then uses
	    # a GC to copy the exposure from the pixmap to the window.
	    my ($X,$win,$icon,$gc) = ($self->{X},$self->{window},$self->{pixmap},$self->{gc});
	    #$X->ClearArea($win,$x,$y,$w,$h,0);
	    $X->CopyArea($icon,$win,$gc,($x-12,$y-12),($w,$h),($x,$y));
	    $X->flush;
	}
    } else {
	my ($X,$win,$buffer,$gc) = ($self->{X},$self->{window},$self->{buffer},$self->{gc});
#	printf STDERR "-> CopyArea(buffer=0x%x,0x%x,0x%x,(%d,%d),(%d,%d),(%d,%d));\n",
#	    $buffer,$win,$gc,($x-12,$y-12),($w,$h),($x,$y);
	$X->CopyArea($buffer,$win,$gc,($x,$y),($w,$h),($x,$y));
#	$X->GetGeometry($buffer);
    }
}

=item $icon->B<show>(I<$pixmap>)

Shows the desktop icon for this instance.  This shows the desktop icon,
but only if it is not already visible.  When the icon is shown, its
background is updated to match that specified by the Gtk2::Gdk::Pixmap,
C<$pixmap>.  This method has no effect when the desktop icon is already
visible.

=cut

sub show {
    my ($self,$pixmap) = @_;
    unless ($self->{visible}) {
	if (1) {
	    my $X = $self->{X};
	    $X->ConfigureWindow($self->{window},stack_mode=>'Below');
	    $X->MapWindow($self->{window});
#	    $X->GetGeometry($self->{window});
	} else {
	    my $gtk = $self->{gtk};
	    $gtk->show_unraised;
	    $gtk->lower;
	}
	#$self->update($pixmap);
	$self->{visible} = 1;
    }
}

=item $icon->B<hide>()

Hides the desktop icon for this instance.  This simply withdraws the
window for the desktop icon.  This method has no effect when the desktop
icon is not visible.

=cut

sub hide {
    my $self = shift;
    if ($self->{visible}) {
	if (1) {
	    my $X = $self->{X};
	    $X->UnmapWindow($self->{window});
#	    $X->GetGeometry($self->{window});
	} else {
	    my $gtk = $self->{gtk};
	    $gtk->hide;
	}
	$self->{visible} = 0;
    }
}

=item $icon->B<place>(I<$x>,I<$y>,I<$pixmap>)

Moves the desktop icon to the specified position, C<$x> and C<$y>, but
only if the icon is truly changing position.  If the position changes,
the icon updates its background from the pixmap provided, C<$pixmap>.

=cut

sub place {
    my ($self,$x,$y,$pixmap) = @_;
    if ($self->{x} != $x or $self->{y} != $y) {
	if (1) {
	    my ($X,$win,$buffer,$ipict,$bpict,$gc) =
		($self->{X},$self->{window},$self->{buffer},$self->{ipict},$self->{bpict},$self->{gc});
	    $X->ConfigureWindow($win,x=>$x,y=>$y);
#	    $X->GetGeometry($win);
#	    printf STDERR "-> CopyArea(pixmap=0x%x,0x%x,0x%x,(%d,%d),(%d,%d),(%d,%d));\n",
#		$pixmap,$buffer,$gc,($x+12,$y+12),(48,48),(0,0);
	    $X->CopyArea($pixmap,$buffer,$gc,($x+12,$y+12),(48,48),(12,12));
#	    $X->GetGeometry($buffer);
	    printf STDERR "RenderComposite('Over',0x%x,'None',0x%x,...);\n", $ipict,$bpict;
	    $X->RenderComposite('Over',$ipict,'None',$bpict,(0,0),(0,0),(12,12),(48,48));
#	    $X->GetGeometry($buffer);
	} else {
	    my $gtk = $self->{gtk};
	    $gtk->move($x,$y);
	}
	$self->{x} = $x;
	$self->{y} = $y;
	$self->update($pixmap) if $self->{visible};
    }
}

1;

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Desktop(3pm)>, L<XDE::Desktop::Icon(3pm)>

=cut

__END__

# vim: set sw=4 tw=72:
