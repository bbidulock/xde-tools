package XDG::Menu::Openbox;
use strict;
use warnings;

=head1 NAME

 XDG::Menu::Openbox - generate an Openbox menu from an XDG::Menu tree.

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_uri('/etc/xdg/menus/applications.menu');
 my $openbox = new XDG::Menu::Openbox;
 print $openbox->create($tree);

=head1 METHODS

B<XDG::Menu::Openbox> has the folllowing methods:

=over

=item XDG::Menu::Openbox->B<new>($tree) => XDG::Menu::Openbox

Creates a new XDG::Menu::Openbox instance for creating Openbox menus.

=cut

sub new {
    return bless {}, shift;
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
    $text .= $self->build($item,' ');
    $text .= "  [separator]\n";
    $text .= "  [config] (Configuration)\n";
    $text .= "    [workspaces] (Workspace)\n";
    $text .= "    [submenu] (System Styles) {Choose a style...}\n";
    $text .= "      [sytlesdir] (/usr/share/openbox/styles)\n";
    $text .= "    [end] # (System Styles)\n";
    $text .= "    [submenu] (User Styles) {Choose a style...}\n";
    $text .= "      [sytlesdir] (~/.openbox/styles)\n";
    $text .= "      [sytlesdir] (~/.config/openbox/styles)\n";
    $text .= "    [end] # (User Styles)\n";
    $text .= "    [separator]\n";
    $text .= "    [submenu] (Window Managers)\n";
    $text .= "      [restart] (Fluxbox) {/usr/bin/fluxbox}\n";
    $text .= "      [restart] (Blackbox) {/usr/bin/blackbox}\n";
    $text .= "      [restart] (Openbox) {/usr/bin/openbox}\n";
    $text .= "      [restart] (WindowMaker) {/usr/bin/wmaker}\n";
    $text .= "      [restart] (IceWM) {/usr/bin/icewm-session}\n";
    $text .= "      [restart] (LXDE) {/usr/bin/startlxde}\n";
    $text .= "    [end] # (Window Managers)\n";
    $text .= "    [separator]\n";
    $text .= "    [exec] (Run Command) {bbrun -a -w}\n";
    $text .= "    [exec] (Lock Screen) {xlock}\n";
    $text .= "    [restart] (Restart) {}\n";
    $text .= "    [exit] (Logout)\n";
    $text .= "  [end] # (Configuration)\n";
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
    return sprintf "%s[nop] (%s) <%s>\n",
       $indent, $name, $item->Icon([qw(png svg xpm)]);
}
sub Separator {
    my ($self,$item,$indent) = @_;
    return sprintf "%s[separator]\n",
        $indent;
}
sub Application {
    my ($self,$item,$indent) = @_;
    my $name = $item->Name; $name =~ s/[)]/\\)/g;
    return sprintf "%s[exec] (%s) {%s} <%s>\n",
        $indent, $name, $item->Exec,
        $item->Icon([qw(png svg xpm)]);
}
sub Directory {
    my ($self,$item,$indent) = @_;
    my $text = '';
    my $name = $item->Name; $name =~ s/[)]/\\)/g;
    $text .= sprintf "%s[submenu] (%s) {%s} <%s>\n",
        $indent, $name, $item->Name." Menu",
        $item->Icon([qw(png svg xpm)]);
    $text .= $self->build($item->{Menu},$indent.'  ');
    $text .= sprintf "%s[end] # (%s)\n",
        $indent, $name;
    return $text;
}

1;

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut


