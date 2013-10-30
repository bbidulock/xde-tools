package XDE::Monitor;
use base qw(XDE::Dual  XDE::X11::StartupNotification);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Monitor -- monitor startup notification of XDG applications

=head1 SYNOPSIS

 use XDE::Monitor;

 my $xde = XDE::Monitor->new(%OVERRIDES,ops=>\%ops);

 $xde->getenv;
 $xde->init;
 $SIG{TERM} = sub{$xde->main_quit};
 $SIG{INT}  = sub{$xde->main_quit};
 $SIG{QUIT} = sub{$xde->main_quit};
 $xde->main;
 $xde->term;
 exit(0);

=head1 DESCRIPTION

Provides a module that runs out of the L<Glib::Mainloop(3pm)> that will
monitor the launching of XDG applications (desktop entries) using
startup notification and will assist light-weight window managers with
proper handling of XDG startup notification.

=head1 METHODS

The following methods are provided:

=over

=item $xde = XDE::Monitor->B<new>(I<%OVERRIDES>,ops=>\I<%ops>)

=item $xde->B<_init>() => $xde

=item $xde->B<_term>() => $xde

=cut

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>,
L<XDE::Dual(3pm)>,
L<XDE::X11(3pm)>,
L<XDE::X11::StartupNotification>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
