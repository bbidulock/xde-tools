#!/usr/bin/perl

# in case we get executed (not sourced) as a shell program
eval 'exec perl -S $0 ${1+"@"}'
    if $running_under_some_shell;

use strict;

#
# are we installed or running in a sandbox?
#
use lib (-e '/usr/lib/perlpanel' ? '/usr/lib/perlpanel' : $ENV{PWD}.'/lib/');

use Glib qw(TRUE FALSE);
use Gtk2;

Gtk2::Rc->set_default_files("$ENV{HOME}/.gtkrc-2.0.xde");

use PerlPanel;

#
# set the values for prefix and libdir:
#
$PerlPanel::PREFIX = (-e '/usr' ? '/usr' : $ENV{PWD});
$PerlPanel::LIBDIR = (-e '/usr/lib/perlpanel' ? '/usr/lib/perlpanel' : $ENV{PWD}.'/lib/');
$PerlPanel::DEFAULT_THEME = 'Mist';

#
# if we're in a sandbox then it's handy to add ./src to the PATH:
#
$ENV{PATH} = $ENV{PATH}.':'.$ENV{PWD}.'/src' if (!-e '/usr');

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

use PerlPanel::Applet::Commander;
my $commander = PerlPanel::Applet::Commander->new;
$commander->configure('no-widget');
$commander->run;
Gtk2->main;

exit;
