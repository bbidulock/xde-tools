package XDE::Input;
use base qw(XDE::Dual);
our %Keysyms;
use X11::Keysyms '%Keysyms',qw(MISCELLANY XKB_KEYS 3270 LATIN1 LATIN2
	LATIN3 LATIN4 KATAKANA ARABIC CYRILLIC GREEK TECHNICAL SPECIAL
	PUBLISHING APL HEBREW THAI KOREAN);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

our %Keynames = (reverse %Keysyms);

=head1 NAME

XDE::Input -- establish and monitor X Display input settings

=head1 SYNOPSIS

 use XDE::Input;

 my $xde = XDE::Input->new(%OVERRIDES,ops=>\%ops);

 $xde->getenv();
 $xde->init;
 $xde->set_from_file($filename);
 $xde->main;

=head1 DESCRIPTION

Provides a module that runs out of the L<Glib::Mainloop(3pm)> that will
set the X Display input settings on a lightweight desktop and monitor
for input changes.  When the input setting changes, the module will
record the changes for later.

=head1 METHODS

=over

=cut

=item $xde = XDE::Input->B<new>(I<%OVERRIDES>,ops=>\I<%ops>)

Creates an instance of an XDE::Input object.  The XDE::Input module uses
the L<XDE::Context(3pm)> module as a base, so the C<%OVERRIDES> are
simply passed to the L<XDE::Context(3pm)> module.  When an options hash,
I<%ops>, is passed to the method, it is initialized with default option
values.

XDE::Input recognizes the following options:

=over

=item verbose => $boolean

When true, output diagnostic information to standard error during
operation.

=item desktop => $desktop

Specifies the desktop environment (e.g. C<FLUXBOX>).  When unspecified,
defaults will be set from environment variables.

=item session => $session

Specifies the desktop session (e.g. C<fluxbox>).  When unspecified,
defaults will be set from C<desktop> or environment variables.

=item filename => $filename

Specifies the file name of the configuration file from which to read
default settings.  When unspecified, defaults to
F<$XDG_CONFIG_HOME/xde/$session/input.ini>.

=back

Additional options may be recognized by the superior L<XDE::Context(3pm)>
object.

=cut

sub new {
    return XDE::Gtk2::new(@_);
}

=item $xde->B<defaults>() => $xde

Internal method that can be used for multiple inheritance instead of the
B<default> method.  Establishes our default configuration file name.

=cut

sub defaults {
    my $self = shift;
    $self->{ops}{desktop} = $self->{XDG_CURRENT_DESKTOP};
    $self->{ops}{desktop} = '' unless $self->{ops}{desktop};
    $self->{ops}{session} = $self->{ops}{desktop};
    $self->{ops}{session} = 'default' unless $self->{ops}{session};
    if (1) {
	$self->{ops}{filename} = "$self->{XDG_CONFIG_HOME}/xde/input.ini"
	    unless $self->{ops}{filename};
    } else {
	$self->{ops}{filename} =
	    "$self->{XDG_CONFIG_HOME}/xde/$self->{ops}{session}/input.ini"
	    unless $self->{ops}{filename};
    }
    return $self;
}

=item $xde->B<_init>() => $xde

Performs initialization for just this module.  Called after
L<XDE::Dual(3pm)> is fully initialized.

=cut

sub _init {
    my $self = shift;
    my $X = $self->{X};
    $X->init_extensions;
#    foreach (qw(DPMS XFree86-Misc XKEYBOARD MIT-SCREEN-SAVER)) {
#	$X->init_extension($_) or
#	    warn "Cannot initialize $_ extension.";
#    }
    if ($X->{ext}{XKEYBOARD}) {
	$X->XkbSelectEvents('UseCoreKbd', XkbControlsNotify=>'selectAll');
    }
    $self->create_window;
    return $self;
}

=item $xde->B<_term>()

Performs termination for just this module.  Called before
C<XDE::X11-E<gt>term()> is called.

B<XDE::Input> needs to write its configuration back to the configuration
file before exit.

=cut

sub _term {
    my $self = shift;
    my $X = $self->{X};
    $self->destroy_window;
    $self->get_input(); # grab it once before exiting
    my $v = $self->{ops}{verbose};
    my $config = $self->{config};
    my $f = $self->{ops}{filename};
    $f = "$self->{XDG_CONFIG_HOME}/xde/input.ini" unless $f;
    my $d = $f; $d =~ s{/[^/]*$}{}; system("mkdir -p \"$d\"") unless -d $d;
    printf STDERR "Writing to filename '%s' on exit\n", $f;
    open(my $fh,">",$f) or return;
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

=item $xde->B<get_input>()

Read the value of all the input settings from the X Server and save them
in the configuration for later writing to the configuration file.

=cut

sub get_input {
    my $self = shift;
    my $X = $self->{X};
    my $v = $self->{ops}{verbose};
    my $config = $self->{config};
    $config = $self->{config} = {
	Keyboard=>{},
	Pointer=>{},
	ScreenSaver=>{},
    } unless $config;
    my %vals = $X->GetKeyboardControl;
    if ($v) {
	print STDERR "Keyboard Control:\n";
	foreach my $key (sort keys %vals) {
	    my $name = $key; $name =~ s{_}{-}g;
	    if ($name eq 'led_mask') {
		printf STDERR "\t%s: 0x%04x\n", $name, $vals{$key};
	    }
	    elsif ($name eq 'auto_repeats') {
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
    if ($v) {
	printf STDERR "Pointer Control:\n";
	printf STDERR "\t%s: %s\n", 'acceleration-numerator', $vals[0];
	printf STDERR "\t%s: %s\n", 'acceleration-denominator', $vals[1];
	printf STDERR "\t%s: %s\n", 'threshold', $vals[2];
    }
    $config->{Pointer}{AccelerationNumerator} = $vals[0];
    $config->{Pointer}{AccelerationDenominator} = $vals[1];
    $config->{Pointer}{Threshold} = $vals[2];

    @vals = $X->GetScreenSaver;

    if ($v) {
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

    if ($v) {
	printf STDERR "Font Path:\n";
	foreach (@vals) {
	    printf STDERR "\t%s\n", $_;
	}
    }
#    $config->{Font}{FontPath} = join(':',@vals);

    @vals = $X->GetModifierMapping;
    if ($v) {
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
    if ($v) {
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
	if ($v) {
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
	if ($v) {
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
	$config->{XKeyboard}{MouseKeysDfltBtn} = $vals[1];
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
        $config->{XKeyboard}{AccessXOptions} = $vals[19];
        $config->{XKeyboard}{AccessXTimeout} = $vals[20];
        $config->{XKeyboard}{AccessXTimeoutOptionsMask} = $vals[21];
        $config->{XKeyboard}{AccessXTimeoutOptionsValues} = $vals[22];
        $config->{XKeyboard}{AccessXTimeoutMask} = $vals[23];
        $config->{XKeyboard}{AccessXTimeoutValues} = $vals[24];
	my %h = $X->unpack_mask(XkbControl=>$vals[25]);
	foreach (@{$X->{ext_const}{XkbControl}}) {
	    next unless $_;
	    $config->{XKeyboard}{$_.'Enabled'} =
		$h{$_} ? 'true' : 'false';
	}
	$config->{XKeyboard}{PerKeyRepeat} =
	    join('',map{sprintf"%02X",$_}unpack('C*',$vals[26]));
    }
    if ($X->{ext}{MIT_SCREEN_SAVER}) {
	@vals = $X->MitScreenSaverQueryInfo($X->root);
	if ($v) {
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

=item $xde->B<read_input>(I<$filename>)

Read the input settings from the configuration file.  Simple and direct.

=cut

sub read_input {
    my ($self,$f) = @_;
    my $v = $self->{ops}{verbose};
    $f = $self->{ops}{filename} unless $f and -f $f;
    $f = "$self->{XDG_CONFIG_HOME}/xde/input.ini" unless $f and -f $f;
    print STDERR "Checking file '$f'\n" if $f and $v;
    return unless $f and -f $f;
    print STDERR "Found file '$f'\n" if $v;
    open(my $fh,"<",$f) or return;
    print STDERR "Reading file '$f'\n" if $v;
    my $config = $self->{config};
    $config = $self->{config} = {} unless $config;
    my $section;
    while (<$fh>) { chomp;
	next if m{^\s*\#}; # comment
	if (m{^\[([^]]*)\]}) {
	    $section = $1;
	    print STDERR "Starting section '$section'\n" if $v;
	}
	elsif ($section and m{^([^=]*)=([^[:cntrl:]]*)}) {
	    $config->{$section}{$1} = $2;
	    print STDERR "Reading field $1=$2\n" if $v;
	}
    }
    close($fh);
}

=item $xde->B<set_input>(I<$filename>)

Perform the actions necessary to establish configuration files and set
inputs from the configuration file specified by
C<$self-E<gt>{ops}{filename}> or the optional argument C<$filename>.

=cut

sub set_input {
    my ($self,$f) = @_;
    my $X = $self->{X};
    my $v = $self->{ops}{verbose};
    $self->read_input($f);
    my $c = $self->{config};
    if (my $k = $c->{Keyboard}) {
        my %vals = ();
        my %mapping = (
                KeyClickPercent   =>q/key_click_percent/,
                BellPercent       =>q/bell_percent/,
                BellPitch         =>q/bell_pitch/,
                BellDuration      =>q/bell_duration/,
        );
        foreach (keys %mapping) {
            $vals{$mapping{$_}} = $k->{$_}
                if defined $k->{$_};
        }
        if ($v) {
            print STDERR "Setting:\n";
            printf STDERR "\tkey_click_percent = %s\n", $vals{key_click_percent};
            printf STDERR "\tbell_percent      = %s\n", $vals{bell_percent};
            printf STDERR "\tbell_pitch        = %s\n", $vals{bell_pitch};
            printf STDERR "\tbell_duration     = %s\n", $vals{bell_duration};
        }
        $X->ChangeKeyboardControl(%vals);
        $X->flush;
        #
        # 'led_mask' cannot be set.  'led_mask' must be broken down into
        # 'led' and 'led_mode' and the $X->ChangeKeyboardControl function
        # must be performed for each 'led' and 'led_mode' combination.
        #
        my $l = $k->{LEDMask};
        if (defined $l and $l ne '') {
            if ($l == 0) {
                print STDERR "Setting all LEDs 'Off'\n" if $v;
                $X->ChangeKeyboardControl(led_mode=>'Off');
            }
            elsif ($l == 0xffff) {
                print STDERR "Setting all LEDs 'On'\n" if $v;
                $X->ChangeKeyboardControl(led_mode=>'On');
            }
            else {
                for (my $i=0;$i<32;$i++,$l>>=1) {
                    my $m = ($l&0x1)?'On':'Off';
                    printf STDERR "Setting LED %d '%s'\n",$i+1,$m if $v;
                    $X->ChangeKeyboardControl(led=>$i+1,led_mode=>$m);
                }
            }
            $X->flush;
        }
        #
        # 'auto_repeats' cannot be set.  'auto_repeats' must be broken down
        # into 'key' and 'auto_repeat_mode' and the
        # $X->ChangeKeyboardControl function must be performed for each
        # 'key' and 'auto_repeat_mode' combination.
        #
	if (0) {
	    for (my $i=8;$i<256;$i++) {
		$X->ChangeKeyboardControl(key=>$i,auto_repeat_mode=>'On');
	    }
	    $X->flush;
	} else {
	    if (my $a = $k->{AutoRepeats}) {
		my ($i,$k) = (0,0);
		foreach my $l (unpack('C*',pack('H*',$a))) {
		    for (my $j=0;$j<8;$j++,$l>>=1,$k++) {
			my $m = ($l & 0x1) ? 1 : 0;
			printf STDERR "Setting key %d '%s'\n", $k, $m if $v;
			next if $k < 8;
			$X->ChangeKeyboardControl(key=>$k,auto_repeat_mode=>$m);
		    }
		    $i++;
		}
		$X->flush;
	    }
	}
        #
        # 'global_auto_repeat' cannot be set.  'auto_repeat_mode' must be
        # set without a 'key' code provided in the message.
        #
        if (my $g = $k->{GlobalAutoRepeat}) {
            $X->ChangeKeyboardControl(auto_repeat_mode=>$g);
            $X->flush;
        }
    }
    if (my $p = $c->{Pointer}) {
        my $do_accel =
            ($p->{AccelerationNumerator} and $p->{AccelerationDenominator}) ? 1 : 0;
        my $do_thresh =
            $p->{Threshold} ? 1 : 0;
        $X->ChangePointerControl($do_accel,$do_thresh,
            $do_accel ? $p->{AccelerationNumerator} : 0,
            $do_accel ? $p->{AccelerationDenominator} : 0,
            $do_thresh ? $p->{Threshold} : 0);
        $X->flush;
    }
    if (my $s = $c->{ScreenSaver}) {
        $X->SetScreenSaver( $s->{Timeout}, $s->{Interval},
            $s->{PreferBlanking}, $s->{AllowExposures});
        $X->flush;
    }
    if (my $d = $c->{DPMS} and $X->{ext}{DPMS}) {
        if (exists $d->{StandbyTimeout}) {
            $X->DPMSSetTimeouts(
                $d->{StandbyTimeout},
                $d->{SuspendTimeout},
                $d->{OffTimeout});
            $X->flush;
        }
        if (defined $d->{State}) {
            if ($d->{State}) {
                $X->DPMSEnable();
            } else {
                $X->DPMSDisable();
            }
            $X->flush;
        }
    }
    if (my $k = $c->{XKeyboard} and $X->{ext}{XKEYBOARD}) {
        foreach (qw(RepeatDelay RepeatInterval SlowKeysDelay
                    DebounceDelay MouseKeysDelay MouseKeysInterval
                    MouseKeysTimeToMax MouseKeysMaxSpeed
                    MouseKeysCurve)) {
            $k->{$_} = 0 unless $k->{$_};
        }
	my @affect = ();
	my @enable = ();
	foreach (qw(RepeatKeys SlowKeys BounceKeys StickyKeys MouseKeys MouseKeysAccel)) {
	    $k->{$_.'Enabled'} = 'false' unless $k->{$_.'Enabled'};
	    push @enable, $_ if $k->{$_.'Enabled'} =~ m{true|yes|on|1}i;
	    push @affect, $_;
	}
	my $affect = $X->pack_mask(XkbBoolCtrl=>\@affect);
	my $enable = $X->pack_mask(XkbBoolCtrl=>\@enable);
	my $cntrls = $X->pack_mask(XkbControl=>
		[qw(RepeatKeys SlowKeys BounceKeys StickyKeys MouseKeys
		    MouseKeysAccel PerKeyRepeat ControlsEnabled)]);
        $X->XkbSetControls(
	    'UseCoreKbd',
	    0=>0,
	    0=>0,
	    0=>0,
	    0=>0,
	    $k->{MouseKeysDfltBtn},
	    0,
	    0,
            $affect=>$enable,
	    $cntrls,
            $k->{RepeatDelay},
            $k->{RepeatInterval},
            $k->{SlowKeysDelay},
            $k->{DebounceDelay},
            $k->{MouseKeysDelay},
            $k->{MouseKeysInterval},
            $k->{MouseKeysTimeToMax},
            $k->{MouseKeysMaxSpeed},
            $k->{MouseKeysCurve},
            0, # $k->{AccessXTimeout},
            0, # $k->{AccessXTimeoutMask},
            0, # $k->{AccessXTimeoutValues},
            0, # $k->{AccessXTimeoutOptionsMask},
            0, # $k->{AccessXTimeoutOptionsValues},
	    pack('H*',$k->{PerKeyRepeat}),
#pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'),
	    );
        $X->flush;
    }
    $X->flush;
    $X->xde_process_errors;
    $X->xde_purge_queue;
}

=item $xde->B<create_window>()

Create a window for editing input setting values.

=cut

sub create_window {
    my $self = shift;
    my $X = $self->{X};
    my $c = $self->{config};
    my ($w,$v,$p,$h,$l,$f,$u,$n,$q,$s);

    $w = $self->{w} = Gtk2::Window->new('toplevel');
    $w->set_wmclass('xde-input','Xde-input');
    $w->set_title('XDE X Input Control');
    $w->set_gravity('center');
    $w->set_type_hint('dialog');
    $w->set_border_width(10);
    $w->set_skip_pager_hint(FALSE);
    $w->set_skip_taskbar_hint(FALSE);
    $w->set_position('center-always');
    $w->signal_connect(delete_event=>\&Gtk2::Widget::hide_on_delete);

    $h = Gtk2::HBox->new(FALSE,5);
    $w->add($h);
    $n = Gtk2::Notebook->new;
    $h->pack_start($n,TRUE,TRUE,0);

    $v = Gtk2::VBox->new(FALSE,5);
    $v->set_border_width(5);
    $p = $n->append_page($v,'Pointer');

    $f = Gtk2::Frame->new('Acceleration Numerator');
    $v->pack_start($f,FALSE,FALSE,0);
    $h = Gtk2::HScale->new_with_range(1,100,1);
    $h->set_draw_value(TRUE);
    $f->add($h);
    $self->{controls}{Pointer}{AccelerationNumerator} = $h;
    $h->set_tooltip_markup(qq{Set the acceleration numerator.  The effective\nacceleration factor is the numerator divided by\nthe denominator.  A typical value is 24.});
    $h->signal_connect(value_changed=>sub{
	    my ($h,$self) = @_;
	    if ($h->get_value != $self->{config}{Pointer}{AccelerationNumerator}) {
		my $X = $self->{X};
		$X->ChangePointerControl(1,0,
		    $h->get_value,
		    $self->{config}{Pointer}{AccelerationDenominator},
		    0);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    $f = Gtk2::Frame->new('Acceleration Denominator');
    $v->pack_start($f,FALSE,FALSE,0);
    $h = Gtk2::HScale->new_with_range(1,100,1);
    $h->set_draw_value(TRUE);
    $f->add($h);
    $self->{controls}{Pointer}{AccelerationDenominator} = $h;
    $h->set_tooltip_markup(qq{Set the acceleration denominator.  The effective\nacceleration factor is the numerator divided by\nthe denominator.  A typical value is 10.});
    $h->signal_connect(value_changed=>sub{
	    my ($h,$self) = @_;
	    if ($h->get_value != $self->{config}{Pointer}{AccelerationDenominator}) {
		my $X = $self->{X};
		$X->ChangePointerControl(1,0,
		    $self->{config}{Pointer}{AccelerationNumerator},
		    $h->get_value,
		    0);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    $f = Gtk2::Frame->new('Threshold');
    $v->pack_start($f,FALSE,FALSE,0);
    $h = Gtk2::HScale->new_with_range(1,100,1);
    $h->set_draw_value(TRUE);
    $f->add($h);
    $self->{controls}{Pointer}{Threshold} = $h;
    $h->set_tooltip_markup(qq{Set the number of pixels moved before acceleration\nbegins.  A typical and usable value is 10 pixels.});
    $h->signal_connect(value_changed=>sub{
	    my ($h,$self) = @_;
	    if ($h->get_value != $self->{config}{Pointer}{Threshold}) {
		my $X = $self->{X};
		$X->ChangePointerControl(0,1, 0, 0, $h->get_value);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    $v = Gtk2::VBox->new(FALSE,5);
    $v->set_border_width(5);
    $p = $n->append_page($v,'Keyboard');

    $f = Gtk2::Frame->new;
    $v->pack_start($f,FALSE,FALSE,0);
    $u = Gtk2::CheckButton->new('Global Auto Repeat');
    $f->add($u);
    $self->{controls}{Keyboard}{GlobalAutoRepeat} = $u;
    $u->set_tooltip_markup(qq{When enabled, all keyboard keys will auto-repeat;\notherwise, only per-key autorepeat settings are\nobserved.});
    $u->signal_connect(toggled=>sub{
	    my ($u,$self) = @_;
	    my $X = $self->{X};
	    $X->ChangeKeyboardControl(auto_repeat_mode=>($u->get_active)?'On':'Off');
	    $X->flush;
	    $self->get_input;
	    $self->edit_set_values;
	    $X->xde_process_errors;
	    $X->xde_purge_queue;
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    $f = Gtk2::Frame->new('Key Click Percent (%)');
    $v->pack_start($f,FALSE,FALSE,0);
    $h = Gtk2::HScale->new_with_range(0,100,1);
    $h->set_draw_value(TRUE);
    $f->add($h);
    $self->{controls}{Keyboard}{KeyClickPercent} = $h;
    $h->set_tooltip_markup(qq{Set the key click volume as a percentage of\nmaximum volume: from 0% to 100%.});
    $h->signal_connect(value_changed=>sub{
	    my ($h,$self) = @_;
	    if ($h->get_value != $self->{config}{Keyboard}{KeyClickPercent}) {
		my $X = $self->{X};
		$X->ChangeKeyboardControl(key_click_percent=>$h->get_value);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    $f = Gtk2::Frame->new('Bell Percent (%)');
    $v->pack_start($f,FALSE,FALSE,0);
    $h = Gtk2::HScale->new_with_range(0,100,1);
    $h->set_draw_value(TRUE);
    $f->add($h);
    $self->{controls}{Keyboard}{BellPercent} = $h;
    $h->set_tooltip_markup(qq{Set the bell volume as a percentage of\nmaximum volume: from 0% to 100%.});
    $h->signal_connect(value_changed=>sub{
	    my ($h,$self) = @_;
	    if ($h->get_value != $self->{config}{Keyboard}{BellPercent}) {
		my $X = $self->{X};
		$X->ChangeKeyboardControl(bell_percent=>$h->get_value);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    $f = Gtk2::Frame->new('Bell Pitch (Hz)');
    $v->pack_start($f,FALSE,FALSE,0);
    $h = Gtk2::HScale->new_with_range(60,2000,20);
    $h->set_draw_value(TRUE);
    $f->add($h);
    $self->{controls}{Keyboard}{BellPitch} = $h;
    $h->set_tooltip_markup(qq{Set the bell pitch in Hertz.  Usable values\nare from 200 to 800 Hz.});
    $h->signal_connect(value_changed=>sub{
	    my ($h,$self) = @_;
	    if ($h->get_value != $self->{config}{Keyboard}{BellPitch}) {
		my $X = $self->{X};
		$X->ChangeKeyboardControl(bell_pitch=>$h->get_value);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    $f = Gtk2::Frame->new('Bell Duration (milliseconds)');
    $v->pack_start($f,FALSE,FALSE,0);
    $h = Gtk2::HScale->new_with_range(10,500,10);
    $h->set_draw_value(TRUE);
    $f->add($h);
    $self->{controls}{Keyboard}{BellDuration} = $h;
    $h->set_tooltip_markup(qq{Set the bell duration in milliseconds.  Usable\nvalues are 100 to 300 milliseconds.});
    $h->signal_connect(value_changed=>sub{
	    my ($h,$self) = @_;
	    if ($h->get_value != $self->{config}{Keyboard}{BellDuration}) {
		my $X = $self->{X};
		$X->ChangeKeyboardControl(bell_duration=>$h->get_value);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    $f = Gtk2::Frame->new;
    $v->pack_start($f,FALSE,FALSE,0);
    $u = Gtk2::Button->new('Ring Bell');
    $u->signal_connect(clicked=>sub{
	    $X->Bell(0); $X->flush;
	    return Gtk2::EVENT_PROPAGATE;
    });
    $f->add($u);
    $u->set_tooltip_markup(qq{Press to ring bell.});

    if ($X->{ext}{XKEYBOARD}) {
	$v = Gtk2::VBox->new(FALSE,5);
	$v->set_border_width(5);
	$p = $n->append_page($v,'XKeyboard');

	$s = Gtk2::Notebook->new;
	$v->pack_start($s,TRUE,TRUE,0);

	$v = Gtk2::VBox->new(FALSE,5);
	$v->set_border_width(5);
	$p = $s->append_page($v,'Repeat Keys');

	$f = Gtk2::Frame->new;
	$v->pack_start($f,FALSE,FALSE,0);
	$u = Gtk2::CheckButton->new('Repeat Keys Enabled');
	$f->add($u);
	$self->{controls}{XKeyboard}{RepeatKeysEnabled} = $u;
	$u->set_tooltip_markup(qq{When enabled, all keyboard keys will auto-repeat;\notherwise, only per-key autorepeat settings are\nobserved.});
	$u->signal_connect(toggled=>sub{
		my ($u,$self) = @_;
		my $X = $self->{X};
		my $affect = $X->pack_mask(XkbBoolCtrl=>['RepeatKeys']);
		my $enable = $u->get_active ? $affect : 0;
		my $cntrls = $X->pack_mask(XkbControl=>[qw(RepeatKeys ControlsEnabled)]);
		my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		#my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		$X->XkbSetControls(
		    'UseCoreKbd',	# 0 deviceSpec
		    0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
		    0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
		    0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
		    0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
		    0,			# 9 mouseKeysDfltBtn
		    0,			# 10 groupsWrap
		    0,			# 11 accessXOptions
		    $affect=>$enable,	# 12-13 affectEnabledControls=>enabledControls
		    $cntrls,		# 14 changeControls
		    $self->{config}{XKeyboard}{RepeatDelay},	# 15 repeatDelay
		    $self->{config}{XKeyboard}{RepeatInterval},	# 16 repeatInterval
		    0,			# 17 slowKeysDelay
		    0,			# 18 debounceDelay
		    0,			# 19 mouseKeysDelay
		    0,			# 20 mouseKeysInterval
		    0,			# 21 mouseKeysTimeToMax
		    0,			# 22 mouseKeysMaxSpeed
		    0,			# 23 mouseKeysCurve
		    0,			# 24 accessXTimeout
		    0,			# 25 accessXTimeoutMask
		    0,			# 26 accessXTimeoutValues
		    0,			# 27 accessXTimeoutOptionsMask
		    0,			# 28 accessXTimeoutOptionsValues
		    $perkey,		# 29 perKeyRepeat
		);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Repeat Delay (milliseconds)');
	$v->pack_start($f,FALSE,FALSE,0);
	$h = Gtk2::HScale->new_with_range(0,1000,10);
	$h->set_draw_value(TRUE);
	$f->add($h);
	$self->{controls}{XKeyboard}{RepeatDelay} = $h;
	$h->set_tooltip_markup(qq{Set the delay after key press before auto-repeat\nbegins in milliseconds.  Usable values are from\n250 to 500 milliseconds.});
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		if ($h->get_value != $self->{config}{XKeyboard}{RepeatDelay}) {
		    my $X = $self->{X};
		    my $cntrls = $X->pack_mask(XkbControl=>['RepeatKeys']);
		    my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		    #my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		    $X->XkbSetControls(
			'UseCoreKbd',	# 0 deviceSpec
			0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
			0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
			0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
			0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
			0,		# 9 mouseKeysDfltBtn
			0,		# 10 groupsWrap
			0,		# 11 accessXOptions
			0=>0,		# 12-13 affectEnabledControls=>enabledControls
			$cntrls,	# 14 changeControls
			$h->get_value,	# 15 repeatDelay
			$self->{config}{XKeyboard}{RepeatInterval},	# 16 repeatInterval
			0,		# 17 slowKeysDelay
			0,		# 18 debounceDelay
			0,		# 19 mouseKeysDelay
			0,		# 20 mouseKeysInterval
			0,		# 21 mouseKeysTimeToMax
			0,		# 22 mouseKeysMaxSpeed
			0,		# 23 mouseKeysCurve
			0,		# 24 accessXTimeout
			0,		# 25 accessXTimeoutMask
			0,		# 26 accessXTimeoutValues
			0,		# 27 accessXTimeoutOptionsMask
			0,		# 28 accessXTimeoutOptionsValues
			$perkey,	# 29 perKeyRepeat
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Repeat Interval (milliseconds)');
	$v->pack_start($f,FALSE,FALSE,0);
	$h = Gtk2::HScale->new_with_range(10,100,1);
	$h->set_draw_value(TRUE);
	$f->add($h);
	$self->{controls}{XKeyboard}{RepeatInterval} = $h;
	$h->set_tooltip_markup(qq{Set the interval between repeats after auto-repeat\nhas begun.  Usable values are from 10 to 100\nmilliseconds.});
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		if ($h->get_value != $self->{config}{XKeyboard}{RepeatInterval}) {
		    my $X = $self->{X};
		    my $cntrls = $X->pack_mask(XkbControl=>['RepeatKeys']);
		    my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		    #my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		    $X->XkbSetControls(
			'UseCoreKbd',	# 0 deviceSpec
			0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
			0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
			0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
			0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
			0,		# 9 mouseKeysDfltBtn
			0,		# 10 groupsWrap
			0,		# 11 accessXOptions
			0=>0,		# 12-13 affectEnabledControls=>enabledControls
			$cntrls,	# 14 changeControls
			$self->{config}{XKeyboard}{RepeatDelay},	# 15 repeatDelay
			$h->get_value,	# 16 repeatInterval
			0,		# 17 slowKeysDelay
			0,		# 18 debounceDelay
			0,		# 19 mouseKeysDelay
			0,		# 20 mouseKeysInterval
			0,		# 21 mouseKeysTimeToMax
			0,		# 22 mouseKeysMaxSpeed
			0,		# 23 mouseKeysCurve
			0,		# 24 accessXTimeout
			0,		# 25 accessXTimeoutMask
			0,		# 26 accessXTimeoutValues
			0,		# 27 accessXTimeoutOptionsMask
			0,		# 28 accessXTimeoutOptionsValues
			$perkey,	# 29 perKeyRepeat
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$v = Gtk2::VBox->new(FALSE,5);
	$v->set_border_width(5);
	$p = $s->append_page($v,'Slow Keys');

	$f = Gtk2::Frame->new;
	$v->pack_start($f,FALSE,FALSE,0);
	$u = Gtk2::CheckButton->new('Slow Keys Enabled');
	$f->add($u);
	$self->{controls}{XKeyboard}{SlowKeysEnabled} = $u;
	$u->set_tooltip_markup(qq{When checked, slow keys are enabled;\notherwise slow keys are disabled.\nWhen enabled, keys pressed and released\nbefore the slow keys delay expires will\nbe ignored.});
	$u->signal_connect(toggled=>sub{
		my ($u,$self) = @_;
		my $X = $self->{X};
		my $affect = $X->pack_mask(XkbBoolCtrl=>['SlowKeys']);
		my $enable = $u->get_active ? $affect : 0;
		my $cntrls = $X->pack_mask(XkbControl=>[qw(SlowKeys ControlsEnabled)]);
		my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		#my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		$X->XkbSetControls(
		    'UseCoreKbd',	# 0 deviceSpec
		    0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
		    0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
		    0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
		    0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
		    0,			# 9 mouseKeysDfltBtn
		    0,			# 10 groupsWrap
		    0,			# 11 accessXOptions
		    $affect=>$enable,	# 12-13 affectEnabledControls=>enabledControls
		    $cntrls,		# 14 changeControls
		    0,			# 15 repeatDelay
		    0,			# 16 repeatInterval
		    $self->{config}{XKeyboard}{SlowKeysDelay}, # 17 slowKeysDelay
		    0,			# 18 debounceDelay
		    0,			# 19 mouseKeysDelay
		    0,			# 20 mouseKeysInterval
		    0,			# 21 mouseKeysTimeToMax
		    0,			# 22 mouseKeysMaxSpeed
		    0,			# 23 mouseKeysCurve
		    0,			# 24 accessXTimeout
		    0,			# 25 accessXTimeoutMask
		    0,			# 26 accessXTimeoutValues
		    0,			# 27 accessXTimeoutOptionsMask
		    0,			# 28 accessXTimeoutOptionsValues
		    $perkey,		# 29 perKeyRepeat
		);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Slow Keys Delay (milliseconds)');
	$v->pack_start($f,FALSE,FALSE,0);
	$h = Gtk2::HScale->new_with_range(0,1000,1);
	$h->set_draw_value(TRUE);
	$f->add($h);
	$self->{controls}{XKeyboard}{SlowKeysDelay} = $h;
	$h->set_tooltip_markup(qq{Set the duration in milliseconds for which a\nkey must remain pressed to be considered\na key press.  Usable values are 100 to 300\nmilliseconds.});
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		if ($h->get_value != $self->{config}{XKeyboard}{SlowKeysDelay}) {
		    my $X = $self->{X};
		    my $cntrls = $X->pack_mask(XkbControl=>[qw(SlowKeys)]);
		    my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		    #my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		    $X->XkbSetControls(
			'UseCoreKbd',	# 0 deviceSpec
			0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
			0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
			0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
			0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
			0,		# 9 mouseKeysDfltBtn
			0,		# 10 groupsWrap
			0,		# 11 accessXOptions
			0=>0,		# 12-13 affectEnabledControls=>enabledControls
			$cntrls,	# 14 changeControls
			0,		# 15 repeatDelay
			0,		# 16 repeatInterval
			$h->get_value,	# 17 slowKeysDelay
			0,		# 18 debounceDelay
			0,		# 19 mouseKeysDelay
			0,		# 20 mouseKeysInterval
			0,		# 21 mouseKeysTimeToMax
			0,		# 22 mouseKeysMaxSpeed
			0,		# 23 mouseKeysCurve
			0,		# 24 accessXTimeout
			0,		# 25 accessXTimeoutMask
			0,		# 26 accessXTimeoutValues
			0,		# 27 accessXTimeoutOptionsMask
			0,		# 28 accessXTimeoutOptionsValues
			$perkey,	# 29 perKeyRepeat
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$v = Gtk2::VBox->new(FALSE,5);
	$v->set_border_width(5);
	$p = $s->append_page($v,'Bounce Keys');

	$f = Gtk2::Frame->new;
	$v->pack_start($f,FALSE,FALSE,0);
	$u = Gtk2::CheckButton->new('Bounce Keys Enabled');
	$f->add($u);
	$self->{controls}{XKeyboard}{BounceKeysEnabled} = $u;
	$u->set_tooltip_markup(qq{When checked, keys that are repeatedly\npressed within the debounce delay will be\nignored; otherwise, keys are not debounced.});
	$u->signal_connect(toggled=>sub{
		my ($u,$self) = @_;
		my $X = $self->{X};
		my $affect = $X->pack_mask(XkbBoolCtrl=>['BounceKeys']);
		my $enable = $u->get_active ? $affect : 0;
		my $cntrls = $X->pack_mask(XkbControl=>[qw(BounceKeys ControlsEnabled)]);
		my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		#my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		$X->XkbSetControls(
		    'UseCoreKbd',   # 0 deviceSpec
		    0=>0,	    # 1-2 affectInternalRealMods=>internalRealMods
		    0=>0,	    # 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
		    0=>0,	    # 5-6 affectInternalVirtualMods=>internalVirtualMods
		    0=>0,	    # 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
		    0,		    # 9 mouseKeysDfltBtn
		    0,		    # 10 groupsWrap
		    0,		    # 11 accessXOptions
		    $affect=>$enable, # 12-13 affectEnabledControls=>enabledControls
		    $cntrls,	    # 14 changeControls
		    0,		    # 15 repeatDelay
		    0,		    # 16 repeatInterval
		    0,		    # 17 slowKeysDelay
		    $self->{config}{XKeyboard}{DebounceDelay}, # 18 debounceDelay
		    0,		    # 19 mouseKeysDelay
		    0,		    # 20 mouseKeysInterval
		    0,		    # 21 mouseKeysTimeToMax
		    0,		    # 22 mouseKeysMaxSpeed
		    0,		    # 23 mouseKeysCurve
		    0,		    # 24 accessXTimeout
		    0,		    # 25 accessXTimeoutMask
		    0,		    # 26 accessXTimeoutValues
		    0,		    # 27 accessXTimeoutOptionsMask
		    0,		    # 28 accessXTimeoutOptionsValues
		    $perkey,	    # 29 perKeyRepeat
		);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Debounce Delay (milliseconds)');
	$v->pack_start($f,FALSE,FALSE,0);
	$h = Gtk2::HScale->new_with_range(0,1000,1);
	$h->set_draw_value(TRUE);
	$f->add($h);
	$self->{controls}{XKeyboard}{DebounceDelay} = $h;
	$h->set_tooltip_markup(qq{Ignores repeated key presses and releases\nthat occur within the debounce delay after\nthe key was released.  Usable values are\n300 milliseconds.});
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		if ($h->get_value != $self->{config}{XKeyboard}{DebounceDelay}) {
		    my $X = $self->{X};
		    my $cntrls = $X->pack_mask(XkbControl=>[qw(BounceKeys)]);
		    my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		    #my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		    $X->XkbSetControls(
			'UseCoreKbd',   # 0 deviceSpec
			0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
			0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
			0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
			0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
			0,		# 9 mouseKeysDfltBtn
			0,		# 10 groupsWrap
			0,		# 11 accessXOptions
			0=>0,		# 12-13 affectEnabledControls=>enabledControls
			$cntrls,	# 14 changeControls
			0,		# 15 repeatDelay
			0,		# 16 repeatInterval
			0,		# 17 slowKeysDelay
			$h->get_value,	# 18 debounceDelay
			0,		# 19 mouseKeysDelay
			0,		# 20 mouseKeysInterval
			0,		# 21 mouseKeysTimeToMax
			0,		# 22 mouseKeysMaxSpeed
			0,		# 23 mouseKeysCurve
			0,		# 24 accessXTimeout
			0,		# 25 accessXTimeoutMask
			0,		# 26 accessXTimeoutValues
			0,		# 27 accessXTimeoutOptionsMask
			0,		# 28 accessXTimeoutOptionsValues
			$perkey,	# 29 perKeyRepeat
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$v = Gtk2::VBox->new(FALSE,5);
	$v->set_border_width(5);
	$p = $s->append_page($v,'Sticky Keys');

	$f = Gtk2::Frame->new;
	$v->pack_start($f,FALSE,FALSE,0);
	$u = Gtk2::CheckButton->new('Sticky Keys Enabled');
	$f->add($u);
	$self->{controls}{XKeyboard}{StickyKeysEnabled} = $u;
	$u->set_tooltip_markup(qq{When checked, sticky keys are enabled;\notherwise sticky keys are disabled.\nWhen enabled, modifier keys will stick\nwhen pressed and released until a non-\nmodifier key is pressed.});
	$u->signal_connect(toggled=>sub{
		my ($u,$self) = @_;
		my $X = $self->{X};
		my $affect = $X->pack_mask(XkbBoolCtrl=>[qw(StickyKeys)]);
		my $enable = $u->get_active ? $affect : 0;
		my $cntrls = $X->pack_mask(XkbControl=>[qw(StickyKeys ControlsEnabled)]);
		my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		#my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		$X->XkbSetControls(
		    'UseCoreKbd',   # 0 deviceSpec
		    0=>0,	    # 1-2 affectInternalRealMods=>internalRealMods
		    0=>0,	    # 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
		    0=>0,	    # 5-6 affectInternalVirtualMods=>internalVirtualMods
		    0=>0,	    # 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
		    0,		    # 9 mouseKeysDfltBtn
		    0,		    # 10 groupsWrap
		    0,		    # 11 accessXOptions
		    $affect=>$enable, # 12-13 affectEnabledControls=>enabledControls
		    $cntrls,	    # 14 changeControls
		    0,		    # 15 repeatDelay
		    0,		    # 16 repeatInterval
		    0,		    # 17 slowKeysDelay
		    0,		    # 18 debounceDelay
		    0,		    # 19 mouseKeysDelay
		    0,		    # 20 mouseKeysInterval
		    0,		    # 21 mouseKeysTimeToMax
		    0,		    # 22 mouseKeysMaxSpeed
		    0,		    # 23 mouseKeysCurve
		    0,		    # 24 accessXTimeout
		    0,		    # 25 accessXTimeoutMask
		    0,		    # 26 accessXTimeoutValues
		    0,		    # 27 accessXTimeoutOptionsMask
		    0,		    # 28 accessXTimeoutOptionsValues
		    $perkey,	    # 29 perKeyRepeat
		);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$v = Gtk2::VBox->new(FALSE,5);
	$v->set_border_width(5);
	$p = $s->append_page($v,'Mouse Keys');

	$f = Gtk2::Frame->new;
	$v->pack_start($f,FALSE,FALSE,0);
	$u = Gtk2::CheckButton->new('Mouse Keys Enabled');
	$f->add($u);
	$self->{controls}{XKeyboard}{MouseKeysEnabled} = $u;
	$u->set_tooltip_markup(qq{When checked, mouse keys are enabled;\notherwise they are disabled.  Mouse\nkeys permit operating the pointer using\nonly the keyboard.});
	$u->signal_connect(toggled=>sub{
		my ($u,$self) = @_;
		my $X = $self->{X};
		my $affect = $X->pack_mask(XkbBoolCtrl=>['MouseKeys']);
		my $enable = $u->get_active ? $affect : 0;
		my $cntrls = $X->pack_mask(XkbControl=>[qw(MouseKeys ControlsEnabled)]);
		my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		#my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		$X->XkbSetControls(
		    'UseCoreKbd',	# 0 deviceSpec
		    0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
		    0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
		    0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
		    0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
		    $self->{config}{XKeyboard}{MouseKeysDfltBtn}, # 9 mouseKeysDfltBtn
		    0,			# 10 groupsWrap
		    0,			# 11 accessXOptions
		    $affect=>$enable,	# 12-13 affectEnabledControls=>enabledControls
		    $cntrls,		# 14 changeControls
		    0,			# 15 repeatDelay
		    0,			# 16 repeatInterval
		    0,			# 17 slowKeysDelay
		    0,			# 18 debounceDelay
		    0,			# 19 mouseKeysDelay
		    0,			# 20 mouseKeysInterval
		    0,			# 21 mouseKeysTimeToMax
		    0,			# 22 mouseKeysMaxSpeed
		    0,			# 23 mouseKeysCurve
		    0,			# 24 accessXTimeout
		    0,			# 25 accessXTimeoutMask
		    0,			# 26 accessXTimeoutValues
		    0,			# 27 accessXTimeoutOptionsMask
		    0,			# 28 accessXTimeoutOptionsValues
		    $perkey,		# 29 perKeyRepeat
		);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
		return Gtk2::EVENT_PROPAGATE;
	},$self);
	$f = Gtk2::Frame->new;
	$v->pack_start($f,FALSE,FALSE,0);
	$q = Gtk2::HBox->new(FALSE,0);
	$f->add($q);
	$u = Gtk2::Label->new('Default Mouse Button');
	$q->pack_start($u,FALSE,FALSE,5);
	$u = Gtk2::ComboBox->new_text;
	foreach (1..8) { $u->append_text("$_") }
	$q->pack_end($u,TRUE,TRUE,0);
	$self->{controls}{XKeyboard}{MouseKeysDfltBtn} = $u;
	$u->set_tooltip_markup(qq{Select the default mouse button.});
	$u->signal_connect(changed=>sub{
		my ($u,$self) = @_;
		if ($u->get_active_text != $self->{config}{XKeyboard}{MouseKeysDfltBtn}) {
		    my $X = $self->{X};
		    my $cntrls = $X->pack_mask(XkbControl=>[qw(MouseKeys)]);
		    my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		    #my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		    $X->XkbSetControls(
			'UseCoreKbd',	# 0 deviceSpec
			0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
			0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
			0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
			0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
			$u->get_active_text, # 9 mouseKeysDfltBtn
			0,		# 10 groupsWrap
			0,		# 11 accessXOptions
			0=>0,		# 12-13 affectEnabledControls=>enabledControls
			$cntrls,	# 14 changeControls
			0,		# 15 repeatDelay
			0,		# 16 repeatInterval
			0,		# 17 slowKeysDelay
			0,		# 18 debounceDelay
			0,		# 19 mouseKeysDelay
			0,		# 20 mouseKeysInterval
			0,		# 21 mouseKeysTimeToMax
			0,		# 22 mouseKeysMaxSpeed
			0,		# 23 mouseKeysCurve
			0,		# 24 accessXTimeout
			0,		# 25 accessXTimeoutMask
			0,		# 26 accessXTimeoutValues
			0,		# 27 accessXTimeoutOptionsMask
			0,		# 28 accessXTimeoutOptionsValues
			$perkey,	# 29 perKeyRepeat
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new;
	$v->pack_start($f,FALSE,FALSE,0);
	$u = Gtk2::CheckButton->new('Mouse Keys Accel Enabled');
	$f->add($u);
	$self->{controls}{XKeyboard}{MouseKeysAccelEnabled} = $u;
	$u->set_tooltip_markup(qq{When checked, mouse key acceleration\nis enabled; otherwise it is disabled.});
	$u->signal_connect(toggled=>sub{
		my ($u,$self) = @_;
		my $X = $self->{X};
		my $affect = $X->pack_mask(XkbBoolCtrl=>[qw(MouseKeysAccel)]);
		my $enable = $u->get_active ? $affect : 0;
		my $cntrls = $X->pack_mask(XkbControl=>[qw(MouseKeysAccess ControlsEnabled)]);
		my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		#my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		$X->XkbSetControls(
		    'UseCoreKbd',	# 0 deviceSpec
		    0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
		    0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
		    0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
		    0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
		    0,			# 9 mouseKeysDfltBtn
		    0,			# 10 groupsWrap
		    0,			# 11 accessXOptions
		    $affect=>$enable,	# 12-13 affectEnabledControls=>enabledControls
		    $cntrls,		# 14 changeControls
		    0,			# 15 repeatDelay
		    0,			# 16 repeatInterval
		    0,			# 17 slowKeysDelay
		    0,			# 18 debounceDelay
		    $self->{config}{XKeyboard}{MouseKeysDelay},	    # 19 mouseKeysDelay
		    $self->{config}{XKeyboard}{MouseKeysInterval},  # 20 mouseKeysInterval
		    $self->{config}{XKeyboard}{MouseKeysTimeToMax}, # 21 mouseKeysTimeToMax
		    $self->{config}{XKeyboard}{MouseKeysMaxSpeed},  # 22 mouseKeysMaxSpeed
		    $self->{config}{XKeyboard}{MouseKeysCurve},	    # 23 mouseKeysCurve
		    0,			# 24 accessXTimeout
		    0,			# 25 accessXTimeoutMask
		    0,			# 26 accessXTimeoutValues
		    0,			# 27 accessXTimeoutOptionsMask
		    0,			# 28 accessXTimeoutOptionsValues
		    $perkey,		# 29 perKeyRepeat
		);
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Mouse Keys Delay (milliseconds)');
	$v->pack_start($f,FALSE,FALSE,0);
	$h = Gtk2::HScale->new_with_range(0,1000,1);
	$h->set_draw_value(TRUE);
	$f->add($h);
	$self->{controls}{XKeyboard}{MouseKeysDelay} = $h;
	$h->set_tooltip_markup(qq{Specifies the amount of time in milliseconds\nbetween the initial key press and the first\nrepeated motion event.  A usable value is\nabout 160 milliseconds.});
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		if ($h->get_value != $self->{config}{XKeyboard}{MouseKeysDelay}) {
		    my $X = $self->{X};
		    my $cntrls = $X->pack_mask(XkbControl=>[qw(MouseKeysAccel)]);
		    my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		    #my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		    $X->XkbSetControls(
			'UseCoreKbd',	# 0 deviceSpec
			0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
			0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
			0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
			0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
			0,		# 9 mouseKeysDfltBtn
			0,		# 10 groupsWrap
			0,		# 11 accessXOptions
			0=>0,		# 12-13 affectEnabledControls=>enabledControls
			$cntrls,	# 14 changeControls
			0,		# 15 repeatDelay
			0,		# 16 repeatInterval
			0,		# 17 slowKeysDelay
			0,		# 18 debounceDelay
			$h->get_value,	# 19 mouseKeysDelay
			$self->{config}{XKeyboard}{MouseKeysInterval},  # 20 mouseKeysInterval
			$self->{config}{XKeyboard}{MouseKeysTimeToMax}, # 21 mouseKeysTimeToMax
			$self->{config}{XKeyboard}{MouseKeysMaxSpeed},  # 22 mouseKeysMaxSpeed
			$self->{config}{XKeyboard}{MouseKeysCurve},	# 23 mouseKeysCurve
			0,		# 24 accessXTimeout
			0,		# 25 accessXTimeoutMask
			0,		# 26 accessXTimeoutValues
			0,		# 27 accessXTimeoutOptionsMask
			0,		# 28 accessXTimeoutOptionsValues
			$perkey,	# 29 perKeyRepeat
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Mouse Keys Interval (milliseconds)');
	$v->pack_start($f,FALSE,FALSE,0);
	$h = Gtk2::HScale->new_with_range(0,1000,1);
	$h->set_draw_value(TRUE);
	$f->add($h);
	$self->{controls}{XKeyboard}{MouseKeysInterval} = $h;
	$h->set_tooltip_markup(qq{Specifies the amout of time in milliseconds\nbetween repeated mouse key events.  Usable\nvalues are from 10 to 40 milliseconds.});
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		if ($h->get_value != $self->{config}{XKeyboard}{MouseKeysInterval}) {
		    my $X = $self->{X};
		    my $cntrls = $X->pack_mask(XkbControl=>[qw(MouseKeysAccel)]);
		    my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		    #my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		    $X->XkbSetControls(
			'UseCoreKbd',	# 0 deviceSpec
			0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
			0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
			0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
			0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
			0,		# 9 mouseKeysDfltBtn
			0,		# 10 groupsWrap
			0,		# 11 accessXOptions
			0=>0,		# 12-13 affectEnabledControls=>enabledControls
			$cntrls,	# 14 changeControls
			0,		# 15 repeatDelay
			0,		# 16 repeatInterval
			0,		# 17 slowKeysDelay
			0,		# 18 debounceDelay
			$self->{config}{XKeyboard}{MouseKeysDelay},	# 19 mouseKeysDelay
			$h->get_value,  # 20 mouseKeysInterval
			$self->{config}{XKeyboard}{MouseKeysTimeToMax}, # 21 mouseKeysTimeToMax
			$self->{config}{XKeyboard}{MouseKeysMaxSpeed},  # 22 mouseKeysMaxSpeed
			$self->{config}{XKeyboard}{MouseKeysCurve},	# 23 mouseKeysCurve
			0,		# 24 accessXTimeout
			0,		# 25 accessXTimeoutMask
			0,		# 26 accessXTimeoutValues
			0,		# 27 accessXTimeoutOptionsMask
			0,		# 28 accessXTimeoutOptionsValues
			$perkey,	# 29 perKeyRepeat
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Mouse Keys Time to Maximum (count)');
	$v->pack_start($f,FALSE,FALSE,0);
	$h = Gtk2::HScale->new_with_range(1,100,1);
	$h->set_draw_value(TRUE);
	$f->add($h);
	$self->{controls}{XKeyboard}{MouseKeysTimeToMax} = $h;
	$h->set_tooltip_markup(qq{Sets the number of key presses after which the\nmouse key acceleration will be at the maximum.\nUsable values are from 10 to 40.});
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		if ($h->get_value != $self->{config}{XKeyboard}{MouseKeysTimeToMax}) {
		    my $X = $self->{X};
		    my $cntrls = $X->pack_mask(XkbControl=>[qw(MouseKeysAccel)]);
		    my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		    #my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		    $X->XkbSetControls(
			'UseCoreKbd',	# 0 deviceSpec
			0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
			0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
			0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
			0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
			0,		# 9 mouseKeysDfltBtn
			0,		# 10 groupsWrap
			0,		# 11 accessXOptions
			0=>0,		# 12-13 affectEnabledControls=>enabledControls
			$cntrls,	# 14 changeControls
			0,		# 15 repeatDelay
			0,		# 16 repeatInterval
			0,		# 17 slowKeysDelay
			0,		# 18 debounceDelay
			$self->{config}{XKeyboard}{MouseKeysDelay},	# 19 mouseKeysDelay
			$self->{config}{XKeyboard}{MouseKeysInterval},  # 20 mouseKeysInterval
			$h->get_value, # 21 mouseKeysTimeToMax
			$self->{config}{XKeyboard}{MouseKeysMaxSpeed},  # 22 mouseKeysMaxSpeed
			$self->{config}{XKeyboard}{MouseKeysCurve},	# 23 mouseKeysCurve
			0,		# 24 accessXTimeout
			0,		# 25 accessXTimeoutMask
			0,		# 26 accessXTimeoutValues
			0,		# 27 accessXTimeoutOptionsMask
			0,		# 28 accessXTimeoutOptionsValues
			$perkey,	# 29 perKeyRepeat
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Mouse Keys Maximum Speed (multiplier)');
	$v->pack_start($f,FALSE,FALSE,0);
	$h = Gtk2::HScale->new_with_range(0,100,1);
	$h->set_draw_value(TRUE);
	$f->add($h);
	$self->{controls}{XKeyboard}{MouseKeysMaxSpeed} = $h;
	$h->set_tooltip_markup(qq{Specifies the multiplier for mouse events at\nthe maximum speed.  Usable values are\nfrom 10 to 40.});
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		if ($h->get_value != $self->{config}{XKeyboard}{MouseKeysMaxSpeed}) {
		    my $X = $self->{X};
		    my $cntrls = $X->pack_mask(XkbControl=>[qw(MouseKeysAccel)]);
		    my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		    #my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		    $X->XkbSetControls(
			'UseCoreKbd',	# 0 deviceSpec
			0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
			0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
			0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
			0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
			0,		# 9 mouseKeysDfltBtn
			0,		# 10 groupsWrap
			0,		# 11 accessXOptions
			0=>0,		# 12-13 affectEnabledControls=>enabledControls
			$cntrls,	# 14 changeControls
			0,		# 15 repeatDelay
			0,		# 16 repeatInterval
			0,		# 17 slowKeysDelay
			0,		# 18 debounceDelay
			$self->{config}{XKeyboard}{MouseKeysDelay},	# 19 mouseKeysDelay
			$self->{config}{XKeyboard}{MouseKeysInterval},  # 20 mouseKeysInterval
			$self->{config}{XKeyboard}{MouseKeysTimeToMax}, # 21 mouseKeysTimeToMax
			$h->get_value,  # 22 mouseKeysMaxSpeed
			$self->{config}{XKeyboard}{MouseKeysCurve},	# 23 mouseKeysCurve
			0,		# 24 accessXTimeout
			0,		# 25 accessXTimeoutMask
			0,		# 26 accessXTimeoutValues
			0,		# 27 accessXTimeoutOptionsMask
			0,		# 28 accessXTimeoutOptionsValues
			$perkey,	# 29 perKeyRepeat
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Mouse Keys Curve (factor)');
	$v->pack_start($f,FALSE,FALSE,0);
	$h = Gtk2::HScale->new_with_range(-1000,1000,50);
	$h->set_draw_value(TRUE);
	$f->add($h);
	$self->{controls}{XKeyboard}{MouseKeysCurve} = $h;
	$h->set_tooltip_markup(qq{Sets the curve ramp up to maximum acceleration.\nNegative values ramp sharply to the maximum;\npositive values ramp slowly.  Usable values are\nfrom -1000 to 1000.});
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		if ($h->get_value != $self->{config}{XKeyboard}{MouseKeysCurve}) {
		    my $X = $self->{X};
		    my $cntrls = $X->pack_mask(XkbControl=>[qw(MouseKeysAccel)]);
		    my $perkey = pack('H*',$self->{config}{XKeyboard}{PerKeyRepeat});
		    #my $perkey = pack('H*','00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
		    $X->XkbSetControls(
			'UseCoreKbd',	# 0 deviceSpec
			0=>0,		# 1-2 affectInternalRealMods=>internalRealMods
			0=>0,		# 3-4 affectIgnoreLockRealMods=>ignoreLockRealMods
			0=>0,		# 5-6 affectInternalVirtualMods=>internalVirtualMods
			0=>0,		# 7-8 affectIgnoreLockVirtualMods=>ignoreLockVirtualMods
			0,		# 9 mouseKeysDfltBtn
			0,		# 10 groupsWrap
			0,		# 11 accessXOptions
			0=>0,		# 12-13 affectEnabledControls=>enabledControls
			$cntrls,	# 14 changeControls
			0,		# 15 repeatDelay
			0,		# 16 repeatInterval
			0,		# 17 slowKeysDelay
			0,		# 18 debounceDelay
			$self->{config}{XKeyboard}{MouseKeysDelay},	# 19 mouseKeysDelay
			$self->{config}{XKeyboard}{MouseKeysInterval},  # 20 mouseKeysInterval
			$self->{config}{XKeyboard}{MouseKeysTimeToMax}, # 21 mouseKeysTimeToMax
			$self->{config}{XKeyboard}{MouseKeysMaxSpeed},  # 22 mouseKeysMaxSpeed
			$h->get_value,	# 23 mouseKeysCurve
			0,		# 24 accessXTimeout
			0,		# 25 accessXTimeoutMask
			0,		# 26 accessXTimeoutValues
			0,		# 27 accessXTimeoutOptionsMask
			0,		# 28 accessXTimeoutOptionsValues
			$perkey,	# 29 perKeyRepeat
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);
    }

    $v = Gtk2::VBox->new(FALSE,5);
    $v->set_border_width(5);
    $p = $n->append_page($v,'Screen Saver');

    $f = Gtk2::Frame->new('Timeout (seconds)');
    $v->pack_start($f,FALSE,FALSE,0);
    $q = Gtk2::VBox->new(FALSE,0);
    $f->add($q);
    $h = Gtk2::HScale->new_with_range(0,3600,30);
    $h->set_draw_value(TRUE);
    $q->pack_start($h,FALSE,FALSE,0);
    $u = Gtk2::Button->new('Activate Screen Saver');
    $q->pack_start($u,FALSE,FALSE,0);
    $u->signal_connect(clicked=>sub{
	    my ($u,$self) = @_;
	    my $X = $self->{X};
	    $X->ForceScreenSaver('Activate');
	    $X->flush;
	    return Gtk2::EVENT_PROPAGATE;
    },$self);
    $self->{controls}{ScreenSaver}{Timeout} = $h;
    $h->set_tooltip_markup(qq{Specify the time in seconds that pointer and keyboard\nmust be idle before the screensaver is activated.\nTypical values are 600 seconds (10 minutes).  Set\nto zero to disable the screensaver.});
    $h->signal_connect(value_changed=>sub{
	    my ($h,$self) = @_;
	    if ($h->get_value != $self->{config}{ScreenSaver}{Timeout}) {
		my $X = $self->{X};
		$X->SetScreenSaver(
		    $h->get_value,
		    $self->{config}{ScreenSaver}{Interval},
		    $self->{config}{ScreenSaver}{PreferBlanking},
		    $self->{config}{ScreenSaver}{AllowExposures});
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    $f = Gtk2::Frame->new('Interval (seconds)');
    $v->pack_start($f,FALSE,FALSE,0);
    $q = Gtk2::VBox->new(FALSE,0);
    $f->add($q);
    $h = Gtk2::HScale->new_with_range(0,3600,30);
    $h->set_draw_value(TRUE);
    $q->pack_start($h,FALSE,FALSE,0);
    $u = Gtk2::Button->new('Rotate Screen Saver');
    $q->pack_start($u,FALSE,FALSE,0);
    $u->signal_connect(clicked=>sub{
	    my ($u,$self) = @_;
	    my $X = $self->{X};
	    $X->ForceScreenSaver('Activate');
	    $X->flush;
	    return Gtk2::EVENT_PROPAGATE;
    },$self);
    $self->{controls}{ScreenSaver}{Interval} = $h;
    $h->set_tooltip_markup(qq{Specify the time in seconds after which the screen\nsaver will change (if other than blanking).  A\ntypical value is 600 seconds (10 minutes).});
    $h->signal_connect(value_changed=>sub{
	    my ($h,$self) = @_;
	    if ($h->get_value != $self->{config}{ScreenSaver}{Interval}) {
		my $X = $self->{X};
		$X->SetScreenSaver(
		    $self->{config}{ScreenSaver}{Timeout},
		    $h->get_value,
		    $self->{config}{ScreenSaver}{PreferBlanking},
		    $self->{config}{ScreenSaver}{AllowExposures});
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
	    }
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    $f = Gtk2::Frame->new;
    $v->pack_start($f,FALSE,FALSE,0);
    $u = Gtk2::CheckButton->new('Prefer Blanking');
    $f->add($u);
    $self->{controls}{ScreenSaver}{PreferBlanking} = $u;
    $u->set_tooltip_markup(qq{When checked, blank the screen instead of using\na screen saver; otherwise, use a screen saver if\nenabled.});
    $u->signal_connect(toggled=>sub{
	    my ($u,$self) = @_;
	    my $X = $self->{X};
	    my $val = $u->get_active ? 'Yes' : 'No';
	    $X->SetScreenSaver(
		$self->{config}{ScreenSaver}{Timeout},
		$self->{config}{ScreenSaver}{Interval},
		$val,
		$self->{config}{ScreenSaver}{AllowExposures});
	    $X->flush;
	    $self->get_input;
	    $self->edit_set_values;
	    $X->xde_process_errors;
	    $X->xde_purge_queue;
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    $f = Gtk2::Frame->new;
    $v->pack_start($f,FALSE,FALSE,0);
    $u = Gtk2::CheckButton->new('Allow Exposures');
    $f->add($u);
    $self->{controls}{ScreenSaver}{AllowExposures} = $u;
    $u->set_tooltip_markup(qq{When set, use a screensaver even when the server\nis not capable of peforming screen saving without\nsending exposure events to existing clients.  Not\nnormally needed nowadays.});
    $u->signal_connect(toggled=>sub{
	    my ($u,$self) = @_;
	    my $X = $self->{X};
	    my $val = $u->get_active ? 'Yes' : 'No';
	    $X->SetScreenSaver(
		$self->{config}{ScreenSaver}{Timeout},
		$self->{config}{ScreenSaver}{Interval},
		$self->{config}{ScreenSaver}{PreferBlanking},
		$val);
	    $X->flush;
	    $self->get_input;
	    $self->edit_set_values;
	    $X->xde_process_errors;
	    $X->xde_purge_queue;
	    return Gtk2::EVENT_PROPAGATE;
    },$self);

    if ($X->{ext}{DPMS}) {
	$v = Gtk2::VBox->new(FALSE,5);
	$v->set_border_width(5);
	$p = $n->append_page($v,'DPMS');

	$f = Gtk2::Frame->new;
	$v->pack_start($f,FALSE,FALSE,0);
	$u = Gtk2::CheckButton->new('DPMS Enabled');
	$f->add($u);
	$self->{controls}{DPMS}{State} = $u;
	$u->signal_connect(toggled=>sub{
		my ($u,$self) = @_;
		my $X = $self->{X};
		if ($u->get_active)
		{ $X->DPMSEnable  } else
		{ $X->DPMSDisable }
		$X->flush;
		$self->get_input;
		$self->edit_set_values;
		$X->xde_process_errors;
		$X->xde_purge_queue;
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Standby Timeout (seconds)');
	$v->pack_start($f,FALSE,FALSE,0);
	$q = Gtk2::VBox->new(FALSE,0);
	$f->add($q);
	$h = Gtk2::HScale->new_with_range(0,3600,30);
	$h->set_draw_value(TRUE);
	$q->pack_start($h,FALSE,FALSE,0);
	$u = Gtk2::Button->new('Activate Standby');
	$q->pack_start($u,FALSE,FALSE,0);
	$u->signal_connect(clicked=>sub{
		my ($u,$self) = @_;
		my $X = $self->{X};
		$X->DPMSForceLevel(q(DPMSModeStandby));
		$X->flush;
		return Gtk2::EVENT_PROPAGATE;
	},$self);
	$self->{controls}{DPMS}{StandbyTimeout} = $h;
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		$h->set_value($self->{config}{DPMS}{SuspendTimeout})
		    if $h->get_value > $self->{config}{DPMS}{SuspendTimeout};
		if ($h->get_value != $self->{config}{DPMS}{StandbyTimeout}) {
		    my $X = $self->{X};
		    $X->DPMSSetTimeouts(
			$h->get_value,
			$self->{config}{DPMS}{SuspendTimeout},
			$self->{config}{DPMS}{OffTimeout},
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Suspend Timeout (seconds)');
	$v->pack_start($f,FALSE,FALSE,0);
	$q = Gtk2::VBox->new(FALSE,0);
	$f->add($q);
	$h = Gtk2::HScale->new_with_range(0,3600,30);
	$h->set_draw_value(TRUE);
	$q->pack_start($h,FALSE,FALSE,0);
	$u = Gtk2::Button->new('Activate Suspend');
	$q->pack_start($u,FALSE,FALSE,0);
	$u->signal_connect(clicked=>sub{
		my ($u,$self) = @_;
		my $X = $self->{X};
		$X->DPMSForceLevel(q(DPMSModeSuspend));
		$X->flush;
		return Gtk2::EVENT_PROPAGATE;
	},$self);
	$self->{controls}{DPMS}{SuspendTimeout} = $h;
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		$h->set_value($self->{config}{DPMS}{OffTimeout})
		    if $h->get_value > $self->{config}{DPMS}{OffTimeout};
		$h->set_value($self->{config}{DPMS}{StandbyTimeout})
		    if $h->get_value < $self->{config}{DPMS}{StandbyTimeout};
		if ($h->get_value != $self->{config}{DPMS}{SuspendTimeout}) {
		    my $X = $self->{X};
		    $X->DPMSSetTimeouts(
			$self->{config}{DPMS}{StandbyTimeout},
			$h->get_value,
			$self->{config}{DPMS}{OffTimeout},
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);

	$f = Gtk2::Frame->new('Off Timeout (seconds)');
	$v->pack_start($f,FALSE,FALSE,0);
	$q = Gtk2::VBox->new(FALSE,0);
	$f->add($q);
	$h = Gtk2::HScale->new_with_range(0,3600,30);
	$h->set_draw_value(TRUE);
	$q->pack_start($h,FALSE,FALSE,0);
	$u = Gtk2::Button->new('Activate Off');
	$q->pack_start($u,FALSE,FALSE,0);
	$u->signal_connect(clicked=>sub{
		my ($u,$self) = @_;
		my $X = $self->{X};
		$X->DPMSForceLevel(q(DPMSModeOff));
		$X->flush;
		return Gtk2::EVENT_PROPAGATE;
	},$self);
	$self->{controls}{DPMS}{OffTimeout} = $h;
	$h->signal_connect(value_changed=>sub{
		my ($h,$self) = @_;
		$h->set_value($self->{config}{DPMS}{SuspendTimeout})
		    if $h->get_value < $self->{config}{DPMS}{SuspendTimeout};
		if ($h->get_value != $self->{config}{DPMS}{OffTimeout}) {
		    my $X = $self->{X};
		    $X->DPMSSetTimeouts(
			$self->{config}{DPMS}{StandbyTimeout},
			$self->{config}{DPMS}{SuspendTimeout},
			$h->get_value,
		    );
		    $X->flush;
		    $self->get_input;
		    $self->edit_set_values;
		    $X->xde_process_errors;
		    $X->xde_purge_queue;
		}
		return Gtk2::EVENT_PROPAGATE;
	},$self);
    }

}

sub destroy_window {
    my $self = shift;
    my $w = $self->{w};
    delete $self->{controls};
    $w->destroy;
}

sub edit_set_values {
    my $self = shift;
    my $X = $self->{X};
    my $c = $self->{config};
    my $x = $self->{controls};
    my ($h,$u);
    $h = $x->{Pointer}{AccelerationNumerator};
    $h->set_value($c->{Pointer}{AccelerationNumerator});
    $h = $x->{Pointer}{AccelerationDenominator};
    $h->set_value($c->{Pointer}{AccelerationDenominator});
    $h = $x->{Pointer}{Threshold};
    $h->set_value($c->{Pointer}{Threshold});

    $h = $x->{Keyboard}{KeyClickPercent};
    $h->set_value($c->{Keyboard}{KeyClickPercent});
    $h = $x->{Keyboard}{BellPercent};
    $h->set_value($c->{Keyboard}{BellPercent});
    $h = $x->{Keyboard}{BellPitch};
    $h->set_value($c->{Keyboard}{BellPitch});
    $h = $x->{Keyboard}{BellDuration};
    $h->set_value($c->{Keyboard}{BellDuration});
    $u = $x->{Keyboard}{GlobalAutoRepeat};
    $u->set_active($c->{Keyboard}{GlobalAutoRepeat} =~ m{true|yes|on|1}i ? 1 : 0);

    if ($X->{ext}{XKEYBOARD}) {
	$u = $x->{XKeyboard}{RepeatKeysEnabled};
	$u->set_active($c->{XKeyboard}{RepeatKeysEnabled} =~ m{true|yes|on|1}i ? 1 : 0);
	$h = $x->{XKeyboard}{RepeatDelay};
	$h->set_value($c->{XKeyboard}{RepeatDelay});
	$h = $x->{XKeyboard}{RepeatInterval};
	$h->set_value($c->{XKeyboard}{RepeatInterval});

	$u = $x->{XKeyboard}{SlowKeysEnabled};
	$u->set_active($c->{XKeyboard}{SlowKeysEnabled} =~ m{true|yes|on|1}i ? 1 : 0);
	$h = $x->{XKeyboard}{SlowKeysDelay};
	$h->set_value($c->{XKeyboard}{SlowKeysDelay});

	$u = $x->{XKeyboard}{StickyKeysEnabled};
	$u->set_active($c->{XKeyboard}{StickyKeysEnabled} =~ m{true|yes|on|1}i ? 1 : 0);

	$u = $x->{XKeyboard}{BounceKeysEnabled};
	$u->set_active($c->{XKeyboard}{BounceKeysEnabled} =~ m{true|yes|on|1}i ? 1 : 0);
	$h = $x->{XKeyboard}{DebounceDelay};
	$h->set_value($c->{XKeyboard}{DebounceDelay});

	$u = $x->{XKeyboard}{MouseKeysEnabled};
	$u->set_active($c->{XKeyboard}{MouseKeysEnabled} =~ m{true|yes|on|1}i ? 1 : 0);
	$u = $x->{XKeyboard}{MouseKeysDfltBtn};
	$u->set_active($c->{XKeyboard}{MouseKeysDfltBtn}-1);

	$u = $x->{XKeyboard}{MouseKeysAccelEnabled};
	$u->set_active($c->{XKeyboard}{MouseKeysAccelEnabled} =~ m{true|yes|on|1}i ? 1 : 0);
	$h = $x->{XKeyboard}{MouseKeysDelay};
	$h->set_value($c->{XKeyboard}{MouseKeysDelay});
	$h = $x->{XKeyboard}{MouseKeysInterval};
	$h->set_value($c->{XKeyboard}{MouseKeysInterval});
	$h = $x->{XKeyboard}{MouseKeysTimeToMax};
	$h->set_value($c->{XKeyboard}{MouseKeysTimeToMax});
	$h = $x->{XKeyboard}{MouseKeysMaxSpeed};
	$h->set_value($c->{XKeyboard}{MouseKeysMaxSpeed});
	$h = $x->{XKeyboard}{MouseKeysCurve};
	$h->set_value($c->{XKeyboard}{MouseKeysCurve});
    }

    $h = $x->{ScreenSaver}{Timeout};
    $h->set_value($c->{ScreenSaver}{Timeout});
    $h = $x->{ScreenSaver}{Interval};
    $h->set_value($c->{ScreenSaver}{Interval});
    $u = $x->{ScreenSaver}{PreferBlanking};
    $u->set_active($c->{ScreenSaver}{PreferBlanking} =~ m{true|yes|on|1}i ? 1 : 0);
    $u = $x->{ScreenSaver}{AllowExposures};
    $u->set_active($c->{ScreenSaver}{AllowExposures} =~ m{true|yes|on|1}i ? 1 : 0);

    if ($X->{ext}{DPMS}) {
	$h = $x->{DPMS}{StandbyTimeout};
	$h->set_value($c->{DPMS}{StandbyTimeout});
	$h = $x->{DPMS}{SuspendTimeout};
	$h->set_value($c->{DPMS}{SuspendTimeout});
	$h = $x->{DPMS}{OffTimeout};
	$h->set_value($c->{DPMS}{OffTimeout});
	$u = $x->{DPMS}{State};
	$u->set_active($c->{DPMS}{State} =~ m{true|yes|on|1}i ? 1 : 0);
    }

}

=item $xde->B<edit_input>()

Launch an editing window to edit the XDE::Input input settings.  This is
a notebook that has separate pages for each section of the F<input.ini>
file.  This is meant as a more complete replacement for L<lxinput(1)>.

=cut

sub edit_input {
    my $self = shift;
    $self->edit_set_values;
    my $w = $self->{w};
    $w->show_all;
}

=item $xde->B<event_handler_XkbEventNotify>(I<$event>)

Internal event handler for the XDE::Input module for handling
C<XkbEventNotify> events.  We register with the B<XKEYBOARD> extension
for C<XkbControlsNotify> events so that we can detect when some other
tool changes the settings.  The response to this is to just go out and
gather all of the settings again.

=cut

sub event_handler_XkbEventNotify {
    my ($self,$e,$X,$v) = @_;
    return unless $e->{xkb_code} eq 'XkbControlsNotify';
    $self->get_input();
    return;
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72
