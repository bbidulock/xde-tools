package XDE::X11::StartupNotification::Monitor;
use base qw(XDE::X11::StartupNotification);
use strict;
use warnings;

=head1 NAME

XDE::X11::StartupNotification::Monitor - startup notification monitor module

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides methods supporting X11 startup notification that
are used by a I<monitor> (a program monitoring the launching of X11
client programs).

=head1 METHODS

The module provides the following methods:

=over

=item B<new> XDE::X11::StartupNotification::Monitor I<$callback>, I<$data> => $ctx

=cut

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::X11::StartupNotification(3pm)>,
L<XDE::X11(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
