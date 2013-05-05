package XDG::Menu::Tray::Blackbox;
use base qw(XDG::Menu::Tray);
use strict;
use warnings;

=head1 NAME

 XDG::Menu::Tray::Blackbox - generate a Blackbox system tray menu from an XDG::Menu tree

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_menu('/etc/xdg/menus/applications.menu');
 my $tray = new XDG::Menu::Tray::Blackbox;
 my $menu = $tray->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Tray::Blackbox> is a module that reads an XDG::Menu::Layout
tree and generates a Gtk2 menu for Blackbox.

=head1 METHODS

B<XDG::Menu::Tray::Blackbox> has the following methods:

=over

=item XDG::Menu::Tray::Blackbox->B<new>() => XDG::Menu::Tray::Blackbox

Creates a new XDG::Menu::Tray::Blackbox instance for creating Gtk2
menus.

=cut

sub new {
    return bless {}, shift;
}

=item $tray->B<create>($tree) => Gtk2::Menu

Creates the Gtk2 menu from menu tree, C<$tree>, and returns the menu as
a Gtk2::Menu object.  C<$tree> must have been created as a result of
parsing the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

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


