package XDG::Menu::Openbox3;
use strict;
use warnings;

=head1 NAME

 XDG::Menu::Openbox3 - generate an Openbox menu from an XDG::Menu tree

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menus/applications.menu');
 my $openbox = new XDG::Menu::Openbox3;
 print $openbox->create($tree);

=head1 METHODS

B<XDG::Menu::Openbox> has the folllowing methods:

=over

=item XDG::Menu::Openbox3->B<new>($tree) => XDG::Menu::Openbox3

Creates a new XDG::Menu::Openbox3 instance for creating Openbox XML menus.

=cut

sub new {
    return bless {
        menus => [],
        texts => [],
        numbs => [],
        number => 1,
    }, shift;
}

=item $openbox->B<create>($tree) => scalar

Creates the Openbox menu from menu tree, C<$tree>, and returns the menu
in a scalar string.  C<$tree> must have been created as the result of
parsing the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

=cut

sub create {
    my ($self,$item) = @_;
    my $text = '';
    $text .= $self->build($item,'  ');
    return $text;
}
sub build {
    my ($self,$item,$indent) = @_;
    my $name = ref($item);
    $name =~ s{.*\:\:}{};
    return $self->$name($item,$indent) if $self->can($name);
    return '';
}

# Creation of the openbox XML menu is quite different from other menus
# because menu definitions are not nested.  Each menu is defined in a
# list (from deepest to shallowest).  Menus that contain other menus are
# referred to by name rather than being nested in the superior menu's
# definition.  So, what we need to do is stack the definitions as we go
# down and then spit them out as we come back up.

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
}
sub Separator {
    my ($self,$item,$indent) = @_;
}
sub Application {
    my ($self,$item,$indent) = @_;
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $text = '';
    my $menu = $item->{Menu};
    $self->{number} += 1;
    my $numb = $self->{number};
    unshift @{$self->{menus}}, $menu;
    unshift @{$self->{texts}}, $text;
    unshift @{$self->{numbs}}, $numb;
    $text .= $self->build($menu,$indent.'  ');
    shift @{$self->{numbs}};
    $self->{text} .= shift @{$self->{texts}};
    shift @{$self->{menus}};
    return $text;
}

1;

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut


