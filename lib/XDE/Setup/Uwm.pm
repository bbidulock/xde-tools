package XDE::Setup::Uwm;
use base qw(XDE::Setup);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Setup::Uwm - setup an XDE session for the L<uwm(1)> window manager

=head1 SYNOPSIS

 use XDE::Setup;

 my $xde = XDE::Setup->new(%OVERRIDES,ops=>%ops);
 $xde->getenv();
 $xde->set_session('uwm') or die "Cannot use uwm";
 $xde->setenv();
 $xde->setup_session() or die "Cannot setup uwm";
 $xde->launch_session() or die "Cannot launch uwm";

=head1 DESCRIPTION

The B<XDE::Setup::Uwm> module provides the ability to seup a L<uwm(1)>
environment  for the I<X Desktop Environment>, L<XDE(3pm)>.  This module
is not normally invoked directly but is established by setting an
L<XDE::Setup(3pm)> session to C<uwm>.

=head1 METHODS

The B<XDE::Setup::Uwm> module provides specializations of the the
following L<XDE::Setup(3pm)> methods:

=over

=item $xde->B<setenv>() => undef

=cut

=item $xde->B<setup_session>() => I<$status>

=cut

=item $xde->B<launch_session>() => I<$status>

=cut

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<uwm(1)>,
L<XDE::Setup(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
