package XDG::Menu::Fluxbox;
use strict;
use warnings;

=head1 NAME

 XDG::Menu::Fluxbox - generate a Fluxbox menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menus/applications.menu');
 my $fluxbox = new XDG::Menu::Fluxbox;
 print $fluxbox->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Fluxbox> is a module that reads an XDG::Menu::Layout tree
and generates a fluxbox style menu.

=head1 METHODS

B<XDG::Menu::Fluxbox> has the folllowing methods:

=over

=item XDG::Menu::Fluxbox->B<new>() => XDG::Menu::Fluxbox

Creates a new XDG::Menu::Fluxbox instance for creating fluxbox menus.

=cut

sub new {
	return bless {}, shift;
}

=item $fluxbox->B<create>($tree) => scalar

Creates the fluxbox menu from menu tree, C<$tree>, and returns the menu
in a scalar string.  C<$tree> must have been created as the result of
parsing the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

=cut

sub create {
	my ($self,$item) = @_;
	my $icons = XDG::Menu::DesktopEntry->get_icons();
	my $icon;
	my $text = '';
	$text .= sprintf "%s\n", '[begin] (Fluxbox)';
	$text .= sprintf "%s\n", '[encoding] {UTF-8}';
	$text .= $self->build($item,'  ');
	$text .= sprintf "%s\n", '  [separator]';
	$text .= sprintf "%s\n", '  [submenu] (Fluxbox menu)';
	$text .= sprintf "%s\n", '    [config] (Configure)';
	$text .= sprintf "%s\n", '    [submenu] (System Styles) {Choose a style...}';
	$text .= sprintf "%s\n", '      [stylesdir] (/usr/share/fluxbox/styles)';
	$text .= sprintf "%s\n", '    [end]';
	$text .= sprintf "%s\n", '    [submenu] (User Styles) {Choose a style...}';
	$text .= sprintf "%s\n", '      [stylesdir] (~/.fluxbox/styles)';
	$text .= sprintf "%s\n", '    [end]';
	$text .= sprintf "%s\n", '    [submenu] (Backgrounds) {Set the Background}';
	$text .= sprintf "%s\n", '      [exec] (Random Background) {fbsetbg -r /usr/share/fluxbox/backgrounds}';
	$text .= sprintf "%s\n", '    [end]';
	$text .= sprintf "%s\n", '    [workspaces] (Workspace List)';
	$text .= sprintf "%s\n", '    [submenu] (Tools)';
	$text .= sprintf "%s\n", '      [exec] (Fluxbox panel) {fbpanel}';
	$text .= sprintf "%s\n", '      [exec] (Window name) {xprop WM_CLASS|cut -d \" -f 2|gxmessage -file - -center}';
	$text .= sprintf "%s\n", '      [exec] (Screenshot - JPG) {import screenshot.jpg && display -resize 50% screenshot.jpg}';
	$text .= sprintf "%s\n", '      [exec] (Screenshot - PNG) {import screenshot.png && display -resize 50% screenshot.png}';
	$text .= sprintf "%s\n", '      [exec] (Run) {fbrun -font 10x20 -fg grey -bg black -title run}';
	$text .= sprintf "%s\n", '      [exec] (Regen Menu) {fluxbox-generate_menu}';
	$text .= sprintf "%s\n", '    [end]';
	$text .= sprintf "%s\n", '    [submenu] (Window Managers)';
	$text .= sprintf "%s\n", '      [restart] (mwm) {mwm}';
	$text .= sprintf "%s\n", '      [restart] (twm) {twm}';
	$text .= sprintf "%s\n", '      [restart] (wmii) {wmii}';
	$text .= sprintf "%s\n", '      [restart] (icewm) {icewm}';
	$text .= sprintf "%s\n", '      [restart] (fvwm) {fvwm}';
	$text .= sprintf "%s\n", '      [restart] (openbox) {openbox}';
	$text .= sprintf "%s\n", '      [restart] (fvwm2) {fvwm2}';
	$text .= sprintf "%s\n", '      [restart] (blackbox) {blackbox}';
	$text .= sprintf "%s\n", '      [restart] (windowmaker) {wmaker}';
	$text .= sprintf "%s\n", '    [end]';
	$text .= sprintf "%s\n", '  [end]';
	$icon = $icons->FindIcon('gnome-lockscreen',16,[qw(png xpm)]);
	$icon = $icons->FindIcon('exec',16,[qw(png xpm)]) unless $icon;
	$text .= sprintf "  [exec] (Lock screen) {slock} <%s>\n", $icon;
	$text .= sprintf "%s\n", '  [commanddialog] (Fluxbox Command)';
	$text .= sprintf "%s\n", '  [reconfig] (Reload config)';
	$text .= sprintf "%s\n", '  [restart] (Restart)';
	$text .= sprintf "%s\n", '  [exec] (About) {(fluxbox -v; fluxbox -info | sed 1d) | gxmessage -file - -center}';
	$text .= sprintf "%s\n", '  [separator]';
	$text .= sprintf "%s\n", '  [exit] (Exit)';
	$text .= sprintf "%s\n", '[endencoding]';
	$text .= sprintf "%s\n", '[end]';
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
	       $indent, $name, $item->Icon([qw(png xpm)]);
}
sub Separator {
	my ($self,$item,$indent) = @_;
	return sprintf "%s[separator]\n",
	       $indent;
}
sub Application {
	my ($self,$item,$indent) = @_;
	my $name = $item->Name; $name =~ s/[)]/\\)/g;
	return sprintf "%s[exec] (%s) {%s} <%s>\n",
	       $indent, $name, $item->Exec, $item->Icon([qw(png xpm)]);
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
		$item->Icon([qw(png xpm)]);
	$text .= $self->build($item->{Menu},$indent.'  ');
	$text .= sprintf "%s[end]\n",
		$indent;
	return $text;
}

1;

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut


