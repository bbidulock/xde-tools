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
use Encode;
use I18N::Langinfo qw(langinfo CODESET);
use POSIX qw(locale_h);
use XDE::Setbg;
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

my $program = $0; $program =~ s{^.*/}{};

my %ops = (
    help	=> '',
    verbose	=> '',
    prompt	=> '',
    banner      => '',
    noask	=> '',
    charset	=> langinfo(CODESET),
    language	=> setlocale(LC_MESSAGES),
    setdflt     => '',
    default	=> '',
    current	=> '',
    choice	=> '',
    vendor	=> '',
    monitor	=> 1,
    grab	=> 1,
    theme	=> '',
    id		=> '',
    setroot	=> 1,
);

my $xde = XDE::Setbg->new(%OVERRIDES,ops=>\%ops);
$xde->getenv;

my $syntax = GetOptions(
    'help|h'	    => \$ops{help},
    'verbose|v'	    => \$ops{verbose},
    'monitor!'	    => \$ops{monitor},
    'setroot|s'	    => \$ops{setroot},
    'grab|g'	    => \$ops{grab},
    'n'		    => sub{ $ops{monitor} = 0 },
    'id=s'	    => \$ops{id},
);

my @files = @ARGV;

$ops{id} = hex($ops{id}) if $ops{id} and $ops{id} =~ m{^0x};

$xde->default; # reset defaults

$xde->init;
#$xde->set_backgrounds(@files);
$xde->main;
$xde->term;

exit(0);

sub show_usage {
    return <<USAGE_EOF;

USAGE:
    xde-setbg [OPTIONS] [FILE [FILE ...]]
USAGE_EOF
}

1;

__END__

=head1 NAME

xde-setbg -- set backgrounds and monitor for desktop changes

=head1 SYNOPSIS

xde-setbg -- [OPTIONS] [FILE [FILE ...]]

=head1 DESCRIPTION

B<xde-setbg> is a gtk2-perl application that can be used to set the
backgrounds on multiple desktops or workspaces and work areas for
lightweight window managers that do not have this capability on their
own.  It installs the specified pixmaps to the current desktop and
monitors for changes.  See L</BEHAVIOUR> for detailed behaviour of the
program.

=head1 ARGUMENTS

B<xde-setbg> takes the following arguments:

=over

=item [I<FILE> [I<FILE>] ...]

A list of files that specify which backgrounds to use for which virtual
desktops.

=back

=head1 COMMAND OPTIONS

One of the following command options should be specified.
When no command option is specified, B<xde-setbg> will assume that the
command option is B<--set>.

=over

=item B<--set>, B<-s>

Set the background.  The additional options and arguments are
interpreted as listed in L</OPTIONS>.

=item B<--edit>, B<-e>

Do not set the background, but, rather, launch the background settings
editor.  When a current instance of B<xde-setbg> is running, the running
instance will launch the editor; otherwise, a new B<xde-setbg> daemon
will be started.

=item B<--quit>, B<-q>

Ask a running instance of B<xde-setbg> to quit.

=item B<--restart>, B<-r>

Ask a running instance of B<xde-setbg> to restart.

=item B<--help>, B<-h>

Print usage information to standard error containing current defaults
and exit.

=back

=head1 OPTIONS

B<xde-setbg> recognizes the following options: (Because
L<Getopt::Long(3pm)> is used, non-ambiguous abbreviations and single
dash long options are accepted.)

=over

=item B<--verbose>, B<-v>

Print debugging information on standard error while running.

=item B<--grab>, B<-g>

Grab the X Display while setting backgrounds.

=item B<--setroot>, B<-s>

Set the background pixmap on the root window instead of just setting the
root window pixmap properties.

=item B<--nomonitor>, B<-n>

Specifies that B<xde-setbg> should just set the background(s) and should
not monitor for changes.  Just use L<hsetroot(1)> or some other
background setter instead of this option.

=item B<--theme>, B<-t> I<THEME>

Tells B<xde-setbg> which theme or style is currently being used by the
window manager.

=item B<--delay>, B<-d> I<MILLISECONDS>

Specifies the amount of time in milliseconds to wait after the apperance
of a window manager before entering full operation.  If set to zero (0),
the program will not wait for a window manager to appear before entering
full operation.

=item B<--areas>, B<-a>

Normaly B<xde-setbg> will only distribute backgrounds over workspaces
and not work areas.  This option causes B<xdg-setbg> to also distribute
backgrounds over work areas.  (L<fvwm(1)> is the only lightweight window
manager that supports work areas and viewports.)

=back

=head1 BEHAVIOUR

When B<xde-setbg> is executed and an existing instance of B<xde-setbg>
is running, it passes its arguments to the running program and exits.

On the initial invocation of B<xde-setbg> for a given X Display,
B<xde-setbg> will first await the appearance of an X Window Manager that
conforms to the EWMH/NetWM specification.  After a delay, (configurable
with the B<--delay> option), B<xde-setbg> will start operation.

The purpose of waiting until after the window manager to appears is that
most lightweight window managers set the background before or after
startup.  Waiting a short duration after window manager startup serves
to ignore any changes made to the desktop background during startup of
the desktop environment.

After beginning full operation, B<xde-setbg> will complete startup
notification (if it was requested).  It then determines whether an
XSETTINGS daemon is in operation, and if so, will read its settings from
the XSETTINGS daemon.  In the absence of an xsettings daemon, it will
read its configuration from its configuration file.  See
L</CONFIGURATION> for how the configuration file is selected.

The configuration will then be used to set backgrounds on the current
desktop and any additional desktops provided by the window manager and
will monitor for further desktop background changes on the X Display.
When the background settings change, it will change the background of
the root window to the corresponding selected background.  Whenever the
image on the root window is changed using a tool such as L<hsetroot(1)>,
B<xde-setbg> will record the change against the desktop and work area
and restore those settings when the desktop and work area change.

Background changes can come background setting tools (such as
L<hsetroot(1)> or L<xsetroot(1)>), command line invocation arguments,
from settings of the XSETTINGS daemon, or from configuration file
changes.

B<xde-setbg> also understands the file and style settings for various
lightweight window managers: L<fluxbox(1)>, L<blackbox(1)>,
L<openbox(1)>, L<icewm(1)>, L<jwm(1)>, L<pekwm(1)>, L<fvwm(1)> and
L<wmaker(1)>.  It can also detect when an instance of L<pcmanfm(1)> is
controlling the desktop wallpaper.  When a multiple-background capable
window manager is running and present (such as L<wmaker(1)> or an
L<lxde(1)> session with L<pcmanfm(1)> desktop), B<xde-setbg> exits and
does nothing.

When there is a current background on initial startup, B<xde-setbg>
assumes that this is a desktop background that was applied by the
lightweight window manager and ignores its settings.

When B<xde-setbg> exits gracefully, it writes its configuration out to
the configuration file.  In addition to the background settings, it
writes the current desktop or workspace and work area and viewport to
the file.  This permits it to restore the current desktop or workspace,
work area and view port on session restart.

=head2 SUMMARY

The user will observe the following when B<xde-setbg> is running:

=over

=item 1.

The desktop background will changed when changing desktops or
workspaces, and optionally when changing work areas when enabled.

=item 2.

When meta-themes are changed using the L<xde-theme(1)> setting tool, the
set of backgrounds will also be changed.

=item 3.

When a background for a particular desktop or workspace and work area is
changed using a background setting tool, it will remain changed for that
desktop or workspace and work area for the remaining session.

=item 4.

When starting a session when running B<xde-setbg> on autostart, the
desktop or workspace and work area and view port will be changed to
match that which was active when the window manager last shut down.
That is, if I was on desktop #5 when I logged out, upon login the
desktop will switch to desktop #4.

=item 5.

The set of backgrounds can set with L<xde-theme(1)>.

=item 6.

B<xde-setbg> can be used to change the set of backgrounds during a
session and they will be applied when the session next starts.

=back

=head1 CONFIGURATION

A F<.desktop> file is distributed with B<xde-setbg> that can be used to
autostart the program in an XDG compliant environment such as is
provided by the X Desktop Environment.  Startup of the program conforms
to the XDG Startup specification, and the program will notify the
launcher once it has fully started.

=head1 WINDOW MANAGERS

B<xde-setbg> supports a number of lightweight window managers and
manages some quirks associated with each:

=over

=item L<fluxbox(1)>

L<fluxbox(1)> sets the background upon startup unless it is requested to
not do so.  The overlay file can have the background resource set to
C<background: unset>, to suppress L<fluxbox(1)> from setting the
background at all.  This setting is recommended and will result in
smooth transition from the xdm background to the B<xde-setbg> initial
background.  The B<--delay> option can be set to zero in this case.

=item L<blackbox(1)>

L<blackbox(1)> sets the background directly from information obtained
from the style file: the C<rootCommand> in the file sets the root
background.  It is normally set to L<bsetroot(1)> or L<bsetbg(1)>.
For styles that are aware of B<xde-setbg>, the C<rootCommand> can be set
to invoke B<xde-setbg> directly.  For metastyles, the background should
be reset using B<xde-setbg> or L<xde-settings(1)> after a new blackbox
style file has been applied.  Note that L<bsetbg(1)> just invokes one of
the may background setting programs.  The C<NO_EXEC> flag can be set to
true in the F<~/.bsetbgrc> file to suppress setting of the background by
L<bsetbg(1)>.

=item L<openbox(1)>

L<openbox(1)> does not provide any theme-based background setting of its
own.

=item L<icewm(1)>

L<icewm(1)> uses the L<icewmbg(1)> program to set the background.  If
the program is not run, L<icewm(1)> will not set the background.  It
reads its configuration from F<~/.icewm/preferences>.  Settings in
F<~/.icewm/prefoverride> can be used to override settings in the
F<~/.icewm/preferences> file and it appears that L<icewmbg(1)> respects
that.  The documentation in L<icewm(1)> indicates that L<icewmbg(1)> can
be used to set backgrounds on multiple desktops; however, examination of
the code fro 1.3.7 reveals that the code for that is completely strapped
out.

Basically, one need not even run B<icewmbg> when using B<xde-setbg>.  An
XDE session will not invoke B<icewmbg> and, therefore, can set the
B<--delay> option to zero (0).

=item L<jwm(1)>

L<jwm(1)> supports setting per-desktop backgrounds as part of its
configuration file (and thus through the sytle mechanism that I added to
the L<jwm(1)> configuration).  The built-in background setter works just
find and it is not necessary to run B<xde-setbg> on this window manager.
Nevertheless, B<xde-setbg> works fine when L<jwm(1)> is configured to
not use its internal background setter.

=item L<pekwm(1)>

=item L<wmaker(1)>

L<wmaker(1)> supports setting per-desktop backgrounds as part of its
theme mechanism.  This built-in background setter works just fine and
it is not necessary to run B<xde-setbg> on this window manager.
Nevertheless, B<xde-setbg> works fine when L<wmaker(1)> is configured to
not use its internal background setter.

=item L<fvwm(1)>

L<fvwm(1)> has a C<FvwmBacker> module that can set the background
per-workspace and per-workarea; however, it is a pig and transfers the
entire image to the X server on each desktop switch.  Don't use it: use
B<xde-setbg> instead.

=item L<metacity(1)>

L<metacity(1)> does not provide any theme-based background setting of
its own.

=back

=head1 BACKGROUND SETTERS

There are no background setters that appear to be desktop or workspace
aware, far less work area and view port aware.  This requires placing a
background editor into the B<xdg-setbg> tool.

Nevertheless, B<xde-setbg> is designed to work (temporarily) with the
following background setters:
(By temporarily, I mean that although B<xde-setbg> will respect the
setting made by these for the current desktop/workspace and work
area/view port, they cannot be saved across sessions.)

=over

=item L<icewmbg(1)>

=item L<bsetbg(1)>

=item L<fbsetbg(1)>

=item L<wmsetbg(1)>

=item L<xsetbg(1)>

=item L<xli(1)>

=item L<display(1)>

=item L<xv(1)>

=item L<Esetroot(1)>

=item L<hsetroot(1)>

=item L<bsetroot(1)>

=item L<fbsetroot(1)>

=item L<xsetroot(1)>

=item L<Esetroot(1)>

=item L<nitrogen(1)>

L<nitrogen(1)> allows setting the root window on the current screen and
saves the settings in F<$XDG_CONFIG_HOME/nitrogen/bg-saved.cfg> for
later restoration.

=back

=head1 HISTORY

Changing backgrounds when desktops or workspaces and work areas was not
possible some decades ago due to the limited memory capabilities of X
Servers at the time.  There is no such limitation today, even on
embedded systems.  The only lightweight window managers with this
capability are L<wmaker(1)> and L<lxde(1)> (running L<pcmanfm(1)> in
B<-desktop> mode).

Placing different backgrounds on different desktops or workspaces and
work areas helps the user of the desktop environment take notice of
desktop changes in an intuitive way without having to take visual
reference of a desktop pager.  It is a useful feature that is missing
from most lightweight window managers.

L<fvwm(1)> has the C<Backer> module that can perform desktop switching
in the same fashion as B<xde-setbg>; however, it does not store the full
set of pixmaps on the X Display and thus switching between workspaces
and work areas is both sluggish and causes screen flashes.  In
particular, changing desktops rapidly with the scroll wheel is
particularly unreponsive.

I wrote B<xde-setbg> for the X Desktop Environment to overcome the
limitations of the lightweight window managers that it supports.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<hsetroot(1)>,
L<XDE::Setbg(3pm)>,
L<X11::Protocol(3pm)>.

=cut

# vim: sw=4 tw=72
