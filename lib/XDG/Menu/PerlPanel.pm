package XDG::Menu::PerlPanel;
use base qw(XDG::Menu::Base);
use strict;
use warnings;

=head1 NAME

XDG::Menu::PerlPanel - generate a PerlPanel menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menus/applications.menu');
 my $panel = new XDG::Menu::PerlPanel;
 print $panel->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::PerlPanel> is a module that reads an XDG::Menu::Layout tree
and generates a perlpanel style menu.

=head1 METHODS

B<XDG::Menu::PerlPanel> has the following methods:

=over

=item $panel->B<icon>(I<@names>) => I<$spec>

Accepts a list of icon names, I<@names>, as specified in a desktop entry
file and returns an icon specification that can be added to a menu
entry.

=cut

sub icon {
    my($self,@names) = @_;
    foreach (@names) {
	my $icon = $self->SUPER::icon($_,qw(png xpm svg jpg));
	return sprintf(" <%s>",$icon) if $icon;
    }
    return '';
}

=item $panel->B<create>(I<$tree>,I<$style>,I<$name>) => I<$menu>

Creates the L<perlpanel(1)> menu from menu tree, C<$tree>, and returns the
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
    $text .= sprintf "%s%s\n", $indent, '[submenu] (Window Managers) {Window Managers}'.$self->icon('gtk-quit');
    $text .= sprintf "%s%s\n", $indent, '  [restart] (Restart)'.$self->icon('gtk-refresh');
    $self->getenv();
    $self->default();
    my $wms = $self->get_xsessions();
    foreach (sort keys %$wms) {
	my $wm = $wms->{$_};
	my $name = $wm->{Name};
	$name = $_ unless $name;
	next if $name =~ m{fluxbox}i;
	my $exec = $wm->{Exec};
	my $icon = $self->icon($wm->{Icon});
	$icon = $self->icon('preferences-system-windows') unless $icon;
	if ($self->{ops}{launch}) {
	    $exec = "$self->{ops}{launch} -X $wm->{id}";
	    $exec =~ s{\.desktop$}{};
	}
	$text .= sprintf("%s  [restart] (Start %s) {%s}%s\n",$indent,$name,$exec,$icon);
    }
    $text .= sprintf "%s%s\n", $indent, '[end] # (Window Managers)';
    return $text;
}

sub appmenu {
    my($self,$entries,$name) = @_;
    my $text = '';
    $text .= sprintf "[submenu] (%s) {%s}%s\n", $name, $name,
	$self->icon(qw(start-here folder));
    $text .= $entries;
    $text .= sprintf "[end] # (%s)\n", $name;
    return $text;
}
sub rootmenu {
    my($self,$entries) = @_;
    my $text = '';
    $text .= sprintf "%s\n", '[begin] (Fluxbox)';
    $text .= sprintf "%s\n", '[encoding] {UTF-8}';
    $text .= $entries;
    $text .= sprintf "%s\n", '  [separator]';
    $text .= sprintf "%s\n", '  [submenu] (Fluxbox menu)'.$self->icon('fluxbox');
    $text .= sprintf "%s\n", '    [config] (Configure)'.$self->icon('preferences-desktop');
    $text .= sprintf "%s\n", '    [submenu] (System Styles) {Choose a style...}'.$self->icon('style');
    $text .= sprintf "%s\n", '      [stylesdir] (/usr/share/fluxbox/styles)';
    $text .= sprintf "%s\n", '    [end] # (System Styles)';
    $text .= sprintf "%s\n", '    [submenu] (User Styles) {Choose a style...}'.$self->icon('style');
    $text .= sprintf "%s\n", '      [stylesdir] (~/.fluxbox/styles)';
    $text .= sprintf "%s\n", '      [stylesdir] (~/.config/fluxbox/styles)';
    $text .= sprintf "%s\n", '    [end] # (User Styles)';
    $text .= sprintf "%s\n", '    [submenu] (Backgrounds) {Set the Background}';
    $text .= sprintf "%s\n", '      [exec] (Random Background) {fbsetbg -r /usr/share/fluxbox/backgrounds}';
    $text .= sprintf "%s\n", '    [end]';
    $text .= sprintf "%s\n", '    [workspaces] (Workspace List)'.$self->icon('preferences-desktop-display');
    $text .= sprintf "%s\n", '    [submenu] (Tools)'.$self->icon('applications-utilities');
    $text .= sprintf "%s\n", '      [exec] (Window name) {xprop WM_CLASS|cut -d \" -f 2|gxmessage -file - -center}';
    $text .= sprintf "%s\n", '      [exec] (Screenshot - JPG) {import screenshot.jpg && display -resize 50% screenshot.jpg}'.$self->icon('applets-screenshooter');
    $text .= sprintf "%s\n", '      [exec] (Screenshot - PNG) {import screenshot.png && display -resize 50% screenshot.png}'.$self->icon('applets-screenshooter');
    $text .= sprintf "%s\n", '      [exec] (Run) {fbrun -font 10x20 -fg grey -bg black -title run}'.$self->icon('gtk-execute');
    $text .= sprintf "%s\n", '      [exec] (Run Command) {bbrun -a -w}'.$self->icon('gtk-execute');
    $text .= sprintf "%s\n", '    [end]';
    $text .= sprintf "%s\n", '    [submenu] (Arrange Windows)'.$self->icon('preferences-system-windows');
    $text .= sprintf "%s\n", '      [arrangewindows] (Arrange Windows)';
    $text .= sprintf "%s\n", '      [arrangewindowshorizontal] (Arrange Windows Horizontal)';
    $text .= sprintf "%s\n", '      [arrangewindowsvertical] (Arrange Windows Vertical)';
    $text .= sprintf "%s\n", '    [end]';
    $text .= $self->wmmenu('    ');
    $text .= sprintf "%s\n", '  [end] # (Fluxbox menu)';
    $text .= sprintf "%s\n", '  [exec] (Lock screen) {xlock}'.$self->icon('gnome-lockscreen');
    $text .= sprintf "%s\n", '  [commanddialog] (Fluxbox Command)'.$self->icon('gtk-execute');
    $text .= sprintf "%s\n", '  [exec] (Refresh Menu) {xdg-menugen -format perlpanel -launch -o '.$self->{ops}{output}.' }'.$self->icon('gtk-refresh')
	if $self->{ops}{output};
    $text .= sprintf "%s\n", '  [reconfig] (Reload config)'.$self->icon('gtk-redo-ltr');
    $text .= sprintf "%s\n", '  [restart] (Restart) {}'.$self->icon('gtk-refresh');
    $text .= sprintf "%s\n", '  [exec] (About) {(fluxbox -v; fluxbox -info | sed 1d) | gxmessage -file - -center}'.$self->icon('help-about');
    $text .= sprintf "%s\n", '  [exec] (Refresh Menu) {(cd '.$ENV{HOME}.'/.perlpanel; xdg-menugen -format perlpanel -launch >menu.new; mv -f menu.new menu)}'.$self->icon('gtk-refresh');
    $text .= sprintf "%s\n", '  [separator]';
    $text .= sprintf "%s\n", '  [exit] (Exit)'.$self->icon('gtk-quit');
    $text .= sprintf "%s\n", '[endencoding]';
    $text .= sprintf "%s\n", '[end] # (Fluxbox)';
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
    my $name = $item->Name; $name =~ s/[)]/\\)/g;
    return sprintf "%s[nop] (%s) <%s>\n",
	   $indent, $name, $item->Icon([qw(png xpm svg jpg)]);
}
sub Separator {
    my ($self,$item,$indent) = @_;
    return sprintf "%s[separator]\n",
	   $indent;
}
sub Application {
    my ($self,$item,$indent) = @_;
    my $name = $item->Name; $name =~ s/[)]/\\)/g;
    my $exec = $item->Exec; $exec =~ s/[)]/\\)/g;
    $exec = "$self->{ops}{launch} ".$item->Id
	if $self->{ops}{launch};
    return sprintf "%s[exec] (%s) {%s} <%s>\n",
	   $indent, $name, $exec, $item->Icon([qw(png xpm svg jpg)]);
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $menu = $item->{Menu};
    my $text = '';
    # no empty menus...
    return $text unless @{$menu->{Elements}};
    my $name = $item->Name; $name =~ s/[)]/\\)/g;
    $text .= sprintf "%s[submenu] (%s) {%s} <%s>\n",
	    $indent, $name, $item->Name." Menu",
	    $item->Icon([qw(png xpm svg jpg)]);
    $text .= $self->build($item->{Menu},$indent.'  ');
    $text .= sprintf "%s[end] # (%s)\n",
	    $indent, $name;
    return $text;
}

1;

__END__

=head1 SEE ALSO

L<XDG::Menu(3pm)>,
L<XDG::Menu::Base(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
