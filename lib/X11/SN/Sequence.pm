package X11::SN::Sequence;
require X11::SN;
use strict;
use warnings;

=head1 NAME

X11::SN::Sequence - module supporting startup notification sequences

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides a representation of an X11 startup notification
sequence.  Each startup notification sequence is identified by its
startup identifier.

=head1 METHODS

The module provides the following methods:

=over

=item B<sn_quote>(I<$string>) => $quoted_string

Utility function to quote a key value string.

=item $seq = X11::SN::Sequence->B<new>(I<$sn>, I<%params>)

Create a new startup notification sequence for the L<X11::SN(3pm)> startup
notification context, I<$sn>, with parameters, I<%params>.  The startup
notification context, I<$sn>, must be either a I<launcher>,
L<X11::SN::Launcher(3pm)>, a I<launchee>, L<X11::SN::Launchee(3pm)> or a
I<monitor>, L<X11::SN::Monitor(3pm)>.

The parameters, I<%params>, can have the following keys:

=over

=item C<ID>

The startup notification identifier.  Uniquely defines a startup
sequence; should be some globally unique string.  This should normally
not be supplied and will be completed during the initiate() call.

=item C<NAME>

Some human readable name of the item being started; for example,
C<Control Center> or C<Untitled Document>; this name should be
localized.

=item C<SCREEN>

The X screen number for the startup sequence.

=item C<BIN>

The name of the executable being started; i.e. C<argv[0]>.

=item C<ICON>

A string to be interpreted exactly as the C<Icon> field in XDG desktop
entries is interpreted.

=item C<DESKTOP>

The desktop on which the application should appear, counting from zero,
as in C<_NET_WM_DESKTOP>.  However, this value should never override a
C<_NET_WM_DESKTOP> property set on a window that is being mapped.  This
desktop is relative to the screen provided by the C<SCREEN> key.

=item C<TIMESTAMP>

The X server timestamp of the user action that caused this launch.  For
example, a window manager that does not allow stealing focus by newly
mapped windows while the user works in an application can use this
timestamp for windows that have matching C<_NET_STARTUP_ID> property if
they do no have any C<_NET_WM_USER_TIME> property set or if it is older.
See the description of C<_NET_WM_USER_TIME> in the EWMH/NetWM
specification for details.

=item C<DESCRIPTION>

A short description suitable for display in a dialog that indicates what
is happening.  For example C<Opening document Foo> or C<Launching
KWord>.  The description should be in C<foo-ing whatever> format,
describing the current status.

=item C<WMCLASS>

A string to match against the name or class in the C<WM_CLASS> property.
If this key is present, the launchee will most likely not send a
C<remove> message on its own.  If the desktop environment detects a
top-level window mapped with this name or class, ti should send a
C<remove> message for the startup sequence.  Note that the class hint is
in Latin-1, so the value of this key must be converted to Latin-1 before
strcmp'ing it with the window class/name (though in all known cases only
ASCII is involved so it does not matter).

=item C<SILENT>

A boolean (1/0) value: when set to 1, there should be no visual
feedback.  This can be use to suspend the visual feedback temporarily,
e.g. when the application shows a dialog during its startup before
mapping the main window.  Another use is for launch sequences for
applications that are neither compliant nor their C<WM_CLASS> is known,
but which should preferably have their window mapped on the desktop
specified by the value C<DESKTOP>.

=item C<APPLICATION_ID>

The application identifier (without the F<.desktop> suffix).

=back

Note that additional parameters may also be specified.  The contents of
each parameter should be an unquoted string.  X11::SN::Sequence will
perform quoting of the value before including it in a startup
notification message.

=item $seq->B<get_id>() => I<$startup_id>

=item $seq->B<get_startup_id>() => I<$startup_id>

Returns the startup notification identifier, I<$startup_id>, associated
with this startup notification sequence.

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

=item $seq->B<get_initiated>() => I<$boolean>

Returns a boolean, I<$boolean>, that indicates whether the sequence has
been initiated.

=item $seq->B<change>()

Performs a change to the startup notification sequence by sending a
C<change> message if the sequence has changed since the previous C<new>
or C<change> message.

This method will raise a warning if the startup notification sequence
has not yet been initiated (get_initiated() returns false) or has been
completed (get_completed() returns true).

=item $seq->B<get_changed>() => I<$boolean>

Returns a boolean, I<$boolean>, that reports whether the sequence has
changed since the last sent C<new> or C<change> message and whether
pending changes exist.

=item $seq->B<complete>()

Completes the startup notification sequence.  This results in sending a
C<remove> message.

This method will raise a warning if the startup notification sequence
has not yet been initiated (get_initiated() returns false) or has
already been completed locally (get_completed() returns true).  No
warning is issued if the completion was as a result of the receipt,
rather than generation, of a C<remove> message.

=item $seq->B<get_completed>() => I<$boolean>

Returns a boolean, I<$boolean>, that indicates whether the startup
notification sequence has completed.  A startup notification sequence
completes when a C<remove> command is sent or received for the sequence.

=back

=head2 ACCESSOR METHODS

=over

=item $seq->B<get_name>() => I<$name>

=item $seq->B<set_name>(I<$name>)

Gets or sets the current name, I<$name>, associated with the startup
notification sequence.  This corresponds to the C<NAME> parameter of the
most recent C<new> or C<change> message, sent or received.

=item $seq->B<get_description>() => I<$description>

=item $seq->B<set_description>(I<$description>)

Gets or sets the current description, I<$description>, associated with
the startup notificaiton sequence.  This corresponds to the
C<DESCRIPTION> parameter of the most recent C<new> or C<change> message,
sent or received.

=item $seq->B<get_workspace>() => I<$workspace>

=item $seq->B<set_workspace>(I<$workspace>)

Gets or sets the current workspace (desktop), I<$workspace>, associated
with the startup notification sequence.  This corresponds to the
C<DESKTOP> parameter of the most recent C<new> or C<change> message,
sent or received.

=item $seq->B<get_timestamp>() => I<$timestamp>

=item $seq->B<set_timestamp>(I<$timestamp>)

Gets or sets the timestamp, I<$timestamp>, associated with the startup
notification sequence.  This corresponds to the C<TIMESTAMP> parameter
of the most recent C<new> or C<change> message, sent or received.

=item $seq->B<get_wmclass>() => I<$wmclass>

=item $seq->B<set_wmclass>(I<$wmclass>)

Gets or sets the window manager name or class, I<$wmclass>, associated
with the startup notification sequence.  This corresponds to the
C<WMCLASS> parameter of the most recent C<new> or C<change> message,
sent or received.

=item $seq->B<get_binary_name>() => I<$binary>

=item $seq->B<set_binary_name>(I<$binary>)

Gets or sets the binary name, I<$binary>, associated with the startup
notification sequence.  This corresponds to the C<BIN> parameter of the
most recent C<new> or C<change> message, sent or received.

=item $seq->B<get_icon_name>() => I<$icon>

=item $seq->B<set_icon_name>(I<$icon>)

Gets or sets the icon name, I<$icon>, associated with the startup
notification sequence.  This corresponds to the C<ICON> parameter of the
most C<new> or C<change> message, to be sent or recently received.

=item $seq->B<get_application_id>() => I<$appid>

=item $seq->B<set_application_id>(I<$appid>)

Gets or sets the application identifier (XDG desktop entry id),
I<$appid>, associated with the startup notification sequence.  This
corresponds to the C<APPID> parameter of the C<new> or C<change>
message, to be sent or recently received.

=item $seq->B<get_screen>() => I<$screen>

=item $seq->B<set_screen>(I<$screen>)

Gets or sets the screen number, I<$screen>, associated with the startup
notification sequence.  This corresponds to the C<SCREEN> parameter of
the C<new> or C<change> message, to be sent or recently received.

=item $seq->B<get_id_has_timestamp>() => I<$boolean>

Returns a boolean, I<$boolean>, that indicates whether the startup id
has a timestamp embedded in the identifier.  Embedded timestamps are
printf formatted as C<_TIME%lu> at the end of the identifier.

=item $seq->B<get_id_timestamp>() => I<$timestamp> or undef

Retruns the timestamp, I<$timestamp>, embedded in a startup id.  When
there is no identifier assigned or when the identifier does not contain
an embedded timestamp, this method returns C<undef>.

=item $seq->B<get_extra_property>(I<$property) => I<$value>

=item $seq->B<set_extra_property>(I<$property>, I<$value>)

Gets or sets the extra startup notification property by name,
I<$property>, with the value, I<$value>.  This corresponds to the extra
property named I<$property>.

=item $seq->B<get_properties>() => I<@properties>

Gets a list of property names, I<@properties>, that are associated with
the startup notification sequence.  Any of the property names can be
interrogated or specified using the get_extra_property() or
set_extra_property() methods using a property name from the list,
I<@properties>.

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
