package X11::SM::Proxy;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

=head1 NAME

X11::SM::Proxy - implements session manager proxy functions for X11::Protocol

=head1 SYNOPSIS

=head1 DESCRIPTION

This module collects the methods provided by the
L<X11::SM::Manager(3pm)>. and L<X11::SM::Client(3pm)> modules and
provides convenience functions and proceudres for provide proxy or
intermediate manager services.

=head1 METHODS

The following methods are provided:

=over

=back

In addition to the methods listed above, the methods provided by the base
modules L<X11::SM::Manager(3pm)> and L<X11::SM::Client(3pm)> modules are
available as well.

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut


# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:

