package XDE::Detect;
use base qw(XDE::Dual);
use Glib qw(TRUE FALSE);
use X11::Protocol::WMSpecific;
use strict;
use warnings;

=head1 NAME

XDE::Detect -- detect window managers

=head1 SYNOPSIS

 use XDE::Detect;

 my $wms = XDE::Detect->new();
 $wms->init;
 $wms->detect;
 $wms->main;

=head1 DESCRIPTION

Provides a module that runs out of the L<Glib::Mainloop(3pm)> that will
detect running window managers and actions performed on those window
managers.

=head1 MEHTHODS

=over

=cut

=item $wms = XDE::Detect->B<new>(I<%OVERRIDES>)

Creates an instance of an XDE::Detect object.  The XDE::Detect module
uses the L<XDE::Context(3pm)> module as a base, so the C<%OVERRIDES> are
simply passed to the L<XDE::Context(3pm)> module.

=cut

sub new {
    return XDE::Context::new(@_);
}

=item XDE::Detect->check_name(I<window>)



=back

# vim: sw=4 tw=72
