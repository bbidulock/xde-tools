package XDG::Menu::Icewm;
use base qw(XDG::Menu::Base);
use strict;
use warnings;

=head1 NAME

XDG::Menu::Icewm - generate an IceWM menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menus/applications.menu');
 my $icewm = new XDG::Menu::Icewm;
 print $icewm->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Icewm> is a module that reads an XDG::Menu::Layout tree
and generates an IceWM style menu.

=head1 METHODS

B<XDG::Menu::Icewm> has the folllowing methods:

=over

=item $icewm->B<icon>(I<@names>) => I<$spec>

Accepts a list of icon names, I<@names>, as specified in a desktop entry
file and returns an icon specification that can be added to a menu
entry.

=cut

sub icon {
    my($self,@names) = @_;
    my $icon;
    foreach (@names) {
	$icon = $self->SUPER::icon($_,qw(png svg xpm jpg));
	last if $icon;
    }
    $icon = '-' unless $icon;
    return $icon;
}

=item $icewm->B<create>(I<$tree>,I<$style>,I<$name>) => I<$menu>

Creates an L<icewm(1)> menu from menu tree, C<$tree>, and returns the
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
    my $self = shift;
    my $text = '';
    $text .= sprintf "  menu \"%s\" %s {\n", q(Window Managers),
	$self->icon('gtk-quit');
    $text .= sprintf "    restart \"%s\" %s\n", q(Restart),
	$self->icon('gtk-refresh');
    $self->getenv();
    $self->default();
    my $wms = $self->get_xsessions();
    foreach (sort keys %$wms) {
	my $wm = $wms->{$_};
	my $name = $wm->{Name};
	$name = $_ unless $name;
	next if $name =~ m{icewm}i;
	my $exec = $wm->{Exec};
	my $icon = $self->icon($wm->{Icon});
	$icon = $self->icon('preferences-system-windows') if $icon eq '-';
	$text .= sprintf("    restart \"Start %s\" %s %s\n",$name,$icon,$exec);
    }
    $text .= sprintf "  }\n";
    return $text;
}

sub appmenu {
    my($self,$entries,$name) = @_;
    my $text = '';
    $text .= sprintf "  menu \"%s\" %s {\n", $name,
	$self->icon(qw(start-here folder));
    $text .= $entries;
    $text .= sprintf "  }\n";
    return $text;
}

# IceWM does not actually support specifying the entire root menu

sub rootmenu {
    my($self,$entries,$name) = @_;
    my $text = '';
    $text .= $entries;
    $text .= $self->wmmenu();
    $text .= 'prog "Refresh Menu" '.$self->icon('gtk-refresh').' xdg-menugen -format icewm -launch >'.$ENV{HOME}.'/.icewm/menu'."\n";
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
            $text .= $self->build($_,$indent.' ');
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
    my $icon = $item->Icon([qw(png svg xpm jpg)]);
    $icon = '-' unless $icon;
    if ($self->{ops}{launch}) {
	return sprintf "%sprog \"%s\" %s xdg-launch %s\n",
	    $indent, $item->Name, $icon, $item->Id;
    } else {
	return sprintf "%sprog \"%s\" %s %s\n",
	    $indent, $item->Name, $icon, $item->Exec;
    }
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $icon = $item->Icon([qw(png svg xpm jpg)]);
    $icon = '-' unless $icon;
    my $text = '';
    $text .= sprintf "%smenu \"%s\" %s {\n",
        $indent, $item->Name, $icon;
    $text .= $self->build($item->{Menu},$indent.' ');
    $text .= sprintf "%s}\n",
        $indent;
    return $text;
}

1;

__END__

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
