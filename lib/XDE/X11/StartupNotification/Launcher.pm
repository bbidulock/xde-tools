package XDE::X11::StartupNotification::Launcher;
use base qw(XDE::X11::StartupNotification::Sequence);
use XDE::X11::StartupNotification;
use POSIX qw(getpid);
use Time::HiRes qw(gettimeofday);
use strict;
use warnings;

=head1 NAME

XDE::X11::StartupNotification::Launcher - startup notification launcher module

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides methods supporting X11 startup notification that
are used by a I<launcher> (the program launching X11 client programs).
This module provides a representation of an X11 startup notification
sequence.  Each startup notification sequence is identified by its
startup identifier.

=head1 METHODS

The module provides the following methods:

=over

=item B<new> XDE::X11::StartupNotification::Launcher I<$sn>, I<%parms> => $ctx

Creates a new launcher startup notification context and assigns it the
startup.  C<$sn> is the startup notification instance (an instance of
L<XDE::X11::StartupNotification(3pm)>); C<%parms> is the parameters for
launch.  Possible parameters are:

=over

=item ID

The startup notification identifier.  Uniquely identifies a startup
sequence; should be some globally unique string.
This should normally not be supplied and will be completed during the
initiate() call.

=item NAME

Some human readable name of the item being started; for example,
"Control Center" or "Untitled Document"; this name should be localized.

=item SCREEN

The X screen number for the startup sequence.

=item BIN

The name of the executable being started, argv[0].

=item ICON

A string to be interpreted exactly as the "Icon" field in desktop
entries is interpreted.

=item DESKTOP

The desktop on which the application should appear, counting from 0, as
in C<_NET_WM_DESKTOP>.  However, this value should never override a
C<_NET_WM_DESKTOP> property set on a window that is being mapped.  This
desktop is relative to the screen provided by the C<SCREEN> key.

=item TIMESTAMP

The X service timestamp of the user action that caused this launch.  For
example, a window manager that does not allow stealing forcus by newly
mapped windows while the user works in an application can use this
timestamp for windows that have matching C<_NET_STARTUP_ID> property if
they do not have any C<_NET_WM_USER_TIME> property set or if it is
older.  See the description of C<_NET_WM_USER_TIME> in the WM spec for
details.

=item DESCRIPTION

A short description suitable for display in a dialog that indicates what
is happening.  For example "Opening document Foo" or "Launching KWord" -
the description should be in "foo-ing whatever" format, dscribing the
current status.

=item WMCLASS

A string to match against the "resource name" or "resource class"
hints.  If this key is present, the launchee will most likely not send a
C<remove> message on its own.  If the desktop environment detects a
toplevel window mapped with this name or class, it should send a
C<remove> message for the startup sequence.  Note that the class hint is
in Latin-1, so the value of this key must be converted to Latin-1 before
strcmp'ing it with the window class/name (though in all known cases only
ASCII is involved so its does not matter).

=item SILENT

A boolean (1/0) value: when set to 1, there should be no visual
feedback.  This can be used to suspend the visual feedback temporarily,
e.g. when the application shows a dialog during its startup before
mapping the main window.  Another use is for launch sequences for
applications that are neither compliant nor their WMClass is known, but
which should preferably have their window mapped on the desktop
specified by the value of C<DESKTOP>.

=item APPLICATION_ID

=back

=cut

sub new {
    my($type,$sn,%parms) = @_;
    my $self = bless {parms=>\%parms}, $type;
    $self->{sn} = $sn;
    return $self;
}

=item $ctx->B<initiate>(I<$launcher>, I<$launchee>, I<$timestamp>) => $id

Initiates a startup sequence.  All the properties of the launch (such as
type, geometry, description) should be set up prior to initiating the
sequence.  The launcher name, C<$launcher>, is the name of the launcher
application, suitable for debug output.  The launchee name,
C<$launchee>, is the name of the launchee application, suitable for
debug output.  The timestamp (X11 server time) of the user X11 event
launching the application, I<$timestamp>, can optionally be provided.

=cut

my sequence_number = 0;

sub initiate {
    my($self,$launcher,$launchee,$timestamp) = @_;
    unless ($self->{parms}{ID}) {
	$launcher =~ s{/}{|}g;
	$launchee =~ s{/}{|}g;
	$id = sprintf("%s/%s/%d-%d-%s_TIME%lu",
		$lancher, $launchee, getpid, sequence_number,
		`hostname -f`, $timestamp);
	sequence_number += 1;
	$self->{parms}{ID} = $id;
	my ($tv_sec,$tv_usec) = gettimeofday;
	$self->{initiated_time} = [ $tv_sec, $tv_usec ];
	my %keys = (ID=>1);
	my $msg = sprintf("new: ID=%s", $self->{parms}{ID});
	foreach (qw(NAME SCREEN BIN ICON DESKTOP TIMESTAMP DESCRIPTION
		    WMCLASS SILENT APPLICATION_ID)) {
	    if (exists $self->{parms}{$_}) {
		my $val = $self->{parms}{$_};
		$keys{$_} = 1;
		$msg .= sprintf(" %s=%s", $_, XDE::X11::StartupNotification:quote($val));
	    }
	}
	foreach (keys %{$self->{parms}}) {
	    next if $keys{$_};
	    if (exists $self->{parms}{$_}) {
		my $val = $self->{parms}{$_};
		$keys{$_} = 1;
		$msg .= sprintf(" %s=%s", $_, XDE::X11::StartupNotification:quote($val));
	    }
	}
	$self->broadcast_message($msg);
	return $id;
    }
}

=item $ctx->B<complete>()

Completes the launcher sequence by sending a C<remove> message to the
root window.

=cut

sub complete {
    my $self = shift;
    if ($self->{parms}{ID}) {
	my $msg = sprintf("remove: ID=%s", $self->{parms}{ID});
	$self->broadcast_message($msg);
	return;
    }
    warn "Cannot complete sequence without an ID!";
}

=item $ctx->B<get_startup_id>() => $startup_id

Returns the startup identifier for this launcher sequence.

=cut

sub get_startup_id {
    my $self = shift;
    return $self->{parms}{ID};
}

=item $ctx->B<get_initiated>() => $boolean

Indicates whether the launcher sequence has been initiated.

=cut

sub get_initiated {
    my $self = shift;
    return defined($self->{parms}{ID});
}

=item $ctx->B<setup_child_process>()

This method should be called after forking, but before exec(), in the
child process being launched.  It sets up the environment variables
telling the child preocess about the launch ID.

=cut

sub setup_child_process {
    my $self = shift;
    if (defined($self->{parms}{ID})) {
	$ENV{DESKTOP_STARTUP_ID} = $self->{parms}{ID};
    } else {
	warn "Cannot setup child process without an ID!";
    }
}

=item $ctx->B<set_name>(I<$name>)

=cut

sub set_name {
    my($self,$name) = @_;
    $self->{parms}{NAME} = $name;
}

=item $ctx->B<set_description>(I<$description>)

=cut

sub set_description {
    my($self,$desc) = @_;
    $self->{parms}{DESCRIPTION} = $desc;
}

=item $ctx->B<set_workspace>(I<$workspace>)

=cut

sub set_workspace {
    my($self,$page) = @_;
    $self->{parms}{DESKTOP} = $page;
}

=item $ctx->B<set_wmclass>(I<$wmclass>)

=cut

sub set_wmclass {
    my($self,$wmclass) = @_;
    $self->{parms}{WMCLASS} = $wmclass;
}

=item $ctx->B<set_binary_name>(I<$name>)

=cut

sub set_binary_name {
    my($self,$name) = @_;
    $self->{parms}{BIN} = $name;
}

=item $ctx->B<set_icon_name>(I<$icon>)

=cut

sub set_icon_name {
    my($self,$icon) = @_;
    $self->{parms}{ICON} = $icon;
}

=item $ctx->B<set_application_id>(I<$desktop_file>)

=cut

sub set_application_id {
    my($self,$id) = @_;
    $self->{parms}{APPLICATION_ID} = $id;
}

=item $ctx->B<set_extra_property>(I<$name>,I<$value>)

=cut

sub set_extra_property {
    my($self,$name,$value) = @_;
    $self->{parms}{"\U$name\E"} = $value;
}

=item $ctx->B<get_initiated_time>() => $tv_sec, $tv_usec

=cut

sub get_initiated_time {
    my $self = shift;
    if ($self->{initiated_time}) {
	return @{$self->{initiated_time}};
    }
    return ();
}

=item $ctx->B<get_last_active_time>() => $tv_sec, $tv_usec

=cut

sub get_last_active_time {
    my $self = shift;
    if ($self->{last_active_time}) {
	return @{$self->{last_active_time}};
    }
    return ();
}

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::X11::StartupNotification(3pm)>,
L<XDE::X11(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
