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
use XDE::Chooser;
use strict;
use warnings;

#use Gtk2;
#Gtk2::Rc->set_default_files("$ENV{HOME}/.gtkrc-2.0.xde");

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
    icons	=> '',
    vendor	=> '',
    session	=> '',
    xdg_rcdir	=> 1,
    tmp_menu	=> 1,
    dry_run     => 1,
);

use constant {
    SIDES=>{top=>1,bottom=>2,left=>3,right=>4},
};

my $syntax = GetOptions(
    'help|h'	    => \$ops{help},
    'verbose|v'     => \$ops{verbose},
    'prompt|p!'	    => \$ops{prompt},
    'banner|b=s'    => \$ops{banner},
    'side|s=s'	    => sub{$ops{side} = $_[1] if &SIDES->{$_[1]}},
    'noask|n'	    => \$ops{noask},
    'charset|c=s'   => \$ops{charset},
    'language|l=s'  => \$ops{language},
    'setdflt|d'	    => \$ops{setdflt},
    'icons|i'	    => \$ops{icons},
    'vendor|V=s'    => \$ops{vendor},
    'session|s=s'   => \$ops{session},
    'xdg_rcdir|x!'  => \$ops{xdg_rcdir},
    'tmp_menu|t!'   => \$ops{tmp_menu},
    'dry_run|r!'    => \$ops{dry_run},
);

$ops{choice} = shift @ARGV if @ARGV;
$ops{choice} = "\L$ops{choice}\E" if $ops{choice};
$ops{choice} = 'default' unless $ops{choice};
$ops{choice} = $ops{default} if $ops{choice} eq 'default' and $ops{default};

if (@ARGV) {
    print STDERR "Too many arguments.\n";
    show_usage();
    exit(2);
}

my $xde = XDE::Chooser->new(%OVERRIDES,ops=>\%ops);
$xde->getenv;

$xde->show_settings;

$xde->default; # reset defaults

$xde->show_settings;

if ($ops{help} or not $syntax) {
    show_usage();
    exit ($syntax ? 0 : 2);
}

print STDERR "Overrides: ", join(',',%OVERRIDES), "\n" if $ops{verbose};

my ($result,$entry,$managed) = $xde->choose;

if ($result eq 'logout') {
    print STDERR "Logging out...\n" if $ops{verbose};
    print STDOUT $result;
}
else {
    print STDERR "Launching session $result...\n" if $ops{verbose};
    print STDOUT $result;
    # the other thing to do here is to pass $entry directly to an
    # instance of XDE::Startup.
    $xde->create_session($result,$entry,$managed);
}

exit(0);

sub show_usage {
    print STDERR <<EOF;
USAGE:
    xde-chooser [OPTIONS] [SESSION]

ARGUMENTS:
    SESSION                 [default: $ops{choice}]
        specifies the name of the session to choose; special values
        include: 'default' and 'choose'.  The default when unspecified
        is 'choose'.

OPTIONS:
    --help, -h
        print this usage information and exit.

    --verbose, -v	    [default: $ops{verbose}]
        print debugging information to standard error during operation.

    --prompt, -p	    [default: $ops{prompt}]
        prompt the user for the session regardless of the value of the
        SESSION argument.

    --banner, -b BANNER     [default: $ops{banner}]
        specifies a custom login logo; depends on environment variables
        when not unspecified.

    --noask, -n		    [default: $ops{noask}]
        do not ask the user whether she wishes to set the current
        session as the default session when SESSION is specified or
        chosen as something different than the current default.

    --charset, -c CHARSET   [default: $ops{charset}]
        specify the character set to use to output the menu; defaults to
        the charset of the current locale.

    --language, -l LANGUAGE [default: $ops{language}]
        specify the language to use to output the menu; defaults to the
        value of the current locale.

    --setdflt, -s	    [default: $ops{setdflt}]
        also set the default to the selected SESSION.

    --icons, -i		    [default: $ops{icons}]

    --vendor, -V VENDOR	    [default: $ops{vendor}]
        specify the vendor string, VENDOR, for branding.

    --exec, -e
        execute the Exec= action from the xsessions file rather than
        returning a string

FILES:
    $xde->{XDE_BANNER_FILE}
	the file containing the branding banner.

    $xde->{XDE_DEFAULT_FILE}
        the file containing the default session.

    $xde->{XDE_CURRENT_FILE}
        the file containing the current session.

ENVIRONMENT:
    XDG_DATA_HOME       [default: $xde->{XDG_DATA_HOME}]
        specifies the user data directory.

    XDG_DATA_DIRS       [default: $xde->{XDG_DATA_DIRS}]
        specifies the system data directory.

    XDG_CONFIG_HOME     [default: $xde->{XDG_CONFIG_HOME}]
        specifies the user configuration directory.

    XDG_CONFIG_DIRS     [default: $xde->{XDG_CONFIG_DIRS}]
        specifies the system configuration directory.

    XDG_CURRENT_DESKTOP [default: $xde->{XDG_CURRENT_DESKTOP}]
    DESKTOP_SESSION     [default: $xde->{DESKTOP_SESSION}]
    FBXDG_DE            [default: $xde->{FBXDG_DE}]
        can also be used to specify the session

EOF
}

1;

__END__

=head1 NAME

xde-chooser -- choose and XDG desktop session to execute

=head1 SYNOPSIS

B<xde-chooser> [I<OPTIONS>] [I<SESSION>]

=head1 DESCRIPTION

B<xde-chooser> is a gtk2-perl application that can be launched from
F<~/.xinitrc> to choose the X session that will be launched, or can be
launched from a window manager or session logout script to switch the
sessions.  The menu can also provide the choice for the user to perform
actions on the box such as powering off the computer, restarting the
computer, etc.

When a selection is made or logout/disconnect is selected,
B<xde-chooser> prints the selected session name or the special name
C<logout> to standard output and exits with a zero exit status.  On
error, a diagnostic message is printed to standard error and a non-zero
exit status is returned.

=head1 OPTIONS

B<xde-chooser> uses L<Getopt::Long(3pm)> to parse options, so
abbreviated or single-dash long options are recognized when not
ambiguous.  B<xde-chooser> accepts the following options:

=over

=item B<--help>, B<-h>

Print usage information to standard error containing current defaults
and exit.

=item B<--verbose>, B<-v>

Print debugging information to standard error during operation.

=item B<--prompt>, B<-p>

Prompt the user for the session regardless of the value of the
I<SESSION> argument.

=item B<--banner>, B<-b> I<BANNER>

Specifies a custom login logo.  When unspecified, B<xde-chooser> will
use a branded logo that depends on environment variables.  This option
is compatible with L<xde-logout(1)>.

=item B<--side>, B<-s> {B<left>|B<top>|B<right>|B<bottom>}

Specifies the side of the window on which the logo will be placed.  This
option is recognized for compatability with L<lxsession-logout(1)>.
B<xde-logout> always places the logo on the left and this option is
ignored.

=item B<--noask>, B<-n>

Do not ask the user whether she wishes to set the current session as the
default session when I<SESSION> is specified or chosen as something
different than the current default.

=item B<--charset>, B<-c> I<CHARSET>

Specify the character set with which to output the menu.  Defaults to
the character set in use by the current locale.

=item B<--language>, B<-l> I<LANGUAGE>

Specify the output language for the menu.  Defaults to the language set
in the current locale.

=item B<--default>, B<-d>

When a I<SESSION> is specified, also set the future default to I<SESSION>.

=item B<--icons>, B<-i> I<THEME>

Specifies the icon theme to use.  Otherwise, the user's default gtk2
icon theme will be used (i.e. from F<$HOME/.gtkrc-2.0>).

=item B<--theme>, B<-t> I<THEME>

Specifies the Gtk2 theme to use.  Otherwise, the user's default gtk2
theme will be used (i.e. from F<$HOME/.gtkrc-2.0>).

=item B<--exec>, B<-e>

Execute the C<Exec=> action from the xsessions file instead of returning
a string indicating the selected xsession.

=back

=head1 ARGUMENTS

B<xde-chooser> take the following arguments:

=over

=item I<SESSION>

The name of the XDG session to execute.  This can be any of the
recognized session names or the special names: C<default> or C<choose>.

=over

=item C<default>

means to execute the default session (typically without
prompting).

=item C<choose>

means to launch a graphical menu so that the use may choose a
session.

=back

When unspecified, the default is C<default>.

A session name is the name of the F<*.desktop> file (without the
F<.desktop> suffix) that exists in a F<@XDG_DATA_DIRS/xsessions/>
directory describing the window manager session.
Some commonly recognized session names are as follows: C<fluxbox>,
C<blackbox>, C<openbox>, C<icewm>, C<pekwm>, C<jwm>, C<metacity>,
C<fvwm>, C<wmaker> and C<afterstep>.

=back

=head1 WINDOW MANAGERS

The I<XDE> suite ships with a number of session files that are contained
in the F</usr/share/xde/xsessions> directory.  Currently these are:
F<AfterStep>, F<blackbox>, F<fluxbox>, F<Fvwm1>, F<fvwm-crystal>,
F<Fvwm>, F<fvwm>, F<gnome>, F<icewm-session>, F<Jwm>, F<LXDE>,
F<openbox>, F<openbox-gnome>, F<openbox-kde>, F<pekwm>, F<ssh>, F<twm>,
F<wmaker>, F<wmii>, F<xfce>.

=head1 FILES

=over

=item F<@XDG_DATA_DIRS/xsessions/*.desktop>

These locations are searched for F<.desktop> files that describe which X
Sessions are to be made available to the user.  Files in this directory
can be desktop files of type I<Application> or I<XSession>.  A I<Window
Manager> section may also describe whether the session needs to be
managed or whether the window manager is capable of managing its own
session.  Desktop entry files in data directories earlier in the search
path override desktop entry files of the same filename later in the
search path.

The I<XDE> suite ships with a number of F<*.desktop> files that are
installed into the F</usr/share/xde/xsessions> directory and are used to
override those for I<gdm> that are normally contained in
F</usr/share/xsessions>.  (To do this, B<xde-chooser> prepends the path
F</usr/share/xde> to the B<XDG_DATA_DIRS> environment variable.)

For a set of these window managers, B<xde-chooser> will execute
L<xde-startup(1)> with the session as an argument.  See
L<xde-startup(1)/WINDOW MANAGERS> for a list of supported window
managers.

=item F<$XDG_CONFIG_HOME/xde/default>

This file contains the default session.  The file consists of a single
line containing the session name.

=item F<$XDG_CONFIG_HOME/xde/current>

This file contains the current session.  The file consists of a single
line containing the session name.

=back

=head1 ENVIRONMENT

=over

=item B<XDG_DATA_HOME>

Specifies the user XDG data directory.  When unspecified, defaults to
F<$HOME/.local/share> in accordance with XDG specifications.
B<xde-chooser> uses this directory to determine the list of default data
directories to search.

=item B<XDG_DATA_DIRS>

Specifies the system XDG data directories.  When unspecified, defaults
to F</usr/local/share:/usr/share> in accordance with XDG specifications.
The directory F</usr/share/xde> will be prefixed to the path unless the
directory is already a component of the path.
B<xde-chooser> uses these directories to determine the list of default
data directories to search.

=item B<XDG_CONFIG_HOME>

Specifies the user XDG configuration directory.  When unspecified,
defaults to F<~/.config> in accordance wtih XDG specifications.
B<xde-chooser> uses this directory to find its configuration files that
are located under F<$XDG_CONFIG_HOME/xde>.

=item B<XDG_CONFIG_DIRS>

Specifies the system XDG configuration directory.  When unspecified,
defaults to F</etc/xdg> in accordance with XDG specifications.
The directory F</etc/xdg/xde> will be prefixed to the path unless the
directory is already a component of the path.
B<xde-chooser> uses these directories to determine the list of default
configuration directories to search.

=back

=head1 USAGE

B<xde-chooser> is meant to be called directly from an F<~/.xinitrc>
file, or from a display manager such as L<slim(1)>.

=head1 BUGS

B<xde-chooser> should really output the path to the F<XSessions> file
instead of the lowercase session name.

=head1 HISTORY

I wrote B<xde-chooser> to provide a mechanism for selecting availabile
window managers in an XDG compliant way for the I<unexicon> desktop.
With L<gdm(1)> going to GTK3, the I<unexicon> desktop uses L<xdm(1)>,
L<slim(1)> and L<xde-chooser(1p)> instead.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<Getopt::Long(3pm)>,
L<xde-logout(1)>,
L<lxsession-logout(1)>,
L<xde-startup(1)>,
L<XDE::Chooser(3pm)>.

=cut

# vim: sw=4 tw=72
