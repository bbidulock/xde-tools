package XDE::Setup::Fluxbox;
use base qw(XDE::Setup);
use File::Path qw(make_path);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Setup::Fluxbox - setup an XDE session for the L<fluxbox(1)> window manager

=head1 SYNOPSIS

 use XDE::Setup;

 my $xde = XDE::Setup->new(%OVERRIDES,ops=>%ops);
 $xde->getenv();
 $xde->set_session('fluxbox') or die "Cannot use fluxbox";
 $xde->setenv();
 $xde->setup_session() or die "Cannot setup fluxbox";
 $xde->launch_session() or die "Cannot launch fluxbox";

=head1 DESCRIPTION

The B<XDE::Setup::Fluxbox> module provides the ability to seup a L<fluxbox(1)>
environment  for the I<X Desktop Environment>, L<XDE(3pm)>.  This module
is not normally invoked directly but is established by setting an
L<XDE::Setup(3pm)> session to C<fluxbox>.

=head1 METHODS

The B<XDE::Setup::Fluxbox> module provides specializations of the the
following L<XDE::Setup(3pm)> methods:

=over

=item $xde->B<setenv>() => undef

=cut

=item $xde->B<setup_session>() => I<$status>

Prepares the L<XDE(3pm)> file for the L<fluxbox(1)> window manager and a
C<FLUXBOX> L<XDE(3pm)> session.  This method primary adjusts the file
location definitions in the F<init>f ile.  L<fluxbox(1)> normally has
its configuration files in F<$HOME/.fluxbox>.  XDG configuration files
will be placed in F<$XDG_CONFIG_HOME/fluxbox>.

L<fluxbox(1)> looks for its primary configuration in the file
F<~/.fluxbox/init>.  This file specifies the location of all other
configuration files.  L<fluxbox(1)> can be invoked with the C<-rc>
option specifying which F<init> file to use (i.e. one other than
F<~/.fluxbox/init>).  The difficulty with doing this is that
L<fluxbox(1)> provides no indication of the configuration file in use.
L<fluxbox-remote(1)> can be used (when the configuraiton file is
configured to allow it) to determine the location of the configuraiton
file.  L<xde-identify(1)> is capable of determining the location of the
configuration file when run on the same host as L<fluxbox(1)>.

It is, therefore, possible to relocate configuration files to the
directory F<$XDG_CONFIG_HOME/fluxbox>.  To avoid difficulties with
starting the window manager from within XDE, XDE should control the menu
item for window manager selection.

=cut

sub setup_session {
    my $self = shift;
    $self->SUPER::setup_session('fluxbox');
    my $rcdir = ($self->{ops}{xdg_rcdir}) ? "~/.fluxbox" : "$self->{XDG_CONFIG_HOME}/fluxbox";
    $rcdir =~ s|~|$ENV{HOME}|;
    my $tilde = $rcdir;
    $tilde = s|^$ENV{HOME}|~|;
    my $dffile = "$ENV{HOME}/.fluxbox/init";
    my $dfmenu = "$ENV{HOME}/.fluxbox/menu";
    foreach (qw(backgrounds icons pixmaps styles)) {
	unless (-d "$rcdir/$_") {
	    eval { make_path("$rcdir/$_") };
	    return undef if $@;
	}
    }
    my $sharedir = $self->{ops}{sharedir};
    $sharedir = "/usr/share/xde" unless $sharedir;
    $sharedir = "$sharedir/fluxbox";
    if (-f "$sharedir/version") {
	if (-f "$rcdir/version") {
	} else {
	}
    }
    my @lines = ();
}


=item $xde->B<launch_session>() => I<$status>

=cut

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<fluxbox(1)>,
L<XDE::Setup(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
