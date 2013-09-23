package XDE::Glib;
use base qw(XDE::Context);
use Glib qw(TRUE FALSE);
use strict;
use warnings;

=head1 NAME

XDE::Glib -- a Glib implementation object for an XDE context

=head1 DESCRIPTION

Provides a package based on L<XDE::Context(3pm)> that provides a Glib
implementation object for the L<XDE(3pm)> context.  This package
integrates the Glib event loop into an XDE context.

=head1 METHODS

The following methods are provided:

=over

=cut

=item $xde = B<new> XDE::Glib I<%OVERRIDES> => blessed HASHREF

Obtains a new B<XDE::Glib> object.  For the use of I<%OVERRIDES> see
L<XDE::Context(3pm)>.  This package is based on the L<XDE::Context(3pm)>
package and simply calls its C<new> method with all arguments intact.

=cut

sub new {
    return XDE::Context::new(@_);
}

=back

=cut

1;

__END__

=head1 BUGS

This package does not do anything yet as we have not yet had a need to
integrate just the Glib event loop (without Gtk2).

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::Gtk2(3pm)>.

=cut

# vim: sw=4 tw=72
