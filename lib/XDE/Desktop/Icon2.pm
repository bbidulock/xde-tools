package XDE::Desktop::Icon2;
use URI::file;
use File::stat;
use Fcntl qw(S_IRUSR S_IWUSR S_IXUSR :mode);
use Time::gmtime;
use X11::Protocol;
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Icon2 -- base class for desktop icons (take 2)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

=item XDE::Desktop::Icon2->B<new>(I<$desktop>,I<$icon_name>,I<$label>) => $Icon

Create an new instance of an XDE::Desktop::Icon2.  This base class
constructor is meant to be called only from the derived classes
L<XDE::Desktop::Icon::Shortcut(3pm)>,
L<XDE::Desktop::Icon::Directory(3pm)> and
L<XDE::Desktop::Icon::File(3pm)>.  C<$desktop> is an instance of an
L<XDE::Desktop(3pm)> providing the content for the icon, C<$icon_name>,
which is the icon name to provide, and I<$label> is the label to use for
the desktop icon.

=cut

my %PIXBUFS;

sub new {
    my ($type,$pixbuf,$label) = @_;
    return bless {
	pixbuf=>$pixbuf,
	label=>$label,
    }, $type;
}

sub new_from_names {
    my ($type,$names,$label,$id) = @_;
    my @names = (ref($names) eq 'ARRAY')?( @$names ):( $names );
    my $pixbuf;
    unless ($pixbuf = $PIXBUFS{$id}) {
	my $theme = Gtk2::IconTheme->get_default;
	foreach my $n (@names) {
	    if ($theme->has_icon($n)) {
		$pixbuf = $theme->load_icon($n,48,['generic-fallback','use-builtin']);
	    }
	    last if $pixbuf;
	}
    }
    return undef unless $pixbuf;
    $PIXBUFS{$id} = $pixbuf;
    return new($type,$pixbuf,$label);
}

sub new_from_mime {
    my ($type,$label,$mime,@names) = @_;
    my $icons = XDE::Desktop2->get_icons($mime);
    push @$icons,@names;
    my $self = new_from_names($type,$icons,$label,$mime);
    $self->{mime} = $mime if $self;
    return $self;
}

sub new_from_file {
    my ($type,$filename) = @_;
    my $label = $filename; $label =~ s{/*$}{}; $label =~ s{.*/}{};
    my $mime = XDE::Desktop2->get_mime_type($filename);
    unless ($mime) {
	warn "No mime type for filename $filename";
	return undef;
    }
    return new_from_mime($type,$label,$mime,'gtk-file');
}

sub new_from_directory {
    my ($type,$directory) = @_;
    my $label = $directory; $label =~ s{/*$}{}; $label =~ s{.*/}{};
    my $mime = XDE::Desktop2->get_mime_type($directory);
    unless ($mime) {
	warn "No mime type for directory $directory";
	return undef;
    }
    return new_from_mime($type,$label,$mime,'folder');
}

sub new_from_unknown {
    my ($type,$unknown) = @_;
    my $label = $unknown; $label =~ s{/*$}{}; $label =~ s{.*/}{};
    my $mime = XDE::Desktop2->get_mime_type($unknown);
    unless ($mime) {
	warn "No mime type for object $unknown";
	return undef;
    }
    return new_from_mime($type,$label,$mime,'gtk-missing-image');
}

sub new_from_path {
    my ($type,$path) = @_;
    my $self;
    if (-f $path) {
	$self = new_from_file(@_);
    }
    elsif (-d $path) {
	$self = new_from_directory(@_);
    }
    else {
	$self = new_from_unknown(@_);
    }
    $self->{path} = $path if $self;
    return $self;
}

sub new_from_entry {
    my ($type,$path,$entry) = @_;
    my @icons = ( $entry->{Icon} );
    my $mime = XDE::Desktop2->get_mime_type($path) if $path;
    push @icons, @{XDE::Desktop2->get_icons($mime)} if $mime;
    if ($entry->{Type} eq 'Application' or $entry->{Type} = 'XSession') {
	push @icons, 'exec';
    }
    elsif ($entry->{Type} eq 'Directory') {
	push @icons, 'folder';
    }
    elsif ($entry->{Type} eq 'Link') {
	push @icons, 'exec'; # for now
    }
    else {
	warn "Unknown desktop entry type $entry->{Type}";
	return undef;
    }
    my $self = new_from_names($type,\@icons,$entry->{Name},$entry->{id});
    if ($self) {
	$self->{entry} = $entry;
	$self->{path} = $path;
	$self->{mime} = $mime;
    }
    return $self;
}

=item $icon->B<create>() => $widget

Create a widget for the desktop icon.

=cut

sub create1 {
    my $self = shift;
    my $label = $self->{label};
    my $pixbuf = $self->{pixbuf};
    my $icon = $self->{gtk}{icon} = Gtk2::Image->new_from_pixbuf($pixbuf);
    $icon->set_alignment(0.5,0.5);
    $icon->set_padding(0,0);
    $icon->set_size_request(48,48);
#   $icon->set_tooltip_text($label);
    $icon->signal_connect(state_changed=>sub{
	    my ($widget,$state) = @_;
	    print "$widget state changed to $state\n";
	    return Gtk2::EVENT_PROPAGATE;
	    });

    my $but;
    $but = $self->{gtk}{widget} = Gtk2::HBox->new;
    $but->set_border_width(0);
    $but->set_size_request(&XDE::Desktop2::ICON_WIDE,&XDE::Desktop2::ICON_HIGH);
#   $but->set_relief('none');
    my $v = Gtk2::VBox->new(FALSE,0);
    $but->add($v);
    $v->pack_start($icon,TRUE,FALSE,0);
    my $h = Gtk2::HBox->new(TRUE,0);
    $v->pack_start($h,TRUE,FALSE,0);
    my $l = $self->{gtk}{label} = Gtk2::Label->new;
    $l->set_size_request(-1,-1);
    $l->set_padding(0,0);
    $l->set_line_wrap(TRUE);
    my $n_chars = int((&XDE::Desktop2::ICON_WIDE+8)/8);
#   $l->set_max_width_chars($n_chars);
    $l->set_width_chars($n_chars);
    $l->set_justify('center');
    my $wrap_mode = 'word-char';
    my $short = $label;
    if (length($short) > ($n_chars*2-3)) {
	$short =~ s{\.[^\.]*$}{};
	if (length($short) > ($n_chars*2-3)) {
	    $short = substr($short,0,$n_chars*2-3).'...';
	    $wrap_mode = 'char';
	}
    }
    $l->set_line_wrap_mode($wrap_mode);
    $l->set_markup("<span font=\"Liberation Sans Bold 8\">$short</span>");
    $l->set_alignment(0.5,0.5);
    $l->set_tooltip_text($label) unless $short eq $label;
    $h->pack_start($l,FALSE,FALSE,0);
    $but->show_all;
    return $but;
}

sub create2 {
    my $self = shift;
    my $label = $self->{label};
    my $pixbuf = $self->{pixbuf};
    my $icon = $self->{gtk}{icon} = Gtk2::Image->new_from_pixbuf($pixbuf);
    $icon->set_alignment(0.5,0.5);
    $icon->set_padding(0,0);
    $icon->set_size_request(48,48);

    my $but;
    $but = $self->{gtk}{widget} = Gtk2::Button->new;
    $but->set_size_request(&XDE::Desktop2::ICON_WIDE,&XDE::Desktop2::ICON_HIGH);
    $but->set_alignment(&XDE::Desktop2::ICON_WIDE,&XDE::Desktop2::ICON_HIGH);
    $but->set_border_width(0);
    $but->set_relief('none');
    #$but->set_tooltip_text($label);
    my $v = Gtk2::VBox->new(FALSE,0);
    $but->add($v);
    $v->pack_start($icon,TRUE,FALSE,0);
    my $h = Gtk2::HBox->new(TRUE,0);
    $v->pack_start($h,TRUE,FALSE,0);
    my $l = $self->{gtk}{label} = Gtk2::Label->new;
    $l->set_size_request(-1,-1);
    $l->set_padding(0,0);
    $l->set_line_wrap(TRUE);
    my $n_chars = int((&XDE::Desktop2::ICON_WIDE+8)/8);
#   $l->set_max_width_chars($n_chars);
    $l->set_width_chars($n_chars);
    $l->set_justify('center');
    my $wrap_mode = 'word-char';
    my $short = $label;
    if (length($short) > ($n_chars*2-3)) {
	$short =~ s{\.[^\.]*$}{};
	if (length($short) > ($n_chars*2-3)) {
	    $short = substr($short,0,$n_chars*2-3).'...';
	    $wrap_mode = 'char';
	}
    }
    $l->set_line_wrap_mode($wrap_mode);
    $l->set_markup("<span font=\"Liberation Sans Bold 8\">$short</span>");
    $l->set_alignment(0.5,0.5);
    $l->set_tooltip_text($label) unless $short eq $label;
    $h->pack_start($l,FALSE,FALSE,0);
    $but->show_all;
    $but->signal_connect_swapped(button_press_event=>sub{
	    my ($self,$event,$widget) = @_;
	    if ($event->button == 3) {
		$self->popup($event);
		return Gtk2::EVENT_STOP;
	    }
#	    we want 'clicked' to execute this
#	    elsif ($event->button == 1) {
#		$self->click();
#		return Gtk2::EVENT_STOP;
#	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);
    $but->signal_connect_swapped(clicked=>sub{
	    my ($self,$widget) = @_;
	    $self->click;
	    return Gtk2::EVENT_STOP;
    },$self);
    $but->signal_connect(leave_notify_event=>sub{
	    my ($widget,$event) = @_;
	    my $alloc = $widget->allocation;
	    my ($x,$y,$w,$h) = ($alloc->x,$alloc->y,$alloc->width,$alloc->height);
	    my $window = $widget->window;
	    $window->clear_area_e($x,$y,$w,$h);
	    return Gtk2::EVENT_PROPAGATE;
    });
    return $but;
}

sub create3 {
    my $self = shift;
    my $label = $self->{label};
    my $pixbuf = $self->{pixbuf};
    my $icon = $self->{gtk}{icon} = Gtk2::Image->new_from_pixbuf($pixbuf);
    $icon->set_alignment(0.5,0.5);
    $icon->set_padding(0,0);
    $icon->set_size_request(48,48);

    my $ibox = Gtk2::EventBox->new;
    $ibox->set_size_request(48,48);
    $ibox->set_border_width(0);
    $ibox->set_visible_window(FALSE);
    $ibox->set_above_child(TRUE);
    $ibox->add($icon);
    $ibox->signal_connect_swapped(button_press_event=>sub{
	    my ($self,$event,$widget) = @_;
	    if ($event->button == 3) {
		$self->popup($event);
		return Gtk2::EVENT_STOP;
	    }
	    elsif ($event->button == 1) {
		$self->click();
		return Gtk2::EVENT_STOP;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);
    $ibox->set_tooltip_text($label);
    $ibox->signal_connect(enter_notify_event=>sub{
	    my ($widget,$event,$self) = @_;
	    unless ($self->{inside}) {
		my ($icon) = $widget->get_children;
		my $alloc = $icon->allocation;
		my ($x,$y,$w,$h) = ($alloc->x,$alloc->y,$alloc->width,$alloc->height);
		$x += ($w-56)/2; $w = 56;
		$y += ($h-56)/2; $h = 56;
		my $window = $icon->window;
		my $gc = $icon->style->bg_gc('prelight');
		my $rect = Gtk2::Gdk::Rectangle->new($x,$y,$w,$h);
		$gc->set_clip_region(Gtk2::Gdk::Region->rectangle($rect));
		$window->draw_rectangle($gc,TRUE,$x,$y,$w,$h);
		$window->draw_pixbuf($gc,$self->{pixbuf},0,0,$x+4,$y+4,48,48,'normal',0,0);
		$gc->set_clip_region(undef);
#		my $cr = Gtk2::Gdk::Cairo::Context->create($window);
#		$cr->rectangle($x,$y,$w,$h);
#		$cr->set_source_color($icon->style->bg('prelight'));
#		$cr->fill;
#		$cr->set_source_pixbuf($$pixbuf,-$x,-$y);
#		$cr->paint;
		$self->{inside} = 1;
	    }
	    return Gtk2::EVENT_PROPAGATE;
	    },$self);
    $ibox->signal_connect(leave_notify_event=>sub{
	    my ($widget,$event,$self) = @_;
	    if (delete $self->{inside}) {
		my ($icon) = $widget->get_children;
		my $alloc = $icon->allocation;
		my ($x,$y,$w,$h) = ($alloc->x,$alloc->y,$alloc->width,$alloc->height);
		$x += ($w-56)/2; $w = 56;
		$y += ($h-56)/2; $h = 56;
		my $window = $icon->window;
		$window->clear_area_e($x,$y,$w,$h);
	    }
	    return Gtk2::EVENT_PROPAGATE;
	    },$self);

    my $but;
    if (0) {
    $but = $self->{gtk}{widget} = Gtk2::Button->new;
    $but->set_size_request(&XDE::Desktop2::ICON_WIDE,&XDE::Desktop2::ICON_HIGH);
    $but->set_alignment(&XDE::Desktop2::ICON_WIDE,&XDE::Desktop2::ICON_HIGH);
    $but->set_border_width(0);
    $but->set_relief('none');
    $but->set_tooltip_text($label);
    } else {
    if (0) {
    $but = $self->{gtk}{widget} = Gtk2::EventBox->new;
    $but->set_size_request(&XDE::Desktop2::ICON_WIDE,&XDE::Desktop2::ICON_HIGH);
    $but->set_border_width(0);
    $but->set_visible_window(FALSE);
    $but->set_above_child(TRUE);
    } else {
    $but = $self->{gtk}{widget} = Gtk2::HBox->new;
    $but->set_border_width(0);
    $but->set_size_request(&XDE::Desktop2::ICON_WIDE,&XDE::Desktop2::ICON_HIGH);
    }
    }
    my $v = Gtk2::VBox->new(FALSE,0);
    $but->add($v);
    $v->pack_start($ibox,TRUE,FALSE,0);
    my $h = Gtk2::HBox->new(TRUE,0);
    $v->pack_start($h,TRUE,FALSE,0);
    my $l = $self->{gtk}{label} = Gtk2::Label->new;
    $l->set_size_request(-1,-1);
    $l->set_padding(0,0);
    $l->set_line_wrap(TRUE);
    my $n_chars = int((&XDE::Desktop2::ICON_WIDE+8)/8);
#   $l->set_max_width_chars($n_chars);
    $l->set_width_chars($n_chars);
    $l->set_justify('center');
    my $wrap_mode = 'word-char';
    my $short = $label;
    if (length($short) > ($n_chars*2-3)) {
	$short =~ s{\.[^\.]*$}{};
	if (length($short) > ($n_chars*2-3)) {
	    $short = substr($short,0,$n_chars*2-3).'...';
	    $wrap_mode = 'char';
	}
    }
    $l->set_line_wrap_mode($wrap_mode);
    $l->set_markup("<span font=\"Liberation Sans Bold 8\">$short</span>");
    $l->set_alignment(0.5,0.5);
    $h->pack_start($l,FALSE,FALSE,0);
    $but->show_all;
    if (0) {
    $but->signal_connect_swapped(button_press_event=>sub{
	    my ($self,$event,$widget) = @_;
	    if ($event->button == 3) {
		$self->popup($event);
		return Gtk2::EVENT_STOP;
	    }
	    elsif ($event->button == 1) {
		$self->click();
		return Gtk2::EVENT_STOP;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);
    }
    if (0) {
    $but->signal_connect_swapped(clicked=>sub{
	    my ($self,$widget) = @_;
	    $self->click;
	    return Gtk2::EVENT_STOP;
    },$self);
    }
    return $but;
}

sub create {
    return shift->create2(@_);
}

=item $icon->B<DESTROY>()

Destroy a desktop icon.  This must destroy the X window resource.

=cut

sub DESTROY {
    my $self = shift;
    if (my $widget = delete $self->{gtk}{widget}) {
	$widget->destroy;
	undef $widget;
    }
}

sub show {
    my $self = shift;
    $self->{gtk}{widget}->show_all;
}

sub hide {
    my $self = shift;
    $self->{gtk}{widget}->hide_all;
}

sub remove {
    my ($self,$table) = @_;
    if (delete $self->{attached}) {
	$table->remove($self->{gtk}{widget});
    }
}

sub place {
    my ($self,$table,$col,$row) = @_;
    my $widget = $self->{gtk}{widget};
    if (delete $self->{attached}) {
	$table->remove($widget);
    }
    $table->attach($widget,$col,$col+1,$row,$row+1,[],[],0,0);
    $self->{attached} = [ $col, $row ];
}

# FIXME: TODO: we need to have some button press events from the widget
# to pop menus and the like.

=item $icon->B<open>()

This method performs the default open action associated with the
file or directory.

=cut

sub open {
    my $self = shift;
    my $command = "xdg-open $self->{path}";  # FIXME: for now
    print STDERR "START $command\n";
    system "$command &";
}

=item $icon->B<click>()

This method performs the default single-click action for the icon.  By
default, it performs the B<open> action, but can be overridden by
derived classes.

=cut

sub click {
    return shift->open(@_);
}

=item $icon->B<open_with>() => $submenu

This method builds the default I<Open With> submenu.  If no submenu
exists, returns undef.

=cut

sub open_with {
    my $self = shift;
    my $menu = $self->{openwith};
    unless ($menu) {
	$menu = Gtk2::Menu->new;
	my ($name,$item,$image,@icons);

	if (my $mime = $self->{mime}) {
	    my ($apps,$subs) = XDE::Desktop2->get_apps_and_subs($mime);
	    if (@$apps or @$subs) {
		my $path = $self->{path};
		my $uri = URI::file->new($path);
		my $theme = Gtk2::IconTheme->get_default;
		foreach my $set ($apps,$subs) {
		    next unless @$set;
		    foreach my $app (@$set) {
			$name = $app->{Name};
			$name = $app->{id} unless $name;
			@icons = ();
			push @icons, $app->{Icon} if $app->{Icon};
			push @icons, $app->{id} if $app->{id};
			push @icons, 'gtk-execute';

			$image = undef;
			if (0) {
			    my $iconinfo =
				$theme->choose_icon(\@icons,16,['generic-fallback','use-builtin']);
			    my $pixbuf = $iconinfo->load_icon();
			    $image = Gtk2::Image->new_from_pixbuf($pixbuf) if $pixbuf;
			} else {
			    foreach my $i (@icons) {
				if ($theme->has_icon($i)) {
				    my $pixbuf =
					$theme->load_icon($i,16,['generic-fallback','use-builtin']);
				    $image = Gtk2::Image->new_from_pixbuf($pixbuf) if $pixbuf;
				    last if $image;
				}
			    }
			}

			$item = Gtk2::ImageMenuItem->new;
			$item->set_label($name);
			$item->set_image($image) if $image;
			my $command = $app->{Exec};
			$command = 'false' unless $command;
			$command =~ s{%[fF]}{"$path"};
			$command =~ s{%[uU]}{"$uri"};
			$command =~ s{%[dDnNickvmfFuU]}{}g;
			$item->signal_connect(activate=>sub{
				print STDERR "START $command\n";
				system "$command &";
			    });
			$item->show_all;
			$menu->append($item);
			$item->set_state('insensitive')
			    if $app->{'X-Disable'} and $app->{'X-Disable'} eq 'true';
			$item->set_state('insensitive')
			    if $app->{NoDisplay} and $app->{NoDisplay} eq 'true';
			$item->set_state('insensitive')
			    if $app->{Hidden} and $app->{Hidden} eq 'true';
		    }
		    $item = Gtk2::SeparatorMenuItem->new;
		    $item->show_all;
		    $menu->append($item);
		}
	    } else {
		warn "No apps for mime type $mime!!!";
	    }
	}
	$item = Gtk2::ImageMenuItem->new;
	$item->set_label('Choose...');
	$image = Gtk2::Image->new_from_icon_name('gtk-open','menu');
	$item->set_image($image) if $image;
	$item->signal_connect(activate=>sub{
		print STDERR "Not yet...\n";
	});
	$item->show_all;
	$menu->append($item);

#	$self->{openwith} = $menu;
    }
    return $menu;
}

=item $icon->B<popup>(I<$event>)

This method performs the default action to pops up a menu associated
with the icon.

=cut

sub popup {
    my ($self,$event) = @_;
    my $menu = $self->{menu};
    unless ($menu) {
	my ($item,$image);
	$menu = Gtk2::Menu->new;
	$menu->signal_connect(map=>sub{
		my $menu = shift;
		my $window = $menu->get_toplevel;
		$window->set_opacity(0.92) if $window;
		return Gtk2::EVENT_PROPAGATE;
	});
#	$item = Gtk2::TearoffMenuItem->new;
#	$item->show_all;
#	$menu->append($item);

	if ($self->can('launch')) {
	    $item = Gtk2::ImageMenuItem->new_from_stock('gtk-execute');
	    my $command = $self->{entry}{Exec};
	    $command = 'false' unless $command;
	    $command =~ s{%[dDnNickvmfFuU]}{}g;
	    $item->set_tooltip_text($command);
	    $item->signal_connect(activate=>sub{
		    print STDERR "START $command\n";
		    system "$command &";
	    });
	    $item->show_all;
	    $menu->append($item);
	}
	if ($self->can('open')) {
	    $item = Gtk2::ImageMenuItem->new_from_stock('gtk-open');
	    my $command = "xdg-open $self->{path}";
	    $item->signal_connect(activate=>sub{
		    print STDERR "START $command\n";
		    system "$command &";
	    });
	    $item->show_all;
	    $menu->append($item);

	    if (my $submenu = $self->open_with) {
		$item = Gtk2::ImageMenuItem->new;
		$item->set_label('Open with');
		$image = Gtk2::Image->new_from_icon_name('gtk-open','menu');
		$item->set_image($image) if $image;
		$item->set_submenu($submenu);
		$item->show_all;
		$menu->append($item);
	    }

	    $item = Gtk2::SeparatorMenuItem->new;
	    $item->show_all;
	    $menu->append($item);
	}

	$item = Gtk2::ImageMenuItem->new_from_stock('gtk-cut');
	$item->signal_connect(activate=>sub{
		print STDERR "Not yet...\n";
	});
	$item->show_all;
	$menu->append($item);

	$item = Gtk2::ImageMenuItem->new_from_stock('gtk-copy');
	$item->signal_connect(activate=>sub{
		print STDERR "Not yet...\n";
	});
	$item->show_all;
	$menu->append($item);

	$item = Gtk2::ImageMenuItem->new_from_stock('gtk-delete');
	$item->signal_connect(activate=>sub{
		print STDERR "Not yet...\n";
	});
	$item->show_all;
	$menu->append($item);

	$item = Gtk2::ImageMenuItem->new;
	$item->set_label('Move to trash');
	$image = Gtk2::Image->new_from_icon_name('user-trash','menu');
	$item->set_image($image) if $image;
	$item->signal_connect(activate=>sub{
		print STDERR "Not yet...\n";
	});
	$item->show_all;
	$menu->append($item);

	if ($self->can('props')) {
	    $item = Gtk2::SeparatorMenuItem->new;
	    $item->show_all;
	    $menu->append($item);

	    if (0) {
	    $item = Gtk2::ImageMenuItem->new;
	    $item->set_label('Properties...');
	    $image = Gtk2::Image->new_from_icon_name('gtk-properties','menu');
	    $item->set_image($image) if $image;
	    } else {
	    $item = Gtk2::ImageMenuItem->new_from_stock('gtk-properties');
	    }
	    $item->signal_connect_swapped(activate=>sub{
		    my $self = shift;
		    $self->props;
		    return Gtk2::EVENT_PROPAGATE;
	    },$self);
	    $item->show_all;
	    $menu->append($item);
	}

#	$self->{menu} = $menu;
    }
    $menu->popup(undef,undef,undef,undef,$event->button,$event->time);
}

=item $icon->B<props>()

Launch a window showing the file properties.

=cut

sub no_press {
    my $cb = shift;
    $cb->set_active(not $cb->get_active);
    Gtk2::Gdk->beep;
    return Gtk2::EVENT_STOP;
}

sub do_toggle {
    my ($cb,$flag,$path) = @_;
    my $st = stat($path);
    my $mode = $st->mode;
    if ($cb->get_active) {
	chmod($mode|$flag,$path);
    } else {
	chmod($mode&~$flag,$path);
    }
    return Gtk2::EVENT_PROPAGATE;
}

sub props {
    my $self = shift;
    my $window = $self->{props};
    unless ($window) {
	$window = new Gtk2::Window('toplevel');
	$window->set_default_size(600,420);
	$window->set_title("Properties: $self->{path}");
	$window->set_role('properties');
	$window->set_type_hint('dialog');
	my $vbox = new Gtk2::VBox;
	$window->add($vbox);
	my $book = new Gtk2::Notebook;
	my $bbox = new Gtk2::HButtonBox;
	my $frame;
	if ($self->{path}) {
	    $frame = new Gtk2::VBox;
	    $frame->set_border_width(2);
	     #$frame = new Gtk2::Frame('General');
	    $book->append_page($frame,'General');
	    my $tab = new Gtk2::Table(20,2,FALSE);
	    $tab->set_border_width(2);
	    $tab->set_col_spacings(5);
	    $tab->set_row_spacings(0);
	    my $sw = new Gtk2::ScrolledWindow;
	    $sw->set_policy('automatic','automatic');
	    $sw->add_with_viewport($tab);
	    $frame->add($sw);
	    my $path = $self->{path};
	    my $st = stat($self->{path});
	    my $row = 0;
	    my %trans = (
		dev=>['FS Device ID',undef],
		ino=>['Inode number',undef],
		mode=>['Mode',sub{
		    my $val = shift;
		    my $mine = ($st->uid == $< or $st->uid == $>);
		    my $tab = new Gtk2::Table(3,5,TRUE);
		    my ($cb,$lab);
		    $lab = new Gtk2::Label('Owner:');
		    $lab->set_justify('left');
		    $lab->set_alignment(0.0,0.5);
		    $tab->attach_defaults($lab,0,1,0,1);
		    $cb = new Gtk2::CheckButton('Set User');
		    $cb->set_active($val & S_ISUID);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_ISUID,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,4,5,0,1);
		    $cb = new Gtk2::CheckButton('Read');
		    $cb->set_active($val & S_IRUSR);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_IRUSR,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,1,2,0,1);
		    $cb = new Gtk2::CheckButton('Write');
		    $cb->set_active($val & S_IWUSR);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_IWUSR,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,2,3,0,1);
		    $cb = new Gtk2::CheckButton('Execute');
		    $cb->set_active($val & S_IXUSR);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_IXUSR,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,3,4,0,1);

		    $lab = new Gtk2::Label('Group:');
		    $lab->set_justify('left');
		    $lab->set_alignment(0.0,0.5);
		    $tab->attach_defaults($lab,0,1,1,2);
		    $cb = new Gtk2::CheckButton('Set Group');
		    $cb->set_active($val & S_ISGID);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_ISGID,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,4,5,1,2);
		    $cb = new Gtk2::CheckButton('Read');
		    $cb->set_active($val & S_IRGRP);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_IRGRP,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,1,2,1,2);
		    $cb = new Gtk2::CheckButton('Write');
		    $cb->set_active($val & S_IWGRP);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_IWGRP,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,2,3,1,2);
		    $cb = new Gtk2::CheckButton('Execute');
		    $cb->set_active($val & S_IXGRP);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_IXGRP,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,3,4,1,2);

		    $lab = new Gtk2::Label('Others:');
		    $lab->set_justify('left');
		    $lab->set_alignment(0.0,0.5);
		    $tab->attach_defaults($lab,0,1,2,3);
		    $cb = new Gtk2::CheckButton('Sticky');
		    $cb->set_active($val & S_ISVTX);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_ISVTX,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,4,5,2,3);
		    $cb = new Gtk2::CheckButton('Read');
		    $cb->set_active($val & S_IROTH);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_IROTH,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,1,2,2,3);
		    $cb = new Gtk2::CheckButton('Write');
		    $cb->set_active($val & S_IWOTH);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_IWOTH,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,2,3,2,3);
		    $cb = new Gtk2::CheckButton('Execute');
		    $cb->set_active($val & S_IXOTH);
		    if ($mine) {
			$cb->signal_connect(toggled=>sub{
			    return do_toggle($_[0],S_IXOTH,$path);
			    });
		    } else {
			$cb->signal_connect(pressed=>\&no_press);
		    }
		    $tab->attach_defaults($cb,3,4,2,3);
		    return $tab;
		}],
		nlink=>['Hard links',undef],
		uid=>['Owner user ID',sub{
		    my $val = shift;
		    my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire)
			= getpwuid($val);
		    my $str = "$name ($uid)";
		    $str .= " -- $gcos" if $gcos;
		    my $ent = new Gtk2::Entry;
		    $ent->set_editable(FALSE);
		    $ent->append_text($str);
		    return $ent;
		}],
		gid=>['Owner group ID',sub{
		    my $val = shift;
		    my ($name,$passwd,$gid,$members) = 
			getgrgid($val);
		    my $str = "$name ($gid)";
		    my $ent = new Gtk2::Entry;
		    $ent->set_editable(FALSE);
		    $ent->append_text($str);
		    return $ent;
		}],
		rdev=>['Raw device ID',undef],
		size=>['Total size',sub{
		    my $val = shift;
		    my $unit = '';
		    if ($val > 1024) {
			$val = "$val.0"/1024.0;
			$unit = 'k';
			if ($val > 1024) {
			    $val = $val/1024.0;
			    $unit = 'M';
			    if ($val > 1024) {
				$val = $val/1024.0;
				$unit = 'G';
			    }
			}
		    }
		    my $str = sprintf "%.1f %s",$val,$unit;
		    my $ent = new Gtk2::Entry;
		    $ent->set_editable(FALSE);
		    $ent->append_text($str);
		    return $ent;
		}],
		atime=>['Access time',sub{
		    my $val = shift;
		    my $ent = new Gtk2::Entry;
		    $ent->set_editable(FALSE);
		    $ent->append_text(gmctime($val));
		    return $ent;
		}],
		mtime=>['Modify time',sub{
		    my $val = shift;
		    my $ent = new Gtk2::Entry;
		    $ent->set_editable(FALSE);
		    $ent->append_text(gmctime($val));
		    return $ent;
		}],
		ctime=>['Change time',sub{
		    my $val = shift;
		    my $ent = new Gtk2::Entry;
		    $ent->set_editable(FALSE);
		    $ent->append_text(gmctime($val));
		    return $ent;
		}],
		blksize=>['Block size',sub{
		    my $val = shift;
		    my $unit = '';
		    if ($val > 1024) {
			$val = $val/1024.0;
			$unit = 'k';
			if ($val > 1024) {
			    $val = $val/1024.0;
			    $unit = 'M';
			    if ($val > 1024) {
				$val = $val/1024.0;
				$unit = 'G';
			    }
			}
		    }
		    my $str = sprintf "%.1f %s",$val,$unit;
		    my $ent = new Gtk2::Entry;
		    $ent->set_editable(FALSE);
		    $ent->append_text($str);
		    return $ent;
		}],
		blocks=>['Blocks',undef],
	    );
	    my $uid = $st->uid;
	    foreach (qw(dev ino mode nlink uid gid rdev size atime mtime
			ctime blksize blocks)) {
		my ($desc,$sub) = @{$trans{$_}};
		my $lab = new Gtk2::Label("$desc:");
		$lab->set_justify('right');
		$lab->set_alignment(1.0,0.5);
		my $ent;
		if ($sub) {
		    $ent = &$sub($st->$_);
		} else {
		    $ent = new Gtk2::Entry;
		    $ent->set_editable(FALSE);
		    $ent->append_text($st->$_);
		}
		$tab->attach($lab,0,1,$row,$row+1,['fill'],['fill'],0,0);
		$tab->attach($ent,1,2,$row,$row+1,['fill','expand'],['fill'],0,0);
		$row += 1;
	    }
	    {
		my $lab = new Gtk2::Label('Access:');
		$lab->set_justify('right');
		$lab->set_alignment(1.0,0.5);
		my ($tbl,$l,$cb);
		$tbl = new Gtk2::Table(2,5,TRUE);

		$l = new Gtk2::Label('Effective:');
		$l->set_justify('left');
		$l->set_alignment(0.0,0.5);
		$tbl->attach_defaults($l,0,1,0,1);
		$cb = new Gtk2::CheckButton('Read');
		$cb->set_active($st->cando(S_IRUSR,TRUE));
		$cb->signal_connect(pressed=>\&no_press);
		$tbl->attach_defaults($cb,1,2,0,1);
		$cb = new Gtk2::CheckButton('Write');
		$cb->set_active($st->cando(S_IWUSR,TRUE));
		$cb->signal_connect(pressed=>\&no_press);
		$tbl->attach_defaults($cb,2,3,0,1);
		$cb = new Gtk2::CheckButton('Execute');
		$cb->set_active($st->cando(S_IXUSR,TRUE));
		$cb->signal_connect(pressed=>\&no_press);
		$tbl->attach_defaults($cb,3,4,0,1);
		$cb = new Gtk2::CheckButton('Owner');
		$cb->set_active($st->uid == $<);
		$cb->signal_connect(pressed=>\&no_press);
		$tbl->attach_defaults($cb,4,5,0,1);

		$l = new Gtk2::Label('Real:');
		$l->set_justify('left');
		$l->set_alignment(0.0,0.5);
		$tbl->attach_defaults($l,0,1,1,2);
		$cb = new Gtk2::CheckButton('Read');
		$cb->set_active($st->cando(S_IRUSR,FALSE));
		$cb->signal_connect(pressed=>\&no_press);
		$tbl->attach_defaults($cb,1,2,1,2);
		$cb = new Gtk2::CheckButton('Write');
		$cb->set_active($st->cando(S_IWUSR,FALSE));
		$cb->signal_connect(pressed=>\&no_press);
		$tbl->attach_defaults($cb,2,3,1,2);
		$cb = new Gtk2::CheckButton('Execute');
		$cb->set_active($st->cando(S_IXUSR,FALSE));
		$cb->signal_connect(pressed=>\&no_press);
		$tbl->attach_defaults($cb,3,4,1,2);
		$cb = new Gtk2::CheckButton('Owner');
		$cb->set_active($st->uid == $>);
		$cb->signal_connect(pressed=>\&no_press);
		$tbl->attach_defaults($cb,4,5,1,2);

		$tab->attach($lab,0,1,$row,$row+1,['fill'],['fill'],0,0);
		$tab->attach($tbl,1,2,$row,$row+1,['fill','expand'],['fill'],0,0);
		$row += 1;
	    }
	    $tab->resize($row,2);
	}
	if ($self->{entry}) {
	    $frame = new Gtk2::VBox;
	    $frame->set_border_width(2);
	    #$frame = new Gtk2::Frame('Desktop Entry');
	    $book->append_page($frame,'Entry');
	    my %e = ( %{$self->{entry}} );
	    delete $e{file};
	    delete $e{id};
	    my $tab = new Gtk2::Table(scalar(keys(%e)),2,FALSE);
	    $tab->set_border_width(2);
	    my $sw = new Gtk2::ScrolledWindow;
	    $sw->set_policy('automatic','automatic');
	    $sw->add_with_viewport($tab);
	    $frame->add($sw);
	    my $row = 0;
	    foreach (qw(Type Encoding Version Name GenericName Comment
			Icon Hidden OnlyShowIn NotShowIn TryExec Exec
			Path Terminal MimeType Categories StartupNotify
			StartupWMClass URL)) {
		next unless exists $e{$_};
		my $lab = new Gtk2::Label("$_=");
		$lab->set_justify('right');
		$lab->set_alignment(1.0,0.5);
		my $ent = new Gtk2::Entry;
		$ent->append_text($e{$_});
		$tab->attach($lab,0,1,$row,$row+1,['fill'],['fill'],0,0);
		$tab->attach($ent,1,2,$row,$row+1,['fill','expand'],['fill'],0,0);
		$row += 1;
		delete $e{$_};
	    }
	    foreach (sort keys %e) {
		my $lab = new Gtk2::Label("$_=");
		$lab->set_justify('right');
		$lab->set_alignment(1.0,0.5);
		my $ent = new Gtk2::Entry;
		$ent->append_text($e{$_});
		$tab->attach($lab,0,1,$row,$row+1,['fill'],['fill'],0,0);
		$tab->attach($ent,1,2,$row,$row+1,['fill','expand'],['fill'],0,0);
		$row += 1;
	    }
	    $tab->resize($row,2);
	}
	$frame = new Gtk2::Frame('Page 3');
	$book->append_page($frame,'Page 3');
	$bbox->set_spacing_default(0);
	$bbox->set_layout_default('end');
	$vbox->pack_start($book,TRUE,TRUE,0);
	$vbox->pack_start($bbox,FALSE,TRUE,0);
	my $button;
	$button = Gtk2::Button->new_from_stock('gtk-cancel');
	$button->set_border_width(5);
	$bbox->pack_end($button,FALSE,FALSE,0);
	$button->show_all;
	$button = Gtk2::Button->new_from_stock('gtk-ok');
	$button->set_border_width(5);
	$bbox->pack_end($button,FALSE,FALSE,0);
	$button->show_all;
	$bbox->show_all;
	$vbox->show_all;
    }
    $window->show_all;
    $window->show;
}




1;

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Desktop(3pm)>, L<XDE::Desktop::Icon(3pm)>

=cut

__END__

# vim: set sw=4 tw=72:
