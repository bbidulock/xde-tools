package XDG::Menu::Openbox3;
use base qw(XDG::Menu::Base);
use strict;
use warnings;

=head1 NAME

 XDG::Menu::Openbox3 - generate an Openbox menu from an XDG::Menu tree

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menus/applications.menu');
 my $openbox = new XDG::Menu::Openbox3;
 print $openbox->create($tree);

=head1 METHODS

B<XDG::Menu::Openbox> has the folllowing methods:

=over

=item $openbox->B<icon>(I<@names>) => I<$spec>

Accepts a list of icon names, I<@names>, as specified in a desktop entry
file and returns an icon specification that can be added to a menu
entry.

=cut

sub icon {
    my($self,@names) = @_;
    foreach (@names) {
	my $icon = $self->SUPER::icon($_,qw(png xpm jpg svg));
	return sprintf("icon=\"%s\" ",$icon) if $icon;
    }
    return '';
}

=item $openbox->B<create>(I<$tree>,I<$style>,I<$name>) => I<$menu>

Creates an L<openbox(1)> menu from menu tree, C<$tree>, and returns the
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
    $name =~ s{&}{&amp;}g;
    $self->{menus} = [];
    my $entries = $self->build($tree,'');
    push @{$self->{menus}},$self->appmenu($entries,$name);
    return $entries if $style eq 'entries';
    $entries = "  <menu id=\"$name Menu\" label=\"$name\" ".$self->icon('start-here')."/>\n"
	if $style eq 'submenu';
    push @{$self->{menus}},$self->rootmenu($entries,$name)
	if $style ne 'appmenu';
    my $menu = join("\n",@{$self->{menus}});
    return $self->makefile($menu);
}

=back

=cut

sub wmmenu {
    my $self = shift;
    my $text = '';
    $text .= "<menu id=\"Window Managers Menu\" label=\"Window Managers\" ".$self->icon('gtk-quit').">\n";
    $self->getenv();
    $self->default();
    my $wms = $self->get_xsesions();
    foreach (sort keys %$wms) {
	my $wm = $wms->{$_};
	my $name = $wm->{Name};
	$name = $_ unless $name;
	next if $name =~ m{openbox}i;
	my $exec = $wm->{Exec};
	my $icon = $self->icon($wm->{Icon});
	$icon = $self->icon('preferences-system-windows') if $icon eq '-';
	if ($self->{ops}{launch}) {
	    $exec = "$self->{ops}{launch} -X $wm->{id}";
	    $exec =~ s{\.desktop$}{};
	}
	$text .= "  <item label=\"$name\" $icon>\n";
	$text .= "    <action name=\"Restart\">\n";
	$text .= "      <command>$exec</command>\n";
	$text .= "    </action>\n";
	$text .= "  </item>\n";
    }
    $text .= "</menu>\n";
    return $text;
}

sub obmenu {
    my $self = shift;
    push @{$self->{menus}}, $self->wmmenu();
    my $text = '';
    $text .= "<menu id=\"Openbox\" label=\"Openbox\" ".$self->icon('openbox').">\n";
    $text .= "  <menu id=\"client-list-menu\" label=\"Desktops\" ".$self->icon('preferences-desktop-display')."/>\n";
    $text .= "  <menu id=\"client-list-combined-menu\" label=\"Windows\" ".$self->icon('preferences-system-windows')."/>\n";
    $text .= "  <menu id=\"Window Managers Menu\" label=\"Window Managers\" ".$self->icon('gtk-quit')."/>\n";
    $text .= "</menu>\n";
    return $text;
}

sub makefile {
    my($self,$menu) = @_;
    my $text = '';
    $text .= "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    $text .= "\n";
    $text .= "<openbox_menu xmlns=\"http://openbox.org/3.4/menu\">\n";
    $text .= "\n";
    $text .= $menu;
    $text .= "\n";
    $text .= "</openbox_menu>\n";
    return $text;
}
sub appmenu {
    my($self,$entries,$name) = @_;
    my $text = '';
    $text .= "<menu id=\"$name Menu\" label=\"$name\" ".$self->icon('start-here').">\n";
    $text .= $entries;
    $text .= "</menu>\n";
    return $text;
}

sub rootmenu {
    my($self,$entries,$name) = @_;
    push @{$self->{menus}}, $self->obmenu();
    my $text = '';
    $text .= "<menu id=\"root-menu\" label=\"Openbox 3\">\n";
    $text .= $entries;
    $text .= "  <separator />\n";
    $text .= "  <menu id=\"Openbox\" label=\"Openbox\" ".$self->icon('openbox')."/>\n";
    if ($self->{ops}{output}) {
	$text .= "  <item label=\"Refresh Menu\" ".$self->icon('gtk-refresh').">\n";
	$text .= "    <action name=\"Execute\">\n";
	$text .= "      <command>xdg-menugen -format openbox3 -desktop OPENBOX -launch -o $self->{ops}{output}</command>\n";
	$text .= "    </action>\n";
	$text .= "  </item>\n";
    }
    $text .= "  <item label=\"Reload\" ".$self->icon('gtk-redo-ltr').">\n";
    $text .= "    <action name=\"Reconfigure\" />\n";
    $text .= "  </item>\n";
    $text .= "  <item label=\"Restart\" ".$self->icon('gtk-refresh').">\n";
    $text .= "    <action name=\"Restart\" />\n";
    $text .= "  </item>\n";
    $text .= "  <separator />\n";
    $text .= "  <item label=\"Exit\" ".$self->icon('gtk-quit').">\n";
    $text .= "    <action name=\"Exit\" />\n";
    $text .= "  </item>\n";
    $text .= "</menu>\n";
    return $text;
}
sub build {
    my ($self,$item,$indent) = @_;
    my $name = ref($item);
    $name =~ s{.*\:\:}{};
    return $self->$name($item,$indent) if $self->can($name);
    return '';
}

# Creation of the openbox XML menu is quite different from other menus
# because menu definitions are not nested.  Each menu is defined in a
# list (from deepest to shallowest).  Menus that contain other menus are
# referred to by name rather than being nested in the superior menu's
# definition.  So, what we need to do is stack the definitions as we go
# down and then spit them out as we come back up.

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
    return sprintf "%s<separator label=\"%s\" icon=\"%s\" />\n",
	   $indent, $item->Name, $item->Icon([qw(png xpm)]);
}
sub Separator {
    my ($self,$item,$indent) = @_;
    return sprintf "%s<separator />\n",
	   $indent;
}
sub Application {
    my ($self,$item,$indent) = @_;
    my $text = '';
    $text .= sprintf "%s<item label=\"%s\" icon=\"%s\">\n",
	$indent, $item->Name, $item->Icon([qw(png xpm)]);
    $text .= sprintf "%s  <action name=\"Execute\">\n",
	$indent;
    $text .= sprintf "%s    <command>%s</command>\n",
	$indent, $item->Exec;
    if ($item->StartupNotify eq 'yes' or $item->StartupWMClass) {
	$text .= sprintf "%s    <startupnotify>\n",
	    $indent;
	if ($item->StartupNotify eq 'yes') {
	    $text .= sprintf "%s      <enabled>%s</enabled>\n",
		$indent, $item->StartupNotify;
	}
	if ($item->StartupWMClass) {
	    $text .= sprintf "%s      <wmclass>%s</wmclass>\n",
		$indent, $item->StartupWMClass;
	}
	$text .= sprintf "%s      <name>%s</name>\n",
	    $indent, $item->Name;
	$text .= sprintf "%s      <icon>%s</icon>\n",
	    $indent, $item->Icon([qw(png xpm)]);
	$text .= sprintf "%s    </startupnotify>\n",
	    $indent;
    }
    $text .= sprintf "%s  </action>\n",
	$indent;
    $text .= sprintf "%s</item>\n",
	$indent;
    return $text;
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $menu = $item->{Menu};
    my $text = '';
    # no empty menus...
    return $text unless @{$menu->{Elements}};
    my $label = $item->Name;
    $label =~ s{&}{&amp;}g;
    my $id = $label." Menu";
    my $icon = $item->Icon([qw(png svg xpm)]);
    $text .= sprintf "<menu id=\"%s\" label=\"%s\" icon=\"%s\">\n",$id,$label,$icon;
    $text .= $self->build($item->{Menu},'');
    $text .= sprintf "</menu> <!-- %s -->\n",$id;
    push @{$self->{menus}}, $text;
    return sprintf "%s<menu id=\"%s\" label=\"%s\" icon=\"%s\"/>\n",$indent,$id,$label,$icon;
}

1;

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
