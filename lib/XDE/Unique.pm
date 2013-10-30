package XDE::Unique;
use base qw(Gtk2::Unique);
use strict;
use warnings;

=head1 NAME

XDE::Unique - XDE wrapper module for Gtk2::Unique

=head1 SYNOPSIS

my $U = XDE::Unique->new;

=head1 DESCRIPTION

XDE::Unique provides a wrapper class for integrating
L<Gtk2::Unique(3pm)> operations in an L<XDE::Context(3pm)> derived
class.

=head1 METHODS

The following methods are provided:

=over

=item $U = B<new> XDE::Unique I<@OPTIONS> => blessed HASHREF

Creates a new L<Gtk2::Unique(3pm)> object and connects it to its parent
L<XDE::Gtk2(3pm)> object.

=cut

=item $U->B<init>($xde) => $U

Initializes the XDE::Unique object.  This sets handlers and initializes
the L<Glib::Mainloop(3pm)> watchers for event-loop operation.
Initialization is not done automatically, because the owner of this
instance might want to set other things up before initializing the main
loop.

C<$xde> is typically an L<XDE::Gtk2(3pm)> derived object, but can be any
object that implements (or not) B<unique_handler> methods.  These
methods will be called during normal operation of the
L<Gtk2::Unique(3pm)> connection and when invoked by
L<Glib::Mainloop(3pm)>.

=cut

=item $U->B<term>() => $U

Terminates the XDE::Unique object.  There are a number of circular
references that are broken by this method that are necessary to allow
L<perl(1)> garbage collection to collect the object.

=cut

1;

__END__

=back

=head1 USAGE

This package is intended on being used as a base for derived packages.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>,
L<XDE::X11(3pm)>,
L<XDE::Gtk2(3pm)>,
L<Gtk2(3pm)>,
L<Gtk2::Unique(3pm)>,
L<X11::Protocol(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
