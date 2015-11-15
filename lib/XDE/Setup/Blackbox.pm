package XDE::Setup::Blackbox;
use base qw(XDE::Setup);
use File::Path qw(make_path);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Setup::Blackbox - setup an XDE session for the L<blackbox(1)> window manager

=head1 SYNOPSIS

 use XDE::Setup;

 my $xde = XDE::Setup->new(%OVERRIDES,ops=>%ops);
 $xde->getenv();
 $xde->set_session('blackbox') or die "Cannot use blackbox";
 $xde->setenv();
 $xde->setup_session() or die "Cannot setup blackbox";
 $xde->launch_session() or die "Cannot launch blackbox";

=head1 DESCRIPTION

The B<XDE::Setup::Blackbox> module provides the ability to seup a L<blackbox(1)>
environment  for the I<X Desktop Environment>, L<XDE(3pm)>.  This module
is not normally invoked directly but is established by setting an
L<XDE::Setup(3pm)> session to C<blackbox>.

=head1 METHODS

The B<XDE::Setup::Blackbox> module provides specializations of the the
following L<XDE::Setup(3pm)> methods:

=over

=item $xde->B<setenv>() => undef

=cut

=item $xde->B<setup_session>() => I<$status>

=cut

sub setup_session {
    my $self = shift;
    $self->SUPER::setup_session('blackbox');
    my $rcdir = $self->{ops}{xdg_rcdir} ? "~/.blackbox" : "$self->{XDG_CONFIG_HOME}/blackbox";
    $rcdir =~ s|~|$ENV{HOME}|;
    my $tilde = $rcdir;
    $tilde = s|^$ENV{HOME}|~|;
    my $dffile = "$ENV{HOME}/.blackboxrc";
    my $dfmenu = "$ENV{HOME}/.bbmenu";
    my $rcfile = "$rcdir/rc";
    foreach (qw(backgrounds styles)) {
	unless (-d "$rcdir/$_") {
	    eval { make_path("$rcdir/$_") };
	    return undef if $@;
	}
    }
    my @lines = ();
    if (-f $rcfile) {
	if (open(my $fh,"<",$rcfile)) {
	    while (<$fh>) { chomp;
		push @lines, $_;
	    }
	    close($fh);
	}
    }
    my %settings = (
	'session.menuFile' => "$rcdir/menu",
	'session.styleFile' => "/usr/share/blackbox/styles/Default",
    );
    for (my $i=0;$i<@lines;$i++) {
	if ($lines[$i] =~ m{^([^!][^:]+):}) {
	    if (exists $settings{$1}) {
		$lines[$i] = "$1:\t".delete($settings{$1});
	    }
	}
    }
    while (my ($k,$v) = each %settings) {
	push @lines, "$k:\t$v";
    }
    if ($self->{ops}{dry_run}) {
	print STDERR "would overwrite $rcfile with:\n",join("\n",@lines),"\n";
    } else {
	if (open(my $fh,">",$rcfile)) {
	    print $fh join("\n",@lines),"\n";
	    close($fh);
	}
    }
    $rcfile =~ s|^$ENV{HOME}|\$HOME|;
    $self->{startwm} = "blackbox -rc \"$rcfile\"";
    return $self;
}

=item $xde->B<launch_session>() => I<$status>

=cut

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<blackbox(1)>,
L<XDE::Setup(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
