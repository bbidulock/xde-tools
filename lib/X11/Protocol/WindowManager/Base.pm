package X11::Protocol::WindowManager::Base;
use X11::Protocol::EWMH	    qw(:all);
use X11::Protocol::WMH	    qw(:all);
use X11::Protocol::ICCCM    qw(:all);
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

=head1 NAME

X11::Protocol::WindowManager::Base -- window manager base class

=head1 SYNOPSIS

  package X11::Protocol::WindowManager::MyWindowManager;
  use base qw(X11::Protocol::WindowManager::Base);

=head1 DESCRIPTION

Provides a base class for window manager classes and a set of utility
methods common to all window manager classes.

=head1 METHODS

=over

=item B<new> X11::Protocol::WindowManager::Base, I<$X>, I<%options>

Creates a new, undetected, window manager instance given the
L<X11::Protocol(3pm)> object, I<$X>, and initializes it
with the provided options.  This also performs detection of the window
manager when required.  The object returned will either be a specialized
module that uses X11::Protocol::WindowManager::Base as a base, or
C<undef> when detection or specification of the window manager fails.
For example:

 my $wm = new X11::Protocol::WindowManager::Base undef, wmname => 'blackbox';

will return a L<X11::Protocol::WindowManager::Blackbox(3pm)> instance.

Recognized options are as follows:

=over

=item B<wmname>

Specifies the name of the window manager.  The name will be detected
when unspecified and I<$X> is defined.

=item B<rcfile>

Specifies the primary configuration file for the window manager.  The
primary configuration file will be detected when unspecified.

=item B<screen>

Specifies the screen number to associate with this window manager.  When
unspecified and I<$X> is specified, the current screen number of the
L<X11::Protocol(3pm)> object will be used.  When unspecified and I<$X>
is C<undef>, the window manager object will not be associated with a
screen.

=back

This method is really not intended on being called by the user, and is
normally invoked by the check_wm() method of
L<X11::Protocol::WindowManager(3pm)>.

=cut

sub new {
    my($type,$X,%options) = @_;
    my $wm = bless \%options, $type;
    $wm->{screen} = $X->{screen} unless defined $wm->{screen};
    die "bad screen number $wm->{screen}"
	if (defined($wm->{screen}) and
		($wm->{screen} < 0 || $wm->{screen} >= @{$X->{screens}}));
    unless ($wm->{wmname}) {
	$X->choose_screen($wm->{screen}) unless $wm->{screen} eq $X->{screen};
	$wm->detect($X);
    }
    if ($wm->{wmname}) {
	my $firstchar = substr($wm->{wmname},0,1);
	my $restchars = substr($wm->{wmname},1);
	my $cname = "X11::Protocol::WindowManager::\U$firstchar\E\L$restchars\E";
	if (eval "require $cname;") {
	    bless $wm, $cname;
	    return $wm;
	}
    }
    return undef;
}

=back

=head2 Window Manager Detection

Window manager detection procedures.

=over


=item $wm->B<find_wm_name>(I<$X>)

=cut

sub find_wm_comp {
    my($wm,$X) = @_;
    my $check;
    $wm->{checks} = [];
    if (($wm->{redir_check} = $X->check_redir())) {
	unshift @{$wm->{checks}}, $wm->{redir_check};
    }
    if (($wm->{icccm_check} = $X->check_icccm())) {
	unshift @{$wm->{checks}}, $wm->{icccm_check};
    }
    if (($wm->{motif_check} = $X->check_motif())) {
	unshift @{$wm->{checks}}, $wm->{motif_check};
    }
    if (($wm->{maker_check} = $X->check_maker())) {
	unshift @{$wm->{checks}}, $wm->{maker_check};
    }
    if (($wm->{winwm_check} = $X->check_winwm())) {
	unshift @{$wm->{checks}}, $wm->{winwm_check};
    }
    if (($wm->{netwm_check} = $X->check_netwm())) {
	unshift @{$wm->{checks}}, $wm->{netwm_check};
    }
    return scalar @{$wm->{checks}};
}

sub find_wm_name {
    my($wm,$X) = @_;
    my $name;
    foreach my $check (@{$wm->{checks}}) {
	defined($name = $X->check_name($check)) and last;
    }
    $wm->{wmname} = $name;
    return $name;
}

sub find_wm_host {
    my($wm,$X) = @_;
    my $host;
    foreach my $check (@{$wm->{checks}}) {
	defined($host = $X->check_host($check)) and last;
    }
    $wm->{host} = $host;
    return $host;
}

sub find_wm_pid {
    my($wm,$X) = @_;
    my $pid;
    foreach my $check (@{$wm->{checks}}) {
	defined($pid = $X->check_pid($check,$wm->{wmname})) and last;

    }
    $wm->{pid} = $pid;
    return $pid;
}

sub find_wm_comm {
    my($wm,$X) = @_;
    my $comm;
    foreach my $check (@{$wm->{checks}}) {
	defined($comm = $X->check_comm($check)) and last;
    }
    $wm->{comm} = $comm;
    return $comm;
}




=item $wm->B<check_wm>(I<$X>)

Detect which window manager is currently running on the associated
screen.

=cut

sub check_wm {
    my($wm,$X) = @_;

    $wm->find_wm_comp($X);
    $wm->find_wm_name($X);
    $wm->find_wm_host($X);
    $wm->find_wm_pid($X);
    $wm->find_wm_comm($X);
    $wm->find_wm_proc($X);

    if ($wm->{wmname}) {
    }
    if ($wm->{wmname} and $wm->{pid}) {
	for (my $i = 0; $i < @{$X->{screens}}; $i++) {
	    next if $i == $wm->{screen};
	    next unless my $sm = $X->{screens}[$i]{wm};
	    next if not $wm->{host} or not $sm->{host} or $wm->{host} ne $sm->{host};
	    next if not $wm->{pid} or not $sm->{pid} or $wm->{pid} != $sm->{pid};
	    $wm = $sm;
	    last;
	}
    }
    $X->{screens}[$wm->{screen}]{wm} = $wm;
    return $wm;
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
