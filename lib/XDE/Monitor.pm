package XDE::Monitor;
use X11::SN::Monitor;
use X11::SN::Sequence;
use strict;
use warnings;

=head1 NAME

XDE::Monitor -- monitor startup notification of XDG applications

=head1 SYNOPSIS

 use XDE::Monitor;

 my $xde = XDE::Monitor->new(%OVERRIDES,ops=>\%ops);

 $xde->getenv;
 $xde->init;
 $xde->main;
 $xde->monitor;
 exit(0);

=head1 DESCRIPTION

Provides the capabilities of an XDG application startup notification
monitor.  It provides facilities for monitoring the launch of XDG
applicaitons (desktop entries) using startup notificaiton and will
assist light-weight window managers with proper handling of XDG startup
notification.  This module is used by, for example, L<xdg-monitor(1p)>.

=head1 METHODS

The following methods are provided:

=over

=item $xde = XDE::Monitor->B<new>(I<%OVERRIDES>,ops=>\I<%ops>)

=item $xde->B<_init>() => $xde

=item $xde->B<_term>() => $xde

=back

=head1 BEHAVIOR

There are several problems with the XDG compliant startup notification:

=over

=item 1.

An XDG desktop entry does not necessary have the correct settings of the
B<StartupNotify> or B<StartupWMClass> fields (or both).  This can cause
a laucher to populate incorrect values in the C<new> message.

=item 2.

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::SN(3pm)>,
L<X11::SN::Monitor(3pm)>,
L<X11::SN::Sequence(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
