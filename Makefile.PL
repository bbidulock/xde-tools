use ExtUtils::MakeMaker;
my $VERSION = '0.01';
if (-d ".git") {
	$VERSION = `git describe --tags`;
	$VERSION =~ s/[-_]/./g;
	$VERSION =~ s/\.g[0-9a-f]{7,}$//;
}
WriteMakefile(
	NAME => 'xde-tools',
	VERSION => $VERSION,
	EXE_FILES => [qw(
		icccm-test
		sn-launch
		sn-monitor
		xde-autostart
		xde-chooser
		xde-clock
		xde-desktop
		xde-dock
		xde-fluxbox
		xde-genmenu
		xde-icon
		xde-init
		xde-input
		xde-keys
		xde-launch
		xde-logout.pl
		xde-menu.pl
		xde-menugen.pl
		xde-monitor
		xde-pager.pl
		xde-panel
		xde-run.pl
		xde-session
		xde-session.conf.pod
		xde-session-ctrl
		xde-session-edit
		xde-session-logout
		xde-session-menu
		xde-session-run
		xde-setbg.pl
		xde-setbg2
		xde-setbg-edit
		xde-settings
		xde-setup
		xde-startup
		xde_style
		xde-test
		xde-test2
		xde-test3
		xde-test4
		xde-test5
		xde-test7
		xde-test8
		xde_theme
		xde-theme2
		xde-theme3
		xde-traymenu.pl
		xde-xset
		xdg_launch
		xlib-test
		xde-winlist
		xde-winmenu
	)],
	PREREQ_PM => {
		'Carp' => 0,			# perl
		'Encode' => 0,			# perl
		'Fcntl' => 0,			# perl
		'File::Path' => 0,		# perl
		'File::stat' => 0,		# perl
		'File::Which' => 0,		# perl-file-which
		'Getopt::Long' => 0,		# perl
		'Glib' => 0,			# glib-perl
		'Gnome2::VFS' => 0,		# gnome-vfs-perl
		'Gtk2' => 0,			# gtk2-perl
		'I18N::Langinfo' => 0,		# perl
		'IO::Select' => 0,		# perl
		'Linux::Inotify2' => 0,		# perl-linux-inotify2
		'Net::DBus' => 0,		# perl-dbus-git
		'Net::DBus::GLib' => 0,		# perl-net-dbus-glib
		'POSIX' => 0,			# perl
		'Time::gmtime' => 0,		# perl
		'Time::HiRes' => 0,		# perl
		'URI::file' => 0,		# perl-uri
		'X11::Keysyms' => 0,		# perl-x11-protocol
		'X11::Protocol' => 0,		# perl-x11-protocol
						# perl-x11-protocol-other
		'X11::Protocol::Enhanced' => 0,	# perl-x11-protocol-more
		'XML::SAX::ParserFactory' => 0,	# perl-xml-sax
	},
	# basically strip the pod out of the .pm file and squeeze blank lines
	PM_FILTER => qq{(sed '/^=[^c]/,/^=cut/d'|cat -s)},
);

sub MY::postamble {
	return <<MAKE_FRAG;

.PHONY: install_xdg install_share
install:: install_xdg install_share

install_xdg:
	install -dm0755 "\$(DESTDIR)/etc"
	cp -rv xdg "\$(DESTDIR)/etc"

install_share:
	install -dm0755 "\$(DESTDIR)/\$(PREFIX)"
	cp -rv share "\$(DESTDIR)/\$(PREFIX)"

MAKE_FRAG
}
