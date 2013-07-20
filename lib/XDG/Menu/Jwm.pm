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
    $text .= q(   <Desktops icon="" label="Desktops"/>)."\n";
    $text .= q(   <Menu icon="" label="Window Menu">)."\n";
    $text .= q(      <SendTo/>)."\n";
    $text .= q(      <Stick/>)."\n";
    $text .= q(      <Maximize/>)."\n";
    $text .= q(      <Minimize/>)."\n";
    $text .= q(      <Shade/>)."\n";
    $text .= q(      <Move/>)."\n";
    $text .= q(      <Resize/>)."\n";
    $text .= q(      <Kill/>)."\n";
    $text .= q(      <Close/>)."\n";
    $text .= q(   </Menu>)."\n";
    $text .= q(   <Separator/>)."\n";
    $text .= q(   <Restart label="Restart" icon="restart.png"/>)."\n";
    $text .= q(   <Program icon="lock.png" label="Lock">slock</Program>)."\n";
    $text .= q(   <Exit label="Exit" confirm="true" icon="quit.png"/>)."\n";
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
	$indent, $item->Icon([qw(png xpm)]), $name;
}
sub Separator {
    my ($self,$item,$indent) = @_;
    return sprintf "%s<Separator/>\n", $indent;
}
sub Application {
    my ($self,$item,$indent) = @_;
    my $name = $item->Name; $name =~ s/["]/\\"/g;
    return sprintf "%s<Program icon=\"%s\" label=\"%s\">%s</Program>\n",
	   $indent, $item->Icon([qw(png xpm)]), $name, $item->Exec;
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $text = '';
    if ($item->{Menu}{Elements} and @{$item->{Menu}{Elements}}) {
	my $name = $item->Name; $name =~ s/["]/\\"/g;
	$text .= sprintf "%s<Menu icon=\"%s\" label=\"%s\" labeled=\"false\">\n",
	    $indent, $item->Icon([qw(png xpm)]), $name;
	$text .= $self->build($item->{Menu},$indent.'   ');
	$text .= sprintf "%s</Menu> <!-- %s -->\n",
	    $indent, $item->Name;
    }
    return $text;
}

1;

__END__

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut

