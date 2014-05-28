package XDG::Menu::Blackbox;
use base qw(XDG::Menu::Base);
use File::Which;
use strict;
use warnings;

=head1 NAME

XDG::Menu::Blackbox - generate a Blackbox menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_menu('/etc/xdg/menus/applications.menu');
 my $blackbox = new XDG::Menu::Blackbox;
 print $blackbox->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Blackbox> is a module that reads an XDG::Menu::Layout tree
and generates a blackbox style menu.

=head1 METHODS

B<XDG::Menu::Blackbox> has the following methods:

=over

=item $blackbox->B<create>(I<$tree>,I<$style>,I<$name>) => I<$menu>

Creates a L<blackbox(1)> menu from menu tree, C<$tree>, and returns the
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
	next if "\L$name\E" eq "blackbox";
	my $exec = $wm->{Exec};
	if ($self->{ops}{launch}) {
	    $exec = "$self->{ops}{launch} -X $wm->{id}";
	    $exec =~ s{\.desktop$}{};
	}
	$text .= sprintf "%s  [restart] (Start %s) {%s}\n",$indent,$name,$exec;
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
	$text .= sprintf "%s\n", '[begin] (Blackbox)';
	$text .= $entries;
	$text .= sprintf "%s\n", '  [nop] ('. "\N{EM DASH}" x 12 .') {}';
	$text .= sprintf "%s\n", '  [workspaces] (Workspace List)';
	$text .= sprintf "%s\n", '  [config] (Configuration)';
	$text .= $self->themes('  ');
	$text .= $self->styles('  ');
	$text .= $self->wmmenu('  ');
	$text .= sprintf "%s\n", '  [reconfig] (Reconfigure)';
	$text .= sprintf "%s\n", '  [exec] (Refresh Menu) {xdg-menugen -format blackbox -desktop BLACKBOX -launch -o '.$self->{ops}{output}
	    if $self->{ops}{output} and which('xdg-menugen');
	$text .= sprintf "%s\n", '  [nop] ('. "\N{EM DASH}" x 12 .') {}';
	$text .= sprintf "%s\n", '  [exit] (Exit)';
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
	return sprintf "%s[nop] (%s)\n",
	       $indent, $name;
}
sub Separator {
	my ($self,$item,$indent) = @_;
	return sprintf "%s[nop] (". "\N{EM DASH}" x 12 .") {}\n",
	       $indent;
}
sub Application {
	my ($self,$item,$indent) = @_;
	my $name = $item->Name; $name =~ s/[)]/\\)/g;
	my $exec = $item->Exec;
	$exec = "$self->{ops}{launch} ".$item->Id
	    if $self->{ops}{launch};
	return sprintf "%s[exec] (%s) {%s}\n",
	       $indent, $name, $exec;
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

sub themes_xde {
    my($self,$indent) = @_;
    my $text = '';
    my $themes;
    eval "\$themes = ".`xde-style -l -t --perl`;
    if ($themes) {
	my(@uthemes,@sthemes,@mthemes);
	foreach (qw(user system mixed)) {
	    $themes->{$_} = {} unless $themes->{$_};
	}
	@uthemes = keys %{$themes->{user}};
	@sthemes = keys %{$themes->{system}};
	@mthemes = keys %{$themes->{mixed}};
	if (@uthemes or @sthemes or @mthemes) {
	    $text .= sprintf "%s%s\n", $indent, '[submenu] (Themes) {Choose a theme...}';
	    foreach (sort @mthemes) {
		$text .= sprintf "%s  [exec] (%s) {xde-style -s -t -r '%s'}\n", $indent, $_, $_;
	    }
	    if (@mthemes and @sthemes) {
		$text .= sprintf "%s  [nop] (". "\N{EM DASH}" x 12 .") {}\n", $indent;
	    }
	    foreach (sort @sthemes) {
		$text .= sprintf "%s  [exec] (%s) {xde-style -s -t -r -y '%s'}\n", $indent, $_, $_;
	    }
	    if ((@mthemes or @sthemes) and @uthemes) {
		$text .= sprintf "%s  [nop] (". "\N{EM DASH}" x 12 .") {}\n", $indent;
	    }
	    foreach (sort @uthemes) {
		$text .= sprintf "%s  [exec] (%s) {xde-style -s -t -r -u '%s'}\n", $indent, $_, $_;
	    }
	    $text .= sprintf "%s%s\n", $indent, '[end]';
	}
    }
    return $text;
}

sub themes_old {
    my($self,$indent) = @_;
    my $text = '';
    return $text;
}

sub themes {
    my $self = shift;
    if (File::Which::which('xde-style')) {
	return $self->themes_xde(@_);
    } else {
	return $self->themes_old(@_);
    }
}

sub styles_xde {
    my($self,$indent) = @_;
    my $text = '';
    my($styles,$themes);
    eval "\$styles = ".`xde-style -l --perl`;
    eval "\$themes = ".`xde-style -l -t --perl`;
    if ($styles and $themes) {
	my(@ustyles,@sstyles,@mstyles);
	foreach (qw(user system mixed)) {
	    $styles->{$_} = {} unless $styles->{$_};
	    $themes->{$_} = {} unless $themes->{$_};
	}
	@ustyles = map {exists $themes->{user}{$_}   ? () : $_} keys %{$styles->{user}};
	@sstyles = map {exists $themes->{system}{$_} ? () : $_} keys %{$styles->{system}};
	@mstyles = map {exists $themes->{mixed}{$_}  ? () : $_} keys %{$styles->{mixed}};
	if (@ustyles or @sstyles or @mstyles) {
	    $text .= sprintf "%s%s\n", $indent, '[submenu] (Styles) {Choose a style...}';
	    foreach (sort @mstyles) {
		$text .= sprintf "%s  [exec] (%s) {xde-style -s -r '%s'}\n", $indent, $_, $_;
	    }
	    if (@mstyles and @sstyles) {
		$text .= sprintf "%s  [nop] (". "\N{EM DASH}" x 12 .") {}\n", $indent;
	    }
	    foreach (sort @sstyles) {
		$text .= sprintf "%s  [exec] (%s) {xde-style -s -r -y '%s'}\n", $indent, $_, $_;
	    }
	    if ((@mstyles or @sstyles) and @ustyles) {
		$text .= sprintf "%s  [nop] (". "\N{EM DASH}" x 12 .") {}\n", $indent;
	    }
	    foreach (sort @ustyles) {
		$text .= sprintf "%s  [exec] (%s) {xde-style -s -r -u '%s'}\n", $indent, $_, $_;
	    }
	    $text .= sprintf "%s%s\n", $indent, '[end]';
	}
    }
    return $text;
}
sub styles_old {
    my($self,$indent) = @_;
    my $text = '';
    $text .= sprintf "%s%s\n", $indent, '[submenu] (Styles) {Choose a style...}';
    $text .= sprintf "%s%s\n", $indent, '  [stylesdir] (/usr/share/blackbox/styles)';
    $text .= sprintf "%s%s\n", $indent, '  [stylesdir] (~/.blackbox/styles)';
    $text .= sprintf "%s%s\n", $indent, '  [stylesdir] (~/.config/blackbox/styles)';
    $text .= sprintf "%s%s\n", $indent, '[end]';
    return $text;
}

sub styles {
    my $self = shift;
    if (File::Which::which('xde-style')) {
	return $self->styles_xde(@_);
    } else {
	return $self->styles_old(@_);
    }
}

1;

__END__

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
