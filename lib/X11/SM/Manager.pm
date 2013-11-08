package X11::SM::Manager;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

=head1 NAME

X11::SM::Manager - implements the manager functions of the X Session Management Library

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides perl-language equivalents of the manager functions
of the X Session Management library.  An X Session Manager is an
application program that listens on ICE socket connections for
communications from clients, launches clients or subordinate managers by
setting its socket communications in a C<SESSION_MANAGER> environment
variable.  A subordinate manager may also acts as a client; however,
client functions are provided by the L<X11::SM::Client(3pm)> module.

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
