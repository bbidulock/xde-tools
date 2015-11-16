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

=head1 NAME

 xde-traymenu - an XDG compliant system tray menu

=head1 SYNOPSIS

 xde-traymenu [OPTIONS]

=head1 DESCRIPTION

B<xde-traymenu> provides an XDG compliant system tray menu.  The tool is
capable of generating XDG applications menus as well as window-manager
specific menus for a number of window-managers.

=cut

use File::Which qw(which);
use Getopt::Long;
use Encode qw(encode decode);
use I18N::Langinfo qw(langinfo CODESET);
use POSIX qw(locale_h);
use MIME::Base64;
use Storable qw(nfreeze thaw);
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::Unique;
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

my $executable = $0;
my $program = $0; $program =~ s{^.*/}{};

Gtk2::Rc->set_default_files("$ENV{HOME}/.gtkrc-2.0.xde");

#if ($here !~ m{^/usr/bin}) {
#	Gtk2::Rc->set_default_files("$here/themes/Unexicon/gtk-2.0/gtkrc", "$here/gtkrc-2.0");
#} else {
#	Gtk2::Rc->set_default_files("$ENV{HOME}/.gtkrc-2.0.mine");
#}
#
#Gtk2::Rc->parse_string('gtk-theme-name="Squared-blue"'."\n");

Gtk2->init;

sub reparse {
	my ($root,$property) = @_;
	my ($type,$format,@data) = $root->property_get($property,undef,0,255,FALSE);
	if ($type and $data[0]) {
		Gtk2::Rc->reparse_all;
		Gtk2::Rc->parse_string("gtk-theme-name=\"$data[0]\"");
	}
}

{
	my $manager = Gtk2::Gdk::DisplayManager->get;
	my $dpy = $manager->get_default_display;
	my $screen = $dpy->get_default_screen;
	my $root = $screen->get_root_window;
	my $property = Gtk2::Gdk::Atom->new(_XDE_THEME_NAME=>FALSE);

	$root->set_events([qw(property-change-mask structure-mask substructure-mask)]);

	Gtk2::Gdk::Event->handler_set(sub{
		my ($event,$data) = @_;
		if (($event->type eq 'client-message' and $event->message_type->name eq "_GTK_READ_RCFILES") ||
		    ($event->type eq 'property-notify' and $event->atom->name eq "_XDE_THEME_NAME")) {
			reparse($root,$property);
			return;
		}
		Gtk2->main_do_event($event);
	},$root);

	reparse($root,$property);
}

require XDG::Menu::Parser;
require XDG::Menu::Tray;

my $HOME = $ENV{HOME} if $ENV{HOME};
$HOME = '~' unless $HOME;

my $XDG_CURRENT_DESKTOP = $ENV{XDG_CURRENT_DESKTOP} if $ENV{XDG_CURRENT_DESKTOP};
$XDG_CURRENT_DESKTOP = '' unless $XDG_CURRENT_DESKTOP;
$ENV{XDG_CURRENT_DESKTOP} = $XDG_CURRENT_DESKTOP if $XDG_CURRENT_DESKTOP;

my $XDG_CONFIG_HOME = $ENV{XDG_CONFIG_HOME} if $ENV{XDG_CONFIG_HOME};
$XDG_CONFIG_HOME = "$HOME/.config" unless $XDG_CONFIG_HOME;
$ENV{XDG_CONFIG_HOME} = $XDG_CONFIG_HOME if $XDG_CONFIG_HOME;

my $XDG_CONFIG_DIRS = $ENV{XDG_CONFIG_DIRS} if $ENV{XDG_CONFIG_DIRS};
$XDG_CONFIG_DIRS = "/etc/xdg" unless $XDG_CONFIG_DIRS;
$ENV{XDG_CONFIG_DIRS} = $XDG_CONFIG_DIRS if $XDG_CONFIG_DIRS;

my @XDG_CONFIG_DIRS = (split(/:/,join(':',$XDG_CONFIG_HOME,$XDG_CONFIG_DIRS)));

my $XDG_DATA_HOME = $ENV{XDG_DATA_HOME} if $ENV{XDG_DATA_HOME};
$XDG_DATA_HOME = "$HOME/.local/share" unless $XDG_DATA_HOME;
$ENV{XDG_DATA_HOME} = $XDG_DATA_HOME if $XDG_DATA_HOME;

my $XDG_DATA_DIRS = $ENV{XDG_DATA_DIRS} if $ENV{XDG_DATA_DIRS};
$XDG_DATA_DIRS = "/usr/local/share:/usr/share" unless $XDG_DATA_DIRS;
$ENV{XDG_DATA_DIRS} = $XDG_DATA_DIRS if $XDG_DATA_DIRS;

my @XDG_DATA_DIRS = (split(/:/,join(':',$XDG_DATA_HOME,$XDG_DATA_DIRS)));

my $XDG_MENU_PREFIX = $ENV{XDG_MENU_PREFIX} if $ENV{XDG_MENU_PREFIX};
$XDG_MENU_PREFIX = '' unless $XDG_MENU_PREFIX;
$ENV{XDG_MENU_PREFIX} = $XDG_MENU_PREFIX if $XDG_MENU_PREFIX;

my $XDG_MENU_NAME = 'applications';

my @XDG_MENU_DIRS = map {"$_/menus"} @XDG_CONFIG_DIRS;

my $XDG_ROOT_MENU = '';
foreach my $name (
	"${XDG_MENU_PREFIX}${XDG_MENU_NAME}.menu",
	"${XDG_MENU_NAME}.menu") {
    foreach (@XDG_MENU_DIRS) {
	if (-f "$_/$name") {
	    $XDG_ROOT_MENU = "$_/$name";
	    last;
	}
    }
    last if $XDG_ROOT_MENU;
}

my $XDG_ICON_THEME = $ENV{XDG_ICON_THEME} if $ENV{XDG_ICON_THEME};
unless ($XDG_ICON_THEME) {
    if (-f "$HOME/.gtkrc-2.0") {
        my @lines = (`cat $ENV{HOME}/.gtkrc-2.0`);
        foreach (@lines) { chomp;
            if (m{gtk-icon-theme-name=["]?(.*[^"])["]?$}) {
                $XDG_ICON_THEME = "$1";
                last;
            }
        }
    } else {
        $XDG_ICON_THEME = 'hicolor';
    }
}
$ENV{XDG_ICON_THEME} = $XDG_ICON_THEME if $XDG_ICON_THEME;

my $XDG_ICON_DIRS = join(':',"$HOME/.icons",map{"$_/icons"}@XDG_DATA_DIRS,'/usr/share/pixmaps');
my @XDG_ICON_DIRS = split(/:/,$XDG_ICON_DIRS);

my %outputs = (
    fluxbox	=> [ "$HOME/.fluxbox/menu" ],
    blackbox	=> [ "$HOME/.blackbox/menu", "$HOME/.bbmenu" ],
    openbox	=> [ "$HOME/.openbox/menu", "$HOME/.config/openbox/menu" ],
    icewm	=> [ "$HOME/.icewm/menu" ],
    pekwm	=> [ "$HOME/.pekwm/menu" ],
    jwm		=> [ "$HOME/.jwm/menu" ],
    fvwm	=> [ "$HOME/.fvwm/menu" ],
    wmaker	=> [ "$HOME/GNUstep/Defaults/WMRootMenu" ],
    ctwm	=> [ "$HOME/.ctwm/menu" ],
    vtwm	=> [ "$HOME/.vtwm/menu" ],
    twm		=> [ "$HOME/.twm/menu" ],
    echinus	=> [ "$HOME/.echinus/menu" ],
    awesome	=> [ "$HOME/.awesome/menu" ],
    adwm	=> [ "$HOME/.adwm/menu" ],
    waimea	=> [ "$HOME/.waimea/menu" ],
);

my %formats = (
    fluxbox	=> [qw(FLUXBOX	XDG::Menu::Tray::Fluxbox	)],
    blackbox	=> [qw(BLACKBOX	XDG::Menu::Tray::Blackbox	)],
    openbox	=> [qw(OPENBOX	XDG::Menu::Tray::Openbox	)],
    openbox3	=> [qw(LXDE	XDG::Menu::Tray::Openbox3	)],
    icewm	=> [qw(ICEWM	XDG::Menu::Tray::Icewm		)],
    pekwm	=> [qw(PEKWM	XDG::Menu::Tray::Pekwm		)],
    jwm		=> [qw(JWM	XDG::Menu::Tray::Jwm		)],
    fvwm	=> [qw(FVWM	XDG::Menu::Tray::Fvwm		)],
    wmaker	=> [qw(WMAKER	XDG::Menu::Tray::Wmaker		)],
    ctwm	=> [qw(CTWM	XDG::Menu::Tray::Ctwm		)],
    vtwm	=> [qw(VTWM	XDG::Menu::Tray::Vtwm		)],
    twm		=> [qw(TWM	XDG::Menu::Tray::Twm		)],
    echinus	=> [qw(ECHINUS	XDG::Menu::Tray::Echinus	)],
    awesome	=> [qw(AWESOME	XDG::Menu::Tray::Awesome	)],
    adwm	=> [qw(ADWM	XDG::Menu::Tray::Adwm		)],
    mwm		=> [qw(MWM	XDG::Menu::Tray::Mwm		)],
    waimea	=> [qw(WAIMEA	XDG::Menu::Tray::Waimea		)],
);

my %desktops = (
    FLUXBOX	=> [qw(fluxbox	XDG::Menu::Tray::Fluxbox	)],
    BLACKBOX	=> [qw(blackbox	XDG::Menu::Tray::Blackbox	)],
    OPENBOX	=> [qw(openbox	XDG::Menu::Tray::Openbox	)],
    ICEWM	=> [qw(icewm	XDG::Menu::Tray::Icewm		)],
    PEKWM	=> [qw(pekwm	XDG::Menu::Tray::Pekwm		)],
    JWM		=> [qw(jwm	XDG::Menu::Tray::Jwm		)],
    FVWM	=> [qw(fvwm	XDG::Menu::Tray::Fvwm		)],
    WMAKER	=> [qw(wmaker	XDG::Menu::Tray::Wmaker		)],
    CTWM	=> [qw(ctwm	XDG::Menu::Tray::Ctwm		)],
    VTWM	=> [qw(vtwm	XDG::Menu::Tray::Vtwm		)],
    TWM		=> [qw(twm	XDG::Menu::Tray::Twm		)],
    ECHINUS	=> [qw(echinus	XDG::Menu::Tray::Echinus	)],
    AWESOME	=> [qw(awesome	XDG::Menu::Tray::Awesom		)],
    LXDE	=> [qw(openbox3 XDG::Menu::Tray::Openbox3	)],
    ADWM	=> [qw(adwm	XDG::Menu::Tray::Adwm		)],
    MWM		=> [qw(mwm	XDG::Menu::Tray::Mwm		)],
    WAIMEA	=> [qw(waimea	XDG::Menu::Tray::Waimea		)],
);


=head1 OPTIONS

B<xde-traymenu> accepts the following options:

=head2 COMMAND OPTIONS

The default when no command option is specified is to launch the
traymenu.  Only one instance of a tray menu will be launched for one
display at one time.

When specified, the following options alter the primary operating mode
of B<xde->traymenu>:

=over

=item B<--help>, B<-h>

Print usage information, including the current values of option
defaults, and exit.

=item B<--refresh>, B<-r>

Asks a running instance of B<xde-traymenu> to refresh the menu.  This is
normally not required as B<xde-traymenu> detects when desktop files or
icons or theme files have changed.

This is the default when B<xde-traymenu> is invoked as
B<xde-traymenu-refresh>.
This option causes an error when no current instance of B<xde-traymenu>
is running.

=item B<--restart>, B<-R>

Asks a running instance of B<xde-traymenu> to restart (re-execute itself
with the same arguments).  This is useful when the B<xde-traymenu>
executables have been upgraded.

This is the default when B<xde-traymenu> is invoked as
B<xde-traymenu-restart>.
This option causes an error when no current instance of B<xde-traymenu>
is running.

=item B<--quit>, B<-q>

Asks a running instance of B<xde-traymenu> to quit.

This is the default when B<xde-traymenu> is invoked as
B<xde-traymenu-quit>.
This option causes an error when no current instance of B<xde-traymenu>
is running.

=item B<--popup>, B<-p>

Asks a running instance of B<xde-traymenu> to popup the menu.  Depending
on the setting of the B<--button> option, this will either popup the
menu at the current pointer position, or will popup the menu at the
center of the screen.  When multiple monitors are present, the menu will
popup at the center of the monitor in which the pointer currently
resides (which is used by most tiling window managers as the "current"
monitor).

This is the default when B<xde-traymenu> is invoked as
B<xde-traymenu-popup>.
This option causes an error when no current instance of B<xde-traymenu>
is running.

=back

=head2 GENERAL OPTIONS

The following options are general options:

=over

=item B<--verbose>, B<-v>

Print debugging information on standard error during operation.

=item B<--format>, B<-f> I<FORMAT>

Specify the output format.  Recognized output formats are as follows:
L<fluxbox(1)>, L<blackbox(1)>, L<openbox(1)>, L<icewm(1)>, L<jwm(1)>,
L<pekwm(1)>, L<fvwm(1)>, L<wmaker(1)>, L<afterstep(1)>, L<metacity(1)>,
L<twm(1)>, L<ctwm(1)>, L<vtwm(1)>, L<etwm(1)>, L<cwm(1)>, L<echinus(1)>,
L<uwm(1)>, L<awesome(1)>, L<matwm2(1)>, L<waimea(1)>, L<2bwm(1)>,
L<wmx(1)>, L<flwm(1)>, L<mwm(1)>, L<dtwm(1)>, L<spectrwm(1)>,
L<yeahwm(1)>.

When unspecified and L<xde-identify(1)> is available, B<xde-traymenu>
uses L<xde-identify> to identify a running window manager.

When unspecified and either L<xde-identify> is unavailable, or cannot
determine a running window manager, the setting of the
B<XDG_CURRENT_DESKTOP> environment variable is used to determine the
format.  This is accomplished by converting the value of
B<XDG_CURRENT_DESKTOP> to lower-case.  See L</ENVIRONMENT>.

When the B<XDG_CURRENT_DESKTOP> environment variable is undefined, the X
Display is examined to determine the window-manager in use.  See
L</X RESOURCES>.

=item B<--fullmenu>, B<-F>, B<--nofullmenu>, B<-N>

When specified, output a full menu and not only the application
sub-menu, or not.  The default is to output a full menu.

=item B<--desktop>, B<-d> I<DESKTOP>

Specify the desktop name for C<NotShowIn> and C<OnlyShowIn> comparisons.
The default is the all upper-case value corresponding to the format
unless B<XDG_CURRENT_DESKTOP> is defined (see L</ENVIRONMENT>).

=item B<--charset>, B<-c> I<CHARSET>

Specify the character set with which to output the menu.  Defaults to
the character set in use by the current locale.

=item B<--language>, B<-l> I<LANGUAGE>

Specify the output language for the menu.  Defaults to the language set
in the current locale.

=item B<--root-menu>, B<-r> I<MENU>

Specify the location of the root menu file.  The default is calculated
using XDG environment variables (see L</ENVIRONMENT>), and defaults to
the file F<${XDG_MENU_PREFIX}applications.menu> in the
F<$XDG_CONFIG_HOME:$XDG_CONFIG_DIRS> search path.

=item B<--die-on-error>, B<-e>

Abort execution on any error.

=item B<--output>, B<-o> [I<FILENAME>]

Write output to the file, I<FILENAME>.  This is particularly useful with
option B<--die-on-error> as the output will not be written at all if an
error is encountered.  If the I<FILENAME> is not specified, the default
menu location for the current B<--format> will be used.

=item B<--noicons>, B<-n>

Do not include icons in the generated menu files.  This option has no
effect when it is not possible to generate icons for the menu format.
That is, when the B<--format> is one such as C<blackbox>, it is not
possible to place icons in the menu and this option is therefore
ignored.  The default is to place icons in capable generated menus.

=item B<--theme>, B<-t> THEME

Specify the icon theme name to use when generating icons.  The default
is to obtain the icon theme name from default locations (such as the
F<$HOME/.gtkrc-2.0> file).

=item B<--monitor>, B<-m>

Specifies that B<xde-traymenu> is not to exit after successfully
generating the menu, but to monitor pertinent directories for changes,
and regenerate the menu when changes are detected.  This option implies
the B<--output> option.  This option requires L<Linux::Inotify2(3pm)>.

=item B<--button>, B<-b> BUTTON

=item B<--timestamp>, B<-T> TIMESTAMP


=back

=cut

my (@SAVEARGS) = (@ARGV);

my ($wmname,$format,$output);

# If we can identify a running window manager, use that format before
# that specified by XDG_CURRENT_DESKTOP.  I would like to use Gnome2::Wnck
# for this but it cannot even identify icewm(1).
#
if (-x "/usr/bin/xde-identify") {
	my $wm = {};
	chomp(my $pl = `xde-identify --perl`);
	eval "\$wm = $pl;";
	$wmname = "\L$wm->{XDE_WM_NAME}\E";
	$format = $wmname;
	$output = $wm->{XDE_WM_MENU};
} else {
	my $screen = Gtk2::Gdk::Screen->get_default;
	my $root = $screen->get_root_window;
	my $atom = Gtk2::Gdk::Atom->new('_NET_SUPPORTING_WM_CHECK');
	my $type = Gtk2::Gdk::Atom->new('WINDOW');
	my ($prop,$form,$data) = $root->property_get($atom,$type,0,1,FALSE);
	if ($prop and $form and $data) {
		if ((my $check = Gtk2::Gdk::Window->foreign_new($data))) {
			($prop,$form,$data) = $check->property_get($atom,$type,0,1,FALSE);
			if ($data == $check->XID) {
				if ($prop and $form and $data) {
					$atom = Gtk2::Gdk::Atom->new('_NET_WM_NAME');
					$type = Gtk2::Gdk::Atom->new('UTF8_STRING');
					($prop,$form,$data) = $check->property_get($atom,$type,0,256,FALSE);
					if ($prop and $form and $data) {
						($wmname) = split(/\s+/,$data,2);
						$wmname = "\L$wmname\E";
					} else {
						$atom = Gtk2::Gdk::Atom->new('_WINDOWMAKER_NOTICEBOARD');
						$type = Gtk2::Gdk::Atom->new('WINDOW');
						($prop,$form,$data) = $check->property_get($atom,$type,0,1,FALSE);
						if ($prop and $form and $data) {
							$format = 'wmaker';
						}
					}
				}
			}
		}
	} else {
		$atom = Gtk2::Gdk::Atom->new('_WIN_SUPPORTING_WM_CHECK');
		$type = Gtk2::Gdk::Atom->new('CARDINAL');
		($prop,$form,$data) = $root->property_get($atom,$type,0,1,FALSE);
		if ($prop and $form and $data) {
			if ((my $check = Gtk2::Gdk::Window->foreign_new($data))) {
				($prop,$form,$data) = $check->property_get($atom,$type,0,1,FALSE);
				if ($data == $check->XID) {
					if ($prop and $form and $data) {
						$atom = Gtk2::Gdk::Atom->new('WM_NAME');
						$type = Gtk2::Gdk::Atom->new('STRING');
						($prop,$form,$data) = $check->property_get($atom,$type,0,256,FALSE);
						if ($prop and $form and $data) {
							($wmname) = split(/\s+/,$data,2);
							$wmname = "\L$wmname\E";
						}
					}
				}
			}
		}
	}
}

$wmname = '' unless $wmname;
$wmname = 'wmaker' if "\L$wmname\E" eq 'windowmaker';
$wmname = 'ctwm' if "\L$wmname\E" eq 'workspacemanager';
$output = '' unless $output;

# handle XDG_CURRENT_DESKTOP with multiple values separated by ':'
#
if ($wmname) {
	$format = $wmname;
} else {
	$format = "\L$XDG_CURRENT_DESKTOP\E";
}
if ($format =~ m{:}) {
	foreach my $f (keys %formats) {
		if ($format =~ m{:$f:}i) {
			$format = $f;
			last;
		}
	}
	if ($format =~ m{:}) {
		$format =~ s{.*:}{};
	}
}

my $launcher = which('xdg-launch') ? 'xdg-launch --pointer' : '';

my %ops = (
    help	=> '',
    wmname	=> "\L$wmname\E",
    format	=> "\L$format\E",
    fullmenu	=> '',
    desktop	=> "\U$format\E",
    charset	=> langinfo(CODESET),
    language	=> setlocale(LC_MESSAGES),
    root_menu	=> $XDG_ROOT_MENU,
    die_on_error=> '',
    verbose	=> '',
    output	=> undef,
    icons	=> '',
    noicons	=> '',
    theme	=> $XDG_ICON_THEME,
    monitor	=> '',
    button	=> 0,
    timestamp	=> 0,
    popup	=> '',
    refresh	=> '',
    restart	=> '',
    quit	=> '',
    launch	=> $launcher,
);

my $syntax = GetOptions(
    "help|h"	    =>\$ops{help},
    "wmname|w=s"    =>\$ops{wmname},
    "format|f=s"    =>\$ops{format},
    "fullmenu|F!"   =>\$ops{fullmenu},
    "N"		    =>sub{$ops{fullmenu}=0},
    "desktop|d=s"   =>\$ops{desktop},
    "charset|c=s"   =>\$ops{charset},
    "language|l=s"  =>\$ops{language},
    "root-menu|r=s" =>\$ops{root_menu},
    "die-on-error|e"=>\$ops{die_on_error},
    "verbose|v"	    =>\$ops{verbose},
    "output|o:s"    =>\$ops{output},
    "icons!"	    =>\$ops{icons},
    "n"		    =>sub{$ops{icons}=0},
    "theme|t=s"	    =>\$ops{theme},
    "monitor|m"	    =>\$ops{monitor},
    "timestamp|T=i" =>\$ops{timestamp},
    "button|b=i"    =>\$ops{button},
    "popup|p"	    =>\$ops{popup},
    "refresh|r"	    =>\$ops{refresh},
    "restart|R"	    =>\$ops{restart},
    "quit|q"	    =>\$ops{quit},
    "launch|L!"	    =>\$ops{launch},
);

# to support symbolic links to this program
$ops{popup}   = 1 if $program =~ m{-popup$};
$ops{quit}    = 1 if $program =~ m{-quit$};
$ops{refresh} = 1 if $program =~ m{-refresh$};
$ops{restart} = 1 if $program =~ m{-restart$};

my $cmds = 0;

$cmds++ if $ops{popup};
$cmds++ if $ops{quit};
$cmds++ if $ops{refresh};
$cmds++ if $ops{restart};

if ($cmds > 1) {
    print STDERR "only one of -popup, -quit, -refresh or -restart can be specified\n";
    usage(2);
}

undef $cmds;

if (defined $ops{output}) {
    unless ($output) {
	if (exists $outputs{$ops{format}}) {
	    foreach (@{$outputs{$ops{format}}}) {
		if (-f $_) {
		    $ops{output} = $_;
		    last;
		}
	    }
	}
    }
    $ops{output} = $output unless $ops{output};
    unless ($ops{output}) {
	    print STDERR "nowhere to output";
	    usage(2);
    }
}

$ops{launch} = '' unless $ops{launch};
if ($ops{launch}) {
    unless ($launcher) {
	$ops{launch} = 0;
	print STDERR "missing xdg-launch program";
	usage(2);
    }
    $ops{launch} = $launcher;
}

if ($ops{root_menu} and not -f $ops{root_menu}) {
    $ops{root_menu} = $XDG_ROOT_MENU
        if $XDG_ROOT_MENU and -f $XDG_ROOT_MENU;
}

unless ($ops{format}) {
    $ops{format} = $desktops{$ops{desktop}}[0]
        if $ops{desktop} and $desktops{$ops{desktop}};
}
unless ($ops{desktop}) {
    $ops{desktop} = $formats{$ops{format}}[0]
        if $ops{format} and $formats{$ops{format}};
}

if ($ops{help} or not $syntax) {
    usage($syntax ? 0 : 2);
}

unless ($ops{root_menu} and -f $ops{root_menu}) {
    print STDERR "bad root menu $ops{root_menu}\n" if $ops{root_menu};
    print STDERR "missing root menu\n" unless $ops{root_menu};
    usage(2);
}

unless ($ops{format} and exists $formats{$ops{format}}) {
    print STDERR "bad format $ops{format}\n" if $ops{format};
    print STDERR "missing format\n" unless $ops{format};
    usage(2);
}

unless ($ops{desktop} and exists $desktops{$ops{desktop}}) {
    print STDERR "bad desktop $ops{desktop}\n" if $ops{desktop};
    print STDERR "missing desktop\n" unless $ops{desktop};
    usage(2);
}

if (($ops{desktop} ne $formats{$ops{format}}[0]) or
    ($ops{format} ne $desktops{$ops{desktop}}[0])) {
    print STDERR "mismatch between format $ops{format} and desktop $ops{desktop}\n";
    usage(2);
}

if ($ops{theme}) {
    my $theme = '';
    foreach (@XDG_ICON_DIRS) {
        $theme = $ops{theme} if -f "$_/$ops{theme}/index.theme";
        last if $theme;
    }
    unless ($theme) {
        print STDERR "invalid theme $ops{theme}\n";
        usage(2);
    }
}
else {
    print STDERR "missing theme\n";
    usage(2);
}

$ops{lang} = $ops{language};
$ops{lang} =~ s/\..*$//;

if ($ops{verbose}) {
    print STDERR "\tRoot menu: $ops{root_menu}\n";
    print STDERR "\tFormat:    $ops{format}\n";
    print STDERR "\tDesktop:   $ops{desktop}\n";
    print STDERR "\tTheme:     $ops{theme}\n";
    print STDERR "\tCharset:   $ops{charset}\n";
    print STDERR "\tLanguage:  $ops{language}\n";
    print STDERR "\tLang:      $ops{lang}\n";
}

sub usage {
    my $retval = shift;
    print STDERR<<EOF;
USAGE:
    $program [OPTIONS]

COMMAND OPTIONS:
  --help,-h
        print this usage info and exit
  --popup,-p
        ask a running instance to popup its menu
  --refresh,-r
        ask a running instance to refresh its menu
  --restart,-R
        ask a running instance to restart
  --quit,-q
        ask a running instance to quit

GENERAL OPTIONS:
  --format,-f FORMAT      [default: $ops{format}]
        specify the output format to use; defaults to the lowercase
        value of XDG_CURRENT_DESKTOP.
  --fullmenu,-F
        generate a full menu instead of a submenu; default is to
        generate a full menu.
  --nofullmenu,-N
        generate a submenu instead of a full menu; default is to
        generate a full menu.
  --desktop,-d DESKTOP    [default: $ops{desktop}]
        specify the desktop string for OnlyShowIn and NotShowIn desktop
        entries; defaults is XDG_CURRENT_DESKTOP or the uppercase FORMAT
        value.
  --charset,-c CHARSET    [default: $ops{charset}]
        specify the character set to use to output the menu; defaults to
        the charset of the current locale.
  --language,-l LANGUAGE  [default: $ops{language}]
        specify the language to use to output the menu; defaults to the
        value of the current locale.
  --root-menu,-r ROOTMENU [default: $ops{root_menu}]
        specify the root menu.  Default is derived from XDG_MENU_PREFIX
        and XDG_CONFIG_DIRS.
  --die-on-error,-e
        abort (do not write output) on any error.
  --verbose,-v
        print debugging information on standard error.
  --output,-o [FILENAME]  [default: $ops{output}]
        print the output to file, FILENAME; default is to print the menu
        to standard output; default FILENAME if unspecified based on
        format.
  --noicons,-n,--icons    [default: --icons]
        do not include icons in the generated menu
  --theme,-t THEME        [default: $ops{theme}]
        use the specified icon theme when generating icons; defaults to
        the user icon theme.
  --monitor,-m
        do not exit after first menu generation, but monitor pertinent
        directories for changes and regenerate the menu when required;
        implies the --output option.
  --launch,-L --nolaunch  [default: $ops{launch}]
        use xdg-launch program to launch desktop entry directly
EOF
    exit($retval);
}

my $prog = $ops{popup} ? "$program-popup" : $program;

my $DESKTOP_STARTUP_ID = delete $ENV{DESKTOP_STARTUP_ID};
my $unique = Gtk2::UniqueApp->new(
	"com.unexicon.$program", $DESKTOP_STARTUP_ID,
	"$program" => 1,
	"$program-popup" => 2);
if ($unique->is_running) {
    if ($prog eq $program) {
	my $text = encode_base64(nfreeze(\%ops));
	$unique->send_message_by_name($prog=>text=>$text);
	print STDERR "Another instance of $program is already running.\n"
	    unless $ops{quit} or $ops{restart} or $ops{refresh} or $ops{popup};
    } elsif ($prog eq "$program-popup") {
	$unique->send_message_by_name($prog=>text=>join(',',$ops{button},$ops{timestamp}));
    }
    exit(0);
}
if ($ops{quit} or $ops{restart} or $ops{refresh} or $ops{popup}) {
    die "No other instance of $program is running.\n";
}

my($menu,$icon,$parser,$tree,$tray);

my $window = Gtk2::Window->new('toplevel');
$unique->watch_window($window);
$unique->signal_connect(message_received=>sub{
	my ($unique,$command,$message,$time) = @_;
	if ($command eq $program) {
	    if ($ops{verbose}) {
		print STDERR "$command command received\n";
		print STDERR "\tscreen is ", $message->get_screen, "\n";
		print STDERR "\tworkspace is ", $message->get_workspace, "\n";
		print STDERR "\tstartup id is ", $message->get_startup_id, "\n";
	    }
	    my $text = $message->get_text;
	    %ops = %{thaw(decode_base64($text))};
	    if ($ops{quit} or $ops{restart}) {
		Gtk2->main_quit();
		# have to return first or no DBus reply generated
		return 'ok';
	    }
	    if ($ops{refresh}) {
		$parser = new XDG::Menu::Parser;
		$tree = $parser->parse_menu($ops{root_menu});
		$tray = new XDG::Menu::Tray;
		$menu = $tray->create($tree);
		return 'ok';
	    }
	}
	elsif ($command eq "$program-popup") {
	    if ($ops{verbose}) {
		print STDERR "$command command received\n";
		print STDERR "\tscreen is ", $message->get_screen, "\n";
		print STDERR "\tworkspace is ", $message->get_workspace, "\n";
		print STDERR "\tstartup id is ", $message->get_startup_id, "\n";
	    }
	    my $text = $message->get_text;
	    my ($button,$timestamp) = split(/,/,$text);
	    $button = 0 unless $button == 1 || $button == 2 || $button == 3;
	    $timestamp = $time unless $timestamp;
	    print STDERR "Popping menu $icon, $button, $timestamp\n" if $ops{verbose};
	    if ($button) {
		    $menu->popup(undef,undef,sub{
			my ($menu,$x,$y,$data,$mods) = @_;
			my $scrn = $message->get_screen;
			my $disp = $scrn->get_display;
			($scrn,$x,$y,$mods) = $disp->get_pointer;
			$menu->set_screen($scrn);
			my $req = $menu->size_request;
			$x -= 5;
			$y -= 5;
			print STDERR "returning: $x, $y, 1\n" if $ops{verbose};
			return ($x,$y,1);
		    },undef,0,0);
	    } else {
		    $menu->popup(undef,undef,sub{
			my ($menu,$x,$y,$data,$mods) = @_;
			my $scrn = $message->get_screen;
			my $disp = $scrn->get_display;
			($scrn,$x,$y,$mods) = $disp->get_pointer;
			$menu->set_screen($scrn);
			my $mon = $scrn->get_monitor_at_point($x,$y);
			my $req = $menu->size_request;
			my $rect = $scrn->get_monitor_geometry($mon);
			$x = $rect->x + $rect->width / 2 - $req->width / 2;
			$y = $rect->y + $rect->height / 2 - $req->height / 2;
			print STDERR "returning: $x, $y, 1\n" if $ops{verbose};
			return ($x,$y,1);
		    },undef,0,0);
	    }
	}
	return 'ok';
});

#my $style = Gtk2::RcStyle->new;
my @colors = (
    Gtk2::Gdk::Color->new(0x16*257,0x16*257,0x16*257), # 0
    Gtk2::Gdk::Color->new(0x37*257,0x37*257,0x37*257), # 1
    Gtk2::Gdk::Color->new(0x46*257,0x72*257,0x77*257), # 2
    Gtk2::Gdk::Color->new(0x4c*257,0x4c*257,0x4c*257), # 3
    Gtk2::Gdk::Color->new(0x9c*257,0x9c*257,0x9c*257), # 4
    Gtk2::Gdk::Color->new(0xc0*257,0xc0*257,0xc0*257), # 5
    Gtk2::Gdk::Color->new(0xff*257,0xff*257,0xff*257), # 6
);
my %colors = (
    base => {
	normal	    => $colors[0],
	active	    => $colors[2],
	prelight    => $colors[2],
	selected    => $colors[2],
	insensitive => $colors[0],
    },
    bg => {
	normal	    => $colors[0],
	active	    => $colors[2],
	prelight    => $colors[2],
	selected    => $colors[2],
	insensitive => $colors[0],
    },
    fg => {
	normal	    => $colors[6],
	active	    => $colors[5],
	prelight    => $colors[5],
	selected    => $colors[5],
	insensitive => $colors[6],
    },
    text => {
	normal	    => $colors[6],
	active	    => $colors[5],
	prelight    => $colors[5],
	selected    => $colors[5],
	insensitive => $colors[6],
    },
);

#my $font = Pango::FontDescription->from_string('Liberation Sans 8');
#$style->font_desc($font);
#$style->name('default');

foreach my $state (qw(normal active prelight selected insensitive)) {
#$style->color_flags($state,[qw(base fg bg text)]);
#$style->base($state,$colors{'base'}{$state});
#$style->bg($state,$colors{'bg'}{$state});
#$style->fg($state,$colors{'fg'}{$state});
#$style->text($state,$colors{'text'}{$state});
}

$parser = new XDG::Menu::Parser;
$tree = $parser->parse_menu($ops{root_menu});
$tray = new XDG::Menu::Tray;
#$tray->{style} = $style;
#$tray->{colors} = \@colors;
$menu = $tray->create($tree);

my $pixbuf = Gtk2::IconTheme->get_default->load_icon('arch-logo',16,['generic-fallback','use-builtin']);
$icon =  Gtk2::StatusIcon->new_from_pixbuf($pixbuf);

#my $icon = new Gtk2::StatusIcon->new_from_icon_name('start-here');
$icon->set_tooltip_text('Click for menu...');
$icon->set_visible(1);
$icon->signal_connect(button_press_event=>sub{
    my ($icon,$ev) = @_;
    my $button = $ev->button;
    return Gtk2::EVENT_PROPAGATE unless $button == 1 or $button == 2;
    my $time = $ev->time;
#   my $menu = $tray->create($tree);
#    Gtk2::Rc->reparse_all;
#    Gtk2::Rc->parse("$ENV{HOME}/.gtkrc-2.0");
#    Gtk2::Rc->reset_styles('gtk-theme-name');
    $menu->popup(undef,undef,\&Gtk2::StatusIcon::position_menu,$icon,$button,$time);
    return Gtk2::EVENT_STOP;
});
$icon->signal_connect(popup_menu=>sub{
    my ($icon,$button,$time) = @_;
#    Gtk2::Rc->parse_string('gtk-theme-name="Squared-green"'."\n");
#    Gtk2::Rc->reparse_all;
#    Gtk2::Rc->reset_styles('gtk-theme-name');
#    my $menu = $tray->create($tree);
#    Gtk2::Rc->set_default_files("$ENV{HOME}/.gtkrc-2.0");
#    Gtk2::Rc->reparse_all;
#    Gtk2::Rc->parse("$ENV{HOME}/.gtkrc-2.0");
#    Gtk2::Rc->reset_styles('gtk-theme-name');
    my ($cmenu,$mi,$im) = Gtk2::Menu->new;
    $mi = Gtk2::ImageMenuItem->new_from_stock('gtk-refresh');
    $mi->signal_connect(activate=>sub{
	    $parser = new XDG::Menu::Parser;
	    $tree = $parser->parse_menu($ops{root_menu});
	    $tray = new XDG::Menu::Tray;
	    $menu = $tray->create($tree);
	    return Gtk2::EVENT_STOP;
    });
    $mi->show_all;
    $cmenu->append($mi);
    $mi = Gtk2::ImageMenuItem->new_from_stock('gtk-about');
    $mi->signal_connect(activate=>sub{
	    Gtk2->show_about_dialog(undef,
		    logo_icon_name=>'start-here',
		    program_name=>$program,
		    version=>'0.01',
		    comments=>'An XDG compliant tray menu for XDE.',
		    copyright=>'Copyright (c) 2013, 2014  OpenSS7 Corporation.',
		    website=>'http://www.unexicon.com/',
		    website_label=>'Unexicon - Linux spun for telecom',
		    authors=>['Brian F. G. Bidulock <bidulock@openss7.org>'],
		    license=><<EOF,
Do what thou wilt shall be the whole of the law.

-- Aleister Crowley
EOF
		    # logo=>,
	    );
    });
    $mi->show_all;
    $cmenu->append($mi);
    $mi = Gtk2::SeparatorMenuItem->new;
    $mi->show_all;
    $cmenu->append($mi);
    $mi = Gtk2::ImageMenuItem->new_from_stock('gtk-redo');
    $mi->show_all;
    $mi->signal_connect(activate=>sub{ exec $executable, @SAVEARGS or die; });
    $cmenu->append($mi);
    $mi = Gtk2::ImageMenuItem->new_from_stock('gtk-quit');
    $mi->show_all;
    $mi->signal_connect(activate=>sub{ Gtk2->main_quit(); 1; });
    $cmenu->append($mi);
    $cmenu->popup(undef,undef,\&Gtk2::StatusIcon::position_menu,$icon,$button,$time);
    return Gtk2::EVENT_PROPAGATE;
});
$icon->signal_connect(activate=>sub{
    my ($icon) = @_;
    return Gtk2::EVENT_PROPAGATE;
	
});
$icon->signal_connect(query_tooltip=>sub{
    my ($icon,$x,$y,$bool,$tooltip) = @_;
    return Gtk2::EVENT_PROPAGATE;
});
$icon->signal_connect(size_changed=>sub{
    my ($icon,$size) = @_;
    if ($size != $pixbuf->get_height) {
	$pixbuf = Gtk2::IconTheme->get_default->load_icon('arch-logo',$size,['generic-fallback','use-builtin']);
	$icon->set_from_pixbuf($pixbuf);
    }
    return Gtk2::EVENT_PROPAGATE;
});

Gtk2->main;

if ($ops{quit}) {
    exit(0);
}
if ($ops{restart}) {
    exec $executable, @SAVEARGS or die;
}
exit(0);

__END__

=head1 X RESOURCES

B<xde-traymenu> examines and interprets the following X Resources
(atoms).

=over

=item B<_BLACKBOX_PID>

This atom is checked on the root window.  If set, then the window
manager in use is I<Fluxbox>. (Note that I<Blackbox> does not set this
poorly named atom.)

=item B<_OPENBOX_PID>

This atom is checked on the root window.  If set, then the window
manager in use is I<Openbox>.  Additional resources set by the Openbox
window manager on the root window include B<_OB_CONFIG_FILE> and
B<_OB_VERSION>.  The B<_OB_VERSION> in particular can be used to
determine whether C<openbox3> or C<openbox3-pipe> format should be used
instead of B<openbox> format.

=item B<_NET_SUPPORTING_WM_CHECK>

This atom is checked on the root window of the display to determine
which window manager is active.

=item B<_NET_WM_NAME>

This atom is checked on the window indicated by
B<_NET_SUPPORTING_WM_CHECK> to determine the window manager in use.
I<Fluxbox> sets this to I<Fluxbox>; I<Blackbox> to I<Blackbox>, I<IceWM>
to I<IceWM> followed by a version and compile string; I<Openbox> to
I<Openbox>.

=back

=cut

=head1 ENVIRONMENT

The following environment variables are significant to the operation of
B<xde-traymenu>:

=over

=item B<XDG_CURRENT_DESKTOP>

Specifies the current desktop.  When the B<--format> is not specified,
the format defaults to the value of this environment variable converted
to lower-case.  When the B<--desktop> is not specified, the desktop
defaults to the value of this environment variable.

=item B<XDG_MENU_PREFIX>

Specifies the prefix to apply to the default menu name to derive the
root menu unless specified with the B<--root-menu>.  When unspecified,
this variable defaults to a null string.

B<xde-traymenu> finds the root menu using the following logic:

=over

=item 1.

If a file name is specified using the B<--root-menu> option, that file
name is used as the root menu.

=item 2.

If not found, the file name F<${XDG_MENU_PREFIX}applications.menu> is
sought in each of the directories in the path F<@XDG_CONFIG_DIRS/menus>.

=item 3.

If not found, the file name F<applications.menu> is sought in each of
the directories in the path F<@XDG_CONFIG_DIRS/menus>.

=back

=item B<XDG_CONFIG_HOME>

Specifies the user XDG configuration directory.
When unspecified, defaults to F<$HOME/.config> in accordance with XDG
specifications.

=item B<XDG_CONFIG_DIRS>

Specifies the system XDG configuration directories.
When unspecified, defaults to F</etc/xdg> in accordance with XDG
specifications.

=item B<XDG_DATA_HOME>

Specifies the user XDG data directory.
When unspecified, defaults to F<$HOME/.local/share> in accordance with
XDG specifications.

=item B<XDG_DATA_DIRS>

Specifies the system XDG data directories.
When unspecified, defaults to F</usr/local/share:/usr/share> in
accordance with XDG specifications.

=item B<XDG_ICON_THEME>

Specifies the name of the icon theme.  When not specified, the icon
theme will be determined from configuration sources (e.g.
F<$HOME/.gtkrc-2.0>).

=back

=head1 HISTORY

I wrote B<xde-traymenu> for a number of reasons:

=over

=item 1.

Existing fluxbox menu generators that read XDG .desktop files
(L<fbmenugen(1)>, L<menutray(1)>) do not conform to XDG menu generation
specifications and in particular are incapable of merging menus.

=item 2.

Existing XDG menu generators (such as the SuSE L<xdg_menu(1)> script) do
not properly merge default merge directories and do not observe <Layout>
commands.  Also, they are poor at including icons in the generated menus.
They, of course, do not generate tray menus either.

=item 3.

Existing XDG menu generators run once and keep cache information, or
have a I<regenerate> command placed in the menu.  They do not monitor
XDG directories for changes and update menus on changes.

=item 4.

The L<lxpanel(1)> and L<pcmanfm(1)> menu generators do not have any of
the above deficiencies; however, they do not create window manager
specific submenus.

=back

=head1 SEE ALSO

L<XDG::Menu(3pm)>, L<XDG::Icons(3pm)>,
L<Linux::Inotify2(3pm)>.

=cut
