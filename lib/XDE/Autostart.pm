package XDE::Autostart;
require XDE::Context;
use base qw(XDE::Context);
use POSIX qw(setsid getpid :sys_wait_h);
use Glib qw(TRUE FALSE);
use Gtk2;
use X11::XDE;
use strict;
use warnings;

=head1 NAME

XDE::Autostart - perform XDG autostart functions

=head1 SYNOPSIS

 my $xde = XDE::Autostart->new(%OVERRIDES);
 $xde->setup();
 $xde->run();

=head1 DESCRIPTION

The B<XDE::Autostart> module provides the ability to perform XDG
autostart functions for the X Desktop Environment.

=head1 METHODS

=over

=item $xde = XDE::Autostart->B<new>(I<%OVERRIDES>) => blessed HASHREF

=cut

sub new {
    my $self = XDE::Context::new(@_);
    $self->getenv() if $self;
    return $self;
}

sub old_new {
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

    # set the hostname and the pid for use in calculating
    # DESKTOP_STARTUP_ID strings.
    chomp($self->{hostname} = `hostname`);
    $self->{pid} = getpid();
    $self->{ts} = gettimeofday();

    $self->{X} = X11::Protocol->new();

    # intern some atoms for use with startup notification
    $self->{atom_begin} = Gtk2::Gdk::Atom->intern('_NET_STARTUP_INFO_BEGIN',FALSE);
    $self->{atom_more}  = Gtk2::Gdk::Atom->intern('_NET_STARTUP_INFO',FALSE);
    $self->{display} = Gtk2::Gdk::Display->get_default;
    $self->{screen} = $self->{display}->get_default_screen;
    $self->{root} = $self->{screen}->get_root_window;
    $self->{xid} = $self->{root}->XID;
    return $self;
}

=item $xde->B<newsnid>() => SCALAR

Obtains a new unique startup notification id.

=cut

sub newsnid {
    my $self = shift;
    my $now = gettimeofday();
    $now = $now + 1 if $self->{ts} eq $now;
    $self->{ts} = $now;
    return "$self->{hostname}+$self->{pid}+$self->{ts}";
}

=item $xde->B<send_sn>(I<$msg>)

Internal method to
send a packed startup notification message.

=cut

sub send_sn {
    my ($self,$msg) = @_;
    my $xid = $self->{xid};
    my $pad = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";
    my $xevent = Gtk2::Gdk::Event->new('client-event');
    $xevent->message_type($self->{atom_begin});
    $xevent->data_format(Gtk2::Gdk::CHARS);
    $xevent->data(substr($msg.$pad,0,20));
    Gtk2::Gdk::Event->send_client_message($xevent,$xid);
    $msg = length($msg) <= 20 ? '' : substr($msg,20);
    while (length($msg)) {
	$xevent = Gtk2::Gdk::Event->new('client-event');
	$xevent->message_type($self->{atom_more});
	$xevent->data_format(Gtk2::Gdk::CHARS);
	$xevent->data(substr($msg.$pad,0,20));
	Gtk2::Gdk::Event->send_client_message($xevent,$xid);
	$msg = length($msg) <= 20 ? '' : substr($msg,20);
    }
}

=item B<sn_quote>($txt) => $quoted_txt

Internal method to
quote parameter C<$txt> according to XDG startup notification rules.

=cut

sub sn_quote {
    my $txt = shift;
    $txt =~ s{\\}{\\\\}g if $txt =~ m{\\};
    $txt =~ s{"}{\\"}g   if $txt =~ m{"};
    $txt =~ "\"$txt\""   if $txt =~ m{ };
    return $txt;
}

=item $xde->B<send_sn_new>(I<$id>,{I<%msg_hash>})

Internal method to
send a startup notification C<new> message.  C<%msg_hash> contains a
hash of the valid startup notification fields.  The C<new> message
requires the C<ID>, C<NAME> and C<SCREEN> fields, and may optionally
contain the C<BIN>, C<ICON>, C<DESKTOP>, C<TIMESTAMP>, C<DESCRIPTION>,
C<WMCLASS> and C<SILENT> fields.

=cut

sub send_sn_new {
    my ($self,$id,$msg) = @_;
    my $txt = 'new:';
    $txt .= ' ID='.sn_quote($id);
    $txt .= ' NAME='.sn_quote($msg->{NAME});
    $txt .= ' SCREEN='.sn_quote($msg->{SCREEN});
    foreach (qw(BIN ICON DESKTOP TIMESTAMP DESCRIPTION WMCLASS SILENT)) {
	$txt .= " $_=".sn_quote($msg->{$_}) if $msg->{$_};
    }
    $txt .= "\0";
    $self->send_sn($txt);
}

=item $xde->B<send_sn_change>(I<$id>,{I<%msg_hash>})

Internal method to
send a startup notification C<change> message.  C<%msg_hash> contains a
hash of the valid startup notification fields.  The C<change> message
requires the C<ID> field, and may optionally contain the C<NAME>,
C<SCREEN>, C<BIN>, C<ICON>, C<DESKTOP>, C<TIMESTAMP>, C<DESCRIPTION>,
C<WMCLASS> and C<SILENT> fields.

=cut

sub send_sn_change {
    my ($self,$id,$msg) = @_;
    my $txt = 'change:';
    $txt .= ' ID='.sn_quote($id);
    foreach (qw(NAME SCREEN BIN ICON DESKTOP TIMESTAMP DESCRIPTION WMCLASS SILENT)) {
	$txt .= " $_=".sn_quote($msg->{$_}) if $msg->{$_};
    }
    $txt .= "\0";
    $self->send_sn($txt);
}

=item $xde->B<send_sn_remove>(I<$id>)

Internal method to
send a startup notification C<remove> message.  C<$id> is the startup
notification identifier.

=cut

sub send_sn_remove {
    my ($self,$id) = @_;
    my $txt = 'remove:';
    $txt .= ' ID='.sn_quote($id);
    $txt .= "\0";
    $self->send_sn($txt);
}

sub autostart {
    my $self = shift;
    my $xde = $self->{xde};
    my %ops = %{$self->{ops}};
    my $autostart = $self->{autostart} = $xde->get_autostart();
    my @autostart = sort {$a->{Label} cmp $b->{Label}} values %$autostart;
    $self->{tasks} = \@autostart;

    if ($ops{verbose}) {
	foreach (@autostart) {
	    print STDERR "----------------------\n";
	    print STDERR "Label: ",$_->{Label},"\n";
	    print STDERR "Autostart: ",$_->{Name},"\n";
	    print STDERR "Comment: ",$_->{Comment},"\n";
	    print STDERR "Exec: ",$_->{Exec},"\n";
	    print STDERR "TryExec: ",$_->{TryExec},"\n";
	    print STDERR "File: ",$_->{file},"\n";
	    print STDERR "Icon: ",$_->{Icon},"\n";
	    print STDERR "Disable: ",$_->{'X-Disable'},"\n"
		if $_->{'X-Disable'};
	    print STDERR "Reason: ",$_->{'X-Disable-Reason'},"\n"
		if $_->{'X-Disable-Reason'};
	}
    }
}

sub do_startup {
    my $self = shift;
    my $xde = $self->{xde};
    my %ops = %{$self->{ops}};
    my $autostart = $self->{autostart};
    my @tasks = @{$self->{tasks}};
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
    my ($w,$h,$v,$f,$s,$sw,$t);
    $w = Gtk2::Window->new('toplevel');
    $w->set_wmclass('xde-session','Xdg-session');
    $w->set_title('Autostarting Applications');
    $w->set_gravity('center');
    $w->set_type_hint('splashscreen');
    $w->set_border_width(20);
    $w->set_skip_pager_hint(TRUE);
    $w->set_skip_taskbar_hint(TRUE);
    $w->set_position('center-always');
    $w->signal_connect(delete_event=>\&Gtk2::Widget::hide_on_delete);
    my $cols = 7;
    $h = Gtk2::HBox->new(FALSE,5);
    $w->add($h);
    $v = Gtk2::VBox->new(FALSE,5);
    if ($ops{banner}) {
	$f = Gtk2::Frame->new;
	$f->set_shadow_type('etched-in');
	$v->pack_start($f,FALSE,FALSE,0);
	$h = Gtk2::HBox->new(FALSE,5);
	$h->set_border_width(10);
	$f->add($h);
	$s = Gtk2::Image->new_from_file($ops{banner});
	$h->add($s);
    }
    $f = Gtk2::Frame->new;
    $f->set_shadow_type('etched-in');
    $v->pack_start($f,TRUE,TRUE,0);
    $h = Gtk2::HBox->new(FALSE,5);
    $h->set_border_width(10);
    $f->add($h);
    $sw = Gtk2::ScrolledWindow->new;
    $sw->set_shadow_type('etched-in');
    $sw->set_policy('never','automatic');
    $sw->set_border_width(3);
    $h->pack_start($sw,TRUE,TRUE,0);
    $t = Gtk2::Table->new(1,$cols,TRUE);
    $t->set_col_spacings(1);
    $t->set_row_spacings(1);
    $t->set_homogeneous(TRUE);
    $t->set_size_request(750,-1);
    $sw->add_with_viewport($t);
    $w->set_default_size(-1,600);
    $w->show_all;
    $w->show_now;

    $self->{table} = $t;
    $self->{row} = 0;
    $self->{col} = 0;
    $self->{cols} = $cols;

    my ($row,$col) = (0,0);
    foreach my $task (@tasks) {
	unless ($task->{'X-After-WM'} and
		$task->{'X-After-WM'} =~ m{true|yes|1}i) {
	    $task = XDE::Autostart::Task->new($self,$task);
	    unless ($task->{'X-Disable'} and
		    $task->{'X-Disable'} =~ m{true|yes|1}i) {
		push @{$self->{running}}, $task;
	    }
	}
    }
    foreach my $task (@tasks) {
	if ($task->{'X-After-WM'} and
	    $task->{'X-After-WM'} =~ m{true|yes|1}i) {
	    $task = XDE::Autostart::Task->new($self,$task);
	    unless ($task->{'X-Disable'} and
		    $task->{'X-Disable'} =~ m{true|yes|1}i) {
		push @{$self->{running}}, $task;
	    }
	}
    }

}

=back

=cut

1;

# vim: sw=4 tw=72
