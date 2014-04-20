package XDG::Menu::Tray::Base;
use base qw(XDG::Menu::Base);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDG::Menu::Tray::Base - base module for WM-specific menu generators

=head1 DESCRIPTION

This module provides a base for WM-specific menu generators and contains
common methods.  It is not intnded on being instantiated directly.

=head1 METHODS

The following methods are provided:

=over

=item $base->B<wmmenu>(I<$current>) => Gtk2::ImageMenuItem

Generates a Gtk2::Menu of alternate window managers to launch.  Returns
a menu item for selecting alternate window managers.  I<$current> is the
name of the current window manager.

=cut

sub wmmenu {
    my ($self,$current) = @_;
    $current = '' unless $current;
    my $menu = Gtk2::Menu->new;
    my $item = Gtk2::ImageMenuItem->new('Window Managers');
    my $im = Gtk2::Image->new_from_icon_name('display','menu');
    $item->set_image($im) if $im;
    $item->set_submenu($menu);

    my $wms = $self->get_xsessions();
    foreach (sort keys %$wms) {
	my $wm = $wms->{$_};
	my $name = $wm->{Name};
	next if "\L$name\E" eq "\L$current\E";
	$name =~ s{_}{ }g; # get rid of accelerators
	my $exec = $wm->{Exec};
	my $icon = $self->icon($wm->{Icon},qw(png xpm svg jpg));
	my $mi = Gkt2::ImageMenuItem->new($name);
	my $pb = Gtk2::Gdk::Pixbuf->new_from_file_at_size($icon,16,16) if $icon;
	my $im = Gtk2::Image->new_from_pixbuf($pb) if $pb;
	$mi->set_image($im) if $im;
	{
	    my $tool = '';
	    $tool .= "<b>Name:</b> $wm->{Name}\n";
	    $tool .= "<b>GenericName:</b> ";
	    $tool .= $wm->{GenericName} if $wm->{GenericName};
	    $tool .= "\n";
	    $tool .= "<b>Comment:</b> ";
	    $tool .= $wm->{Comment} if $wm->{Comment};
	    $tool .= "\n";
	    $tool .= "<b>Exec:</b> ";
	    $tool .= $wm->{Exec} if $wm->{Exec};
	    $tool .= "\n";
	    $tool .= "<b>Icon:</b> ";
	    $tool .= $wm->{Icon} if $wm->{Icon};
	    $tool .= "\n";
	    $tool .= "<b>Categories:</b> ";
	    $tool .= $wm->{Categories} if $wm->{Categories};
	    $tool .= "\n";
	    $tool .= "<b>file:</b> ";
	    $tool .= $wm->{file} if $wm->{file};
	    $tool .= "\n";
	    $tool .= "<b>icon:</b> ";
	    $tool .= $icon if $icon;
	    $tool .= "\n";
	    $mi->set_tooltip_markup($tool) if $tool;
	}
	$mi->signal_connect(activate=>sub{system $wm->Exec.' &'});
	$mi->show_all;
	$menu->append($mi);
    }
    return $item;
}

=item $base->B<wsmenu>() => Gtk2::ImageMenuItem

Creates a workspaces menu that contains all of the workspaces and
clients in each workspace along with the actions for activating a
client.

=cut

sub wsmenu {
    my $self = shift;
    my $screen = Gnome2::Wnck::Screen->get_default;
    my $menu = Gtk2::Menu->new;
    my $item = Gtk2::ImageMenuItem->new('Window Menu');
    my $im = Gtk2::Image->new_from_icon_name('display','menu');
    $item->set_image($im) if $im;
    $item->set_submenu($menu);
    my @windows = $screen->get_windows;
    for (my $n = 0;$n < $screen->get_workspace_count;$n++) {
	my $workspace = $screen->get_workspace($n);
	my $name = $workspace->get_name;
	$name = '' unless $name;
	my $wm = Gtk2::Menu->new;
	my $mi = Gtk2::ImageMenuItem->new(sprintf("Workspace %d: %s", $n+1, $name));
	my $im = Gtk2::Image->new_from_icon_name('display','menu');
	$mi->set_image($im) if $im;
	$mi->set_submenu($wm);
	$mi->show_all;
	$mi->append($menu);
	foreach my $win (@windows) {
	    continue unless $win->is_visible_on_workspace($workspace);
	    continue if $win->is_sticky;
	    continue if $win->is_skip_tasklist;
	    my $name = $win->get_name;
	    $name = '' unless $name;
	    $name =~ s{_}{ }g; # remove accelerators
	    $name = substr($name,0,37).'...' if length($name) > 40;
	    my $wi = Gtk2::ImageMenuItem->new($name);
	    my $pb = $win->get_icon;
	    $pb = $pb->scale_simple(16,16,'bilinear') if $pb;
	    my $iw = Gtk2::Image->new_from_pixbuf($pb) if $pb;
	    $wi->set_image($iw) if $iw;
	    $wi->signal_connect(activate=>sub{$win->activate(0)});
	    $wi->show_all;
	    $wi->append($wm);
	}
    }
    my $wm = Gtk2::Menu->new;
    my $mi = Gtk2::ImageMenuItem->new('Workspace All');
    my $im = Gtk2::Image->new_from_icon_name('display','menu');
    $mi->set_image($im) if $im;
    $mi->set_submenu($wm);
    $mi->show_all;
    $mi->append($menu);
    foreach my $win (@window) {
	continue unless $win->is_sticky;
	continue if $win->is_skip_tasklist;
	my $name = $win->get_name;
	$name = '' unless $name;
	$name =~ s{_}{ }g; # remove accelerators
	$name = substr($name,0,37).'...' if length($name) > 40;
	my $wi = Gtk2::ImageMenuItem->new($name);
	my $pb = $win->get_icon;
	$pb = $pb->scale_simple(16,16,'bilinear') if $pb;
	my $iw = Gtk2::Image->new_from_pixbuf($pb) if $pb;
	$wi->set_image($iw) if $iw;
	$wi->signal_connect(activate=>sub{$win->activate(0)});
	$wi->show_all;
	$wi->append($wm);
    }
    return $item;
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDG::Menu(3pm)>,
L<XDG::Menu::Base(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
