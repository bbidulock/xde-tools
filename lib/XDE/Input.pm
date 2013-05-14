package XDE::Input;
use base qw(XDE::Gtk2);
use Glib qw(TRUE FALSE);
use Gtk2;
use XDE::X11;
our %Keysyms;
use X11::Keysyms '%Keysyms',qw(MISCELLANY XKB_KEYS 3270 LATIN1 LATIN2
        LATIN3 LATIN4 KATAKANA ARABIC CYRILLIC GREEK TECHNICAL SPECIAL
        PUBLISHING APL HEBREW THAI KOREAN);
use strict;
use warnings;

our %Keynames = (reverse %Keysyms);

=head1 NAME

XDE::Input -- establish and monitor X Display input settings

=head1 SYNOPSIS

 use XDE::Input;

 my $xde = XDE::Input->new();
 $xde->init;
 $xde->set_from_file($filename);
 $xde->main;

=head1 DESCRIPTION

Provides a module that runs out of the Glib::Mainloop that will set the
X Display input settings on a lightweight desktop and monitor for input
changes.  When the input setting changes, the module will record the
changes for later.

=head1 METHODS

=over

=cut

=item $xde = XDE::Input->B<new>(I<%OVERRIDES>)

Creates an instance of an XDE::Input object.  The XDE::Input module uses
the L<XDE::Context(3pm)> module as a base, so the C<%OVERRIDES> are
simply passed to the L<XDE::Context(3pm)> module.

=cut

sub new {
    return XDE::Context::new(@_);
}

=item $xde->B<setup>(I<%OVERRIDES>) => $xde

Provides the setup method that is called by L<XDE::Context(3pm)> when
the instance is created.  This examines environment variables and
initializes the L<XDE::Context(3pm)> in accordance with those
environment variables and I<%OVERRIDES>.

=cut

sub setup {
    my $self = shift;
    $self->SUPER::setup(@_);
    $self->getenv();
    return $self;
}

=item $xde->B<default>() => $xde

Called by L<XDE::Context(3pm)> to set defaults.  We need to default our
configuration file name.

=cut

sub default {
    my $self = shift;
    $self->SUPER::default(@_);
    $self->{ops}{desktop} = $self->{XDG_CURRENT_DESKTOP};
    $self->{ops}{desktop} = '' unless $self->{ops}{desktop};
    $self->{ops}{session} = $self->{ops}{desktop};
    $self->{ops}{session} = 'default' unless $self->{ops}{session};
    $self->{ops}{filename} =
        "$self->{XDG_CONFIG_HOME}/xde/$self->{ops}{session}/input.ini";
    return $self;
}

=item $xde->B<init>()

Initialization routine that is called like Gtk->init.  It establishes
the X11::Protocol connection to the X Server and determines the initial
values and settings.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    my $X = $self->{X} = XDE::X11->new();
    my $verbose = $self->{ops}{verbose};
    $X->init($self);
    foreach (qw(DPMS XFree86-Misc XKEYBOARD MIT-SCREEN-SAVER)) {
        $X->init_extension($_) or
            warn "Cannot initialize $_ extension.";
    }
    if ($X->{ext}{XKEYBOARD}) {
        $X->XkbSelectEvents('UseCoreKbd', XkbControlsNotify=>'selectAll');
    }
    return $self;
}

=item $xde->B<term>()

Processes events that should occur on graceful termination of the
process.  Must be called by the creator of this instance and should be
called from $SIG{TERM} rocesures or other signal handler.  B<XDE::Input>
needs to write its configuration back to the configuration file before
exit.

=cut

sub term {
    my $self = shift;
    my $X = $self->{X};
    $self->get_input(); # grab it once before exiting
    $X->term(@_);
    my $verbose = $self->{ops}{verbose};
    my $config = $self->{config};
    my $filename = $self->{ops}{filename};
    printf STDERR "Writing to filename '%s' on exit\n", $filename;
    open(my $fh,">",$filename) or return;
    foreach my $section (sort keys %$config) {
        printf $fh "\n[%s]\n", $section;
        my $fields = $config->{$section};
        foreach my $label (sort keys %$fields) {
            printf $fh "%s=%s\n", $label, $fields->{$label};
        }
    }
    close($fh);
    return $self;
}

=item $xde->B<main>()

Run the main loop and wait for events, detecting when X Display input
configuration has changed and record the changes.

=cut

sub main {
    my $self = shift;
    my $X = $self->{X};
    $X->xde_process_errors;
    $X->xde_process_events;
    my $ret = $self->SUPER::main;
    $self->term();
    return $ret;
}

=item $xde->B<set_input>($filename)

Perform the actions necessary to establisha configuraiton files and set
inputs from the configuration file specified by $self->{ops}{filename}
or the optional argument I<$filename>.

=cut

sub set_input {
    my $self = shift;
}

=item $xde->B<get_input>()

Read the value of all the input settings from the X Server and save them
in the configuration for later writing to the configuration file.

=cut

sub get_input {
    my $self = shift;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    my $config = $self->{config};
    $config = $self->{config} = {
        Keyboard=>{},
        Pointer=>{},
        ScreenSaver=>{},
    } unless $config;
    my %vals = $X->GetKeyboardControl;
    if ($verbose) {
        print STDERR "Keyboard Control:\n";
        foreach my $key (sort keys %vals) {
            my $name = $key; $name =~ s{_}{-}g;
            if ($name eq 'led-mask') {
                printf STDERR "\t%s: 0x%04x\n", $name, $vals{$key};
            }
            elsif ($name eq 'auto-repeats') {
                printf STDERR "\t%s: %s\n", $name, join(' ',map{sprintf "%02X",$_} unpack('C*',$vals{$key}));
            }
            else {
                printf STDERR "\t%s: %s\n", $name, $vals{$key};
            }
        }
    }
    my $keyboard = $config->{Keyboard};
    my %mapping = (
        key_click_percent   =>'KeyClickPercent',
        bell_percent        =>'BellPercent',
        bell_pitch          =>'BellPitch',
        bell_duration       =>'BellDuration',
        led_mask            =>'LEDMask',
        global_auto_repeat  =>'GlobalAutoRepeat',
#       auto_repeats        =>'AutoRepeats',
    );
    $config->{Keyboard}{$mapping{$_}} = $vals{$_} foreach (keys %mapping);
    $config->{Keyboard}{AutoRepeats} =
        join('',map{sprintf"%02X",$_}unpack('C*',$vals{auto_repeats}));

    my @vals = $X->GetPointerControl;
    if ($verbose) {
        printf STDERR "Pointer Control:\n";
        printf STDERR "\t%s: %s\n", 'acceleration-numerator', $vals[0];
        printf STDERR "\t%s: %s\n", 'acceleration-denominator', $vals[1];
        printf STDERR "\t%s: %s\n", 'threshold', $vals[2];
    }
    $config->{Pointer}{AccelerationNumerator} = $vals[0];
    $config->{Pointer}{AccelerationDenominator} = $vals[1];
    $config->{Pointer}{Threshold} = $vals[2];

    @vals = $X->GetScreenSaver;

    if ($verbose) {
        printf STDERR "Screen Saver:\n";
        printf STDERR "\t%s: %s\n", 'timeout', $vals[0];
        printf STDERR "\t%s: %s\n", 'interval', $vals[1];
        printf STDERR "\t%s: %s\n", 'prefer-blanking', $vals[2];
        printf STDERR "\t%s: %s\n", 'allow-exposures', $vals[3];
    }
    $config->{ScreenSaver}{Timeout} = $vals[0];
    $config->{ScreenSaver}{Interval} = $vals[1];
    $config->{ScreenSaver}{PreferBlanking} = $vals[2];
    $config->{ScreenSaver}{AllowExposures} = $vals[3];

    @vals = $X->GetFontPath;

    if ($verbose) {
        printf STDERR "Font Path:\n";
        foreach (@vals) {
            printf STDERR "\t%s\n", $_;
        }
    }
#    $config->{Font}{FontPath} = join(':',@vals);

    @vals = $X->GetModifierMapping;
    if ($verbose) {
        my @tmp = @vals;
        printf STDERR "Modifier Mapping: (%d)\n", scalar(@tmp);
        foreach my $mod (qw(Shift Lock Control Mod1 Mod2 Mod3 Mod4 Mod5)) {
            printf STDERR "\t%s: %s\n",
                $mod, join(',',map {sprintf "0x%x",$_} @{shift @tmp});
        }
    }
#    foreach my $mod (qw(Shift Lock Control Mod1 Mod2 Mod3 Mod4 Mod5)) {
#        $config->{Keyboard}{$mod} =
#            join('',map{sprintf"%02X",$_}@{shift @vals});
#    }

    my $count = $X->max_keycode - $X->min_keycode + 1;
    (@vals) = $X->GetKeyboardMapping($X->min_keycode,$count);
    if ($verbose) {
        my @tmp = @vals;
        printf STDERR "Keyboard Mapping: (%d)\n", scalar(@tmp);
        for (my $i=$X->min_keycode;$i<=$X->max_keycode;$i++) {
            printf STDERR "\t0x%x: %s\n", $i,
                join(',',map{$_?($Keynames{$_}?$Keynames{$_}:sprintf "0x%x",$_):()}@{shift @tmp});
        }
    }

    if ($X->{ext}{DPMS}) {
        my ($major,$minor) = $X->DPMSGetVersion;
        my ($power_level,$state) = $X->DPMSInfo;
        my ($standby,$suspend,$off) = $X->DPMSGetTimeouts;
        if ($verbose) {
            print STDERR "DPMS:\n";
            printf STDERR "\tDPMS Version: %d.%d\n", $major,$minor;
            printf STDERR "\tpower-level: %s\n", $power_level;
            printf STDERR "\tstate: %s\n", $state;
            printf STDERR "\tstandby-timeout: %s\n", $standby;
            printf STDERR "\tsuspend-timeout: %s\n", $suspend;
            printf STDERR "\toff-timeout: %s\n", $off;
        }
        $config->{DPMS}{PowerLevel} = $power_level;
        $config->{DPMS}{State} = $state;
        $config->{DPMS}{StandbyTimeout} = $standby;
        $config->{DPMS}{SuspendTimeout} = $suspend;
        $config->{DPMS}{OffTimeout} = $off;
    }

    if ($X->{ext}{'XFree86-Misc'}) {
        my ($major,$minor) = $X->XF86MiscQueryVersion;
        my ($suspend,$off) = $X->XF86MiscGetSaver(0);
        my %mouse = $X->XF86MiscGetMouseSettings;
        my @keybd = $X->XF86MiscGetKbdSettings;
        print STDERR "XF86 Misc:\n";
        printf STDERR "\tXF86-Misc Version: %d.%d\n", $major,$minor;
        printf STDERR "\tsuspend-time: %s\n", $suspend;
        printf STDERR "\toff-time: %s\n", $off;
        printf STDERR "\ttype: %s\n", $keybd[0];
        printf STDERR "\trate: %s\n", $keybd[1];
        printf STDERR "\tdelay: %s\n", $keybd[2];
        printf STDERR "\tservnumlock: %s\n", $keybd[3];
        foreach (sort keys %mouse) {
            my $name = $_; $name =~ s{_}{-}g;
            printf STDERR "\t%s: %s\n", $name,$mouse{$_};
        }
    }
    if ($X->{ext}{XKEYBOARD}) {
        @vals = $X->XkbGetControls('UseCoreKbd');
        if ($verbose) {
            print STDERR "Keyboard:\n";
            printf STDERR "\t%s: %s\n", 'DeviceID', $vals[0];
            printf STDERR "\t%s: %s\n", 'mouseKeysDfltBtn', $vals[1];
            printf STDERR "\t%s: %s\n", 'repeatDelay', $vals[10];
            printf STDERR "\t%s: %s\n", 'repeatInterval', $vals[11];
            printf STDERR "\t%s: %s\n", 'slowKeysDelay', $vals[12];
            printf STDERR "\t%s: %s\n", 'debounceDelay', $vals[13];
            printf STDERR "\t%s: %s\n", 'mouseKeysDelay', $vals[14];
            printf STDERR "\t%s: %s\n", 'mouseKeysInterval', $vals[15];
            printf STDERR "\t%s: %s\n", 'mouseKeysTimeToMax', $vals[16];
            printf STDERR "\t%s: %s\n", 'mouseKeysMaxSpeed', $vals[17];
            printf STDERR "\t%s: %s\n", 'mouseKeysCurve', $vals[18];
            my %h = $X->unpack_mask(XkbControl=>$vals[25]);
            printf STDERR "\t%s: %s\n", 'enabledControls', join(',',keys %h);
            printf STDERR "\t%s: %s\n", 'perKeyRepeat',
                join('',map{sprintf"%02X",$_}unpack('C*',$vals[26]));
        }
        $config->{XKeyboard}{RepeatDelay} = $vals[10];
        $config->{XKeyboard}{RepeatInterval} = $vals[11];
        $config->{XKeyboard}{RepeatRate} = int(1000/$vals[11]);
        $config->{XKeyboard}{SlowKeysDelay} = $vals[12];
        $config->{XKeyboard}{DebounceDelay} = $vals[13];
        $config->{XKeyboard}{MouseKeysDelay} = $vals[14];
        $config->{XKeyboard}{MouseKeysInterval} = $vals[15];
        $config->{XKeyboard}{MouseKeysTimeToMax} = $vals[16];
        $config->{XKeyboard}{MouseKeysMaxSpeed} = $vals[17];
        $config->{XKeyboard}{MouseKeysCurve} = $vals[18];
        my %h = $X->unpack_mask(XkbControl=>$vals[25]);
        foreach (@{$X->{ext_const}{XkbControl}}) {
            next unless $_;
            $config->{XKeyboard}{$_.'Enabled'} =
                $h{$_} ? 'true' : 'false';
        }
    }
    if ($X->{ext}{MIT_SCREEN_SAVER}) {
        @vals = $X->MitScreenSaverQueryInfo($X->root);
        if ($verbose) {
            print STDERR "MIT Screen Saver:\n";
            printf STDERR "\t%s: %s\n", 'state', $vals[0];
            printf STDERR "\t%s: 0x%08x\n", 'window', $vals[1];
            printf STDERR "\t%s: %s\n", 'till_or_since', $vals[2];
            printf STDERR "\t%s: %s\n", 'idle', $vals[3];
            printf STDERR "\t%s: %s\n", 'event_mask', $vals[4];
            printf STDERR "\t%s: %s\n", 'kind', $vals[5];
        }
    }
}

=item $xde->B<event_handler_XkbEventNotify>(I<$event>)

Internal event handler for the XDE::Input module for handling
C<XkbEventNotify> events.  We register with the B<XKEYBOARD> extension
for C<XkbControlsNotify> events so that we can detect when some other
tool changes the settings.  The response to this is to just go out and
gather all of the settings again.

=cut

sub event_handler_XkbEventNotify {
    my ($self,$e) = @_;
    return unless $e->{xkb_code} eq 'XkbControlsNotify';
    $self->get_input();
    return;
}

=item $xde->B<event_handler>(I<$event>)

Internal event handler for the XDE::Input module.  This is an
L<X11::Protocol(3pm)> handler that is invoked either by direct requests
made of the X11::Protocol object ($self->{X}) or by Glib::Mainloop when
it triggers an input watcher on the X11::Protocol::Connection.
C<$event> is the unpacked X11::Protocol event.

=cut

sub event_handler {
    my ($self,%e) = @_;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    print STDERR "-----------------\nReceived event: ", join(',',%e), "\n" if $verbose;
    my $handler = "event_handler_$e{name}";
    print STDERR "Handler is: '$handler'\n" if $verbose;
    if ($self->can($handler)) {
	$self->$handler(\%e);
	return;
    }
    print STDERR "Discarding event...\n" if $verbose;
}

=item $xde->B<error_handler>(I<$X>,I<$error>)

Internal error handler for the XDE::Input module.  This is an
L<X11::Protocol(3pm)> handler that is invoked either by direct requests
made of the X11::Protocol object ($self->{X}) or by Glib::Mainloop when
it triggers an input watcher on the X11::Protocol::Connection.
C<$error> is the packed error message.

=cut

sub error_handler {
    my ($self,$e) = @_;
    my $X = $self->{X};
    print STDERR "Received error: \n",
	  $X->format_error_msg($e), "\n";
}

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

1;

# vim: sw=4 tw=72
