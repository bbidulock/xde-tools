package XDE::Chooser;
use Glib qw(TRUE FALSE);
use Gtk2;
#use Net::DBus;
#use Net::DBus::GLib;
require XDE::Context;
use strict;
use warnings;

sub new {
    my ($type,$xde,$ops) = @_;
    die 'usage: XDE::Chooser->new($xde,$ops)'
	unless $xde and $xde->isa('XDE::Context') and
	       $ops and ref($ops) =~ /HASH/;
    my $self = bless {
	xde=>$xde,
	ops=>$ops,
    }, $type;
    foreach (qw(verbose lang charset language)) {
	$xde->{$_} = $ops->{$_} if $ops->{$_};
    }
    $xde->set_vendor($ops->{vendor}) if $ops->{vendor};
    return $self;
}

sub choose {
    my $self = shift;
    my $xde = $self->{xde};
    my %ops = %{$self->{ops}};
    my $xsessions = $self->{xsessions} = $xde->get_xsessions();
    my @xsessions = sort {$a->{Label} cmp $b->{Label}} values %$xsessions;
    $self->{sessions} = \@xsessions;

    if ($ops{verbose}) {
	foreach (@xsessions) {
	    print STDERR "----------------------\n";
	    print STDERR "Label: ",$_->{Label},"\n";
	    print STDERR "XSession: ",$_->{Name},"\n";
	    print STDERR "Comment: ",$_->{Comment},"\n";
	    print STDERR "Exec: ",$_->{Exec},"\n";
	    print STDERR "SessionManaged: ",$_->{SessionManaged},"\n";
	    print STDERR "File: ",$_->{file},"\n";
	    print STDERR "Icon: ",$_->{Icon},"\n";
	}
    }

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
	    if $ops{verrbose};
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
	return $self->makechoice();
    }
    else {
	print STDERR "Choosing $ops{choice}...\n"
	    if $ops{verbose};
	my $entry = $xsessions->{$ops{choice}}
	    if $xsessions->{$ops{choice}};
	return ($ops{choice},$entry) if wantarray;
	return $ops{choice};
    }
}

sub launch_session {
    my $self = shift;
    my ($label,$session) = @_;
    return unless $label and $session;
    my $xde = $self->{xde};
    my %ops = %{$self->{ops}};
    $xde->set_session($label);
    $xde->setenv;
    print STDERR "Environment would be: \n---------------------\n"
	if $ops{verbose};
    system("env | sort >&2") if $ops{verbose};
    print STDERR "Launching session for $label\n" if $ops{verbose};
    print STDERR "Launch command would be '$session->{Exec}'\n" if $ops{verbose};
    $ops{current} = "$label";
    if (open(my $fh,">",$xde->{XDE_CURRENT_FILE})) {
	$ops{current} = $label;
	print $fh "$ops{current}\n";
	close($fh);
    }
    if ($ops{setdflt}) {
	if (open(my $fh,">",$xde->{XDE_DEFAULT_FILE})) {
	    $ops{default} = $label;
	    print $fh "$ops{default}\n";
	    close($fh);
	}
    }
    exit(0);
    #Gtk2->main_quit;
}

sub makechoice {
    my $self = shift;
    my $xde = $self->{xde};
    my %ops = %{$self->{ops}};
    my $xsessions = $self->{xsessions};
    my @xsessions = @{$self->{sessions}};
    Gtk2->init;
    if ($xde->{XDG_ICON_PREPEND} or $xde->{XDG_ICON_APPEND})
    {
	my $theme = Gtk2::IconTheme->get_default;
	if ($xde->{XDG_ICON_PREPEND}) {
	    foreach (reverse split(/:/,$xde->{XDG_ICON_PREPEND})) {
		$theme->prepend_search_path($_);
	    }
	}
	if ($xde->{XDG_ICON_APPEND}) {
	    foreach (split(/:/,$xde->{XDG_ICON_APPEND})) {
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
    $w->set_border_width(15);
    $w->set_skip_pager_hint(TRUE);
    $w->set_skip_taskbar_hint(TRUE);
    $w->set_position('center-always');
    $w->signal_connect(delete_event=>sub{
	Gtk2->main_quit;
	Gtk2::EVENT_STOP;
    });
    $h = Gtk2::HBox->new(FALSE,5);
    $w->add($h);
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
	    'Glib::Boolean', # SessionManaged ?
    );
    my $view = Gtk2::TreeView->new($store);
    $view->set_rules_hint(TRUE);
    $view->set_search_column(1);
    $view->set_headers_visible(FALSE);
    $view->set_grid_lines('both');
    $sw->add($view);

    my ($rend,$col);

    $rend = Gtk2::CellRendererToggle->new;
    $col = Gtk2::TreeViewColumn->new_with_attributes('Managed',$rend,active=>5);
    $view->append_column($col);

    $rend = Gtk2::CellRendererPixbuf->new;
    $view->insert_column_with_data_func(-1,'Icon',$rend,sub{
            my ($col,$cell,$store,$iter) = @_;
            my ($iname) = $store->get($iter,0);
            $iname =~ s/\.(xpm|svg|png)$// if $iname;
            $iname = 'gtk-missing-image' unless $iname;
            my $theme = Gtk2::IconTheme->get_default;
            my $pixbuf = $theme->load_icon($iname,32,'generic-fallback');
            $pixbuf = $theme->load_icon('gtk-missing-image',32,'generic-fallback') unless $pixbuf;
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
	$i = Gtk2::Image->new_from_stock('gtk-quit','button');
	$b->set_image($i);
	$b->set_label('Logout');
    } else {
	$i = Gtk2::Image->new_from_stock('gtk-disconnect','button');
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
	    $ops{current} = 'logout';
	    Gtk2->main_quit;
    });

    $b = Gtk2::Button->new;
    $b->set_border_width(3);
    $b->set_image_position('left');
    $b->set_alignment(0.0,0.5);
    $i = Gtk2::Image->new_from_stock('gtk-save','button');
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
		if (open(my $fh,">",$xde->{XDE_DEFAULT_FILE})) {
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
    $i = Gtk2::Image->new_from_stock('gtk-revert-to-saved','button');
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
    $i = Gtk2::Image->new_from_stock('gtk-ok','button');
    $b->set_image($i);
    $b->set_label('Launch Session');
    $bb->pack_start($b,TRUE,TRUE,5); push @b, $b;
    $b->signal_connect(clicked=>sub{
	    my $selection = $view->get_selection;
	    my ($store,$iter) = $selection->get_selected;
	    if ($store) {
		my ($label) = $store->get($iter,4); # Label column
		$ops{current} = $label;
		Gtk2->main_quit;
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
		my ($label) = $store->get($iter,4); # Label column
		$ops{current} = $label;
		Gtk2->main_quit;
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
	my $managed = ($s->{SessionManaged} =~ /true/i) ? TRUE : FALSE;
        my $iter = $store->append;
        $store->set($iter,
                0, $iname,
                1, $name,
                2, $comment,
                3, $markup,
                4, $label,
		5, $managed,
        );
	if ($label eq $ops{choice} or
		(($ops{choice} eq 'choose' or $ops{choice} eq 'default') and
		 $label eq $ops{default})) {
	    $selection->select_iter($iter);
	    my $path = Gtk2::TreePath->new_from_string("$index");
	    $view->set_cursor_on_cell($path,$cursor,undef,FALSE);
	}
    }

    $w->set_default_size(-1,400);
    $w->show_all;

    $b[3]->grab_focus;

    # TODO: we should really set a timeout and if no user interaction
    #	    has occurred before the timeout, we should continue if we
    #	    have a viable default or choice.
    Gtk2->main;
    $w->destroy;
    my $entry = $xsessions->{$ops{current}}
	if $xsessions->{$ops{current}};
    return ($ops{current},$entry) if wantarray;
    return $ops{current};
}

1;
