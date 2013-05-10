package XDE::Icons;
use base qw(XDE::Context);
use strict;
use warnings;

=head1 NAME

XDE::Icons - locate icons under an icon theme

=head1 SYNOPSIS

 use XDE::Icons;
 my $icons = XDE::Icons->new(
	XDG_ICON_PREPEND => '/some/path:/another/path',
	XDG_ICON_APPEND  => '/some/path:/another/path',
	XDG_ICON_FALLBACK => '/usr/X11/lib/pixmaps',
 );

=head1 DESCRIPTION

The B<XDE::Icons> module provides an XDG compliant mechanism for looking up Icons.

=cut
