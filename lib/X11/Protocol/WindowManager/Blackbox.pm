package X11::Protocol::WindowManager::Blackbox;
use base qw(X11::Protocol::WindowManager::Base);
use strict;
use warnings;

=head1 NAME

X11::Protocol::WindowManager::Blackbox -- blackbox window manager

=head1 SYNOPSIS

 my $bb = X11::Protocol::WindowManager::Blackbox->new($X);

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

=item $bb->B<get_rcfile>() => $rcfile

=cut

sub get_rcfile {
	return shift->get_rcfile_simple("blackbox", ".blackboxrc", "-rc");
}

=item $bb->B<find_style>(I<$style>) => [I<$name>, I<$file>]

=cut

sub find_style {
	return shift->find_style_simple("styles", "/stylerc", "");
}

=item $bb->B<get_style>() => [I<$name>, I<$file>]

=cut

sub get_style {
	return shift->get_style_database("session.styleFile", "Session.StyleFile");
}

=item $bb->B<set_style>(I<$style>)

=cut

sub set_style  {
	return shift->set_style_database("session.styleFile");
}

=item $bb->B<reload_style>()

=cut

sub reload_style {
	my $self = shift;
	if ($self->{wm}{pid}) {
		kill($self->{wm}{pid}, SIGUSR1);
	} else {
		warn "cannot reload blackbox without a pid";
	}
}

=item $bb->B<list_dir>(I<$dir>,I<$style>) => [I<$name>,I<$file>,I<$current>]

=cut

sub list_dir {
	my ($self,$xdir,$style) = @_;
	return $self->list_dir_simple($xdir, "styles", "/stylerc", "", $style);
}

=item $bb->B<list_styles>() => I<@styles>o

=cut

sub list_styles {
	return $self->list_styles_simple();
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
