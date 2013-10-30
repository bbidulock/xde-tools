package XDE::X11::StartupNOtification::Sequence;
use strict;
use warnings;

=head1 NAME

XDE::X11::StartupNotification::Sequence - startup notification sequence object

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides a representation of an X11 startup notification
sequence.  Each startup notification sequence is identified by its
startup identifier.  It is not intended on being directly instantiated
by users, but generated and supplied to callbacks of the
L<XDE::X11::StartupNotification::Monitor(3pm)> object.

=head1 METHODS

The module provides the following methods:

=over

=item B<sn_quote>(I<$string>) => $quoted

Utility function to quote a key value string.

=cut

sub sn_quote {
    my $string = shift;
    my $need_quotes = 0;
    $need_quotes = 1 if $string =~ m{\s};
    $need_quotes = 1 if $string =~ s{"}{\\"}g;
    $need_quotes = 1 if $string =~ s{\\}{\\\\}g;
    $string = '"'.$string.'"' if $need_quotes;
    return $string;
}

=item B<new> XDE::X11::StartupNotification::Sequence

Create a new, blank, startup notification sequence.

=cut

sub new {
    return bless {parms=>{}}, shift;
}

=item $seq->B<get_id>() => $startup_id

Returns the startup identifier, C<$startup_id>, associated with this
startup notification sequence.

=cut

sub get_id {
    return shift->{parms}{ID};
}

=item $seq->B<get_startup_id>() => $startup_id

Returns the startup identifier for this launcher sequence.

=cut

sub get_startup_id {
    return shift->{parms}{ID};
}

=item $seq->B<get_initiated>() => $boolean

Indicates whether the launcher sequence has been initiated.

=cut

sub get_initiated {
    my $self = shift;
    return defined($self->{parms}{ID});
}

=item $seq->B<get_completed>() => $boolean

Returns a boolean value that indicates whether the startup notification
sequence has completed.  A startup notification sequence completes when
a C<remove> command is sent or received for the sequence.

=cut

sub get_completed {
    return shift->{completed};
}

=item $seq->B<get_name>() => $name

Provides the current name associated with the startup notification
sequence.  This corresponds to the C<NAME> parameter of the most recent
C<new> or C<change> message.

=cut

sub get_name {
    return shift->{parms}{NAME};
}

=item $seq->B<set_name>(I<$name>)

=cut

sub set_name {
    my($self,$name) = @_;
    $self->{parms}{NAME} = $name;
}

=item $seq->B<get_description>() => $description

Provides the current description associated with the startup
notification sequence.  This corresponds to the C<DESCRIPTION> parameter
of the most recent C<new> or C<change> message.

=cut

sub get_description {
    return shift->{parms}{DESCRIPTION};
}

=item $seq->B<set_description>(I<$description>)

=cut

sub set_description {
    my($self,$desc) = @_;
    $self->{parms}{DESCRIPTION} = $desc;
}

=item $seq->B<get_workspace>() => $workspace

Provides the current workspace (desktop) associated with the startup
notification sequence.  This corresponds to the C<DESKTOP> parameter of
the most recent C<new> or C<change> message.

=cut

sub get_workspace {
    return shift->{parms}{DESKTOP};
}

=item $seq->B<set_workspace>(I<$workspace>)

=cut

sub set_workspace {
    my($self,$page) = @_;
    $self->{parms}{DESKTOP} = $page;
}

=item $seq->B<get_timestamp>() => $timestamp

Provides the current timestamp associated with the startup notification
sequence.  This corresponds to the C<TIMESTAMP> parameter of the most
recent C<new> or C<change> message.

=cut

sub get_timestamp {
    return shift->{parms}{TIMESTAMP};
}

=item $seq->B<get_wmclass>() => $wmclass

Provides the current window class associated with the startup
notification sequence.  This corresponds to the C<WMCLASS> parameter of
the most recent C<new> or C<change> message.

=cut

sub get_wmclass {
    return shift->{parms}{WMCLASS};
}

=item $seq->B<set_wmclass>(I<$wmclass>)

=cut

sub set_wmclass {
    my($self,$wmclass) = @_;
    $self->{parms}{WMCLASS} = $wmclass;
}

=item $seq->B<get_binary_name>() => $name

Provides the current binary name associated with the startup
notification sequence.  This corresponds to the C<BIN> parameter of the
most recent C<new> or C<change> message.

=cut

sub get_binary_name {
    return shift->{parms}{BIN};
}

=item $seq->B<set_binary_name>(I<$name>)

=cut

sub set_binary_name {
    my($self,$name) = @_;
    $self->{parms}{BIN} = $name;
}

=item $seq->B<get_icon_name>() => $name

Provides the current icon name associated with the startup notification
sequence.  This corresponds to the C<ICON> parameter of the most recent
C<new> or C<change> message.

=cut

sub get_icon_name {
    return shift->{parms}{ICON};
}

=item $seq->B<set_icon_name>(I<$icon>)

=cut

sub set_icon_name {
    my($self,$icon) = @_;
    $self->{parms}{ICON} = $icon;
}

=item $seq->B<get_application_id>() => $desktop_file

Provides the current application id associated with the startup
notification sequence.

=cut

sub get_application_id {
    return shift->{parms}{APPLICATION_ID};
}

=item $seq->B<set_application_id>(I<$desktop_file>)

=cut

sub set_application_id {
    my($self,$id) = @_;
    $self->{parms}{APPLICATION_ID} = $id;
}

=item $seq->B<get_screen>() => $screen

Provides the screen associated with the startup notification sequence.
The screen is determined by the XID of the root window receiving the
startup notification message sequence.

=cut

sub get_screen {
    return shift->{parms}{SCREEN};
}

=item $seq->B<set_screen>(I<$screen>)

=cut

sub set_screen {
    my($self,$screen) = @_;
    $self->{parms}{SCREEN} = $screen;
}

=item $seq->B<get_id_has_timestamp>() => $boolean

Indicates whether the startup notification sequence has a timestamp
associated with it.

=cut

sub get_id_has_timestamp {
    return defined(shift->{parms}{TIMESTAMP});
}

=item $seq->B<get_timestamp>() => $timestamp

Gets the timestamp associated with the startup notification sequence.

=cut

=item $seq->B<set_timestamp>(I<$timestamp>)

=cut

=item $seq->B<get_extra_property>(I<$name>) => $value

=cut

sub get_extra_property {
    my($self,$name) = @_;
    return $self->{parms}{$name};
}

=item $seq->B<set_extra_property>(I<$name>,I<$value>)

=cut

sub set_extra_property {
    my($self,$name,$value) = @_;
    $self->{parms}{"\U$name\E"} = $value;
}

=item $seq->B<get_initiated_time>() => $tv_sec, $tv_usec

Provides the time at which the startup notification sequence was
initiated.  This is the time that the initial C<new> message was
received.

=cut

sub get_initiated_time {
    my $self = shift;
    if ($self->{initiated_time}) {
	return @{$self->{initiated_time}};
    }
    return ();
}

=item $seq->B<get_last_active_time>() => $tv_sec, $tv_usec

Provides the time at which the startup notification sequence was last
active.  This is the time that the last C<new>, C<change> or C<remove>
message was received in the sequence.

=cut

sub get_last_active_time {
    my $self = shift;
    if ($self->{last_active_time}) {
	return @{$self->{last_active_time}};
    }
    return ();
}

=item $seq->B<setup_child_process>() => $id

This method should be called after forking, but before exec(), in the
child process being launched.  It sets up the environment variables
telling the child preocess about the launch ID.

=cut

sub setup_child_process {
    my $self = shift;
    unless ($self->{parms}{ID}) {
	warn "Cannot setup child without an ID!";
	return;
    }
    my $id = $ENV{DESKTOP_STARTUP_ID} =
	$self->{parms}{ID};
    return $id;
}

=item $seq->B<initiate>(I<$launcher>, I<$launchee>, I<$timestamp>) => $id

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
    if ($self->{parms}{ID}) {
	warn "Startup sequence already iniitated!";
	return $self->{parms}{ID};
    }
    $self->{launcher} = $launcher;
    $self->{launchee} = $launchee;
    $self->{launcher} =~ s{/}{|}g;
    $self->{launchee} =~ s{/}{|}g;
    $self->{id} = $self->{parms}{ID} = sprintf(
	    "%s/%s/%d-%d-%s_TIME%lu",
	    $self->{launcher},
	    $self->{launchee},
	    getpid,
	    sequence_number,
	    `hostname -f`,
	    $timestamp);

    sequence_number++;

    my($tv_sec,$tv_usec) = gettimeofday;
    $self->{initiated_time} = [ $tv_sec, $tv_usec ];
    $self->{last_active_time} = [ $tv_sec, $tv_usec ];

    my $msg = "new:";
    my %keys = ();
    foreach (qw(ID NAME SCREEN BIN ICON DESKTOP
	    DESCRIPTION WMCLASS SILENT
	    APPLICATION_ID)) {
	if ($self->{parms}{$_}) {
	    my $val = $self->{parms}{$_};
	    $keys{$_} = 1;
	    $msg .= sprintf(" %s=%s", sn_quote($val));
	}
    }
    foreach (keys %{$self->{parms}}) {
	next if $keys{$_};
	if ($self->{parms}{$_}) {
	    my $val = $self->{parms}{$_};
	    $keys{$_} = 1;
	    $msg .= sprintf(" %s=%s", sn_quote($val));
	}
    }
    $self->broadcast_message($msg);
    return $self->{parms}{$ID};
}

=item $seq->B<change>()

Performs a change to the startup notification sequence by sending a
C<change> message if the sequence has changed since the previous C<new>
or C<change> message.

=cut

sub change {
    my $self = shift;
    return unless $self->{changed};
    $self->{changed} = 0;
    my $msg = "change:";
    my %keys = ();
    foreach (qw(ID NAME SCREEN BIN ICON DESKTOP
		DESCRIPTION WMCLASS SILENT APPLICATION_ID)) {
	my $val = $self->{parms}{$_};
	next unless $val;
	$keys{$_} = 1;
	$msg .= sprintf(" %s=%s", sn_quote($val));
    }
}

=item $seq->B<complete>()

Completes the startup notification sequence by sending a C<remove>
message if the sequence is not already complete.

=cut

sub complete {
    my $self = shift;
    if ($self->{completed}) {
	warn "Startup sequence already complete!";
	return;
    }
    unless ($self->{parms}{ID}) {
	warn "Startup sequence not initiated!";
	return;
    }
    my $msg = sprintf("remove: ID=%s", sn_quote($self->{parms}{ID}));
    $self->broadcast_message($msg);
}


1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::X11::StartupNotification(3pm)>,
L<XDE::X11(3pm)>,
L<startup-notification-0.1.txt>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:

