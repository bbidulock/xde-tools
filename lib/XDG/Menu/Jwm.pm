package XDG::Menu::Jwm;
use base qw(XDG::Menu::Base);
use strict;
use warnings;

=head1 NAME

XDG::Menu::Jwm - generate a JWM menu from an XDG::Menu tree

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menus/applications.menu');
 my $jwm = new XDG::Menu::Jwm;
 print $jwm->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Jwm> is a module that reads an XDG::Menu::Layout tree
and generates a JWM style menu.

=head1 METHODS

B<XDG::Menu::Jwm> has the folllowing methods:

=over

=cut

sub escape {
    my $string = shift;
    $string =~ s/[&]/&amp;/g;
    return $string;
}

=item $jwm->B<icon>(I<@names>) => I<$spec>

Accepts a list of icon names, I<@names>, as specified in a desktop entry
file and returns an icon specification that can be added to a menu
entry.

=cut

sub icon {
    my($self,@names) = @_;
    foreach (@names) {
	my $icon = $self->SUPER::icon($_,qw(png svg xpm jpg));
	return sprintf("icon=\"%s\" ",$icon) if $icon;
    }
    return '';
}

=item $jwm->B<create>(I<$tree>,I<$style>,I<$name>) => I<$menu>

Creates the L<jwm(1)> menu from menu tree, C<$tree>, and returns the
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
    return $self->makefile($menu);
}

=back

=cut

sub makefile {
    my($self,$menu) = @_;
    my $text = '';
    $text .= q(<?xml version="1.0"?>)."\n";
    $text .= q(<JWM>)."\n";
    $text .= $menu;
    $text .= q(</JWM>)."\n";
    return $text;
}

sub wmmenu {
    my($self,$indent) = @_;
    my $text = '';
    $text .= sprintf "%s%s\n", $indent, q(<Menu ).$self->icon('gtk-quit').q(label="Window Managers">);
    $text .= sprintf "%s%s\n", $indent, q(  <Restart ).$self->icon('gtk-refresh').q(label="Restart"/>);
    $self->getenv();
    $self->default();
    my $wms = $self->get_xsessions();
    foreach (sort keys %$wms) {
	my $wm = $wms->{$_};
	my $name = $wm->{Name};
	$name = $_ unless $name;
	next if $name =~ m{jwm}i;
	$name =~ s/["]/\\"/g;
	my $exec = $wm->{Exec};
	my $icon = $self->icon($wm->{Icon});
	$icon = $self->icon('preferences-system-windows') unless $icon;
	$text .= sprintf "%s%s\n", $indent, q(  <Exit ).$icon.q(label=").escape($name).q(" confirm="false">).$exec.q(</Exit>);
    }
    $text .= sprintf "%s%s\n", $indent, q(</Menu>);
    return $text;
}

sub appmenu {
    my($self,$entries,$name) = @_;
    my $text = '';
    $text .= q(  <Menu ).$self->icon('start-here').q(label=").$name.q(">)."\n";
    $text .= $entries;
    $text .= q(  </Menu>)."\n";
    return $text;
}
sub rootmenu {
    my($self,$entries) = @_;
    my $text = '';
    $text .= $entries;
    $text .= q(  <Separator/>)."\n";
    $text .= q(  <Menu ).$self->icon('jwm').q(label="JWM">)."\n";
    $text .= q(    <Menu ).$self->icon('preferences-system-windows').q(label="Window Menu">)."\n";
    $text .= q(      <SendTo ).$self->icon('window-sendto').q(label="Send To ..." />)."\n";
    $text .= q(      <Stick ).$self->icon('window-stick').q(label="(Un)stick" />)."\n";
    $text .= q(      <Maximize ).$self->icon('window-maximize').q(label="(Un)maximize" />)."\n";
    $text .= q(      <Minimize ).$self->icon('window-minimize').q(label="(Un)minimize" />)."\n";
    $text .= q(      <Shade ).$self->icon('window-shade').q(label="(Un)shade" />)."\n";
    $text .= q(      <Program ).$self->icon('window-above').q(label="Above/Normal">wmctrl -r :SELECT: -b toggle,above</Program>)."\n";
    $text .= q(      <Program ).$self->icon('window-below').q(label="Below/Normal">wmctrl -r :SELECT: -b toggle,below</Program>)."\n";
    $text .= q(      <Move ).$self->icon('window-move').q(label="Move" />)."\n";
    $text .= q(      <Resize ).$self->icon('window-resize').q(label="Resize" />)."\n";
    $text .= q(      <Kill ).$self->icon('window-kill').q(label="Kill" />)."\n";
    $text .= q(      <Close ).$self->icon('window-close').q(label="Close" />)."\n";
    $text .= q(    </Menu>)."\n";
    $text .= q(    <Desktops ).$self->icon('preferences-desktop-display').q(label="Desktops"/>)."\n";
    $text .= $self->themes('    ');
    $text .= $self->styles('    ');
    $text .= $self->wmmenu('    ');
    $text .= q(    <Program ).$self->icon('gtk-refresh').q(label="Regenerate Menu">xde-menugen -o /home/brian/.jwm/menu.new</Program>)."\n";
    $text .= q(  </Menu>)."\n";
    $text .= q(  <Separator/>)."\n";
    $text .= q(  <Restart ).$self->icon('gtk-refresh').q(label="Restart"/>)."\n";
    $text .= q(  <Program ).$self->icon('gnome-lockscreen').q(label="Lock">slock</Program>)."\n";
    $text .= q(  <Exit ).$self->icon('gtk-quit').q(label="Exit" confirm="true"/>)."\n";
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
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    return sprintf "%s<Menu icon=\"%s\" label=\"%s\" labeled=\"false\"/>\n",
	$indent, $item->Icon([qw(png svg xpm jpg)]), escape($name);
}
sub Separator {
    my ($self,$item,$indent) = @_;
    return sprintf "%s<Separator/>\n", $indent;
}
sub Application {
    my ($self,$item,$indent) = @_;
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    if ($self->{ops}{launch}) {
	return sprintf "%s<Program icon=\"%s\" label=\"%s\">xdg-launch %s</Program>\n",
	       $indent, $item->Icon([qw(png svg xpm jpg)]), escape($name), $item->Id;
    } else {
	return sprintf "%s<Program icon=\"%s\" label=\"%s\">%s</Program>\n",
	       $indent, $item->Icon([qw(png svg xpm jpg)]), escape($name), $item->Exec;
    }
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $menu = $item->{Menu};
    my $text = '';
    # no empty menus...
    return $text unless @{$menu->{Elements}};
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    $text .= sprintf "%s<Menu icon=\"%s\" label=\"%s\" labeled=\"false\">\n",
	$indent, $item->Icon([qw(png svg xpm jpg)]), escape($name);
    $text .= $self->build($item->{Menu},$indent.'   ');
    $text .= sprintf "%s</Menu> <!-- %s -->\n",
	$indent, $item->Name;
    return $text;
}

sub themes {
    my ($self,$indent) = @_;
    my $base = '/usr/share/jwm';
    my @sthemes = ();
    my $sdir = "$base/themes";
    if (opendir (my $fh, $sdir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-f "$sdir/$f") {
		push @sthemes, $f;
	    }
	    elsif (-f "$sdir/$f/style") {
		push @sthemes, "$f/style";
	    }
	}
    }
    my @uthemes = ();
    my $udir = "$ENV{HOME}/.jwm/themes";
    if (opendir (my $fh, $udir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-f "$udir/$f") {
		push @uthemes, $f;
	    }
	    elsif (-f "$udir/$f/style") {
		push @uthemes, "$f/style";
	    }
	}
    }
    my $conf = $ENV{XDG_CONFIG_HOME};
    $conf = "$ENV{HOME}/.config" unless $conf;
    my @xthemes = ();
    my $xdir = "$conf/jwm/themes";
    if (opendir (my $fh, $xdir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-f "$xdir/$f") {
		push @xthemes, $f;
	    }
	    elsif (-f "$xdir/$f/style") {
		push @xthemes, "$f/style";
	    }
	}
    }
    my $text = '';
    if (@sthemes or @uthemes) {
	my $icon = $self->icon('style');
	$text .= "$indent<Menu ${icon}label=\"Themes\">\n";
	foreach (sort @sthemes) {
	    my $label = $_; $label =~ s{/style$}{};
	    $text .= "$indent   <Program ${icon}label=\"".escape($label)."\">$base/setstyle $sdir/$_</Program>\n";
	}
	if (@sthemes and @uthemes) {
	    $text .= "$indent   <Separator/>\n";
	}
	foreach (sort @uthemes) {
	    my $label = $_; $label =~ s{/style$}{};
	    $text .= "$indent   <Program ${icon}label=\"".escape($label)."\">$base/setstyle $udir/$_</Program>\n";
	}
	if ((@sthemes or @uthemes) and @xthemes) {
	    $text .= "$indent   <Separator/>\n";
	}
	foreach (sort @xthemes) {
	    my $label = $_; $label =~ s{/style$}{};
	    $text .= "$indent   <Program ${icon}label=\"".escape($label)."\">$base/setstyle $xdir/$_</Program>\n";
	}
	$text .= "$indent</Menu>\n";
    }
    return $text;
}

sub styles {
    my ($self,$indent) = @_;
    my $base = '/usr/share/jwm';
    my @sstyles = ();
    my $sdir = "$base/styles";
    if (opendir (my $fh, $sdir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-f "$sdir/$f") {
		push @sstyles, $f;
	    }
	    elsif (-f "$sdir/$f/style") {
		push @sstyles, "$f/style";
	    }
	}
    }
    my @ustyles = ();
    my $udir = "$ENV{HOME}/.jwm/styles";
    if (opendir (my $fh, $udir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-f "$udir/$f") {
		push @ustyles, $f;
	    }
	    elsif (-f "$udir/$f/style") {
		push @ustyles, "$f/style";
	    }
	}
    }
    my $conf = $ENV{XDG_CONFIG_HOME};
    $conf = "$ENV{HOME}/.config" unless $conf;
    my @xstyles = ();
    my $xdir = "$conf/jwm/styles";
    if (opendir (my $fh, $xdir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-f "$xdir/$f") {
		push @xstyles, $f;
	    }
	    elsif (-f "$xdir/$f/style") {
		push @xstyles, "$f/style";
	    }
	}
    }
    my $text = '';
    if (@sstyles or @ustyles) {
	my $icon = $self->icon('style');
	$text .= "$indent<Menu ${icon}label=\"Styles\">\n";
	foreach (sort @sstyles) {
	    my $label = $_; $label =~ s{/style$}{};
	    $text .= "$indent   <Program ${icon}label=\"".escape($label)."\">$base/setstyle $sdir/$_</Program>\n";
	}
	if (@sstyles and @ustyles) {
	    $text .= "$indent   <Separator/>\n";
	}
	foreach (sort @ustyles) {
	    my $label = $_; $label =~ s{/style$}{};
	    $text .= "$indent   <Program ${icon}label=\"".escape($label)."\">$base/setstyle $udir/$_</Program>\n";
	}
	if ((@sstyles or @ustyles) and @xstyles) {
	    $text .= "$indent   <Separator/>\n";
	}
	foreach (sort @xstyles) {
	    my $label = $_; $label =~ s{/style$}{};
	    $text .= "$indent   <Program ${icon}label=\"".escape($label)."\">$base/setstyle $xdir/$_</Program>\n";
	}
	$text .= "$indent</Menu>\n";
    }
    return $text;
}

1;

__END__

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
