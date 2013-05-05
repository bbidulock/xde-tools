package XDG::Menu::Icewm;
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

=item XDG::Menu::Icewm->B<new>($tree) => XDG::Menu::Icewm

Creates a new XDG::Menu::Icewm instance for creating IceWM menus.

=cut

sub new {
    return bless {}, shift;
}

=item $icewm->B<create>($tree) => scalar

Creates the IceWM menu from menu tree, C<$tree>, and returns the menu
in a scalar string.  C<$tree> must have been created as the result of
parsing the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

=cut

sub create {
    my ($self,$item) = @_;
    return $self->build($item,' ');
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
    my $icon = $item->Icon([qw(png xpm)]);
    $icon = '-' unless $icon;
    return sprintf "%sprog \"%s\" %s %s\n",
        $indent, $item->Name, $icon, $item->Exec;
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $icon = $item->Icon([qw(png xpm)]);
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

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut

