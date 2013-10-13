package XDG::Menu::Pekwm;
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

=item XDG::Menu::Pekwm>B<new>($tree) => XDG::Menu::Pekwm

Creates a new XDG::Menu::Pekwm instance for creating PekWM menus.

=cut

sub new {
    return bless {}, shift;
}

sub icon {
    my ($self,$name) = @_;
    return '' unless $name;
    return $name if $name =~ m{/} and -f $name;
    $name =~ s{.*/}{};
    $name =~ s{\.(png|xpm|svg|jpg)$}{};
    my $icons = XDG::Menu::DesktopEntry->get_icons;
    return '' unless $icons;
    my $fn = $icons->FindIcon($name,16,[qw(png xpm)]);
    return sprintf("Icon = \"%s\"; ", $fn) if $fn;
    return '';
}

=item $pekwm->B<create>($tree) => scalar

Creates the PekWM menu from menu tree, C<$tree>, and returns the menu in
a scalar string.  C<$tree> must have been created as the result of
parsing the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

=cut

sub create {
    my ($self,$item) = @_;
    my $text = '';
    $text .= q(# Menu config for pekwm)."\n";
    $text .= q()."\n";
    $text .= q(# Variables)."\n";
    $text .= q(INCLUDE = "vars")."\n";
    $text .= q()."\n";
    $text .= q(RootMenu = "Pekwm" {)."\n";
    $text .= $self->build($item,'');
    $text .= q(    Separator {})."\n";
    $text .= q(    Submenu = "Pekwm" { ).$self->icon('pekwm')."\n";
    $text .= q(        Entry = "Run Command..." { ).$self->icon('gtk-execute').q(Actions = "ShowCmdDialog" })."\n";
    $text .= q(        SubMenu = "Workspace List" { ).$self->icon('preferences-desktop-display')."\n";
    $text .= q(            Entry = "" { Actions = "Dynamic $_PEKWM_SCRIPT_PATH/pekwm_ws_menu.sh goto dynamic" })."\n";
    $text .= q(        })."\n";
    $text .= q(        Entry = "Window List" { ).$self->icon('preferences-system-windows').q(Actions = "ShowMenu GotoClient True" })."\n";
    $text .= q(        Submenu = "Themes" { ).$self->icon('style')."\n";
    $text .= q(            Entry { Actions = "Dynamic $_PEKWM_SCRIPT_PATH/pekwm_themeset.sh $_PEKWM_THEME_PATH" })."\n";
    $text .= q(            Entry { Actions = "Dynamic $_PEKWM_SCRIPT_PATH/pekwm_themeset.sh ~/.pekwm/themes" })."\n";
    $text .= q(            Entry { Actions = "Dynamic $_PEKWM_SCRIPT_PATH/pekwm_themeset.sh ~/.config/pekwm/themes" })."\n";
    $text .= q(        })."\n";
    $text .= q(        Submenu = "Window Managers" { ).$self->icon('gtk-quit')."\n";
    $text .= q(            Entry = "Blackbox" { ).$self->icon('blackbox').q(Actions = "RestartOther blackbox" })."\n";
    $text .= q(            Entry = "Fluxbox" { ).$self->icon('fluxbox').q(Actions = "RestartOther fluxbox" })."\n";
    $text .= q(            Entry = "FVWM" { ).$self->icon('fvwm').q(Actions = "RestartOther fvwm2" })."\n";
    $text .= q(            Entry = "IceWM" { ).$self->icon('icewm').q(Actions = "RestartOther icewm" })."\n";
    $text .= q(            Entry = "JWM" { ).$self->icon('archlinux-wm-jwm').q(Actions = "RestartOther jwm" })."\n";
    $text .= q(            Entry = "Openbox" { ).$self->icon('openbox').q(Actions = "RestartOther openbox" })."\n";
    $text .= q(            Entry = "TWM" { ).$self->icon('twm').q(Actions = "RestartOther twm" })."\n";
    $text .= q(            Entry = "WindowMaker" { ).$self->icon('wmaker').q(Actions = "RestartOther wmaker" })."\n";
    $text .= q(            Entry = "Terminal" { ).$self->icon('terminal').q(Actions = "RestartOther lxterminal" })."\n";
    $text .= q(            Separator {})."\n";
    $text .= q(            Entry = "Reload" { ).$self->icon('gtk-redo-ltr.png').q(Actions = "Reload" })."\n";
    $text .= q(            Entry = "Restart" { ).$self->icon('gtk-refresh').q(Actions = "Restart" })."\n";
    $text .= q(            Entry = "Exit" { ).$self->icon('gtk-quit').q(Actions = "Exit" })."\n";
    $text .= q(        })."\n";
    $text .= q(    })."\n";
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
    return sprintf "%sEntry = \"%s\" { Icon = \"%s\"; Actions = \"Exec %s\" }\n",
	   $indent, $name, $item->Icon([qw(png xpm jpg)]), $item->Exec;
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
