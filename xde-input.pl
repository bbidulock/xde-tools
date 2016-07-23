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
use Gtk2;
use Gtk2::Unique;
use XDE::Input;
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
my $editor = ($program eq 'xde-input-edit') ? 1 : 0;

my (@SAVEARGS) = (@ARGV);

my %ops = (
    help        => '',
    verbose     => '',
    charset     => langinfo(CODESET),
    language    => setlocale(LC_MESSAGES),
    session     => '',
    desktop     => '',
    editor      => $editor,
    filename    => '',
    vendor      => '',
);

my $xde = XDE::Input->new(%OVERRIDES,ops=>\%ops);
$xde->getenv;

my $syntax = GetOptions( \%ops, qw(
    help|h
    verbose|v
    charset|c=s
    language|l=s
    session|s=s
    desktop|d=s
    editor|e!
    filename|f=s
    vendor|V=s
));

$xde->default; # reset defaults

if ($ops{help}) {
    print STDOUT show_usage();
    exit(0);
}

unless ($syntax) {
    print STDERR "Syntax ERROR\n";
    print STDERR show_usage();
    exit(2);
}

$xde->init;

$program = 'xde-input-edit' if $ops{editor};

$xde->{DESKTOP_STARTUP_ID} = $ENV{DESKTOP_STARTUP_ID}
    unless $xde->{DESKTOP_STARTUP_ID};
delete $ENV{DESKTOP_STARTUP_ID};
my $unique = Gtk2::UniqueApp->new(
        'com.unexicon.xde-input', $xde->{DESKTOP_STARTUP_ID},
        'xde-input' => 1,
        'xde-input-edit' => 2);
if ($unique->is_running) {
    $unique->send_message_by_name($program=>text=>join('|',@SAVEARGS));
    print STDERR "Another instance of $program is already running.\n";
    exit(0);
}

my $window = Gtk2::Window->new('toplevel');
$unique->watch_window($window);
$unique->signal_connect(message_received=>sub{
        my ($unique,$command,$message,$time) = @_;
        if ($command eq 'xde-input') {
	    if ($ops{verbose}) {
		print STDERR "$command command received\n";
		print STDERR "\tscreen is ", $message->get_screen, "\n";
		print STDERR "\tworkspace is ", $message->get_workspace, "\n";
		print STDERR "\tstartup id is ", $message->get_startup_id, "\n";
	    }
        }
        elsif ($command eq 'xde-input-edit') {
	    if ($ops{verbose}) {
		print STDERR "$command command received\n";
		print STDERR "\tscreen is ", $message->get_screen, "\n";
		print STDERR "\tworkspace is ", $message->get_workspace, "\n";
		print STDERR "\tstartup id is ", $message->get_startup_id, "\n";
	    }
	    $xde->edit_input;
        }
        return 'ok';
});


$xde->get_input();
$xde->set_input();
$SIG{TERM} = sub{$xde->main_quit};
$SIG{INT}  = sub{$xde->main_quit};
$SIG{QUIT} = sub{$xde->main_quit};
$xde->edit_input() if $ops{editor};
$xde->main;
$xde->term;

exit(0);

sub show_usage {
    return <<USAGE_EOF;

USAGE:
    $program [OPTIONS]

OPTIONS:
    --help, -h
        print this usage information and exit

    --verbose, -v
        print debugging information to standard error during operation

    --charset, -c CHARSET   [default: $ops{charset}]
        specify the character set to use on output; defaults to the
        charset of the current locale.

    --language, -l LANGUAGE [default: $ops{language}]
        specify the language to use on output; defaults to the value for
        the current locale.

    --session, -s SESSION   [default: $ops{session}]
        specify the XDG_CURRENT_DESKTOP session.

    --desktop, -d DESKTOP   [default: $ops{desktop}]
        specify the XDG_CURRENT_DESKTOP desktop.

    --filename, -f FILENAME [default: $ops{filename}]
        specify the configuration file to use instead of the default.

    --editor, -e            [default: $ops{editor}]
        launch the X Server settings editor.  This is the default when
        called as 'xde-input-edit'.

USAGE_EOF
}

1;

__END__

=head1 NAME

xde-input - X settings for the X Desktop Environment

=head1 SYNOPSIS

B<xde-input> [I<OPTIONS>]

=head1 DESCRIPTION

B<xde-input> is a X Display mouse and keyboard settings tool for the X
Desktop Environment.  It can be used to set initial X Display settings
from a configuration file, or can launch a dialogue to interactively set
X Desktop input settings.  B<xde-input> runs as a daemon and monitors
for changes made by other configuration tools (such as L<xset(1)> or
L<lxinput(1)>) and log changes to its configuration file.

The settings that can be set are those that can normally be performed
with L<xset(1)>, and are as follows:

=over

=item I<Keyboard>

Setting the keyboard I<LEDS> on or off.  The I<Keyclick> volume and
whether key clicks are on or off.  The I<Bell> volume, pitch and
duration.  Whether the I<Bell> is on or off.  Setting the I<Autorepeat>
delay and rate.  Turning I<Autorepeat> on or off.  Access to a wide
range of keyboard controls is available through the B<XKEYBOARD> X
Server extension.

=item I<Pointer>

Setting I<Mouse> acceleration (multiplier and divisor) and threshold.
Resetting the I<Mouse> to default acceleration and threshold.

=item I<Screen Saver>

Setting the I<Screen Saver> timeout and cycle.  Setting the I<Screen
Saver> to blank, expose, activate, default, not blank, not expose,
reset.  Setting the I<Screen Saver> on or off.

=item I<Colors>

Setting pixel values to a colour name.

=item I<Font Path>

Setting the I<Font Path>, or restoring the default font path.  Making
the server reread the font database.  Adding or removing elements to or
from the I<Font Path>.

=item I<DPMS (Energy Star)>

I<Standby> setting in seconds; I<Suspend> setting in seconds; I<Off>
setting in seconds.  Whether I<DPMS> is enabled or not.  Whether the
I<Monitor> is on or off.  Forcing the I<Monitor> to on, standby, suspend
or off.

=back

=head1 OPTIONS

B<xde-input> understands the following options:

=over

=item B<--help>, B<-h>

Prints usage information and defaults to standard output and exits.

=item B<--verbose>, B<-v>

Prints debugging information to standard error while operating.

=item B<--editor>, B<-e>

When specified (or when the program is called as F<xde-input-edit>),
launch the X Server settings editor.  This is the default when called as
F<xde-input-edit>.

=item B<--filename>, B<-f> I<FILENAME>

Specify the file to use as the configuration file instead of the
default.  The default is F<$XDG_CONFIG_HOME/xde/input.ini>.  This option
does not recognize C<-> as standard input: use F</dev/stdin> instead.

=back

=head1 ENVIRONMENT VARIABLES

As an XDG compatible application, B<xde-input> considers the following
environment variables when calculating the location of the user's
configuration file and the default configuration files:

=over

=item B<XDG_CONFIG_HOME>

When unspecified, defaults to F<$HOME/.config> in accordance with XDG
specifications.  B<xde-input> looks for user configuration files in
F<$XDG_CONFIG_HOME/xde/input.ini>.

=item B<XDG_CONFIG_DIRS>

When unspecified, defaults to F</etc/xdg> in accordance with XDG
specifications.  XDE will prepend the F</etc/xdg/xde> directory to this
path if it does not already exist in the path.  B<xde-input> looks for
system configuration files in F<$XDG_CONFIG_DIRS/xde/input.ini>.

=back

=head1 SIGNALS

B<xde-input> intercepts and acts upon the following signals:

=over

=item B<$SIG{HUP}>

When B<xde-input> receives a C<$SIG{HUP}> signal, it rereads the
configuration from the X Server.

=item B<$SIG{TERM}>

When B<xde-input> receives a C<$SIG{TERM}> signal, it rereads the
configuration from the X Server, and writes the current settings into
the configuration file if possible before exitting gracefully.

=back

=head1 CONFIGURATION FILE

When B<xde-input> starts it reads the configuration file located in
F<$XDG_CONFIG_HOME/xde/input.ini> unless the configuration file was
overridden with options on the command line.  If the configuration file
does not exist, it copies the first file it finds in
F<@XDG_CONFIG_DIRS/xde/input.ini>.  When no configuration file is found
at all, it does not change settings and will write the current
configuration to the configuration file.

B<xde-input> monitors the configuration file for changes and applies
changes when detected.  Note that the file parser is not very robust,
so when editting by hand, avoid syntax errors.

The configuration file is F<.ini> format and has several sections
containing the following information as follows:

=over

=item DPMS

 [DPMS]
 OffTimeout=600
 PowerLevel=DPMSModeOn
 StandbyTimeout=600
 State=1
 SuspendTimeout=660

=item Keyboard

 [Keyboard]
 AutoRepeats=00FFFFFFDFFFFBBFFADFFFEFFFEDFFFF9FFFFFFFFFFFFFFFFFF7FFFFFFFFFFFF
 BellDuration=100
 BellPercent=50
 BellPitch=400
 GlobalAutoRepeat=On
 KeyClickPercent=0
 LEDMask=8192

=item Pointer

 [Pointer]
 AccelerationDenominator=10
 AccelerationNumerator=24
 Threshold=10

=item ScreenSaver

 [ScreenSaver]
 AllowExposures=Yes
 Interval=600
 PreferBlanking=Yes
 Timeout=600

=item XKeyboard

 [XKeyboard]
 AccessXFeedbackMaskEnabled=true
 AccessXKeysEnabled=false
 AccessXOptions=3119
 AccessXTimeout=120
 AccessXTimeoutMask=30
 AccessXTimeoutMaskEnabled=true
 AccessXTimeoutOptionsMask=16
 AccessXTimeoutOptionsValues=0
 AccessXTimeoutValues=0
 AudibleBellMaskEnabled=true
 BounceKeysEnabled=false
 ControlsEnabledEnabled=false
 DebounceDelay=300
 GroupsWrapEnabled=false
 IgnoreGroupLockMaskEnabled=true
 IgnoreLockModsEnabled=false
 InternalModsEnabled=false
 MouseKeysAccelEnabled=true
 MouseKeysCurve=500
 MouseKeysDelay=160
 MouseKeysDfltBtn=1
 MouseKeysEnabled=true
 MouseKeysInterval=40
 MouseKeysMaxSpeed=30
 MouseKeysTimeToMax=30
 Overlay1MaskEnabled=false
 Overlay2MaskEnabled=false
 PerKeyRepeat=00FFFFFFDFFFFBBFFADFFFEFFFEDFFFF9FFFFFFFFFFFFFFFFFF7FFFFFFFFFFFF
 PerKeyRepeatEnabled=false
 RepeatDelay=300
 RepeatInterval=12
 RepeatKeysEnabled=true
 RepeatRate=83
 SlowKeysDelay=300
 SlowKeysEnabled=false
 StickyKeysEnabled=false

=back

The package also installs by default an autostart F<.desktop> file to
autostart this program when any of the lightweight window managers
supported by XDE are loaded.

Supported lightweight window managers are: L<fluxbox(1)>,
L<blackbox(1)>, L<openbox(1)>, L<icewm(1)>, L<fvwm(1)>, and
L<wmaker(1)>.  Note, however, that although L<wmaker(1)> is capable of
managing L<xset(1)> parameters itself, it does not support all XKEYBOARD
extensions, so the default for B<XDE> is to configure window maker to
not set L<xset(1)> parameters.

=head1 EDITING INPUT SETTINGS

B<xde-input> provides a mechanism for editting settings by invoking it
using the B<--editor> option, or by invoking it as B<xde-input-edit>.
Other tools for editing input settings are L<lxinput(1)> and L<xset(1)>.
Values set with these tools are also detected and saved by B<xde-input>.
Note, however, that some versions of L<lxinput(1)> have bugs and
annoyingly incorrectly set key repeat rates (they set the rate to the
interval and intervals to the rate).

=head1 HISTORY

I wrote this tool because none of the lightweight window managers (with
the notable excpetion of WindowMaker) save or restore the L<xset(1)>
settings.  I got tired of typing C<xset r rate 300 66> every time I
entered an X Window session under L<fluxbox(1)>, so I wrote this tool.
Unfortunately, I also had to write the
L<X11::Protocol::Ext::XKEYBOARD(3pm)> extension module to change just
that: the repeat delay and rate on the keyboard.  Then, after
discovering that L<lxinput(1)> incorrectly sets the rate to the interval
(or visa versa), I had to include an input editor.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<xset(1)>,
L<lxinput(1)>,
L<XDE::Input(3pm)>,
L<X11::Protocol(3pm)>.
L<X11::Protocol::Ext::XKEYBOARD(3pm)>.

=cut

# vim: sw=4 tw=72
