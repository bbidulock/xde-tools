package XDE::Chooser;
use base qw(XDE::Gtk2);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDG::Chooser -- choose an X Desktop Environment or Window Manager session

=head1 SYNOPSIS

 use XDE::Chooser;

 my $xde = XDE::Chooser->new(%OVERRIDES,ops=>\%ops);

 $xde->getenv();
 my ($result,$entry) = $xde->choose(%ops);
 exit(0) if $result eq 'logout';
 $xde->set_session($result);
 $xde->setenv();

=head1 METHODS

=over

=item $xde = XDE::Chooser->B<new>(I<%OVERRIDES>,ops=>\I<%ops>) => blessed HASHREF

Creates a new instance of an XDE::Chooser object and returns a blessed
reference.  The XDE::Chooser module uses the L<XDE::Context(3pm)> module
as a base, so the C<%OVERRIDES> are simply passed to the
L<XDE::Context(3pm)> module.
When a options hash, I<%ops>, is passed to the method, it is initialized
with default option values.

XDE::Chooser recognizes the following options:

=over

=item verbose => $boolean

Prints diagnostic information to standard error during operation.

=item banner => $filename

The filename of the branding banner to include in the display.  Selected
from the I<vendor> option or XDG environment variables when not
specified.

=item noask => $boolean

Do not ask the user to choose when a viable default is available.  Do
not ask the user whether they want to make a new choice the default when
a selection different from the default is specified.  Defaults to
asking.

=item charset => $charset

The character set to use when displaying desktop entries.  Defaults to
the character set of the current locale.

=item language => $language

The language to use when displaying desktop entries.  Defaults to the
language of the current locale.

=item setdflt => $boolean

Whether to set the selection passed in I<choice> as the new default
automatically.  Defaults to false.

=item default => $xsession_label

The user's current default selection.  Defaults to the value obtained
from the user's F<$XDG_CONFIG_HOME/xde/default> file; or when the file
does not exist, any F<$XDG_CONFIG_DIRS/xde/default> file; or when that
does not exist, a null string.

=item current => $xsession_label

The users's current selection.  This is the last session that the user
launched and defaults to that obtained from the user's
F<$XDG_CONFIG_HOME/xde/current> file; or when the file does not exist,
the null string.

=item choice => $xsession_label

The choice that was passed as an argument from an F<.xinitrc> file.
This is the case-insensitive label corresponding to the desktop session
(window manager): a F<.desktop> file must exist in the
F<@XDG_DATA_DIRS/xsessions> directory with the same case-insensitive
name (e.g. F<Fluxbox.desktop>).  It can also be one of three special
values:

=over

=item C<choose>

Choose the session to launch regardless of the C<default> and C<current>
settings.  This will alway launch a session chooser window.

=item C<default>

Select the default session that was last set by the user if one exists.
Otherwise, this has the same effect as C<choose>.

=item C<current>

Select the session that was last launched by the user if one exists.
Otherwise, this has the same effect as C<choose>.

=back

=item vendor => $vendor

Specifies the vendor string for branding.  This affects default banner
selection and the settings of B<$XDG_MENU_PREFIX>.  Defaults to a null
string or the value obtained from the environment variables
B<$XDG_VENDOR_ID> or B<$XDG_MENU_PREFIX> (minus the trailing dash).

=back

=cut

sub new {
    return XDE::Gtk2::new(@_);
}

=item $xde->B<defaults>() => $xde

Internal method that establishes only defaults specific to this module
upon instance creation.  This method does not invoke the superior
(inherited method) as does the B<default> method.  Reads the C<default>
string from the first F<@XDG_CONFIG_DIRS/xde/default> file found.  Reads
the C<current> string from the F<$XDG_CONFIG_HOME/xde/current> file if
it exists.

=cut

sub defaults {
    my $self = shift;
    unless ($self->{ops}{default}) {
	my $default = '';
	foreach my $fn (map{"$_/xde/default"} $self->XDG_CONFIG_ARRAY) {
	    if (-f $fn) {
		if (open(my $fh,"<",$fn)) {
		    while (<$fh>) {
			$default = $1 if m{(\S+)};
			last;
		    }
		    close($fh);
		    last if $default;
		}
	    }
	}
	$self->{ops}{default} = $default unless $self->{ops}{default};
    }
    unless ($self->{ops}{current}) {
	my $current = '';
	my $fn = "$self->{XDG_CONFIG_HOME}/xde/current";
	if (-f $fn) {
		if (open(my $fh,"<",$fn)) {
		    while (<$fh>) {
			$current = $1 if m{(\S+)};
			last;
		    }
		    close($fh);
		}
	}
	$self->{ops}{current} = $current unless $self->{ops}{current};
    }
    return $self;
}

=item $xde->B<choose>() => (I<$choice>,I<$entry>)

Performs the actions necessary to choose the desktop session.  This
includes displaying a selection window and allowing the user to change
the default and current selections.  The selection returns a I<$choice>
and, in an list context, an I<$entry>.  When I<$choice> is C<logout>,
I<$entry> is undefined; otherwise, I<$choice> is the label of the chosen
(current) desktop session and I<$entry> is the xsessions desktop entry
associated with that session.

=cut

sub choose {
    my $self = shift;
    my %ops = %{$self->{ops}};
    my $xsessions = $self->get_xsessions();
    my @xsessions = sort {$a->{Label} cmp $b->{Label}} values %$xsessions;
    $self->{sessions} = \@xsessions;
    $self->{xsessions} = $xsessions;

    if ($ops{verbose}) {
	foreach (@xsessions) {
	    print STDERR "----------------------\n";
	    foreach my $tag (qw(Label Name Comment Exec TryExec SessionManaged X-XDE-Managed Icon file)) {
		print STDERR "$tag: ";
		if (defined $_->{$tag}) {
		    print STDERR $_->{$tag};
		} else {
		    print STDERR "(undef)";
		}
		print STDERR "\n";
	    }
	}
    }

    $ops{choice} = "\L$ops{choice}\E" if $ops{choice};
    $ops{choice} = $ops{default} if $ops{choice} eq 'default' and $ops{default};
    $ops{choice} = $ops{current} if $ops{choice} eq 'current' and $ops{current};
    $ops{choice} = 'default' unless $ops{choice};
    $ops{choice} = $ops{default} if $ops{choice} eq 'default' and $ops{default};
    $ops{choice} = $ops{current} if $ops{choice} eq 'current' and $ops{current};

    if ($ops{default} and not exists $xsessions->{$ops{default}}) {
	print STDERR "Default $ops{default} is not available!\n"
	    if $ops{verbose};
	$ops{choice} = 'choose' if $ops{choice} eq $ops{default};
    }

    if ($ops{choice} eq 'default' and not $ops{default}) {
	print STDERR "Default is chosen but there is no default.\n"
	    if $ops{verbose};
	$ops{choice} = 'choose';
    }

    if ($ops{choice} ne 'choose' and not exists $xsessions->{$ops{choice}}) {
	print STDERR "Choice $ops{choice} is not available.\n"
	    if $ops{verbose};
	$ops{choice} = 'choose';
    }

    if ($ops{choice} eq 'choose') {
	$ops{prompt} = 1;
    }

    print STDERR "The default was $ops{default}: "
	if $ops{verbose} and $ops{default};
    if ($ops{prompt}) {
	print STDERR "Choosing $ops{choice}...\n"
	    if $ops{verbose};
	return ($self->make_login_choice());
    }
    else {
	print STDERR "Choosing $ops{choice}...\n"
	    if $ops{verbose};
	my $entry = $xsessions->{$ops{choice}}
	    if $xsessions->{$ops{choice}};
	return ($ops{choice},$entry,$ops{managed});
    }
}

=item $xde->B<create_session>(I<$label>,I<$session>)

Launch the session specified by the I<$label> argument with the
xsessions desktop file passed in the I<$session> argument.  This method
writes the selection and default to the users's current and default
files in F<$XDG_CONFIG_HOME/xde/current> and
F<$XDG_CONFIG_HOME/xde/default>, sets the option variables
C<$xde-E<gt>{ops}{current}> and C<$xde-E<gt>{ops}{default}> and quits
the main loop.

=cut

sub create_session {
    my $self = shift;
    my ($label,$session) = @_;
    unless ($label and $session) {
	print STDERR "\$label and \$session must be specified: $label, $session\n";
	return;
    }
    my %ops = %{$self->{ops}};
    $self->set_session($label);
    $self->setenv;
    print STDERR "Environment would be: \n---------------------\n"
	if $ops{verbose};
    system("env | sort >&2") if $ops{verbose};
    print STDERR "Launching session for $label\n" if $ops{verbose};
    print STDERR "Launch command would be '$session->{Exec}'\n" if $ops{verbose};
    $ops{current} = "$label";
    if (open(my $fh,">",$self->{XDE_CURRENT_FILE})) {
	$ops{current} = $label;
	print $fh "$ops{current}\n";
	close($fh);
    }
    if ($ops{setdflt}) {
	if (open(my $fh,">",$self->{XDE_DEFAULT_FILE})) {
	    $ops{default} = $label;
	    print $fh "$ops{default}\n";
	    close($fh);
	}
    }
}

=item $xde->B<make_login_choice>() => $current

Internal method to launch a window to make the login choice.  This is
the main chooser window.  The scalar label returned is the label of the
current session choice.  This is normally invoked by calling the
B<choose> method, above.

=cut

sub make_login_choice {
    my $self = shift;
    my %ops = %{$self->{ops}};
    my $xsessions = $self->{xsessions};
    my @xsessions = @{$self->{sessions}};
    Gtk2->init;
    #system("xsetroot -solid \"#223377\" -cursor_name left_ptr");
    system("xsetroot -cursor_name left_ptr");
    if ($self->{XDG_ICON_PREPEND} or $self->{XDG_ICON_APPEND})
    {
	my $theme = Gtk2::IconTheme->get_default;
	if ($self->{XDG_ICON_PREPEND}) {
	    foreach (reverse split(/:/,$self->{XDG_ICON_PREPEND})) {
		$theme->prepend_search_path($_);
	    }
	}
	if ($self->{XDG_ICON_APPEND}) {
	    foreach (split(/:/,$self->{XDG_ICON_APPEND})) {
		$theme->append_search_path($_);
	    }
	}
    }
    my ($w,$h,$f,$v,$s,$l,$sw,$bb);
    $w = Gtk2::Window->new('toplevel');
    $w->set_wmclass('xde-chooser','Xdg-chooser');
    $w->set_title('Window Manager Selection');
    $w->set_gravity('center');
    $w->set_type_hint('dialog');
    $w->set_icon_name('xdm');
#   $w->set_border_width(15);
    $w->set_skip_pager_hint(TRUE);
    $w->set_skip_taskbar_hint(TRUE);
    $w->set_position('center-always');
# ====================
    $w->fullscreen;
    $w->set_decorated(FALSE);
    my $screen = Gtk2::Gdk::Screen->get_default;
    my ($width,$height) = ($screen->get_width,$screen->get_height);
    $w->set_default_size($width,$height);
    $w->set_app_paintable(TRUE);
    my $pixbuf = Gtk2::Gdk::Pixbuf->get_from_drawable(
	    Gtk2::Gdk->get_default_root_window,
	    undef, 0, 0, 0, 0, $width, $height);
    my $a = Gtk2::Alignment->new(0.5,0.5,0.0,0.0);
    $w->add($a);
    my $e = Gtk2::EventBox->new;
    $a->add($e);
    $e->set_size_request(-1,400);
    $w->signal_connect(expose_event=>sub{
	    my ($w,$e,$p) = @_;
	    my $cr = Gtk2::Gdk::Cairo::Context->create($w->window);
	    $cr->set_source_pixbuf($p,0,0);
	    $cr->paint;
	    my $color;
#	    $color = Gtk2::Gdk::Color->new(0x72*257,0x9f*257,0xcf*257,0);
#	    $cr->set_source_color($color);
#	    $cr->paint_with_alpha(0.6);
	    $color = Gtk2::Gdk::Color->new(0,0,0,0);
	    $cr->set_source_color($color);
	    $cr->paint_with_alpha(0.7);
    },$pixbuf);
    $v = Gtk2::VBox->new(FALSE,0);
    $v->set_border_width(15);
    $e->add($v);
# ====================
    $w->signal_connect(delete_event=>sub{
	$self->main_quit('logout');
	Gtk2::EVENT_STOP;
    });
    $h = Gtk2::HBox->new(FALSE,5);
    $v->add($h);
    if ($ops{banner}) {
        $f = Gtk2::Frame->new;
        $f->set_shadow_type('etched-in');
        $h->pack_start($f,FALSE,FALSE,0);
        $v = Gtk2::VBox->new(FALSE,5);
        $v->set_border_width(10);
        $f->add($v);
        $s = Gtk2::Image->new_from_file($ops{banner});
        $v->add($s);
    }
    $f = Gtk2::Frame->new;
    $f->set_shadow_type('etched-in');
    $h->pack_start($f,TRUE,TRUE,0);
    $v = Gtk2::VBox->new(FALSE,5);
    $v->set_border_width(10);
    $f->add($v);
    $sw = Gtk2::ScrolledWindow->new;
    $sw->set_shadow_type('etched-in');
    $sw->set_policy('never','automatic');
    $sw->set_border_width(3);
    $v->pack_start($sw,TRUE,TRUE,0);
    $bb = Gtk2::HButtonBox->new;
    $bb->set_spacing_default(5);
    $bb->set_layout_default('end');
    $v->pack_end($bb,FALSE,TRUE,0);

    my $store = Gtk2::ListStore->new(
            'Glib::String',  # pixbuf
            'Glib::String',  # Name
            'Glib::String',  # Comment
            'Glib::String',  # Name and Comment Markup
            'Glib::String',  # Label
	    'Glib::Boolean', # SessionManaged ? X-XDE-Managed ?
	    'Glib::Boolean', # X-XDE-Managed original setting
    );
    my $view = Gtk2::TreeView->new($store);
    $view->set_rules_hint(TRUE);
    $view->set_search_column(1);
    $view->set_headers_visible(FALSE);
    $view->set_grid_lines('both');
    $sw->add($view);

    my ($rend,$col);

    $rend = Gtk2::CellRendererToggle->new;
    $rend->set_activatable(TRUE);
    $rend->signal_connect(toggled=>sub{
	    my ($toggle,$index) = @_;
	    print STDERR "Toggled! ", join(',',@_), "\n" if $self->{ops}{verbose};
	    my $iter = $store->get_iter_from_string($index);
	    my ($user) = $store->get($iter,5);
	    my ($orig) = $store->get($iter,6);
	    if ($orig) {
		$user = $user ? FALSE : TRUE;
		$store->set($iter,5,$user);
	    }
	    });
    $col = Gtk2::TreeViewColumn->new_with_attributes('Managed',$rend,active=>5);
    $view->append_column($col);

    $rend = Gtk2::CellRendererPixbuf->new;
    $view->insert_column_with_data_func(-1,'Icon',$rend,sub{
            my ($col,$cell,$store,$iter) = @_;
            my ($iname) = $store->get($iter,0);
            $iname =~ s/\.(xpm|svg|png)$// if $iname;
	    $iname = 'preferences-system-windows' unless $iname;
            my $theme = Gtk2::IconTheme->get_default;
	    my $pixbuf;
	    if ($theme->has_icon($iname)) {
		$pixbuf = $theme->load_icon($iname,32,['generic-fallback','use-builtin']);
	    } else {
		$iname = 'preferences-system-windows';
		if ($theme->has_icon($iname)) {
		    $pixbuf = $theme->load_icon($iname,32,['generic-fallback','use-builtin']);
		} else {
		    my $image = Gtk2::Image->new_from_stock('gtk-missing-image','large-toolbar');
		    $pixbuf = $image->render_icon('gtk-missing-image','large-toolbar');
		}
	    }
            $cell->set(pixbuf=>$pixbuf);
    });

    $rend = Gtk2::CellRendererText->new;
    $col = Gtk2::TreeViewColumn->new_with_attributes(
            'Window Manager',$rend,markup=>3);
    $col->set_sort_column_id(1);
    $view->append_column($col);
    my $cursor = $col;

    my (@b,$b,$i);

    $b = Gtk2::Button->new;
    $b->set_border_width(3);
    $b->set_image_position('left');
    $b->set_alignment(0.0,0.5);
    if ($ENV{DISPLAY} =~ /^:/) {
	$i = $self->get_icon('button','gtk-quit');
	$b->set_image($i);
	$b->set_label('Logout');
    } else {
	$i = $self->get_icon('button','gtk-disconnect');
	$b->set_image($i);
	$b->set_label('Disconnect');
    }
    $bb->pack_start($b,TRUE,TRUE,5); push @b, $b;
    $b->signal_connect(clicked=>sub{
	    my $selection = $view->get_selection;
	    my ($store,$iter) = $selection->get_selected;
	    if ($store) {
		my ($label) = $store->get($iter,4); # Label column
		print STDERR "Label selected $label\n"
		    if $ops{verbose};
	    }
	    $self->{ops}{current} = 'logout';
	    $self->{ops}{managed} = undef;
	    $self->main_quit('logout');
    });

    $b = Gtk2::Button->new;
    $b->set_border_width(3);
    $b->set_image_position('left');
    $b->set_alignment(0.0,0.5);
    $i = $self->get_icon('button','gtk-save');
    $b->set_image($i);
    $b->set_label('Make Default');
    $bb->pack_start($b,TRUE,TRUE,5); push @b, $b;
    $b->signal_connect(clicked=>sub{
	    my $selection = $view->get_selection;
	    my ($store,$iter) = $selection->get_selected;
	    if ($store) {
		my ($label) = $store->get($iter,4); # Label column
		print STDERR "Label selected $label\n"
		    if $ops{verbose};
		if (open(my $fh,">",$self->{XDE_DEFAULT_FILE})) {
		    $ops{default} = $label;
		    print $fh "$ops{default}\n";
		    close($fh);
		    $ops{default} = '';
		    $b[1]->set_sensitive(FALSE);
		    $b[2]->set_sensitive(FALSE);
		    $b[3]->set_sensitive(TRUE);
		}
	    }
	    return Gtk2::EVENT_PROPAGATE;
    });

    $b = Gtk2::Button->new;
    $b->set_border_width(3);
    $b->set_image_position('left');
    $b->set_alignment(0.0,0.5);
    $i = $self->get_icon('button','gtk-revert-to-saved');
    $b->set_image($i);
    $b->set_label('Select Default');
    $bb->pack_start($b,TRUE,TRUE,5); push @b, $b;
    $b->signal_connect(clicked=>sub{
	    my $selection = $view->get_selection;
	    if ($ops{default}) {
		my $store = $view->get_model;
		my $index = $xsessions->{$ops{default}}{index};
		my $iter = $store->iter_nth_child(undef,$index);
		$selection->select_iter($iter);
		my $path = Gtk2::TreePath->new_from_string("$index");
		$view->set_cursor_on_cell($path,$cursor,undef,FALSE);
	    } else {
		$selection->unselect_all;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    });

    $b = Gtk2::Button->new;
    $b->set_flags(['can-default','has-default']);
    $b->set_border_width(3);
    $b->set_image_position('left');
    $b->set_alignment(0.0,0.5);
    $i = $self->get_icon('button','gtk-ok');
    $b->set_image($i);
    $b->set_label('Launch Session');
    $bb->pack_start($b,TRUE,TRUE,5); push @b, $b;
    $b->signal_connect(clicked=>sub{
	    my $selection = $view->get_selection;
	    my ($store,$iter) = $selection->get_selected;
	    if ($store) {
		my ($label)  = $store->get($iter,4); # Label column
		my ($manage) = $store->get($iter,5); # managed column
		$self->{ops}{current} = $label;
		$self->{ops}{managed} = $manage;
		$self->main_quit($label);
	    }
	    return Gtk2::EVENT_PROPAGATE;
    });

    my $selection = $view->get_selection;
    $selection->set_mode('single');
    $selection->signal_connect(changed=>sub{
            my $selection = shift;
            my ($store,$iter) = $selection->get_selected;
	    if ($store) {
		my ($label) = $store->get($iter,4); # Label column
		my $session = $xsessions->{$label};
		print STDERR "Label selected was: $label\n" if $ops{verbose};
		if ($label eq $ops{default}) {
		    $b[1]->set_sensitive(FALSE);
		    $b[2]->set_sensitive(FALSE);
		    $b[3]->set_sensitive(TRUE);
		} else {
		    $b[1]->set_sensitive(TRUE);
		    $b[2]->set_sensitive(TRUE);
		    $b[3]->set_sensitive(TRUE);
		}
	    } else {
		$b[1]->set_sensitive(FALSE);
		$b[2]->set_sensitive(TRUE);
		$b[3]->set_sensitive(FALSE);
	    }
            return Gtk2::EVENT_PROPAGATE;
    });
    $view->signal_connect(row_activated=>sub{
            my ($view,$path,$column) = @_;
            my $selection = $view->get_selection;
            my ($store,$iter) = $selection->get_selected;
	    if ($store) {
		my ($label)  = $store->get($iter,4); # Label column
		my ($manage) = $store->get($iter,5); # managed column
		$self->{ops}{current} = $label;
		$self->{ops}{managed} = $manage;
		$self->main_quit($label);
	    }
            return Gtk2::EVENT_PROPAGATE;
    });
    $view->signal_connect(button_press_event=>sub{
            my ($view,$event) = @_;
            my ($path,$column) = $view->get_path_at_pos($event->x,$event->y);
            my $selection = $view->get_selection;
            $selection->select_path($path);
            my ($store,$iter) = $selection->get_selected;
	    if ($store) {
		my ($label) = $store->get($iter,4); # Label column
		my $session = $xsessions->{$label};
		print STDERR "Label clicked was: $label\n" if $ops{verbose};
	    }
            return Gtk2::EVENT_PROPAGATE;
    });

    my $index = 0;
    foreach my $s (@xsessions) {
	$s->{index} = $index; $index = $index + 1;
        my $iname = $s->{Icon};
        my $name = $s->{Name};
        my $comment = $s->{Comment};
        my $markup = "<b>$name</b>\n$comment";
        my $label = $s->{Label};
	my $managed = ($s->{'X-XDE-Managed'} and ($s->{'X-XDE-Managed'} =~ /true/i)) ? TRUE : FALSE;
        my $iter = $store->append;
        $store->set($iter,
                0, $iname,
                1, $name,
                2, $comment,
                3, $markup,
                4, $label,
		5, $managed,
		6, $managed,
        );
	if ($label eq $ops{choice} or
		(($ops{choice} eq 'choose' or $ops{choice} eq 'default') and
		 $label eq $ops{default})) {
	    $selection->select_iter($iter);
	    my $path = Gtk2::TreePath->new_from_string("$index");
	    $view->set_cursor_on_cell($path,$cursor,undef,FALSE);
	}
    }

#   $w->set_default_size(-1,400);
    $w->show_all;

    $b[3]->grab_focus;

    # TODO: we should really set a timeout and if no user interaction
    #	    has occurred before the timeout, we should continue if we
    #	    have a viable default or choice.
    $ops{current} = $self->main;
    $w->destroy;
    my $entry = $xsessions->{$ops{current}} if $ops{current} ne 'logout';
    my $managed = $self->{ops}{managed};
    if ($ops{current} ne 'logout' and not $entry) {
	print STDERR "Available xsessions are: ", join(',',keys %$xsessions), "\n";
	die "What happenned to entry for $ops{current}?";
    }
    return ($ops{current},$entry,$managed);
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72
