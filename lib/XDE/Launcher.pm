package XDE::Launcher;
use X11::SN::Launcher;
use X11::SN::Sequence;
use strict;
use warnings;

=head1 NAME

XDE::Launcher - an XDG compliant startup notification launcher module

=head1 SYNOPSIS

 use XDE::Launcher;

 my $xde = XDE::Launcher->new(%OVERRIDES,ops=>\%ops);

 $xde->getenv;
 $xde->default;
 $xde->init;
 $xde->launch($appid,$fileorurl);
 $xde->term;
 exit(0);

=head1 DESCRIPTION

This module provides the capabilities of an XDG compliant startup
notification launcher.  This module is used by, for example,
L<xdg-launch(1p)>.

=head1 METHODS

The following methods are provided:

=over

=item $xde = XDE::Launcher->B<new>(I<%OVERRIDES>,ops=>\I<%ops>)

Creates an instance of an XDE::Launcher object.  The XDE::Launcher
module uses the L<XDE::Context(3pm)> module as a base, so the
I<%OVERRIDES> and I<%ops> are simply passed to the L<XDE::Context(3pm)>
module.

=item $xde->B<_init>() => $xde

=item $xde->B<_term>() => $xde

=item $xde->B<launch>(I<%args>) => I<$success>

Requires that the application specified using the argument, I<%args>, be
launghed.  The arguments hash, I<%args>, may contain the following
recognized fields (unrecognized fields are ignored):

=over

=item B<verbose>

A boolean indicating whether to display diagnostic information to
standard error during the launch.

=item B<monitor>

A boolean indicating whether the XDG application is launched as a child
task (when true) or a foreground task (when false).  The default when
unspecified is to run as a foreground task.

=item B<launcher>

The name of the launcher used to generate human readable startup
identifiers.  Defaults the name of the currently running program, C<$0>,
stripped of any path.

=item B<launchee>

The name of the launchee used to generate human readable startup
identifiers.  Defaults to the C<BIN> field of the C<new> message to be
launched, stripped of any path.

=item B<sequence>

Specifies a sequence number to be used to generate the startup
identifier for the launch.  When a launcher restarts an application, it
may be necessary to supply a different sequence number.  Defaults to
zero (0).

=item B<hostname>

Specifies the hostname to be used to generate the startup identifier for
the launch.  This should be the fully qualified host name as is used for
the B<WM_CLIENT_MACHINE> property when used in conjunction with the
B<_NET_WM_PID> property.

=item B<screen>

The screen number on which to launch the application.  This affects the
C<SCREEN> key-value pair in the startup notification C<new> message.  A
null string value or unspecified value indicates the default screen.

Typically, the procedures that invoked the launch() should set the
screen to the screen on which the launcher itself received user input.

=item B<workspace>

The desktop name or number on which to launch the application.  When
specified as a simple number, that desktop number is used (counting from
zero); otherwise, the C<_NET_DESKTOP_NAMES> property on the root window
is checked to determine the desktop number that corressponds to the
name.  A null string value indicates the current desktop.  When
specified, supplies the C<DESKTOP> key-value pair for the startup
notification C<new> message.

Typically, the procedures that invoked the launch() should set the
workspace to the desktop that was active at the time that the laucher
rceived user input.  This is so that window managers that follow startup
notification can map a window on the correct desktop when the desktop
changed after launch.

=item B<timestamp>

The X Server timestamp of the X Event that cause the launch to be
invoked.  A value of zero specifies the current time and the method
should obtain a new timestamp from the X Display.  When specified,
supplies the C<TIMESTAMP> key-value pair for the startup notification
C<new> message.

This parameter may be used by window managers that refuse to let a newly
mapped window steal the focus from the window in which the user is
currently working, or when the active desktop has changed since the
launch of the client.

=item B<name>

When specified, overrides the B<Name> field of the XDG desktop entry and
supplies the C<NAME> key-value pair for the startup notification C<new>
message.

=item B<icon>

When specified, overrides the B<Icon> field of the XDG desktop entry and
supplies the C<ICON> key-value pair for the startup notification C<new>
message.

=item B<binary>

When specified, overrides the B<TryExec> field of the XDG desktop entry
and supplies the C<BIN> key-value pair for the startup notification
C<new> message.

=item B<description>

When specified, overrides the B<Comment> field of the XDG desktop entry
and supplies the C<DESCRIPTION> key-value pair for the startup
notification C<new> message.

=item B<wmclass>

When specified, overrides the B<StartupWMClass> field of the XDG desktop
entry and supplies the C<WMCLASS> key-value pair for the startup
notification C<new> message.

=item B<silent>

When specified, supplies the C<SILENT> key-value pair for the startup
notification C<new> message.  When unpspecified, the C<SILENT> key-value
pair defaults to C<0> for XDG desktop entries that provide true
B<StartupNotify> field or supply a B<StartupWMClass> field; defaults to
C<1> for those that supply neither.

=item B<appid>

When specified, overrides the application id and provides the
C<APPLICATION_ID> key-value pair for the startup notification C<new>
message.

=item B<exec>

When specified, overrides the C<Exec> field of the XDG desktop entry.

=item B<file>

Specifies a file path and name to substitute in the XDG application
startup command (i.e. the C<%f> or C<%F> portions of the C<Exec> field).

=item B<url>

Specifies a URL to substitute in the XDG application startup command
(i.e. the C<%u> or C<%U> portions of the C<Exec> field).

=item B<argv>

Specifies the application identifier that is used to locate the XDG
desktop entry file and provides the default for the C<APPLICATION_ID>
key-value pair in the startup notification C<new> message.

Each application identifier can be one of:

=over

=item 1.

The name of an XDG compliant desktop entry file, including the
C<.desktop> suffix.  Example C<gvim.desktop>.

=item 2.

The name of an XDG compliant desktop entry file, excluding the
C<.desktop> suffix.  Example: C<gvim>.

=item 3.

A full (absolute or relative) path to a desktop entry file with the file
name and any F<.desktop> suffix included.

=back

When unspecified, an XDG application can still be lauched when the
B<appid>, B<binary> or B<exec> argument is specified.  Example:
C</usr/share/applications/gvim.desktop>.

=back

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::SN(3pm)>,
L<X11::SN::Launcher(3pm)>,
L<X11::SN::Sequence(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
