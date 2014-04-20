package XDG::Menu::Wmaker;
use base qw(XDG::Menu::Base);
use strict;
use warnings;

=head1 NAME

 XDG::Menu::Wmaker - generate a WindowMaker menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menus/applications.menu');
 my $wmaker = new XDG::Menu::Wmaker;
 print $wmaker->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Wmaker> is a module that reads an XDG::Menu::Layout tree
and generates a L<wmaker(1)> new-style properties list menu.  This is
now the default for WindowMaker.

=head1 METHODS

B<XDG::Menu::Wmaker> has the folllowing methods:

=over

=item $wmaker->B<create>(I<$tree>,I<$style>,I<$name>) => I<$menu>

Creates the WindowMaker menu from menu tree, C<$tree>, and returns the menu
in a scalar string, I<$menu>.  C<$tree> must have been created as the
result of parsing the XDG menu using XDG::Menu::Parser (see
L<XDG::Menu(3pm)>).

I<$style>, which defaults to C<fullmenu>, is the style menu to create as
follows:

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

When the applications menu entries are creates as a submenu of the root
menu or a menu of its own, the submenu will be given the name, I<$name>.
I<$name>, when unspecified, defaults to C<Applications>.

=cut

sub create {
    my($self,$tree,$style,$name) = @_;
    $style = 'fullmenu' unless $style;
    $name = 'Applications' unless $name;
    my $menu = $self->build($tree,'');
    return $menu if $style eq 'entries';
    $menu = $self->appmenu($menu,$name) unless $style eq 'fullmenu';
    $menu = $self->rootmenu($menu,$name) unless $style eq 'appmenu';
    return $menu;
}

=back

=cut

sub wmmenu {
    my ($self,$indent) = @_;
    my $text = '';
    $text .= ",\n";
    $text .= $indent."(\n";
    $text .= $indent."  \"\N{BLACK CIRCLE} Window Managers\",\n";
    $text .= $indent."  (\"Restart\", RESTART)";
    $self->getenv();
    $self->default();
    my $wms = $self->get_xsessions();
    foreach (sort keys %$wms) {
	my $wm = $wms->{$_};
	my $name = $wm->{Name};
	$name = $_ unless $name;
	$name =~ s{\\}{\\\\}g;
	$name =~ s{"}{\\"}g;
	next if $name =~ m{wmaker|windowmaker}i;
	my $exec = $wm->{Exec};
	$exec =~ s{\\}{\\\\}g;
	$exec =~ s{"}{\\"}g;
	$text .= ",\n";
	$text .= "$indent  (\"Start $name\", RESTART, \"$exec\")";
    }
    $text .= "\n";
    $text .= $indent.")";
    return $text;
}

sub appmenu {
    my($self,$entries,$name) = @_;
    my $text = '';
    $text .= "(\n";
    $text .= "  \"\N{BLACK CIRCLE} $name\"";
    $text .= $entries;
    $text .= "\n";
    $text .= ")\n";
    return $text;
}

sub rootmenu {
    my($self,$entries) = @_;
    my $GDIR = $ENV{GNUSTEP_USER_ROOT};
    $GDIR = '$HOME/GNUstep' unless $GDIR;
    my $text = '';
    $text .= "(\n";
    $text .= "  \"\N{BLACK CIRCLE} Window Maker\"";
    $text .= $entries;
    $text .= ",\n";
    $text .= "  (\n";
    $text .= "    \"\N{BLACK CIRCLE} Screen\",\n";
    $text .= "    (\n";
    $text .= "      \"\N{BLACK CIRCLE} Locking\",\n";
    $text .= "      (\"Lock Screen (XScreenSaver)\", SHEXEC, \"/usr/bin/screensaver-command -lock\"),\n";
    $text .= "      (\"Lock Screen (slock)\", SHEXEC, \"/usr/bin/slock\")\n";
    $text .= "    ),\n";
    $text .= "    (\n";
    $text .= "      \"\N{BLACK CIRCLE} Saving\",\n";
    $text .= "      (\"Activate ScreenSaver (Next)\", SHEXEC, \"/usr/bin/screensaver-command -next\"),\n";
    $text .= "      (\"Activate ScreenSaver (Prev)\", SHEXEC, \"/usr/bin/screensaver-command -prev\"),\n";
    $text .= "      (\"Activate ScreenSaver (Rand)\", SHEXEC, \"/usr/bin/screensaver-command -activate\"),\n";
    $text .= "      (\"Demo Screen Hacks\", SHEXEC, \"/usr/bin/xscreensaver-command -demo\"),\n";
    $text .= "      (\"Disable XScreenSaver\", SHEXEC, \"/usr/bin/xscreensaver-command -exit\"),\n";
    $text .= "      (\"Enable XScreenSaver\", SHEXEC, \"/usr/bin/xscreensaver\"),\n";
    $text .= "      (\"Reinitialize XScreenSaver\", SHEXEC, \"/usr/bin/xscreensaver-command -restart\"),\n";
    $text .= "      (\"ScreenSaver Preferences\", SHEXEC, \"/usr/bin/xscreensaver-command -prefs\")\n";
    $text .= "    )\n";
    $text .= "  ),\n";
    $text .= "  (\n";
    $text .= "    \"\N{BLACK CIRCLE} Window Maker\",\n";
    $text .= "    (\"Info Panel\", INFO_PANEL),\n";
    $text .= "    (\"Legal Panel\", LEGAL_PANEL),\n";
    $text .= "    (\"Preferences\", EXEC, /usr/lib/GNUstep/Applications/WPrefs.app/WPrefs),\n";
    $text .= "    (\"Refresh Screen\", REFRESH),\n";
    $text .= "    (\"Restart\", RESTART)\n";
    $text .= "  )";
    $text .= $self->wmmenu('  ');
    $text .= ",\n";
    $text .= "  (\n";
    $text .= "    \"\N{BLACK CIRCLE} WorkSpace\",\n";
    $text .= "    (\n";
    $text .= "      \"\N{BLACK CIRCLE} Appearance\",\n";
    $text .= "      (\n";
    $text .= "        \"\N{BLACK CIRCLE} Background\",\n";
    $text .= "        (\n";
    $text .= "          \"\N{BLACK CIRCLE} Solid\",\n";
    $text .= "          (\"Black\",         EXEC, \"wdwrite WindowMaker WorkspaceBack '(solid, \\\"black\\\"  )'\"),\n";
    $text .= "          (\"Blue\",          EXEC, \"wdwrite WindowMaker WorkspaceBack '(solid, \\\"#505075\\\")'\"),\n";
    $text .= "          (\"Indigo\",        EXEC, \"wdwrite WindowMaker WorkspaceBack '(solid, \\\"#243e6c\\\")'\"),\n";
    $text .= "          (\"Deep Blue\",     EXEC, \"wdwrite WindowMaker WorkspaceBack '(solid, \\\"#180090\\\")'\"),\n";
    $text .= "          (\"Purple\",        EXEC, \"wdwrite WindowMaker WorkspaceBack '(solid, \\\"#554466\\\")'\"),\n";
    $text .= "          (\"Wheat\",         EXEC, \"wdwrite WindowMaker WorkspaceBack '(solid, \\\"wheat4\\\" )'\"),\n";
    $text .= "          (\"Dark Gray\",     EXEC, \"wdwrite WindowMaker WorkspaceBack '(solid, \\\"#333340\\\")'\"),\n";
    $text .= "          (\"Wine\",          EXEC, \"wdwrite WindowMaker WorkspaceBack '(solid, \\\"#400020\\\")'\")\n";
    $text .= "        ),\n";
    $text .= "        (\n";
    $text .= "          \"\N{BLACK CIRCLE} Gradient\",\n";
    $text .= "          (\"Sunset\",        EXEC, \"wdwrite WindowMaker WorkspaceBack '(mvgradient, deepskyblue4, black deepskyblue4, tomato4)'\"),\n";
    $text .= "          (\"Sky\",           EXEC, \"wdwrite WindowMaker WorkspaceBack '(vgradient, blue4, white)'\"),\n";
    $text .= "          (\"Blue Shades\",   EXEC, \"wdwrite WindowMaker WorkspaceBack '(vgradient, \\\"#7080a5\\\", \\\"#101020\\\")'\"),\n";
    $text .= "          (\"Indigo Shades\", EXEC, \"wdwrite WindowMaker WorkspaceBack '(vgradient, \\\"#746ebc\\\", \\\"#242e4c\\\")'\"),\n";
    $text .= "          (\"Purple Shades\", EXEC, \"wdwrite WindowMaker WorkspaceBack '(vgradient, \\\"#654c66\\\", \\\"#151426\\\")'\"),\n";
    $text .= "          (\"Wheat Shades\",  EXEC, \"wdwrite WindowMaker WorkspaceBack '(vgradient, \\\"#a09060\\\", \\\"#302010\\\")'\"),\n";
    $text .= "          (\"Grey Shades\",   EXEC, \"wdwrite WindowMaker WorkspaceBack '(vgradient, \\\"#636380\\\", \\\"#131318\\\")'\"),\n";
    $text .= "          (\"Wine Shades\",   EXEC, \"wdwrite WindowMaker WorkspaceBack '(vgradient, \\\"#600050\\\", \\\"#180010\\\")'\")\n";
    $text .= "        ),\n";
    $text .= "        (\n";
    $text .= "          \"\N{BLACK CIRCLE} Images\",\n";
    $text .= "          (\n";
    $text .= "            \"\N{BLACK CIRCLE} Tiled\",\n";
    $text .= "            OPEN_MENU,\n";
    $text .= "            \"-noext /usr/share/WindowMaker/Backgrounds $GDIR/Library/WindowMaker/Backgrounds WITH wmsetbg -u -t\"\n";
    $text .= "          ),\n";
    $text .= "          (\n";
    $text .= "            \"\N{BLACK CIRCLE} Scaled\",\n";
    $text .= "            OPEN_MENU,\n";
    $text .= "            \"-noext /usr/share/WindowMaker/Backgrounds $GDIR/Library/WindowMaker/Backgrounds WITH wmsetbg -u -s\"\n";
    $text .= "          )\n";
    $text .= "        )\n";
    $text .= "      ),\n";
    $text .= "      (\n";
    $text .= "        \"\N{BLACK CIRCLE} Styles\",\n";
    $text .= "        OPEN_MENU,\n";
    $text .= "        \"-noext /usr/share/WindowMaker/Styles $GDIR/Library/WindowMaker/Styles WITH setstyle\"\n";
    $text .= "      ),\n";
    $text .= "      (\n";
    $text .= "        \"\N{BLACK CIRCLE} Themes\",\n";
    $text .= "        OPEN_MENU,\n";
    $text .= "        \"-noext /usr/share/WindowMaker/Themes $GDIR/Library/WindowMaker/Themes WITH setstyle\"\n";
    $text .= "      ),\n";
    $text .= "      (\n";
    $text .= "        \"\N{BLACK CIRCLE} Icon Sets\",\n";
    $text .= "        OPEN_MENU,\n";
    $text .= "        \"-noext /usr/share/WindowMaker/IconSets $GDIR/Library/WindowMaker/IconSets WITH seticons\"\n";
    $text .= "      ),\n";
    $text .= "      (\"Save Theme\", EXEC, \"getstyle -p \\\"%a(Theme name, Name to save theme as)\\\"\"),\n";
    $text .= "      (\"Save IconSet\", SHEXEC, \"geticonset $GDIR/Library/WindowMaker/IconSets/\\\"%a(IconSet name,Name to save iconset as)\\\"\")\n";
    $text .= "    ),\n";
    $text .= "    (\"Arrange Icons\", ARRANGE_ICONS),\n";
    $text .= "    (\"Clear Session\", CLEAR_SESSION),\n";
    $text .= "    (\"Hide Others\", HIDE_OTHERS),\n";
    $text .= "    (\"Save Session\", SAVE_SESSION),\n";
    $text .= "    (\"Show All\", SHOW_ALL),\n";
    $text .= "    (\"\N{BLACK CIRCLE} Workspaces\", WORKSPACE_MENU)\n";
    $text .= "  ),\n";
    $text .= "  (\"Exit\", EXIT),\n";
    $text .= "  (\"Exit Session\", SHUTDOWN)\n";
    $text .= ")\n";
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
    return '';
}
sub Separator {
    my ($self,$item,$indent) = @_;
    return '';
}
sub Application {
    my ($self,$item,$indent) = @_;
    my $name = $item->Name;
    $name =~ s{\\}{\\\\}g;
    $name =~ s{"}{\\"}g;
    my $exec = $item->Exec;
    $exec =~ s{\\}{\\\\}g;
    $exec =~ s{"}{\\"}g;
    my $text = '';
    $text .= ",\n";
    $text .= "$indent(\"$name\", SHEXEC, \"$exec\")";
    return $text;
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $menu = $item->{Menu};
    my $text = '';
    # no empty menus...
    return $text unless @{$menu->{Elements}};
    my $name = $item->Name;
    $name =~ s{\\}{\\\\}g;
    $name =~ s{"}{\\"}g;
    $text .= ",\n";
    $text .= "$indent(\n";
    $text .= "$indent  \"\N{BLACK CIRCLE} $name\"";
    $text .= $self->build($item->{Menu},$indent);
    $text .= "\n";
    $text .= "$indent)";
    return $text;
}

1;

__END__

=head1 SEE ALSO

L<XDG::Menu(3pm)>,
L<XDG::Menu::Base(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
