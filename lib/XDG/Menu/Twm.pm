package XDG::Menu::Twm;
use strict;
use warnings;

=head1 NAME

XDG::Menu::Twm - generate a TWM menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_menu('/etc/xdg/menus/applications.menu');
 my $twm = new XDG::Menu::Twm;
 print $twm->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Twm> is a module that reads an XDG::Menu::Layout tree and
generates a L<twm(1)> style menu.

=head1 METHODS

B<XDG::Menu::Twm> has the following methods:

=over

=item XDG::Menu::Twm->B<new>() => XDG::Menu::Twm

Creates a new XDG::Menu::Twm instance for creating blackbox menus.

=cut

sub new { return bless {}, shift }

=item $twm->B<create>(I<$tree>) => scalar

Creates a twm menu from menu tree, I<$tree>, and returns the menu in a
scalar string.  I<$tree> must have been created as a result of parsing
the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

=cut

my $SEPARATOR = '"'.('-' x 32).'"';

sub create {
    my ($self,$item) = @_;
    $self->{menus} = [];
    my $text = '';
    $text .= "Menu \"defops\"\n";
    $text .= "{\n";
    $text .= sprintf("    %-20s  %s\n",'"Twm"',		'f.title');
    $text .= sprintf("    %-20s  %s\n",'"Iconify"',	'f.iconify');
    $text .= sprintf("    %-20s  %s\n",'"Resize"',	'f.resize');
    $text .= sprintf("    %-20s  %s\n",'"Move"',	'f.move');
    $text .= sprintf("    %-20s  %s\n",'"Raise"',	'f.raise');
    $text .= sprintf("    %-20s  %s\n",'"Lower"',	'f.lower');
    $text .= sprintf("    %-20s  %s\n",$SEPARATOR,	'f.nop');
#   $text .= sprintf("    %-20s  %s\n",'"Applications"','f.menu "Applications"');
    $text .= $self->build($item);
    $text .= sprintf("    %-20s  %s\n",$SEPARATOR,	'f.nop');
    $text .= sprintf("    %-20s  %s\n",'"Focus"',	'f.focus');
    $text .= sprintf("    %-20s  %s\n",'"Unfocus"',	'f.unfocus');
    $text .= sprintf("    %-20s  %s\n",'"Show Iconmgr"','f.showiconmgr');
    $text .= sprintf("    %-20s  %s\n",'"Hide Iconmgr"','f.hideiconmgr');
    $text .= sprintf("    %-20s  %s\n",$SEPARATOR,	'f.nop');
    $text .= sprintf("    %-20s  %s\n",'"Xterm"',	'f.exec "exec xterm &"');
    $text .= sprintf("    %-20s  %s\n",$SEPARATOR,	'f.nop');
    $text .= sprintf("    %-20s  %s\n",'"Kill"',	'f.destroy');
    $text .= sprintf("    %-20s  %s\n",'"Delete"',	'f.delete');
    $text .= sprintf("    %-20s  %s\n",$SEPARATOR,	'f.nop');
    $text .= sprintf("    %-20s  %s\n",'"Restart"',	'f.restart');
    $text .= sprintf("    %-20s  %s\n",'"Exit"',	'f.quit');
    $text .= "}\n";
    push @{$self->{menus}}, $text;
    return join("\n\n",@{$self->{menus}});
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
    return sprintf "    %-20s f.title\n", '"'.$name.'"';
}
sub Separator {
    my($self,$item) = @_;
    return sprintf "    %-20s f.nop\n", $SEPARATOR;
}
sub Application {
    my($self,$item) = @_;
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    my $exec = $item->Exec; $exec =~ s/["]/\\"/g;
    return sprintf "    %-20s f.exec \"exec %s &\"\n",
	   '"'.$name.'"', $exec;
}
sub Directory {
    my($self,$item) = @_;
    my $menu = $item->{Menu};
    my $text = '';
    # no empty menus...
    return $text unless @{$menu->{Elements}};
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    $text .= sprintf "Menu \"%s\"\n{\n", $name;
    $text .= sprintf "    %-20s f.title\n",'"'.$name.'"';
    $text .= $self->build($menu);
    $text .= "}\n";
    push @{$self->{menus}}, $text;
    return sprintf "    %-20s f.menu \"%s\"\n",'"'.$name.'"',$name;
}

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
