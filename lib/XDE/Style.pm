package XDE::Style;
use base qw(XDE::Actions);
use Linux::Inotify2;
use strict;
use warnings;

=head1 NAME

XDE::Style - provides methods for monitoring and managing window manager styles

=head1 SYNOPSIS

 package XDE::Setbg;
 use base qw(XDE::Dual XDE::Style);

=head1 DESCRIPTION

Provides a module with methods that can be used to monitor and manage
style changes in window managers supported by L<XDE(3pm)>.

=head1 METHODS

This module provides the following methods:

=over

=cut

=item $style->B<_init>() => $style

=cut

sub _init {
    my $self = shift;
    $self->XDE::Actions::_init(@_);
    $self->get_OB_THEME;
    return $self;
}

=item $style->B<_term>() => $style

=cut

sub _term {
    my $self = shift;
    $self->XDE::Actions::_term(@_);
    return $self;
}

=back

=head2 Configuration file location

=over

=item $style->B<get_config_file>() => $filename or undef

Locates the file in which the style needs to be changed.  This depends
on the window manager: L<fluxbox(1)>, L<blackbox(1)>, L<openbox(1)>,
L<icewm(1)>, L<pekwm(1)>, L<jwm(1)>, L<wmaker(1)>, L<fvwm(1)>,
L<afterstep(1)>, L<metacity(1)>, L<wmx(1)>, none and unknown.

=cut

sub get_config_file {
    my $self = shift;
    my $v = $self->{ops}{verbose};
    print STDERR "Getting config file\n" if $v;
    my $wm = "\U$self->{wmname}\E" if $self->{wmname};
    $wm = 'NONE' unless $wm;
    my $getter = "get_config_file_$wm";
    my $sub = $self->can($getter);
    $sub = $self->can('get_config_file_UNKNOWN') unless $sub;
    my $result = &$sub($self,@_) if $sub;
    return $result;
}

=item $style->B<get_config_file_FLUXBOX>() => $filename or undef

When L<xde-session(1p)> runs, it sets the C<FLUXBOX_RCFILE> environment
variable.  L<xde-session(1p)> and associated tools always launch
L<fluxbox(1)> with a command such as:

  fluxbox ${FLUXBOX_RCFILE:+-rc $FLUXBOX_RCFILE}

The default configuration file when C<FLUXBOX_RCFILE> is not specified is
F<~/.fluxbox/init>.  The locations of other L<fluxbox(1)> configuration
files are specified by the initial configuration file.
L<xde-session(1p)> typically sets C<FLUXBOX_RCFILE> to
F<$XDG_CONFIG_HOME/fluxbox/init>.

=cut

sub get_config_file_FLUXBOX {
    my $self = shift;
    my $file = $ENV{FLUXBOX_RCFILE};
    $file = "$ENV{HOME}/.fluxbox/init" unless $file and -f $file;
    return undef unless $file and -f $file;
    return $file;
}

=item $style->B<get_config_file_BLACKBOX>() => $filename or undef

When L<xde-session(1p)> runs, it sets the C<BLACKBOX_RCFILE> environment
variable.  L<xde-session(1p)> and associated tools always launch
L<blackbox(1)> with a command such as:

  blackbox ${BLACKBOX_RCFILE:+-rc $BLACKBOX_RCFILE}

The default configuration file when C<$BLACKBOX_RCFILE> is not specified is
F<~/.blackboxrc>.  The locations of other L<blackbox(1)> configuration
files are specified by the initial configuration file.
L<xde-session(1p)> typically sets C<$BLACKBOX_RCFILE> to
F<$XDG_CONFIG_HOME/blackbox/rc>.

=cut

sub get_config_file_BLACKBOX {
    my $self = shift;
    my $file = $ENV{BLACKBOX_RCFILE};
    $file = "$ENV{HOME}/.blackboxrc" unless $file and -f $file;
    return undef unless $file and -f $file;
    return $file;
}

=item $style->B<get_config_file_OPENBOX>() => $filename or undef

When L<xde-session(1p)> runs, it sets the C<OPENBOX_RCFILE> environment
variable.  L<xde-session(1p)> and associated tools always launch
L<openbox(1)> with a command such as:

  openbox ${OPENBOX_RCFILE:+--config-file $OPENBOX_RCFILE}

The default caonfiguration file when C<OPENBOX_RCFILE> is not specified is
F<$XDG_CONFIG_HOME/openbox/rc.xml>.  The locations of other
L<openbox(1)> configuration files are specified by the initial
configuration file.  L<xde-session(1p)> typically sets C<OPENBOX_RCFILE> to
F<$XDG_CONFIG_HOME/openbox/xde-rc.xml>.

=cut

sub get_config_file_OPENBOX {
    my $self = shift;
    my $file = $ENV{OPENBOX_RCFILE};
    $file = "$self->{XDG_CONFIG_HOME}/openbox/rc.xml" unless $file;
    return undef unless $file and -f $file;
    return $file;
}

=item $style->B<get_config_file_ICEWM>() => $filename or undef

When L<xde-session(1p)> runs, it sets the C<ICEWM_PRIVCFG> environment
variable.  L<xde-session(1p)> and associated tools always launch
L<icewm(1)> with this environment variable set.  L<icewm(1)> respects
the environment variable, so no special options are required when
launching L<icewm(1)>.

The default configuration file when C<ICEWM_PRIVCFG> is not specified is
F<~/.icewm/theme>.  The locations of all L<icewm(1)> configuration files
are the same directory.  L<xde-session(1p)> typically sets
C<ICEWM_PRIVCFG> to F<$XDG_CONFIG_HOME/icewm>.

=cut

sub get_config_file_ICEWM {
    my $self = shift;
    my $file = "$ENV{ICEWM_PRIVCFG}/theme" if $ENV{ICEWM_PRIVCFG};
    $file = "$ENV{HOME}/.icewm/theme" unless $file and -f $file;
    return undef unless $file and -f $file;
    return $file;
}

=item $style->B<get_config_file_PEKWM>() => $filename or undef

When L<xde-session(1p)> runs, it sets the C<PEKWM_RCFILE> environment
variable.  L<xde-session(1p)> and associated tools always launch
L<pekwm(1)> with a command such as:

  pekwm ${PEKWM_RCFILE:+--config $PEKWM_RCFILE}

The default configuration file when C<PEKWM_RCFILE> is not specified is
F<~/.pekwm/config>.  The locations of other L<pekwm(1)> configuration
files are specified by the initial configuration file.
L<xde-session(1p)> typically sets C<PEKWM_RCFILE> to
F<$XDG_CONFIG_HOME/pekwm/config>.

=cut

sub get_config_file_PEKWM {
    my $self = shift;
    my $file = $ENV{PEKWM_RCFILE} if $ENV{PEKWM_RCFILE};
    $file = "$ENV{HOME}/.pekwm/config" unless $file and -f $file;
    return undef unless $file and -f $file;
    return $file;
}

=item $style->B<get_config_file_JWM>() => $filename or undef

When L<xde-session(1p)> runs, it sets the C<JWM_RCFILE> environment
variable.  L<xde-session(1p)> and associated tools always launch
L<jwm(1)> with a command such as:

  jwm ${JWM_RCFILE:+-rc $JWM_RCFILE}

The default configuration file when C<JWM_RCFILE> is not specified is
F<~/.jwmrc>.  The locations of other L<jwm(1)> configuraiton files are
specified by the initial configuraiton file.  L<xde-session(1p)>
typically sets C<JWM_RCFILE> to F<$XDG_CONFIG_HOME/jwm/rc>.

=cut

sub get_config_file_JWM {
    my $self = shift;
    my $file = $ENV{JWM_RCFILE} if $ENV{JWM_RCFILE};
    $file = "$ENV{HOME}/.jwmrc" unless $file and -f $file;
    return undef unless $file and -f $file;
    return $file;
}

=back

=item $style->B<get_config_file_WMAKER>() => $filename or undef

When L<xde-session(1p)> runs, it sets the C<GNUSTEP_USER_ROOT>
environment variable.  L<xde-session(1p)> and associated tools always
lanuch L<wmaker(1)> with this environment variable set.  L<wmaker(1)>
respects the environment variable, so no special options are required
when launching L<wmaker(1)>.

The default configuration file when C<GNUSTEP_USER_ROOT> is not
specified is F<~/GNUstep/Defaults/WindowMaker>.  The locations of all
L<wmaker(1)> configuration files are under the same directory.
L<xde-session(1p)> typically sets C<GNUSTEP_USER_ROOT> to
F<$XDG_CONFIG_HOME/GNUstep>.

=cut

sub get_config_file_WMAKER {
    my $self = shift;
    my $file = $ENV{GNUSTEP_USER_ROOT};
    $file = "$ENV{HOME}/$file" if $file and not $file =~ m{/};
    $file = "$ENV{HOME}/GNUstep" unless $file and -d $file;
    $file = "$file/Defaults/WindowMaker" if $file and -d $file;
    return undef unless $file and -f $file;
    return $file;
}

=item $style->B<get_config_file_FVWM>() => $filename or undef

When L<xde-session(1p)> runs, it sets the C<FVWM_USRDIR> and
C<FVWM_RCFILE> environment variables.  L<fvwm(1)> observes the
C<FVWM_USRDIR> environment variable.  Nevertheless, L<xde-session(1p)>
and associated tools always sets the C<FVWM_USRDIR> environment
variable and launches L<fvwm(1)> with a command such as:

  fvwm ${FVWM_RCFILE:+-f $FVWM_RCFILE}

The default configuration file when the C<FVWM_USRDIR> and
C<FVWM_RCFILE> environment variables are not set is F<~/.fvwm/config>.
When only C<FVWM_USRDIR> is set, the default configuration file is
F<$FVWM_USRDIR/config>.  The locations of all L<fvwm(1)> configuration
files are under F<$FVWM_USRDIR> which defaults to F<~/.fvwm>.
L<xde-session(1p)> typically sets C<FVWM_USRDIR> to
F<$XDG_CONFIG_HOME/fvwm> and C<FVWM_RCFILE> to
F<$XDG_CONFIG_HOME/fvwm/config>.

=cut

sub get_config_file_FVWM {
    my $self = shift;
    my $dir = $ENV{FVWM_USRDIR} if $ENV{FVWM_USRDIR};
    $dir = "$ENV{HOME}/.fvwm" unless $dir and -d $dir;
    my $file= $ENV{FVWM_RCFILE} if $ENV{FVWM_RCFILE};
    $file = "$dir/config" unless $file and -f $file;
    return undef unless $file and -f $file;
    return $file;
}

=item $style->B<get_config_file_AFTERSTEP>() => $filename or undef

Not yet implemented, just returns C<undef>.

=cut

sub get_config_file_AFTERSTEP {
    return undef;
}

=item $style->B<get_config_file_METACITY>() => $filename or undef

Not yet implemented, just returns C<undef>.

=cut

sub get_config_file_METACITY {
    return undef;
}

=item $style->B<get_config_file_WMX>() => $filename or undef

Not yet implemented, just returns C<undef>.

=cut

sub get_config_file_WMX {
    return undef;
}

=head2 Style setting

=over

=item $style->B<set_style>(I<@styles>) => $result

Sets the style for the window manager based on the currently running
window manager and a knowledge of how to set styles/themes for the
supported list of window managers: L<fluxbox(1)>, L<blackbox(1)>,
L<icewm(1)>, L<jwm(1)>, L<pekwm(1)>, L<fvwm(1)>, L<wmaker(1)>,
L<afterstep(1)>, L<metacity(1)>, L<wmx(1)>, none and unknown.

=cut

sub set_style {
    my $self = shift;
    my $v = $self->{ops}{verbose};
    print STDERR "Setting style\n" if $v;
    my $wm = "\U$self->{wmname}\E" if $self->{wmname};
    $wm = 'NONE' unless $wm;
    my $setter = "set_style_$wm";
    print STDERR "Setter: $setter\n" if $v;
    my $sub = $self->can($setter);
    $sub = $self->can('set_style_UNKNOWN') unless $sub;
    my $result = &$sub($self,@_) if $sub;
    return $result;
}

=item $style->B<set_style_FLUXBOX>(I<@styles>) => $result

When L<fluxbox(1)> changes the style, it writes the path to the new
style in the C<session.styleFile> resource in the file
F<$FLUXBOX_RCFILE> (default F<~/.fluxbox/init>) and then reloads the
configuration.

The C<session.styleFile> entry looks like:

 session.styleFile:	/usr/share/fluxbox/styles/Airforce

Unlike other window managers, it reloads the configuration rather than
restarting.  However, L<fluxbox(1)> has the problem that simply
reloading the configuration does not result in a change to the menu
styles (in particular just the font color), so a restart is likely
required.

Sending C<SIGUSR2> to the L<fluxbox(1)> PID provided in the
C<_BLACKBOX_PID(CARDINAL)> property on the root window will result in a
reconfigure of L<fluxbox(1)> (which is what L<fluxbox(1)> itself does
when changing styles); sending C<SIGHUP>, a restart.

Note that when L<fluxbox(1)> restarts, it does not change the
C<_NET_SUPPORTING_WM_CHECK(WINDOW)> root window property but it does
change the C<_BLACKBOX_PID(CARDINAL)> root window property, even if it
is just to replace it with the same value again.

=cut

sub set_style_FLUXBOX {
    my ($self,@styles) = @_;
    my $style;
    foreach (@styles) { if (-f $_ or -f "$_/theme.cfg") { $style = $_; last; } }
    return unless $style;
    my $file = $self->get_config_file_FLUXBOX;
    return unless $file and -f $file;
    my @lines = ();
    open(my $fh, "<", $file) or return;
    while (<$fh>) { chomp;
	if (/^session\.StyleFile:/) {
	    push @lines, "session.StyleFile:\t$style";
	} else {
	    push @lines, $_;
	}
    }
    close $fh;
    open($fh, ">", $file) or return;
    print $fh join("\n", @lines), "\n";
    close $fh;
    my $pid = $self->getWMRootPropertyInt('_BLACKBOX_PID');
    return unless $pid;
    kill 'USR2', $pid;
}

=item $style->B<set_style_BLACKBOX>(I<@styles>) => $result

When L<blackbox(1)> changes the style, it writes the path to the new
style in the C<session.styleFile> resource in the F<~/.blackboxrc> file
and then reloads the configuration.

The C<session.styleFile> entry looks like:

 session.styleFile:	/usr/share/fluxbox/styles/Airforce

Unlike other window managers, it reloads the configuration rather than
restarting.  Sending C<SIGUSR1> to the L<blackbox(1)> PID provided in
the C<_NET_WM_PID> property on the C<_NET_SUPPORTING_WM_CHECK> window>
will effect the reconfiguration that results in rereading of the style
file.

=cut

sub set_style_BLACKBOX {
    my ($self,@styles) = @_;
    my $style;
    foreach (@styles) { if (-f $_ or -f "$_/theme.cfg") { $style = $_; last; } }
    return unless $style;
    my $file = $self->get_config_file_BLACKBOX;
    return unless $file and -f $file;
    my @lines = ();
    open(my $fh, "<", $file) or return;
    while (<$fh>) { chomp;
	if (/^session\.StyleFile:/) {
	    push @lines, "session.StyleFile:\t$style";
	} else {
	    push @lines, $_;
	}
    }
    close $fh;
    open($fh, ">", $file) or return;
    print $fh join("\n", @lines), "\n";
    close $fh;
    my $window = $self->getWMRootPropertyInt('_NET_SUPPORTING_WM_CHECK');
    return unless $window;
    my $pid = $self->getWmPropertyInt($window, '_NET_WM_PID');
    return unless $pid;
    kill 'USR1', $pid;
}

=item $style->B<set_style_OPENBOX>(I<@styles>) => $result

When L<openbox(1)> changes its theme, it changes the C<_OB_THEME>
property on the root window.  L<openbox(1)> also changes the C<theme>
section in F<~/.config/openbox/rc.xml> and writes the file and performs
a reconfigure.

L<openbox(1)> sets the C<_OB_CONFIG_FILE> property on the root window
when the configuration file differs from the default (but not otherwise).

L<openbox(1)> does not provide internal actions for setting the theme:
it uses an external theme setting program that communicates with the
window manager.

L<openbox(1)> can be reconfigured by sending an C<_OB_CONTROL> message
to the root window with a control type in C<data.l[0]>.  The control
type can be one of:

 OB_CONTROL_RECONFIGURE    1   reconfigure
 OB_CONTROL_RESTART        2   restart
 OB_CONTROL_EXIT           3   exit

When L<xde-session(1p)> runs, it sets the C<OPENBOX_RCFILE> environment
variable.  L<xde-session(1p)> and associated tools will always launch
L<openbox(1)> with a command such as:

 openbox ${OPENBOX_RCFILE:+--config-file $OPENBOX_RCFILE}

The default configuration file when C<OPENBOX_RCFILE> is not specified is
F<$XDG_CONFIG_HOME/openbox/rc.xml>.  The location of other L<openbox(1)>
configuration files are specified by the initial configuration file.
L<xde-session(1p)> typically sets C<OPENBOX_RCFILE> to
F<$XDG_CONFIG_HOME/openbox/xde-rc.xml>.

=cut

use constant {
    OB_CONTROL_RECONFIGURE=>1,
    OB_CONTROL_RESTART=>2,
    OB_CONTROL_EXIT=>3,
};

sub set_style_OPENBOX {
    my ($self,@styles) = @_;
}

=item $style->B<set_style_ICEWM>(I<@styles>) => $result

When L<icewm(1)> changes the style, it writes the new style to the
F<~/.icewm/theme> or F<$ICEWM_PRIVCFG/theme> file and then restarts.
The F<~/.icewm/theme> file looks like:

 Theme="Penguins/default.theme"
 #Theme="Airforce/default.theme"
 ##Theme="Penguins/default.theme"
 ###Theme="Pedestals/default.theme"
 ####Theme="Penguins/default.theme"
 #####Theme="Airforce/default.theme"
 ######Theme="Archlinux/default.theme"
 #######Theme="Airforce/default.theme"
 ########Theme="Airforce/default.theme"
 #########Theme="Airforce/default.theme"
 ##########Theme="Penguins/default.theme"

L<icewm(1)> cannot distinguish between system an user styles.  The theme
name specifies a directory in the F</usr/share/icewm/themes>,
F<~/.icewm/themes> or F<$ICEWM_PRIVCFG/themes> subdirectories.

There are two ways to get L<icewm(1)> to reload the theme, one is to
send a C<SIGHUP> to the window manager process.  The other is to send an
C<_ICEWM_ACTION> client message to the root window.

When L<xde-session(1p)> runs, it sets the C<ICEWM_PRIVCFG> environment
variable.  L<xde-session(1p)> and associated tools will always set this
environment variable before launching L<icewm(1)>.  L<icewm(1)> respects
this environment variable and no special options are necessary when
launching L<icewm(1)>.

The default configuration directory when C<ICEWM_PRIVCFG> is not
specified is F<~/.icewm>.  The location of all other L<icewm(1)>
configuration files are in this directory.  L<xde-session(1p)> typically
sets C<ICEWM_PRIVCFG> to F<$XDG_CONFIG_HOME/icewm>.

=cut

use constant {
    ICEWM_ACTION_NOP=>0,
    ICEWM_ACTION_PING=>1,
    ICEWM_ACTION_LOGOUT=>2,
    ICEWM_ACTION_CANCEL_LOGOUT=>3,
    ICEWM_ACTION_REBOOT=>4,
    ICEWM_ACTION_SHUTDOWN=>5,
    ICEWM_ACTION_ABOUT=>6,
    ICEWM_ACTION_WINDOWLIST=>7,
    ICEWM_ACTION_RESTARTWM=>8,
};

sub set_style_ICEWM {
    my ($self,@styles) = @_;
    my $style;
    foreach (@styles) { if (-d $_ and -f "$_/default.theme") { $style = $_; last; } }
    return unless $style;
    my $theme = $style; $theme = s{^.*/}{};
    my $dir = $ENV{ICEWM_PRIVCFG};
    $dir = "$ENV{HOME}/.icewm" unless $dir;
    $dir = "$self->XDG_CONFIG_HOME/icewm" unless -d $dir;
    my $file = "$dir/theme";
    return unless -f $file;
    open(my $fh, "<", $file) or return;
    my @lines = ("Theme=\"$theme/default.theme\"");
    while (<$fh>) { chomp; push @lines "#$_"; }
    close $fh;
    open($fh, ">", $file) or return;
    print $fh join("\n",@lines), "\n";
    close $fh;
    if (1) {
	my $X = $self->{X};
	$X->SendEvent($X->root,0,
	    $X->pack_event_mask(qw(
		SubstructureRedirect
		SubstructureNotify)),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$X->root,
		format=>32,
		type=>$X->atom('_ICEWM_ACTION'),
		data=>pack('LLLLL',&ICEWM_ACTION_RESTARTWM,0,0,0,0),
	    ));
	$X->flush;
    } else {
	my $window = $self->getWMRootPropertyInt('_NET_SUPPORING_WM_CHECK');
	return unless $window;
	my $pid = $self->getWmPropertyInt($window=>_NET_WM_PID);
	return unless $pid;
	kill 'HUP', $pid;
    }
}

=item $style->B<set_style_JWM>(I<@styles>) => $result

When L<jwm(1)> changes its style (the way we have it set up), it writes
F<~/.jwm/style> to include a new file and restarts.  The L<jwm(1)> style
file, F<~/.jwm/style> looks like:

 <?xml version="1.0"?>
 <JWM>
    <Include>/usr/share/jwm/styles/Squared-blue</Include>
 </JWM>

The last component of the path is the theme name.  System styles are
located in F</usr/share/jwm/styles>; user styles are located in
F<~/.jwm/styles>.

L<jwm(1)> can be reloaded or restarted by sending a C<_JWM_RELOAD> or
C<_JWM_RESTART> C<ClientMessage> to the root window, or by executing
C<jwm -reload> or C<jwm -restart>.

L<xde-session(1p)> sets the environment variable C<JWM_CONFIG_FILE> to
point to the primary configuration file; C<JWM_CONFIG_DIR> to point
to the system configuration directory (default F</usr/share/jwm>);
C<JWM_CONFIG_HOME> to point to the user configuration directory (default
F<~/.jwm> but set under an L<xde-session(1p)> to F<~/.config/jwm>).

Note that older versions of L<jwm(1)> do not provide tilde expansion in
configuration files.

=cut

sub set_style_JWM {
    my ($self,@styles) = @_;
    my $style;
    foreach (@styles) { if (-f $_) { $style = $_; last; } }
    return unless $style;
    my $dir = $ENV{JWM_CONFIG_HOME};
    $dir = "$ENV{HOME}/.jwm" unless $dir;
    $dir = "$self->XDG_CONFIG_HOME/jwm" unless -d $dir;
    my $file = "$dir/style";
    return unless -f $file;
    open(my $fh, ">", $file) or return;
    print $fh<<EOF
<?xml version="1.0"?>
<JWM>
   <Include>$style</Include>
</JWM>
EOF
    close $fh;
    my $X = $self->{X};
    $X->SendEvent($X->root,0,
	    $X->pack_event_mask(qw(
		    SubstructureRedirect
		    SubstructureNotify)),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$X->root,
		format=>32,
		type=>$X->atom('_JWM_RESTART'),
		data=>pack('LLLLL',0,0,0,0,0),
		));
    $X->flush;
}

=item $style->B<set_style_PEKWM>(I<@styles>) => $result

When L<pekwm(1)> changes its style, it places the theme directory in the
F<~/.pekwm/config> file.  This normally has the form:

 Files {
     Theme = "/usr/share/pekwm/themes/Airforce"
 }

The last component of the path is the theme name.  The full path is to a
directory which contains a F<theme> file.  System styles are located in
F</usr/share/pekwm/themes>; user styles are located in
F<~/.pekwm/themes>.

L<pekwm(1)> can be restarted by sending a C<SIGHUP> signal to the
L<pekwm(1)> process.  L<pekwm(1)> sets its pid in the
C<_NET_WM_PID(CARDINAL)> property on the root window (not the check
window) as well as the fqdn of the host in the
C<WM_CLIENT_MACHINE(STRING)> property, again on the root window.  The
L<XDE::EWMH(3pm)> module figures this out.

When L<xde-session(1p)> runs, it sets the C<PEKWM_RCFILE> environment
variable.  L<xde-session(1p)> and associated tools always launch
L<pekwm(1)> with a command such as:

 pekwm ${PEKWM_RCFILE:+--config $PEKWM_RCFILE}

The default configuration file when C<PEKWM_RCFILE> is not specified is
F<~/.pekwm/config>.  The locations of other L<pekwm(1)> configuration
files are specified in the initial configuration file.
L<xde-session(1p)> typically sets C<PEKWM_RCFILE> to
F<$XDG_CONFIG_HOME/pekwm/config>.

=cut

sub set_style_PEKWM {
    my ($self,@styles) = @_;
    my $style;
    foreach (@styles) { if (-d $_) { $style = $_; last; } }
    return unless $style;
    my $pid = $self->getWMRootPropertyInt('_NET_WM_PID');
    return unless $pid;
    my $file = $ENV{PEKWM_RCFILE};
    unless ($file and -f $file) {
	my $dir = $ENV{PEKWM_CONFIG_HOME};
	$dir = "$ENV{HOME}/.pekwm" unless $dir;
	$dir = "$self->XDG_CONFIG_HOME/pekwm" unless -d $dir;
	$file = "$dir/config";
    }
    return unless $file and -f $file;
    open(my $fh, "<", $file) or return;
    while (<$fh>) { chomp;
	s/Theme = "[^"]*"/Theme = "$style"/ if /Theme = "[^"]*"/
	push @lines, $_;
    }
    close $fh;
    open($fh, ">", $file) or return;
    print $fh join("\n",@lines), "\n";
    close $fh;
    kill 'HUP', $pid;
}

=item $style->B<set_style_FVWM>(I<@styles>) => $result

=cut

=item $style->B<set_style_WMAKER>(I<@styles>) => $result

=cut

=item $style->B<set_style_AFTERSTEP>(I<@styles>) => $result

=cut

=item $style->B<set_style_METACITY>(I<@styles>) => $result

=cut

=item $style->B<set_style_NONE>(I<@styles>) => $result

=cut

=item $style->B<set_style_UNKNOWN>(I<@styles>) => $result

=cut

=back

=head2 Style checking

=over

=item $style->B<check_style>() => $result

Gets the theme according to the current window manager, checks for a
theme change, and coordinates a theme change when necessary.

=cut

sub check_style {
    my $self = shift;
    my $v = $self->{ops}{verbose};
    print STDERR "Checking style\n" if $v;
    my $wm = "\U$self->{wmname}\E" if $self->{wmname};
    $wm = 'NONE' unless $wm;
    my $checker = "check_style_$wm";
    print STDERR "Checker: $checker\n" if $v;
    my $sub = $self->can($checker);
    $sub = $self->can('check_style_UNKNOWN') unless $sub;
    my $result = &$sub($self,@_) if $sub;
    return $result;
}

sub lookup_theme {
    my ($self,$name) = @_;
    my %entry = $self->get_style_by_name($name);
    my $theme;
    if (%entry) {
	$theme = $theme{'Xde/ThemeName'};
	$theme = $theme{'Net/ThemeName'} unless $theme;
	$theme = $theme{'Gtk/ThemeName'} unless $theme;
    }
    $theme = $name unless $theme;
    return $theme, %entry;
}

=item $style->B<check_style_FLUXBOX>() => $result

Checks the style reported by the L<fluxbox(1)> window manager.

When L<fluxbox> changes its style, it writes the new style in the
C<session.styleFile> resource in the F<~/.fluxbox/init> file.  Note,
however, that unlike other window managers, it does not restart.
(Unfortunately, this also leads to L<fluxbox> not correctly changing the
style of the L<fluxbox> menus.)  We use L<Linux::Inotify2> to help us
detect a change to the file.  We might be able to also use
L<fluxbox-remote(1)> to restart L<fluxbox> and have it correctly render
menus under the new style.

Note also that F<~/.fluxbox/init> might be the incorrect file depending
on how L<fluxbox> was started.  We might also be able to use
L<fluxbox-remote(1)> to get L<fluxbox> to surrender its primary
configuration file path.  However, it is atypical to set up L<fluxbox>
to permit L<fluxbox-remote(1)> operation at all.

When there is no XDE theme name corresponding to the L<fluxbox> style,
we can still use the L<fluxbox> style name to lookup a GTK2 theme name
to use for GTK2 applications that are associated with the desktop and
which should maintain a style similar to that of the window manager.

=cut

sub check_style_FLUXBOX {
    my $self = shift;
    my $config = "$ENV{HOME}/.fluxbox/init"; # for now
    $self->watch_style_file(config=>$config);
    my $style = $self->read_anybox_style($config) or return undef;
    $style = "$style/theme.cfg" if -d $style;
    return undef if defined($self->{style}) and $self->{style} eq $style;
    $self->{style} = $style;
#   STYLE CHANGED
    my $name = $style; $name =~ s{/theme\.cfg$}{}; $name =~ s{.*/}{};
    my ($theme, %entry) = $self->get_style_by_name($name);
    return undef if defined($self->{theme}) and $self->{theme} eq $theme;
    $self->{theme} = $theme;
    return $theme, %entry;
}

=item $style->B<check_style_BLACKBOX>() => $result

Checks the style reported by the L<blackbox(1)> window manager.

L<blackbox(1)> is similar to L<fluxbox(1)>: it sets the style in the
F<~/.blackboxrc> file when changing styles; however, L<blackbox(1)>
normally changes the background with every style change, therefore, a
change in the background image should also trigger a recheck.

=cut

sub check_style_BLACKBOX {
    my $self = shift;
    my $config = "$ENV{HOME}/.blackboxrc"; # for now
    $self->watch_style_file(config=>$config);
    my $style = $self->read_anybox_style($config) or return undef;
    return undef if defined($self->{style}) and $self->{style} eq $style;
    $self->{style} = $style;
#   STYLE CHANGED
    my $name = $style; $name =~ s{.*/}{};
    my ($theme, %entry) = $self->get_style_by_name($name);
    return undef if defined($self->{theme}) and $self->{theme} eq $theme;
    $self->{theme} = $theme;
    return $theme, %entry;
}

=item $style->B<check_style_OPENBOX>() => $result

Checks the style reported by the L<openbox(1)> window manager.

L<openbox(1)> will change the C<_OB_THEME> property on the root window
when its theme changes: so a simple C<PropertyNotify> on this property
should trigger the recheck.  Note that L<openbox(1)> also set
C<_OB_CONFIG_FILE> on the root window when the configuration file
differs from the default (but not otherwise).  Note that L<openbox(1)>
also changes the C<theme> section in F<~/.config/openbox/rc.xml> and
writes the file, but we don't need that.

=cut

sub check_style_OPENBOX {
    my $self = shift;
    $self->watch_style_file(config=>'');
    my $style = $self->{_OB_THEME} or return undef;
    return undef if defined($self->{style}) and $self->{style} eq $style;
    $self->{style} = $style;
#   STYLE CHANGED
    my $name = $style;
    my ($theme, %entry) = $self->get_style_by_name($name);
    return undef if defined ($self->{theme}) and $self->{theme} eq $theme;
    $self->{theme} = $theme;
    return $theme, %entry;
}

=item $style->B<check_style_ICEWM>() => $result

Checks the style reported by the L<icewm(1)> window manager.

When L<icewm(1)> changes its theme it restarts, which results in a new
C<_NET_SUPPORTING_WM_CHECK(WINDOW)> window, which invokes this internal
function.  L<icewm(1)> changes the setting for the theme in its
F<~/.icewm/theme> file (or C<$ICEWM_PRIVCFG/theme>) file.

=cut

sub check_style_ICEWM {
    my $self = shift;
    my $cfgdir = $ENV{ICEWM_PRIVCFG} if $ENV{ICEWM_PRIVCFG};
    $cfgdir = "$ENV{HOME}/.icewm" unless $cfgdir;
    my $config = "$cfgdir/theme";
    $self->watch_style_file(config=>$config);
    my @styles = $self->read_icewm_style($config) or return;
    #
    # each @styles is a relative path that can be in two places:
    # @XDG_DATA_DIRS/icewm/themes or $ICEWM_PRIVCFG/themes.  User themes
    # override system themes of the same name.  When a theme cannot be
    # found, try an older theme in the list.
    #
    my $v = $self->{ops}{verbose};
    my ($style,$name);
    foreach my $s (@styles) {
	foreach my $dir ($cfgdir, "$ENV{HOME}/.icewm",
		map{"$_/icewm"} $self->XDG_DATA_ARRAY) {
	    print STDERR "Directory: '$dir'\nStyle: '$s'\n" if $v;
	    my $file = "$dir/themes/$s";
	    if (-f $file) {
		$name = $s;
		$style = $file;
		last;
	    }
	}
	last if $style;
    }
    return undef if defined($self->{style}) and $self->{style} eq $style;
    $self->{style} = $style;
    if ($name) {
	$name =~ s{/default\.theme$}{};
	$name =~ s{\.theme$}{};
    }
    my ($theme,%entry) = $self->get_style_by_name($name);
    return undef if defined($self->{theme}) and $self->{theme} eq $theme;
    $self->{theme} = $theme;
    return $theme, %entry;
}

=item $style->B<check_style_JWM>() => $result

=cut

=item $style->B<check_style_PEKWM>() => $result

=cut

=item $style->B<check_style_FVWM>() => $result

=cut

=item $style->B<check_style_WMAKER>() => $result

=cut

=item $style->B<check_style_AFTERSTEP>() => $result

=cut

=item $style->B<check_style_METACITY>() => $result

=cut

=item $style->B<check_style_NONE>() => $result

=cut

=item $style->B<check_style_UNKNOWN>() => $result

=cut

=back

=head2 Support methods

=over

=item $style->B<watch_style_file>(I<$label>,I<$file>) => $installed

=cut

=item $style->B<get_style_by_name>(I<$name>) => %entry

Search out in XDG theme directories an XDE theme with the name,
I<$name>, and collect the sections and fields into a hash reference.
The keys of the hash reference are the sections in the file with subkeys
represented fields in the section.  An empty hash is returned when no
file of the appropriate name could be found or if the file was empty.
When successful, C<$entry{file}> contains the filename read.

Because the theme name is derived from the window manager specific style
file or directory, it is possible to symbolically link an arbitrary
style to a window manager specific style file or directory to associate
it with an XDE theme.  In this way, different XDE themes can use the
same window manager style.  See L</CONFIGURATION> for more information
on XDE theme file contents.

=cut

sub get_style_by_name {
    my ($self,$name) = @_;
    my $v = $self->{ops}{verbose};
    print STDERR "Getting theme for '$name'\n" if $v;
    foreach my $d (map{"$_/themes/$name"}@{$self->{XDG_DATA_ARRAY}}) {
	print STDERR "Checking directory '$d'\n" if $v;
	next unless -d $d;
	my $f = "$d/xde/theme.ini";
	print STDERR "Checking file '$f'\n" if $v;
	next unless -f $f;
	print STDERR "Found file '$f'\n" if $v;
	open (my $fh,"<",$f) or next;
	print STDERR "Reading file '$f'\n" if $v;
	my %e = (file=>$f,theme=>$name);
	my $section;
	while (<$fh>) { chomp;
	    next if m{^\s*\#}; # comment
	    if (m{^\[([^]]*)\]}) {
		$section = $1;
		print STDERR "Starting section '$section'\n" if $v;
	    }
	    elsif ($section and m{^([^=]*)=([^[:cntrl:]]*)}) {
		$e{$section}{$1} = $2;
		print STDERR "Reading field $1=$2\n" if $v;
	    }
	}
	close($fh);
	my $short = $1 if $self->{ops}{lang} =~ m{^(..)};
	$e{Theme}{Name} = $name unless $e{Theme}{Name};
	$e{Xsettings}{'Xde/ThemeName'} = $e{Theme}{Name}
	    unless $e{Xsettings}{'Xde/ThemeName'};
	foreach my $wm (qw(fluxbox blackbox openbox icewm jwm pekwm fvwm wmaker afterstep metacity)) {
	    foreach (keys %{$e{Theme}}) {
		$e{$wm}{$_} = $e{Theme}{$_} unless exists $e{$wm}{$_};
	    }
	}
	my %r = ();
	my $theme = 'Theme';
	$theme = $self->{wmname} if $self->{wmname};
	foreach (keys %{$e{$self->{wmname}}}) {
	    my $valu = $e{$self->{wmname}}{$_};
	    if (m{^Workspace(\d+)?(Color|Image|Center|Scaled|Tiled|Full)}) {
		my $spec = (defined $1 and $1 ne '') ? $1 : 'all';
		my $part = $2;
#		$r{workspace}{$spec}{mode} = $r{workspace}{all}{mode}
#		    unless $r{workspace}{$spec}{mode};
#		$r{workspace}{$spec}{mode} = 'tiled'
#		    unless $r{workspace}{$spec}{mode};
		$r{numb} = $spec+1 if $spec ne 'all' and
		    (not defined $r{numb} or $spec >= $r{numb});
		if ($part eq 'Image') {
		    $r{workspace}{$spec}{pixmap} = $valu;
		}
		elsif ($part eq 'Color') {
		    $r{workspace}{$spec}{color} = $valu;
		}
		elsif ($part eq 'Center') {
		    $r{workspace}{$spec}{mode} = 'centered' if $valu =~ m{yes|true|1}i;
		}
		elsif ($part eq 'Scaled') {
		    $r{workspace}{$spec}{mode} = 'aspect' if $valu =~ m{yes|true|1}i;
		}
		elsif ($part eq 'Full') {
		    $r{workspace}{$spec}{mode} = 'fullscreen' if $valu =~ m{yes|true|1}i;
		}
	    }
	    elsif ($_ eq 'Workspaces') {
		$r{workspaces} = $valu;
	    }
	    elsif ($_ eq 'WorkspaceNames') {
		my $names = $valu;
		my @names = split(/,/,$names);
		$r{workspaces} = scalar(@names) unless $r{workspaces};
		$r{workspaceNames} = \@names;
	    }
	}
	$r{workspace}{all}{mode} = 'tiled'
	    unless $r{workspace}{all}{mode};
	if ($r{numb}) {
	    for (my $i=0;$i<$r{numb};$i++) {
		$r{workspace}{$i}{mode} = $r{workspace}{all}{mode}
		    unless $r{workspace}{$i}{mode};
	    }
	}
	%r = $self->correct_theme(%r);
	return %r;
    }
    return ();
}

=back

=head2 Event handlers

=over

=item $style->get_OB_THEME() => $theme

=cut

sub get_OB_THEME {
    my $self = shift;
    my $theme = $self->getWMRootPropertyString('_OB_THEME');
    $theme = '' unless $theme;
    return $theme;
}

=item $style->event_handler_PropertyNotify_OB_THEME(I<$e>,I<$X>,I<$v>)

Event handler for changes in the C<_OB_THEME> property.

=cut

sub event_handler_PropertyNotify_OB_THEME {
    my ($self,$e,$X,$v) = @_;
    $self->get_OB_THEME if $e->{window} == $X->root;
    $self->check_style;
}


1;

__END__

=back

=head1 CONFIGURATION

Theme files are DOS F<.ini> style files.  They consist of a C<[Theme]>
section that contains definitions that apply to all window managers.  A
window-manager-specific section can be included, (e.g. C<[fluxbox]>)
that provides overrides for that window manager.

Theme files are named F<theme.ini> and contain the following fields in
the C<[Theme]> section.  Any fields may be overridden by a window
manager specific section (e.g. C<[fluxbox]>).

Following is an example theme file:

=over

 [Theme]
 Name=Airforce
 Style=Squared-green
 
 WallpaperDefault=emeraldcoast
 WallpaperRepeat=true
 Wallpaper0=emeraldcoast
 Wallpaper1=squad
 Wallpaper2=thunderbird
 Wallpaper3=overalaska
 
 Workspaces=6
 WorkspaceNames= 1 , 2 , 3 , 4 , 5 , 6 , 7 , 8 , 9 
 
 WorkspaceColor=rgb:00/20/40
 WorkspaceCenter=0
 WorkspaceScaled=0
 WorkspaceFull=1
 WorkspaceImage=airforce/emeraldcoast.jpg
 
 Workspace0Image=airforce/emeraldcoast.jpg
 Workspace1Image=airforce/fighterjets.jpg
 Workspace2Image=airforce/squad.jpg
 Workspace3Image=airforce/landing.jpg
 Workspace4Image=airforce/thunderbird.jpg
 Workspace5Image=airforce/overalaska.jpg
 
 [Xsettings]
 Gtk/ButtonImages=1
 Gtk/ColorScheme=
 Gtk/CursorThemeName=
 Gtk/CursorThemeSize=18
 Gtk/EnableEventInputFeedbackSounds=1
 Gtk/EnableEventSounds=1
 Gtk/FallbackIconTheme=
 Gtk/FontName=Liberation Sans 9
 Gtk/IconSizes=
 Gtk/IconThemeName=Mist
 Gtk/KeyThemeName=
 Gtk/MenuBarAccel=F10
 Gtk/MenuImages=1
 Gtk/SoundThemeName=freedesktop
 Gtk/ThemeName=Mist
 Gtk/ToolbarIconSize=2
 Gtk/ToolbarStyle=2
 
 Net/EnableEventSounds=1
 Net/EnableInputFeedbackSounds=1
 Net/IconThemeName=Mist
 Net/ThemeName=Mist
 
 Xft/Antialias=1
 Xft/Hinting=1
 Xft/HintStyle=hintfull
 Xft/RGBA=rgb
 
 Xde/ThemeName=Airforce
 Xde/MenuThemeName=Squared-green
 
 [fluxbox]
 
 [blackbox]
 WorkspaceNames=Workspace 1,Workspace 2,Workspace 3,\
		Workspace 4,Workspace 5,Workspace 6,\
		Workspace 7,Workspace 8,Workspace 9
 
 [openbox]
 WorkspaceNames=1,2,3,4,5,6,7,8,9
 
 [icewm]
 
 [jwm]
 WorkspaceNames=1,2,3,4,5,6,7,8,9
 
 [pekwm]
 
 [fvwm]
 
 [wmaker]

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72

