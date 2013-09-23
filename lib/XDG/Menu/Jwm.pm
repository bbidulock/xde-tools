package XDG::Menu::Jwm;
use strict;
use warnings;

=head1 NAME

XDG::Menu::Jwm - generate a JWM menu from an XDG::Menu tree

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menus/applications.menu');
 my $jwm = new XDG::Menu::Jwm;
 print $jwm->create($tree);

=head1 METHODS

B<XDG::Menu::Jwm> has the folllowing methods:

=over

=item XDG::Menu::Jwm->B<new>($tree) => XDG::Menu::Jwm

Creates a new XDG::Menu::Jwm instance for creating JWM menus.

=cut

sub new {
    return bless {}, shift;
}

sub escape {
    my $string = shift;
    $string =~ s/[&]/&amp;/g;
    return $string;
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

=item $jwm->B<create>($tree) => scalar

Creates the JWM menu from menu tree, C<$tree>, and returns the menu
in a scalar string.  C<$tree> must have been created as the result of
parsing the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

=cut

sub create {
    my ($self,$item) = @_;
    my $text = '';
    $text .= q(<?xml version="1.0"?>)."\n";
    $text .= q(<JWM>)."\n";
    $text .= $self->build($item,'  ');
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
    $text .= q(    <Program ).$self->icon('gtk-refresh').q(label="Regenerate Menu">xde-menugen -o /home/brian/.jwm/menu.new</Program>)."\n";
    $text .= q(  </Menu>)."\n";
    $text .= q(  <Separator/>)."\n";
    $text .= q(  <Restart ).$self->icon('gtk-refresh').q(label="Restart"/>)."\n";
    $text .= q(  <Program ).$self->icon('gnome-lockscreen').q(label="Lock">slock</Program>)."\n";
    $text .= q(  <Exit ).$self->icon('gtk-quit').q(label="Exit" confirm="true"/>)."\n";
    $text .= q(</JWM>)."\n";
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
	$indent, $item->Icon([qw(png xpm)]), escape($name);
}
sub Separator {
    my ($self,$item,$indent) = @_;
    return sprintf "%s<Separator/>\n", $indent;
}
sub Application {
    my ($self,$item,$indent) = @_;
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    return sprintf "%s<Program icon=\"%s\" label=\"%s\">%s</Program>\n",
	   $indent, $item->Icon([qw(png xpm)]), escape($name), $item->Exec;
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $text = '';
    if ($item->{Menu}{Elements} and @{$item->{Menu}{Elements}}) {
	my $name = $item->Name; $name =~ s/["]/\\"/g;
	$text .= sprintf "%s<Menu icon=\"%s\" label=\"%s\" labeled=\"false\">\n",
	    $indent, $item->Icon([qw(png xpm)]), escape($name);
	$text .= $self->build($item->{Menu},$indent.'   ');
	$text .= sprintf "%s</Menu> <!-- %s -->\n",
	    $indent, $item->Name;
    }
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
	}
    }
    my $text = '';
    if (@sthemes or @uthemes) {
	my $icon = $self->icon('style');
	$text .= "$indent<Menu ${icon}label=\"Themes\">\n";
	foreach (sort @sthemes) {
	    $text .= "$indent   <Program ${icon}label=\"".escape($_)."\">$base/setstyle $sdir/$_</Program>\n";
	}
	if (@sthemes and @uthemes) {
	    $text .= "$indent   <Separator/>\n";
	}
	foreach (sort @uthemes) {
	    $text .= "$indent   <Program ${icon}label=\"".escape($_)."\">$base/setstyle $udir/$_</Program>\n";
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
	}
    }
    my $text = '';
    if (@sstyles or @ustyles) {
	my $icon = $self->icon('style');
	$text .= "$indent<Menu ${icon}label=\"Styles\">\n";
	foreach (sort @sstyles) {
	    $text .= "$indent   <Program ${icon}label=\"".escape($_)."\">$base/setstyle $sdir/$_</Program>\n";
	}
	if (@sstyles and @ustyles) {
	    $text .= "$indent   <Separator/>\n";
	}
	foreach (sort @ustyles) {
	    $text .= "$indent   <Program ${icon}label=\"".escape($_)."\">$base/setstyle $udir/$_</Program>\n";
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

# vim: set sw=4 tw=72:
