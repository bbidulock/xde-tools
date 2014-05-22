package XDG::Menu::Tray;
use base qw(XDG::Menu::Base);
use Gtk2;
use strict;
use warnings;

=head1 NAME

 XDG::Menu::Tray - generate a system tray menu from an XDG::Menu tree

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_menu('/etc/xdg/menus/applications.menu');
 my $tray = new XDG::Menu::Tray;
 my $menu = $tray->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Tray> is a module that reads an XDG::Menu::Layout tree and
generates a Gtk2 menu.

=head1 METHODS

B<XDG::Menu::Tray> has the following methods:

=over

=item $tray->B<create>($tree) => Gtk2::Menu

Creates the Gtk2 menu from menu tree, C<$tree>, and returns the menu as
a Gtk2::Menu object.  C<$tree> must have been created as the result of
parsing the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

=cut

sub apply_style {
    my ($self,$widget) = @_;
    if (my $style = $self->{style}) {
	print STDERR "Setting style for $widget...\n";
	$widget->modify_style($style);
	if ($widget->isa('Gtk2::Container')) {
	    print STDERR "Setting style for children of $widget...\n";
	    my @children = ($widget->get_children);
	    foreach (@children) {
		print STDERR "Setting style for child $_ of $widget...\n";
		$self->apply_style($_);
	    }
	}
	if ($widget->isa('Gtk2::Bin')) {
	    if (my $child = $widget->get_child) {
		print STDERR "Setting style for child $child of $widget...\n";
		$self->apply_style($child);
	    }
	}
    }
}
sub make_transparent {
    my $menu = shift;
    my $window = $menu->get_parent_window;
    $window->set_opacity(0.92) if $window;
    return Gtk2::EVENT_PROPAGATE;
}

sub create {
    my ($self,$item) = @_;
    my $m = Gtk2::Menu->new;
    $self->apply_style($m);
    $m->signal_connect(map=>\&make_transparent);

    my $mi = Gtk2::TearoffMenuItem->new;
    $self->apply_style($mi);
    $mi->show_all;
    $m->append($mi);

    $self->build($item,$m);

    $mi = Gtk2::SeparatorMenuItem->new;
    $self->apply_style($mi);
    $mi->show_all;
    $m->append($mi);

    $mi = Gtk2::ImageMenuItem->new;
    $self->apply_style($mi);
    $mi->set_label('Run');
    my $im = Gtk2::Image->new_from_icon_name('gtk-execute','menu');
    $self->apply_style($im) if $im;
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "fbrun &"});
    $mi->show_all;
    $m->append($mi);

    $mi = Gtk2::SeparatorMenuItem->new;
    $self->apply_style($mi);
    $mi->show_all;
    $m->append($mi);

    $mi = Gtk2::ImageMenuItem->new;
    $self->apply_style($mi);
    $mi->set_label('Exit');
    $im = Gtk2::Image->new_from_icon_name('system-log-out','menu');
    $self->apply_style($im) if $im;
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "xde-logout"});
    $mi->show_all;
    $m->append($mi);

    return $m;
}
sub build {
    my ($self,$item,$menu) = @_;
    my $name = ref($item);
    $name =~ s{.*\:\:}{};
    $self->$name($item,$menu) if $self->can($name);
}

sub Menu {
    my ($self,$item,$menu) = @_;
    foreach (@{$item->{Elements}}) {
	next unless $_;
	$self->build($_,$menu);
    }
}
sub Header {
    my ($self,$item,$menu) = @_;
    my $name = $item->Name; $name =~ s{_}{ }g; # get rid of accellerators
    my $mi = Gtk2::ImageMenuItem->new;
    $self->apply_style($mi);
    $mi->set_label($name);
    if (my $tool = $item->{Entry}{Comment}) {
	$mi->set_tooltip_text($tool);
    }
    my $fi = $item->Icon([qw(png xpm svg jpg)]);
    my $pb = Gtk2::Gdk::Pixbuf->new_from_file_at_size($fi,16,16) if $fi;
    my $im = Gtk2::Image->new_from_pixbuf($pb) if $pb;
    $self->apply_style($im) if $im;
    $mi->set_image($im) if $im;
    $mi->show_all;
    $menu->append($mi);
}
sub Separator {
    my ($self,$item,$menu) = @_;
    my $mi = Gtk2::SeparatorMenuItem->new;
    $self->apply_style($mi);
    $mi->show_all;
    $menu->append($mi);
}
sub Application {
    my ($self,$item,$menu) = @_;
    my $name = $item->Name; $name =~ s{_}{ }g; # get rid of accellerators
    my $mi = Gtk2::ImageMenuItem->new;
    $self->apply_style($mi);
    $mi->set_label($name);
    my $fi = $item->Icon([qw(png xpm svg jpg)]);
    if (1) {
	my $tool = '';
	$tool .= "<b>Name:</b> $item->{Entry}{Name}\n";
	$tool .= "<b>GenericName:</b> ";
	$tool .= $item->{Entry}{GenericName} if $item->{Entry}{GenericName};
	$tool .= "\n";
	$tool .= "<b>Comment:</b> ";
	$tool .= $item->{Entry}{Comment} if $item->{Entry}{Comment};
	$tool .= "\n";
	$tool .= "<b>Exec:</b> ";
	$tool .= $item->{Entry}{Exec} if $item->{Entry}{Exec};
	$tool .= "\n";
	$tool .= "<b>Icon:</b> ";
	$tool .= $item->{Entry}{Icon} if $item->{Entry}{Icon};
	$tool .= "\n";
	$tool .= "<b>Categories:</b> ";
	$tool .= $item->{Entry}{Categories} if $item->{Entry}{Categories};
	$tool .= "\n";
	$tool .= "<b>file:</b> $item->{Entry}{file}\n";
	$tool .= "<b>icon_file:</b> ";
	$tool .= $fi if $fi;
	$tool =~ s{\&}{\&amp;}g;
	$mi->set_tooltip_markup($tool) if $tool;
    } else {
	if (my $tool = $item->{Entry}{Comment}) {
	    $mi->set_tooltip_text($tool);
	}
    }
    my $pb = Gtk2::Gdk::Pixbuf->new_from_file_at_size($fi,16,16) if $fi;
    my $im = Gtk2::Image->new_from_pixbuf($pb) if $pb;
    $self->apply_style($im) if $im;
    $mi->set_image($im) if $im;
    if ($self->{ops}{launch}) {
	$mi->signal_connect(activate=>sub{system "xdg-launch --pointer ".$item->{Entry}{file}.' &'});
    } else {
	$mi->signal_connect(activate=>sub{system $item->Exec.' &'});
    }
    $mi->show_all;
    $menu->append($mi);
}
sub Directory {
    my ($self,$item,$menu) = @_;
    my $name = $item->Name; $name =~ s{_}{ }g; # get rid of accellerators
    my $imenu = $item->{Menu};
    # no empty menus
    return unless $imenu->{Elements} and @{$imenu->{Elements}};
    my $m = Gtk2::Menu->new;
    $self->apply_style($m);
    $m->signal_connect(map=>\&make_transparent);
    $self->build($imenu,$m);
    my $mi = Gtk2::ImageMenuItem->new;
    $self->apply_style($mi);
    $mi->set_label($name);
    if (my $tool = $item->{Entry}{Comment}) {
	$mi->set_tooltip_text($tool);
    }
    my $fi = $item->Icon([qw(png xpm svg jpg)]);
    my $pb = Gtk2::Gdk::Pixbuf->new_from_file_at_size($fi,16,16) if $fi;
    my $im = Gtk2::Image->new_from_pixbuf($pb) if $pb;
    $self->apply_style($im) if $im;
    $mi->set_image($im) if $im;
    $mi->set_submenu($m);
    $mi->show_all;
    $menu->append($mi);
}

1;

__END__

=head1 SEE ALSO

L<XDG::Menu(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
