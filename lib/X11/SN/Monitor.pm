package X11::SN::Monitor;
use base qw(X11::SN);
use strict;
use warnings;

=head1 NAME

X11::SN::Monitor - module supporting startup notification monitoring

=head1 SYNOPSIS

=head1 DESCRIPTION

The X11::SN::Monitor package provides implementation of monitor-specific
methods for use in startup notification monitoring.  The module provides
hooks for event loops; however, it does not provide an event loop of its
own.  See L</EVENT LOOP>.

Although this module mimics the functions of the libsn library, it does
not depend on the library and uses L<X11::Protocol(3pm)> to perform its
functions.

=head1 METHODS

The module provides the following methods:

=over

=item $monitor = X11::SN::Monitor->B<new>()

=back

=cut

1;

__END__

=head1 EVENT LOOP

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::SN(3pm)>,
L<X11::Protocol(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
