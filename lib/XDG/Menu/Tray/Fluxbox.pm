package XDG::Menu::Tray::Fluxbox;
use base qw(XDG::Menu::Tray);
use strict;
use warnings;

=head1 NAME

 XDG::Menu::Tray::Fluxbox - generate a Fluxbox system tray menu from an XDG::Menu tree

=head1 SYNOPSIS

 my $parser = new XDG::Menu::Parser;
 my $tree = $parser->parse_menu('/etc/xdg/menus/applications.menu');
 my $tray = new XDG::Menu::Tray::Fluxbox;
 my $menu = $tray->create($tree);

=head1 DESCRIPTION

B<XDG::Menu::Tray::Fluxbox> is a module that reads an XDG::Menu::Layout
tree and generates a Gtk2 menu for Fluxbox.

=head1 METHODS

B<XDG::Menu::Tray::Fluxbox> has the following methods:

=over

=item XDG::Menu::Tray::Fluxbox->B<new>() => XDG::Menu::Tray::Fluxbox

Creates a new XDG::Menu::Tray::Fluxbox instance for creating Gtk2 menus.

=cut

sub new {
    return bless {}, shift;
}

=item $tray->B<create>($tree) => Gtk2::Menu

Creates the Gtk2 menu from menu tree, C<$tree>, and returns the menu as
a Gtk2::Menu object.  C<$tree> must have been created as a result of
parsing the XDG menu using XDG::Menu::Parser (see L<XDG::Menu(3pm)>).

=back

=cut

sub create {
    my ($self,$item) = @_;
    my $m = Gtk2::Menu->new;
    $self->build($item,$m);
    my ($mi,$im,$sm);

    $mi = Gtk2::SeparatorMenuItem->new;
    $m->append($mi);

    $sm = Gtk2::Menu->new;

    $mi = Gtk2::ImageMenuItem->new('Fluxbox menu');
    $im = Gtk2::Image->new_from_icon_name('archlinux-wm-fluxbox','menu');
    $mi->set_image($im) if $im;
    $mi->set_submenu($sm);
    $m->append($mi);

    $self->submenu_system_styles($sm);
    $self->submenu_user_styles($sm);
    $self->submenu_backgrounds($sm);

    $mi = Gtk2::ImageMenuItem->new('Workspace List');
    $im = Gtk2::Image->new_from_icon_name('display','menu');
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "fluxbox-remote WorkspaceMenu"});
    $sm->append($mi);

    $self->submenu_tools($sm);
    $self->submenu_window_managers($sm);

    $mi = Gtk2::ImageMenuItem->new('Lock screen');
    $im = Gtk2::Image->new_from_icon_name('gnome-lockscreen','menu');
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "slock &"});
    $m->append($mi);

    $mi = Gtk2::ImageMenuItem->new('Fluxbox Command');
    $im = Gtk2::Image->new_from_icon_name('gtk-execute','menu');
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "fluxbox-remote CommandDialog"});
    $m->append($mi);

    $mi = Gtk2::ImageMenuItem->new('Reload config');
    $im = Gtk2::Image->new_from_icon_name('gtk-revert-to-saved-ltr','menu');
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "fluxbox-remote Reconfig"});
    $m->append($mi);

    $mi = Gtk2::ImageMenuItem->new('Restart');
    $im = Gtk2::Image->new_from_icon_name('gtk-refresh','menu');
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "fluxbox-remote Restart"});
    $m->append($mi);

    $mi = Gtk2::ImageMenuItem->new('About');
    $im = Gtk2::Image->new_from_icon_name('gtk-about','menu');
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "(fluxbox -v; fluxbox -info | sed 1d) | gxmessage -file - -center) &"});
    $m->append($mi);

    $mi = Gtk2::SeparatorMenuItem->new;
    $m->append($mi);

    $mi = Gtk2::ImageMenuItem->new('Exit');
    $im = Gtk2::Image->new_from_icon_name('gtk-quit','menu');
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "fluxbox-remote Exit"});
    $m->append($mi);

    return $m;
}

sub submenu_system_styles {
    my ($self,$menu) = @_;

    my $dir = "/usr/share/fluxbox/styles";
    return unless -d $dir;

    my @styles = ();
    if (opendir(my $fh, $dir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-d "$dir/$f" and -f "$dir/$f/theme.cfg") {
		push @styles, "$dir/$f";
	    }
	    elsif (-f "$dir/$f") {
		push @styles, "$dir/$f";
	    }
	}
	close($fh);
    }
    return unless @styles;

    my ($mi,$im,$sm);

    $sm = Gtk2::Menu->new;
    $mi = Gtk2::ImageMenuItem->new('System Styles');
    $mi->set_tooltip_text('Choose a style...');
    $im = Gtk2::Image->new_from_icon_name('preferences-desktop-theme','menu');
    $mi->set_image($im) if $im;
    $mi->set_submenu($sm);
    $menu->append($mi);

    foreach my $style (sort{$a cmp $b}@styles) {
	my $name = $style; $name =~ s{.*/}{}; $name =~ s{_}{ }g;
	$mi = Gtk2::ImageMenuItem->new($name);
	$im = Gtk2::Image->new_from_icon_name('preferences-desktop-theme','menu');
	$mi->set_image($im) if $im;
	$mi->signal_connect(activate=>sub{system "fluxbox-remote SetStyle $style"});
	$sm->append($mi);
    }
}
sub submenu_user_styles {
    my ($self,$menu) = @_;

    my $dir = "$ENV{HOME}/.fluxbox/styles";
    return unless -d $dir;

    my @styles = ();
    if (opendir(my $fh, $dir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-d "$dir/$f" and -f "$dir/$f/theme.cfg") {
		push @styles, "$dir/$f";
	    }
	    elsif (-f "$dir/$f") {
		push @styles, "$dir/$f";
	    }
	}
	close($fh);
    }
    return unless @styles;

    my ($mi,$im,$sm);

    $sm = Gtk2::Menu->new;
    $mi = Gtk2::ImageMenuItem->new('User Styles');
    $mi->set_tooltip_text('Choose a style...');
    $im = Gtk2::Image->new_from_icon_name('preferences-desktop-theme','menu');
    $mi->set_image($im) if $im;
    $mi->set_submenu($sm);
    $menu->append($mi);

    foreach my $style (sort{$a cmp $b}@styles) {
	my $name = $style; $name =~ s{.*/}{}; $name =~ s{_}{ }g;
	$mi = Gtk2::ImageMenuItem->new($name);
	$im = Gtk2::Image->new_from_icon_name('preferences-desktop-theme','menu');
	$mi->set_image($im) if $im;
	$mi->signal_connect(activate=>sub{system "fluxbox-remote SetStyle $style"});
	$sm->append($mi);
    }
}
sub submenu_backgrounds {
    my ($self,$menu) = @_;

    my @dirs = ( "/usr/share/fluxbox/backgrounds", "$ENV{HOME}/.fluxbox/backgrounds" );
    return unless -d $dirs[0] or -d $dirs[1];

    my @backgrounds;
    foreach my $dir (@dirs) {
	if (opendir(my $fh, $dir)) {
	    foreach my $f (readdir($fh)) {
		next if $f eq '.' or $f eq '..';
		if (-f "$dir/$f" and $f =~ m{\.(png|jpg|xpm)$}) {
		    push @backgrounds,$f;
		}
	    }
	}
    }
    return unless @backgrounds;

    my ($mi,$im,$sm,$ssm);

    $sm = Gtk2::Menu->new;
    $mi = Gtk2::ImageMenuItem->new('Backgrounds');
    $mi->set_tooltip_text('Set the background');
    $im = Gtk2::Image->new_from_icon_name('preferences-desktop-wallpaper','menu');
    $mi->set_image($im) if $im;
    $mi->set_submenu($sm);
    $menu->append($mi);

    my $ssm_numb = 1;
    if (scalar @backgrounds > 25) {
	$ssm = Gtk2::Menu->new;
	$mi = Gtk2::ImageMenuItem->new("Backgrounds $ssm_numb");
	$mi->set_tooltip_text('Set the background');
	$im = Gtk2::Image->new_from_icon_name('preferences-desktop-wallpaper','menu');
	$mi->set_image($im) if $im;
	$mi->set_submenu($ssm);
	$sm->append($mi);
    } else {
	$ssm = $sm;
    }

    my $bg = 0;
    foreach my $background (sort{$a cmp $b}@backgrounds) {
	if ($bg >= 25) {
	    $ssm_numb = $ssm_numb + 1;
	    $ssm = Gtk2::Menu->new;
	    $mi = Gtk2::ImageMenuItem->new("Backgrounds $ssm_numb");
	    $mi->set_tooltip_text('Set the background');
	    $im = Gtk2::Image->new_from_icon_name('preferences-desktop-wallpaper','menu');
	    $mi->set_image($im) if $im;
	    $mi->set_submenu($ssm);
	    $sm->append($mi);
	    $bg = 0;
	}
	$bg = $bg + 1;
	my ($f,$w,$h) = Gtk2::Gdk::Pixbuf->get_file_info($background);
	next unless defined $f;
	my $name = $background; $name =~ s{.*/}{}; $name =~ s{_}{ }g;
	$name =~ s{\.(png|jpg|xpm)$}{};
	eval {my $pb = Gtk2::Gdk::Pixbuf->new_from_file_at_size($background,16,16);};
	next unless $pb;
	$mi = Gtk2::ImageMenuItem->new($name);
	$im = Gtk2::Image->new_from_pixbuf($pb);
	$mi->set_image($im) if $im;
	if ($h < 480 or $w < 640) {
	    $mi->signal_connect(activate=>sub{system "fbsetbg -t $background"});
	} else {
	    $mi->signal_connect(activate=>sub{system "fbsetbg -f $background"});
	}
	$ssm->append($mi);
    }
}
sub submenu_tools {
    my ($self,$menu) = @_;
    my ($mi,$im,$sm);

    $sm = Gtk2::Menu->new;
    $mi = Gtk2::ImageMenuItem->new('Tools');
    $im = Gtk2::Image->new_from_icon_name('preferences-other','menu');
    $mi->set_image($im) if $im;
    $mi->set_submenu($sm);
    $menu->append($mi);

    $mi = Gkt2::ImageMenuItem->new('Fluxbox panel');
    $im = Gtk2::Image->new_from_icon_name('fbpanel','menu');
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "fbpanel &"});
    $sm->append($mi);

    $mi = Gtk2::ImageMenuItem->new('Screenshot - JPG');
    $im = Gtk2::Image->new_from_icon_name('screenshot','menu');
    $im = Gtk2::Image->new_from_icon_name('applets-screenshooter','menu') unless $im;
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "import screenshot.jpg && display -resize 50% screenshot.jpg &"});
    $sm->append($mi);

    $mi = Gtk2::ImageMenuItem->new('Screenshot - PNG');
    $im = Gtk2::Image->new_from_icon_name('screenshot','menu');
    $im = Gtk2::Image->new_from_icon_name('applets-screenshooter','menu') unless $im;
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "import screenshot.png && display -resize 50% screenshot.png &"});
    $sm->append($mi);

    $mi = Gtk2::ImageMenuItem->new('Run');
    $im = Gkt2::Image->new_from_icon_name('gtk-execute','menu');
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>sub{system "fbrun -font 10x20 -fg grey -bg black -title run &"});
    $sm->append($mi);

    $mi = Gtk2::ImageMenuItem->new('Regen Menu');
    $im = Gtk2::Image->new_from_icon_name('gtk-refresh','menu');
    $mi->set_image($im) if $im;
    $mi->signal_connect(activate=>'Regenerate');
    $sm->append($mi);
}
sub submenu_window_managers {
    my ($self,$menu) = @_;
    my ($mi,$im,$sm);

    $sm = Gtk2::Menu->new;
    $mi = Gtk2::ImageMenuItem->new('Window Managers');
    $im = Gtk2::Image->new_from_icon_name('display','menu');
    $mi->set_image($im) if $im;
    $mi->set_submenu($sm);
    $menu->append($mi);

    foreach my $wm (qw(mwm twm wmii icewm fvwm openbox fvwm2 blackbox wmaker)) {
	$mi = Gtk2::ImageMenuItem->new($wm);
	$im = Gtk2::Image->new_from_icon_name($wm,'menu');
	$mi->set_image($im) if $im;
	$mi->signal_connect(activate=>sub{system "fluxbox-remote Restart $wm"});
	$sm->append($mi);
    }
}
