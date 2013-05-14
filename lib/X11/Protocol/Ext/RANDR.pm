
# The X Rotate and Resolution Extension Protocol
package X11::Protocol::Ext::RANDR;

use X11::Protocol qw(pad padding make_num_hash);
use Carp;
use strict;
use warnings;
use vars '$VERSION';

$VERSION = 0.01;

=head1 NAME

X11::Protocol::Ext::RANDR -- Perl extension module for the X Resize, Rotate and Reflect Extension

=head1 SYNOPSIS

 use X11::Protocol;
 $x = X11::Protocol->new($ENV{'DISPLAY'});
 $x->init_extension('RANDR') or die;

=head1 DESCRIPTION

This moudle is used by the L<X11::Protocol(3pm)> module to participate
in the resize, rotate and reflect extension to the X protocol, allowing
a client to participate or control these screen changes per L<The X
Resize, Rotate and Reflect Extension>, a copy of which can be obtained
from L<http://www.x.org/releases/X11R7.7/doc/randrproto/randrproto.txt>.

This manual page does not attempt to document the protocol itself, see
the specification for that.  It documents the L</CONSTANTS>,
L</REQUESTS>, L</EVENTS> and L</ERRORS> that are added to the
L<X11::Protocol(3pm)> module.

=cut

sub new
{
    my $self = bless {}, shift;
    my ($x, $request_base, $event_base, $error_base) = @_;

=head1 CONSTANTS

B<X11::Protocol::Ext::RANDR> provides the following symbolic constants:

 Rotation =>
     [ qw(Rotate_0 Rotate_90 Rotate_180 Rotate_270
          Reflect_X Refect_Y) ]

 RrSelectMask =>
     [ qw(ScreenChangeNotifyMask CrtcChangeNotifyMask
          OutputChangeNotifyMask OutputPropertyNotifyMask) ]

 RrConfigStatus =>
     [ qw(Success InvalidConfigTime InvalidTime Failed) ]

 ModeFlag =>
     [ qw(HSyncPositive HSyncNegative VSyncPositive VSyncNegative
          Interlace DoubleScan CSync CSyncPositive CSyncNegative
          HSkewPercent BCast PixelMultiplex
          DoubleClock ClockDividedBy2) ]

 Connection =>
    [ qw(Connected Disconnected UnknownConnection) ]

=cut
    $x->{ext_const}{Rotation} =
	[ qw(Rotate_0 Rotate_90 Rotate_180 Rotate_270 Reflect_X
	     Refect_Y) ]
    $x->{ext_const}{RrSelectMask} =
	 [ qw(ScreenChangeNotifyMask CrtcChangeNotifyMask
	      OutputChangeNotifyMask OutputPropertyNotifyMask) ];
    $x->{ext_const}{RrConfigStatus} =
	 [ qw(Success InvalidConfigTime InvalidTime Failed) ];
    $x->{ext_const}{ModeFlag} =
	 [ qw(HSyncPositive HSyncNegative VSyncPositive VSyncNegative
	      Interlace DoubleScan CSync CSyncPositive CSyncNegative
	      HSkewPercent BCast PixelMultiplex
	      DoubleClock ClockDividedBy2) ];
    $x->{ext_const}{Connection} =
	[ qw(Connected Disconnected UnknownConnection) ];

    $x->{ext_const_num}{$_} = {make_num_hash($x->{ext_const}{$_})}
	foreach (qw(Rotation RrSelectMask RrConfigStatus ModeFlag
	            Connection));

=head1 ERRORS

B<X11::Protocol::Ext::RANDR> provides the folowing bad resource errors:
C<Output>, C<Crtc>, C<Mode>.

=cut
    {
	my $i = $error_base;
	foreach (qw(Output Crtc Mode)) {
	    $x->{ext_const}{Error}[$i] = $_;
	    $x->{ext_const_num}{Error}{$_} = $i;
	    $x->{ext_error_type}[$i] = 1; # bad resource
	}
    }

=head1 REQUESTS

B<X11::Protocol::Ext::RANDR> provides the following requests:

=cut
    $x->{ext_request}{$request_base} =
    [
    ];
}

=head1 EVENTS

B<X11::Protocol::Ext::RANDR> provides the following events:

 RRCrtcChangeNotify => {
     timestamp=>$timestamp,
     request_window=>$window,
     crtc_affected=>$crtc,
     mode_in_use=>$mode,  # Mode
     new_rotation_and_reflection=>$rotation, # Rotation
     x=>$x,
     y=>$y,
     width=>$width,
     height=>$height}

=cut
    $x->{ext_const}{Events}[$event_base+0] = q(RRCrtcChangeNotify);
    $x->{ext_events}[$event_base+0] = ['xxxxLLLLSxxSSSS',
	[timestamp => ['CurrentTime']], 'request_window',
	'crtc_affected', [mode => ['None']],
	[new_rotation_and_reflection => 'Rotation'],
	'x', 'y', 'width', 'height'];
=pod
 
 RROutputChangeNotify => {
     timestamp=>$time,
     configuration_timestamp=>$config_time,
     request_window=>$window,
     output_affected=>$output,
     crtc_in_use=>$crtc,
     mode_in_use=>$mode,
     rotation_in_use=>$rotation, # Rotation
     connection_status=>$status, # Connection
     subpixel_order=>$subpixel_order}

=cut
    $x->{ext_const}{Events}[$event_base+1] = q(RROutputChangeNotify);
    $x->{ext_events}[$event_base+1] = ['xxxxLLLLLLSCC',
	[timestamp=>['CurrentTime']],
	[configuration_timestamp=>['CurrentTime']],
	[request_window=>['None']],
	'output_affected', 'crtc_in_use', [mode => ['None']],
	[rotation_in_use=>'Rotation'],

=pod

 RROutputPropertyNotify => {
     window=>$window,
     output=>$output,
     atom=>$atom,
     timestamp=>$time}

=cut

    $x->{ext_const}{Events}[$event_base+1] = q(RROutputPropertyNotify);

1;

__END__

=head1 BUGS

Probably lots: this module has not been thoroughly tested.  At least it
loads and initializes on server supporting the correct version.

=head1 AUTHOR

Brian Bidulock <bidulock@openss7.org>

=head1 SEE ALSO

L<perl(1)>,
L<X11::Protocol(3pm)>,
L<X Synchronization Extension Protocol|http://www.x.org/releases/X11R7.7/doc/xextproto/sync.pdf>.

=cut

# vim: sw=4 tw=72
