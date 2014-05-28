package XDG::Menu::Pekwm;
use base qw(XDG::Menu::Base);
use strict;
use warnings;

=head1 NAME

XDG::Menu::Pekwm - generate a PekWM menu from an XDG::Menu tree

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menus/applications.menu');
 my $pekwm = new XDG::Menu::Pekwm;
 print $pekwm->create($tree);

=head1 METHODS

B<XDG::Menu::Pekwm> has the following methods:

=over

=item $pekwm->B<icon>(I<@names>) => I<$spec>

Accepts a list of icon names, I<@names>, as specified in a desktop entry
file and returns an icon specification that can be added to a menu
entry.

=cut

sub icon {
    my($self,@names) = @_;
    foreach (@names) {
	my $icon = $self->SUPER::icon($_,qw(png xpm));
	return sprintf("Icon = \"%s\"; ",$icon) if $icon;
    }
    return '';
}

=item $pekwm->B<create>(I<$tree>,I<$style>,I<$name>) => I<$menu>

Creates the L<pekwm(1)> menu from menu tree, C<$tree>, and returns the
menu in a scalar string, I<$menu>.  C<$tree> must have been created as
the result of parsing the XDG menu using XDG::Menu::Parser (see
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
    my $menu = $self->build($tree,'    ');
    return $menu if $style eq 'entries';
    $menu = $self->appmenu($menu,$name) unless $style eq 'fullmenu';
    $menu = $self->rootmenu($menu,$name) unless $style eq 'appmenu';
    return $menu;
}

=back

=cut

sub wmmenu {
    my($self,$indent) = @_;
    my $text = '';
    $text .= $indent.q(Submenu = "Window Managers" { ).$self->icon('gtk-quit')."\n";
    $self->getenv();
    $self->default();
    my $wms = $self->get_xsessions();
    foreach (sort keys %$wms) {
	my $wm = $wms->{$_};
	my $name = $wm->{Name};
	$name = $_ unless $name;
	next if "\L$name\E" eq 'pekwm';
	my $exec = $wm->{Exec};
	my $icon = $self->icon($wm->{Icon}, 'preferences-system-windows');
	if ($self->{ops}{launch}) {
	    $exec = "$self->{ops}{launch} -X $wm->{id}";
	    $exec =~ s{\.desktop$}{};
	}
	$text .= $indent.q(    Entry = "Start ).$name.q(" { ).$icon.q(Actions = "RestartOther ).$exec.q(" })."\n";
    }
    $text .= $indent.q(    Separator {})."\n";
    $text .= $indent.q(    Entry = "Reload" { ).$self->icon('gtk-redo-ltr.png').q(Actions = "Reload" })."\n";
    $text .= $indent.q(    Entry = "Restart" { ).$self->icon('gtk-refresh').q(Actions = "Restart" })."\n";
    $text .= $indent.q(    Entry = "Exit" { ).$self->icon('gtk-quit').q(Actions = "Exit" })."\n";
    $text .= $indent.q(})."\n";
    return $text;
}

sub appmenu {
    my($self,$entries,$name) = @_;
    my $text = '';
    my $icon = $self->icon(qw(start-here folder));
    $text .= q(Submenu = ").$name.q(" { ).$icon."\n";
    $text .= $entries;
    $text .= q(})."\n";
}

sub rootmenu {
    my($self,$entries) = @_;
    my $text = '';
    $text .= q(# Menu config for pekwm)."\n";
    $text .= q()."\n";
    $text .= q(# Variables)."\n";
    $text .= q(INCLUDE = "vars")."\n";
    $text .= q()."\n";
    $text .= q(RootMenu = "Pekwm" {)."\n";
    $text .= $entries;
    $text .= q(    Separator {})."\n";
    $text .= q(    Submenu = "Pekwm" { ).$self->icon('pekwm')."\n";
    $text .= q(        Entry = "Run Command..." { ).$self->icon('gtk-execute').q(Actions = "ShowCmdDialog" })."\n";
    $text .= q(        SubMenu = "Workspace List" { ).$self->icon('preferences-desktop-display')."\n";
    $text .= q(            Entry = "" { Actions = "Dynamic $_PEKWM_SCRIPT_PATH/pekwm_ws_menu.sh goto dynamic" })."\n";
    $text .= q(        })."\n";
    $text .= q(        Entry = "Window List" { ).$self->icon('preferences-system-windows').q(Actions = "ShowMenu GotoClient True" })."\n";
    $text .= q(        Submenu = "Themes" { ).$self->icon('style')."\n";
    $text .= q(            Entry { Actions = "Dynamic xde-style -m -t" })."\n";
    $text .= q(        })."\n";
    $text .= q(        Submenu = "Styles" { ).$self->icon('style')."\n";
    $text .= q(            Entry { Actions = "Dynamic xde-style -m" })."\n";
    $text .= q(        })."\n";
#   $text .= q(        Submenu = "Themes" { ).$self->icon('style')."\n";
#   $text .= q(            Entry { Actions = "Dynamic $_PEKWM_SCRIPT_PATH/pekwm_themeset.sh $_PEKWM_THEME_PATH" })."\n";
#   $text .= q(            Entry { Actions = "Dynamic $_PEKWM_SCRIPT_PATH/pekwm_themeset.sh ~/.pekwm/themes" })."\n";
##  $text .= q(            Entry { Actions = "Dynamic $_PEKWM_SCRIPT_PATH/pekwm_themeset.sh ~/.config/pekwm/themes" })."\n";
#   $text .= q(        })."\n";
    $text .= q(        Submenu = "Layout" {)."\n";
    $text .= q(            Entry = "Smart" { Actions = "SetLayouter Smart" })."\n";
    $text .= q(            Entry = "Mouse Not Under" { Actions = "SetLayouter MouseNotUnder" })."\n";
    $text .= q(            Entry = "Mouse Centered" { Actions = "SetLayouter MouseCentered" })."\n";
    $text .= q(            Entry = "Mouse Top Left" { Actions = "SetLayouter MouseTopLeft" })."\n";
    $text .= q(            Separator {})."\n";
    $text .= q(            Entry = "Layout Horizontal" { Actions = "SetLayouter TILE_Horizontal" })."\n";
    $text .= q(            Entry = "Layout Vertical" { Actions = "SetLayouter TILE_Vertical" })."\n";
    $text .= q(            Entry = "Layout Dwindle" { Actions = "SetLayouter TILE_Dwindle" })."\n";
    $text .= q(            Entry = "Layout Stacked" { Actions = "SetLayouter TILE_Stacked" })."\n";
    $text .= q(            Entry = "Layout Center One" { Actions = "SetLayouter TILE_CenterOne" })."\n";
    $text .= q(            Entry = "Layout Boxed" { Actions = "SetLayouter TILE_Boxed" })."\n";
    $text .= q(            Entry = "Layout Fib" { Actions = "SetLayouter TILE_Fib" })."\n";
    $text .= q(        })."\n";
    $text .= $self->wmmenu('        ');
    $text .= q(    })."\n";
    $text .= q(    Entry = "Refresh Menu" {).$self->icon('gtk-refresh').q(Actions = "Exec xdg-menugen -format pekwm -desktop PEKWM -launch -o ).$self->{ops}{output}.q(" })."\n"
	if $self->{ops}{output};
    $text .= q(    Entry = "Reload" { ).$self->icon('gtk-redo-ltr.png').q(Actions = "Reload" })."\n";
    $text .= q(    Entry = "Restart" { ).$self->icon('gtk-refresh.png').q(Actions = "Restart" })."\n";
    $text .= q(    Separator {})."\n";
    $text .= q(    Entry = "Exit" { ).$self->icon('gtk-quit').q(Actions = "Exit" })."\n";
    $text .= q(})."\n";
    $text .= q()."\n";
    $text .= q(COMMAND = "cat $HOME/.pekwm/window")."\n";
    $text .= q()."\n";
    return $text;
}
sub build {
    my ($self,$item,$indent) = @_;
    my $name = ref($item);
    $name =~ s{.*\:\:}{};
    return $self->$name($item,$indent) if $self->can($name);
    return '';
}
sub Menu {
    my ($self,$item,$indent) = @_;
    my $text = '';
    if ($item->{Elements}) {
	foreach (@{$item->{Elements}}) {
	    next unless $_;
	    $text .= $self->build($_,$indent.'    ');
	}
    }
    return $text;
}
sub Header {
    my ($self,$item,$indent) = @_;
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    my $text = '';
    # Pekwm does not (really) support inline headers, try and empty
    # entry with separators
    $text .= sprintf "%sSeparator {}\n", $indent;
    $text .= sprintf "%sEntry = \"%s\" { Icon = \"%s\" }\n",
	$indent, $name, $item->Icon([qw(png xpm jpg)]);
    $text .= sprintf "%sSeparator {}\n", $indent;
    return $text;
}
sub Separator {
    my ($self,$item,$indent) = @_;
    return sprintf "%sSeparator {}\n", $indent;
}
sub Application {
    my ($self,$item,$indent) = @_;
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    my $exec = $item->Exec;
    $exec = "$self->{ops}{launch} ".$item->Id
	if $self->{ops}{launch};
    return sprintf "%sEntry = \"%s\" { Icon = \"%s\"; Actions = \"Exec %s\" }\n",
	   $indent, $name, $item->Icon([qw(png xpm jpg)]), $exec;
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $text = '';
    if ($item->{Menu}{Elements} and @{$item->{Menu}{Elements}}) {
	my $name = $item->Name; $name =~ s/["]/\\"/g;
	$text .= sprintf "%sSubmenu = \"%s\" {\n", $indent, $name;
	$text .= sprintf "%s    Icon = \"%s\"\n", $indent,
	    $item->Icon([qw(png xpm jpg)]);
	$text .= $self->build($item->{Menu},$indent.'    ');
	$text .= sprintf "%s}\n", $indent;
    }
    return $text;
}

1;

__END__

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
