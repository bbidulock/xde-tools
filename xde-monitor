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
use XDE::Monitor;
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
    banner	=> '',
    noask	=> '',
    charset	=> langinfo(CODESET),
    language	=> setlocale(LC_MESSAGES),
    setdflt	=> '',
    default	=> '',
    current	=> '',
    choice	=> '',
    vendor	=> '',
    monitor	=> 1,
    grab	=> 1,
    theme	=> '',
    id		=> '',
    setroot	=> 1,
    display	=> $ENV{DISPLAY},
    time	=> 0,
    appid	=> '',
);

my $xde - XDE::Monitor->new(%OVERRIDES,ops=>\%ops);
$xde->getenv;

my $syntax = GetOptions(
    'help|h'	    => \$ops{help},
    'verbose|v'	    => \$ops{verbose},
    'display|d=s'   => \$ops{display},
    'charset|c=s'   => \$ops{charset},
    'language|L=s'  => \$ops{language},
);

$xde->default; # reset defaults

if ($ops{help}) {
    print STDOUT show_usage;
    exit(0);
}

unless ($syntax) {
    print STDERR "ERROR: syntax error\n";
    print STDERR show_usage;
    exit(2);
}

if ($program eq 'xde-launch' and not $ops{appid}) {
    print STDERR "ERROR: missing argument\n";
    print STDERR show_usage;
    exit(2);
}

$xde->init;

$xde->{DESKTOP_STARTUP_ID} = $ENV{DESKTOP_STARTUP_ID}
    unless $xde->{DESKTOP_STARTUP_ID};
delete $ENV{DESKTOP_STARTUP_ID};

my $unique = Gtk2::UniqueApp->new(
	'com.unexicon.xde-monitor',
	$xde->{DESKTOP_STARTUP_ID},
	'xde-monitor' => 1,
	'xde-launch'  => 2);

if ($unique->is_running) {
    $unique->send_message_by_name($program=>text=>$ops{appid});
    print STDERR "Another instance of $program is already running\n";
    exit(0);
}

my $window = Gtk2::Window->new('toplevel');
$unique->watch_window($window);
$unique->signal_connect(message_received=>sub{
	my ($unique,$command,$message,$time) = @_;
	my $appid = $message->get_text;
	my $screen = $message->get_screen;
	my $workspace = $message->get_workspace;
	my $startup_id = $message->get_startup_id;
	if ($ops{verbose}) {
	    print STDERR "$command command received\n";
	    print STDERR "\tscreen is ", $screen, "\n";
	    print STDERR "\tworkspace is ", $workspace, "\n";
	    print STDERR "\tstartup id is ", $startup_id, "\n";
	    print STDERR "\ttime is ", $time, "\n";
	}
	if ($command == 1 or $command eq 'xde-monitor') {
	    # nothing to do
	}
	elsif ($command == 2 or $command eq 'xde-launch') {
	    $xde->launch($screen,$workspace,$appid);
	}
	if ($startup_id) {
	    Gtk2::Gdk->notify_startup_complete_with_id($startup_id);
	}
	else {
	    Gtk2::Gdk->notify_startup_complete();
	}
	return 'ok';
});

$xde->launch(undef,undef,$ops{appid}) if $ops{appid};

$SIG{TERM} = sub{$xde->main_quit};
$SIG{INT}  = sub{$xde->main_quit};
$SIG{QUIT} = sub{$xde->main_quit};

$xde->main;

$xde->term;

exit(0);

sub show_usage {
    return <<EOF
USAGE:
    xde-monitor [OPTIONS]

OPTIONS:
    --help, -h
	print this usage info and exit.

    --verbose, -v
	print diagnostic information to standard error while operating.

    --display, -d DISPLAY	[default: $ops{display}]
	specifies the X Display to use.

EOF
}

1;

__END__

=head1 NAME

xde-monitor -- monitor startup notification

=head1 SYNOPSIS

xde-monitor [OPTIONS]

=head1 DESCRIPTION

B<xde-monitor> is an L<X11::Protocol(3pm)> application that can be used
to monitor XDG application program launching using startup notification
and assist light-weight window managers with completion of startup
notification.

=head1 OPTIONS

=over 4

=item B<--help>, B<-h>

=item B<--verbose>, B<-v>

=item B<--charset>, B<-c> I<CHARSET>

=item B<--language>, B<-L> I<LANGUAGE>

=item B<--grab>, B<-g>

=item B<--display>, B<-d> I<DISPLAY>

Specifies the X display to use.  This is not normally necessary as the
display is obtained from the C<DISPLAY> environment variable when this
option is not specified.

=back

=head1 BEHAVIOR

B<xde-monitor> uses L<Gtk2::Unique(3pm)> to ensure that only one
instance of the monitor exists per X Display.  Havoc would rule
otherwise.  When B<xde-monitor> starts it establishes a list of mapped
top-level client windows from the ICCCM compliant window manager by
searching the tree for windows with a B<WM_STATE> property.

=head1 WINDOW MANAGERS

=over

=item L<fluxbox(1)>

=item L<blackbox(1)>

=item L<openbox(1)>

=item L<icewm(1)>

=item L<pekwm(1)>

=item L<jwm(1)>

=item L<wmaker(1)>

=item L<fvwm(1)>

=item L<afterstep(1)>

=item L<metacity(1)>

=item L<wmx(1)>

=back

=head1 HISTORY

There are several window managers that perform startup notification and
startup notification completion for applications that will not send a
C<remove> message: L<openbox(1)> and L<metacity(1)> do. However, most
other light-weight window managers do not support this function.  Rather
than rewrite the same addition six or seven times in the style of each
window manager, I wrote B<xde-monitor> to perform this function for the
window manager.

=head1 AUTHOR

Brian Bidulock <bidulock@openss7.org>

=head1 SEE ALSO

L<XDE::Monitor(3pm)>,
L<XDE(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
