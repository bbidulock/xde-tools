package X11::Protocol::WindowManager;
use X11::Protocol::Xlib		qw(:all);
use X11::Protocol::WMSpecific	qw(:all);
use X11::Protocol::Util		qw(:all);
use X11::Protocol::ICCCM	qw(:all);
use X11::Protocol::WMH		qw(:all);
use X11::Protocol::EWMH		qw(:all);
use X11::Protocol;
use Sys::Hostname;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

=head1 NAME

X11::Protocol::WindowManager -- window manager base class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

=item $X = X11::Protocol::WindowManager->B<new>(I<$X>)

Creates a new instance of an X11::Protocol::WindowManager object.  When
the passed argument, I<$X>, is C<undef>, a new X11::Protocol object will
be created.  Otherwise, if an X11::Protocol object is passed, it will be
initialized and blessed as an X11::Protocol::WindowManager object.

=cut

sub new {
    my ($type,$X) = @_;
    $X = X11::Protocol::WMSpecific::new($type, $X);
    for (my $i=0;$i<@{$X->{screens}};$i++) {
	$X->{screens}[$i]{screen} = $i;
    }
    return $X;
}

=back

=head2 PROC FILESYSTEM METHODS

The following methods provide access to information in the F</proc>
filesystem for a given process id.

=over

=cut

=item B<get_proc_file>(I<$pid>,I<$name>) => I<$contents> or undef

Return the contents of the file F</proc/$pid/$name> or C<undef> when the
file does not exist or cannot be accessed.

=cut

sub get_proc_file {
    my ($pid, $name) = @_;
    return undef unless $pid;
    my $file = "/proc/$pid/$name";
    return undef unless -f $file;
    my $result;
    open my $fh, "<", $file or return undef;
    {
	local $/;
	$result = <$fh>;
    }
    close $fh;
    return $result
}

=item B<get_proc_link>(I<$pid>,I<$name>) => I<$target> or undef

Gets the target of the symbolic link F</proc/$pid/$name> or C<undef>
when the link does not exist or cannot be accessed.

=cut

sub get_proc_link {
    my ($pid, $name) = @_;
    return undef unless $pid;
    my $link = "/proc/$pid/$link";
    return undef unless -l $link;
    return readlink $link;
}

=item B<get_environ>(I<$pid>) => I<\%environ>

Returns a reference to the environment of the process id, I<$pid>, or,
when that fails, returns a reference to I<%ENV> (the environment of the
current process).

=cut

sub get_environ {
    my $pid = shift;
    return \%ENV unless $pid;
    my $contents = get_proc_file($pid, 'environ') or return \%ENV;
    return { map{split(/=/,$_,2)}unpack('(Z*)*',$contents) };
}

=item B<get_proc_comm>(I<$pid>) => I<$comm> or undef

=cut

=item B<get_proc_exe>(I<$pid>) => I<$exe> or undef

Gets the current executable file, I<$exe>, or C<undef> when the
F</proc/$pid/exe> symbolic link cannot be read or accessed.

=cut

sub get_proc_exe {
    return get_proc_link(shift, 'exe');
}

=item B<get_proc_cwd>(I<$pid>) => I<$cwd> or undef

Gets the current working directory, I<$cwd>, or C<undef> when the
F</proc/$pid/cwd> symbolic link cannot be read or accessed.

=cut

sub get_proc_cwd {
    return get_proc_link(shift, 'cwd');
}

=item B<get_proc_environ>(I<$pid>, I<$name>) => I<$value> or undef

Gets the value of the environment variable named I<$name> for the
process id I<$pid>.

=cut

sub get_proc_environ {
    my ($pid, $name) = @_;
    my $environ = get_environ($pid) or return undef;
    return undef unless exists $environ->{$name};
    return $environ->{$name};
}

=item B<get_xdg_dirs>(I<$pid>)

=cut

sub get_xdg_dirs {
    my $pid = shift;
    my $env = get_environ($pid);
    my $home = $env->{HOME} or ".";

    my $dhome = $env->{XDG_DATA_HOME} or "$home/.local/share";
    my $ddirs = $env->{XDG_DATA_DIRS} or "/usr/local/share:/usr/share";
    my @data = split(/:/,"$dhome:$ddirs");

    my $chome = $env->{XDG_CONFIG_HOME} or "$home/.config";
    my $cdirs = $env->{XDG_CONFIG_DIRS} or "/etc/xdg";
    my @conf = split(/:/,"$chome:$cdirs");

    return \@data, \@conf if wantarray;
    return [ \@data, \@conf ];
}

sub find_theme {
    my ($wm,$name) = @_;
    ($wm->{xdg_data},$wm->{xdg_conf}) = get_xdg_dirs($wm->{pid})
	unless $wm->{xdg_data};
    foreach my $dir (@{$wm->{xdg_data}})
	return 1 if -f "$dir/themes/$name/xde/theme.ini";
    return 0;
}

=back

=head2 WINDOW MANAGER DETECTION

=over

=cut

=item B<check_name>(I<$X>,I<$check>) => I<$name> or C<undef>

Determine the name of a window manager from the check window, I<$check>.

=cut

sub check_name {
    my($X,$check,$name) = @_;
    return undef unless $check;
    $name = get_NET_WM_NAME($X, $check);
    $name = getWM_NAME($X, $check) unless $name;
    unless ($name) {
	if ((my $hints = getWM_CLASS($X, $check))) {
	    $name = $hints->{res_name};
	    $name = $hints->{res_class} unless $name;
	}
    }
    unless ($name) {
	if ((my $argv = getWM_COMMAND($X, $check))) {
	    $name = $argv->[0];
	}
    }
    return undef unless $name;
    $name =~ s{^.*/}{};
    $name =~ s{^\s*}{};
    $name =~ s{\s.*$}{};
    $name = "\L$name\E";
    return $name;
}

sub find_wm_name {
    my($X,@checks) = @_;
    my $name = undef;
    foreach my $check (@checks) {
	next unless $check;
	$name = check_name($X, $check) and last;
    }
    return $name;
}

=item B<check_host>(I<$X>,I<$check>) => I<$name> or C<undef>

Determine the host of a window manager from the check window, I<$check>.

=cut

sub check_host {
    my($X,$check,$host);
    return undef unless $check;
    return getWM_CLIENT_MACHINE($X, $check);
}

=item B<find_wm_host>(I<$X>,I<$wm>) => I<$host> or C<undef>

=cut

sub find_wm_host {
    my($X,$wm) = @_;
    my $host = undef;
    foreach my $check (@{$wm->{checks}}) {
	next unless $check;
	$host = check_host($X, $check) and last;
    }
    $wm->{host} = $host;
    return $host;
}

=item B<check_pid>(I<$X>,I<$check>,[I<$name>]) => I<$pid> or C<undef>

Determine pid of a window manager from the check window, I<$check>.
When available, the name of the window manager, I<$name>, should be
provided.

=cut

sub check_pid {
    my($X,$check,$name,$pid);
    return undef unless $check;
    $pid = get_NET_WM_PID($X, $check);
    if (not $pid and $name and $name eq 'fluxbox') {
	$pid = get_BLACKBOX_PID($X, $check);
    }
    if (not $pid and $name and $name eq 'openbox') {
	$pid = get_OPENBOX_PID($X, $check);
    }
    return undef unless $pid;
}

=item B<find_wm_pid>(I<$X>,I<$wm>) => I<$pid> or C<undef>

=cut

sub find_wm_pid {
    my($X,$wm) = @_;
    my $pid = undef;
    foreach my $check (@{$wm->{checks}}) {
	next unless $check;
	$pid = check_pid($X, $check, $wm->{wmname}) and last;
    }
    $wm->{pid} = $pid;
    return $pid;
}

=item B<check_comm>(I<$X>,I<$check>) => I<$argv> or C<undef>

Determine the command arguments of a window manager from the check
window, I<$check>.  When found, returns a reference to the argument
array.

=cut

sub check_comm {
    my($X,$check,$argv) = @_;
    return undef unless $check;
    return getWM_COMMAND($X, $check);
}

=item B<find_wm_comm>(I<$X>,I<$wm>) => I<$argv> or C<undef>

=cut

sub find_wm_comm {
    my($X,$wm) = @_;
    my $argv = undef;
    foreach my $check (@{$wm->{checks}}) {
	next unless $check;
	$argv = check_comm($X, $check) and last;
    }
    $wm->{comm} = $argv;
    return $argv;
}

=item B<check_proc>(I<$X>)

=item B<find_wm_proc>(I<$X>,I<$wm>)

=back

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
