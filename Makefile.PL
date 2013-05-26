use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'xdg-tools',
	VERSION => '0.01',
	EXE_FILES => [
		'xde-chooser',
		'xde-icon',
		'xde-input',
		'xde-logout',
		'xde-menugen',
		'xde-pager',
		'xde-session',
		'xde-session-ctrl',
		'xde-session-edit',
		'xde-session-logout',
		'xde-session-menu',
		'xde-session-run',
		'xde-setbg',
		'xde-setbg-edit',
		'xde-setup',
		'xde-settings',
		'xde-startup',
		'xde-theme',
		'xde-traymenu',
	],
	PREREQ_PM => {
		'Getopt::Long' => 0,
		'Encode' => 0,
		'I18N::Langinfo' => 0,
		'POSIX' => 0,
		'Glib' => 0,
		'Gtk2' => 0,
		'Net::DBus' => 0,
		'Net::DBus::GLib' => 0,
	},
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
