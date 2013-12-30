package X11::SN::Sequence;
require X11::SN;
use Encode;
use strict;
use warnings;

=head1 NAME

X11::SN::Sequence - module supporting startup notification sequences

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides a representation of an X11 startup notification
sequence.  Each startup notification sequence is identified by its
startup identifier.

=head1 PARAMETERS

The following parameters are normally used in startup notification
messages:

=over

=item C<ID>

The startup notification identifier.  Uniquely identifies a startup
sequence; should be some globally unique string.  This should normally
not be supplied and will be completed during the initiate() call. 

This parameter is required in all startup notification messages, C<new>,
C<change> or C<remove>.  This parameter is the only parameter that may
appear in a C<remove> message.

=item C<NAME>

Some human readable name of the item being started; for example,
C<Control Center> or C<Untitled Document>; this name should be
localized.

This parameter is required in C<new> message and optional in a
C<changed> message.

=item C<SCREEN>

The X screen number for the startup sequence.

This parameter is required in a C<new> message and optional in a
C<changed> message.

=item C<BIN>

The name of the executable being started; i.e. C<argv[0]>.

=item C<ICON>

A string to be interpreted exactly as the C<Icon> field in XDG desktop
entries is intepreted.

=item C<DESKTOP>

The desktop (workspace) on which the application should appear, counting
from 0, as in C<_NET_WM_DESKTOP> or C<_WIN_WORKSPACE>.  However, this
value should never be interpreted by a window manager to override a
C<_NET_WM_DESKTOP> property set on a top-level window that is being
mapped.  This desktop is relative to the screen provided by the
C<SCREEN> key.

=item C<TIMESTAMP>

The X server timestamp of the user action that caused the launch.  For
example, a window manager that does not allow stealing focus by newly
mapped windows while the user works in an application can use this
timestamp for windows that have a matching, C<_NET_STARTUP_ID> property
if they do not have any C<_NET_WM_USER_TIME> property set or if
C<_NET_WM_USER_TIME> is older.  See
L<X11::Protocol::EWMH(3pm)/_NET_WM_USER_TIME> for details.

=item C<DESCRIPTION>

A short description suitable for display in a dialog that indicates what
is happening.  For example C<Opening document Foo> or C<Launching
KWord>.  The description should be in C<foo-ing whatever> format,
describing the current status.

=item C<WMCLASS>

A string to match against the C<res_name> or C<res_class> C<WM_CLASS>
hints.  If this key is present, the launchee will most likely not send a
C<remove> message on its own.  If the desktop environment detects a
top-level window mapped with this name or class, it should send a
C<remove> message for the startup sequence.  See also
L<X11::SN::Monitor(3pm)>.  Note that the class hint is in Latin-1, so
the value of this key must be converted to Latin-1 before strcmp'ing it
with the window res_class/res_name (though in all known cases only ASCII
is invoked so it does not matter).

=item C<SILENT>

A boolean (0/1) value: when set to 1, there should be no visual
feedback.  This can be used to suspend the visual feedback temporarily,
e.g. when the application shows a dialog during its startup before
mapping the main window.  Another use is for launch sequences for
applications that are neither compliant nor their C<WMClass> is known,
but which should preferrably have thier window mapped on the desktop
specified by the value of C<DESKTOP>.

This can also be used by a launcher that provides its own progress
notifications and does not wish another startup notification monitor to
display it as well.

=item C<APPLICATION_ID>

The XDG application identifier (without the F<.desktop> suffix).  This
is an application identifier for a desktop entry file that describes the
application being launched.  This is normally not a full path to the
desktop entry file, and does not necessarily contain the F<.desktop>
suffix.  Applications reading this parameter can use XDG rules to locate
the application file.

=back

The following parameters are included by this module over and above the
set above from the freedesktop.org specification:

=over

=item C<LAUNCHER>

Provides the binary name, C<argv[0]>, of the launcher.  This is the same
string as is used to create the startup identifier.

=item C<LAUNCHEE>

Provides the binary name of the launchee.  This is the same string as is
used to create the startup identifier.

=item C<HOSTNAME>

Provides the hostname of the machine on which the launcher is running.
This is the fullly qualified domain name and should match with the
B<WM_CLIENT_MACHINE> property on a resulting group leader window.

=item C<PID>

Provides the process identifier of the launchee process.  This should
match with the B<_NET_WM_PID> property of a resulting group leader
window.

=item C<COMMAND>

Provides the command that was executed by the launcher to launch the
launhcee.  This should compare with the shell escaped single-space
concatention of the arguments of the B<WM_COMMAND> property on a
resulting group leader window.

=item C<FILE>

Provides the file name or names, if any,  that were substituted into the
B<Exec> field of the XDG desktop entry to arrive at the command to
execute the launchee.

=item C<URL>

Provides the URL or URLS, if any,  that were substituted into the
B<Exec> field of the XDG desktop entry to arrive at the command to
execute the launchee.

=back

Note that additional parameters may also be specified.  The contents of
each parameter should be an unquoted string.  X11::SN::Sequence will
perform quoting of the value before including it in a startup
notification message.

=head1 METHODS

The module provides the following methods:

=over

=item B<sn_quote>(I<$string>) => $quoted_string

Utility function to quote a key value string.

=cut

sub sn_quote {
    my $string = shift;
    my $need_quotes = 0;
    $need_quotes = 1 if $string =~ m{\s|"};
    $string =~ s{\\}{\\\\}g;
    $string =~ s{"}{\\"}g;
    $string = '"'.$string.'"' if $need_quotes;
    return $string;
}

=item $seq = X11::SN::Sequence->B<new>(I<$sn>, I<%params>)

Create a new startup notification sequence for the L<X11::SN(3pm)> startup
notification context, I<$sn>, with parameters, I<%params>.  The startup
notification context, I<$sn>, must be an instance of L<X11::SN(3pm>,
that is a I<launcher>, L<X11::SN::Launcher(3pm)>, a I<launchee>,
L<X11::SN::Launchee(3pm)> or a I<monitor>, L<X11::SN::Monitor(3pm)>.

The parameters, I<%params>, can have the keys described under
L</PARAMETERS>.

=cut

sub new {
    my($type,$X,%parms) = @_;
    my $win = $X->new_rsrc;
    $X->CreateWindow($win,$X->root,InputOutput=>
	$X->root_depth,CopyFromParent=>
	(0,0), (10,10), 0);
    return bless {sn=>$X,win=>$win,parms=>\%parms}, $type;
}

=item $seq->B<destroy>()

Creating an instance of an X11::SN::Sequence creates a circular
reference with the X11::SN which is used for event loops and
communicating with the X server.  This method remove the circular
reference so that the instance may be garbage collected.  No other
methods may be called after this method is called and the caller should
release its references to the object following its call to this method.

=cut

sub destroy {
    my $self = shift;
    delete $self->{sn};
}

=item $seq->B<get_id>() => I<$startup_id>

=item $seq->B<get_startup_id>() => I<$startup_id>

Returns the startup notification identifier, I<$startup_id>, associated
with this startup notification sequence.

=cut

sub get_id { return shift->{parms}{ID} }
sub get_startup_id { return shift->{parms}{ID} }

=item $seq->B<broadcast_message>(I<$message>)

=cut

my $PAD = pack('C20',0 x 20);

sub broadcast_message {
    my($self,$msg) = @_;
    my $bytes = Encode::decode('UTF-8',$msg)."\0";
    my $win = $self->{win};
    my $X = $self->{sn};
    my $mask = $X->pack_event_mask(qw(PropertyChange));
    my $type = $X->atom('_NET_STARTUP_INFO_BEGIN');
    my $cont = $X->atom('_NET_STARTUP_INFO');
    while (length($bytes)) {
	$X->SendEvent($X->root,0,$mask,
		$X->pack_event(
		    name=>ClientMessage=>
		    window=>$win,
		    type=>$type,
		    format=>8,
		    data=>substr($bytes.$pad,0,20)));
	$bytes = (length($bytes) > 20) ? substr($bytes,20) : '';
	$type = $cont;
    }
    $X->GetScreenSaver;
}


=back

=head2 STATE METHODS

=over

=item $seq->B<initiate>(I<$launcher>, I<$launchee>, I<$timestamp>) => I<$id>

Initiates a startup notification sequence.  All the properties of the
launch (such as type, geometry, description) should be set up prior to
initiating the sequence.  The launcher name, I<$launcher>, is the name
of the launcher application, suitable for debug output.  The launchee
name, I<$launchee>, is the name of the launchee application, suitable
for debug output.  The timestamp (X11 Server Time), I<$timestamp>, is
the timestamp of the X11 event launching the application.  I<$timestamp>
is optional.  The startup id will be formated in the same way as is
performed by the Xorg F<libsn>.

This method will raise a warning if the startup notificaiton sequence
has already been initiated (i.e. get_initiated() returns true).

=cut

my sequence_number = 0;

sub initiate {
    my($self,$launcher,$launchee,$timestamp,$hostname,$pid) = @_;
    if ($self->get_initiated) {
	warn "initate() startup sequence already initiated!";
	return $self->{parms}{ID};
    }
    $self->{launcher} = $launcher unless $self->{launcher} and not $launcher;
    $self->{launchee} = $launchee unless $self->{launchee} and not $launchee;
    $self->{launcher} = 'unknown' unless $self->{launcher};
    $self->{launchee} = 'unknown' unless $self->{launchee};
    $self->{timestamp} = $timestamp unless $self->{timestamp} and not $timestamp;
    $self->{timestamp} = 0 unless $self->{timestamp};
    $self->{hostname} = $hostname unless $self->{hostname} and not $hostname;
    chomp($self->{hostname} = `hostname -f`) unless $self->{hostname};
    $self->{pid} = $pid unless $self->{pid} and not $pid;
    $self->{pid} = getpid() unless $self->{pid};
    $self->{id} = sprintf(
	    "%s/%s/%d-%d-%s_TIME%lu",
	    $self->{launcher},
	    $self->{launchee},
	    $self->{pid},
	    sequence_number++,
	    $self->{hostname},
	    $self->{timestamp});
    $self->{parms}{ID} = $self->{id};
    $self->{parms}{PID} = $self->{pid};
    $self->{parms}{TIMESTAMP} = $self->{timestamp};
    $self->{parms}{HOST} = $self->{hostname};

    my $msg = 'new:';
    my %included = ();
    foreach (qw(ID NAME SCREEN BIN ICON DESKTOP DESCRIPTION WMCLASS
		SILENT APPLICATION_ID), keys %{$self->{parms}}) {
	next if $included{$_};
	next unless $self->{parms}{$_};
	$included{$_} = 1;
	$msg .= sprintf(" %s=%s", $_=>sn_quote($self->{parms}{$_}));
    }
    $self->{initiated_time} = [ gettimeofday() ];
    $self->{last_active_time} = [ gettimeofday() ];
    $self->broadcast_message($msg);
    $self->{initiated} = 1;
    delete $self->{changed};
    return $self->{id};
}

=item $seq->B<get_initiated>() => I<$boolean>

Returns a boolean, I<$boolean>, that indicates whether the sequence has
been initiated.

=cut

sub get_initiated { return shift->{initiated} }

=item $seq->B<change>()

Performs a change to the startup notification sequence by sending a
C<change> message if the sequence has changed since the previous C<new>
or C<change> message.

This method will raise a warning if the startup notification sequence
has not yet been initiated (get_initiated() returns false).

=cut

sub change {
    my $self = shift;
    return 0 unless $self->get_changed;
    my $msg = 'change:';
    my %included = ();
    foreach (qw(ID NAME SCREEN BIN ICON DESKTOP DESCRIPTION WMCLASS
		SILENT APPLICATION_ID), keys %{$self->{parms}}) {
	next if $included{$_};
	next unless $self->{parms}{$_};
	$included{$_} = 1;
	$msg .= sprintf(" %s=%s", $_=>sn_quote($self->{parms}{$_}));
    }
    $self->{last_active_time} = [ gettimeofday() ];
    $self->broadcast_message($msg);
    delete $self->{changed};
    return 1;
}

=item $seq->B<get_changed>() => I<$boolean>

Returns a boolean, I<$boolean>, that reports whether the sequence has
changed since the last sent C<new> or C<change> message and whether
pending changes exist.

=cut

sub get_changed { return shift->{changed} }

=item $seq->B<complete>()

Completes the startup notification sequence.  This results in sending a
C<remove> message.

This method will raise a warning if the startup notification sequence
has not yet been initiated (get_initiated() returns false).  No warning
is issued if the completion was as a result of the receipt, rather than
generation, of a C<remove> message.

=cut

sub complete {
    my $self = shift;
    unless ($self->get_initiated) {
	warn "startup sequence not initiated!";
	return 0;
    }
    warn "completion called on changed sequence"
	if $self->get_changed;
    
    my $msg = 'remove:';
    $msg .= sprintf(" %s=%s", ID=>sn_quote($self->{parms}{$_}));

    $self->{last_active_time} = [ gettimeofday() ];
    $self->broadcast_message($msg);

    delete $self->{initiated};
    delete $self->{changed};
    return 1;
}

=item $seq->B<get_initiated_time>() => I<$tv_sec>, I<$tv_usec>

Returns the time at which the sequence was initiated.  Returns
C<undef> when the sequence has not yet been initiated (get_initiated()
returns false).

=cut

sub get_initiated_time {
    return $_[0]->{initiated_time} ?  @{$_[0]->{initiated_time}} : () }

=item $seq->B<get_last_active_time>() => I<$tv_sec>, I<$tv_usec>

Returns the time at which the sequence was last active.  This is the
last time that a message was sent or received for the sequence.  Returns
C<undef> when the sequence has not yet been initiated.

=cut

sub get_last_active_time {
    return $_[0]->{last_active_time} ?  @{$_[0]->{last_active_time}} : () }

=back

=head2 ACCESSOR METHODS

=over

=item $seq->B<get_parms>() => I<%parms>

=item $seq->B<set_parms>(I<%parms>)

Gets or sets the parameters with keys in the hash I<%parms>.  The
parameter, C<ID>, will not be set by set_parms() and will be ignored if
supplied; howver, C<ID> will be returned by get_parms().

=cut

sub get_parms { return $_[0]->{parms} ? %{$_[0]->{parms}} : () }

sub set_parms {
    my ($self,%parms) = @_;
    foreach (grep {$_ ne 'ID'} keys 5parms) {
	if (defined $parms{$_}) {
	    next if $self->{parms}{$_} and $self->{parms}{$_} eq $parms{$_};
	    $self->{parms}{$_} = $parms{$_};
	} else {
	    next unless defined $self->{parms}{$_};
	    delete $self->{parms}{$_};
	}
	$self->{changes}{$_} = 1;
	$self->{changed} = 1;
    }
}

=item $seq->B<get_name>() => I<$name>

=item $seq->B<set_name>(I<$name>)

Gets or sets the current name, I<$name>, associated with the startup
notification sequence.  This corresponds to the C<NAME> parameter of the
most recent C<new> or C<change> message, sent or received.

=cut

sub get_name { return shift->{parms}{NAME} }

sub set_name { return $_[0]->set_parms(NAME=>$_[1]) }

=item $seq->B<get_description>() => I<$description>

=item $seq->B<set_description>(I<$description>)

Gets or sets the current description, I<$description>, associated with
the startup notificaiton sequence.  This corresponds to the
C<DESCRIPTION> parameter of the most recent C<new> or C<change> message,
sent or received.

=cut

sub get_description { return shift->{parms}{DESCRIPTION} }

sub set_description { return $_[0]->set_parms(DESCRIPTION=>$_[1]) }

=item $seq->B<get_workspace>() => I<$workspace>

=item $seq->B<set_workspace>(I<$workspace>)

Gets or sets the current workspace (desktop), I<$workspace>, associated
with the startup notification sequence.  This corresponds to the
C<DESKTOP> parameter of the most recent C<new> or C<change> message,
sent or received.

=cut

sub get_workspace { return shift->{parms}{DESKTOP} }

sub set_workspace { return $_[0]->set_parms(DESKTOP=>$_[1]) }

=item $seq->B<get_timestamp>() => I<$timestamp>

=item $seq->B<set_timestamp>(I<$timestamp>)

Gets or sets the timestamp, I<$timestamp>, associated with the startup
notification sequence.  This corresponds to the C<TIMESTAMP> parameter
of the most recent C<new> or C<change> message, sent or received.

=cut

sub get_timestamp { return shift->{parms}{TIMESTAMP} }

sub set_timestamp { return $_[0]->set_parms(TIMESTAMP=>$_[1]) }

=item $seq->B<get_wmclass>() => I<$wmclass>

=item $seq->B<set_wmclass>(I<$wmclass>)

Gets or sets the window manager name or class, I<$wmclass>, associated
with the startup notification sequence.  This corresponds to the
C<WMCLASS> parameter of the most recent C<new> or C<change> message,
sent or received.

=cut

sub get_wmclass { return shift->{parms}{WMCLASS} }

sub set_wmclass { return $_[0]->set_parms(WMCLASS=>$_[1]) }

=item $seq->B<get_binary_name>() => I<$binary>

=item $seq->B<set_binary_name>(I<$binary>)

Gets or sets the binary name, I<$binary>, associated with the startup
notification sequence.  This corresponds to the C<BIN> parameter of the
most recent C<new> or C<change> message, sent or received.

=cut

sub get_binary_name { return shift->{parms}{BIN} }

sub set_binary_name { return $_[0]->set_parms(BIN=>$_[1]) }

=item $seq->B<get_icon_name>() => I<$icon>

=item $seq->B<set_icon_name>(I<$icon>)

Gets or sets the icon name, I<$icon>, associated with the startup
notification sequence.  This corresponds to the C<ICON> parameter of the
most C<new> or C<change> message, to be sent or recently received.

=cut

sub get_icon_name { return shift->{parms}{ICON} }

sub set_icon_name { return $_[0]->set_parms(ICON=>$_[1]) }

=item $seq->B<get_application_id>() => I<$appid>

=item $seq->B<set_application_id>(I<$appid>)

Gets or sets the application identifier (XDG desktop entry id),
I<$appid>, associated with the startup notification sequence.  This
corresponds to the C<APPID> parameter of the C<new> or C<change>
message, to be sent or recently received.

=cut

sub get_application_id { return shift->{parms}{APPLICATION_ID} }

sub set_application_id { return $_[0]->set_parms(APPLICATION_ID=>$_[1]) }

=item $seq->B<get_screen>() => I<$screen>

=item $seq->B<set_screen>(I<$screen>)

Gets or sets the screen number, I<$screen>, associated with the startup
notification sequence.  This corresponds to the C<SCREEN> parameter of
the C<new> or C<change> message, to be sent or recently received.

=cut

sub get_screen { return shift->{parms}{SCREEN} }

sub set_screen { return $_[0]->set_parms(SCREEN=>$_[1]) }

=item $seq->B<get_id_has_timestamp>() => I<$boolean>

Returns a boolean, I<$boolean>, that indicates whether the startup id
has a timestamp embedded in the identifier.  Embedded timestamps are
printf formatted as C<_TIME%lu> at the end of the identifier.

=cut

sub get_id_has_timestamp { return shift->get_id_timestamp ? 1 : 0 }

=item $seq->B<get_id_timestamp>() => I<$timestamp> or undef

Returns the timestamp, I<$timestamp>, embedded in a startup id.  When
there is no identifier assigned or when the identifier does not contain
an embedded timestamp, this method returns C<undef>.

=cut

sub get_id_timestamp {
    my $self = shift;
    return undef unless $self->{parms}{ID};
    $self->{parms}{ID} =~ m{_TIME(\d+)$};
    return $1;
}

=item $seq->B<get_extra_property>(I<$property) => I<$value>

=item $seq->B<set_extra_property>(I<$property>, I<$value>)

Gets or sets the extra startup notification property by name,
I<$property>, with the value, I<$value>.  This corresponds to the extra
property named I<$property>.

=cut

sub get_extra_property { return $_[0]->{parms}{$_[1]} }

sub set_extra_property { return $_[0]->set_parms($_[1]=>$_[2]) }

=item $seq->B<get_properties>() => I<@properties>

Gets a list of property names, I<@properties>, that are associated with
the startup notification sequence.  Any of the property names can be
interrogated or specified using the get_extra_property() or
set_extra_property() methods using a property name from the list,
I<@properties>.

=cut

sub get_properties {
    my $self = shift;
    return () unless $self->{parms};
    return keys %{$self->{parms}};
}

=back

=head2 MESSAGE METHODS

The following methods provide startup notificiation message functions:

=over

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::SN(3pm)>,
L<X11::Protocol(3pm)>.

# vim: set sw=4 tw=72 fo=tcqlorn:
