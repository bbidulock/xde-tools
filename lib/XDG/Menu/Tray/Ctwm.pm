package XDG::Menu::Tray::Ctwm;
use base qw(XDG::Menu::Tray);
use strict;
use warnings;

=head1 NAME

XDG::Menu::Tray::Ctwm - generate a CTWM system tray menu

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_menu('/etc/xdg/menus/applications.menu');
 my $tray = new XDG::Menu::Tray::Ctwm;
 my $menu = $tray->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Tray::Ctwm> is a module that reads an
L<XDG::Menu::Layout(3pm)> tree and generates a Gtk2 menu for CTWM.

=head1 METHODS

The following methods are provided:

=over

=item $tray = XDG::Menu::Tray::Ctwm->B<new>()

Creates a new XDG::Menu::Tray::Ctwm instance for creating a  Gtk2::Menu.

=cut

sub new { return bless {}, shift }

=item $tray->B<create>(I<$tree>) => Gtk2::Menu

Creates the L<Gtk2(3pm)> menu from menu tree, I<$tree>, and returns the
menu as a L<Gtk2::Menu(3pm)> object.  I<$tree> must have been created as
a result of parsing the XDG menu using XDG::Menu::Parser (see
L<XDG::Menu(3pm)>).

The resulting menu has window-manager specific actions that are included
in a C<CTWM> submenu.

=cut

sub create {
    my ($self,$item) = @_;
    my $m = Gtk2::Menu->new;
    $self->build($item,$m);
    my ($mi,$im,$sm);

    $mi = Gtk2::SeparatorMenuItem->new;
    $m->append($mi);

    $sm = Gtk2::Menu->new;

    $mi
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDG::Menu(3pm)>,
L<XDG::Menu::Tray(3pm)>.


# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
