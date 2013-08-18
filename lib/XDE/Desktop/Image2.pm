package XDE::Desktop::Image2;
use X11::Protocol;
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Image2 -- image class for desktop icons (take 2)

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides a single representation of an icon image used to
display the desktop icon.  Because XDE::Desktop2 uses Gtk2::Gdk::Pixbuf
objects to render each icon image to be displayed, we only need to
create one Pixbuf for each icon image to be displayed, regardless of the
number of places that it is displayed on the diestkop.

=head1 METHODS

This module provides the following methods:

=over

=cut

=item XDE::Desktop::Image2->B<new>(I<$desktop>,I<$name>,I<$mime>,I<$id>)

Creates a new instance of a desktop image.  This method creates a pixbuf
for the image using Gtk2 to look up the icon by name and create the
pixbuf.

=cut

my %IMAGES;

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

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Desktop(3pm)>, L<XDE::Desktop::Icon(3pm)>

=cut

__END__

# vim: set sw=4 tw=72:
