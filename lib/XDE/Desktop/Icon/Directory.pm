package XDE::Desktop::Icon::Directory;
use base qw(XDE::Desktop::Icon);
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Icon::Directory -- desktop directory

=head1 SYNOPSIS

 my $dtop = XDE::Desktop->new(\%OVERRIDES);
 my $icon = XDE::Desktop::Icon::Directory->new($desktop,$path);

=head1 DESCRIPTION

A desktop icon object for a directory.  Directories are represented by
folder icons and have a label of the same name as the subdirectory.  The
action associated with desktop icon directories is opening the directory
using a file manager.

Note that this is an implementation class that is not expected to be
used directly, but is to be called from XDE::Desktop.

=head1 METHODS

This module provides the following methods:

=over

=item $directory = XDE::Desktop::Icon::Directory->B<new>(I<$desktop>,I<$directory>)

Creates an instance of an XDE::Desktop::Icon::Directory object.  A
directory corresponds to a normal directory under the F<Desktop>
directory that may be opened with a file manager.  C<$desktop> is an
instance of an XDE::Desktop object, and C<$directory> is the full path
to the subdirectory.

This method identifies the icon (full path) and label associated with
the directory.  The icon is the directory icon under the icon theme; the
label is simply the directory name.

=cut

sub new {
    my ($type,$desktop,$directory) = @_;
    my $label = $directory;
    $label =~ s{^.*/}{};
    my $mime = $desktop->get_mime($directory);
    my $icons = $desktop->get_icons($mime);
    push @$icons, 'folder';
    my $self = XDE::Desktop::Icon::new($type,$desktop,$icons,$label,$mime);
    $self->{directory} = $directory;
    return $self;
}

=item $directory->B<open>()

This method performs the default open action associated with the
directory.

=cut

sub open {
}

=item $directory->B<popup>(I<$event>)

This method pops up a menu associated with the directory.

=cut

sub popup {
    my $self = shift;
    my ($e,$X,$v) = @_;
    print STDERR "Popping up ", ref($self), " menu, time $e->{time}.\n";
    my $menu = $self->{menu};
    unless ($menu) {
	$menu = Gtk2::Menu->new;
	$menu->signal_connect(map=>sub{
		my $menu = shift;
		my $window = $menu->get_toplevel;
		$window->set_opacity(0.92) if $window;
		return Gtk2::EVENT_PROPAGATE;
	});
	my $item = Gtk2::TearoffMenuItem->new;
	$item->show_all;
	$menu->append($item);

	$item = Gtk2::ImageMenuItem->new;
	$item->set_label('Open');
	my $image = Gtk2::Image->new_from_icon_name('folder','menu');
	$item->set_image($image) if $image;
	my $command = "pcmanfm $self->{directory}";
	$item->signal_connect(activate=>sub{
		system "$command &";
	});
	$item->show_all;
	$menu->append($item);

	$item = Gtk2::SeparatorMenuItem->new;
	$item->show_all;
	$menu->append($item);
	$menu->visible(Glib::TRUE);
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
