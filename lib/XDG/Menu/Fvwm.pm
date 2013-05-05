package XDG::Menu::Fvwm;
use strict;
use warnings;

=head1 NAME

 XDG::Menu::Fvwm - generate an FVWM menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->$parse_uri('/etc/xdg/menus/applications.menu');
 my $fvwm = new XDG::Menu::FVWM;
 print $fluxbox->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Fvwm> is a module that reads an XDG::Menu::Layout tree
and generates an FVWM style menu.

=head1 METHODS

B<XDG::Menu::Fvwm> has the following methods:

=over

=item XDG::Menu::Fvwm->B<new>() => XDG::Menu::Fvwm

Create a new XDG::Menu::Fvwm instance for creating FVWM menus.

=cut

sub new {
    return bless {}, shift;
}

=item $fvwm->B<create>($tree) => scalar

Creates the FVWM menu from menu tree, C<$tree>, and returns the menu in
a scalar string.  C<$tree> must have been created as the result of
parsing the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

=cut

# For FVWM we perform a breadth first traversal: the root menu is first
# and then subsequent deeper menus are defined after that.  Menus are
# not nested in FVWM.  We create both the RootMenu and the StartMenu.
#
sub create {
    my ($self,$item) = @_;
    my $icons = XDG::Menu::DesktopEntry->get_icons();
    my $icon;
    my $text = '';
    $text .= sprintf "%s\n", 'DestroyMenu Utilities';
    $text .= sprintf "%s\n", 'AddToMenu Utilities "Root Menu" Title';
    $text .= $self->build($item,1);
    $text .= sprintf "%s\n", '+ "Fvwm &Modules%mini.modules.xpm%" Popup Module-Popup';
    $text .= sprintf "%s\n", '+ "&Settings%mini.desktop.xpm%"     Popup Settings';
    $text .= sprintf "%s\n", '+ "&Documents%mini.books.xpm%"      Popup Documents';
    $text .= sprintf "%s\n", '+ "&Screen Saver%mini.display.xpm%" Popup Screen';
    $text .= sprintf "%s\n", '+ ""                                Nop';
    $text .= sprintf "%s\n", '+ "&Restart%mini.turn.xpm%"         Popup Restart';
    $text .= sprintf "%s\n", '+ "&Quit FVWM%mini.stop.xpm%"       FvwmForm FvwmForm-QuitVerify';
    $text .= sprintf "%s\n", 'DestroyMenu StartMenu';
    $text .= sprintf "%s\n", 'AddToMenu StartMenu@side.fvwm2.xpm@^black^';
    $text .= $self->build($item,1);
    $text .= sprintf "%s\n", '+ ""                                Nop';
    $text .= sprintf "%s\n", '+ "&Module%modules.xpm%"            Popup Module-Popup';
    $text .= sprintf "%s\n", '+ "&Find%find1.xpm%"                FvwmScript FvwmScript-Find';
    $text .= sprintf "%s\n", '+ "&Help%help.xpm%"                 Exec exec xman';
    $text .= sprintf "%s\n", '+ "&Run...%run.xpm%"                FvwmScript FvwmScript-Run';
    $text .= sprintf "%s\n", '+ ""                                Nop';
    $text .= sprintf "%s\n", '+ "&Screen Saver%screen.xpm%"       Popup Screen';
    $text .= sprintf "%s\n", '+ "Shut &Down%shutdown.xpm%"        Exec exec xdg-logout';
    $text .= $self->build($item,0);
}
sub build {
    my ($self,$item,$breadth) = @_;
    my $name = ref($item);
    $name =~ s{.*\:\:}{};
    return $self->$name($item,$breadth) if $self->can($name);
    return '';
}

# Creation of the FVWM menu is somewhat different from other menus
# because menu definitions are not nested.  Each menu is defined in a
# list (from shallowest to deepest).  Menus that contain other menus are
# referred to by name rather than being nested in the superior menu's
# definition.  So what we need to do is traverse breadth first and
# outputting the definitions before going deep.

sub Menu {
    my ($self,$item,$breadth) = @_;
    my $text = '';
    if ($item->{Elements}) {
	foreach (@{$item->{Elements}}) {
	    next unless $_;
	    $text .= $self->build($_,$breadth);
	}
    }
    return $text;
}
sub Header {
    my ($self,$item,$breadth) = @_;
    my $text = '';
    if ($breadth) {
	$text .= sprintf "+ \"%s\" Nop\n", $item->Name;
    }
    return $text;
}
sub Separator {
    my ($self,$item,$breadth) = @_;
    my $text = '';
    if ($breadth) {
	$text .= sprintf "%s\n", '+ "" Nop';
    }
    return $text;
}
sub Application {
    my ($self,$item,$breadth) = @_;
    my $text = '';
    if ($breadth) {
	my $name = $item->Name;
	my $icon = $item->Icon([qw(png xpm)]);
	my $exec = $item->Exec;
	$text .= sprintf "+ \"%s%%%s%%\" Exec exec %s\n", $name, $icon, $exec;
    }
    return $text;
}
sub Directory {
    my ($self,$item,$breadth) = @_;
    my $menu = $self->{Menu};
    my $text = '';
    # no empty menus
    return $text unless @{$menu->{Elements}}; 
    my $name = $item->Name;
    my $id = $name; $name =~ s{ }{-}g;
    if ($breadth) {
	$text .= sprintf "+ \"%s%%%s%%\" Popup %s\n", $name,
	    $item->Icon([qw(png xpm)]), $id;
    } else {
	$text .= sprintf "DestroyMenu %s\n", $id;
	$text .= sprintf "AddToMenu %s \"%s\" Title\n", $id, $name;
	$text .= $self->build($menu,1); # breadth first
	$text .= $self->build($menu,0); # go deep
    }
    return $text;
}
