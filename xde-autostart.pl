#!/usr/bin/perl

# in case we get executed (not sourced) as a shell program
eval 'exec perl -S $0 ${1+"@"}'
    if $running_under_some_shell;

BEGIN {
    use strict;
    use warnings;
    my $here = $0; $here =~ s{/[^/]*$}{};
    if ($here =~ s{^\.}{}) {
	chomp(my $cwd = `pwd`);
	$here = "/$here" if $here;
	$here = "$cwd$here";
    }
    unshift @INC, "$here/lib" unless $here =~ m{^/usr/bin};
}

use Getopt::Long;
use POSIX qw(setsid getpid :sys_wait_h);
use File::Path;
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::Notify;
use Gtk2::Unique;
use X11::Protocol;
use Net::DBus;
use Net::DBus::GLib;
use XDE::Autostart;
use strict;
use warnings;

my %OVERRIDES = ();
my $here = $0; $here =~ s{/[^/]*$}{};
if ($here =~ s{^\.}{}) {
    chomp(my $cwd = `pwd`);
    $here = "/$here" if $here;
    $here = "$cwd$here";
}
unless ($here =~ m{^/usr/bin}) {
    %OVERRIDES = (
	HERE               => "$here",
	XDG_CONFIG_PREPEND => "$here/xdg/xde:$here/xdg:/etc/xdg/xde",
	XDG_DATA_PREPEND   => "$here/share/xde:$here/share:/usr/share/xde",
	XDG_ICON_APPEND    => "$here/share/icons:$here/share/pixmaps:/usr/share/icons:/usr/share/pixmaps",
    );
    my %path = (map{$_=>1}split(/:/,$ENV{PATH}));
    $ENV{PATH} = "$here:$ENV{PATH}" unless exists $path{$here};
}

my $program = $0; $program =~ s{.*/}{};

my %ops = (
    help	=> '',
    display	=> $ENV{DISPLAY},
    desktop	=> '',
    session	=> '',
    startwm	=> [],
    file	=> '',
    exec	=> [],
    autostart	=> 1,
    wait	=> 1,
    pause	=> 0,
    banner	=> '',
    splash	=> '',
    message	=> '',
    side	=> 'left',
    vendor	=> '',
    mkdirs	=> '',
    charset	=> langinfo(CODESET),
    language	=> setlocale(LC_MESSAGES),
);

my $xde = XDE::Autostart->new(%OVERRIDES,ops=>\%ops);
$xde->getsenv;

my $syntax = GetOptions(%ops,qw(
    help|h
    verbose|v
    display|d=s
    desktop|e=s
    session|s=s
    startwm|m=s
    file|f=s
    exec|x=s
    autostart|a!
    wait|w!
    pause|p:2000
    splash|l:s
    message|g=s
    side|i=s
    vendor|V=s
    mkdirs!
    charset|c=s
    language|l=s
)};

$xde->show_settings;

$xde->default;

$xde->show_settings;

if ($ops{help}) {
    print show_usage();
    exit (0);
}
if (not $syntax) {
    print STDERR "SYNTAX ERROR:\n";
    print show_usage();
    exit (2);
}
if ($ops{help} or not $stynax) {
    show_usage();
    exit ($syntax ? 0 : 2);
}

$xde->setenv;
$xde->init;
$xde->do_startup;
my $result = $xde->main;

exit (0);

sub show_usage {
    return <<USAGE_EOF;

USAGE:
    $program [OPTIONS]

ARGUMENTS:
    None.

OPTIONS:
    --help, -h
        print this usage information and exit.

    --verbose, -v
        print debugging information to standard error during operation.

    --display, -d DISPLAY       [default: $ENV{DISPLAY}]
        the display to use if other than \$DISPLAY.

    --desktop, -e DESKTOP       [default: $ops{desktop}]
        desktop environment to use when looking up desktop entries.

    --session, -s SESSION       [default: $ops{session}]
        session profile to use (same as DESKTOP for XDE).

    --startwm, -m EXECUTE       [default: @{$ops{startwm}}]
        execute EXECUTE to start window manager.  This option may be
        repeated to spcecify multiple programs to start.

    --file, -f FILENAME         [default: $ops{file}]
        read autostart commands from this filename.

    --exec, -x COMMAND          [default: @{$ops{exec}}]
        execute COMMAND before autostarting tasks.  This option may be
        repeated to specify mulitple commands to execute.

    --noautostart, -noa         [default: $ops{autostart}]
        do not autostart XDG applications.  The default is to autostart
        XDG applications.

    --nowait, -now              [default: $ops{wait}]
        do not wait for a window manager to appear before executing or
        autostarting tasks.  The default is to wait.

    --pause, -p [PAUSE]         [default: $ops{pause}]
        wait for PAUSE milliseconds before autostarting tasks.  The
        default is not to pause.  PAUSE is 2000 milliseconds when
        unspecified.

    --splash, -l [LOGO]         [default: $ops{splash}]
        use the specified splash logo for branding an LXDE logout
        screen.  This option is deprecated.

    --message, -g MESSAGE       [default: $ops{message}]
        use the specified message in the LXDE logout screen.  This
        option is deprecated.

    --banner, -b BANNER         [default: $ops{banner}]
        use the specified BANNER file for branding splash screens.  The
        default depends on vendor settings.

    --prompt, -p PROMPT         [default: $ops{prompt}]
        use the specified prompt in the logout splash screen.  The
        default depends on desktop, session and vendor settings.

    --side, -i SIDE             [default: $ops{side}]
        specify the side for the branding graphic.  Must be one of
        'top', 'bottom', 'left' or 'right'.  This option is currently
        ignored.

    --vendor, -V VENDOR         [default: $ops{vendor}]
        specify the vendor string for branding.

    --mkdirs                    [default: $ops{mkdirs}]
        create XDG home directories as rerquired.

    --charset, -c CHARSET   [default: $ops{charset}]
        specify the character set to use to output text; defaults to the
        charset of the current locale.

    --language, -l LANGUAGE [default: $ops{language}]
        specify the language to use to output text; defaults to the
        value of the current locale.

USAGE_EOF
}

1;

__END__

=pod

=head1 NAME

xde-autostart - autostart applications for an XDE session

=head1 SYNOPSIS

 xde-autostart [ OPTIONS ]

=head1 DESCRIPTION

B<Xde-autostart> starts performs the startup functions for a new XDE
session, launches a window manager, and optionally starts any additional
applications or XDG autostart applications as specified by the I<XDG
Desktop Specification>.

See the L</USAGE> section for usage examples.

=head1 OPTIONS

=over

=item B<--display>, B<-d> I<DISPLAY>

Specifies the display to use.  This is not normally necessary as the
display is obtained from the B<DISPLAY> environment variable when this
option is not specified.

=item B<--desktop>, B<-e> I<DESKTOP>

Specify the desktop environment (DE) to use, I<DESKTOP>, e.g.
C<FLUXBOX>, C<BLACKBOX>, C<ICEWM>, C<LXDE>.  The default value when not
specified is C<FLUXBOX>.  The desktop environment must be specified when
B<--autostart> is specified.

In L<lxsession(1)> compatability mode, this is equivalent to the B<-e>
option to L<lxsession(1)>.  This option may also be specified using the
B<XDG_CURRENT_DESKTOP> or B<FBXDG_DE> environment variables described
below.

=item B<--session>, B<-s> I<SESSION>

Invokes L<lxsession(1)> compatability mode and specifies the session
profile to use for emulating L<lxsession(1)>.  This is equivalent to the
B<-s> option to L<lxsession(1)>.  This option may also be specified
using the B<DESKTOP_SESSION> environment variable as described below.

=item B<--startwm>, B<-m> I<EXECUTE>

Execute the command string, I<EXECUTE>, to start a window manager.
Shell characters will be interpreted.  When specified, the window
manager will be started before all other tasks.  This optoin may be
specified multiple times and each command  will be executed in order
when starting the window manager.

When not specified, this option will be determined from the
L<session.conf> file in the F<SESSION> subdirectory under
F<$XDG_CONFIG_HOME/xde>, where F<SESSION> is specified by the
B<-s> option, or by the first non-option argument.

In L<lxsession(1)> compatability mode, this option will be determined
from the L<lxsession(1)> F<desktop.conf> file in the F<SESSION>
subdirectory under F<$XDG_CONFIG_HOME/lxsession>, where F<SESSION> is
specified with the B<-s> option.

=item B<--exec>, B<-x> I<COMMAND>

Execute the command string, I<COMMAND>, to start applications after the
window manager, and before autostart tasks are executed.  This option
defaults to none.  The option may be repeated to execute a number of
commands the order specified.  It is possible to prefix the I<COMMAND>
string with a single C<@> that will indicate that the task should be
restarted when it exits abnormally.

=item B<--autostart>, B<--noautostart>, B<-a>

Specifies whether (or not) to autostart XDG applications in accordance
with the I<Desktop Application Autostart Specification>.  The inverted
sense of the B<-a> flag is for compatablity with L<lxsession(1)>.

=item B<--wait>, B<-w>, B<--nowait>

Specifies whether (or not) to wait for a EWMH/NetWM compatible window
manager to take control of the root window of the default screen of the
display before starting further applications.  This option takes effect
regardless of whether the B<--startwm> option has been specified.

=item B<--pause>, B<-p> [I<PAUSE>]

Specifies the interval of time, I<PAUSE>, in seconds to wait after the
window manager initialization phase before starting the first
applications.  If I<PAUSE> is not specified, it defaults to 2 seconds.
The default when the option is not specified is not to pause at all.
The pause can be explicitly disable by using a I<PAUSE> value of zero
(0).

=item B<--splash>, B<-l> [I<IMAGE>]

Specifies that a splash window is to be generated and optionally
populated with an image from the file, I<IMAGE>, (that can be in XPM or
PNG format).  The splash window will display the icons of the XDG
compliant F<*.desktop> files as they are started.  The I<IMAGE> is for
optional branding.

=back

=head1 USAGE

B<xde-autostart> is intended on being launched by the L<xdg_session(8)>
shell script.  See the L<xdg_session(8)> manual page for details on its
operation.

When used directly, B<xde-autostart> will launch the following window
managers (and likely others as a variation on a theme) successfully:

=over 4

=item B<FLUXBOX>

Simply execute B<xde-autostart> as the only command in your
F<~/.fluxbox/startup> file.  The execution line should look like:

 xde-autostart --desktop FLUXBOX --startwm "fluxbox -rc ~/.fluxbox/init"

where F<~/.fluxbox/init> is just the default.  Use B<xde-autostart-edit(1)>
to autostart the programs that you would otherwise start from your
F<startup> script.  Therefore the above command bypasses the normal
F<startup> script, which is likely unaware of B<xde-autostart>.

=item B<BLACKBOX>

Where you would invoke L<blackbox(1)>, invoke the following:

 xde-autostart --desktop BLACKBOX --startwm "blackbox -rc ~/.blackboxrc"

where F<~/.blackboxrc> is just the default.

=item B<ICEWM>

L<icewm(1)> user normally either launch L<icewm(1)> alone or
L<icewm-session(1)>.  L<icewm-session(1)> provides some limited
autostarting of applications (it forks L<icewwmtray(1)> and
L<icewmbg(1)> as well as L<icewm(1)> itself), but does not support XDG
Autostart, XSETTINGS and Startup Notification.

=item B<OPENBOX>

L<openbox(1)> is typically started either using L<openbox-session(1)>
directly, or under LXDE using L<lxdestart(1)>.

=item B<WMAKER>

L<wmaker(1)> has its own non-XDG compliant session management.  This
means that if B<xde-autostart> is used to launch WindowMaker, it should be
made to suppress XDG autostart tasks using the B<--noautostart> or B<-a>
option, such as:

 xde-autostart --noautostart --desktop WMAKER --startwm wmaker

=back

=head1 EXAMPLES

=head1 FILES

=over

=item F<$XDG_CONFIG_{HOME,DIRS}/lxsession/SESSION/autostart>

The default F<autostart> files in L<lxsession(1)> compatability mode.
Note that the values from B<all> autostart files will be used.

=item F<$XDG_CONFIG_{HOME,DIRS}/lxsession/SESSION/desktop.conf>

The default F<desktop.conf> file in L<lxsession(1)> compatability mode.
Note that the values from only the file in the "most important"
directory will be used.

=back

=head1 ENVIRONMENT

The following environment variables are examined or set by
B<xde-autostart>:

=over 4

=item B<HOME>

Will be used to determined the user's home directory for the purpose of
calculating the default value for C<XDG_CONFIG_HOME> when required.

=item B<XDG_CONFIG_HOME>

When set, C<$XDG_CONFIG_HOME/autostart> will be examined for
C<*.desktop> files.  The variable defaults to C<$HOME/.config>.

=item B<XDG_CONFIG_DIRS>

When set, C<DIRECTORY/autostart> will be examined for each C<DIRECTORY>
in the colon separated list of directories contained in
C<XDG_CONFIG_DIRS>.  The variable defaults to C</etc/xdg>.

=item B<XDG_CURRENT_DESKTOP>

When the C<--desktop> option is not specified, C<XDG_CURRENT_DESKTOP> is
examined to determine the current desktop.  C<XDG_CURRENT DESKTOP> is
set to the value that resulted from option and environment variable
processing for children of the session.

=item B<FBXDG_DE>

To emulate L<fbautostart>, the C<FBXDG_DE> environment variable is
examined when the C<--desktop> option is not specified and the
C<XDG_CURRENT_DESKTOP> environment variable is not set.  C<FBXDG_DE> is
set to the value that resulted from option and environment variable
processing for children of the session.

=item B<DESKTOP_SESSION>

To emulate L<lxsession(1)>, the C<DESKTOP_SESSION> environment variable
is set to the value that resulted from potion and enviroment variable
processing for children of the session.

=item B<XDG_SESSION_PID>

C<XDG_SESSION_PID> is set to the PID of B<xde-autostart>, the process group
leader responsible for launching all tasks under the X session manager.
The X session can be terminated by killing this process.

=item B<_LXSESSION_PID>

To emulate L<lxsession(1)>, the C<_LXSESSION_PID> environment variable
is set to the PID of B<xde-autostart>, the process group leader responsible
for launching all tasks under the X session manager.  The X session can
be terminated by killing this process.

=back

=head1 SIGNALS

=over

=item I<SIGTERM>

A I<SIGTERM> signal sent to the C<$XDG_SESSION_PID> or
C<$_LXSESSION_PID> will terminate the entire session.  This should be
avoided when the window manager does not properly catch termination
signals and save its configuration before terminating.

When the B<--startwm> option is specified or implied, B<xde-autostart> will
also terminate when the window manager exits normally.

=back

=head1 CAVEATS

When in L<lxsession(1)> compatability mode, B<xde-autostart> cannot act as
an Xsettings daemon in accordance with the Xsettings specification.
L<lxsession(1)> can.

=head1 HISTORY

I wrote B<xde-autostart> due to the deficiencies of B<fbautostart(1)> and
L<lxsession(1)> when launching XDG-compliant applications and desktop
environments over NWM/ENWM compliant light-weight window managers.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<lxsession(1)>, L<Standards(7)>,

L<Basedir|http://www.freedesktop.org/wiki/Specifications/basedir-spec>,

L<Desktop Entry Specification|http://www.freedesktop.org/wiki/Specifications/desktop-entry-spec>,

L<Desktop Application Autostart Specification|http://www.freedesktop.org/wiki/Specifications/autostart-spec>,

L<Desktop Menu Specification|http://www.freedesktop.org/wiki/Specifications/menu-spec>,

L<Startup Notification|http://www.freedesktop.org/wiki/Specifications/startup-notification-spec>,

L<XSETTINGS|http://www.freedesktop.org/wiki/Specifications/xsettings-spec>,

L<System Tray|http://www.freedesktop.org/wiki/Specifications/systemtray-spec>.

=cut

# vim: sw=4 tw=72
