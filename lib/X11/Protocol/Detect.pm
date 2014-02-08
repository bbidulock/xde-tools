package X11::Protocol::Detect;
use X11::Protocol::WMSpecific	qw(:all);
use X11::Protocol::Util		qw(:all);
use X11::Protocol::ICCCM	qw(:all);
use X11::Protocol::WMH		qw(:all);
use X11::Protocol::EWMH		qw(:all);
use X11::Protocol;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

=head1 NAME

X11::Protocol::Detect -- window manager detection things

=head1 SYNOPSIS

 package X11::Protocol::My;
 use base qw(X11::Protocol::Detect X11::Protocol);

 package main;

 my $wms = X11::Protocol::My->new();

 my $pid = $wm->get_pid;

=head1 DESCRIPTION

Provides a modules with methods that can be used to detect running
window managers and events related to running window managers.

=head1 METHODS

The following methods are provided by this module:

=over

=back

=head2 General

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
