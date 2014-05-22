package XDG::Menu::Waimea;
use base qw(XDG::Menu::Base);
use strict;
use warnings;

=head1 NAME

XDG::Menu::Waimea - generate a Waimea menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_menu('/etc/xdg/menus/applications.menu');
 my $waimea = new XDG::Menu::Waimea;
 print $waimea->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Waimea> is a module that reads an XDG::Menu::Layout tree
and generates a waimea style menu.

=head1 METHODS

B<XDG::Menu::Waimea> has the following methods:

=over

=item $waimea->B<create>(I<$tree>,I<$style>,I<$name>) => I<$menu>

Creates a L<waimea(1)> menu from menu tree, C<$tree>, and returns the
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
    $text .= sprintf "%s%s\n", $indent, '[submenu] (Window Managers)';
    $text .= sprintf "%s%s\n", $indent, '  [restart] (Restart)';
    $self->getenv();
    $self->default();
    my $wms = $self->get_xsessions();
    foreach (sort keys %$wms) {
	my $wm = $wms->{$_};
	my $name = $wm->{Name};
	$name = $_ unless $name;
	next if "\L$name\E" eq "waimea";
	my $exec = $wm->{Exec};
	$text .= sprintf("%s  [restart] (Start %s) {%s}\n",$indent,$name,$exec);
    }
    $text .= sprintf "%s%s\n", $indent, '[end]';
    return $text;
}

sub appmenu {
    my($self,$entries,$name) = @_;
    my $text = '';
    $text .= sprintf "[submenu] (%s)\n", $name;
    $text .= $entries;
    $text .= sprintf "[end]\n";
    return $text;
}
sub rootmenu {
	my ($self,$entries) = @_;
	my $text = '';
	$text .= sprintf "%s\n", '[start] (rootmenu)';
	$text .= $entries;
	$text .= sprintf "%s\n", '  [nop] ('. "-" x 32 .') {}';
	$text .= sprintf "%s\n", '  [submenu] (Waimea)';
	$text .= sprintf "%s\n", '  [workspaces] (Workspace List)';
	$text .= sprintf "%s\n", '    [submenu] (Tools)';
	$text .= sprintf "%s\n", '      [exec] (Window name) {xprop WM_CLASS|cut -d \" -f 2|gxmessage -file - -center}';
	$text .= sprintf "%s\n", '      [exec] (Screenshot - JPG) {import screenshot.jpg && display -resize 50% screenshot.jpg}';
	$text .= sprintf "%s\n", '      [exec] (Screenshot - PNG) {import screenshot.png && display -resize 50% screenshot.png}';
	$text .= sprintf "%s\n", '      [exec] (Run) {fbrun -font 10x20 -fg grey -bg black -title run}';
	$text .= sprintf "%s\n", '      [exec] (Run Command) {bbrun -a -w}';
	$text .= sprintf "%s\n", '    [end]';
	$text .= sprintf "%s\n", '  [config] (Configuration)';
	$text .= $self->stylemenu('    ');
#	$text .= sprintf "%s\n", '    [sub] (Styles) <!stylesdir.pl>';
	$text .= sprintf "%s\n", '    [sub] (Processes) <!procinfo.pl>';
	$text .= $self->wmmenu('    ');
	$text .= sprintf "%s\n", '  [end]';
	$text .= sprintf "%s\n", '  [reconfig] (Reconfigure)';
	$text .= sprintf "%s\n", '  [nop] ('. "-" x 32 .') {}';
	$text .= sprintf "%s\n", '  [exit] (Exit)';
	$text .= sprintf "%s\n", '[end]';
	$text .= sprintf "%s\n", '[include] (~/.waimea/winmenu)';
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
	return sprintf "%s[nop] (%s)\n",
	       $indent, $name;
}
sub Separator {
	my ($self,$item,$indent) = @_;
	return sprintf "%s[nop] (". "-" x 32 .") {}\n",
	       $indent;
}
sub Application {
	my ($self,$item,$indent) = @_;
	my $name = $item->Name; $name =~ s/[)]/\\)/g;
	if ($self->{ops}{launch}) {
	    return sprintf "%s[exec] (%s) {xdg-launch %s}\n",
		   $indent, $name, $item->Id;
	} else {
	    return sprintf "%s[exec] (%s) {%s}\n",
		   $indent, $name, $item->Exec;
	}
}
sub Directory {
	my ($self,$item,$indent) = @_;
	my $menu = $item->{Menu};
	my $text = '';
	# no empty menus...
	return $text unless @{$menu->{Elements}};
	my $name = $item->Name; $name =~ s/[)]/\\)/g;
	$text .= sprintf "%s[submenu] (%s) {%s}\n",
		$indent, $name, $item->Name." Menu";
	$text .= $self->build($menu,$indent.'  ');
	$text .= sprintf "%s[end]\n",
		$indent;
	return $text;
}

sub stylemenu {
    my($self,$indent) = @_;
    my $text = $indent.'[sub] (Styles) <!styledir.pl>'."\n";
    my $exec;
    foreach (split(/:/,$ENV{PATH})) {
	if (-x "$_/xde-style") {
	    $exec = "$_/xde-style";
	    last;
	}
    }
    return $text unless $exec;
    my $styles;
    my $pl = `$exec -l --perl`;
    eval "\$styles = $pl;";
    return $text unless $styles;
    $text = '';
    $text .= sprintf "%s%s\n", $indent, '[submenu] (Styles) {Choose a style...}';
    if ($styles->{user} and %{$styles->{user}}) {
#	$text .= sprintf "%s%s\n", $indent, '  [submenu] (User Styles) {Choose a style...}';
	foreach my $name (sort keys %{$styles->{user}}) {
	    my $label = $name;
	    $label =~ s{[-_]}{ }g;
	    $label =~ s{([(){}<>])}{\\$1}g;
	    $label =~ s{\.style$}{};
	    $text .= sprintf "%s  [exec] (%s) {xde-style -s -u '%s'}\n", $indent, $label, $name;
	}
#	$text .= sprintf "%s%s\n", $indent, '  [end]';
    }
    $text .= sprintf "%s  %s\n", $indent, '[nop] ('. "-" x 32 .') {}';
    if ($styles->{system} and %{$styles->{system}}) {
#	$text .= sprintf "%s%s\n", $indent, '  [submenu] (System Styles) {Choose a style...}';
	foreach my $name (sort keys %{$styles->{system}}) {
	    my $label = $name;
	    $label =~ s{[-_]}{ }g;
	    $label =~ s{([(){}<>])}{\\$1}g;
	    $label =~ s{\.style$}{};
	    $text .= sprintf "%s  [exec] (%s) {xde-style -s -y '%s'}\n", $indent, $label, $name;
	}
#	$text .= sprintf "%s%s\n", $indent, '  [end]';
    }
    $text .= sprintf "%s%s\n", $indent, '[end]';
    return $text;
}

sub styles {
    my ($self,$indent) = @_;
    my $base = '/usr/share/waimea';
    my @sstyles = ();
    my $sdir = "$base/styles";
    if (opendir (my $fh, $sdir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-f "$sdir/$f") {
		push @sstyles, $f;
	    } elsif (-f "$sdir/$f/stylerc") {
		push @sstyles, "$f/stylerc";
	    }
	}
    }
    my @ustyles = ();
    my $udir = "$ENV{HOME}/.waimea/styles";
    if (opendir (my $fh, $udir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-f "$udir/$f") {
		push @ustyles, $f;
	    } elsif (-f "$udir/$f/stylerc") {
		push @ustyles, "$f/style";
	    }
	}
    }
    my $conf = $ENV{XDG_CONFIG_HOME};
    $conf = "$ENV{HOME}/.config" unless $conf;
    my @xstyles = ();
    my $xdir = "$conf/waimea/styles";
    if (opendir (my $fh, $xdir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-f "$xdir/$f") {
		push @xstyles, $f;
	    }
	    elsif (-f "$xdir/$f/stylerc") {
		push @xstyles, "$f/style";
	    }
	}
    }
    my $text = '';
    if (@sstyles or @ustyles) {
    }
    return $text;
}

1;

__END__

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
