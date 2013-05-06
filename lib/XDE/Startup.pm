package XDE::Startup;
require XDE::Context;
use strict;
use warnings;

=head1 NAME

XDE::Startup - setup and start an XDE session for a window manager

=head1 SYNOPSIS

 require XDE::Context;
 require XDE::Chooser;
 require XDE::Startup;

 my $xde = XDE::Context->new();
 $xde->getenv();
 my $xsessions = $xde->get_xsessions;
 my $chooser = XDE::Chooser->new($xde,{});
 my ($choice,$entry) = $chooser->choose();
 exit(0) if $choice eq 'logout';

 if (my $startup = XDE::Startup->new($xde,{},$choice,$entry)) {
     $startup->setup();
     $startup->exec();
     exit(1);
 }
 else {
     print STDERR "Cannot start $choice under XDE\n";
     print STDERR "Executing '$entry->{Exec}'\n";
     exec("$entry->{Exec}");
     exit(1);
 }

=head1 DESCRIPTION

B<XDE::Startup> is a module in the X Desktop Environment suite that
sets up configuration files and executes autostart sequences and window
managers for various supported sessions.

=cut


use constant {
    SESSIONS => {
	fluxbox		 => 'fluxbox',
	'fluxbox-xde'	 => 'fluxbox',
	blackbox	 => 'blackbox',
	'blackbox-xde'	 => 'blackbox',
	openbox		 => 'openbox',
	'openbox-session'=> 'openbox',
	'openbox-xde'	 => 'openbox',
	icewm		 => 'icewm',
	'icewm-session'	 => 'icewm',
	'icewm-xde'	 => 'icewm',
	fvwm		 => 'fvwm',
	fvwm2		 => 'fvwm',
	'fvwm-xde'	 => 'fvwm',
	wmaker		 => 'wmaker',
	'wmaker-xde'	 => 'wmaker',
	windowmaker	 => 'wmaker',
    },
    CONFDIR => {
	fluxbox		 => "~/.fluxbox",
	blackbox	 => "~/.blackbox",
	openbox		 => "~/.config/openbox",
	icewm		 => "~/.icewm",
	fvwm		 => "~/.fvwm",
	wmaker		 => "~/GNUstep",
    },
    CONFFILE => {
	fluxbox		 => 'xde-init',
	blackbox	 => 'xde-rc',
	openbox		 => 'xde-rc.xml',
	icewm		 => '', # multiple actually
	fvwm		 => 'config', # other names too
	wmaker		 => 'Defaults/WindowMaker',
    },
    MENUDIR => {
	fluxbox		 => '~/.fluxbox',
	blackbox	 => '~/.blackbox',
	openbox		 => '~/.config/openbox',
	icewm		 => '~/.icewm',
	fvwm		 => '~/.fvwm',
	wmaker		 => '~/GNUstep',
    },
    MENUFILE => {
	fluxbox		 => 'menu',
	blackbox	 => 'menu',
	openbox		 => 'menu.xml',
	icewm		 => 'menu',
	fvwm		 => 'preferences',
	wmaker		 => 'Library/WindowMaker/menu',
    },
    SUBDIRS => {
	fluxbox		 => [qw(backgrounds icons pixmaps splash styles tiles)],
	blackbox	 => [qw(backgrounds styles)],
	openbox		 => [],
	icewm		 => [qw(themes)],
	fvwm		 => [qw(icons)],
    },
    CFGFILES => {
	fluxbox		 => [qw(overlay menuconfig startup windowmenu usermenu fbpager keys slitlist apps)],
	blackbox	 => [],
	openbox		 => [],
	icewm		 => [qw(focus_mode keys prefoverride programs theme)],
	fvwm		 => [qw(bindings decorations functions globalfeel iconstyles menus modules startup sytles)],
    },
};

=head1 METHODS

=over

=item $startup = XDE::Startup->B<new>(I<$xde>,I<$ops>,I<$choice>,I<$entry>)

Creates a new XDE::Startup instance.  C<undef> is returned unless the
session specified by C<$choice> is supported.  See L</SESSIONS>.

=cut

sub new {
    my $type = shift;
    my ($xde,$ops,$label,$entry) = @_;
    die 'usage: XDG::Startup->new($xde,$ops,$label,$entry)'
	unless $xde and $xde->isa('XDE::Context') and
	       $ops and ref($ops) =~ /HASH/
	       and $label and $entry;
    unless (&SESSION->{"\L$label\E"}) {
	print STDERR "Cannot start up session '$label'\n"
	    if $ops->{verbose};
	return undef;
    }
    return undef unless &SESSION->{"\L$label\E"};
    my $session = &SESSION->{"\L$label\E"};
    my $desktop = "\U$session\E";
    my $self = bless {
	xde=>$xde,
	ops=>$ops,
	label=>$label,
	session=>$session,
	desktop=>$desktop,
	entry=>$entry,
    }, $type;
    $xde->setup({
	    XDG_CURRENT_DESKTOP => $desktop,
	    DESKTOP_SESSION	=> $desktop,
	    FBXDG_DE		=> $desktop,
	    XDE_SESSION		=> $session,
	    XDE_CONFIG_DIR	=> undef,
	    XDE_CONFIG_FILE	=> undef,
	    XDE_MENU_DIR	=> undef,
	    XDE_MENU_FILE	=> undef,
    });
    $xde->setenv();
    return $self;
}

=item $startup->B<setup_session>()

=cut

sub setup_session {
    my $self = shift;
    my $session = shift;
    my $rcdir = $self->{XDE_CONFIG_DIR};
    mkpath $rcdir unless -d $rcdir;
    foreach (@{&XDE::Context::SUBDIRS->{$session}}) {
	mkpath "$rcdir/$_" unless -d "$rcdir/$_";
    }
    foreach my $file ($self->{XDE_CONFIG_FILE}, $self->{XDE_MENU_FILE},
	    @{&XDE::Context::CFGFILES->{$session}}) {
	my $rcfile = "$rcdir/$file";
	$base = $file; $base =~ s{^.*/}{};
	foreach my $dir (map {"$_/$session"} @{$self->{XDG_DATA_ARRAY}}) {
	    my $rcbase = "$dir/$base";
	    if (-f $rcbase) {
		system("/bin/cp -f \"$rcbase\" \"$rcfile\"")
		    unless -f $rcfile and stat($rcfile)[9] > stat($rcbase);
		last;
	    }
	}
    }
}

=back

=cut

1;
