package XDE::Desktop::Icon::File;
use base qw(XDE::Desktop::Icon);
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Icon::File -- desktop file

=head1 SYNOPSIS

 my $desktop = XDE::Desktop->new();
 my $filename = q{somefile};
 my ($x,$y) = (0,0);
 my $icon = XDE::Desktop::Icon::File->new($desktop,$filename,$x,$y);

=head1 DESCRIPTION

This module provides the methods and attributes unique to a regular file
(i.e. not a F<*.desktop> file) in the C<$HOME/Desktop> directory.

=head1 METHODS

The following methods are provided:

=over

=item B<new> XDE::Desktop::Icon::File I<$desktop>,I<$filename>,I<$x>,I<$y> => $icon

Creates an instance of an XDE::Desktop::Icon::File object.  A file
corresponds to a normal file in the F<Desktop> directory that may be
opened with an application.  C<$desktop> is an instance of an
L<XDE::Desktop(3pm)> object, and C<$filename> is the full path and file
name of the F<.desktop> file to which the file corresponds.  C<$x> and
C<$y> are the x- and y-coordinates of the upper-left corner of the cell
on the desktop at which to render the icon and label.

This method identifies the icon and label associated with the file and
then calls C<XDE::Desktop::Icon-E<gt>new()> to create the desktop icon.  The
icon is based on the detected mime type of the file; the label is simply
the filename.

=cut

sub new {
    my ($type,$desktop,$filename) = @_;
    return XDE::Desktop::Icon::new_from_path($type,$filename);
}

1;

=back

See L<XDE::Desktop::Icon(3pm)/METHODS> for additional inherited methods.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Desktop(3pm)>, L<XDE::Desktop::Icon(3pm)>

=cut

__END__

# vim: set sw=4 tw=72:

