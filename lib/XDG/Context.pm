package XDG::Context;
use File::Path;
use Encode;
use I18N::Langinfo qw(langinfo CODESET);
use POSIX qw(locale_h);
use strict;
use warnings;

use constant {
    MYENV => [qw(
	XDG_CONFIG_HOME
	XDG_CONFIG_DIRS
	XDG_DATA_HOME
	XDG_DATA_DIRS
	XDG_VENDOR_ID
	XDG_MENU_PREFIX
	XDG_CURRENT_DESKTOP
    )],
    MYPATH => [qw(
	XDG_CONFIG_HOME
	XDG_CONFIG_PREPEND
	XDG_CONFIG_DIRS
	XDG_CONFIG_APPEND
	XDG_DATA_HOME
	XDG_DATA_PREPEND
	XDG_DATA_DIRS
	XDG_DATA_APPEND
	XDG_ICON_HOME
	XDG_ICON_PREPEND
	XDG_ICON_DIRS
	XDG_ICON_APPEND
    )],
};
sub new {
    my $self = bless {}, shift;
    return $self->setup(@_);
}
sub setup {
    my $self = shift;
    my $setup = shift;
    if (defined $setup and ref($setup) and ref($setup) =~ /HASH/) {
	foreach (keys %$setup) {
	    $self->{$_} = $setup->{$_};
	}
    }
    $self->default;
    return $self;
}
sub default {
    my $self = shift;

    $self->{HOME} = $ENV{HOME} unless $self->{HOME};
    $self->{XDG_CONFIG_LEGACY} = undef unless $self->{XDG_CONFIG_LEGACY};
    $self->{XDG_CONFIG_HOME} = "$self->{HOME}/.config" unless $self->{XDG_CONFIG_HOME};
    $self->{XDG_CONFIG_PREPEND} = undef unless $self->{XDG_CONFIG_PREPEND};
    $self->{XDG_CONFIG_DIRS} = '/etc/xdg' unless $self->{XDG_CONFIG_DIRS};
    $self->{XDG_CONFIG_APPEND} = undef unless $self->{XDG_CONFIG_APPEND};
    $self->{XDG_CONFIG_FALLBACK} = undef unless $self->{XDG_CONFIG_FALLBACK};
    $self->{XDG_DATA_LEGACY} = undef unless $self->{XDG_DATA_LEGACY};
    $self->{XDG_DATA_HOME} = "$self->{HOME}/.local/share" unless $self->{XDG_DATA_HOME};
    $self->{XDG_DATA_PREPEND} = undef unless $self->{XDG_DATA_PREPEND};
    $self->{XDG_DATA_DIRS} = '/usr/local/share:/usr/share' unless $self->{XDG_DATA_DIRS};
    $self->{XDG_DATA_APPEND} = undef unless $self->{XDG_DATA_APPEND};
    $self->{XDG_DATA_FALLBACK} = undef unless $self->{XDG_DATA_FALLBACK};
    $self->{XDG_ICON_LEGACY} = "$self->{HOME}/.icons" unless $self->{XDG_ICON_LEGACY};
    $self->{XDG_ICON_HOME} = "$self->{XDG_DATA_HOME}/icons";
    $self->{XDG_ICON_PREPEND} = undef unless $self->{XDG_ICON_PREPEND};
    $self->{XDG_ICON_DIRS} = join(':',map {"$_/icons"} split(/:/,$self->{XDG_DATA_DIRS}));
    $self->{XDG_ICON_APPEND} = undef unless $self->{XDG_ICON_APPEND};
    $self->{XDG_ICON_FALLBACK} = '/usr/share/pixmaps' unless $self->{XDG_ICON_FALLBACK};
    if ($self->{XDG_MENU_PREFIX} and not $self->{XDG_VENDOR_ID}) {
	$self->{XDG_VENDOR_ID} = $self->{XDG_MENU_PREFIX};
	$self->{XDG_VENDOR_ID} =~ s{-$}{};
    }
    elsif ($self->{XDG_VENDOR_ID} and not $self->{XDG_MENU_PREFIX}) {
	$self->{XDG_MENU_PREFIX} = "$self->{XDG_VENDOR_ID}-";
    }
    $self->{XDG_VENDOR_ID} = '' unless $self->{XDG_VENDOR_ID};
    $self->{XDG_MENU_PREFIX} = '' unless $self->{XDG_MENU_PREFIX};
    $self->{XDG_CURRENT_DESKTOP} = '' unless $self->{XDG_CURRENT_DESKTOP};
    $self->{XDG_CURRENT_DESKTOP} = "\U$self->{XDG_CURRENT_DESKTOP}\E" if $self->{XDG_CURRENT_DESKTOP};
    foreach my $var (@{&MYPATH}) {
	    $self->{$var} =~ s(~)($self->{HOME})g if $self->{$var};
    }
    foreach (qw(XDG_CONFIG XDG_DATA XDG_ICON)) {
	    $self->update_array($_);
    }
    $self->{language} = setlocale(LC_MESSAGES) unless $self->{language};
    $self->{charset} = langinfo(CODESET) unless $self->{charset};
    unless ($self->{lang}) {
	$self->{lang} = $self->{language};
	$self->{lang} =~ s{\..*$}{};
    }
    return $self;
}
sub getenv {
    my $self = shift;
    foreach my $var (@{&MYENV}) { $self->{$var} = $ENV{$var} }
    $self->default;
    return $self;
}
sub setenv {
    my $self = shift;
    foreach my $var (@{&MYENV}) {
	delete $ENV{$var};
	my $val = $self->{$var};
	my $base = $var;
	if ($base =~ s{_DIRS$}{}) {
	    # collapse APPEND and PREPEND into DIRS value
	    $val = join(':',
		    $self->{"${base}_PREPEND"} ? split(/:/,$self->{"${base}_PREPEND"}) : (),
		    $self->{"${base}_DIRS"}    ? split(/:/,$self->{"${base}_DIRS"}   ) : (),
		    $self->{"${base}_APPEND"}  ? split(/:/,$self->{"${base}_APPEND"} ) : (),
	    );
	}
	$ENV{$var} = $val if $val;
    }
    return $self;
}

sub update_array {
    my $self = shift;
    my $base = shift;
    # collapse PREPEND and APPEND into DIRS
    if (my $dirs = $self->{"${base}_DIRS"}) {
	if (my $prepend = $self->{"${base}_PREPEND"}) {
	    if (length($dirs) >= length($prepend)) {
		if (substr($dirs,0,length($prepend)) eq $prepend) {
		    $self->{"${base}_PREPEND"} = undef;
		}
	    }
	}
	if (my $append = $self->{"${base}_APPEND"}) {
	    if (length($dirs) >= length($append)) {
		if (substr($dirs,length($dirs)-length($append),length($append)) eq $append) {
		    $self->{"${base}_APPEND"} = undef;
		}
	    }
	}
    }
    $self->{"${base}_ARRAY"} = [];
    foreach my $part (qw(LEGACY HOME PREPEND DIRS APPEND FALLBACK)) {
	push @{$self->{"${base}_ARRAY"}},
	    split(/:/,$self->{"${base}_${part}"})
		if $self->{"${base}_${part}"};
    }
}
sub get_or_set {
    my $self = shift;
    my $name = shift;
    my $base = $name;
    $base =~ s{_(LEGACY|HOME|PREPEND|DIRS|APPEND|FALLBACK|ARRAY)$}{};
    if (@_) {
	if ($name =~ m{_ARRAY$}) {
	    $self->{$name} = [ @_ ];
	}
	elsif ($name =~ m{_DIRS$}) {
	    $self->{$name} = join(':',@_);
	}
	else {
	    $self->{$name} = shift;
	}
	$self->update_array($base) unless $base eq $name;
    }
    return $self->{$name} unless wantarray and "${base}_ARRAY" eq $name;
    $self->{"${base}_ARRAY"} = [] unless $self->{"${base}_ARRAY"};
    return @{$self->{"${base}_ARRAY"}};
}

sub HOME                { return shift->get_or_set(HOME               =>@_) }
sub XDG_CONFIG_HOME     { return shift->get_or_set(XDG_CONFIG_HOME    =>@_) }
sub XDG_CONFIG_LEGACY   { return shift->get_or_set(XDG_CONFIG_LEGACY  =>@_) }
sub XDG_CONFIG_PREPEND  { return shift->get_or_set(XDG_CONFIG_PREPEND =>@_) }
sub XDG_CONFIG_DIRS     { return shift->get_or_set(XDG_CONFIG_DIRS    =>@_) }
sub XDG_CONFIG_APPEND   { return shift->get_or_set(XDG_CONFIG_APPEND  =>@_) }
sub XDG_CONFIG_FALLBACK { return shift->get_or_set(XDG_CONFIG_FALLBACK=>@_) }
sub XDG_CONFIG_ARRAY    { return shift->get_or_set(XDG_CONFIG_ARRAY   =>@_) }
sub XDG_DATA_LEGACY     { return shift->get_or_set(XDG_DATA_LEGACY    =>@_) }
sub XDG_DATA_HOME       { return shift->get_or_set(XDG_DATA_HOME      =>@_) }
sub XDG_DATA_PREPEND    { return shift->get_or_set(XDG_DATA_PREPEND   =>@_) }
sub XDG_DATA_DIRS       { return shift->get_or_set(XDG_DATA_DIRS      =>@_) }
sub XDG_DATA_APPEND     { return shift->get_or_set(XDG_DATA_APPEND    =>@_) }
sub XDG_ICON_LEGACY     { return shift->get_or_set(XDG_ICON_LEGACY    =>@_) }
sub XDG_DATA_FALLBACK   { return shift->get_or_set(XDG_DATA_FALLBACK  =>@_) }
sub XDG_DATA_ARRAY      { return shift->get_or_set(XDG_DATA_ARRAY     =>@_) }
sub XDG_ICON_HOME       { return shift->get_or_set(XDG_ICON_HOME      =>@_) }
sub XDG_ICON_PREPEND    { return shift->get_or_set(XDG_ICON_PREPEND   =>@_) }
sub XDG_ICON_DIRS       { return shift->get_or_set(XDG_ICON_DIRS      =>@_) }
sub XDG_ICON_APPEND     { return shift->get_or_set(XDG_ICON_APPEND    =>@_) }
sub XDG_ICON_FALLBACK   { return shift->get_or_set(XDG_ICON_FALLBACK  =>@_) }
sub XDG_ICON_ARRAY      { return shift->get_or_set(XDG_ICON_ARRAY     =>@_) }
sub XDG_VENDOR_ID       { return shift->get_or_set(XDG_VENDOR_ID      =>@_) }
sub XDG_CURRENT_DESKTOP { return shift->get_or_set(XDG_CURRENT_DESKTOP=>@_) }
sub XDG_MENU_PREFIX	{ return shift->get_or_set(XDG_MENU_PREFIX    =>@_) }

sub set_vendor {
    my $self = shift;
    my $vendor = shift;
    if ($vendor) {
	$vendor = "\L$vendor\E";
	$self->setup({
	    XDG_VENDOR_ID   => "${vendor}",
	    XDG_MENU_PREFIX => "${vendor}-",
	});
    }
    return $vendor;
}

sub get_xsessions {
    my $self = shift;
    my %files;
    foreach my $d (reverse map {"$_/xsessions"} @{$self->{XDG_DATA_ARRAY}}) {
        opendir(my $dir, "$d") or next;
        foreach my $f (readdir($dir)) {
            next unless -f "$d/$f" and $f =~ /\.desktop$/;
            open (my $fh, "<", "$d/$f") or next;
            my $parsing = 0;
            my %e = (file=>"$d/$f");
            my %xl = ();
            while (<$fh>) {
                if (/^\[([^]]*)\]/) {
                    my $section = $1;
                    if ($section eq 'Desktop Entry' or $section eq 'Window Manager') {
                        $parsing = 1;
                    } else {
                        $parsing = 0;
                    }
                }
                elsif ($parsing and /^([^=\[]+)\[([^=\]]+)\]=([^[:cntrl:]]*)/) {
                    $xl{$1}{$2} = $3;
                }
                elsif ($parsing and /^([^=]*)=([^[:cntrl:]]*)/) {
                    $e{$1} = $2 unless exists $e{$1};
                }
            }
            close($fh);
            $self->{lang} =~ m{^(..)}; my $short = $1;
            foreach (keys %xl) {
                if (exists $xl{$_}{$self->{lang}}) {
                    $e{$_} = $xl{$_}{$self->{lang}};
                }
                elsif (exists $xl{$_}{$short}) {
                    $e{$_} = $xl{$_}{$short};
                }
            }
            $e{Name} = '' unless $e{Name};
            $e{Exec} = '' unless $e{Exec};
            $e{SessionManaged} = 'false' unless $e{SessionManaged};
            $e{Comment} = $e{Name} unless $e{Comment};
            $e{Label} = "\L$e{Name}\E" unless $e{Label};
            $files{$f} = \%e;
        }
        close($dir);
    }
    my %sessions;
    foreach (values %files) {
        $sessions{$_->{Label}} = $_;
    }
    undef %files;
    # Get rid of those that are not to be displayed.
    my @todelete = ();
    foreach my $s (keys %sessions) {
        my $e = $sessions{$s};
        unless ($e->{Name}) {
            print STDERR "$s has no Name!\n"
                if $self->{verbose};
            push @todelete, $s;
            next;
        }
        unless ($e->{Exec}) {
            print STDERR "$s ($e->{Name}): has no Exec!\n"
                if $self->{verbose};
            push @todelete, $s;
            next;
        }
        if ($e->{Hidden} and $e->{Hidden} =~ m{true|yes}i) {
            print STDERR "$s ($e->{Name}) is Hidden!\n"
                if $self->{verbose};
            push @todelete, $s;
            next;
        }
        if ($e->{NoDisplay} and $e->{NoDisplay} =~ m{true|yes}i) {
            print STDERR "$s ($e->{Name}) is NoDisplay!\n"
                if $self->{verbose};
            push @todelete, $s;
            next;
        }
        unless ($e->{TryExec}) {
            my @words = split(/\s+/,$e->{Exec});
            $e->{TryExec} = $words[0];
        }
        if (my $x = $e->{TryExec}) {
            if ($x =~ m{/}) {
                unless (-x "$x") {
                    print STDERR "$s ($e->{Name}) $x is not executable!\n"
                        if $self->{verbose};
                    push @todelete, $s;
                    next;
                }
            }
            else {
                my @PATH = split(/:/,$ENV{PATH});
                my $found = 0;
                foreach (@PATH) {
                    if (-x "$_/$x") {
                        $found = 1;
                        last;
                    }
                }
                unless ($found) {
                    print STDERR "$s ($e->{Name}) $x is not executable!\n"
                        if $self->{verbose};
                    push @todelete, $s;
                    next;
                }
            }
        }
    }
    foreach (@todelete) {
        print STDERR "Deleting $_ ($sessions{$_}->{Name})\n"
            if $self->{verbose};
        delete $sessions{$_};
    }
    return \%sessions;
}

sub mkdirs {
    my $self = shift;
    foreach (qw(XDG_CONFIG_HOME XDG_DATA_HOME)) {
	if (my $dir = $self->{$_}) {
	    eval { mkpath $dir; } unless -d $dir;
	}
    }
}

1;

