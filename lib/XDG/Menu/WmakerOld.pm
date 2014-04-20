package XDG::Menu::WmakerOld;
use base qw(XDG::Menu::Base);
use strict;
use warnings;

=head1 NAME

 XDG::Menu::WmakerOld - generate a WindowMaker menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menus/applications.menu');
 my $wmaker = new XDG::Menu::WmakerOld;
 print $wmaker->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::WmakerOld> is a module that reads an XDG::Menu::Layout tree
and generates a L<wmaker(1)> old-style menu.  This is no longer the
default for WindowMaker.

=head1 METHODS

B<XDG::Menu::WmakerOld> has the folllowing methods:

=over

=item $wmaker->B<create>($tree) => scalar

Creates the WindowMaker menu from menu tree, C<$tree>, and returns the menu
in a scalar string.  C<$tree> must have been created as the result of
parsing the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

=cut

sub create {
    my ($self,$item) = @_;
    my $text = '';
    $text .= "\"\N{BLACK CIRCLE} Root Menu\" MENU\n";
    $text .= "\"Run...\" SHEXEC \"%A(Run,Type Command:)\"\n";
    $text .= "\"Gvim\" SHORTCUT \"Control+Mod1+v\" SHEXEC \"gvim -geometry 120x142\"\n";
    $text .= "\"Gvim (wilbur)\" SHORTCUT \"Control+Shift+Mod1+v\" SHEXEC \"ssh -f wilbur gvim -geometry 120x100\"\n";
    $text .= "\"Rxvt\" SHORTCUT \"Control+Mod1+r\" SHEXEC \"rxvt -ls -fn 6x10 -fb 6x10 -geometry 120x116 -sl 10000 +sb\"\n";
    $text .= "\"Terminal\" SHORTCUT \"Control+Mod1+t\" SHEXEC \"xterm-wrapper\"\n";
    $text .= "\"XTerm\" SHORTCUT \"Control+Mod1+x\" SHEXEC \"xterm -ls -fn 6x10 -fb 6x10 -geometry 120x116 -sl 15000\"\n";
    $text .= "\"XTerm Tiny\" SHORTCUT \"Control+Mod1+s\" SHEXEC \"xterm -ls -fn -schumacher-clean-medium-r-normal--8-80-75-75-c-50-iso646.1991-irv -fb -schumacher-clean-medium-r-bold--8-80-75-75-c-50-iso646.1991-irv -geometry 146x145 -sl 15000\"\n";
    $text .= "\"XTerm Small\" SHORTCUT \"Control+Mod1+y\" SHEXEC \"xterm -ls -fn -schumacher-clean-medium-r-normal--8-80-75-75-c-60-iso646.1991-irv -fb -schumacher-clean-bold-r-normal--8-80-75-75-c-60-iso646.1991-irv -geometry 120x145 -sl 15000\"\n";
    $text .= "\"XTerm Large\" SHORTCUT \"Control+Mod1+l\" SHEXEC \"xterm -ls -fn 6x13 -fb 6x13bold -geometry 120x89 -sl 15000\"\n";
    $text .= "\"XTerm Big\" SHORTCUT \"Control+Mod1+b\" SHEXEC \"xterm -ls -fn 7x13 -fb 7x13bold -geometry 104x89 -sl 15000\"\n";
    $text .= "\"XTerm Huge\" SHORTCUT \"Control+Mod1+h\" SHEXEC \"xterm -ls -fn 9x15 -fb 9x15bold -geometry 81x77 -sl 15000\"\n";
    $text .= $self->build($item,' ');
    $text .= "\"\N{BLACK CIRCLE} Screen\" MENU\n";
    $text .= "  \"\N{BLACK CIRCLE} Locking\" MENU\n";
    $text .= "    \"Lock Screen (XScreenSaver)\" SHEXEC /usr/bin/xscreensaver-command -lock\n";
    $text .= "    \"Lock Screen (slock)\" SHEXEC /usr/bin/slock\n";
    $text .= "  \"\N{BLACK CIRCLE} Locking\" END\n";
    $text .= "  \"\N{BLACK CIRCLE} Saving\" MENU\n";
    $text .= "    \"Activate ScreenSaver (Next)\" SHEXEC /usr/bin/xscreensaver-command -next\n";
    $text .= "    \"Activate ScreenSaver (Prev)\" SHEXEC /usr/bin/xscreensaver-command -prev\n";
    $text .= "    \"Activate ScreenSaver (Rand)\" SHEXEC /usr/bin/xscreensaver-command -activate\n";
    $text .= "    \"Demo Screen Hacks\" SHEXEC /usr/bin/xscreensaver-command -demo\n";
    $text .= "    \"Disable XScreenSaver\" SHEXEC /usr/bin/xscreensaver-command -exit\n";
    $text .= "    \"Enable XScreenSaver\" SHEXEC /usr/bin/xscreensaver\n";
    $text .= "    \"Reinitialize XScreenSaver\" SHEXEC /usr/bin/xscreensaver-command -restart\n";
    $text .= "    \"ScreenSaver Preferences\" SHEXEC /usr/bin/xscreensaver-command -prefs\n";
    $text .= "  \"\N{BLACK CIRCLE} Saving\" END\n";
    $text .= "\"\N{BLACK CIRCLE} Screen\" END\n";
    $text .= "\"\N{BLACK CIRCLE} Window Maker\" MENU\n";
    $text .= "  \"Info Panel ...\" INFO_PANEL\n";
    $text .= "  \"Legal Panel ...\" LEGAL_PANEL\n";
    $text .= "  \"Preferences\" EXEC WPrefs\n";
    $text .= "  \"Refresh screen\" REFRESH\n";
    $text .= "  \"Restart\" RESTART\n";
    $text .= "\"\N{BLACK CIRCLE} Window Maker\" END\n";

# FIXME: we should get the list of window manager from the .desktop
# files in /usr/share/xsessions or just plain check for executability.

    $text .= "\"\N{BLACK CIRCLE} Window Managers\" MENU\n";
    $text .= "  \"Fluxbox\" RESTART /usr/bin/fluxbox\n";
    $text .= "  \"Blackbox\" RESTART /usr/bin/blackbox\n";
    $text .= "  \"Openbox\" RESTART /usr/bin/openbox\n";
    $text .= "  \"IceWM\" RESTART /usr/bin/icewm-session\n";
    $text .= "  \"Twm\" RESTART /usr/bin/twm\n";
    $text .= "  \"Window Maker\" RESTART /usr/bin/wmaker\n";
    $text .= "  \"XFwm\" RESTART /usr/bin/xfwm4\n";
    $text .= "  \"LXDE\" RESTART /usr/bin/startlxde\n";
    $text .= "\"\N{BLACK CIRCLE} Window Managers\" END\n";

    $text .= "\"\N{BLACK CIRCLE} WorkSpace\" MENU\n";
    $text .= "  \"Appearance\" OPEN_MENU appearance.menu\n";
    $text .= "  \"Arrange Icons\" ARRANGE_ICONS\n";
    $text .= "  \"Clear Session\" CLEAR_SESSION\n";
    $text .= "  \"Hide Others\" HIDE_OTHERS\n";
    $text .= "  \"Save Session\" SAVE_SESSION\n";
    $text .= "  \"Show All\" SHOW_ALL\n";
    $text .= "  \"Workspaces\" WORKSPACE_MENU\n";
    $text .= "\"\N{BLACK CIRCLE} WorkSpace\" END\n";
    $text .= "\"Exit\" EXIT\n";
    $text .= "\"Exit Session\" SHUTDOWN\n";
    $text .= "\"\N{BLACK CIRCLE} Root Menu\" END\n";
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
    return sprintf "%s\"%s\" SHEXEC %s\n",
        $indent, $item->Name, $item->Exec;
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $text = '';
    $text .= sprintf "%s\"\N{BLACK CIRCLE} %s\" MENU\n",
        $indent, $item->Name;
    $text .= $self->build($item->{Menu},$indent.'  ');
    $text .= sprintf "%s\"\N{BLACK CIRCLE} %s\" END\n",
        $indent, $item->Name;
    return $text;
}

1;

__END__

=head1 SEE ALSO

L<XDG::Menu(3pm)>,
L<XDG::Menu::Base(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
