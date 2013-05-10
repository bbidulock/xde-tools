package XDE::Glib;
use base qw(XDE::Context);
use Glib qw(TRUE FALSE);
use strict;
use warnings;

=head1 NAME

XDE::Glib -- a Glib implementation object for an XDE context

=head1 METHODS

=over

=cut

=item $xde = XDE::Glib->new(%OVERRIDES) => blessed HASHREF

Obtains a new B<XDE::Gtk2> object.  For the use of I<%OVERRIDES> see
L<XDE::Context(3pm)>.

=cut

sub new {
    return XDE::Context::new(@_);
}

=back

=cut

1;

# vim: sw=4 tw=72
