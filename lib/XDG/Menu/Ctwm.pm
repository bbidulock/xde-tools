package XDG::Menu::Ctwm;
use base qw(XDG::Menu::Base);
use strict;
use warnings;

=head1 NAME

XDG::Menu::Ctwm - generate a CTWM menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_menu('/etc/xdg/menus/applications.menu');
 my $ctwm = new XDG::Menu::Ctwm;
 print $ctwm->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Ctwm> is a module that reads an XDG::Menu::Layout tree and
generates a L<ctwm(1)> style menu.

In general, creation of the applications submenu for L<ctwm(1)>,
L<mwm(1)> and L<twm(1)> are almost identical; however, generation of a
full root menu is different.

=head1 METHODS

B<XDG::Menu::Ctwm> has the following methods:

=over

=item $ctwm->B<create>(I<$tree>,I<$style>,I<$name>) => I<$menu>

Creates a L<ctwm(1)> menu from menu tree, I<$tree>, and returns the
menu in a scalar string, I<$menu>.  I<$tree> must have been created as a
result of parsing the XDG menu using XDG::Menu::Parser (see
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

my $SEPARATOR = '"'.('-' x 32).'"';

sub create {
    my($self,$tree,$style,$name) = @_;
    $style = 'fullmenu' unless $style;
    $name = 'Applications' unless $name;
    $self->{menus} = [];
    push @{$self->{menus}},"changequote(`[[[',`]]]')dnl\n";
    my $entries = $self->build($tree);
    push @{$self->{menus}},$self->wmmenu()
	if $style eq 'fullmenu';
    push @{$self->{menus}},$self->twmmenu()
	if $style eq 'fullmenu';
    push @{$self->{menus}},$self->appmenu($entries,$name)
	if $style eq 'appmenu' or $style eq 'submenu';
    return $entries if $style eq 'entries';
    $entries = sprintf("    %-32s  f.menu \"%s\"\n",'"'.$name.'"',$name)
	if $style eq 'submenu';
    push @{$self->{menus}},$self->rootmenu($entries,$name)
	if $style ne 'appmenu';
    push @{$self->{menus}},"changequote(`,)dnl\n";
    return join("\n",@{$self->{menus}});
}

=back

=cut

sub wmmenu {
    my $self = shift;
    my $text = '';
    $text .= "Menu \"managers\" twm_MenuColor\n";
    $text .= "{\n";
    $text .= sprintf("    %-32s  %s\n",'"Window Managers"',	  'f.title');
    $self->getenv();
    $self->default();
    my $wms = $self->get_xsessions();
    my $gotone = 0;
    foreach (sort keys %$wms) {
	my $wm = $wms->{$_};
	my $name = $wm->{Name};
	$name = $_ unless $name;
	next if "\L$name\E" eq "ctwm";
	my $exec = $wm->{Exec};
	my $icon = $self->icon($wm->{Icon});
	$icon = $self->icon('preferences-desktop-display') unless $icon;
	$name =~ s/["]/\\"/g;
	$exec =~ s/["]/\\"/g;
	$text .= sprintf "    %-32s  %s\n",'"'.$name.'"','f.exec "exec '.$exec.' &"';
	$gotone = 1;
    }
    $text .= $self->Separator() if $gotone;
    $text .= sprintf("    %-32s  %s\n",'"Restart"',		  'f.restart');
    $text .= sprintf("    %-32s  %s\n",'"Quit"',		  'f.quit');
    $text .= "}\n";
    return $text;
}
sub twmmenu {
    my $self = shift;
    my $text = '';
    $text .= "Menu \"twmmenu\" twm_MenuColor\n";
    $text .= "{\n";
    $text .= sprintf("    %-32s  %s\n",'"TWM Menu"',		    'f.title');
    if (1) {
    $text .= sprintf("    %-32s  %s\n",'"Icons List"',		    'f.menu "TwmIcons"');
    }
    $text .= sprintf("    %-32s  %s\n",'"Window List"',		    'f.menu "TwmWindows"');
    $text .= sprintf("    %-32s  %s\n",'"Window Operations"',	    'f.menu "windowops"');
    $text .= sprintf("    %-32s  %s\n",'"Styles"',		    'f.menu "twmstyles"');
    $text .= sprintf("    %-32s  %s\n",'"Window Managers"',	    'f.menu "managers"');
    $text .= sprintf("    %-32s  %s\n",'"Hide Icon Manager"',	    'f.hideiconmgr');
    $text .= sprintf("    %-32s  %s\n",'"Show Icon Manager"',	    'f.showiconmgr');
    if (1) {
    $text .= sprintf("    %-32s  %s\n",'"Hide Workspace Manager"',  'f.hideworkspacemgr');
    $text .= sprintf("    %-32s  %s\n",'"Show Workspace Manager"',  'f.showworkspacemgr');
    }
    if (0) {
    $text .= sprintf("    %-32s  %s\n",'"Hide Desktop Display"',    'f.hidedesktopdisplay');
    $text .= sprintf("    %-32s  %s\n",'"Show Desktop Display"',    'f.showdesktopdisplay');
    }
    $text .= sprintf("    %-32s  %s\n",'"Refresh"',		    'f.refresh');
    $text .= sprintf("    %-32s  %s\n",'"Restart"',		    'f.restart');
    $text .= "}\n";
    return $text;
}
sub appmenu {
    my($self,$entries,$name) = @_;
    $name = 'Applications' unless $name;
    my $text = '';
    $text .= "Menu \"$name\" twm_MenuColor\n";
    $text .= "{\n";
    $text .= sprintf("    %-32s  %s\n",'"'.$name.'"',	'f.title');
    $text .= $entries;
    $text .= "}\n";
    return $text;
}
sub rootmenu {
    my($self,$entries) = @_;
    my $text = '';
    $text .= "Menu \"defops\" twm_MenuColor\n";
    $text .= "{\n";
    $text .= sprintf("    %-32s  %s\n",'"Twm"',			    'f.title');
    $text .= $self->Pin();
    $text .= $entries;
    $text .= $self->Separator();
    $text .= sprintf("    %-32s  %s\n",'"TWM Menu"',		    'f.menu "twmmenu"');
    $text .= $self->Separator();
    $text .= sprintf("    %-32s  %s\n",'"Refresh"',		    'f.refresh');
    $text .= sprintf("    %-32s  %s\n",'"Reconfigure"',		    'f.function "reconfig"');
    $text .= sprintf("    %-32s  %s\n",'"Restart"',		    'f.restart');
    $text .= sprintf("    %-32s  %s\n",'"Exit"',		    'f.quit');
    $text .= "}\n";
    return $text;
}
sub build {
    my($self,$item) = @_;
    my $name = ref($item);
    $name =~ s{.*\:\:}{};
    return $self->$name($item) if $self->can($name);
    return '';
}
sub Menu {
    my($self,$item) = @_;
    my $text = '';
    if ($item->{Elements}) {
	foreach (@{$item->{Elements}}) {
	    next unless $_;
	    $text .= $self->build($_);
	}
    }
    return $text;
}
sub Header {
    my($self,$item) = @_;
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    return sprintf "    %-32s  %s\n", '"'.$name.'"','f.title';
}
sub Separator {
    my($self,$item) = @_;
    my $text = '';
    if (1) {
    $text .= sprintf "    %-32s  %s\n", '""', 'f.separator';
    } else {
    $text .= sprintf "    %-32s  f.nop\n", $SEPARATOR;
    }
    return $text;
}
sub Pin {
    my($self,$item) = @_;
    my $text = '';
    if (1) {
    $text .= sprintf "    %-32s  %s\n", '"--------> pin <--------"', 'f.pin';
    }
    return $text;
}
sub Application {
    my($self,$item) = @_;
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    if ($self->{ops}{launch}) {
	my $id = $item->Id; $id =~ s/["]/\\"/g;
	return sprintf "    %-32s  f.exec \"exec xdg-launch %s &\"\n",
	       '"'.$name.'"', $id;
    } else {
	my $exec = $item->Exec; $exec =~ s/["]/\\"/g;
	return sprintf "    %-32s  f.exec \"exec %s &\"\n",
	       '"'.$name.'"', $exec;
    }
}
sub Directory {
    my($self,$item) = @_;
    my $menu = $item->{Menu};
    my $text = '';
    # no empty menus...
    return $text unless @{$menu->{Elements}};
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    $text .= sprintf "Menu \"%s\" twm_MenuColor\n{\n", $name;
    $text .= sprintf "    %-32s  f.title\n",'"'.$name.'"';
    $text .= $self->build($menu);
    $text .= "}\n";
    push @{$self->{menus}}, $text;
    return sprintf "    %-32s  f.menu \"%s\"\n",'"'.$name.'"',$name;
}

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDG::Menu(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
