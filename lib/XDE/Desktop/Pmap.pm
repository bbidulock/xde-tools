package XDE::Desktop::Pmap;
use X11::Protocol;
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Pmap -- pixmap class for desktop backgrounds

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides a private representation of a background pixmap use
to display the background on the desktop.  A problem arrises when we
assign a pixmap as a background and that pixmap goes away just before an
expose event: it generates an X11 protocol BadPixmap error.  The purpose
of this module is to keep a copy of the background pixmap and release
that copy when there are no longer any references to an instance of this
module.

=head1 ATTRIBUTES

The following attribtues are provided:

=over



=head1 METHODS

This module provides the following methods:

=over

=item B<new> XDE::Desktop::Pmap I<$pixmap> => $pmap

Creates a new XDE::Desktop::Pmap instance for the source pixmap,
I<$pixmap>.  A copy of the pixmap is created for internal use.

=cut

sub new {
    my ($type,$pmap) = @_;
    my $self = bless {pmap=>$pmap}, shift;
    my $screen = Gtk2::Gdk::Screen->get_default;
    my $root = $screen->get_root_window;
    my ($x,$y,$w,$h,$d) = $root->get_geometry;
    my $pixmap = Gtk2::Gdk::Pixmap->foreign_new_for_screen($screen,$pmap,$w,$h,$d);
    $pixmap->set_colormap($screen->get_default_colormap);
    my $mypmap = Gtk2::Gdk::Pixmap->new($root,$w,$h,$d);
    my $cr = Gtk2::Gdk::Cairo::Context->create($mypmap);
    $cr->set_source_pixmap($pixmap, 0, 0);
    $cr->paint;
    $self->{pixmap} = $mypmap;
    return $self;
}

=item $pmap->B<pixmap>() => $pixmap

Obtains the Gtk2::Gdk::Pixmap that represents our copy of the background
pixmap.

=cut

sub pixmap {
    return shift->{pixmap};
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
