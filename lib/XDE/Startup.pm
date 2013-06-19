package XDE::Startup;
use base qw(XDE::Dual);
use strict;
use warnings;

=head1 NAME

XDE::Startup - setup and start an XDE session for a window manager

=head1 SYNOPSIS

 use XDE::Startup;

 my $xde = XDE::Startup->new(%OVERRIDES,ops=>\%ops);

 $xde->getenv();
 $xde->init;
 $xde->startup;
 $xde->main;

=head1 DESCRIPTION

B<XDE::Startup> provides a module that runs out of the Glib::Mainloop
that will execute preliminary commands, start the window manager and
launch an XDG autostart session.  It will monitor the session, provide
notification and restart as necessary and gracefully shut down when
requested.  The module mimics the behaviour of L<lxsession(1)> for
compatibility with LXDE tools.

=cut

=head1 METHODS

=over

=item $xde = XDE::Startup->B<new>(I<%OVERRIDES>,ops=>\I<%ops>) => blessed HASHREF

Creates a new XDE::Startup instance.  The XDE::Startup module uses the
L<XDE::Context(3pm)> module as a base, so the C<%OVERRIDES> are simply
passed to the L<XDE::Context(3pm)> module.  When an options hash,
I<%ops>, is passed to the method, it is initialized with default option
values.  See L</OPTIONS> for details on the options recognized.

=cut

sub new {
    return XDE::Gtk2::new(@_);
}

=item $xde->B<defaults>() => $xde

Internal method that can be used for multiple inheritance instead of the
B<default> method.  Establishes our option defaults.  See L</OPTIONS>
for detauls on options and their default values.

=cut

sub defaults {
    my $self = shift;

    $self->{ops}{startwm} = ''      unless exists $self->{ops}{startwm};
    $self->{ops}{autostart} = 1     unless exists $self->{ops}{autostart};
    $self->{ops}{wait} = 2000       unless exists $self->{ops}{wait};
    $self->{ops}{pause} = 250       unless exists $self->{ops}{pause};

    my $session = $self->{XDG_VENDOR_STRING};
    $session = $self->{XDG_CURRENT_DESKTOP} unless $session;
    $session = $self->{ops}{session} unless $session;
    $session = 'XDE' unless $session;
    $session = "\U$session\E";
    $self->{ops}{message} = "Logout $session session?"
	unless exists $self->{ops}{message};
    return $self;
}

=item $xde->B<startup>()

Establishes setup to the startup operation.  This method seeks out exec
defintions from the XDE autostart files, seeks out XDG autostart
defintions from the XDG auotstart directories, establishes the window
manager start command and adds any watchers to the Glib::mainloop that
are required to run the autostart.

=cut

sub startup {
    my $self = shift;
    if ($self->{ops}{autostart}) {
	$self->startup_window;
	$self->{autostart} = {};
	$self->{atuostart} = $self->get_autostart;
    }
}

=item $xde->B<startup_window>()

Internal function, establishes the splash window.

=cut

sub startup_window {
    my $self = shift;
    my $win = $self->{startup}{win} = Gtk2::Window->new('toplevel');
    $win->set_wmclass('xde-startup','Xde-startup');
    $win->set_gravity('center');
    $win->set_type_hint('splashscreen');
    $win->set_border_width(20);
    $win->set_skip_pager_hint(TRUE);
    $win->set_skip_taskbar_hint(TRUE);
    $win->set_position('center-always');
    my $table;
    my $cols = 7;
    my $hbox = Gtk2::HBox->new(FALSE,5);
    $win->add($hbox);
    my $vbox = Gtk2::VBox->new(FALSE,5);
    $hbox->pack_start($vbox,TRUE,TRUE,0);
    if ($self->{ops}{banner}) {
	my $img = Gtk2::Image->new_from_file($self->{ops}{banner});
	$vbox->pack_start($img,FALSE,FALSE,0);
    }
    my $sw = Gtk2::ScrolledWindow->new;
    $sw->set_shadow_type('etched-in');
    $sw->set_policy('never','automatic');
    $sw->set_size_request(800,-1);
    $vbox->pack_end($sw,TRUE,TRUE,0);
    $table = $self->{startup}{table} = Gtk2::Table->new(1,$cols,TRUE);
    $table->set_col_spacings(1);
    $table->set_row_spacings(1);
    $table->set_homogeneous(TRUE);
    $table->set_size_request(750,-1);
    $sw->add_with_viewport($table);
    $win->set_default_size(-1,600);
}

=item $xde->B<exec_startup>()

Internal function that executes F<autostart> scripts and any B<--exec>
options supplied (normally from the command line).  These functions are
called prior to starting and checking the window manager.

=cut

sub exec_startup {
    my $self = shift;

    my $cmd = XDE::Autostart::Command->new($self,$command);
    $cmd->startup($self);
}

=item $xde->B<check_wm>()

Internal function to check the presence of a window manager and to
determine which window manager is actually running, where possible.

=cut

sub check_wm {
    my $self = shift;
}

=item $xde->B<_init>() => $xde

Performs initialization for just this module.  Called after
L<XDE::Dual(3pm)> is fully initialized.

=cut

sub _init {
    my $self = shift;
    return $self;
}

=item $xde->B<_term>() => $xde

Performs termination for just this module.  Called before
C<XDE::X11-E<gt>term()> is called.

=cut

sub _term {
    my $self = shift;
    return $self;
}

=back

=cut

1;

__END__

=head1 OPTIONS

XDE::Startup recognizes the following options:

=over

=item startwm => $command

Specifies the command to be used to start the window manager.  When
unspecified, no window manager will be started.

=item exec => [ @commands ]

Specifies commands to execute before starting the window manager or
autostarting tasks.  When unspecified, the default set of commands is
taken from environment variables and XDE F<autostart> files.

=item autostart => $boolean

When true, specifies that XDG autostart tasks for the current desktop
environment are to be executed.  When false, it XDG autostart is
skipped.  The default value when unspecified is true.

=item wait => $milliseconds or undef

Specifies the number of milliseconds that the module will await the
appearance of a window manager before autostarting tasks.  When set to
C<undef>, the module will not awaiting a window manager (but may still
be subject to a pause), and will not await a window manager.  This is a
guard timer to keep the module from hanging when no window manager
appears.  The default is 2000 milliseconds (2 seconds).

=item pause => $milliseconds

Wait for the specified number of milliseconds before autostarting tasks.
When unspecified or specified as zero (C<0>), the module will not pause
before autostarting tasks.  The default value is C<250> milliseconds to
allow non-XDE aware window managers to complete their initializations on
startup before this module autostarts tasks.

=item message => $message

Specifies a message to display on the logout window.  The default when
unspecified is C<Logout XDE session?>.

=back

See also L<XDE::Context(3pm)> for options recognized by the base module.

=head1 BEHAVIOUR

The XDE::Startup module is responsible for starting up an entire X
Desktop Environment.  I has a number of options and many of the options
simply default to XDG/XDE environment variables when unspecified.  The
sequence of startup is as follows:

=head2 XDE Autostart

The module searches out the list of XDE autostart files that it has to
execute.  The files considered consist of a system XDE autostart file
and a user XDE autostart file.

The system XDE autostart file is the first F<autostart> file found in
the F<@XDG_CONFIG_DIRS/xde-session/$XDG_CURRENT_DESKTOP/> directories.
If an autostart file is not found, the first file in the
F<@XDG_CONFIG_DIRS/xde-session/default/> directories will be used.  If
no system XDE autostart file is found, system XDE autostart will be
skipped.

The user XDE autostart file is the F<autostart> file in the
F<$XDG_CONFIG_HOME/xde/$XDG_CURRENT_DESKTOP/> directory.  If that file
does not exist, a file in the F<$XDG_CONFIG_HOME/xde/default/> directory
will be be used.  If no user XDE autostart file is found, user XDE
autostart will be skipped.

When XDE autostart commands are specified using the C<exec> option,
neither file will be considered and the XDE autostart phase will consist
of simply the commands listed in the C<exec> option.

The commands collected from the system and user XDE autostart files or
the C<exec> option are exected in that order.  If the command begins
with the C<@> character, they will be restarted when they abort.

=head2 Window Manager

The module will look up the window manager command from the
F<session.ini> file located in the
F<$XDG_CONFIG_HOME/xde/$XDG_CURRENT_DESKTOP/> directory.  When this file
does not exist, no window manager command will be set.

When the C<startwm> option is provided, the command specified by the
C<startwm> option will be used instead of any from the F<session.ini>
file.

When no window manager command is found or specified, or when the window
manager command is undefined or a null string, no window manager will be
started.  Otherwise, the module will start the window manager using the
command.

When the C<wait> option is defined, whether the module launched a window
manager or not, it will wait up to C<wait> milliseconds for a NetWM/EHWM
compatible window manager to appear on the X Display before proceding.
Should the timer expire, it will post a notice dialog, print a
diagnostic message on standard error and exit back to the display
manager with a non-zero status.

When the C<wait> option is undefined, the module procedes immediately to
the next step.

=head2 XDG Autostart

When the C<autostart> option is false, this entire section is skipped.

The XDE::Startup module will search out all of the F<.desktop> files in
XDG autostart directories according to the L<XDG Autostart
Specification>.

When the C<pause> option is specified and non-zero, the module waits for
the specified number of milliseconds before proceding with XDG
autostart.

Once XDG autostart begins, the XDE::Startup module displays an XDG
autostart splash window that shows the order and progress of starting
the XDG programs in a table.  The module starts a new XDG autostart
F<.desktop> entry each time that the Glib::mainloop is idle.

Should any of the XDG startup entries fail during this period,
notification of failure will be given to the user.

Several (2) seconds after all XDG autostart entries are initiated and
have completed startup notification, the splash window is withdrawn.

=head2 Session Monitoring

The XDE::Startup module now goes into session monitoring mode.  In this
mode, any XDE autostart commands that specified an C<@> will be
restarted should they abort.  To avoid constant looping, the task must
have been running for at least 250 ms before it will be automatically
restarted.  When it is failing faster than this period, the user will be
prompted to restart or abandon the task.

XDG autostart entries that fail will generate notification to the user
of failure and asked whether she wants to restart the task.

Should the window manager exit (abort or normal) logout procedures will
be initiated.  (The logout procedure includes the possibility of
restarting the same window manager.)

Should the XDE::Startup notice that the window manager has changed (due
to a change in properties on the root window), it will shutdown and
reinitiate all phases with the exception of launching the window
manager.

=head2 Client Requests

The XDG::Startup module also accepts client messages that can invoke a
number of procedures as follows:

=over

=item 1.

Initiating logout procedures.

=item 2.

Restarting with a new window manager.

=item 3.

Launching an XDG autostart editor window.

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72
