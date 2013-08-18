package XDE::Desktop::Image;
use X11::Protocol;
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Image -- image class for desktop icons

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides a single representation of an icon image used to
display the desktop icon.  Because XDE::Desktop uses the X11 protocol
RENDER extension, we only need to create one Picture for each icon image
to be displayed, regardless of the number of places that it is displayed
on the desktop.

=head1 METHODS

This module provides the following methods:

=over

=cut

=item XDE::Desktop::Image->B<new>(I<$desktop>,I<$name>)

Creates a new instance of a desktop image.  This method creates a
pixmap and pict for the image and uses Gtk2 to look up the icon by name,
create a pixbuf and render the icon to the pixmap.  The pixmap uses an
ARGB32 visual.  Also, the icon is rendered to a bitmap mask with alpha
thresholding at 1.  The bitmap uses a BITMAP visual.

=cut

sub new {
    my $self = bless {}, shift;
    return $self->reread(@_);
}

=item $image->B<reread>()

=cut

sub reread {
    my ($self,$desktop,$name) = @_;
    my $X = $self->{X} = $desktop->{X};

    $self->DESTROY;

    my @names = (ref($name) eq 'ARRAY') ? (@$name) : ($name);
    push @names, 'gtk-missing-image';
    my $pixbuf;
    my $theme = Gtk2::IconTheme->get_default;
    if (my $iconinfo = $theme->lookup_icon(\@names,48,['generic-fallback','use-builtin'])) {
	print STDERR "Using ",$iconinfo->get_filename," for ",$name,"\n";
	$pixbuf = $iconinfo->load_icon();
    }
    unless ($pixbuf) {
	foreach my $n (@names) {
	    if ($theme->has_icon($n)) {
		$pixbuf = $theme->load_icon($n,48,['generic-fallback','use-builtin']);
	    }
	    last if $pixbuf;
	}
	unless ($pixbuf) {
	    my $image = Gtk2::Image->new_from_stock('gtk-missing-image','dialog');
	    $pixbuf = $image->render_icon('gtk-missing-image','dialog');
	}
    }

    $self->{pixmap} = $X->new_rsrc;
    $X->CreatePixmap($self->{pixmap},$X->root,32,48,48);
    $X->GetGeometry($self->{pixmap});
    my $pixmap = Gtk2::Gdk::Pixmap->foreign_new($self->{pixmap});
    $pixmap->set_colormap(Gtk2::Gdk::Screen->get_default->get_rgba_colormap);
    $pixbuf->render_to_drawable_alpha($pixmap,
	    (0,0),(0,0),(48,48),'full',1,'none',0,0);

    $self->{bitmap} = $X->new_rsrc;
    $X->CreatePixmap($self->{bitmap},$X->root,1,48,48);
    $X->GetGeometry($self->{bitmap});
    my $bitmap = Gtk2::Gdk::Bitmap->foreign_new($self->{bitmap});
    $pixbuf->render_threshold_alpha($bitmap,(0,0),(0,0),(48,48),1);

    $self->{ipict} = $X->new_rsrc;
    $X->RenderCreatePicture($self->{ipict},$self->{pixmap},$desktop->{argb32});
    $X->GetGeometry($self->{pixmap});

    $self->{mpict} = $X->new_rsrc;
    $X->RenderCreatePicture($self->{mpict},$self->{bitmap},$desktop->{bitmap});
    $X->GetGeometry($self->{bitmap});

    return $self;
}

=item $image->B<DESTROY>()

=cut

sub DESTROY {
    my $self = shift;
    if (my $X = $self->{X}) {
	$X->RenderFreePicture(delete $self->{ipict}) if $self->{ipict};
	$X->FreePixmap(delete $self->{pixmap}) if $self->{pixmap};
	$X->RenderFreePicture(delete $self->{mpict}) if $self->{mpict};
	$X->FreePixmap(delete $self->{bitmap}) if $self->{bitmap};
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
