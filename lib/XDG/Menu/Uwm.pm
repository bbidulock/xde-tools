package XDG::Menu::Uwm;
use base qw(XDG::Menu::Base);
use strict;
use warnings;

=head1 NAME

XDG::Menu::Uwm - generate μwm menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menu/applications.menu');
 my $uwm = new XDG::Menu::Uwm;
 print $uwm->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Uwm> is a module that reads an XDG::Menu::Layout tree and
generates a μwm syle menu.

=head1 METHODS

B<XDG::Menu::Uwm> has the following methods:

=over

=item $uwm->B<icon>(I<@names>) => I<$spec>

Accepts a list of icon names, I<@names>, as specified in a desktop entry
file and returns an icon specification that can be added to a menu
entry.

=cut

sub icon {
    my($self,@names) = @_;
    foreach (@names) {
	my $icon = $self->SUPER::icon($_,qw(png svg xpm));
	return sprintf("icon = \"%s\" ",$icon) if $icon;
    }
    return '';
}

=item $uwm->B<create>(I<$tree>,I<$style>,I<$name>) => I<$menu>

Creates a L<uwm(1)> menu from menu tree, I<$tree>, and returns the menu
in a scalar string, I<$menu>. I<$tree> must have been created as the
result of parsing the XDG menu using XDG::Menu::Parser (see
L<XDG::Menu(3pm)>).

I<$style>, which defaults to C<fullmenu>, is the style of the menu to
create as follows:

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
    my $menu = $self->build($tree,'  ');
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
    $text .= sprintf "%s%s\n", $indent, '[ '.$self->icon('gtk-quit').' text = "Window Managers" menu = [';
    $text .= sprintf "%s%s\n", $indent, '  label = "Window Managers"'; 
    $text .= sprintf "%s%s\n", $indent, ' [ '.$self->icon('gtk-refresh').' text = "Restart" restart = true ]';
    $self->getenv();
    $self->default();
    my $wms = $self->get_xsessions();
    foreach (sort keys %$wms) {
	my $wm = $wms->{$_};
	my $name = $wm->{Name}; $name =~ s{"}{\\"}g;
	next if $name =~ m{[uμμ]wm}i;
	my $exec = $wm->{Exec}; $exec =~ s{"}{\\"}g;
	my $icon = $self->icon($wm->{Icon});
	$icon = $self->icon('preferences-desktop-display') unless $icon;
	$text .= sprintf "%s  [%s text = \"%s\" exit = \"%s\" ]\n",
	    $indent, $icon, $name, $exec;
    }
    $text .= sprintf "%s%s\n", $indent, '  ] ; menu Window Managers';
    $text .= sprintf "%s%s\n", $indent, ']';
    return $text;
}

sub appmenu {
    my($self,$entries,$name) = @_;
    my $indent = '    ';
    my $text = '';
    $name =~ s{"}{\\"}g;
    $text .= sprintf "%s[ %stext = \"%s\" menu = [\n", $indent, $self->icon(qw(start-here folder)), $name;
    $text .= sprintf "%s  label = \"%s\"\n", $indent, $name;
    $text .= $entries;
    $text .= sprintf "%s  ] ; menu %s\n", $indent, $name;
    $text .= sprintf "%s]\n", $indent;
    return $text;
}

sub rootmenu {
    my($self,$entries) = @_;
    my $text = '';
    my $indent = '';
    $text .= sprintf "%s\n", 'root-menu = [';
    $text .= sprintf "%s\n", '  opacity = 1.0';
    $text .= sprintf "%s\n", '  [0] = [';
    $text .= sprintf "%s\n", '    label = "μWM " ~ UWM-VERSION';
    $text .= sprintf "%s\n", '    height = 18';
    $text .= $entries;
    $text .= sprintf "%s\n", '    [ separator = true ]';
    $text .= sprintf "%s\n", '    [ icon = "uwm16x16.xpm" text = "μWM Menu" menu = [';
    $text .= sprintf "%s\n", '      label = "μWM Menu"';
    $text .= $self->wmmenu('      ');
    $text .= sprintf "%s\n", '      ] ; μWM menu';
    $text .= sprintf "%s\n", '    ]';
    $text .= sprintf "%s\n", '    [ '.$self->icon('gtk-refresh').' text = "Restart" restart = true ]';
    $text .= sprintf "%s\n", '    [ '.$self->icon('gtk-quit').' text = "Exit" exit = true ]';
    $text .= sprintf "%s\n", '    ';
    $text .= sprintf "%s\n", '  ] ; 0';
    $text .= sprintf "%s\n", '] ; root-menu';
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
	    $text .= $self->build($_,$indent.'  ');
	}
    }
    return $text;
}

sub Header {
    my ($self,$item,$indent) = @_;
    my $text = '';
    my $name = $item->Name; $name =~ s{"}{\\"}g;
    my $icon = $item->Icon([qw(png svg xpm)]);
    $icon = "icon = \"$icon\" " if $icon;
    $icon = '' unless $icon;
    $text .= sprintf "%s\n", $icon if $icon;
    $text .= sprintf "label = \"%s\"\n", $name if $name;
    return $text;
}

sub Separator {
    my ($self,$item,$indent) = @_;
    return sprintf "%s[ separator = true ]\n", $indent;
}

sub Application {
    my ($self,$item,$indent) = @_;
    my $name = $item->Name; $name =~ s{"}{\\"}g;
    my $icon = $item->Icon([qw(png svg xpm)]);
    $icon = "icon = \"$icon\" " if $icon;
    $icon = '' unless $icon;
    if ($self->{ops}{launch}) {
	return sprintf "%s[ %stext = \"%s\" execute = \"xdg-launch %s\" ]\n",
	       $indent, $icon, $name, $item->Id;
    } else {
	my $exec = $item->Exec; $exec =~ s{"}{\\"}g;
	return sprintf "%s[ %stext = \"%s\" execute = \"%s\" ]\n",
	       $indent, $icon, $name, $exec;
    }
}

sub Directory {
    my ($self,$item,$indent) = @_;
    my $menu = $item->{Menu};
    my $text = '';
    # no empty menus...
    return $text unless @{$menu->{Elements}};
    my $name = $item->Name; $name =~ s{"}{\\"}g;
    my $icon = $item->Icon([qw(png svg xpm)]);
    $icon = "icon = \"$icon\" " if $icon;
    $icon = '' unless $icon;
    $text .= sprintf "%s[ %stext = \"%s\" menu = [\n",
	$indent, $icon, $name;
    $text .= $self->build($item->{Menu},$indent.'  ');
    $text .= sprintf "%s    ] ; menu %s\n", $indent, $name;
    $text .= sprintf "%s]\n", $indent;
    return $text;
}

1;

__END__

=head1 SEE ALSO

L<XDG::Menu(3pm)>,
L<XDG::Menu::Base(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
