package XDE::Desktop;
use base qw(XDE::Dual);
use Linux::Inotify2;
use Glib qw(TRUE FALSE);
use Gnome2::VFS;
use XDE::Desktop::Icon;
use XDE::Desktop::Icon::Shortcut;
use XDE::Desktop::Icon::Directory;
use XDE::Desktop::Icon::File;
use strict;
use warnings;

=head1 NAME

XDE::Desktop -- XDE Desktop Environment

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=item $desk = XDE::Desktop->B<new>(I<%OVERRIDES>)

Creates an instance of an XDE::Desktop object.  The XDE::Desktop module
uses the L<XDE::Context(3pm)> modules as a base, so the C<%OVERRIDES>
are simply passed to the L<XDE::Context(3pm)> module.

=cut

sub new {
    return XDE::Context::new(@_);
}

sub get_visual {
    my $self = shift;
    my $X = $self->{X};
    for my $id (keys %{$X->{visuals}}) {
	my $v = $X->{visuals}{$id};
	return $id if
	    $v->{depth} == 32 and
	    $v->{red_mask} == 0x00ff0000 and
	    $v->{green_mask} == 0x0000ff00 and
	    $v->{blue_mask} == 0x000000ff;
    }
    die "Cannot find 32 bit visual!";
}

sub get_argb32 {
    my $self = shift;
    my $X = $self->{X};
    my ($formats,$screens) = $X->RenderQueryPictFormats();
    for my $f (@$formats) {
	return $f->[0] if
	    $f->[2] == 32 and # depth
	    $f->[3] == 16 and # red shift
	    $f->[5] ==  8 and # grn shift
	    $f->[7] ==  0 and # blu shift
	    $f->[9] == 24;    # alp shift
    }
    die "Cannot find ARGB32 format!";
}

sub get_bitmap {
    my $self = shift;
    my $X = $self->{X};
    my ($formats,$screens) = $X->RenderQueryPictFormats();
    for my $f (@$formats) {
	return $f->[0] if $f->[2] == 1;
    }
    die "Cannot find BITMAP format!";
}

sub get_format {
    my $self = shift;
    my $X = $self->{X};
    my ($formats,$screens) = $X->RenderQueryPictFormats();
    for my $s (@$screens) {
	my @s = @$s;
	shift @s; # discard fallback
	for my $d (@s) {
	    my @d = @$d;
	    next unless shift(@d) == $X->root_depth;
	    for my $v (@d) {
		if ($v->[0] == $X->root_visual) {
		    return $v->[1];
		}
	    }
	}
    }
    die "Cannot find root visual format!";
}

sub get_image {
    my ($self,$names,$id) = @_;
    unless ($self->{images}{$id}) {
	$self->{images}{$id} =
	    XDE::Desktop::Image->new($self,$names);
    }
    return $self->{images}{$id};
}

sub read_icons {
    my $self = shift;
    my $file;
    foreach my $dir ($self->XDG_DATA_DIRS) {
	if (-f "$dir/theme/generic-icons") {
	    $file = "$dir/theme/generic-icons";
	}
    }
    $self->{generic_icons} = {};
    return unless $file;
    if (open(my $fh,"<",$file)) {
	while (<$fh>) { chomp;
	    if (m{^([^:]*):(.*)$}) {
		$self->{generic_icons}{$1} = $2;
	    }
	}
	close($fh);
    }
}

sub get_mime {
    my ($self,$file) = @_;
    my ($mime,$result,$info);
    if (1) {
	my $uri = Gnome2::VFS::URI->new($file);
	($result,$info) = 
	    $uri->get_file_info(['default','get-mime-type','force-fast-mime-type']);
	if ($info) {
	    $mime = $info->get_mime_type;
	}
	unless ($mime) {
	    ($result,$info) = 
		$uri->get_file_info(['default','get-mime-type','force-slow-mime-type']);
	    if ($info) {
		$mime = $info->get_mime_type;
	    }
	}
    }
    unless ($mime) {
	$mime = Gnome2::VFS->get_mime_type_for_name($file);
    }
    return $mime;
}

sub get_icons {
    my ($self,$mime) = @_;
    my @icons = ();
    return \@icons unless $mime;
    my $icon1 = $mime; $icon1 =~ s{/}{-}g;
    push @icons, $icon1, "gnome-mime-$icon1" if $icon1;
    my $icon3 = $self->{generic_icons}{$mime};
    push @icons, $icon3 if $icon3;
    my $icon2 = $mime; $icon2 =~ s{/.*}{};
    push @icons, $icon2, "gnome-mime-$icon2" if $icon2;
    return \@icons;
}

sub _init {
    my $self = shift;
    print STDERR "-> Creating desktop...\n";
    my $v = $self->{ops}{verbose};

    $self->{images} = {};

    # set up an Inotify2 connection
    unless ($self->{N}) {
	$self->{N} = Linux::Inotify2->new;
	$self->{N}->blocking(FALSE);
    }

    # initialize VFS
    $self->read_icons;
    Gnome2::VFS->init;

    my $icons = $self->{icontheme} =
	Gtk2::IconTheme->get_default;
    $icons->append_search_path("$ENV{HOME}/.icons");
    $icons->append_search_path("/usr/share/pixmaps");
    undef $icons;

    # initialize extensions
    my $X = $self->{X};
    $X->init_extensions;

    # get render formats
    $self->{format} = $self->get_format;
    $self->{argb32} = $self->get_argb32;
    $self->{bitmap} = $self->get_bitmap;
    $self->{visual} = $self->get_visual;

    # register for root events
    $X->ChangeWindowAttributes($X->root,
	    event_mask=>$X->pack_event_mask(
		'PropertyChange',
		'StructureNotify'));

    # set up colormap
    $self->{root} = Gtk2::Gdk->get_default_root_window;
    $self->{cmap} = Gtk2::Gdk::Colormap->new($self->{root}->get_visual,TRUE);

    # get the root pixmap
    $self->get_pixmap;

    # set up a top level window for tooltip queries
    my $win = $self->{ttipwin} = Gtk2::Window->new('toplevel');
    $win->set_has_tooltip(TRUE);
    $win->set_tooltip_text('A tool tip.');
    $win->signal_connect_swapped(query_tooltip=>sub{
	    print STDERR "Tooltip query: ", join(',',@_), "\n";
	    my ($self,$x,$y,$bool,$tooltip,$win) = @_;
	    if ($self->{showtip}) {
		$tooltip->set_text($self->{showtip});
		return TRUE;
	    }
	    return FALSE;
    },$self);

    # set up event handler for buttons
    Gtk2::Gdk::Event->handler_set(sub{
	    my ($event,$self) = @_;
	    if (my $win = $event->window) {
		if (my $xid = $win->XID) {
		    if (my $icon = $self->{icons}{winds}{$xid}) {
			my $e = {
			    event=>$xid,
			    root_x=>$event->x_root,
			    root_y=>$event->y_root,
			    time=>$event->time,
			};
			$e->{time} = 0 unless $e->{time};
			if ($event->type eq 'motion-notify') {
			    $icon->motion($e,$self->{X},$self->{ops}{verbose});
			}
			elsif ($event->type eq 'button-press') {
			    $e->{detail} = $event->button;
			    $icon->press($e,$self->{X},$self->{ops}{verbose});
			}
			elsif ($event->type eq 'button-release') {
			    $e->{detail} = $event->button;
			    $icon->release($e,$self->{X},$self->{ops}{verbose});
			}
		    }
		}
	    }
	    Gtk2->main_do_event($event);
    },$self);
    return $self;
}

sub _term {
    my $self = shift;
    # remove Inotify2 connection.
    my $N = delete $self->{N};
    Glib::Source->remove(delete $self->{notify}{watcher})
	if $self->{notify}{watcher};
    foreach (keys %{$self->{notify}}) {
	if (my $w = delete $self->{notify}{$_}) {
	    $w->cancel;
	}
    }
    undef $N;
}

=item $desktop->B<update_desktop>()

Creates or updates the complete desktop arrangement, including reading
or rereading the C<$ENV{HOME}/Desktop> directory.

=cut

sub update_desktop {
    my $self = shift;
    print STDERR "==> Reading desktop...\n";
    $self->read_desktop;
    print STDERR "==> Creating objects...\n";
    $self->create_objects;
    print STDERR "==> Creating windows...\n";
    $self->create_windows;
    print STDERR "==> Rearranging icons...\n";
    $self->rearrange_icons;
    print STDERR "==> Showing icons...\n";
    $self->show_icons;
}

=item $desktop->B<calculate_cells>()

Creates an array of 72x72 cells on the desktop in columns and rows.
This uses the available area of the desktop as indicated by the
C<_NET_WORKAREA> or C<_WIN_WORKAREA> properties on the root window.

=cut

sub calculate_cells {
    my $self = shift;
    my $X = $self->{X};
    my ($x,$y,$w,$h);
    my ($val,$type) = $X->GetProperty($X->root,
	    $X->atom('_NET_WORKAREA'),
	    0,0,4,0);
    if ($type and $val) {
	($x,$y,$w,$h) = unpack('LLLL',$val);
    } else {
	($val,$type) = $X->GetProperty($X->root,
		$X->atom('_WIN_WORKAREA'),
		0,0,4,0);
	if ($type and $val) {
	    ($x,$y,$w,$h) = unpack('LLLL',$val);
	} else {
	    # just WindowMaker and AfterStep do not set either
	    ($x,$y,$w,$h) = ((64,64),
		    $X->width_in_pixels-128,
		    $X->height_in_pixels-128);
	    # leave room for clip and dock (or wharf)
	}
    }
    # leave at least 1/2 a cell (36 pixels) around the desktop area to
    # accomodate window managers that do not account for panels.
    $self->{cols} = int($w/72)-1;
    $self->{rows} = int($h/72)-1;
    $self->{xoff} = int(($w-$self->{cols}*72)/2);
    $self->{yoff} = int(($h-$self->{rows}*72)/2);
    return ($self->{xoff}, $self->{yoff}, $self->{cols}, $self->{rows});
}

=item $desktop->B<watch_directory>(I<$label>,I<$directory>)

Establishes a watch on the desktop directory, C<$directory>, with the
label specified by C<$label>.

=cut

sub watch_directory {
    my ($self,$label,$directory) = @_;
    my $N = $self->{N};
    delete($self->{notify}{$label})->cancel
	if $self->{notify}{$label};
    # FIXME: should probably be more than IN_MODIFY
    $self->{notify}{$label} = $N->watch($directory,IN_MODIFY, sub{
	    my $e = shift;
	    if ($self->{ops}{verbose}) {
		print STDERR "------------------------\n";
		print STDERR "$e->{w}{name} was modified\n"
		    if $e->IN_MODIFY;
		print STDERR "Rereading directory\n";
	    }
	    $self->update_desktop;
    });
}

=item $desktop->B<read_desktop>()

Perform a read of the C<$ENV{HOME}/Desktop> directory.

=cut

sub read_desktop {
    my $self = shift;
    # must follow xdg spec to find directory, just use
    # $ENV{HOME}/Desktop for now
    my $dir = "$ENV{HOME}/Desktop";
    $self->watch_directory(Desktop=>$dir);
    my @paths = ();
    my @links = ();
    my @dires = ();
    my @files = ();
    print STDERR "-> Directory is '$dir'\n";
    opendir(my $dh, $dir) or return;
    print STDERR "-> Opening directory\n";
    foreach my $f (readdir($dh)) {
	print STDERR "-> Got entry: $f\n"
	    if $self->{ops}{verbose};
	next if $f eq '.' or $f eq '..';
	if (-d "$dir/$f") {
	    push @dires, "$dir/$f";
	    push @paths, "$dir/$f";
	}
	elsif (-f "$dir/$f") {
	    if ($f =~ /\.desktop$/) {
		push @links, "$dir/$f";
	    } else {
		push @files, "$dir/$f";
	    }
	    push @paths, "$dir/$f";
	}
    }
    closedir($dh);
    $self->{paths} = \@paths;
    $self->{links} = \@links;
    $self->{dires} = \@dires;
    $self->{files} = \@files;
    print STDERR "There are:\n";
    print STDERR scalar(@paths), " paths\n";
    print STDERR scalar(@links), " links\n";
    print STDERR scalar(@dires), " dires\n";
    print STDERR scalar(@files), " files\n";
}

=item $desktop->B<create_objects>()

Creates the desktop icons objects for each of the shortcuts, directories
and documents found in the Desktop directory.  Desktop icon objects are
only created if they have not already been created.  Desktop icons
objects that are no longer used are released to be freed by garbage
collection.

=cut

sub create_objects {
    my $self = shift;
    my %paths = ();
    my @detop = ();
    my @links = ();
    my @dires = ();
    my @files = ();
    foreach my $l (sort @{$self->{links}}) {
	my $e = $self->{icons}{paths}{$l};
	$e = XDE::Desktop::Icon::Shortcut->new($self,$l) unless $e;
	if ($e and $e->isa('XDE::Desktop::Icon::Shortcut')) {
	    push @links, $e;
	    push @detop, $e;
	    $paths{$l} = $e;
	} else {
	    push @files, $l;
	}
    }
    foreach my $d (sort @{$self->{dires}}) {
	my $e = $self->{icons}{paths}{$d};
	$e = XDE::Desktop::Icon::Directory->new($self,$d) unless $e;
	if ($e) {
	    push @dires, $e;
	    push @detop, $e;
	    $paths{$d} = $e;
	}
    }
    foreach my $f (sort @{$self->{files}}) {
	my $e = $self->{icons}{paths}{$f};
	$e = XDE::Desktop::Icon::File->new($self,$f) unless $e;
	if ($e) {
	    push @files, $e;
	    push @detop, $e;
	    $paths{$f} = $e;
	}
    }
    $self->{icons}{links} = \@links;
    $self->{icons}{dires} = \@dires;
    $self->{icons}{files} = \@files;
    $self->{icons}{paths} = \%paths;
    $self->{icons}{detop} = \@detop;
}

=item $desktop->B<create_windows>()

Creates windows for all desktop icons.  This method simply requests that
each icon create a window and return the XID of the window.  Desktop
icons are indexed by XID so that we can find them in event handlers.
Note that if a window has already been created for a desktop icon, it
still returns its XID.  If desktop icons have been deleted, hide them
now so that they do not persist until garbage collection removes them.

=cut

sub create_windows {
    my $self = shift;
    my %winds = ();
    foreach (@{$self->{icons}{detop}}) {
	my $xid = $_->create;
	$winds{$xid} = $_; # so we can find icon by xid
    }
    if ($self->{icons}{winds}) {
	foreach (keys %{$self->{icons}{winds}}) {
	    $self->{icons}{winds}{$_}->hide unless exists $winds{$_};
	}
    }
    $self->{icons}{winds} = \%winds;
}

=item $desktop->B<hide_icons>()

Hides all of the desktop icon windows.  This method simply requests that
each icon hide itself.

=cut

sub hide_icons {
    foreach (@{$_[0]->{icons}{detop}}) { $_->hide_noflush }
}

=item $desktop->B<show_icons>()

Shows all of the desktop icons.  The method simply requests that each
icon show itself.

=cut

sub show_icons {
    foreach (@{$_[0]->{icons}{detop}}) { $_->show_noflush($_[1]) }
}

=item $desktop->B<next_cell>(I<$col>,I<$row>,I<$x>,I<$y>) => $col,$row,$x,$y

Given the column and row of a cell, C<$col> and C<$row>, and the x- and
y-coordinates of the upper left corner of the cell, C<$x> and C<$y>,
calculate the column, row, x- and y-coordinate of the next cell moving
from top to bottom, left to right.
Used internally by C<arrange_icons()>.

=cut

sub next_cell {
    my ($self,$col,$row,$x,$y) = @_;
    $row += 1; $y += 72;
    unless ($row < $self->{rows}) {
	$row = 0; $y = $self->{yoff};
	$col += 1; $x += 72;
    }
    return ($col,$row,$x,$y);
}

=item $desktop->B<next_column>(I<$col>,I<$row>,I<$x>,I<$y>) => $col,$row,$x,$y

Given the column and row of a cell, C<$col> and C<$row>, and the x- and
y-coordinates of the upper left corner of the cell, C<$x> and C<$y>,
calculate the column, row, x- and y-coordinate of the cell beginning a
new column.
Used internally by C<arrange_icons()>.

=cut

sub next_column {
    my ($self,$col,$row,$x,$y) = @_;
    if ($row != 0) {
	$row = 0; $y = $self->{yoff};
	$col += 1; $x += 72;
    }
    return ($col,$row,$x,$y);
}


=item $desktop->B<arrange_icons>()

Arranges (places) all of the destkop icons.  The placement is performed
by arranging each icon and asking it to place itself, and update its
contents.

=cut

sub arrange_icons {
    my ($self) = @_;
    my $col = 0; my $x = $self->{xoff};
    my $row = 0; my $y = $self->{yoff};
    if (@{$self->{icons}{links}} and $col < $self->{cols}) {
	foreach (@{$self->{icons}{links}}) {
	    $_->place($x,$y);
	    push @{$self->{icons}{detop}}, $_;
	    ($col,$row,$x,$y) = $self->next_cell($col,$row,$x,$y);
	    last unless $col < $self->{cols};
	}
	($col,$row,$x,$y) = $self->next_column($col,$row,$x,$y);
    }
    if (@{$self->{icons}{dires}} and $col < $self->{cols}) {
	foreach (@{$self->{icons}{dires}}) {
	    $_->place($x,$y);
	    push @{$self->{icons}{detop}}, $_;
	    ($col,$row,$x,$y) = $self->next_cell($col,$row,$x,$y);
	    last unless $col < $self->{cols};
	}
	($col,$row,$x,$y) = $self->next_column($col,$row,$x,$y);
    }
    if (@{$self->{icons}{files}} and $col < $self->{cols}) {
	foreach (@{$self->{icons}{files}}) {
	    $_->place($x,$y);
	    push @{$self->{icons}{detop}}, $_;
	    ($col,$row,$x,$y) = $self->next_cell($col,$row,$x,$y);
	    last unless $col < $self->{cols};
	}
    }
}

=item $desktop->B<update_icons>()

Updates the contents of all of the desktop icons.  This method simply
asks each icon to update itself.

=cut

sub update_icons {
    my ($self) = @_;
    foreach (@{$self->{icons}{detop}}) {
	$_->update_noflush;
    }
}

=item $desktop->B<rearrange_icons>()

Recalculate the cell positions given the current work area and
reposition all existing desktop icons so that they correspond to the
layout for the given workarea.

=cut

sub rearrange_icons {
    my $self = shift;
    $self->calculate_cells;
    $self->arrange_icons;
}

sub get_pixmap {
    my $self = shift;
    my $X = $self->{X};
    my ($val,$type) = $X->GetProperty($X->root,
	    $X->atom('_XROOTPMAP_ID'),
	    $X->atom('PIXMAP'),
	    0,1,0);
    $self->{pixmap} = unpack('L',substr($val,0,4)) if $type and $val;
    return $self->{pixmap};
}

sub event_handler_ButtonPress {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my $win = $e->{event};
    my $icon = $self->{icons}{winds}{$win};
    return unless $icon;
    $icon->press(@_);
}

sub event_handler_ButtonRelease {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my $win = $e->{event};
    my $icon = $self->{icons}{winds}{$win};
    return unless $icon;
    $icon->release(@_);
}

sub event_handler_MotionNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my $win = $e->{event};
    my $icon = $self->{icons}{winds}{$win};
    return unless $icon;
    $icon->motion(@_);
}

sub event_handler_EnterNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my $win = $e->{event};
    my $icon = $self->{icons}{winds}{$win};
    return unless $icon;
    $icon->enter(@_,$self);
}

sub event_handler_LeaveNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my $win = $e->{event};
    my $icon = $self->{icons}{winds}{$win};
    return unless $icon;
    $icon->leave(@_,$self);
}

sub event_handler_VisibilityNotify {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my $win = $e->{window};
    my $icon = $self->{icons}{winds}{$win};
    return unless $icon;
    $icon->visible_noflush($e->{state});
}

sub event_handler_Expose {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my $win = $e->{window};
    my $icon = $self->{icons}{winds}{$win};
    return unless $icon;
    $icon->expose_noflush($e);
}

=item $desktop->B<event_handler_PropertyNotify_XROOTPMAP_ID>(I<$e>,I<$X>,I<$v>)

Event handler for changes to the C<_XROOTPMAP_ID> property on the root
window.  When this changes we need to update the backgrounds for all of
the desktop icons.
This is an internal method called from the X11::Protocol event loop.

=cut

sub event_handler_PropertyNotify_XROOTPMAP_ID {
    my $self = shift;
    my ($e,$X,$v) = @_;
    return unless $e->{window} == $X->root;
    $self->get_pixmap;
    $self->update_icons;
    $X->flush;
}

=item $desktop->B<event_handler_PropertyNotify_NET_WORKAREA>(I<$e>,I<$X>,I<$v>)

Event handler for changes to the C<_NET_WORKAREA> property on the root
window.  When this changes we need to potentially adjust the position of
all of the destkop icons.
This is an internal method called from the X11::Protocol event loop.

=cut

sub event_handler_PropertyNotify_NET_WORKAREA {
    my $self = shift;
    my ($e,$X,$v) = @_;
    return unless $e->{window} == $X->root;
    $self->rearrange_icons;
}

=item $desktop->B<event_handler_PropertyNotify_WIN_WORKAREA>(I<$e>,I<$X>,I<$v>)

Event handler for changes to the C<_WIN_WORKAREA> property on the root
window.  When this changes we need to potentially adjust the position of
all of the destkop icons.
This is an internal method called from the X11::Protocol event loop.

=cut

sub event_handler_PropertyNotify_WIN_WORKAREA {
    my $self = shift;
    my ($e,$X,$v) = @_;
    return unless $e->{window} == $X->root;
    $self->rearrange_icons;
}

1;

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Desktop(3pm)>, L<XDE::Desktop::Icon(3pm)>

=cut

__END__

# vim: sw=4 tw=72
