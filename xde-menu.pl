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
require XDE::Menu;
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
    format	=> "\L$ENV{XDG_CURRENT_DESKTOP}\E",
    fullmenu	=> 1,
    desktop	=> "\U$ENV{XDG_CURRENT_DESKTOP}\E",
    charset	=> langinfo(CODESET),
    language	=> setlocale(LC_MESSAGES),
    root_menu	=> $ENV{XDG_ROOT_MENU},
    die_on_error=> '',
    output	=> '',
    icons	=> 1,
    noicons	=> '',
    theme	=> $ENV{XDG_ICON_THEME},
    vendor	=> '',
    monitor	=> 1,
);

exit(0);

1;

__END__

=head1 NAME

xde-menu - generate XDG compliant menus and system tray menu

=head1 SYNOPSIS

B<xde-menu> [I<OPTIONS>]

=head1 DESCRIPTION

B<xde-menu> can be used to generate an XDG compliant menu in a number of
formats to support configuration of the root menu for light-weight
window managers.  In addition it provides an optional GTK2 system tray
menu that is themed in accordance with the window manager XDE theme.

=head1 OPTIONS

B<xde-menu> accepts the following options:

=over

=item B<--help>, B<-h>

Print usage information, including the current values of option
defaults, and exits.

=item B<--verbose>, B<-v>

Print debugging information on standard error during operation.

=item B<--edit>, B<-e>

When specified (or the program is called as B<xde-menu-edit>), launch
the preferences dialog.  THis is the default when called as
B<xde-menu-edit>.

=item B<--format>,B<-f> I<FORMAT>

Specify the output format.  Recognized output formats are as follows:
C<twm>, C<wmaker>, C<fvwm2>, C<ion3>, C<blackbox>, C<fluxbox>,
C<openbox>, C<xfce4>, C<openbox3>, C<openbox3-pipe>, C<awesome>.

When unspecified, the setting of the B<XDG_CURRENT_DESKTOP> environment
variable is used to determine the format.  This is accomplished by
converting the value of B<XDG_CURRENT_DESKTOP> to  lower-case.  See
L</ENVIRONMENT>.

=item B<--desktop>,B<-d> I<DESKTOP>

Specify the desktop name for C<NotShowIn> and C<OnlyShowIn> comparisons.
The default is the all upper-case value corresponding to the format
unless C<XDG_CURRENT_DESKTOP> is defined (see L</ENVIRONMENT>).

=item B<--charset>,B<-c> I<CHARSET>

Specify the character set with which to output the menu.  Defaults to
the character set in use by the current locale.

=item B<--language>,B<-l> I<LANGUAGE>

Specify the output language for the menu.  Defaults to the language set
in the current locale.

=item B<--noicons>,B<-n>

Do not include icons in the generated menu files.  This option has no
effect when it is not possible to generate icons for the menu format.
That is, when the B<--format> is one such as C<blackbox>, it is not
possible to place icons in the menu and this option is therefore
ignored.  The default is to place icons in capable generated menus.

=item B<--root-menu>,B<-r> I<MENU>

Specify the location of the root menu file.  The default is calculated
using XDG environment variables (see L</ENVIRONMENT>), and defaults to
the file F<${XDG_MENU_PREFIX}applications.menu> in the
F<$XDG_CONFIG_HOME:$XDG_CONFIG_DIRS> search path.

=back

=head1 BEHAVIOR

When B<xde-menu> starts, it detects the environment within which it is
started, detects the current window manager and determines whether the
window manager is a supported window manager, and generates the menu
based on the B<XDE_MENU_PREFIX> and B<XDE_CURRENT_DESKTOP> fields.

For most supported window managers, B<xde-menu> moves the current
menu file to a backup file and creates a symbolic link to a file in the
F</tmp> directory that contains the updated menu.  This is because menus
are host specific and the user home directory could be shared over an
NFS mount.

B<xde-menu> then generates a system tray (GTK2) menu that corresponds to
the root window for the current window manager.  The theme for the GTK2
menu is taken from the current settings of style and theme for the
window manager (rather than the GTK2 theme in effect for applications).
The fallback if an unknown window manager is present is to use the
default GTK2 theme.

B<xde-menu> then monitors for three conditions:

=over

=item 1.

A change to any of the source directories that were used to generate the
menu.  L<Linux::Inotify2(3pm)> is used for this purpose so that no
adverse load is placed on the processor or file system.  If the contents
of any directory used in the generation of the menu changes, the menus
(root and tray) are regenerated.

=item 2.

A change in the window manager is monitored and the root menu is
generated for a new window manager whenever it changes.  See L</WINDOW
MANAGERS>.

=item 3.

A change in the window manager style is monitored and the selected style
is applied to the system tray GTK2 menu when a style change (XDE theme
change) is detected.

=back

B<xde-menu> understands the file and style settings for various
lightweight window managers: L<fluxbox(1)>, L<blackbox(1)>,
L<openbox(1)>, L<icewm(1)>, L<fvwm(1)>, L<lxde(1)>, and L<wmaker(1)>.

=head1 ENVIRONMENT

As an XDG compatible application, B<xde-menu> considers the following
environment variables:

=over

=item B<XDG_MENU_PREFIX>


Specifies the prefix to apply to the default menu name to derive the
root menu unless specified with B<--root-menu>.  When unspecified, this
variable defaults to a null string.

B<xde-menu> finds the root menu using the following logic:

=over

=item 1.

If a file name is specified using the B<--root-menu> option, that file
name is used as the root menu.

=item 2.

If not found, the file name F<${XGD_MENU_PREFIX}application.menu> is
sought in each of the directories in the path F<@XDG_CONFIG_DIRS/menus>.

=item 3.

If not found, the file name F<application.menu> is sought in each of the
directories in the path F<@XDG_CONFIG_DIRS/menus>.

=back

=item B<XDG_CURRENT_DESKTOP>

Specifies the current desktop.  When the B<--format> is not specified,
the format defaults to the value of this environment variable converted
to lower-case.  When the B<--desktop> is not specified, the desktop
defaults to the value of this environment variable.

Although this value is considered when the program is started,
B<xde-menu> monitors for a change in the active window manager and
alters the current desktop definition accordingly.  This is so that the
root menu continues to function properly even when the window manager is
changed from within the window manager (i.e. from the menu) and when run
outside of a proper XDG environment.

=item B<XDG_CONFIG_HOME>

Specifies the user configuration directory.  When unspecified, this
variable defaults to F<$HOME/.config> in accordance with XDG
specifications.

=item B<XDG_CONFIG_DIRS>

Specifies the system configuration directories.  When unspecified, this
variable defaults to F</etc/xdg> in accordance with XDG specifications.

=item B<XDG_DATA_HOME>

Specifies the user data directory.  When unspecified, this variable
defaults to F<$HOME/.local/share> in accordance with XDG specifications.

=item B<XDG_DATA_DIRS>

Specifies the system data directories.  When unspecified, this variable
defaults to F</usr/local/share:/usr/share> in accordance with XDG
specifications.

=back

=head1 SIGNALS

B<xde-menu> intercepts and acts upon the following signals:

=over

=item B<$SIG{HUP}>

When B<xde-menu> receives a C<$SIG{HUP}> signal, it rereads source files
and regenerates menu files.

=item B<$SIG{TERM}>

When B<xde-menu> receives a C<$SIG{HUP}> signal, it rereads source files
and regenerates menu files one last time before exitting gracefully.

=back

=head1 WINDOW MANAGERS

B<xde-menu> supports a number of lightweight window managers.  To avoid
communication with any other XDE tools and to allow B<xde-menu> to be a
standalone resource, it detects the window manager in use and the theme
being applied to the window manager so that the GTK2 system tray menu
can be formatted to appear consistent with the window manager root menu.
Note that only XDE themes or GTK2 themes with the same name as the
window manager style are supported.  Otherwise, the GTK2 system tray
menu style will revert to the same style used by applications and set
with such tools as L<lxappearance(1)>.

All supported window managers set the B<_NET_SUPPORTING_WM_CHECK>
option.  All also set B<_NET_WM_NAME> which can be used to determine the
name of the window manager, with the exception of WindowMaker, which
does not set B<_NET_WM_NAME> at all.

B<xde-menu> manages some of the quirks associated with each supported
window manager as follows:

=over

=item L<fluxbox(1)>

When L<fluxbox(1)> changes its style, it writes the new style in the
C<sessionStyle> routes in the init file (typically
F<$HOME/.fluxbox/init>).  B<xde-meu> monitors for this change and
parses the file to locate its new GTK2 theme when it changes.

When L<fluxbox(1)> restarts, it does not change the
B<_NET_SUPPORTING_WM_CHECK> property but does change the
B<_BLACKBOX_PID> property, even if it is just to replace it with the
same value.  When check for style changes when this property changes.

=item L<blackbox(1)>

When L<blackbox(1)> changes its style, it restarts, and executes the
C<rootCommand> from the style file.  Our XDE style files have a root
command that changes the B<_BB_THEME> property on the root window, so we
recheck the GTK2 theme whenever this property changes.

=item L<openbox(1)>

When L<openbox(1)> changes its theme, it changes the B<_OB_THEME>
property on the root window.  Whenever the B<_OB_THEME> property on the
root window changes, we recheck for a new GTK2 theme.

=item L<icewm(1)>

When L<icewm(1)> changes its style it restarts.  When it restarts it
changes the B<_NET_SUPPORTING_WM_CHECK> property on the root window.
Whenever the B<_NET_SUPPORTING_WM_CHECK> property changes on the root
window, we recheck the GTK2 theme.

=item L<fvwm(1)>

=item L<wmaker(1)>

When L<wmaker(1)> changes its theme, the
F<$HOME/GNUStep/Defaults/WindowMaker> file is changed.

=back

=head1 HISTORY

B<xde-menu> was written for a number of reasons:

=over

=item 1.

Existing fluxbox menu generators that read XDG .desktop files
(L<fbmenugen(1)>, L<menutray(1)>) do not conform to XDG menu generation
specifications and in particular are incapable of merging menus.

=item 2.

Existing XDG menu generators (such as the SuSE L<xdg_menu(1)> script) do
not properly merge default merge directories and do not observe <Layout>
commands.  Also, they are poor at including icons in the generated menus.

=item 3.

Existing XDG menu generators run once and keep cache information.  They
do not monitor XDG directories for changes and update menus on changes.

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDG::Menu(3pm)>, L<XDG::Icons(3pm)>,
L<Linux::Inotify2(3pm)>.

=cut

# vim: sw=4 tw=72:
