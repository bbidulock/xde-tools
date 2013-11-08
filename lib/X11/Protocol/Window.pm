package X11::Protocol::Window;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

=head1 NAME

X11::Protocol::Window - representation of X11 window

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides an object-oriented perl representation of an X11
window.  THis is used primarily to track the creation, reparenting,
withdrawal, docking, startup notificaiton, session management proxy and
other assistance for light-weight window managers.

=head1 METHODS

The following methods are provided:

=over

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut


# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
