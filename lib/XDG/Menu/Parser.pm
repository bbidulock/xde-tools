package XDG::Menu::Parser;
use base qw(XML::SAX::Base);
use XML::SAX::ParserFactory;
use XDG::Menu;
use strict;
use warnings;

#package XDG::Menu::Parser;
sub new {
    my ($type,$file) = @_;
    my $self = XML::SAX::Base::new($type);
    my $root = $self->{root} = bless {Name=>'Applications'}, "XDG::Menu::Menu";
    $self->{stack} = [$root];
    $self->{menus} = [$root];
    $self->{Menus} = {};
    $self->{Paths} = {};
    my $HOME = $ENV{HOME} if $ENV{HOME};
    $HOME = '~' unless $HOME;
    my $XDG_CONFIG_HOME = $ENV{XDG_CONFIG_HOME} if $ENV{XDG_CONFIG_HOME};
    $XDG_CONFIG_HOME = "$HOME/.config" unless $XDG_CONFIG_HOME;
    my $XDG_CONFIG_DIRS = $ENV{XDG_CONFIG_DIRS} if $ENV{XDG_CONFIG_DIRS};
    $XDG_CONFIG_DIRS = "/etc/xdg" unless $XDG_CONFIG_DIRS;
    my $XDG_DATA_HOME = $ENV{XDG_DATA_HOME} if $ENV{XDG_DATA_HOME};
    $XDG_DATA_HOME = "$HOME/.local/share" unless $XDG_DATA_HOME;
    my $XDG_DATA_DIRS = $ENV{XDG_DATA_DIRS} if $ENV{XDG_DATA_DIRS};
    $XDG_DATA_DIRS = "/usr/local/share:/usr/share" unless $XDG_DATA_DIRS;
    my @XDG_DATA_DIRS   = ( $XDG_DATA_HOME,   split(/:/,$XDG_DATA_DIRS)   );
    my @XDG_CONFIG_DIRS = ( $XDG_CONFIG_HOME, split(/:/,$XDG_CONFIG_DIRS) );
    my $XDG_MENU = 'applications';
    my @XDG_MERGED_DIRS = map{$_?"$_/menus/${XDG_MENU}-merged":()} @XDG_CONFIG_DIRS;
    my @XDG_APPLICATIONS_DIRS = (
	    (map {$_?"$_/dockapps":()} @XDG_DATA_DIRS),
	    (map {$_?"$_/applications":()} @XDG_DATA_DIRS),
	    (map {$_?"$_/fallback":()} @XDG_DATA_DIRS) );
    my @XDG_DIRECTORY_DIRS = map{$_?"$_/desktop-directories":()} @XDG_DATA_DIRS;
    my $XDG_CURRENT_DESKTOP = $ENV{XDG_CURRENT_DESKTOP};
    $XDG_CURRENT_DESKTOP = 'FLUXBOX' unless $XDG_CURRENT_DESKTOP;
    $self->{XDG_DATA_DIRS} = \@XDG_DATA_DIRS;
    $self->{XDG_CONFIG_DIRS} = \@XDG_CONFIG_DIRS;
    $self->{XDG_MERGED_DIRS} = \@XDG_MERGED_DIRS;
    $self->{XDG_APPLICATIONS_DIRS} = \@XDG_APPLICATIONS_DIRS;
    $self->{XDG_DIRECTORY_DIRS} = \@XDG_DIRECTORY_DIRS;
    $self->{XDG_CURRENT_DESKTOP} = $XDG_CURRENT_DESKTOP;
    return $self;
}

#package XDG::Menu::Parser;
sub start_document {
    my ($self) = @_;
    $self->{starting} = 1;
}

#package XDG::Menu::Parser;
sub end_document {
    my ($self) = @_;
    return $self->{root};
}

#package XDG::Menu::Parser;
sub parse_uri {
    my ($self,$file) = @_;
    unless (-f $file) {
	#warn "Menu file $file does not exist";
	return;
    }
    unshift @{$self->{files}}, $file;
    XML::SAX::ParserFactory->parser(Handler=>$self)->parse_uri($file);
    shift @{$self->{files}};
    return $self->{root};
}
#package XDG::Menu::Parser;
sub parse_menu {
    my ($self,$file) = @_;
    my $root = $self->{root};
    $self->parse_uri($file);
    $root->resolve($self);
    $root->layout($self);
    $root->cleanup($self);
    return $root;
}
#package XDG::Menu::Parser;
sub start_element {
    my ($self,$data) = @_;
    my $obj;
    my $type = "XDG\::Menu\::$data->{Name}";
    if ($type->can('beg')) {
	$obj = $type->beg($self,$data);
    }
    else {
	warn "Unrecognized element <$data->{Name}>";
	$obj = XDG::Menu::Element->beg($self,$data);
    }
    unshift @{$self->{stack}}, $obj;
}
#package XDG::Menu::Parser;
sub characters {
    my ($self,$data) = @_;
    my $object = $self->{stack}[0];
    $object->content($self,$data->{Data});
}
#package XDG::Menu::Parser;
sub end_element {
    my $self = shift;
    my $object = shift @{$self->{stack}};
    $object->end($self);
}
#package XDG::Menu::Parser;
sub watch_directory {
    my ($self,$path) = @_;
    $self->{Paths}{$path}++;
}
#package XDG::Menu::Parser;
sub watch_file {
    my ($self,$file) = @_;
    my $path = $file; $path =~ s{/[^/]*$}{};
    $self->watch_directory($path);
}
#package XDG::Menu::Parser;
sub print_directories {
    my $self = shift;
    if ($self->{Paths}) {
	foreach (sort keys %{$self->{Paths}}) {
	    printf "%6d %s\n", $self->{Paths}{$_}, $_;
	}
    }
}

1;
