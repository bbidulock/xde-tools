package XDE::Desktop;
use base qw(XDE::Dual XDE::Actions);
use Linux::Inotify2;
use Glib qw(TRUE FALSE);
use Gnome2::VFS;
use XDE::Desktop::Icon;
use XDE::Desktop::Icon::Shortcut;
use XDE::Desktop::Icon::Directory;
use XDE::Desktop::Icon::File;
use XDE::Desktop::Pmap;
use strict;
use warnings;

=head1 NAME

XDE::Desktop -- XDE Desktop Environment

=head1 SYNOPSIS

=head1 DESCRIPTION

B<XDE::Desktop> provides a module that manages the desktop environment
for the L<XDE(3pm)> suite.

Like most desktop environments (typically file managers run in desktop
mode), B<XDE::Desktop> provides clickable icons on the desktop.
Following XDG specifications, it places items from the user's
F<~/Desktop> directory on the background (desktop).  Unlike most file
managers run in desktop mode, B<XDE::Desktop> does not involve itself
with setting the background image.  That is the domain of
L<XDE::Setbg(3pm)>.  In general, B<XDE::Desktop> cooperates

=head1 METHODS

Most of the methods provided by this module are internal and used for
implementation only.

This module provides the following methods:

=over

=cut

my %MIME_APPLICATIONS;
my %MIME_SUBCLASSES;
my %MIME_ALIASES;
my %MIME_GENERIC_ICONS;
my %XDG_DESKTOPS;
my %XDG_CATEGORIES;

use constant {
    ICON_WIDE=>80,
    ICON_HIGH=>80,
};

=item $desktop = XDE::Desktop->B<new>(I<%OVERRIDES>)

Creates an instance of an XDE::Desktop object.  The XDE::Desktop
module uses the L<XDE::Context(3pm)> modules as a base, so the
C<%OVERRIDES> are simply passed to the L<XDE::Context(3pm)> module.

=cut

sub new {
    return XDE::Context::new(@_);
}

=item $desktop->B<get_image>(I<$names>,I<$id>,I<$mime>) => XDE::Desktop::Image

Returns the XDE::Desktop::Image object that corresponds to an
identifier, C<$id>, mime type, C<$mime>, and uses icons from an array
reference to a list of preferred icon names, C<$names>.  The result is
cached against I<$id> so that only one pixmap is installed on the X
display for multiple occurrences of the same id.

=cut

sub get_image {
    my ($self,$names,$id,$mime) = @_;
    unless ($self->{images}{$id}) {
	$self->{images}{$id} =
	    XDE::Desktop::Image->new($self,$names,$mime);
    }
    return $self->{images}{$id};
}

=item XDE::Desktop->B<get_mime_type>(I<$file>) => $mimetype

Gets the mime type for the specified file, C<$file>.   This method uses
L<Gnome2::VFS::URI(3pm)> to obtain information about the mime type of
the file.  The XDG shared-mime specification could be used directly
using just L<perl(1)> to do so, however, L<Gnome2::VFS(3pm)> gives good
results for the most part.  As a fall back when L<Gnome2::VFS::URI(3pm)>
cannot determine the mime type, the L<file(1)> program is queried.
L<file(1)> gives less consistent results than L<Gnome2::VFS(3pm)>.  The
previous two approaches examine the file but do not consider the name.
As a final fall back, L<Gnome2::VFS(3pm)> is used to query for a mime
type based solely on the file name.  Heuristically, this approach gives
good results for determining the mime type of any file.

=cut

sub get_mime_type {
    my ($selfortype,$file) = @_;
    my ($mime,$result,$info);
    unless ($mime) {
	if (my $uri = Gnome2::VFS::URI->new($file)) {
	    if (0) {
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
	    } else {
		($result,$info) = 
		    $uri->get_file_info(['default','get-mime-type','force-slow-mime-type']);
		if ($info) {
		    $mime = $info->get_mime_type;
		    if (0) {
		    foreach (keys %$info) {
			printf STDERR "%-20s:%-50s\n",$_,$info->{$_};
		    }
		    }
		}
	    }
	}
    }
    unless ($mime) {
	chomp($mime = `file -b --mime-type "$file"`);
    }
    unless ($mime) {
	$mime = Gnome2::VFS->get_mime_type_for_name($file);
    }
    return $mime;
}

=item XDE::Desktop->B<get_icons>(I<$mime>) = \@icons

Given a mime type, C<$mime>, returns an array reference to a list of
icon names, or C<undef> when unsuccessful.  The icon names are in order
of preference, starting with the mime type supplied, any aliases of
that mime type, and any subclasses of that mime type.  The purpose of
this method is to always find a reasonable icon representation of the
mime type.  Use when displaying an icon for a given desktop object.

=cut


sub get_icons {
    my ($selfortype,$mime) = @_;
    my @icons = ();
    return \@icons unless $mime;
    my @mimes = ($mime);
    if ($MIME_ALIASES{$mime}) {
	push @mimes, @{$MIME_ALIASES{$mime}};
    }
    if ($MIME_SUBCLASSES{$mime}) {
	push @mimes, @{$MIME_SUBCLASSES{$mime}};
    }
    foreach $mime (@mimes) {
	my $icon1 = $mime; $icon1 =~ s{/}{-}g;
	push @icons, $icon1, "gnome-mime-$icon1" if $icon1;
	my $icon3 = $MIME_GENERIC_ICONS{$mime};
	push @icons, $icon3 if $icon3;
	my $icon2 = $mime; $icon2 =~ s{/.*}{};
	push @icons, $icon2, "gnome-mime-$icon2" if $icon2;
    }
    return \@icons;
}

=item XDE::Desktop->B<get_apps_and_subs>(I<$mime>) => \@apps, \@subs

Given a mime type, C<$mime>, returns a list of array references for the
primary application ids and the subclass application ids associated
with the mime type.  This is used for determining which applications
should be used to open a given desktop file, and which subclass
applications can be used as a fall back or for opening a desktop file
using a subclass mime type.  For example, a browser (C<firefox>) could
be returned in the C<\@apps> list for C<text/html> and a text editor
(C<vim>) in the C<\@subs> list.

=cut

sub get_apps_and_subs {
    my ($selfortype,$mime) = @_;
    my @apps = ();
    my @subs = ();
    if ($MIME_APPLICATIONS{$mime}) {
	@apps = sort {$a->{Name} cmp $b->{Name}}
	    @{$MIME_APPLICATIONS{$mime}};
    }
    if ($MIME_SUBCLASSES{$mime}) {
	foreach (@{$MIME_SUBCLASSES{$mime}}) {
	    if ($MIME_APPLICATIONS{$_}) {
		push @subs, @{$MIME_APPLICATIONS{$_}};
	    }
	}
	@subs = sort {$a->{Name} cmp $b->{Name}} @subs;
    }
    return \@apps, \@subs;
}

=item XDE::Desktop->B<get_desktops> => \@desktops

Returns a list of the desktops that appeared in the C<OnlyShowIn> and
C<NotShowIn> key fields of XDG desktop applications files.  This will be
used to present the user a choice when adding custom applications.

=cut

sub get_desktops {
    my $selfortype = shift;
    my @des = reverse sort{$XDG_DESKTOPS{$a} <=> $XDG_DESKTOPS{$b}} keys %XDG_DESKTOPS;
    foreach (@des) {
	printf STDERR "Desktop %-20s -> %d\n", $_, $XDG_DESKTOPS{$_};
    }
    return \@des;
}

=item XDE::Desktop->B<get_categories> => \@categories

Returns a list of the categories that appeared in the C<Categories> key
fields of XDG desktop applications files.  This will be used to present
the user a choice when adding custom applications.

=cut

sub get_categories {
    my $selfortype = shift;
    my @cats = reverse sort{$XDG_CATEGORIES{$a} <=> $XDG_CATEGORIES{$b}} keys %XDG_CATEGORIES;
    foreach (@cats) {
	printf STDERR "Category %-20s -> %d\n", $_, $XDG_CATEGORIES{$_};
    }
    return \@cats;
}

=item $desktop->B<read_icons>()

Initialization method that
reads the XDG shared-mime specification compliant generic icons from the
files in F<@XDG_DATA_DIRS/mime/generic-icons> and places the icons into
a package global hash C<%XDE::Desktop::MIME_GENERIC_ICONS> keyed by mime
type.  This hash is later used by get_icons() to find icons for various
mime types.

This method is idempotent and can be called at any time to update the hash.

=cut

sub read_icons {
    my $self = shift;
    my $file;
    %MIME_GENERIC_ICONS = ();
    foreach my $dir (reverse $self->XDG_DATA_ARRAY) {
	 #print STDERR "Checking: $dir/mime/generic-icons\n";
	if (-f "$dir/mime/generic-icons") {
	    $file = "$dir/mime/generic-icons";
	     #print STDERR "Found: $file\n";
	    if (open(my $fh,"<",$file)) {
		while (<$fh>) { chomp;
		    if (m{^([^:]*):(.*)$}) {
			$MIME_GENERIC_ICONS{$1} = $2;
		    }
		}
		close($fh);
	    }
	}
    }
}

=item $desktop->B<read_aliases>()

Initialization method that
reads the XDG shared-mime specification compliant aliases  from the
files in F<@XDG_DATA_DIRS/mime/aliases> and places the aliases into a
package global hash C<%XDE::Desktop::MIME_ALIASES> keyed by mime type.
This is later used by get_icons() and read_mimeapps() to find icons and
applications for various mime types.

This method is idempotent and can be called at any time to update the hash.

=cut

sub read_aliases {
    my $self = shift;
    my $file;
    %MIME_ALIASES = ();
    foreach my $dir (reverse $self->XDG_DATA_ARRAY) {
	 #print STDERR "Checking: $dir/mime/aliases\n";
	if (-f "$dir/mime/aliases") {
	    $file = "$dir/mime/aliases";
	     #print STDERR "Found: $file\n";
	    if (open(my $fh,"<",$file)) {
		while (<$fh>) { chomp;
		    my ($one,$two) = split(/\s+/,$_);
		    push @{$MIME_ALIASES{$one}}, $two;
		    push @{$MIME_ALIASES{$two}}, $one;
		     #printf STDERR "<=> %-30s: %-30s alias\n", $one,$two;
		}
		close($fh);
	    }
	}
    }
}

=item $desktop->B<read_subclasses>()

Initialization method that
reads the XDG shared-mime specification compliant subclasses from the
files in F<@XDG_DATA_DIRS/mime/subclasses> and places the subclasses
into a package global hash C<%XDE::Desktop::MIME_SUBCLASSES> keyed by
mime type.  This is later used by get_icons() and read_mimeapps() to
find icons and applications for various mime types.

=cut

sub read_subclasses {
    my $self = shift;
    my $file;
    %MIME_SUBCLASSES = ();
    foreach my $dir (reverse $self->XDG_DATA_ARRAY) {
	 #print STDERR "Checking: $dir/mime/subclasses\n";
	if (-f "$dir/mime/subclasses") {
	    $file = "$dir/mime/subclasses";
	     #print STDERR "Found: $file\n";
	    if (open(my $fh,"<",$file)) {
		while (<$fh>) { chomp;
		    my ($one,$two) = split(/\s+/,$_);
		    push @{$MIME_SUBCLASSES{$one}}, $two;
		}
		close($fh);
	    }
	}
    }
}

=item $desktop->B<read_gvfsapps>()

L<Gnome2::VFS(3pm)> has its own idea of the mapping of mime types to
applications outside of the XDG desktop specification.  This method uses
the L<Gnome2::VFS::ApplicationRegistry(3pm)> to retrieve those
applications.  This provides a somewhat richer mapping verses using the
XDG desktop specification applications files alone.  This method is used
by read_mimeapps() to get a fuller set of mime type to application
mappings.

=cut

sub read_gvfsapps {
    my $self = shift;
    my %files = ();
    my @PATH = split(/:/,$ENV{PATH});
    my (@apps) = Gnome2::VFS::ApplicationRegistry->get_applications();
    foreach my $app_id (@apps) {
	my %a = (id=>$app_id);
	$self->{gvfs_keys}{id} += 1;
	 #printf STDERR "\t\t%-40s: %40s\n",'id',$app_id;
	my $app = Gnome2::VFS::ApplicationRegistry->new($app_id);
	foreach my $key (sort $app->get_keys) {
	    my $val = $app->peek_value($key);
	     #printf STDERR "\t\t%-40s: %40s\n",$key,$val;
	    $a{$key} = $val;
	    $self->{gvfs_keys}{$key} += 1;
	}
	my %e = ();
	$e{id} = $a{id}.'.desktop';
	$e{Type} = 'Application';
	$e{Name} = $a{name} if $a{name};
	$e{Name} = $a{id} unless $e{Name};
	$e{Terminal} = $a{requires_terminal} if $a{requires_terminal};
	$e{StartupNotify} = $a{startup_notify} if $a{startup_notify};
	$e{MimeType} = join(';',split(/,/,$a{mime_types})).';' if $a{mime_types};
	my $code = '';
	if ($a{expect_uris}) {
	    if ($a{expect_uris} eq 'true') {
		if ($a{can_open_multiple_files} and $a{can_open_multiple_files} eq 'true'){ 
		    $code = ' %U';
		} else {
		    $code = ' %u';
		}
	    } else {
		if ($a{can_open_multiple_files} and $a{can_open_multiple_files} eq 'true'){ 
		    $code = ' %F';
		} else {
		    $code = ' %f';
		}
	    }
	}
	$e{Exec} = $a{command}.$code if $a{command};
	$e{'X-SupportedURISchemes'} = $a{supported_uri_schemes}
	    if $a{supported_uri_schemes};
	$e{'X-UsesGnomeVFS'} = $a{uses_gnomevfs}
	    if $a{uses_gnomevfs};

	my $desktop = $self->{XDG_CURRENT_DESKTOP};
	unless ($e{Name}) {
	    $e{'X-Disable'} = 'true';
	    $e{'X-Disable-Reason'} = 'No Name';
	}
	unless ($e{Exec}) {
	    $e{'X-Disable'} = 'true';
	    $e{'X-Disable-Reason'} = 'No Exec';
	}
	if ($e{Hidden} and $e{Hidden} =~ m{true|yes}i) {
	    $e{'X-Disable'} = 'true';
	    $e{'X-Disable-Reason'} = 'Hidden';
	}
	if ($e{OnlyShowIn} and ";$e{OnlyShowIn};" !~ /;$desktop;/) {
	    $e{'X-Disable'} = 'true';
	    $e{'X-Disable-Reason'} = "Only shown in $e{OnlyShowIn}";
	}
	if ($e{NotShowIn} and ";$e{NotShowIn};" =~ /;$desktop;/) {
	    $e{'X-Disable'} = 'true';
	    $e{'X-Disable-Reason'} = "Not shown in $e{NotShowIn}";
	}
	unless ($e{TryExec}) {
	    ($e{TryExec}) = split(/\s+/,$e{Exec},2) if $e{Exec};
	}
	if (my $x = $e{TryExec}) {
            if ($x =~ m{/}) {
                unless (-x "$x") {
		    $e{'X-Disable'} = 'true';
		    $e{'X-Disable-Reason'} = "$x is not executable";
                     #next;
                }
            }
            else {
                my $found = 0;
                foreach (@PATH) {
                    if (-x "$_/$x") {
                        $found = 1;
                        last;
                    }
                }
                unless ($found) {
		    $e{'X-Disable'} = 'true';
		    $e{'X-Disable-Reason'} = "$x is not executable";
                     #next;
                }
            }
	}
	if (0) {
	foreach (sort keys %e) {
	    printf STDERR "%-20s: %-40s\n", $_, $e{$_};
	}
	}
#	$e{'X-Disable'} = 'false';
	$files{$e{id}} = \%e;
    }
    return \%files;
}

=item $desktop->B<read_mimeapps>()

Initialization method that uses XDE::Desktop::read_gvfsapps() and
XDG::Context::get_applications() to get all of the applications known to
L<Gnome2::VFS(3pm)> and those specified according to the XDG desktop
specification.  These applications are placed into the package global
hash C<%XDE::Desktop::MIME_APPLICATIONS> keyed by application id.  This
is later used by get_apps_and_subs() to retrieve applications and
subclass applications associated with a mime type.

This method is idempotent and can be called at any time to update the
hash.

=cut

sub read_mimeapps {
    my $self = shift;
    my $apps = $self->read_gvfsapps;
    foreach (keys %$apps) {
	$self->{applications}{$_} = $apps->{$_};
    }
    $apps = $self->get_applications;
    foreach (keys %$apps) {
	$self->{applications}{$_} = $apps->{$_};
    }
    undef $apps;
    %MIME_APPLICATIONS = ();
    %XDG_DESKTOPS = ();
    %XDG_CATEGORIES = ();
    foreach my $app (values %{$self->{applications}}) {
	if (my $show = $app->{OnlyShowIn}) {
	    foreach (split(/;/,$show)) {
		if ($_) { $XDG_DESKTOPS{$_} += 1; }
	    }
	}
	if (my $show = $app->{NotShowIn}) {
	    foreach (split(/;/,$show)) {
		if ($_) { $XDG_DESKTOPS{$_} += 1; }
	    }
	}
	if (my $cat = $app->{Categories}) {
	    foreach (split(/;/,$cat)) {
		if ($_) { $XDG_CATEGORIES{$_} += 1; }
	    }
	}
	if (my $mime = $app->{MimeType}) {
	    my %types = ();
	    foreach my $type (split(/;/,$mime)) {
		if ($type) {
		    $types{$type} = 1;
		    if ($MIME_ALIASES{$type}) {
			 #printf STDERR "!!! %-30s: mime aliases:\n", $type;
			foreach my $two (@{$MIME_ALIASES{$type}}) {
			    $types{$two} = 1 if $two;
			     #printf STDERR "--> %-30s: %-30s\n", $type, $two;
			}
		    } else {
			 #printf STDERR "xxx %-30s: no mime aliases:\n", $type;
		    }
		}
	    }
	    foreach my $type (keys %types) {
		push @{$MIME_APPLICATIONS{$type}}, $app;
		 #printf STDERR "==> %-30s: %-30s\n", $app->{id}, $type;
	    }
	}
    }
    $self->get_desktops;
    $self->get_categories;
    $self->{mimeapps} = $self->get_mimeapps;
}

=item $desktop->B<read_primary_data>()

Simply calls read_icons(), read_aliases(), read_subclasses() and
read_mimeapps() in order.

This method is idempotent and can be called at any time to update
primary data.

=cut

sub read_primary_data {
    my $self = shift;
    $self->read_icons;
    $self->read_aliases;
    $self->read_subclasses;
    $self->read_mimeapps;
}

=item $desktop->B<_init>() => $desktop

Internal method to initialize the module.  This is called by the
XDE::Context::new() method during initialization.

=cut


sub _init {
    my $self = shift;
     #print STDERR "-> Creating desktop...\n";
    my $verbose = $self->{ops}{verbose};

    # set up an Inotify2 connection
    unless ($self->{N}) {
	$self->{N} = Linux::Inotify2->new;
	$self->{N}->blocking(FALSE);
    }

    # initialize VFS
    Gnome2::VFS->init;

    # initialize icon search path
    my $icons = $self->{icontheme} =
	Gtk2::IconTheme->get_default;
    $icons->append_search_path("$ENV{HOME}/.icons");
    $icons->append_search_path("/usr/share/pixmaps");
    undef $icons;

    # initialize extensions
    my $X = $self->{X};
    $X->init_extensions;

    # set up the EWMH/WMH environment
    $self->XDE::Actions::setup;

    # get the root pixmap
    $self->get_XROOTPMAP_ID;

    # initialize pixmap array (one per desktop)
    $self->{pixmaps} = [];

    # set up the desktop window
    $self->create_desktop;

    return $self;
}

=item $desktop->B<create_desktop>() => $desktop

Internal method to create the window used for the desktop.  There are
two approaches to backgrounds:

=over

=item 1.

set the background pixmap to (and synchronize it with) the _XROOTPMAP_ID
property on the root window; and,

=item 2.

set the window to have a C<ParentRelative> background.

=back

In either case, because this is a Gtk2::Window, we must adjust the style
of the window to match the approach; otherwise, Gtk2 will set the
background corresponding to the style for the window.

=cut

use constant {
    TARGET_URI_LIST	=>1,
    TARGET_MOZ_URL	=>2,
    TARGET_XDS		=>3,
    TARGET_RAW		=>4,
};

sub create_desktop {
    my $self = shift;
    my $X = $self->{X};
    my $win = $self->{desktop} = Gtk2::Window->new('toplevel');
    $win->set_accept_focus(FALSE);
    $win->set_auto_startup_notification(TRUE);
    $win->set_decorated(FALSE);
    $win->set_default_size($X->width_in_pixels,$X->height_in_pixels);
    $win->set_deletable(FALSE);
    $win->set_focus_on_map(FALSE);
#   $win->set_frame_dimensions(0,0,0,0);
    $win->fullscreen;
    $win->set_gravity('static');
    $win->set_has_frame(FALSE);
#   $win->set_keep_below(TRUE);
    $win->move(0,0);
    $win->set_opacity(1.0);
    $win->set_position('center-always');
    $win->set_resizable(FALSE);
    $win->resize($X->width_in_pixels,$X->height_in_pixels);
    $win->set_skip_pager_hint(TRUE);
    $win->set_skip_taskbar_hint(TRUE);
    $win->stick;
    $win->set_type_hint('desktop');

#   $win->set_app_paintable(TRUE);
    unless ($win->get_double_buffered) {
	warn "Setting double buffering!";
	$win->set_double_buffered(TRUE);
    } else {
	warn "Double buffering already set!";
    }
#   $win->drag_dest_set(['drop'],[qw(copy ask move link private)],
#	    {target=>'text/uri-list',flags=>[],info=>&TARGET_URI_LIST},
##	    {target=>'text/x-moz-url',flags=>[],info=>&TARGET_MOZ_URL},
##	    {target=>'XdndDirectSave0',flags=>[],info=>&TARGET_XDS},
##	    {target=>'application/octet-stream',flags=>[],info=>&TARGET_RAW},
#	    );
#   $win->drag_dest_add_image_targets;
#   $win->drag_dest_add_text_targets;
#   $win->drag_dest_add_uri_targets;
    $win->set_size_request($X->width_in_pixels,$X->height_in_pixels);
    $win->parse_geometry($X->width_in_pixels."x".$X->height_in_pixels);

#		exposure-mask
    $win->add_events([qw(
		button-press-mask
		button-release-mask
		button1-motion-mask
		button2-motion-mask
		button3-motion-mask
		)]);

    $win->realize;
    $win->window->set_override_redirect(TRUE);
    $win->window->set_back_pixmap(undef,TRUE);
if (0) {
    my $gdk = $win->window;
    $gdk->set_accept_focus(FALSE);
    $gdk->set_back_pixmap(undef,TRUE);
    $gdk->set_composited(FALSE);
    $gdk->set_decorations([]);
    $gdk->set_focus_on_map(FALSE);
    $gdk->fullscreen;
    $gdk->set_functions([]);
    my $geom = Gtk2::Gdk::Geometry->new;
    $geom->base_width($X->width_in_pixels);
    $geom->base_height($X->height_in_pixels);
    $geom->gravity('static');
    $geom->max_width($X->width_in_pixels);
    $geom->max_height($X->height_in_pixels);
    $geom->min_width($X->width_in_pixels);
    $geom->min_height($X->height_in_pixels);
    $geom->win_gravity('static');
    $gdk->set_geometry_hints({
	    min_width=>$X->width_in_pixels,
	    min_height=>$X->height_in_pixels,
	    max_width=>$X->width_in_pixels,
	    max_height=>$X->height_in_pixels,
	    base_width=>$X->width_in_pixels,
	    base_height=>$X->height_in_pixels,
	    width_inc=>0,
	    height_inc=>0,
	    win_gravity=>'static',
	},['pos','user-pos','user-size']);
    $gdk->set_keep_below(TRUE);
    $gdk->move(0,0);
    $gdk->move_resize(0,0,$X->width_in_pixels,$X->height_in_pixels);
    $gdk->set_opacity(1.0);
    $gdk->set_override_redirect(TRUE);
    $gdk->register_dnd;
    $gdk->remove_redirection;
    $gdk->resize($X->width_in_pixels,$X->height_in_pixels);
    $gdk->restack(undef,FALSE);
    $gdk->set_skip_pager_hint(TRUE);
    $gdk->set_skip_taskbar_hint(TRUE);
    $gdk->set_static_gravities(TRUE);
    $gdk->stick;
    $gdk->set_type_hint('desktop');
    $gdk->set_urgency_hint(TRUE);
#   $gdk->clear;
    $gdk->process_all_updates;
    $gdk->show_unraised;
    $gdk->lower;
    $X->ConfigureWindow($gdk->XID,stack_mode=>'Below');
}

    $win->signal_connect_swapped(button_press_event=>\&button_press_event,$self);
    $win->signal_connect_swapped(button_release_event=>\&button_release_event,$self);
#   $win->signal_connect_swapped(motion_notify_event=>\&motion_notify_event,$self);
#   $win->signal_connect_swapped(expose_event=>\&expose_event,$self);
    $win->signal_connect_swapped(scroll_event=>\&scroll_event,$self);

#   $win->signal_connect_swapped(drag_drop=>&drag_drop,$self);
#   $win->signal_connect_swapped(drag_data_received=>\&drag_data_received,$self);
#   $win->signal_connect_swapped(drag_motion=>\&drag_motion,$self);
#   $win->signal_connect_swapped(drag_leave=>\&drag_leave,$self);

    my $aln = $self->{align} = Gtk2::Alignment->new(0.5,0.5,1.0,1.0);
#   my $fix = $self->{fixed} = Gtk2::Fixed->new;
#   $fix->set_size_request($X->width_in_pixels,$X->height_in_pixels);

    $win->set_border_width(0);
#   $win->add($fix);
    $win->add($aln);

    my $tab = $self->{table} = Gtk2::Table->new(1,1,TRUE);
    $tab->set_col_spacings(0);
    $tab->set_row_spacings(0);
    $tab->set_homogeneous(TRUE);
    $tab->set_size_request(ICON_WIDE,ICON_HIGH);
#   $tab->set_tooltip_text('Click Me!');

#   $fix->put($tab,0,0);
    $aln->add($tab);

    if (0) {
    my $rows = int(($X->height_in_pixels+ICON_HIGH-1)/ICON_HIGH)-2;
    my $cols = int(($X->width_in_pixels +ICON_WIDE-1)/ICON_WIDE)-2;
    warn "rows = $rows, cols = $cols";
    my $tab = $self->{table} = Gtk2::Table->new($rows,$cols,TRUE);
    $tab->set_col_spacings(0);
    $tab->set_row_spacings(0);
    $tab->set_homogeneous(TRUE);
    $tab->set_size_request($X->width_in_pixels-144,$X->height_in_pixels-144);
    $tab->signal_connect(expose_event=>sub{
	    my ($tab,$event) = @_;
	    my $area = $event->area;
	    if (0) {
	    printf STDERR "Exposure area: x=%d, y=%d, w=%d, h=%d\n",
		$area->x, $area->y, $area->width, $area->height;
	    }
	    return  Gtk2::EVENT_PROPAGATE;
    });

#   $fix->put($tab,ICON_WIDE,ICON_HIGH);

    my ($icon,$but,$v,$h,$a,$b,$pixbuf,$l);

    $icon = Gtk2::Image->new_from_icon_name('gtk-missing-image','dialog');
    $icon->set_alignment(0.5,0.5);
    $icon->set_padding(0,0);
    $but = Gtk2::Button->new;
    $but->set_size_request(ICON_WIDE,ICON_HIGH);
    $but->set_alignment(0.5,0.0);
    $but->set_border_width(0);
    $but->set_relief('none');
    $but->set_image_position('top');
    $but->set_image($icon);
    $but->set_label('An icon');
    $but->set_tooltip_text('A tooltip');
    $tab->attach($but,0,1,0,1,['fill'],['fill'],0,0);
    $but->show_all;

    $icon = Gtk2::Image->new_from_icon_name('gtk-missing-image','dialog');
    $icon->set_alignment(0.5,0.5);
    $icon->set_padding(0,0);
    $but = Gtk2::Button->new;
    $but->set_size_request(ICON_WIDE,ICON_HIGH);
    $but->set_alignment(0.5,0.0);
    $but->set_border_width(0);
    $but->set_relief('none');
    $but->set_image_position('top');
    $but->set_image($icon);
    $but->set_label('Another icon');
    $but->set_tooltip_text('Another tooltip');
    $tab->attach($but,0,1,1,2,['fill'],['fill'],0,0);
    $but->show_all;

    $icon = Gtk2::Image->new_from_icon_name('gtk-missing-image','dialog');
    $icon->set_alignment(0.5,0.5);
    $icon->set_padding(0,0);
    $but = Gtk2::Button->new;
    $but->set_size_request(ICON_WIDE,ICON_HIGH);
    $but->set_alignment(0.5,0.0);
    $but->set_border_width(0);
    $but->set_relief('none');
    $but->set_image_position('top');
    $but->set_image($icon);
    $but->set_label('Another icon');
    $but->set_tooltip_text('Another tooltip');
    $tab->attach($but,4,5,4,5,['fill'],['fill'],0,0);
    $but->show_all;

    $icon = Gtk2::Image->new_from_icon_name('gtk-missing-image','dialog');
    $icon->set_alignment(0.5,0.5);
    $icon->set_padding(0,0);
    $pixbuf = $icon->render_icon('gtk-missing-image','dialog');
    $but = Gtk2::Button->new;
    $but->set_size_request(ICON_WIDE,ICON_HIGH);
    $but->set_alignment(0.5,0.0);
    $but->set_border_width(0);
    $but->set_relief('none');
    $but->set_tooltip_text('Even more tooltips');
    $v = Gtk2::VBox->new(FALSE,0);
    $but->add($v);
#   $a = Gtk2::Alignment->new(0.5,0.0,1.0,1.0);
    $h = Gtk2::HBox->new(FALSE,0);
    $h->set_size_request(48,48);
#   $a->add($h);
    $h->signal_connect(expose_event=>sub{
	    my ($hbox,$event,$pixbuf) = @_;
	    my $gc = $hbox->style->black_gc;
	    $gc->set_clip_region($event->region);
	    $hbox->window->draw_pixbuf($gc,$pixbuf,0,0,
		$hbox->allocation->x,$hbox->allocation->y,
		-1,-1,'normal',0,0);
	    $gc->set_clip_region(undef);
	    return Gtk2::EVENT_STOP;
    },$pixbuf);
    $v->pack_start($h,FALSE,FALSE,0);
    $l = Gtk2::Label->new;
    $l->set_size_request(-1,-1);
    $l->set_padding(0,0);
    $l->set_alignment(0.5,0.5);
    $l->set_line_wrap_mode('word-char');
    $l->set_line_wrap(TRUE);
    $l->set_justify('center');
    $l->set_markup('<span font="Liberation Sans Bold 8">A really long label</span>');
#   $b = Gtk2::Alignment->new(0.5,1.0,1.0,1.0);
#   $b->add($l);
    $v->pack_end($l,FALSE,FALSE,0);
    $tab->attach($but,7,8,7,8,['fill'],['fill'],0,0);
    $but->show_all;

    $icon = Gtk2::Image->new_from_icon_name('gtk-missing-image','dialog');
    $icon->set_alignment(0.5,0.5);
    $icon->set_padding(0,0);
    $icon->set_size_request(48,48);
    $but = Gtk2::Button->new;
    $but->set_size_request(ICON_WIDE,ICON_HIGH);
    $but->set_alignment(0.5,0.5);
    $but->set_border_width(0);
    $but->set_relief('none');
    $but->set_tooltip_text('Even more tooltips');
    $v = Gtk2::VBox->new(FALSE,0);
    $but->add($v);
    $v->pack_start($icon,TRUE,FALSE,0);
    $h = Gtk2::HBox->new(TRUE,0);
    $v->pack_start($h,TRUE,FALSE,0);
    $l = Gtk2::Label->new;
    $l->set_size_request(-1,-1);
    $l->set_padding(0,0);
    $l->set_line_wrap_mode('word-char');
    $l->set_line_wrap(TRUE);
#   $l->set_max_width_chars(10);
    $l->set_width_chars(10);
    $l->set_justify('center');
    $l->set_markup('<span font="Liberation Sans Bold 8">this_is_a_very_long_filename.pdf</span>');
    $l->set_alignment(0.5,0.5);
#   $b = Gtk2::Alignment->new(0.5,0.2,1.0,1.0);
#   $b->add($l);
    $h->pack_start($l,FALSE,FALSE,0);
    $tab->attach($but,8,9,8,9,[],[],0,0);
    $but->show_all;
    }

    $self->set_style;

    $tab->show;
#   $fix->show;
    $aln->show;
    $win->show;
    $win->window->lower;
#   $gdk->lower;
#   $X->ConfigureWindow($gdk->XID,stack_mode=>'Below');

    return $self;
}

=item $desktop->B<set_style>()

Adjusts the style of the desktop window to use the pixmap specified by
C<_XROOTPMAP_ID> as the background.  Uses L<Gtk2(3pm)> styles to do
this.  You must call get_XROOTPMAP_ID() before calling this method for
it to work correctly.

=cut

sub set_style {
    my $self = shift;
    my $pmap = $self->{_XROOTPMAP_ID};
    $pmap = $self->get_XROOTPMAP_ID unless defined $pmap;
    unless ($pmap) {
	warn "No pixmap for _XROOTPMAP_ID!";
	return;
    }

    unless ($self->{old_XROOTPMAP_ID} and $self->{old_XROOTPMAP_ID} == $pmap) {

	my $dtop = $self->{_NET_CURRENT_DESKTOP};
	$dtop = $self->get_NET_CURRENT_DESKTOP unless defined $dtop;
	$dtop = $self->{_WIN_WORKSPACE} unless defined $dtop;
	$dtop = $self->get_WIN_WORKSPACE unless defined $dtop;
	$dtop = 1 unless defined $dtop;

	my $pobj;
	# go looking for it
	foreach (@{$self->{pixmaps}}) {
	    if ($_ and $_->{pmap} == $pmap) {
		$pobj = $_;
		last;
	    }
	}
	$pobj = XDE::Desktop::Pmap->new($pmap) unless $pobj;
	$self->{pixmaps}[$dtop] = $pobj;
	my $pixmap = $pobj->{pixmap};
#	$pixmap->set_colormap(Gtk2::Gdk::Screen->get_default->get_default_colormap);

	my $style = $self->{desktop}->get_default_style->copy;
	foreach (qw(normal prelight)) {
	    $style->bg_pixmap($_,$pixmap);
	}
	$self->{desktop}->set_style($style);
#	$self->{desktop}->window->clear;
	$self->{old_XROOTPMAP_ID} = $pmap;
    }
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
    print STDERR "==> Calculating cells...\n";
    $self->calculate_cells;
    print STDERR "==> Arranging icons...\n";
    $self->arrange_icons;
    print STDERR "==> Showing icons...\n";
    $self->show_icons;
}

=item $desktop->B<calculate_cells>() => $changed

Creates an array of ICON_WIDEx72 cells on the desktop in columns and rows.
This uses the available area of the desktop as indicated by the
C<_NET_WORKAREA> or C<_WIN_WORKAREA> properties on the root window.
Returns a boolean indicating whether the calculation changed.

=cut

sub calculate_cells {
    my $self = shift;
    my $X = $self->{X};
    my ($x,$y,$w,$h);
    if ($self->{_NET_WORKAREA}) {
	 #print STDERR "Have _NET_WORKAREA\n";
	my $n = $self->{_NET_CURRENT_DESKTOP};
	$n = $self->get_NET_CURRENT_DESKTOP unless defined $n;
	$n = 0 unless defined $n;
	my $m = @{$self->{_NET_WORKAREA}};
	$n = 0 if $n >= $m/4;
	$n *= 4; $m = $n + 3;
	($x,$y,$w,$h) = @{$self->{_NET_WORKAREA}}[$n..$m];
    }
    elsif ($self->{_WIN_WORKAREA}) {
	 #print STDERR "Have _WIN_WORKAREA\n";
	my ($x1,$y1,$x2,$y2) = @{$self->{_WIN_WORKAREA}};
	($x,$y,$w,$h) = ($x1,$x2,$x2-$x1,$y2-$y1);
    }
    else {
	 #print STDERR "No _NET_WORKAREA or _WIN_WORKAREA\n";
	# just WindowMaker and AfterStep do not set either
	# leave room for clip and dock (or wharf)
	($x,$y,$w,$h) =
	    ((64,64),($X->width_in_pixels-128,$X->height_in_pixels-128));
    }
    if ($self->{workarea} and
	    $self->{workarea}[0] == $x and
	    $self->{workarea}[1] == $y and
	    $self->{workarea}[2] == $w and
	    $self->{workarea}[3] == $h) {
	return 0;
    }
    $self->{workarea} = [$x,$y,$w,$h];
    # leave at least 1/2 a cell ((36,42) pixels) around the desktop area to
    # accomodate window managers that do not account for panels.
    my $cols = $self->{cols} = int($w/ICON_WIDE);
    my $rows = $self->{rows} = int($h/ICON_HIGH);
    my $xoff = $self->{xoff} = int(($w-$cols*ICON_WIDE)/2);
    my $yoff = $self->{yoff} = int(($h-$rows*ICON_HIGH)/2);
     #print STDERR "Table: cols=$cols,rows=$rows,xoff=$xoff,yoff=$yoff\n";
    my $table = $self->{table};
#   $self->{fixed}->move($table,$xoff,$yoff);
     #print STDERR "Warea: x=$x,y=$y,w=$w,h=$h\n";
    my ($T,$B,$L,$R) = (
	    $y,($X->height_in_pixels-$y-$h),
	    $x,($X->width_in_pixels-$x-$w),
	    );
    $self->{align}->set_padding($T,$B,$L,$R);
     #print STDERR "Align: t=$T,b=$B,l=$L,r=$R\n";
    my ($r,$c) = $table->get_size;
    if ($r != $rows or $c != $cols) {
	if ($r < $rows or $c < $cols) {
	    # icons might be out of place
	    $self->remove_icons;
	} else {
	    # leave icons where they are for now
	}
	$table->set_size_request(ICON_WIDE*$cols,ICON_HIGH*$rows);
	$table->resize($rows,$cols);
    }
    return 1;
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
     #print STDERR "-> Directory is '$dir'\n";
    opendir(my $dh, $dir) or return;
     #print STDERR "-> Opening directory\n";
    foreach my $f (readdir($dh)) {
	if (0) {
	print STDERR "-> Got entry: $f\n"
	    if $self->{ops}{verbose};
	}
	next if $f eq '.' or $f eq '..';
	next if $f =~ m{^\.};  # TODO: option for hidden files.
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
    foreach (@{shift->{icons}{detop}}) { $_->hide }
}

=item $desktop->B<show_icons>()

Shows all of the desktop icons.  The method simply requests that each
icon show itself.

=cut

sub show_icons {
    foreach (@{shift->{icons}{detop}}) { $_->show }
}

=item $desktop->B<remove_icons>()

Remove all of the desktop icons.  This does not deallocate the icons.

=cut

sub remove_icons {
    my $self = shift;
    my $table = $self->{table};
    foreach (@{$self->{icons}{detop}}) { $_->remove($table) }
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
    $row += 1; $y += ICON_HIGH;
    unless ($row < $self->{rows}) {
	$row = 0; $y = $self->{yoff};
	$col += 1; $x += ICON_WIDE;
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
	$col += 1; $x += ICON_WIDE;
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
    my $table = $self->{table};
    if (@{$self->{icons}{links}} and $col < $self->{cols}) {
	foreach (@{$self->{icons}{links}}) {
	    $_->place($table,$col,$row);
	    push @{$self->{icons}{detop}}, $_;
	    ($col,$row,$x,$y) = $self->next_cell($col,$row,$x,$y);
	    last unless $col < $self->{cols};
	}
	($col,$row,$x,$y) = $self->next_column($col,$row,$x,$y);
    }
    if (@{$self->{icons}{dires}} and $col < $self->{cols}) {
	foreach (@{$self->{icons}{dires}}) {
	    $_->place($table,$col,$row);
	    push @{$self->{icons}{detop}}, $_;
	    ($col,$row,$x,$y) = $self->next_cell($col,$row,$x,$y);
	    last unless $col < $self->{cols};
	}
	($col,$row,$x,$y) = $self->next_column($col,$row,$x,$y);
    }
    if (@{$self->{icons}{files}} and $col < $self->{cols}) {
	foreach (@{$self->{icons}{files}}) {
	    $_->place($table,$col,$row);
	    push @{$self->{icons}{detop}}, $_;
	    ($col,$row,$x,$y) = $self->next_cell($col,$row,$x,$y);
	    last unless $col < $self->{cols};
	}
    }
}

=item $desktop->B<rearrange_icons>()

Recalculate the cell positions given the current work area and
reposition all existing desktop icons so that they correspond to the
layout for the given workarea.  This method only performs the
rearrangement when the work area has changed.

=cut

sub rearrange_icons {
    my $self = shift;
    if ($self->calculate_cells) {
	$self->arrange_icons;
    }
}

use constant {
    KEYBUTMASK_SHIFT_MASK	=>(1<< 0),
    KEYBUTMASK_LOCK_MASK	=>(1<< 1),
    KEYBUTMASK_CONTROL_MASK	=>(1<< 2),
    KEYBUTMASK_MOD1_MASK	=>(1<< 3),
    KEYBUTMASK_MOD2_MASK	=>(1<< 4),
    KEYBUTMASK_MOD3_MASK	=>(1<< 5),
    KEYBUTMASK_MOD4_MASK	=>(1<< 6),
    KEYBUTMASK_MOD5_MASK	=>(1<< 7),
    KEYBUTMASK_BUTTON1_MASK	=>(1<< 8),
    KEYBUTMASK_BUTTON2_MASK	=>(1<< 9),
    KEYBUTMASK_BUTTON3_MASK	=>(1<<10),
    KEYBUTMASK_BUTTON4_MASK	=>(1<<11),
    KEYBUTMASK_BUTTON5_MASK	=>(1<<12),

    KEYBUTMASK_SUPER_MASK	=>(1<<13),
    KEYBUTMASK_HYPER_MASK	=>(1<<14),
    KEYBUTMASK_META_MASK	=>(1<<15),
    KEYBUTMASK_RELEASE_MASK	=>(1<<16),
    KEYBUTMASK_MODIFIER_MASK	=>(1<<17),
};
use constant {
    GTKSTATE_XLATE=>{
	'shift-mask'	=>&KEYBUTMASK_SHIFT_MASK,
	'lock-mask'	=>&KEYBUTMASK_LOCK_MASK,
	'control-mask'	=>&KEYBUTMASK_CONTROL_MASK,
	'mod1-mask'	=>&KEYBUTMASK_MOD1_MASK,
	'mod2-mask'	=>&KEYBUTMASK_MOD2_MASK,
	'mod3-mask'	=>&KEYBUTMASK_MOD3_MASK,
	'mod4-mask'	=>&KEYBUTMASK_MOD4_MASK,
	'mod5-mask'	=>&KEYBUTMASK_MOD5_MASK,
	'button1-mask'	=>&KEYBUTMASK_BUTTON1_MASK,
	'button2-mask'	=>&KEYBUTMASK_BUTTON2_MASK,
	'button3-mask'	=>&KEYBUTMASK_BUTTON3_MASK,
	'button4-mask'	=>&KEYBUTMASK_BUTTON4_MASK,
	'button5-mask'	=>&KEYBUTMASK_BUTTON5_MASK,

	'super-mask'	=>&KEYBUTMASK_SUPER_MASK,
	'hyper-mask'	=>&KEYBUTMASK_HYPER_MASK,
	'meta-mask'	=>&KEYBUTMASK_META_MASK,
	'release-mask'	=>&KEYBUTMASK_RELEASE_MASK,
	'modifier-mask'	=>&KEYBUTMASK_MODIFIER_MASK,
    },
};

=item XDE::Desktop->B<xlate_state>(I<$states>) => $state

L<Gtk2(3pm)> specifies the state associated with an event using a
textual description.  L<X11::Protocol(3pm)> uses a bit mask.  This
method simply translates the former to the later.  It is used for
passing events from L<Gtk2(3pm)> to L<X11::Protocol(3pm)> and should
probably by part of the L<XDE::Dual(3pm)> module instead of here.

=cut

sub xlate_state {
    my ($self,$states) = @_;
    my $state = 0;
    foreach (split(/\s+/,$states)) {
	next if $_ eq '[' or $_ eq ']';
	if (exists &GTKSTATE_XLATE->{$_}) {
	    $state |= &GTKSTATE_XLATE->{$_};
	} else {
	    warn "Unknown KEYBUTMASK $_";
	}
    }
    return $state;
}

=item $desktop->B<button_press_event>(I<$event>,I<$win>) => $boolean

Gtk2::Gdk::Event handler to process button press events.  Note that this
does not include buttons 4 or 5 (these are handled in scroll_event).
Basically we want to pass this event to the root window so that the
window manager can respond to it.  We might use button 1 (normally
unused by the window manager), or another button with a modifier, to
launch the desktop root menu.

=cut

sub button_press_event {
    my $self = shift;
    my ($event,$win) = @_;
    if (0) {
    if ($event->button == 1 or $event->button == 3) {
	my ($x,$y) = $event->get_coords;
	foreach my $icon (@{$self->{icons}{detop}}) {
	    my $alloc = $icon->{gtk}{icon}->allocation;
	    my $region = Gtk2::Gdk::Region->rectangle($alloc);
	    if ($region->point_in($x,$y)) {
		printf STDERR "Allocation: x=%d,y=%d,w=%d,h=%d\n",
		       $alloc->x,$alloc->y,$alloc->width,$alloc->height;
		printf STDERR "Event: x=%d,y=%d\n",$x,$y;
		if ($event->button == 3) {
		    $icon->popup($event);
		    return Gtk2::EVENT_STOP;
		}
		else {
		    $icon->click($event);
		    return Gtk2::EVENT_STOP;
		}

	    }
	}
    }
    }
    return Gtk2::EVENT_PROPAGATE if $event->button == 1;
    $win->window->lower;
    my $X = $self->{X};
    $X->ConfigureWindow($win->window->XID,stack_mode=>'Below');
    my %e = (
	name=>'ButtonPress',
	detail=>$event->button,
	time=>$event->time,
	root=>$X->root,
	event=>$X->root,
	child=>'None',
	root_x=>$event->x_root,
	root_y=>$event->y_root,
	event_x=>$event->x_root,
	event_y=>$event->y_root,
	state=>$self->xlate_state($event->state),
	same_screen=>1,
    );
    Gtk2::Gdk->pointer_ungrab($event->time);
    $X->SendEvent($X->root, 0,
	    $X->pack_event_mask(qw(ButtonPress)),
	    $X->pack_event(%e));
    $X->flush;
    return Gtk2::EVENT_STOP;
}

=item $desktop->B<button_release_event>(I<$event>,I<$win>) => $boolean

Gtk2::Gdk::Event handler to process button release events.  Note that
this does not include buttons 4 or 5 (these are handled in
scroll_event).  Bsically we want to pass this event to the root window
so that the window manager can respond to it.  We might use button 1
(normally unused by the window manager), or another button with a
modifier, to launch the desktop root menu.

=cut

sub button_release_event {
    my $self = shift;
    my ($event,$win) = @_;
    return Gtk2::EVENT_PROPAGATE if $event->button == 1;
    $win->window->lower;
    my $X = $self->{X};
    $X->ConfigureWindow($win->window->XID,stack_mode=>'Below');
    my %e = (
	name=>'ButtonRelease',
	detail=>$event->button,
	time=>$event->time,
	root=>$X->root,
	event=>$X->root,
	child=>'None',
	root_x=>$event->x_root,
	root_y=>$event->y_root,
	event_x=>$event->x_root,
	event_y=>$event->y_root,
	state=>$self->xlate_state($event->state),
	same_screen=>1,
    );
    $X->SendEvent($X->root,0,
	    $X->pack_event_mask(qw(ButtonRelease)),
	    $X->pack_event(%e));
    $X->flush;
    # TODO: handle button release event internally
    return Gtk2::EVENT_STOP;
}

=item $desktop->B<scroll_event_passalong>(I<$event>,I<$win>) => $boolean

Gtk2::Gdk::Event handler for Gtk2::Gdk::Event::Scroll events.  This
method simply passes the scroll wheel events to the root window.  Note
that this includes scroll events on desktop icons.

=cut

sub scroll_event_passalong {
    my $self = shift;
    my ($event,$win) = @_;
    $win->window->lower;
    my $X = $self->{X};
    $X->ConfigureWindow($win->window->XID,stack_mode=>'Below');
    my %e = (
	name=>'ButtonPress',
	time=>$event->time,
	root=>$X->root,
	event=>$X->root,
	child=>'None',
	root_x=>$event->x_root,
	root_y=>$event->y_root,
	event_x=>$event->x_root,
	event_y=>$event->y_root,
	state=>$self->xlate_state($event->state),
	same_screen=>1,
    );
    my $dir = $event->direction;
    if ($dir eq 'up' or $dir eq 'right') {
	$e{detail} = 4;
    }
    elsif ($dir eq 'down' or $dir eq 'left') {
	$e{detail} = 5;
    }
    Gtk2::Gdk->pointer_ungrab($event->time);
    $X->SendEvent($X->root,0,
	    $X->pack_event_mask(qw(ButtonPress)),
	    $X->pack_event(%e));
    $e{name} = 'ButtonRelease';
    $e{state} |= (1<<($e{detail}+7));
#   $e{time} = $e{time}+1;
    $X->SendEvent($X->root,0,
	    $X->pack_event_mask(qw(ButtonRelease)),
	    $X->pack_event(%e));
    $X->flush;
    return Gtk2::EVENT_STOP;
}

=item $desktop->B<scroll_event_override>(I<$event>,I<$win>) => $boolean

Gtk2::Gdk::Event handler for Gtk2::Gdk::Event::Scroll events.  This
method overrides the behaviour of the window manager's response to
scroll wheel events on the desktop; however, if any unused modifiers are
present, the event is passed along to the root window.

=cut

sub scroll_event_override {
    my $self = shift;
    my ($event,$win) = @_;
    $win->window->lower;
    my $X = $self->{X};
    $X->ConfigureWindow($win->window->XID,stack_mode=>'Below');
    my $dir = $event->direction;
    my $time = $event->time;
    my $mods = $self->xlate_state($event->state) & 0xfd;
     #warn sprintf "Modifiers is 0x%x", $mods;
    if ($mods == 0) {
	# Scroll moves next or prev with wrap
	if ($dir eq 'up' or $dir eq 'right') {
	    $self->DesktopNext($time,1,1);
	} elsif ($dir eq 'down' or $dir eq 'left') {
	    $self->DesktopPrev($time,1,1);
	}
    }
    elsif ($mods == &KEYBUTMASK_CONTROL_MASK) {
	# Ctrl+Scroll moves right or left without wrap
	if ($dir eq 'up' or $dir eq 'right') {
	    $self->DesktopRight($time,1,0);
	} elsif ($dir eq 'down' or $dir eq 'left') {
	    $self->DesktopLeft($time,1,0);
	}
    }
    elsif ($mods == &KEYBUTMASK_SHIFT_MASK) {
	# Shift+Scroll moves up or down without wrap
	if ($dir eq 'up' or $dir eq 'right') {
	    $self->DesktopUp($time,1,0);
	} elsif ($dir eq 'down' or $dir eq 'left') {
	    $self->DesktopDown($time,1,0);
	}
    }
    else {
	return $self->scroll_event_passalong(@_);
    }
    return Gtk2::EVENT_STOP;
}

=item $desktop->B<scroll_event_openbox>(I<$event>,I<$win>) => $boolean

Gtk2::Gdk::Event handler for Gtk2::Gdk::Event::Scroll events for the
L<openbox(1)> window manager.
L<openbox(1)> has a strange idea for changing desktops using scroll
events.  Scroll events only change desktops within a row of the desktop
layout, but much can be changed using the L<openbox(1)> configuration
file.  B<XDE::Desktop> intercepts scroll events on the desktop and makes
the experience consistent with other window managers by calling
scroll_event_override().

=cut

sub scroll_event_openbox {
    my $self = shift;
    return $self->scroll_event_override(@_);
}

=item $desktop->B<scroll_event_pekwm>(I<$event>,I<$win>) => $boolean

Gtk2::Gdk::Event handler for Gtk2::Gdk::Event::Scroll events for the
L<pekwm(1)> window manager.
L<pekwm(1)> has a strange idea for changing desktops using scroll
events.  Scroll events only change desktops within a row of the desktop
layout.  B<XDE::Desktop> intercepts scroll events on the desktop and
makes the experience consistent with other window managers by calling
scroll_event_override().

=cut

sub scroll_event_pekwm {
    my $self = shift;
    return $self->scroll_event_override(@_);
}

=item $desktop->B<scroll_event_jwm>(I<$event>,I<$win>) => $boolean

Gtk2::Gdk::Event handler for Gtk2::Gdk::Event::Scroll events for the
L<jwm(1)> window manager.  The JWM panel reverses the direction of the
scroll wheel: we do C<up> is I<DesktopNext> and C<down> is
I<DesktopPrev>, whereas JWM does C<up> is I<DesktopLeft> with wrap,
C<down> is I<DesktopRight> with wrap.  There are no scroll wheel
definitions for I<DesktopNext>, I<DesktopPrev>, I<DesktopUp> or
I<DesktopDown> (see L<XDE::Actions(3pm)>).

=cut

sub scroll_event_jwm {
    my $self = shift;
    return $self->scroll_event_override(@_);
}

=item $desktop->B<scroll_event_icewm>(I<$event>,I<$win>) => $boolean

Gtk2::Gdk::Event handler for Gtk2::Gdk::Event::Scroll events.  We
basically provide for the basic desktop events here, particularly
because L<icewm(1)> cannot handle scroll events unless specially
specified in the F<preferences> file and forwarding them usually
accomplishes nothing when L<icewm(1)> is running.

=cut

sub scroll_event_icewm {
    my $self = shift;
    return $self->scroll_event_override(@_);
}

=item $desktop->B<scroll_event>(I<$event>,I<$window>) => $boolean

Gtk2::Gdk::Event handler for Gtk2::Gdk::Event::Scroll events.  Decides
which behaviour to use based on the window manager.  The default
currently is to pass along scroll events.

=cut

sub scroll_event {
    my $self = shift;
    if ($self->{wmname} and
	    (my $sub = $self->can("scroll_event_$self->{wmname}"))) {
	return &$sub($self,@_);
    }
    return $self->scroll_event_passalong(@_);
}

=item $desktop->B<draw_lasso>()

Unused method taken from L<rox(1)>.

=cut

sub draw_lasso {
    my $self = shift;
    return unless $self->{lasso};
    my $area = Gtk2::Gdk::Rectangle->new(0,0,0,0);
    if ($self->{lasso}{x1} < $self->{lasso}{x2}) {
	$area->x($self->{lasso}{x1});
	$area->width($self->{lasso}{x2} - $self->{lasso}{x1});
    } else {
	$area->x($self->{lasso}{x2});
	$area->width($self->{lasso}{x1} - $self->{lasso}{x2});
    }
    if ($self->{lasso}{y1} < $self->{lasso}{y2}) {
	$area->y($self->{lasso}{y1});
	$area->height($self->{lasso}{y2} - $self->{lasso}{y1});
    } else {
	$area->y($self->{lasso}{y2});
	$area->height($self->{lasso}{y1} - $self->{lasso}{y2});
    }
    my $win = $self->{desktop}->window;
    my $edge = Gtk2::Gdk::Rectangle->new($area->values);
    $edge->height(2);
    $win->invalidate_rect($edge,TRUE);

    $edge->y($edge->y + $area->height - 2);
    $win->invalidate_rect($edge,TRUE);

    $edge->y($area->y);
    $edge->height($area->height);
    $edge->width(2);
    $win->invalidate_rect($edge,TRUE);

    $edge->x($edge->x + $area->width - 2);
    $win->invalidate_rect($edge,TRUE);
}

=item $desktop->B<motion_notify_event>(I<$event>,I<$win>)

Unused method taken from L<rox(1)>.

=cut

sub motion_notify_event {
    my $self = shift;
    my ($event,$win) = @_;
    $win->window->lower;
    my $X = $self->{X};
    $X->ConfigureWindow($win->window->XID,stack_mode=>'Below');
    return Gtk2::EVENT_PROPAGATE unless $self->{lasso};
    my ($x,$y) = $event->get_coords;
    if ($self->{lasso}{x2} != $x or $self->{lasso}{y2} != $y) {
	$self->draw_lasso;
	$self->{lasso}{x2} = $x;
	$self->{lasso}{y2} = $y;
	$self->draw_lasso;
    }
}

=item $desktop->B<expose_event>(I<$event>,I<$win>)

Unused method taken from L<rox(1)>.

=cut

sub expose_event {
    warn "expose-event: ",join(',',@_);
    my $self = shift;
    my ($event,$win) = @_;
    my $region1 = $event->region;
    my $rect = $region1->get_clipbox;
    my ($x,$y,$w,$h) = ($rect->x,$rect->y,$rect->width,$rect->height);
     #printf STDERR "Exposure area: x=%d, y=%d, w=%d, h=%d\n", $x, $y, $w, $h;
#   $win->window->invalidate_rect($rect,TRUE);
#   return Gtk2::EVENT_STOP;
    $win->window->clear_area($x,$y,$w,$h);
    return Gtk2::EVENT_PROPAGATE;
    my $region2 = Gtk2::Gdk::Region->rectangle($rect);
    $region2->subtract($region1);
    unless ($region2->empty) {
	foreach ($region2->get_rectangles) {
	    $win->window->invalidate_rect($_,TRUE);
	}
    }
    return Gtk2::EVENT_PROPAGATE;
}

=item $desktop->B<drag_data_received>(I<$drag>,I<$select>,I<$win>) => $propagate

Unused method taken from L<rox(1)>.

=cut

sub drag_data_received {
    warn "drag-data-received: ",join(',',@_);
    my $self = shift;
    my ($drag,$select,$win) = @_;
    return Gtk2::EVENT_PROPAGATE;
}

=item $desktop->B<drag_motion>(I<$drag>,I<$x>,I<$y>,I<$id>,I<$win>) => $propagate

Unused method taken from L<rox(1)>.

=cut

sub drag_motion {
    warn "drag-motion: ",join(',',@_);
    my $self = shift;
    my ($drag,$x,$y,$id,$win) = @_;
    return Gtk2::EVENT_PROPAGATE;
}

=item $desktop->B<drag_leave>(I<$drag>,I<$id>,I<$win>) => $propagate

Unused method taken from L<rox(1)>.

=cut

sub drag_leave {
    warn "drag-leave: ",join(',',@_);
    my $self = shift;
    my ($drag,$id,$win) = @_;
    return Gtk2::EVENT_PROPAGATE;
}


=item $desktop->B<get_XROOTPMAP_ID>() => $value

Return the C<_XROOTPMAP_ID> property from the root window and store it
in C<$self-E<gt>{_XROOTPMAP_ID}>.

=cut

sub get_XROOTPMAP_ID {
    return shift->getWMRootPropertyInt('_XROOTPMAP_ID');
}

=item $desktop->B<event_handler_PropertyNotify_XROOTPMAP_ID>(I<$e>,I<$X>,I<$v>)

L<XDE::X11(3pm)> event handler for changes to the C<_XROOTPMAP_ID>
property on the root window.  The default response is to obtain the new
value of the property and set the style accordingly by calling
set_style().  This is the way that XDE::Desktop plays nice with any
background setter: it simply makes its background equal to whatever
C<_XROOTPMAP_ID> says it should be.

=cut

sub event_handler_PropertyNotify_XROOTPMAP_ID {
    my $self = shift;
    my ($e,$X,$v) = @_;
    return unless $e->{window} == $X->root;
    $self->get_XROOTPMAP_ID;
    $self->set_style;
#   $self->{desktop}->window->clear;
}

=item $desktop->B<event_handler_PropertyNotify_NET_WORKAREA>(I<$e>,I<$X>,I<$v>)

L<XDE::X11(3pm)> event handler for changes to the C<_NET_WORKAREA>
property on the root window.  When this property changes we may need to
adjust the area occupied by desktop icons by calling rearrange_icons().

=cut

sub event_handler_PropertyNotify_NET_WORKAREA {
    my $self = shift;
    my ($e,$X,$v) = @_;
    return unless $e->{window} == $X->root;
    $self->get_NET_WORKAREA;
    $self->rearrange_icons;
}

=item $desktop->B<event_handler_PropertyNotify_NET_CURRENT_DESKTOP>(I<$e>,I<$X>,I<$v>)

L<XDE::X11(3pm)> event handler for changes to the
C<_NET_CURRENT_DESKTOP> property of the root window.  When this property
changes we may need to adjust the area occupied by desktop icons by
calling rearrange_icons().

=cut

sub event_handler_PropertyNotify_NET_CURRENT_DESKTOP {
    my $self = shift;
    my ($e,$X,$v) = @_;
    return unless $e->{window} == $X->root;
    $self->get_NET_CURRENT_DESKTOP;
    $self->rearrange_icons();
}

=item $desktop->B<event_handler_PropertyNotify_WIN_WORKAREA>(I<$e>,I<$X>,I<$v>)

L<XDE::X11(3pm)> event handler for changes to the C<_WIN_WORKAREA>
property on the root window.  When this property changes we may need to
adjust the area occupied by desktop icons by calling rearrange_icons().

=cut

sub event_handler_PropertyNotify_WIN_WORKAREA {
    my $self = shift;
    my ($e,$X,$v) = @_;
    return unless $e->{window} == $X->root;
    $self->get_WIN_WORKAREA;
    $self->rearrange_icons;
}

=item $desktop->B<event_handler_PropertyNotify_WIN_WORKSPACE>(I<$e>,I<$X>,I<$v>)

L<XDE::X11(3pm)> event handler for changes to the C<_WIN_WORKSPACE>
property of the root window.  When this property changes we may need to
adjust the area occupied by desktop icons by calling rearrange_icons().

=cut

sub event_handler_PropertyNotify_WIN_WORKSPACE {
    my $self = shift;
    my ($e,$X,$v) = @_;
    return unless $e->{window} == $X->root;
    $self->get_WIN_WORKSPACE;
    $self->rearrange_icons();
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
