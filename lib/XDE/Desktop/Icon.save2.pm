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
     #print STDERR "-> Creating desktop icon for '$name' and '$label'\n";
    my $theme = Gtk2::IconTheme->get_default;
    my $self = bless {
	X=>$desktop->{X},
	icon=>$name,
	label=>$label,
	theme=>$theme,
    }, $type;
    my $X = $self->{X};
    if ($theme->has_icon($name)) {
	$self->{pixbuf} = 
	    $theme->load_icon($name,48,['generic-fallback','use-builtin']);
    } else {
	my $image = Gtk2::Image->new_from_stock('gtk-missing-image','dialog');
	$self->{pixbuf} =
	    $image->render_icon('gtk-missing-image','dialog');
    }
    $self->{iconpx} = $X->new_rsrc;
    $X->CreatePixmap($self->{iconpx},$X->root,32,48,48);
    $self->{buffer} = $X->new_rsrc;
    $X->CreatePixmap($self->{buffer},$X->root,$X->root_depth,72,72);
    $self->{bpict} = $X->new_rsrc;
    $X->RenderCreatePicture($self->{bpict},$self->{buffer},$desktop->{format});
    $X->GetGeometry($self->{iconpx});
    my $root = Gtk2::Gdk->get_default_root_window;
    $self->{mask} = Gtk2::Gdk::Pixmap->new($root,48,48,1);
    $self->{bitmap} = $self->{mask}->get_xid;
    $self->{gc2} = $X->new_rsrc;
    if (0) {
	$X->CreateGC($self->{gc2},$self->{buffer},
		clip_x_origin=>12,
		clip_y_origin=>12,
		clip_mask=>$self->{bitmap});
    } else {
	$X->CreateGC($self->{gc2},$self->{buffer});
    }
    $self->{pixbuf}->render_threshold_alpha($self->{mask},(0,0),(0,0),(48,48),1);
    $self->{image} = Gtk2::Gdk::Pixmap->foreign_new($self->{iconpx});
    my $screen = Gtk2::Gdk::Screen->get_default;
    my $colormap = $screen->get_rgba_colormap;
    $self->{image}->set_colormap($colormap);
    $self->{pixbuf}->render_to_drawable_alpha($self->{image},
	    (0,0),(0,0),(48,48),'full',1,'none',0,0);
    $self->{ipict} = $X->new_rsrc;
    $X->RenderCreatePicture($self->{ipict},$self->{iconpx},$desktop->{argb32});
    $X->GetGeometry($self->{iconpx});
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
    $self->{x} = -1;
    $self->{y} = -1;
    $self->{window} = $X->new_rsrc;
    my $visual;
    my %visuals = (%{$X->visuals});
    foreach my $v (keys %visuals) {
	next unless $visuals{$v}{depth} == 32;
	printf STDERR "Using visual 0x%x\n", $v;
	$visual = $v if $visuals{$v}{depth} == 32;
	last;
    }
    $X->CreateWindow($self->{window},$X->root,'InputOutput',
	    0,'CopyFromParent',
	    $self->{x},$self->{y},72,72,0,
	    background_pixmap=>'ParentRelative',
	    backing_store=>'Always',
	    override_redirect=>1,
	    save_under=>1,
	    event_mask=>$X->pack_event_mask(qw(
		    Exposure
	    )),
	    do_not_propagate_mask=>0,
	    colormap=>'CopyFromParent',
	);
    $X->GetScreenSaver;
    $self->{gc} = $X->new_rsrc;
    if (0) {
	$X->CreateGC($self->{gc},$self->{window},
		clip_x_origin=>12,
		clip_y_origin=>12,
		clip_mask=>$self->{bitmap});
    } else {
	$X->CreateGC($self->{gc},$self->{window});
    }
    $X->ShapeMask($self->{window},'Boundary','Set',12,12,$self->{bitmap});
    return $self->{window};
}

=item $icon->B<DESTROY>()

Destroy a desktop icon.  This must destroy the X window resource.

=cut

sub DESTROY {
    my $self = shift;
    if (my $X = delete $self->{X}) {
	$X->DestroyWindow(delete $self->{window}) if $self->{window};
	$X->FreeGC(delete $self->{gc}) if $self->{gc};
	$X->FreeGC(delete $self->{gc2}) if $self->{gc2};
	$X->FreePixmap(delete $self->{iconpx}) if $self->{iconpx};
	$X->FreePixmap(delete $self->{buffer}) if $self->{buffer};
	$X->RenderFreePicture(delete $self->{bpict}) if $self->{bpict};
	$X->RenderFreePicture(delete $self->{ipict}) if $self->{ipict};
	$X->flush;
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
    my $X = $self->{X};
    $X->ClearArea($self->{window},0,0,0,0,0);
    $X->CopyArea($pixmap,$self->{buffer},$self->{gc2},($self->{x},$self->{y}),(72,72),(0,0));
    $X->RenderComposite('Over',$self->{ipict},'None',$self->{bpict},(0,0),(0,0),(12,12),(48,48));
    $X->CopyArea(
	    $self->{buffer},
	    $self->{window},
	    $self->{gc},
	    (0,0),(72,72),
	    (0,0));
    $X->flush;
}

sub remap {
    my ($self,$pixmap) = @_;
    my $X = $self->{X};
}

sub expose {
    my ($self,$e,$pixmap) = @_;
    my $X = $self->{X};
    $X->ClearArea($self->{window},
	    $e->{x},$e->{y},
	    $e->{width},$e->{height},0);
    $X->CopyArea(
	    $self->{buffer},
	    $self->{window},
	    $self->{gc},
	    ($e->{x},$e->{y}),($e->{width},$e->{height}),
	    ($e->{x},$e->{y}));
    $X->flush;
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
    my $X = $self->{X};
    $X->ConfigureWindow($self->{window},stack_mode=>'Below');
    $X->MapWindow($self->{window});
    $X->flush;
    $self->{visible} = 1;
}

=item $icon->B<hide>()

Hides the desktop icon for this instance.  This simply withdraws the
window for the desktop icon.  This method has no effect when the desktop
icon is not visible.

=cut

sub hide {
    my $self = shift;
    my $X = $self->{X};
    $X->UnmapWindow($self->{window});
    $X->flush;
    $self->{visible} = 0;
}

=item $icon->B<place>(I<$x>,I<$y>,I<$pixmap>)

Moves the desktop icon to the specified position, C<$x> and C<$y>, but
only if the icon is truly changing position.  If the position changes,
the icon updates its background from the pixmap provided, C<$pixmap>.

=cut

sub place {
    my ($self,$x,$y,$pixmap) = @_;
    my $X = $self->{X};
    $X->ConfigureWindow($self->{window},x=>$x,y=>$y);
    $X->CopyArea($pixmap,$self->{buffer},$self->{gc2},($x,$y),(72,72),(0,0));
    $X->RenderComposite('Over',$self->{ipict},'None',$self->{bpict},(0,0),(0,0),(12,12),(48,48));
    $X->flush;
    $self->{x} = $x;
    $self->{y} = $y;
    $self->update($pixmap);
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
