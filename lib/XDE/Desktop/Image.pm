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
display the desktop icon.  This is the icon image itself, without the
label underneath and with no corresponding widget.  It is associated
directly with an X-server pixmap.  Because L<XDE::Desktop(3pm)> uses
L<Gtk2::Gdk::Pixbuf(3pm)> objects to render each icon image to be
displayed, we only need to create one C<Pixbuf> for each icon image to
be displayed, regardless of the number of places that it is displayed on
the desktop.  This minimizes the use of pixmap resources in the
X-server.

=head1 ATTRIBUTES

The following attributes are provided:

=over

=item B<%XDE::Desktop::Image::IMAGES>

Provides a cache of images by mapping the C<$id> of the image to the
image object using a global hash, C<%IMAGES>.

=cut

my %IMAGES;

=back

=head1 METHODS

This module provides the following methods:

=over

=cut

=item B<new> XDE::Desktop::Image I<$desktop>,I<$name>,I<$mime>,I<$id> => $image

Creates a new instance of a desktop image.  This method creates a pixbuf
for the image using Gtk2 to look up the icon by name and create the
pixbuf.  C<$name> is the name of the icon to look up; C<$mime>, the mime
type associated with the icon; and C<$id> is the identifier of the icon
to use as an index to place the resulting image into a cache.  If an
image with the identifier, C<$id>, exists in the cache at the time of
call, it is simply returned and no new image is constructed.

=cut

sub new {
    my ($type,$desktop,$name,$mime,$id) = @_;
    return $IMAGES{$id} if $id and $IMAGES{$id};
    my $self = bless {}, shift;
    $IMAGES{$id} = $self if $id;
    return $self->reread($desktop,$name,$mime);
}

=item $image->B<reread>(I<$desktop>,I<$name>,I<$mime>) => $image

Rereads an instance of a desktop image.  This method updates the pixbuf
for the image using Gtk2 to look up the icon by name and create the
pixbuf.  This must be done when the icon style changes.  Note that
C<$mime>, when defined, is the mime type (also used as an identifier).
When defined we determine which applications can be used to open this
type of file.

This method is meant to be called from derived packages using
L<XDE::Desktop::Icon(3pm)> as a base.

=cut

sub reread {
    my ($self,$desktop,$name,$mime) = @_;
    if ($mime) {
	print STDERR "New class for mime: $mime\n";
    }
    my $X = $self->{X} = $desktop->{X};

    my @names = (ref($name) eq 'ARRAY') ? (@$name) : ($name);
    push @names, 'gtk-file';
    my $pixbuf;
    my $theme = Gtk2::IconTheme->get_default;
    foreach my $n (@names) {
	if ($theme->has_icon($n)) {
	    $pixbuf = $theme->load_icon($n,48,['generic-fallback','use-builtin']);
	}
	last if $pixbuf;
    }
    $self->{pixbuf} = $pixbuf;
    if ($mime) {
	if ($desktop->{mime_apps}{$mime}) {
	    $self->{apps} = [ sort {$a->{Name} cmp $b->{Name}} @{$desktop->{mime_apps}{$mime}} ];
	    if ($desktop->{mime_subclasses}{$mime}) {
		my @subs = ();
		foreach my $type (@{$desktop->{mime_subclasses}{$mime}}) {
		    if ($desktop->{mime_apps}{$type}) {
			push @subs, @{$desktop->{mime_apps}{$type}};
		    }
		}
		$self->{subs} = [ sort {$a->{Name}cmp$b->{Name}} @subs ];
	    }
	}
    }
    return $self;
}

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Desktop(3pm)>, L<XDE::Desktop::Icon(3pm)>

=cut

# vim: set sw=4 tw=72:
