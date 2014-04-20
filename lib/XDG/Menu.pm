use XDG::Icons;


package XDG::Menu::Layout::Item;
use strict;
use warnings;

package XDG::Menu::Layout::Entry;
use base qw(XDG::Menu::Layout::Item);
use strict;
use warnings;

sub Name {
    return shift->{Name};
}
sub Icon {
    my $self = shift;
    return $self->{Entry}->Icon(@_);
}

package XDG::Menu::Layout::Menu;
use base qw(XDG::Menu::Layout::Item);
use strict;
use warnings;

sub new {
    return bless {}, shift;
}

package XDG::Menu::Layout::Header;
use base qw(XDG::Menu::Layout::Entry);
use strict;
use warnings;

sub new {
    my ($type,$menu) = @_;
    return bless {
	Entry =>    $menu->{Directory},
	Name =>	    $menu->{Directory}{Name},
	Path =>	    $menu->{Path},
	Item =>	    $menu->{Item},
    }, $type;
}

sub Icon {
    my ($self,$exts) = @_;
    return $self->SUPER::Icon($exts,'unknown');
}

package XDG::Menu::Layout::Separator;
use base qw(XDG::Menu::Layout::Item);
use strict;
use warnings;

sub new {
    return bless { Name=>undef }, shift;
}

package XDG::Menu::Layout::Application;
use base qw(XDG::Menu::Layout::Entry);
use strict;
use warnings;

sub new {
    my ($type,$app) = @_;
    return bless {
	Entry =>    $app,
	Name =>	    $app->{Name},
    }, $type;
}
sub Id {
    my $self = shift;
    my $file = $self->{Entry}->{file};
    $file =~ s{^.*/}{};
    $file =~ s{\.desktop$}{};
    return $file;
}
sub Exec {
    my $self = shift;
    return $self->{Entry}->Exec;
}
sub StartupNotify {
    my $self = shift;
    my $entry = $self->{Entry};
    if ($entry->{StartupNotify} and $entry->{StartupNotify} =~ /yes|true/i) {
	return 'yes';
    }
    return 'no';
}
sub StartupWMClass {
    my $self = shift;
    return $self->{Entry}->{StartupWMClass};
}

sub Icon {
    my ($self,$exts) = @_;
    return $self->SUPER::Icon($exts,'exec');
}

package XDG::Menu::Layout::Directory;
use base qw(XDG::Menu::Layout::Entry);
use strict;
use warnings;

sub new {
    my ($type,$menu) = @_;
    return bless {
	Menu =>	    $menu,
	Entry =>    $menu->{Directory},
	Name =>	    $menu->{Directory}{Name},
	Path =>	    $menu->{Path},
    }, $type;
}

sub Icon {
    my ($self,$exts) = @_;
    return $self->SUPER::Icon($exts,'folder');
}

package XDG::Menu::DesktopAction;
use Carp qw(cluck croak confess);
use strict;
use warnings;

my $icons;

sub get_icons {
    my $self = shift;
    $icons = XDG::Icons->new({
	Append => '/usr/share/WindowMaker/Icons',
    }) unless $icons;
    confess "no icons" unless defined $icons;
    return $icons;
}

sub Icon {
    my ($self,$exts,$dflt) = @_;
    $dflt = 'exec' unless $dflt;
    my $icon = $self->{Icon};
    $icon = '' unless $icon;
    $exts = ['xpm'] unless $exts and @$exts;
    if ($icon =~ m{^/} and -f $icon) {
	foreach (@$exts) {
	    return $icon if $icon =~ m{\.$_$};
	}
    }
    my $name = $icon;
    $name =~ s{^.*/}{};
    $name =~ s/\.[a-z]{3,4}$//;
    if (my $icons = $self->get_icons) {
	$icon = $icons->FindIcon($name,16,$exts) if $name;
	$icon = $icons->FindIcon($dflt,16,$exts) unless $icon;
	return $icon if $icon;
    }
    return '';
}

package XDG::Menu::DesktopEntry;
use base qw(XDG::Menu::DesktopAction);
use Encode qw(decode encode);
use strict;
use warnings;

sub new {
    my $self = bless {}, shift;
    my $file = shift;
    my $lang = shift;
    return undef unless -f $file;
    open (my $fh, "<", $file) or warn $!;
    return undef unless $fh;
    my ($section,$action) = ('','');
    my %xl = ();
    while (<$fh>) {
	if (/^\[([^]]*)\]/) {
	    $section = $1;
	    if ($section =~ /^Desktop Action (\w+)$/) {
		$action = $1;
		$self->{_actions}{$action} = bless {}, 'XDG::Menu::DesktopAction';
	    } else {
		$action = '';
	    }
	     #print "I: $file parsing section $section\n";
	    $section = '' unless
		$section eq 'Desktop Entry' or $action;
	    }
	elsif ($section and /^([^=\[]+)\[([^=\]]+)\]\s*=\s*([^[:cntrl:]]*)/) {
	    my ($label,$trans,$value) = ($1,$2,$3);
	    $value =~ s/\s+$//;
	    if ($action) {
		$xl{_actions}{$action}{$label}{$trans} = decode('UTF-8', $value);
		 #print "I: $file action $action $label\[$trans\]=$value\n";
	    } else {
		$xl{$label}{$trans} = decode('UTF-8', $value);
		 #print "I: $file $label\[$trans\]=$value\n";
	    }
	}
	elsif ($section and /^([^=]*)\s*=\s*([^[:cntrl:]]*)/) {
	    my ($label,$value) = ($1,$2);
	    $value =~ s/\s+$//;
	    if ($action) {
		$self->{_actions}{$action}{$label} = decode('UTF-8', $value);
		 #print "I: $file action $action $label=$value\n";
	    } else {
		$self->{$label} = decode('UTF-8', $value);
		 #print "I: $file $label=$value\n";
	    }
	}
    }
    close($fh);
    if ($lang) {
	$lang =~ m{^(..)}; my $short = $1;
	if (exists $xl{_actions}) {
	    foreach $action (keys %{$xl{_actions}}) {
		foreach (keys %{$xl{_actions}{$action}}) {
		    if (exists $xl{_actions}{$action}{$_}{$lang}) {
			$self->{_actions}{$action}{$_} = $xl{_actions}{$action}{$_}{$lang};
		    }
		    elsif ($short and exists $xl{_actions}{$action}{$_}{$short}) {
			$self->{$_} = $xl{$_}{$short};
		    }
		}
	    }
	}
	foreach (keys %xl) {
	    next if $_ eq '_actions';
	    if (exists $xl{$_}{$lang}) {
		$self->{$_} = $xl{$_}{$lang};
	    }
	    elsif (exists $xl{$_}{$short}) {
		$self->{$_} = $xl{$_}{$short};
	    }
	}
    }
    $self->{file} = $file;
    unless ($self->{Type}) {
	print STDERR "ERROR: $file has no Type key\n";
	return undef;
    }
    unless ($self->{Type} =~ m{^(Application|Directory)$}) {
	print STDERR "ERROR: $file is of Type $self->{Type}\n";
	return undef;
    }
    unless ($self->{Name}) {
	print STDERR "ERROR: $file has no Name key\n";
	return undef;
    }
    unless ($file =~ m{\.desktop$}) {
    return $self;
    }
    my $d = $file; $d =~ s{/[^/]*$}{};
    my $f = $file; $f =~ s{.*/}{};
    my $id = $f; $id =~ s{\.desktop$}{};
    unless ($self->{Name}) {
	$self->{Name} = $id;
	#print STDERR "WARNING: $file has no Name key, using $id\n";
    }
    unless ($self->{Exec}) {
	$self->{Exec} = '';
	#print STDERR "WARNING: $file has no Exec key\n";
    }
    unless ($self->{Comment}) {
	$self->{Comment} = $self->{Name};
	#print STDERR "WARNING: $file has no Comment key, using $self->{Name}\n";
    }
    unless ($self->{Icon}) {
	$self->{Icon} = $id;
	#print STDERR "WARNING: $file has no Icon key, using $id\n";
    }
    unless ($self->{Icon} =~ m{^/}) {
	if ($self->{Icon} =~ m{\.(png|jpg|xpm|svg|jpeg|tiff|gif)$}) {
	    #print STDERR "WARNING: $file Icon $self->{Icon} should not have .$1 extension\n";
	    $self->{Icon} =~ s{\.(png|jpg|xpm|svg|jpeg|tiff|gif)$}{};
	}
    }
    if ($self->{_actions}) {
	my @todelete = ();
	foreach $action (keys %{$self->{_actions}}) {
	    unless ($self->{_actions}{$action}{Name}) {
		$self->{_actions}{$action}{Name} = $action;
		push @todelete, $action;
		continue;
	    }
	    unless ($self->{_actions}{$action}{Exec}) {
		$self->{_actions}{$action}{Exec} = '';
	    }
	    unless ($self->{_actions}{$action}{Icon}) {
		$self->{_actions}{$action}{Icon} = $self->{Icon};
	    }
	    unless ($self->{_actions}{$action}{Icon} =~ m{^/}) {
		if ($self->{_actions}{$action}{Icon} =~ m{\.(png|jpg|xpm|svg|jpeg|tiff|gif)$}) {
		    #print STDERR "WARNING: $file action $action Icon $self->{_actions}{$action}{Icon} should not have .$1 extension\n";
		    $self->{_actions}{$action}{Icon} =~ s{\.(png|jpg|xpm|svg|jpeg|tiff|gif)$}{};
		}
	    }
	}
	foreach $action (@todelete) {
	    delete $self->{_actions}{$action};
	}
    }
    return $self;
}

package XDG::Menu::DesktopApplication;
use base qw(XDG::Menu::DesktopEntry);
use Carp qw(cluck);
use strict;
use warnings;

sub new {
    my ($type,$file) = @_;
    return undef unless $file =~ /\.desktop$/;
    return XDG::Menu::DesktopEntry::new(@_);
}

sub Exec {
    my $self = shift;
    my $exec = $self->{Exec};
    $exec = 'xterm -T %c -e '.$exec if $self->{Terminal} and $self->{Terminal} =~ /true/i;
    $exec =~ s/([^%])%i/$1--icon $self->{Icon}/g if $self->{Icon};
    $exec =~ s/([^%])%c/$1"$self->{Name}"/g if $self->{Name};
    $exec =~ s/([^%])%k/$1"$self->{file}"/g if $self->{file};
    $exec =~ s{([^%])%[fFuUdDnNvm]}{$1}g;
    $exec =~ s{([^%])%[A-Za-z]}{$1}g;
    $exec =~ s{([^%])%([^%])}{$1$2}g;
    $exec =~ s{%%}{%}g;
    $exec =~ s{\s+$}{};
    $exec =~ s{^\s+}{};
    return $exec;
}

package XDG::Menu::DesktopDirectory;
use base qw(XDG::Menu::DesktopEntry);
use strict;
use warnings;

sub new {
    my ($type,$file) = @_;
    return undef unless $file =~ /\.directory$/;
    return XDG::Menu::DesktopEntry::new(@_);
}

package XDG::Menu::Element;
use strict;
use warnings;

#package XDG::Menu::Element;
sub beg {
    my ($type,$pars,$data) = @_;
    my $self = bless {}, $type;
    if (exists $data->{Attributes}) {
	my $attrs = $data->{Attributes};
	foreach (keys %$attrs) {
	    my $attr = $attrs->{$_};
	    $self->{$attr->{Name}} = $attr->{Value};
	}
    }
    return $self;
}

#package XDG::Menu::Element;
sub content {
    my ($self,$pars,$chars) = @_;
    $self->{Data} = $chars;
}

#package XDG::Menu::Element;
sub end {
    my ($self,$pars) = @_;
    push @{$pars->{stack}[0]{Contains}}, $self;
}

#package XDG::Menu::Element;
sub absolute {
    my ($self,$pars,$dir) = @_;
    unless (not $dir or $dir =~ m{^/}) {
	my $basedir = $pars->{files}[0]; $basedir =~ s{/[^/]*$}{};
	my @dirs = (split(/\//,$basedir),split(/\//,$dir));
	my @rslt = ();
	foreach (@dirs) {
	    if ($_ eq '' or $_ eq '.') {
		next;
	    }
	    elsif ($_ eq '..') {
		pop @rslt if @rslt;
		next;
	    }
	    else {
		push @rslt, $_;
		next;
	    }
	}
	my $abs = join('/',@rslt);
	$abs = "/$abs" unless $abs =~ m{^/};
	return $abs;
    }
    return $dir;
}

#package XDG::Menu::Element;
sub resolve {
    my ($self,$pars) = @_;
    foreach my $array (qw(AppDirs Rules DirectoryDirs Directories DefaultLayouts Layouts Contains Submenus)) {
	if ($self->{$array}) {
	    foreach my $obj (@{$self->{$array}}) {
		if ($obj->can('resolve')) {
		    unshift @{$pars->{stack}}, $obj if $obj->isa('XDG::Menu::Element');
		    unshift @{$pars->{menus}}, $obj if $obj->isa('XDG::Menu::Menu');
		    $obj->resolve($pars);
		    shift @{$pars->{menus}} if $obj->isa('XDG::Menu::Menu');
		    shift @{$pars->{stack}} if $obj->isa('XDG::Menu::Element');
		}
	    }
	}
    }
}

#package XDG::Menu::Element;
sub layout {
    my ($self,$pars) = @_;
    foreach my $array (qw(Submenus Layouts Contains)) {
	if ($self->{$array}) {
	    foreach my $obj (@{$self->{$array}}) {
		if ($obj->can('layout')) {
		    unshift @{$pars->{stack}}, $obj if $obj->isa('XDG::Menu::Element');
		    unshift @{$pars->{menus}}, $obj if $obj->isa('XDG::Menu::Menu');
		    $obj->layout($pars);
		    shift @{$pars->{menus}} if $obj->isa('XDG::Menu::Menu');
		    shift @{$pars->{stack}} if $obj->isa('XDG::Menu::Element');
		}
	    }
	}
    }
}

#package XDG::Menu::Element;
sub cleanup {
    my ($self,$pars) = @_;
    foreach my $array (qw(Submenus)) {
	if ($self->{$array}) {
	    foreach my $obj (@{$self->{$array}}) {
		if ($obj->can('cleanup')) {
		    unshift @{$pars->{stack}}, $obj if $obj->isa('XDG::Menu::Element');
		    unshift @{$pars->{menus}}, $obj if $obj->isa('XDG::Menu::Menu');
		    $obj->cleanup($pars);
		    shift @{$pars->{menus}} if $obj->isa('XDG::Menu::Menu');
		    shift @{$pars->{stack}} if $obj->isa('XDG::Menu::Element');
		}
	    }
	}
    }
}

package XDG::Menu::NoData;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub content {
    my ($self,$pars,$chars) = @_;
    # ignore content
}

package XDG::Menu::Rule;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    push @{$pars->{stack}[0]{Rules}}, $self;
}

package XDG::Menu::Menu;
use base qw(XDG::Menu::NoData XDG::Menu::Layout::Menu);
use File::Which qw(which);
use strict;
use warnings;

#package XDG::Menu::Menu;
sub beg {
    my ($type,$pars,$data) = @_;
    if ($pars->{starting}) {
	my $self = shift @{$pars->{stack}};
	push @{$self->{wasrooted}}, $self->{rooted};
	$self->{rooted} = 1;
	$pars->{starting} = 0;
	return $self;
    }
    my $self = bless {}, $type;
    unshift @{$pars->{menus}}, $self;
    return $self;
}

#package XDG::Menu::Menu;
sub end {
    my ($self,$pars) = @_;
    $self->{Name} = 'Unknown' unless $self->{Name};
    # merge directories of the same name at the same level.
    my $parent = $pars->{stack}[0];
    my $path = $self->{Path} =
	    join('/',map {$_->{Name}} reverse @{$pars->{menus}});
    if (my $menu = $pars->{Menus}{$path}) {
	# remove from previous position
	$parent->{Submenus} =
	    [ map {($_->{Name} eq $menu->{Name}) ? () : $_}
		@{$parent->{Submenus}} ];
	# incorporate deleted submenu into this one
	foreach (qw(Rules DirectoryDirs AppDirs MergeDirs MergeFiles Directories DefaultLayouts Layouts Contains)) {
	    $menu->{$_} = [] unless $menu->{$_};
	    $self->{$_} = [] unless $self->{$_};
	    $self->{$_} = [@{$menu->{$_}},@{$self->{$_}}];
	}
	# expose apps, dirs and mrgs but do not overwrite
	foreach my $map (qw(apps dirs mrgs)) {
	    foreach (keys %{$menu->{$map}}) {
		$self->{$map}{$_} = $menu->{$map}{$_}
		    unless exists $self->{$map}{$_};
	    }
	}
	# $menu is dropped
    }
    $pars->{Menus}{$path} = $self;
    push @{$parent->{Submenus}}, $self;
    if ($self->{rooted}) {
	$self->{rooted} = pop @{$self->{wasrooted}};
	unshift @{$pars->{stack}}, $self;
    }
    else {
	shift @{$pars->{menus}};
    }
}

#package XDG::Menu::Menu;
sub resolve {
    my ($self,$pars) = @_;
    # on our way down, create Applications array to be completed by
    # rules
    $self->{apps} = {};
    # we inherit all of the {apps} defined by superior menus
    if (my $parent = $pars->{menus}[1]) {
	if ($parent->{apps}) {
	    foreach (values %{$parent->{apps}}) {
		$self->{apps}{$_->{id}} = $_;
	    }
	}
    }
    $self->{Applications} = {};
    # create default Directory entry to be overwritten by XDG::Menu::Directory
    # entries
    $self->{dirs} = {};
    # we inherit all of the {dirs} defined by superior menus
    if (my $parent = $pars->{menus}[1]) {
	if ($parent->{dirs}) {
	    foreach (values %{$parent->{dirs}}) {
		$self->{dirs}{$_->{id}} = $_;
	    }
	}
    }
    # generate default directory
    $self->{Directory} = bless({
	Type=>'Directory',
	Name=>$self->{Name},
    }, "XDG::Menu::DesktopDirectory");
    $self->XDG::Menu::Element::resolve($pars);
    # cull {Applications} based on (Only|Not)ShowIn, Hidden, NoDisplay
    if ($self->{Applications}) {
	my @des = split(/:/,$pars->{XDG_CURRENT_DESKTOP});
	my @deletions = ();
	foreach (keys %{$self->{Applications}}) {
	    my $app = $self->{Applications}{$_};
	    if ($app->{OnlyShowIn}) {
		my $found = 0;
		foreach my $de (@des) {
		    if (";$app->{OnlyShowIn};" =~ /;$de;/) {
			$found = 1;
			last;
		    }
		}
		if (!$found) {
		push @deletions, $_;
		next;
	    }
	    }
	    if ($app->{NotShowIn}) {
		my $found = 0;
		foreach my $de (@des) {
		    if (";$app->{NotShowIn};" =~ /;$de;/) {
			$found = 1;
			last;
		    }
		}
		if ($found) {
		    push @deletions, $_;
		    next;
		}
	    }
	    if ($app->{Hidden} and $app->{Hidden} =~ /true/i) {
		push @deletions, $_;
		next;
	    }
	    if ($app->{NoDisplay} and $app->{NoDisplay} =~ /true/i) {
		push @deletions, $_;
		next;
	    }
	    unless ($app->{Exec}) {
		print STDERR "WARNING: $app->{file} has no Exec statement\n";
		push @deletions, $_;
		next;
	    }
	    if ($app->{TryExec}) {
		if ($app->{TryExec} =~ m{/} and not -x $app->{TryExec}) {
		    push @deletions, $_;
		    next;
		}
		if ($app->{TryExec} !~ m{/} and not which($app->{TryExec})) {
		    push @deletions, $_;
		    next;
		}
	    } else {
		my $exec = $app->{Exec};
		$exec =~ s/\s.*$//;
		if ($exec =~ m{/} and not -x $exec) {
		push @deletions, $_;
		next;
	    }
		if ($exec !~ m{/} and not which($exec)) {
		push @deletions, $_;
		next;
		}
	    }
	}
	foreach (@deletions) {
	    delete $self->{Applications}{$_};
	}
    }
}

#package XDG::Menu::Menu;
sub layout {
    my ($self,$pars) = @_;
    # generate default layouts on the way down
    unless ($self->{DefaultLayouts}) {
	if (my $parent = $pars->{menus}[1]) {
	    if ($parent->{DefaultLayouts} and $parent->{DefaultLayouts}[-1]) {
		$self->{DefaultLayouts} = [ $parent->{DefaultLayouts}[-1] ];
	    }
	}
	unless ($self->{DefaultLayouts}) {
	    $self->{DefaultLayouts} = [
		bless({
		    show_empty=>'false',
		    inline=>'false',
		    inline_limit=>4,
		    inline_header=>'true',
		    inline_alias=>'false',
		    Contains=>[
			bless ({
			    type=>'menus',
			}, 'XDG::Menu::Merge'),
			bless ({
			    type=>'files',
			}, 'XDG::Menu::Merge'),
		    ],
		}, 'XDG::Menu::DefaultLayout'),
	    ];
	}
    }
    unless ($self->{Layouts}) {
	$self->{Layouts} = [ bless($self->{DefaultLayouts}[-1],'XDG::Menu::Layout') ];
    }
    # empty layout means use a default layout
    unless ($self->{Layouts}[0]{Contains} and $self->{Layouts}[0]{Contains}[1]) {
	$self->{Layouts} = [ bless($self->{DefaultLayouts}[-1],'XDG::Menu::Layout') ];
    }
    # need to collapse merged layouts
    shift @{$self->{Layouts}} while $self->{Layouts}[1];
    $self->XDG::Menu::Element::layout($pars);
    # clean up elements on the way out
    if ($self->{Elements}) {
	# cleanup separators in elements
	shift @{$self->{Elements}}
	    while $self->{Elements}[0] and
		  $self->{Elements}[0]->isa('XDG::Menu::Layout::Separator');
	pop @{$self->{Elements}}
	    while $self->{Elements}[-1] and
		  $self->{Elements}[-1]->isa('XDG::Menu::Layout::Separator');
    }
}

#package XDG::Menu::Menu;
sub cleanup {
    my ($self,$pars) = @_;
    $self->XDG::Menu::Element::cleanup($pars);
    # cleanup on the way out
    foreach (qw(rooted wasrooted apps dirs mrgs rules OnlyUnallocated
		Rules DirectoryDirs AppDirs MergeDirs MergeFiles
		Directories Contains Layouts DefaultLayouts Applications
		Path Name Directory Submenus)) {
	delete $self->{$_};
    }
}

package XDG::Menu::AppDir;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub content {
    my ($self,$pars,$chars) = @_;
    my $dir = $self->{path} = $self->absolute($pars,$chars);
    $pars->watch_directory($dir);
    return unless $dir and -d $dir;
    $self->scan($pars,$dir,[]);
}
sub end {
    my ($self,$pars) = @_;
     #delete $self->{apps};
    push @{$pars->{menus}[0]{AppDirs}}, $self;
}
sub scan {
    my ($self,$pars,$dir,$paths) = @_;
    opendir (my $fh, $dir) or warn $!;
    return 0 unless $fh;
    my $gotone = 0;
    foreach my $f (readdir($fh)) {
	next if $f eq '.' or $f eq '..';
	if (-d "$dir/$f") {
	    push @$paths, $f;
	    $gotone |= $self->scan($pars,"$dir/$f",$paths);
	    pop @$paths;
	}
	elsif (-f "$dir/$f") {
	    next unless $f =~ /\.desktop$/;
	    if (my $obj = XDG::Menu::DesktopApplication->new("$dir/$f")) {
		    my $id = join('-',@$paths,$f);
		    $obj->{id} = $id;
		     #$pars->{menus}[0]{apps}{$id} = $obj;
		    $self->{apps}{$id} = $obj;
		    $gotone = 1;
	    }
	}
    }
    close($fh);
    return $gotone;
}

sub resolve {
    my ($self,$pars) = @_;
    # on the way down assign all of our {apps} to the current menu
    if ($self->{apps}) {
	my $menu = $pars->{menus}[0];
	foreach (keys %{$self->{apps}}) {
	    $menu->{apps}{$_} = delete $self->{apps}{$_};
	}
    }
    $self->XDG::Menu::Element::resolve($pars);
}

package XDG::Menu::DefaultAppDirs;
use base qw(XDG::Menu::NoData);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    foreach (reverse @{$pars->{XDG_APPLICATIONS_DIRS}}) {
	next unless $_;
	my $obj = XDG::Menu::AppDir->beg($pars,{});
	#unshift @{$pars->{stack}}, $obj;
	$obj->content($pars,$_);
	#shift @{$pars->{stack}};
	$obj->end($pars);
    }
}

package XDG::Menu::DirectoryDir;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

#package XDG::Menu::DirectoryDir;
sub content {
    my ($self,$pars,$chars) = @_;
    my $dir = $self->{path} = $self->absolute($pars,$chars);
    $pars->watch_directory($dir);
    return unless $dir and -d $dir;
    $self->scan($pars,$dir,[]);
}

#package XDG::Menu::DirectoryDir;
sub end {
    my ($self,$pars) = @_;
     #delete $self->{dirs};
    push @{$pars->{menus}[0]{DirectoryDirs}}, $self;
}

#package XDG::Menu::DirectoryDir;
sub scan {
    my ($self,$pars,$dir,$paths) = @_;
    opendir (my $fh, $dir) or warn $!;
    return 0 unless $fh;
    my $gotone = 0;
    foreach my $f (readdir($fh)) {
	next if $f eq '.' or $f eq '..';
	if (-d "$dir/$f") {
	    push @$paths, $f;
	    $gotone |= $self->scan($pars,"$dir/$f",$paths);
	    pop @$paths;
	}
	elsif (-f "$dir/$f") {
	    if (my $obj = XDG::Menu::DesktopDirectory->new("$dir/$f")) {
		my $id = join('/',@$paths,$f);
		$obj->{id} = $id;
		 #$pars->{menus}[0]{dirs}{$id} = $obj;
		$self->{dirs}{$id} = $obj;
		$gotone = 1;
	    }
	}
    }
    close($fh);
    return $gotone;
}

#package XDG::Menu::DirectoryDir;
sub resolve {
    my ($self,$pars) = @_;
    # on the way down assign all of our {dirs} to the current menu
    if ($self->{dirs}) {
	my $menu = $pars->{menus}[0];
	foreach (keys %{$self->{dirs}}) {
	    $menu->{dirs}{$_} = delete $self->{dirs}{$_};
	}
    }
    $self->XDG::Menu::Element::resolve($pars);
}

package XDG::Menu::DefaultDirectoryDirs;
use base qw(XDG::Menu::NoData);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    foreach (reverse @{$pars->{XDG_DIRECTORY_DIRS}}) {
	next unless $_;
	my $obj = XDG::Menu::DirectoryDir->beg($pars,{});
	#unshift @{$pars->{stack}}, $obj;
	$obj->content($pars,$_);
	#shift @{$pars->{stack}};
	$obj->end($pars);
    }
}

package XDG::Menu::Name;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    # just set the name on the parent;
    my $name = $self->{Data}; $name =~ s{/}{_}g;
    $pars->{menus}[0]{Name} = $name;
}

package XDG::Menu::Directory;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    push @{$pars->{menus}[0]{Directories}}, $self;
}

sub resolve {
    my ($self,$pars) = @_;
    my $dent = $self->{Data};
    my $menu = $pars->{menus}[0];
    foreach my $level (@{$pars->{menus}}) {
	if (my $dir = $level->{dirs}{$dent}) {
	    die "$dir has no Name" unless $dir->{Name};
	    $menu->{Directory} = $dir;
	    last;
	}
    }
    # XDG:Directory does not need to nest
}

package XDG::Menu::OnlyUnallocated;
use base qw(XDG::Menu::NoData);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    $pars->{menus}[0]{OnlyUnallocated} = 'true';
     #$self->XDG::Menu::Element::end($pars);
}

package XDG::Menu::NotOnlyUnallocated;
use base qw(XDG::Menu::NoData);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    $pars->{menus}[0]{OnlyUnallocated} = 'false';
     #$self->XDG::Menu::Element::end($pars);
}

package XDG::Menu::Deleted;
use base qw(XDG::Menu::NoData);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    $pars->{menus}[0]{Deleted} = 'true';
    $self->XDG::Menu::Element::end($pars);
}

package XDG::Menu::NotDeleted;
use base qw(XDG::Menu::NoData);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    $pars->{menus}[0]{Deleted} = 'false';
    $self->XDG::Menu::Element::end($pars);
}

package XDG::Menu::Include;
use base qw(XDG::Menu::Rule XDG::Menu::NoData);
use strict;
use warnings;

sub resolve {
    my ($self,$pars) = @_;
    # mark the rule on the way down
    my $menu = $pars->{menus}[0];
    my $unalloc = 0; $unalloc = 1 if $menu->{OnlyUnallocated};
    unshift @{$menu->{rules}}, sub {
	# takes an XDG::Menu::DesktopApplication reference and a match result
	my ($app, $result) = @_;
	if ($result) {
	    return if $unalloc and $app->{Allocated};
	    $menu->{Applications}{$app->{id}} = $app;
	    $app->{Allocated} = 'true';
	}
    };
    $self->XDG::Menu::Element::resolve($pars);
    shift @{$menu->{rules}};
}

package XDG::Menu::Exclude;
use base qw(XDG::Menu::Rule XDG::Menu::NoData);
use strict;
use warnings;

sub resolve {
    my ($self,$pars) = @_;
    # mark the operation on the way down
    my $menu = $pars->{menus}[0];
    unshift @{$menu->{rules}}, sub {
	# takes an XDG::Menu::DesktopApplication reference and a match result
	my ($app, $result) = @_;
	if ($result) {
	    delete $menu->{Applications}{$app->{id}};
	}
    };
    $self->XDG::Menu::Element::resolve($pars);
    shift @{$menu->{reuls}};
}

package XDG::Menu::Filename;
use base qw(XDG::Menu::Rule XDG::Menu::Element);
use strict;
use warnings;

sub resolve {
    my ($self,$pars) = @_;
    my $menu = $pars->{menus}[0];
    my $sub = $menu->{rules}[0];
    my $id = $self->{Data};
    if ($menu->{apps}) {
	foreach my $app (values %{$menu->{apps}}) {
	    my $result = 0;
	    $result = 1 if $app->{id} eq $id;
	    &$sub($app,$result);
	}
    }
}

package XDG::Menu::Category;
use base qw(XDG::Menu::Rule XDG::Menu::Element);
use strict;
use warnings;

sub resolve {
    my ($self,$pars) = @_;
    my $menu = $pars->{menus}[0];
    my $sub = $menu->{rules}[0];
    if ($menu->{apps}) {
	my $cat = ";$self->{Data};";
	foreach my $app (values %{$menu->{apps}}) {
	    my $result = 0;
	    if ($app->{Categories}) {
		$result = 1 if ";$app->{Categories};" =~ /$cat/;
	    }
	    &$sub($app,$result);
	}
    }
}

package XDG::Menu::All;
use base qw(XDG::Menu::Rule XDG::Menu::Element);
use strict;
use warnings;

sub resolve {
    my ($self,$pars) = @_;
    my $menu = $pars->{menus}[0];
    my $sub = $menu->{rules}[0];
    if ($menu->{apps}) {
	foreach (values %{$menu->{apps}}) {
	    &$sub($_, 1);
	}
    }
}

package XDG::Menu::And;
use base qw(XDG::Menu::Rule XDG::Menu::NoData);
use strict;
use warnings;

sub resolve {
    my ($self, $pars) = @_;
    # mark the rule on the way down
    my $menu = $pars->{menus}[0];
    my %accum;
    unshift @{$menu->{rules}}, sub {
	# takes an XDG::Menu::DesktopApplication reference and a match result
	my ($app, $result) = @_;
	my $id = $app->{id};
	if (exists $accum{$id}) {
	    if ($accum{$id}[1] and $result) {
		$result = 1;
	    } else {
		$result = 0;
	    }
	}
	$accum{$id} = [ $app, $result ];
    };
    $self->XDG::Menu::Element::resolve($pars);
    shift @{$menu->{rules}};
    my $sub = $menu->{rules}[0];
    foreach (values %accum) { &$sub(@$_) }
}

package XDG::Menu::Or;
use base qw(XDG::Menu::Rule XDG::Menu::NoData);
use strict;
use warnings;

sub resolve {
    my ($self, $pars) = @_;
    # mark the rule on the way down
    my $menu = $pars->{menus}[0];
    my %accum;
    unshift @{$menu->{rules}}, sub {
	# takes an XDG::Menu::DesktopApplication reference and a match result
	my ($app, $result) = @_;
	my $id = $app->{id};
	if (exists $accum{$id}) {
	    if ($accum{$id}[1] or $result) {
		$result = 1;
	    } else {
		$result = 0;
	    }
	}
	$accum{$id} = [ $app, $result ];
    };
    $self->XDG::Menu::Element::resolve($pars);
    shift @{$menu->{rules}};
    my $sub = $menu->{rules}[0];
    foreach (values %accum) { &$sub(@$_) }
}

package XDG::Menu::Not;
use base qw(XDG::Menu::Rule XDG::Menu::NoData);
use strict;
use warnings;

sub resolve {
    my ($self, $pars) = @_;
    # mark the rule on the way down
    my $menu = $pars->{menus}[0];
    my %accum;
    unshift @{$menu->{rules}}, sub {
	# takes an XDG::Menu::DesktopApplication reference and a match result
	my ($app, $result) = @_;
	my $id = $app->{id};
	if (exists $accum{$id}) {
	    if ($accum{$id}[1] or $result) {
		$result = 1;
	    } else {
		$result = 0;
	    }
	}
	$accum{$id} = [ $app, $result ];
    };
    $self->XDG::Menu::Element::resolve($pars);
    shift @{$menu->{rules}};
    my $sub = $menu->{rules}[0];
    foreach (values %accum) {
	my ($app,$result) = @$_;
	if ($result) { $result = 0 } else { $result = 1 }
	&$sub($app,$result);
    }
}

package XDG::Menu::MergeFile; # type = "path|parent"
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub content {
    my ($self,$pars,$chars) = @_;
    my $path = $self->absolute($pars,$chars);
    if ($self->{type} and $self->{type} eq 'parent') {
	$path = undef;
	my $stem = '';
	my $file = $pars->{files}[0];
	foreach (@{$pars->{XDG_CONFIG_DIRS}}) {
	    next unless $_;
	    if ($stem eq '') {
		$stem = substr($file,length($_))
		    if $_ eq substr($file,0,length($_));
	    }
	    else {
		if (-f "$_/$stem") {
		    $path = "$_/$stem";
		    last;
		}
	    }
	}
    }
    $self->{path} = $path;
    $pars->watch_file($path);
}
sub end {
    my ($self,$pars) = @_;
    my $path = $self->{path};
    return unless $path;
    return if $pars->{menus}[0]{mrgs}{$path};
    $pars->{menus}[0]{mrgs}{$path} = $self;
    push @{$pars->{menus}[0]{MergeFiles}}, $self;
    if (-f $path) {
	 #warn "Nesting parsing into $path";
	 #$Data::Dumper::Maxdepth = 1;
	 #warn "stack is: ", Data::Dumper->Dump($pars->{stack});
	 #warn "menus is: ", Data::Dumper->Dump($pars->{menus});
	$pars->parse_uri($path);
    }
}

package XDG::Menu::MergeDir;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub content {
    my ($self,$pars,$chars) = @_;
    my $dir = $self->{path} = $self->absolute($pars,$chars);
    $pars->watch_directory($dir);
    unless ($dir and -d $dir) {
	#warn "$dir is not a directory";
	return;
    }
    $self->scan($pars,$dir,[]);
}
sub end {
    my ($self,$pars) = @_;
    push @{$pars->{menus}[0]{MergeDirs}}, $self;
}
sub scan {
    my ($self,$pars,$dir,$paths) = @_;
    my $gotone = 0;
    #warn "Reading MergeDir directory $dir...";
    opendir (my $fh, $dir) or warn $!;
    if ($fh) {
	foreach my $f (readdir($fh)) {
	    if (-f "$dir/$f") {
		next unless $f =~ /\.menu$/;
		my $id = "$dir/$f";
		my $obj = XDG::Menu::MergeFile->beg($pars,{});
		$obj->content($pars,"$dir/$f");
		$obj->end($pars);
		$gotone = 1;
	    }
	}
	close($fh);
    }
    return $gotone;
}

package XDG::Menu::DefaultMergeDirs;
use base qw(XDG::Menu::NoData);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    foreach (reverse @{$pars->{XDG_MERGED_DIRS}}) {
	next unless $_;
	my $obj = XDG::Menu::MergeDir->beg($pars,{});
	#unshift @{$pars->{stack}}, $obj;
	$obj->content($pars,$_);
	#shift @{$pars->{stack}};
	$obj->end($pars);
    }
}

package XDG::Menu::LegacyDir;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub content {
    my ($self,$pars,$chars) = @_;
    my $dir = $self->{path} = $self->absolute($pars,$chars);
    $pars->watch_directory($dir);
}
sub end {
    my ($self,$pars) = @_;
    XDG::Menu::Element::end(@_);
    my $dir = $self->{path};
    return unless $dir and -d $dir;
    $self->scan($pars,$dir);
}
sub scan {
    my ($self,$pars,$dir) = @_;
    my $obj = XDG::Menu::AppDir->beg($pars,{});
    #unshift @{$pars->{stack}}, $obj;
    $obj->content($pars,$dir);
    # need to add Legacy to Categories
    foreach (keys %{$obj->{apps}}) {
	if ($obj->{apps}{$_}{Categories}) {
	    $obj->{apps}{$_}{Categories} =
		join(';','Legacy',$obj->{apps}{$_}{Categories});
	}
	else {
	    $obj->{apps}{$_}{Categories} = 'Legacy;';
	}
    }
    #shift @{$pars->{stack}};
    $obj->end($pars);
    if (-d "$dir/.directory") {
	$obj = XDG::Menu::DirectoryDir->beg($pars,{});
	$obj->content($pars,$dir);
	$obj->end($pars);
	$obj = XDG::Menu::Directory->beg($pars,{});
	$obj->content($pars,'.directory');
	$obj->end($pars);
    }
    my $include = XDG::Menu::Include->beg($pars,{});
    $include->end($pars);
    if (opendir(my $fh, $dir)) {
	foreach my $f (readdir($fh)) {
	    next if $f eq '.' or $f eq '..';
	    if (-d "$dir/$f") {
		my $menu = XDG::Menu::Menu->beg($pars,{});
		unshift @{$pars->{stack}}, $menu;
		my $name = XDG::Menu::Name->beg($pars,{});
		$name->content($pars,$f);
		$name->end($pars);
		$self->scan($pars,"$dir/$f");
		shift @{$pars->{stack}};
		$menu->end($pars);
	    }
	    elsif (-f "$dir/$f") {
		next unless $f =~ /\.desktop$/;
		unshift @{$pars->{stack}}, $include;
		my $file = XDG::Menu::Filename->beg($pars,{});
		$file->content($pars,$f);
		$file->end($pars);
		shift @{$pars->{stack}};
	    }
	}
    }
}

package XDG::Menu::KDELegacyDirs;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

package XDG::Menu::Move;
use base qw(XDG::Menu::NoData);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    push @{$pars->{menus}[0]{Moves}}, $self;
}

package XDG::Menu::Old;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub characters {
    my ($self,$pars,$chars) = @_;
    $self->{RelativePath} = $chars;
    $self->{AbsolutePath} = join('/',map{$_->{Name}}reverse(@{$pars->{menus}}), $chars);
}

# XXX: maybe this should be done in XDG::Menu::Menu::end
sub resolve {
    my ($self,$pars) = @_;
    # just mark the old absolute path on the XDG::Menu::Move object
    $pars->{stack}[0]{Old} = $self->{AbsolutePath};
}

package XDG::Menu::New;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub characters {
    my ($self,$pars,$chars) = @_;
    $self->{RelativePath} = $chars;
    $self->{AbsolutePath} = join('/',map{$_->{Name}}reverse(@{$pars->{menus}}), $chars);
}

# XXX: maybe this should be done in XDG::Menu::Menu::end
sub resolve {
    my ($self,$pars) = @_;
    if (my $old = delete $pars->{stack}[0]{Old}) {
	my $new = $self->{AbsolutePath};
	# move it
	if (my $menu = delete $pars->{Menus}{$old}) {
	    $menu->{Path} = $new;
	    $pars->{Menus}{$new} = $menu;
	}
    }
}

package XDG::Menu::Layout;
use base qw(XDG::Menu::NoData);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    push @{$pars->{menus}[0]{Layouts}}, $self;
}

sub layout {
    my ($self,$pars) = @_;
    # one the way down have to determine which Menuname elements mention
    # directories in advance
    if ($self->{Contains}) {
	foreach (@{$self->{Contains}}) {
	    if ($_->isa('XDG::Menu::Menuname')) {
		$self->{Mentioned}{$_->{Data}} = $_;
	    }
	}
    }
    $self->XDG::Menu::Element::layout($pars);
    delete $self->{Mentioned};
}

package XDG::Menu::DefaultLayout; # lots of attrs
use base qw(XDG::Menu::NoData);
use strict;
use warnings;

sub end {
    my ($self,$pars) = @_;
    push @{$pars->{menus}[0]{DefaultLayouts}}, $self;
}

package XDG::Menu::Menuname; # lots of attrs
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub beg {
    my ($type,$pars,$data) = @_;
    my $self = XDG::Menu::Element::beg(@_);
    $self->{show_empty} = 'false' unless exists $self->{show_empty};
    $self->{inline} = 'false' unless exists $self->{inline};
    $self->{inline_limit} = 4 unless exists $self->{inline_limit};
    $self->{inline_header} = 'true' unless exists $self->{inline_header};
    $self->{inline_alias} = 'false' unless exists $self->{inline_alias};
    return $self;
}

sub layout {
    my ($self,$pars) = @_;
    my $path = join('/',map {$_->{Name}} reverse @{$pars->{menus}}).'/'.$self->{Data};
    if (my $dent = $pars->{Menus}{$path}) {
	my $menu = $pars->{menus}[0];
	push @{$menu->{Elements}}, XDG::Menu::Layout::Directory->new($dent);
    }
}

package XDG::Menu::Separator;
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub layout {
    my ($self,$pars) = @_;
    my $menu = $pars->{menus}[0];
    # can't go at top
    if ($menu->{Elements}) {
	push @{$menu->{Elements}}, XDG::Menu::Layout::Separator->new()
	    unless $menu->{Elements}[-1] and
	    $menu->{Elements}[-1]->isa('XDG::Menu::Layout::Separator');
    }
}

package XDG::Menu::Merge; # type = "menus|files|all"
use base qw(XDG::Menu::Element);
use strict;
use warnings;

sub layout {
    my ($self,$pars) = @_;
    my $menu = $pars->{menus}[0];
    my $layout = $pars->{stack}[1];
    if ($self->{type} and $self->{type} eq 'menus') {
	if ($menu->{Submenus}) {
	    my @directories = map {$layout->{Mentioned}{$_->{Name}}?():XDG::Menu::Layout::Directory->new($_)} @{$menu->{Submenus}};
	    push @{$menu->{Elements}}, sort {$a->{Name} cmp $b->{Name}} @directories;
	}
    }
    elsif ($self->{type} and $self->{type} eq 'files') {
	if ($menu->{Applications}) {
	    my @applications = map {XDG::Menu::Layout::Application->new($_)} values %{$menu->{Applications}};
	    push @{$menu->{Elements}}, sort {$a->{Name} cmp $b->{Name}} @applications;
	}
    }
    else { # all
	my @directories = map {$layout->{Mentioned}{$_->{Name}}?():XDG::Menu::Layout::Directory->new($_)} @{$menu->{Submenus}} if $menu->{Submenus};
	my @applications = map {XDG::Menu::Layout::Application->new($_)} values %{$menu->{Applications}} if $menu->{Applications};
	push @{$menu->{Elements}}, sort {$a->{Name} cmp $b->{Name}} (@applications, @directories);
    }
}

1;
