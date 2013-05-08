package XDE::Autostart::Task;
require XDE::Autostart;
require XDE::Autostart::Command;
use POSIX qw(setsid getpid :sys_wait_h);
use base qw(XDE::Autostart::Command);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Autostart::Task - an instance of an autostart task

=head1 SYNOPSIS

 require XDE::Context;
 require XDE::Autostart;
 require XDE::Autostart::Task;

 my $xde = XDE::Context->new();
 $xde->getenv();
 $xde->setenv();
 my $autostart = XDE::Autostart->new($xde,{});
 my $task = XDE::Autostart::Task->new($autostart,$entry);
 $task->startup($autostart);
 $task->shudown($autostart);

=head1 DESCRIPTION

The B<XDE::Autostart::Task> module provides an object-oriented approach
to XDG autostart.  Unfortunately, XDG autostart has a number of basic
deficiencies:

=over

=item 1.

There is no (standard) way of specifying what needs to be started before
a window manager and what needs to be started after a window manager.

=item 2.

There is no (standard) way of specifying the order of startup.

=back

Nevertheless, we separate XDG autostart tasks into three classes:

=over

=item 1.

Entries that are started before the window manager.  These are
entries that do not depend upon the window manager being present.  This
is the default when it cannot be determined into which class the entry
belongs.

=item 2.

The window manager itself.

=item 3.

Entries that need to be started after the window manager.  This is
normally so that the window manager will not mess with these
applications during its startup.  An example is DockApps, TrayIcon, and
desktop applications such as L<idesk(1)>.  XDE determines these by
looking in the C<Category> field of the entry.  DockApps and TrayIcons
are started after the window manager.  Any entries with the field
C<X-After-WM> set to C<true> will be started after the window manager
has confirmed to be started.

=back

=head1 METHODS

=over

=item $task = XDE::Autostart::Task->B<new>(I<$autostart>,I<$entry>)

Creates a new autostart task entry using the I<$entry> hash.  The
I<$entry> has is a simple hash that has a key-value pair for each of the
desktop entry fields that were read from the F<.desktop> file.  If the
entry passed in is of I<Type> C<XSession> instead of C<Application>, it
will be treated as the window manager.  If it has the field
I<X-After-WM> set to C<true>, it will be started after the window
manager, otherwise it will be started before the window manager.

=cut

sub new {
    my ($type,$owner,$entry) = @_;
    my $self = bless $entry, $type;
    $self->{cmd} = $self->{Exec};
    # clean up the icon
    my ($name,$icon,$b,$t,$c,$r);
    $name = $self->{Icon};
    $name = 'gtk-execute' unless $name;
    if ($name =~ m{^/}) {
	my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_size($name,48,48);
	if ($pixbuf) {
	    $icon = Gtk2::Image->new_from_pixbuf($pixbuf);
	}
    }
    unless ($icon) {
	$name =~ s{^.*/}{};
	$name =~ s{\.(xpm|png|svg|tif|tiff|jpg)$}{};
	$name = 'gtk-execute' unless $name;
	$icon = Gtk2::Image->new_from_icon_name($name,'dialog');
    }
    $icon = Gtk2::Image->new_from_icon_name('gtk-execute','dialog') unless $icon;
    $self->{icon} = $icon;
    $b = Gtk2::Button->new;
    $b->set_image_position('top');
    $b->set_image($icon);
     #$b->set_label($self->{Name});
    $b->set_tooltip_text($self->{Name});
    $t = $owner->{table};
    $r = $owner->{row};
    $c = $owner->{col};
    $t->attach_defaults($b,$c,$c+1,$r,$r+1);
    $b->set_sensitive(FALSE);
    $b->show_all;
    $b->show_now;
    $c = $c+1;
    if ($c > $owner->{cols}) {
	$c = 0; $r = $r+1;
	$owner->{row} = $r;
    }
    $owner->{col} = $c;
    unless ($self->{'X-Disable'} and $self->{'X-Disable'} =~ m{true|yes|1}i) {
	$b->set_sensitive(TRUE);
	$b->show_now;
    }
    Gtk2->main_iteration while Gtk2->events_pending;
    return $self;
}

=item $task->B<startup>(I<$autostart>)

Starts up and autostart task under the task owner provided in the
I<$autostart> argument.

This method is a little more complex than that provided by the base
class XDE::Autostart::Command.  This is because we have more information
and can perform proper startup notification.  We can also monitor for
the appearance of a window of a given name or class.  We can also
provide a range of information on task failure and provide the user with
the option to restart the task via notification.

=cut

sub startup {
    my ($self,$owner) = @_;
    my $id = $self->{DESKTOP_STARTUP_ID} = $owner->newsnid();
    $owner->send_sn_new($id,{
	ID=>$id,
	NAME=>$self->{Name},
	SCREEN=>$owner->{screen}->get_number,
	BIN=>$self->{TryExec},
	ICON=>$self->{Icon},
	DESKTOP=>0,
	TIMESTAMP=>Gtk2::Gdk::X11->get_server_time($owner->{root}),
	DESCRIPTION=>$self->{Comment},
	WMCLASS=>$self->{StartupWMClass},
	SILENT=>(($self->{StartupNotify} and $self->{StartupNotify} =~ m{true|yes|1}i) or $self->{StartupWMClass}) ? 0 : 1,
    });
    $ENV{DESKTOP_STARTUP_ID} = $id;
    my $pid = fork();
    unless (defined $pid) {
	warn "cannot fork!";
	return;
    }
    if ($pid) {
	# we are the parent
	delete $ENV{DESKTOP_STARTUP_ID};
    }
    else {
	# we are the child
	$ENV{DESKTOP_STARTUP_ID} = $id;
    }
}

=item $task->B<shutdown>(I<$autostart>)

=cut

=item $task->B<exited>(I<$pid>,I<$waitstatus>,I<$autostart>)

=cut

sub exited {
    my ($self,$pid,$waitstatus,$autostart) = @_;
}

=back

=cut

1;

