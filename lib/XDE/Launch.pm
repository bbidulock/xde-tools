package XDE::Launch;
use base qw(XDE::Dual XDE::X11::StartupNotification);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Launch -- launch and monitor XDG applications

=head1 SYNOPSIS

 use XDE::Launch;

 my $xde = XDE::Launch->new(%OVERRIDES,ops=>\%ops);

 $xde->getenv;
 $xde->init;
 $xde->launch(%args);
 $SIG{TERM} = sub{$xde->main_quit};
 $SIG{INT}  = sub{$xde->main_quit};
 $SIG{QUIT} = sub{$xde->main_quit};
 $xde->main;
 $xde->term;

=head1 DESCRIPTION

Provides a moudle that runs out of the L<Glib::Mainloop(3pm)> that will
launch an XDG application (desktop entry) and monitor for startup
notification.

=head1 METHODS

The following methods are provided:

=over

=item $xde = XDE::Launch->B<new>(I<%OVERRIDES>,ops=>\I<%ops>)

Creates an instance of an XDE::Launch object.  The XDE::Launch module
uses the L<XDE::Context(3pm)> module as a base, so the C<%OVERRIDES> are
simply passed to the L<XDE::Context(3pm)> module.  When an options hash,
I<%ops>, is passed to the method, it is initialized with default option
values.

XDE::Launch recognizes the following options:

=over

=item verbose => $boolean

=item appid => $application_id

=back

Additional options may be recognized by the superior
L<XDE::Context(3pm)> object.

=cut

sub new {
    return XDE::Gtk2::new(@_);
}

=item $xde->B<_init>() => $xde

Performs initialization for just this module.  Called after
L<XDE::Dual(3pm)> is fully initialized.  Calls the _init() method for
L<XDE::X11::StartupNotification(3pm)> which would otherwise not be
called due to multiple inheritance.

=cut

sub _init {
    my $self = shift;
    $self->XDE::X11::StartupNotification::_init();
    return $self;
}

=item $xde->B<_term>()

Performs termination for just this module.  Called before
C<XDE::X11-E<gt>term()> is called.  Calls the _term() method for
L<XDE::X11::StartupNotification(3pm)> which would otherwise not be
called due to multiple inheritance.

=cut

sub _term {
    my $self = shift;
    $self->XDE::X11::StartupNotification::_term();
    return $self;
}

=item $xde->B<launch>(I<%args>)

Requests that the application specified using the argument, I<%args>, be
launched.  The arguments hash, I<%args>, may contain the following
recognized fields (unrecognized fields are ignored):

=over

=item B<verbose>

A boolean indicating whether to display diagnostic information to
standard error during the launch.

=item B<monitor>

A boolean indicating whether the XDG application is launched as a
child task (when true) or a foreground task (when false).

=item B<screen>

The screen number on which to launch the application.  This affects the
C<SCREEN> key-value pair in the startup notification C<new> message.  A
null string value indicates the default screen.

=item B<workspace>

The desktop name or number on which to launch the application.  When
specified as a simple number, that desktop number is used (counting from
zero); otherwise, the C<_NET_DESKTOP_NAMES> property on the root window
is checked to determine the desktop number that corressponds to the
name.  A null string value indicates the current desktop.

=item B<timestamp>

The X Server timestamp of the X Event that cause the launch to be
invoked.  A value of zero specifies the current time and the method
should obtain a new timestamp from the X Display.

=item B<name>

When not null, specifies or overrides the C<Name> field of the XDG
desktop entry and supplies the C<NAME> key-value pair for the startup
notification C<new> message.

=item B<icon>

When not null, specifies or overrides the C<Icon> field of the XDG
desktop entry and supplies the C<ICON> key-value pair for the startup
notification C<new> message.

=item B<binary>

When not null, specifies or overrides the C<TryExec> field of the XDG
desktop entry and supplies the C<BIN> key-value pair for the startup
notification C<new> message.

=item B<description>

When not null, specifies or overrides the C<Comment> field of the XDG
desktop entry and supplies the C<DESCRIPTION> key-value pair for the
startup notification C<new> message.

=item B<wmclass>

When not null, specifies or overrides the C<StartupWMClass> field of the
XDG desktop entry and supplies the C<WMCLASS> key-value pair for the
startup notification C<new> message.

=item B<silent>

When not null, specifies or overrides the C<SILENT> key-value pair for
the startup notification C<new> message.

=item B<appid>

When not null, specifies or overrides the application id and provides
the C<APPLICATION_ID> key-value pair for the startup notification C<new>
message.

=item B<exec>

When not null, specifies or overrides the C<Exec> field of the XDG
desktop entry.

=item B<file>

When not null, specifies a file path and name to substitute in the XDG
application startup command (i.e. C<Exec> field).

=item B<url>

When not null, specifies a url to substitute in the XDG application
startup command (i.e. C<Exec> field).

=item B<argv>

When not null, specifies the application identifier that is used to
locate the XDG desktop entry file and provides the default for the
C<APPLICATION_ID> key-value pair in the startup notification C<new>
message.

Each application identifier can be one of:

=over

=item 1.

The name of an XDG compliant desktop entry file, including the
C<.desktop> suffix.

=item 2.

The name of an XDG compliant desktop entry file, excluding the
C<.desktop> suffix.

=item 3.

A full (absolute or relative) path to a desktop entry file.

=back

When null, an XDG application can still be lauched when the B<appid>,
B<binary> or B<exec> argument is specified.

=back

=cut

use constant {
    LAUNCH_MAPPING=>{
	screen=>'Screen',
	workspace=>'Desktop',
	timestamp=>'TimeStamp',
	name=>'Name',
	icon=>'Icon',
	binary=>'TryExec',
	description=>'Comment',
	wmclass=>'StartupWMClass',
	silent=>'Hidden',
	appid=>'id',
	exec=>'Exec',
	file=>'File',
	url=>'URL',
    },
    ENTRY_MAPPING=>{
	Screen=>'SCREEN',
	Desktop=>'DESKTOP',
	TimeStamp=>'TIMESTAMP',
	Name=>'NAME',
	Icon=>'ICON',
	TryExec=>'BIN',
	Comment=>'DESCRIPTION',
	StartupWMClass=>'WMCLASS',
	Hidden=>'SILENT',
	id=>'APPLICATION_ID',
    },
};

sub launch {
    my($self,%args) = @_;
    return unless
	$args{argv} or
	$args{appid} or
	$args{binary} or
	$args{exec};
    my($appid,$dir,$file,$launchee,$entry);
    if ($appid = $args{argv} or $appid = $args{appid}) {
	if ($appid =~ m{/}) {
	    return unless -f $appid;
	    $file = $appid;
	    $appid =~ s{.*/}{};
	    $appid =~ s{\.desktop$}{};
	}
	elsif ($appid =~ m{\.desktop$}) {
	    foreach $dir (reverse map{"$_/applications"}$self->XDG_DATA_ARRAY) {
		if (-f "$dir/$appid") {
		    $file = $appid;
		    last;
		}
	    }
	    return unless $file;
	    $appid =~ s{.*/}{};
	    $appid =~ s{\.desktop$}{};
	    $entry = $self->get_entry($dir,$file,'Desktop Entry');
	}
	else {
	    foreach $dir (reverse map{"$_/applications"}$self->XDG_DATA_ARRAY) {
		if (-f "$dir/$appid.desktop") {
		    $file = "$appid.desktop";
		    last;
		}
	    }
	    return unless $file;
	    $appid =~ s{.*/}{};
	    $appid =~ s{\.desktop$}{};
	    $entry = $self->get_entry($dir,$file,'Desktop Entry');
	}
    }
    elsif ($appid = $args{exec} or $appid = $args{binary}) {
	($appid) = split(/\s/,$appid,2);
	$appid =~ s{.*/}{};
	$entry = {};
	$entry->{appid} = $appid;
    }
    foreach (qw(screen workspace timestamp name icon binary description
		wmclass silent appid exec file url)) {
	$entry->{&LAUNCH_MAPPING->{$_}} = $args{$_} if $args{$_};
    }
}

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>,
L<XDE::Dual(3pm)>,
L<XDE::X11(3pm)>,
L<XDE::X11::StartupNotification>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
