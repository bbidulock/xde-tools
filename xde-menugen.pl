#!/usr/bin/perl

binmode STDOUT, "encoding(UTF-8)";

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

=encoding UTF-8

=head1 NAME

xde-menugen -- generate XDG compliant menus

=head1 SYNOPSIS

 xde-menugen [ OPTIONS ]

=head1 DESCRIPTION

B<xde-menugen> is a command-line program that can be used to generate a
XDG compliant menu in a number of formats to support configuration of
the root menu for light-weight window managers.

B<xde-menugen> is capable of generating either a complete menu for a
number of well-known window managers, or for generating a submenu that
can be included in the root menu of those window managers.

=cut

use XDG::Menu::Parser;
use XDG::Menu::Fluxbox;
use XDG::Menu::Blackbox;
use XDG::Menu::Openbox;
use XDG::Menu::Openbox3;
use XDG::Menu::Icewm;
use XDG::Menu::Pekwm;
use XDG::Menu::Jwm;
use XDG::Menu::Fvwm;
use XDG::Menu::WmakerOld;
use XDG::Menu::Wmaker;
use XDG::Menu::Ctwm;
use XDG::Menu::Vtwm;
use XDG::Menu::Twm;
use XDG::Menu::Uwm;
use XDG::Menu::Waimea;
use XDG::Menu::PerlPanel;
use Getopt::Long;
use Encode;
use I18N::Langinfo qw(langinfo CODESET);
use POSIX qw(locale_h);
use File::Which qw(which);
use File::Temp qw(tempfile);	# part of perl 5.18.2
use File::Copy qw(copy move);	# part of perl 5.18.2
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
    uwm		=> [ "$HOME/.uwm/menu" ],
    waimea	=> [ "$HOME/.waimea/menu" ],
    perlpanel	=> [ "$HOME/.perlpanel/menu" ],
);

my %formats = (
    fluxbox	=> [qw(FLUXBOX	XDG::Menu::Fluxbox  )],
    blackbox	=> [qw(BLACKBOX	XDG::Menu::Blackbox )],
    openbox	=> [qw(OPENBOX	XDG::Menu::Openbox  )],
    openbox3	=> [qw(OPENBOX	XDG::Menu::Openbox3 )],
    icewm	=> [qw(ICEWM	XDG::Menu::Icewm    )],
    pekwm	=> [qw(PEKWM	XDG::Menu::Pekwm    )],
    jwm		=> [qw(JWM	XDG::Menu::Jwm      )],
    fvwm	=> [qw(FVWM	XDG::Menu::Fvwm	    )],
    wmaker	=> [qw(WMAKER	XDG::Menu::Wmaker   )],
    wmakerold	=> [qw(WMAKER	XDG::Menu::WmakerOld)],
    ctwm	=> [qw(CTWM	XDG::Menu::Ctwm	    )],
    vtwm	=> [qw(VTWM	XDG::Menu::Vtwm	    )],
    twm		=> [qw(TWM	XDG::Menu::Twm	    )],
    uwm		=> [qw(UWM	XDG::Menu::Uwm	    )],
    waimea	=> [qw(WAIMEA	XDG::Menu::Waimea   )],
    perlpanel	=> [qw(PERLPANEL XDG::Menu::PerlPanel )],
);

my %desktops = (
    FLUXBOX	=> [qw(fluxbox	XDG::Menu::Fluxbox  )],
    BLACKBOX	=> [qw(blackbox	XDG::Menu::Blackbox )],
    OPENBOX	=> [qw(openbox3	XDG::Menu::Openbox3 )],
    ICEWM	=> [qw(icewm	XDG::Menu::Icewm    )],
    PEKWM	=> [qw(pekwm	XDG::Menu::Pekwm    )],
    JWM		=> [qw(jwm	XDG::Menu::Jwm      )],
    FVWM	=> [qw(fvwm	XDG::Menu::Fvwm	    )],
    WMAKER	=> [qw(wmaker	XDG::Menu::Wmaker   )],
    CTWM	=> [qw(ctwm	XDG::Menu::Ctwm	    )],
    VTWM	=> [qw(vtwm	XDG::Menu::Vtwm	    )],
    TWM		=> [qw(twm	XDG::Menu::Twm	    )],
    UWM		=> [qw(uwm	XDG::Menu::Uwm	    )],
    WAIMEA	=> [qw(waimea	XDG::Menu::Waimea   )],
    LXDE	=> [qw(openbox3 XDG::Menu::Openbox3 )],
);


=head1 OPTIONS

B<xde-menugen> accepts the following options:

=over

=item B<--help>, B<-h>

Print usage information, including the current values of option
defaults, and exit.

=item B<--verbose>, B<-v>

Print debugging information on standard error during operation.

=item B<--format>, B<-f> I<FORMAT>

Specify the output format.  Recognized output formats are as follows:
C<twm>, C<wmaker>, C<windowmaker>, C<fvwm>, C<fvwm2>, C<fvwm-crystal>,
C<ion3>, C<blackbox>, C<fluxbox>, C<openbox>, C<xfce4>, C<openbox3>,
C<openbox3-pipe>, C<awesome>, C<icewm>, C<jwm>, C<pekwm>, C<μwm>, C<waimea>.

When unspecified, the setting of the B<XDG_CURRENT_DESKTOP> environment
variable is used to determine the format.  This is accomplished by
converting the value of B<XDG_CURRENT_DESKTOP> to  lower-case.  See
L</ENVIRONMENT>.

=item B<--fullmenu>, B<-F>, B<--nofullmenu>, B<-N>

When specified, output a full menu and not only the application
sub-menu, or not.  The default is to output a full menu.

=item B<--desktop>, B<-d> I<DESKTOP>

Specify the desktop name for C<NotShowIn> and C<OnlyShowIn> comparisons.
The default is the all upper-case value corresponding to the format
unless C<XDG_CURRENT_DESKTOP> is defined (see L</ENVIRONMENT>).

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
That is, when the B<--format> is one such as C<blackbox>, or C<waimea> it is not
possible to place icons in the menu and this option is therefore
ignored.  The default is to place icons in capable generated menus.

=item B<--theme>, B<-t> THEME

Specify the icon theme name to use when generating icons.  The default
is to obtain the icon theme name from default locations (such as the
F<$HOME/.gtkrc-2.0> file).

=item B<--monitor>, B<-m>

Specifies that B<xde-menugen> is not to exit after successfully
generating the menu, but to monitor pertinent directories for changes,
and regenerate the menu when changes are detected.  This option implies
the B<--output> option.  This option requires L<Linux::Inotify2(3pm)>.

=item B<--launch>, B<-L>, B<--nolaunch>

Specifies whether to use L<xdg-launch(1)> to launch desktop files directly
or not.  This option will only be honored when the L<xdg-launch(1)> program
is available.

=back

=cut

my ($wmname,$format,$output);

# If we can identify a running window manager, use that format before that
# specified by XDG_CURRENT_DESKTOP.  We cannot use Gtk2 directly here because
# we want this program to run without Gtk2.
#
if (-x "/usr/bin/xde-identify") {
	my $wm = {};
	chomp(my $pl = `xde-identify --perl`);
	eval "\$wm = $pl;";
	$wmname = "\L$wm->{XDE_WM_NAME}\E";
	$format = $wmname;
	$output = $wm->{XDE_WM_MENU};
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
    help        => '',
    wmname	=> "\L$wmname\E",
    format	=> "\L$format\E",
    fullmenu    => '',
    desktop	=> "\U$format\E",
    charset     => langinfo(CODESET),
    language    => setlocale(LC_MESSAGES),
    root_menu   => $XDG_ROOT_MENU,
    die_on_error=> '',
    verbose     => '',
    output      => undef,
    icons       => '',
    noicons     => '',
    theme       => $XDG_ICON_THEME,
    monitor     => '',
    style	=> 'fullmenu',
    launch	=> $launcher,
);

my $syntax = GetOptions(
    "help|h"        =>\$ops{help},
    "format|f=s"    =>\$ops{format},
    "fullmenu|F!"   =>\$ops{fullmenu},
    "N"		    =>sub{$ops{fullmenu}=0},
    "desktop|d=s"   =>\$ops{desktop},
    "charset|c=s"   =>\$ops{charset},
    "language|l=s"  =>\$ops{language},
    "root-menu|r=s" =>\$ops{root_menu},
    "die-on-error|e"=>\$ops{die_on_error},
    "verbose|v"     =>\$ops{verbose},
    "output|o:s"    =>\$ops{output},
    "icons!"        =>\$ops{icons},
    "n"             =>sub{$ops{icons}=0},
    "theme|t=s"     =>\$ops{theme},
    "monitor|m"     =>\$ops{monitor},
    "style|s=s"	    =>\$ops{style},
    "launch|L!"	    =>\$ops{launch},
);

if (defined $ops{output}) {
    unless ($output) {
	if (exists $outputs{$ops{format}}) {
	    foreach (@{$outputs{$ops{format}}}) {
		if (-f $_) {
		    $output = $_;
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

if (0) {
if (($ops{desktop} ne $formats{$ops{format}}[0]) or
    ($ops{format} ne $desktops{$ops{desktop}}[0])) {
    print STDERR "mismatch between format $ops{format} and desktop $ops{desktop}\n";
    usage(2);
}
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
    xde-menugen [OPTIONS]

OPTIONS:
    --help,-h
        print this usage info and exit

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

    --noicons,-n
        do not include icons in the generated menu; default is to
        include icons in capable menus.

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

my $parser = new XDG::Menu::Parser;
my $tree = $parser->parse_menu($ops{root_menu});
my $builder = $formats{$ops{format}}[1];
my $wm = $builder->new(%OVERRIDES,ops=>\%ops);
my $menu = $wm->create($tree,$ops{style});
if ($ops{output}) {
    my $base = $ops{output};
    $base =~ s{//*$}{};
    $base =~ s{/[^/]*$}{};
    my $file = $ops{output};
    $file =~ s{//*$}{};
    $file =~ s{^.*/}{};
    my ($oh,$oname) = tempfile(".$file.XXXXXXXXXX", DIR => $base, SUFFIX => '.tmp');
    print $oh $menu;
    close($oh);
    copy($oname,$ops{output});
    unlink($oname);
} else {
    print $menu;
}
exit (0);



=head1 ENVIRONMENT

The following environment variables are significant to the operation of
B<xde-menugen>:

=over

=item B<XDG_CURRENT_DESKTOP>

Specifies the current desktop.  When the B<--format> is not specified,
the format defaults to the value of this environment variable converted
to lower-case.  When the B<--desktop> is not specified, the desktop
defaults to the value of this environment variable.

=item B<XDG_MENU_PREFIX>

Specifies the prefix to apply to the default menu name to derive the
root menu unless specified with B<--root-menu>.  When unspecified,
this variable defaults to a null string.

B<xde-menugen> finds the root menu using the following logic:

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

B<xde-menugen> was written for a number of reasons:

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
