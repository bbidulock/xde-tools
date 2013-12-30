package XDG::Menu::Base;
use base qw(XDG::Context);
use strict;
use warnings;

=head1 NAME

XDG::Menu::Base - base module for WM-specfic menu generators.

=head1 DESCRIPTION

This module provide as base for WM-specfic menu generators and contains
common methods.  It is not intended on being instantiated directly.

=head1 METHODS

The following methods are provided:

=over

=item $base->B<icon>(I<$name>,I<@ext>) => I<$icon>

Takes the name of an icon, I<$name>, as directly obtained from a desktop
entry file, and a list of acceptable extensions, I<@exts>.  Returns the
complete path to the icon file.

=cut

sub icon {
    my($self,$file,@exts) = @_;
    return '' unless $file;
    @exts = ('xpm') unless @exts;
    if ($file =~ m{/} and -f $file) {
	foreach (@exts) {
	    return $file if $file =~ m{\.$_$};
	}
    }
    my $name = $file;
    $name =~ s{^.*/}{};
    $name =~ s/\.[a-z]{3,4}$//;
    if (my $icons = XDG::Menu::DesktopEntry->get_icons) {
	if ($file = $icons->FindIcon($name,16,\@exts)) {
	    return $file;
	}
    }
    return '';
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
