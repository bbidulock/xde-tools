package XDG::Menu::Fvwm;
use base qw(XDG::Menu::Base);
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

=item $fvwm->B<icon>(I<@names>) => I<$spec>

Accepts a list of icon names, I<@names>, as specified in a desktop entry
file and returns an icon specification that can be added to a menu
entry.

=cut

sub icon {
    my($self,@names) = @_;
    foreach (@names) {
	my $icon = $self->SUPER::icon($_,qw(png xpm));
	return "%$icon%" if $icon;
    }
    return '';
}

=item $fvwm->B<create>(I<$tree>,I<$style>,I<$name>) => I<$menu>

Creates the FVWM menu from menu tree, I<$tree>, and returns the menu in
a scalar string, I<$menu>.  I<$tree> must have been created as the
result of parsing the XDG menu using XDG::Menu::Parser (see
L<XDG::Menu(3pm)>).

I<$style>, which defaults to C<fullmenu>, is the style of menu to create
as follows:

=over

=item C<entries>

Does not create a full menu at all, but just supplies the entries that
would be placed in an applications menu (but not the shell of the menu).
This can be useful for menu systems that include other menu files.  When
the menu system does not nest, this does not return the preamble.  The
preamble can be obtained using C<appmenu>.

=item C<appmenu>

Does not create a root window menu, but only creates a stand-alone
applications menu named, I<$name>.  This menu contains only applications
menu items.

=item C<submenu>

Creates a full root window menu, however, the XDG applications are
contained in a submenu of the root menu, named I<$name>.  The
applications submenu is also made available (where supported by the menu
system) as a stand-alone applications menu named, I<$name>.

=item C<fullmenu>

Creates a full root window menu, however, the XDG applications are
contained directly in the root window menu rather than in a submenu.
An applications submenu is also made available (where supported by the
menu system) as a stand-alone applications menu named, I<$name>.

=back

When the applications menu entries are created as a submenu of the root
menu or a menu of its own, the submenu will be given the name, I<$name>.
I<$name>, when unspecified, defaults to C<Applications>.

=cut

sub create {
    my($self,$tree,$style,$name) = @_;
    $style = 'fullmenu' unless $style;
    $name = 'Applications' unless $name;
    $self->{menus} = [];
    my $entries = $self->build($tree);
    push @{$self->{menus}}, $self->wmmenu()
	if $style eq 'fullmenu';
    push @{$self->{menus}}, $self->fvwmmenu()
	if $style eq 'fullmenu';
    push @{$self->{menus}}, $self->appmenu($entries,$name);
    return $entries if $style eq 'entries';
    $entries = sprintf("")
	if $style eq 'submenu';
    push @{$self->{menus}}, $self->rootmenu($entries,$name)
	if $style ne 'appmenu';
    return join("\n",@{$self->{menus}});
}

sub wmmenu {
    my $self = shift;
    my $text = '';
    $text .= sprintf "%s\n", 'DestroyMenu WindowManagers';
    $text .= sprintf "%s\n", 'AddToMenu WindowManagers "Window Managers" Title';
    $self->getenv();
    $self->default();
    my $wms = $self->get_xsessions();
    my $gotone = 0;
    foreach (sort keys %$wms) {
	my $wm = $wms->{$_};
	my $name = $wm->{Name};
	$name = $_ unless $name;
	next if $name =~ m{fvwm}i;
	my $exec = $wm->{Exec};
	my $icon = $self->icon($wm->{Icon},'preferences-desktop-display');
	$text .= sprintf "+ \"%s%s\" Restart %s\n", $name, $icon, $exec;
	$gotone = 1;
    }
    $text .= $self->Separator() if $gotone;
    $text .= sprintf "+ \"%s%s\" Restart\n", 'Restart', $self->icon('gtk-refresh');
    $text .= sprintf "+ \"%s%s\" Quit\n", 'Quit', $self->icon('gtk-quit');
    return $text;
}
sub fvwmmenu {
    my $self = shift;
    my $text = '';
    $text .= sprintf "%s\n", 'DestroyMenu FVWMmenu';
    $text .= sprintf "%s\n", 'AddToMenu FVWMmenu "FVWM" Title';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Modules',		'%mini.modules.xpm%',	'Popup Module-Popup';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Settings',		'%mini.desktop.xpm%',	'Popup Settings';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Documents',		'%mini.books.xpm%',	'Popup Documents';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Screen Saver',	'%mini.display.xpm%',	'Popup Screen';
    $text .= $self->Separator();
    $text .= sprintf "+ \"%s%s\" %s\n", '&Restart',		'%mini.turn.xpm%',	'Popup Restart';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Quit FVWM',		'%mini.stop.xpm%',	'FvwmForm FvwmForm-QuitVerify';
    $text .= "\n";
    $text .= sprintf "%s\n", 'DestroyMenu StartMenu';
    $text .= sprintf "%s\n", 'AddToMenu StartMenu@side.fvwm2.xpm@^black^';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Applications',	'%programs.xpm%',	'Popup xdg_menu';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Shells',		'%shells.xpm%',		'Popup Shells';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Programs',		'%programs.xpm%',	'Popup Programss';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Documents',		'%documents.xpm%',	'Popup Documents';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Settings',		'%settings.xpm%',	'Popup Settings';
    $text .= $self->Separator();
    $text .= sprintf "+ \"%s%s\" %s\n", '&Modules',		'%modules.xpm%',	'Popup Module-Popup';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Find',		'%find1.xpm%',		'FvwmScript FvwmScript-Find';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Help',		'%help.xpm%',		'Exec exec xman';
    $text .= sprintf "+ \"%s%s\" %s\n", '&Run',			'%run.xpm%',		'Exec exec xde-run';
    $text .= $self->Separator();
    $text .= sprintf "+ \"%s%s\" %s\n", '&Screen Saver',	'%screen.xpm%',		'Popup Screen';
    $text .= sprintf "+ \"%s%s\" %s\n", 'Shut &Down',		'%shutdown.xpm%',	'Module FvwmScript FvwmScript-Quit';
    return $text;
}
sub appmenu {
    my($self,$entries,$name) = @_;
    $name = 'Applications' unless $name;
    my $text = '';
    $text .= sprintf "%s\n", "DestroyMenu xdg_menu";
    $text .= sprintf "%s\n", "AddToMenu xdg_menu \"$name\" Title";
    $text .= $entries;
    return $text;
}
sub rootmenu {
    my($self,$entries) = @_;
    my $text = '';
    $text .= sprintf "%s\n", 'DestroyMenu Utilities';
    $text .= sprintf "%s\n", 'AddToMenu Utilities "Root Menu" Title';
    $text .= $entries;
    $text .= $self->Separator();
    $text .= sprintf "+ \"%s%s\" Popup %s\n", 'FVWM', $self->icon('fvwm'), 'FVWMmenu';
    $text .= $self->Separator();
    $text .= sprintf "+ \"%s%s\" Restart\n", 'Restart', $self->icon('gtk-refresh');
    $text .= sprintf "+ \"%s%s\" Quit\n", 'Quit', $self->icon('gtk-quit');
    return $text;
}

# For FVWM we perform a breadth first traversal: the root menu is first
# and then subsequent deeper menus are defined after that.  Menus are
# not nested in FVWM.  We create both the RootMenu and the StartMenu.
#
sub old_create {
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

=back

=cut

sub build {
    my ($self,$item,@args) = @_;
    my $name = ref($item);
    $name =~ s{.*\:\:}{};
    return $self->$name($item,@args) if $self->can($name);
    return '';
}
sub Menu {
    my ($self,$item,@args) = @_;
    my $text = '';
    if ($item->{Elements}) {
	foreach (@{$item->{Elements}}) {
	    next unless $_;
	    $text .= $self->build($_,@args);
	}
    }
    return $text;
}
sub Header {
    my ($self,$item,@args) = @_;
    my $text = '';
    my $icon = $item->Icon([qw(png xpm)]); $icon = "%$icon%" if $icon;
    $text .= sprintf "+ \"%s%s\" Nop\n", $item->Name,$icon;
    return $text;
}
sub Separator {
    my ($self,$item,@args) = @_;
    my $text = '';
    $text .= sprintf "%s\n", '+ "" Nop';
    return $text;
}
sub Application {
    my ($self,$item,@args) = @_;
    my $text = '';
    my $name = $item->Name;
    my $icon = $item->Icon([qw(png xpm)]); $icon = "%$icon%" if $icon;
    my $exec = $item->Exec;
    $text .= sprintf "+ \"%s%s\" Exec exec %s\n", $name, $icon, $exec;
    return $text;
}
sub Directory {
    my ($self,$item,@args) = @_;
    my $text = '';
    my $menu = $item->{Menu};
    # no empty menus
    return $text unless $menu->{Elements} and @{$menu->{Elements}}; 
    my $name = $item->Name;
    my $id = $name; $id =~ s{\W}{}g; $id = "/XDG/$id";
    $text .= sprintf "DestroyMenu %s\n", $id;
    $text .= sprintf "AddToMenu %s \"%s\" Title\n", $id, $name;
    $text .= $self->build($menu,@args);
    push @{$self->{menus}}, $text;
    my $icon = $item->Icon([qw(png xpm)]); $icon = "%$icon%" if $icon;
    return sprintf "+ \"%s%s\" Popup %s\n", $name, $icon, $id;
}

1;

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
