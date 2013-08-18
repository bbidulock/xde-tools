package XDE::Desktop::Icon::File;
use base qw(XDE::Desktop::Icon);
use X11::Protocol;
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Icon::File -- desktop file

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=item $file = XDE::Desktop::Icon::File->B<new>(I<$desktop>,I<$filename>,I<$x>,I<$y>)

Creates an instance of an XDE::Desktop::Icon::File object.  A file
corresponds to a normal file in the F<Desktop> directory that may be
opened with an application.  C<$desktop> is an instance of an
XDE::Desktop object, and C<$filename> is the full path and file name of
the F<.desktop> file to which the file corresponds.  C<$x> and
C<$y> are the x- and y-coordinates of the upper-left corner of the cell
on the desktop at which to render the icon and label.

This method identifies the icon and label associated with the file and
then calls XDE::Desktop::Icon->new() to create the desktop icon.  The
icon is based on the detected mime type of the file; the label is simply
the filename.

=cut

sub new {
    my ($type,$desktop,$filename) = @_;
    my $label = $filename;
    $label =~ s{^.*/}{};
    my $mime = $desktop->get_mime($filename);
    my $icons = $desktop->get_icons($mime);
    my $self = XDE::Desktop::Icon::new($type,$desktop,$icons,$label,$mime);
    $self->{filename} = $filename;
    return $self;
}

=item $file->B<open>()

This method performs the default open action associated with the
file.

=cut

sub open {
}

=item $file->B<popup>()

This method pops up a menu associated with the file.

=cut

sub popup {
    my $self = shift;
    my ($e,$X,$v) = @_;
    print STDERR "Popping up ", ref($self), " menu, time $e->{time}.\n";
    my $menu = $self->{menu};
    unless ($menu) {
	my ($item,$image,$command);
	$menu = Gtk2::Menu->new;
	$menu->signal_connect(map=>sub{
		my $menu = shift;
		my $window = $menu->get_toplevel;
		$window->set_opacity(0.92) if $window;
		return Gtk2::EVENT_PROPAGATE;
	});
#	$item = Gtk2::TearoffMenuItem->new;
#	$item->show_all;
#	$menu->append($item);

	$item = Gtk2::ImageMenuItem->new;
	$item->set_label('Open...');
	$image = Gtk2::Image->new_from_icon_name('gtk-open','menu');
	$item->set_image($image) if $image;
	$command = "xdg-open $self->{filename}";
	$item->signal_connect(activate=>sub{
		system "$command &";
	});
	$item->show_all;
	$menu->append($item);

	$item = Gtk2::SeparatorMenuItem->new;
	$item->show_all;
	$menu->append($item);

	$item = Gtk2::ImageMenuItem->new;
	$item->set_label('Properties...');
	$image = Gtk2::Image->new_from_icon_name('gtk-settings','menu');
	$item->set_image($image) if $image;
	$item->signal_connect_swapped(activate=>sub{
		my $self = shift;
		$self->props;
		return Gtk2::EVENT_PROPAGATE;
	});
	$item->show_all;
	$menu->append($item);
	$self->{menu} = $menu;
    }
    $menu->popup(undef,undef,undef,undef,$e->{detail},$e->{time});
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
