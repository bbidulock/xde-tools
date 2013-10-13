package XDG::Menu::Openbox3;
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

=item XDG::Menu::Openbox3->B<new>($tree) => XDG::Menu::Openbox3

Creates a new XDG::Menu::Openbox3 instance for creating Openbox XML menus.

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
    my $fn = $icons->FindIcon($name,16,[qw(png xpm jpg)]);
    $fn = '' unless $fn;
    return sprintf("icon=\"%s\" ", $fn);
}

=item $openbox->B<create>($tree) => scalar

Creates the Openbox menu from menu tree, C<$tree>, and returns the menu
in a scalar string.  C<$tree> must have been created as the result of
parsing the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

=cut

sub create {
    my ($self,$item) = @_;
    my $text = '';
    $text .= "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    $text .= "\n";
    $text .= "<openbox_menu xmlns=\"http://openbox.org/3.4/menu\">\n";
    $text .= "\n";
    $text .= "<menu id=\"root-menu\" label=\"Openbox 3\">\n";
    $text .= $self->build($item,'  ');
    $text .= "  <separator />\n";
    $text .= "  <menu id=\"Openbox\" label=\"Openbox\" ".$self->icon('openbox').">\n";
    $text .= "    <menu id=\"client-list-menu\" label=\"Desktops\" ".$self->icon('preferences-desktop-display')."/>\n";
    $text .= "    <menu id=\"client-list-combined-menu\" label=\"Windows\" ".$self->icon('preferences-system-windows')."/>\n";
    $text .= "    <menu id=\"Window Managers\" label=\"Window Managers\" ".$self->icon('gtk-quit').">\n";
    $text .= "      <item label=\"Blackbox\" ".$self->icon('blackbox').">\n";
    $text .= "        <action name=\"Restart\">\n";
    $text .= "          <command>blackbox</command>\n";
    $text .= "        </action>\n";
    $text .= "      </item>\n";
    $text .= "      <item label=\"Fluxbox\" ".$self->icon('fluxbox').">\n";
    $text .= "        <action name=\"Restart\">\n";
    $text .= "          <command>fluxbox</command>\n";
    $text .= "        </action>\n";
    $text .= "      </item>\n";
    $text .= "      <item label=\"FVWM\" ".$self->icon('fvwm').">\n";
    $text .= "        <action name=\"Restart\">\n";
    $text .= "          <command>fvwm2</command>\n";
    $text .= "        </action>\n";
    $text .= "      </item>\n";
    $text .= "      <item label=\"IceWM\" ".$self->icon('icewm').">\n";
    $text .= "        <action name=\"Restart\">\n";
    $text .= "          <command>icewm</command>\n";
    $text .= "        </action>\n";
    $text .= "      </item>\n";
    $text .= "      <item label=\"JWM\" ".$self->icon('archlinux-wm-jwm').">\n";
    $text .= "        <action name=\"Restart\">\n";
    $text .= "          <command>jwm</command>\n";
    $text .= "        </action>\n";
    $text .= "      </item>\n";
    $text .= "      <item label=\"Openbox\" ".$self->icon('openbox').">\n";
    $text .= "        <action name=\"Restart\">\n";
    $text .= "          <command>openbox</command>\n";
    $text .= "        </action>\n";
    $text .= "      </item>\n";
    $text .= "      <item label=\"TWM\" ".$self->icon('twm').">\n";
    $text .= "        <action name=\"Restart\">\n";
    $text .= "          <command>twm</command>\n";
    $text .= "        </action>\n";
    $text .= "      </item>\n";
    $text .= "      <item label=\"WindowMaker\" ".$self->icon('wmaker').">\n";
    $text .= "        <action name=\"Restart\">\n";
    $text .= "          <command>wmaker</command>\n";
    $text .= "        </action>\n";
    $text .= "      </item>\n";
    $text .= "      <item label=\"Terminal\" ".$self->icon('terminal').">\n";
    $text .= "        <action name=\"Restart\">\n";
    $text .= "          <command>roxterm-</command>\n";
    $text .= "        </action>\n";
    $text .= "      </item>\n";
    $text .= "      <separator />\n";
    $text .= "      <item label=\"Reload\" ".$self->icon('gtk-redo-ltr').">\n";
    $text .= "        <action name=\"Reconfigure\" />\n";
    $text .= "      </item>\n";
    $text .= "      <item label=\"Restart\" ".$self->icon('gtk-refresh').">\n";
    $text .= "        <action name=\"Restart\" />\n";
    $text .= "      </item>\n";
    $text .= "      <item label=\"Exit\" ".$self->icon('gtk-quit').">\n";
    $text .= "        <action name=\"Exit\" />\n";
    $text .= "      </item>\n";
    $text .= "    </menu>\n";
    $text .= "  </menu>\n";
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
    $text .= "\n";
    $text .= "</openbox_menu>\n";
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
    $text .= sprintf "%s<menu id=\"%s\" label=\"%s\" icon=\"%s\">\n",
	$indent, $item->Name." Menu", $item->Name,
	$item->Icon([qw(png xpm)]);
    $text .= $self->build($item->{Menu},$indent.'  ');
    $text .= sprintf "%s</menu> <!-- %s -->\n",
	$indent, $item->Name;
    return $text;
}

1;

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut


