package XDG::Context;
use File::Path;
use Encode;
use I18N::Langinfo qw(langinfo CODESET);
use POSIX qw(locale_h);
use strict;
use warnings;

=head1 NAME

XDG::Context -- establish an XDG environment context

=head1 SYNOPSIS

 use XDG::Context;

 my $xdg = new XDG::Context %OVERRIDES;
 $xdg->getenv();

 use Getopt::Long;

 GetOptions($xdg->{ops},
    'language|l=s',
    'charset|c=s',
 ) or die "bad option";

 print "XDG config home directory is ",
    $xdg->{XDG_CONFIG_HOME}, "\n";

 $xdg->setenv();

=head1 DESCRIPTION

XDG::Context provides a collection of the XDG context as gleened from
environment variables with overrides specified on creation.  It is able
to provide lists of directories of a type.  This modules tracks the XDG
configuration directories B<XDG_CONFIG_*>, data directories
B<XDG_DATA_*>, icon directories B<XDG_ICON_*> and maybe soon sound
directories B<XDG_SOUND_*>.

=cut

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
	XDG_CONFIG_LEGACY
	XDG_CONFIG_PREPEND
	XDG_CONFIG_DIRS
	XDG_CONFIG_APPEND
	XDG_CONFIG_FALLBACK
	XDG_DATA_HOME
	XDG_DATA_LEGACY
	XDG_DATA_PREPEND
	XDG_DATA_DIRS
	XDG_DATA_APPEND
	XDG_DATA_FALLBACK
	XDG_ICON_HOME
	XDG_ICON_LEGACY
	XDG_ICON_PREPEND
	XDG_ICON_DIRS
	XDG_ICON_APPEND
	XDG_ICON_FALLBACK
    )],
};

=head1 METHODS

=over

=item $xdg = B<new> XDG::Context I<%OVERRIDES> => bless HASHREF

This method establishes a blessed hash reference of whatever type was
passed to the method and calls the B<setup> method.  The default
B<setup> method establishes I<%OVERRIDES> and defaults.  It is
up to the caller to caller or derived class to call the B<getenv> or
B<setenv> methods to read or write values from or to the environment.
An options hash reference with default values (considering overrides)
will be available in C<$xdg-E<gt>{ops}>.

See L</OVERRIDES> for details on the I<%OVERRIDES> interpreted by this
module.
See L</OPTIONS> for details on the I<%ops> interpreted by this module.

=cut

sub new {
    my $self =  bless {}, shift;
    return $self->setup(@_);
}

=item $xdg->B<setup>(I<%OVERRIDES>) => $xdg

The default B<setup> method called by B<new>.  This can be overriden by
a derived class.  This default method establishes the I<%OVERRIDES>
specified to the B<new> methods and the C<$xdg->{ops}> options hash
reference.

This method can be called at any time (such as after calling B<getenv>)
to reapply overrides if necessary.

=cut

sub setup {
    print STDERR "Args are: ", join(',',@_), "\n"
	unless (scalar(@_)&0x1);
    my ($self,%OVERRIDES) = @_;
    foreach (keys %OVERRIDES) {
	if ($_ eq 'ops' and exists $self->{ops}) {
	    foreach my $k (keys %{$OVERRIDES{ops}}) {
		$self->{ops}{$k} = $OVERRIDES{ops}{$k};
	    }
	} else {
	    $self->{$_} = $OVERRIDES{$_};
	}
    }
    return $self;
}

=item $xdg->B<default>() => $xdg

Called internally to reset all default settings that were not overridden
or obtained from the environment.  This too can be overridden by a
derived module; however, it should call this method from the overridden
method to ensure that proper defaults are assigned to this module.

=cut

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
    $self->{XDG_VENDOR_ID} = $self->{ops}{vendor} unless $self->{XDG_VENDOR_ID} and not $self->{ops}{vendor};
    if ($self->{XDG_MENU_PREFIX} and not $self->{XDG_VENDOR_ID}) {
	$self->{XDG_VENDOR_ID} = $self->{XDG_MENU_PREFIX};
	$self->{XDG_VENDOR_ID} =~ s{-$}{};
    }
    elsif ($self->{XDG_VENDOR_ID}) {
	$self->{XDG_MENU_PREFIX} = "$self->{XDG_VENDOR_ID}-";
    }
    $self->{XDG_VENDOR_ID} = '' unless $self->{XDG_VENDOR_ID};
    $self->{XDG_MENU_PREFIX} = '' unless $self->{XDG_MENU_PREFIX};
    $self->{XDG_CURRENT_DESKTOP} = $self->{ops}{desktop};
    $self->{XDG_CURRENT_DESKTOP} = $self->{ops}{session} unless $self->{XDG_CURRENT_DESKTOP};
    $self->{XDG_CURRENT_DESKTOP} = '' unless $self->{XDG_CURRENT_DESKTOP};
    $self->{XDG_CURRENT_DESKTOP} = "\U$self->{XDG_CURRENT_DESKTOP}\E" if $self->{XDG_CURRENT_DESKTOP};
    foreach my $var (@{&MYPATH}) {
	    $self->{$var} =~ s(~)($self->{HOME})g if $self->{$var};
    }
    foreach (qw(XDG_CONFIG XDG_DATA XDG_ICON)) {
	    $self->update_array($_);
    }
    $self->{ops}{language} = setlocale(LC_MESSAGES) unless $self->{ops}{language};
    $self->{ops}{charset} = langinfo(CODESET) unless $self->{ops}{charset};
    unless ($self->{ops}{lang}) {
	$self->{ops}{lang} = $self->{ops}{language};
	$self->{ops}{lang} =~ s{\..*$}{};
    }
    $self->{ops}{vendor} = $self->{XDG_VENDOR_ID}
	unless $self->{ops}{vendor};
    $self->{ops}{desktop} = $self->{XDG_CURRENT_DESKTOP}
	unless $self->{ops}{desktop};
    return $self;
}

=item $xdg->B<getenv>() => $xdg

Reads pertinent environment variables and then resets defaults in
accordance with the environment variables read.  Environment variables
read by this module are: B<XDG_CONFIG_HOME>, B<XDG_CONFIG_DIRS>,
B<XDG_DATA_HOME>, B<XDG_DATA_DIRS>, B<XDG_VENDOR_ID>, B<XDG_MENU_PREFIX>
and B<XDG_CURRENT_DESKTOP>.

This method can be overridden by a derived module to read supplemental
environment variables.

=cut

sub getenv {
    my $self = shift;
    foreach my $var (@{&MYENV}) {
        $self->{$var} = $ENV{$var}
    }
    $self->default;
    return $self;
}

=item $xdg->B<setenv>() => $xdg

Writes pertinent environment variables to the environment.  This method
can be overridden by a derived module to write supplemental environment
variables.

=cut

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

=item $xdg->B<mkdirs>()

Creates necessary directories (normally in the user's C<$HOME>
directory).  This method may be overridden by a derived module to create
supplemental directories.

=cut

sub mkdirs {
    my $self = shift;
    foreach (qw(XDG_CONFIG_HOME XDG_DATA_HOME)) {
	if (my $dir = $self->{$_}) {
	    eval { mkpath $dir; } unless -d $dir;
	}
    }
}

=item $xdg->B<update_array>($base)

An internal method to update the internal B<XDG_*_ARRAY> fields which
contains a complete array of B<_LEGACY>, B<_HOME>, B<_PREPEND>, B<_DIRS>,
B<_APPEND> and B<_FALLBACK> directories for B<XDG_CONFIG_*>,
B<XDG_DATA_*> and B<XDG_ICON_*>.  It can be used by derived modules that
pass it the C<XDG_DATA> portion of the the string (for example).

=cut

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


sub show_options {
    my $self = shift;
    my %ops = %{$self->{ops}};
    if ($ops{verbose}) {
	print STDERR "Option settings:\n";
	foreach (sort keys %ops) {
	    next unless defined $ops{$_};
	    my $val = $ops{$_};
	    $val = join(',',@$val) if ref($val) eq 'ARRAY';
	    printf STDERR "\t%-20s: '%s'\n", $_, $val;
	}
    }
}

sub show_variables {
    my $self = shift;
    if ($self->{ops}{verbose}) {
	print STDERR "Current settings:\n";
	foreach (sort keys %$self) {
	    next unless m{^XD} and defined $self->{$_};
	    my $val = $self->{$_};
	    $val = join(':',@$val) if ref($val) eq 'ARRAY';
	    printf STDERR "\t%-20s: '%s'\n", $_, $val;
	}
    }
}

sub show_settings {
    my $self = shift;
    if ($self->{ops}{verbose}) {
	$self->show_variables;
	$self->show_options;
    }
}

=item $xdg->B<set_vendor>($vendor) => $vendor

Used to set the I<$vendor> string for setting the B<XDG_VENDOR_ID> and
B<XDG_MENU_PREFIX> variables.

=cut

sub set_vendor {
    my $self = shift;
    my $vendor = shift;
    if ($vendor) {
	$vendor = "\L$vendor\E";
	$self->setup(
	    XDG_VENDOR_ID   => "${vendor}",
	    XDG_MENU_PREFIX => "${vendor}-",
	);
	$self->default;
    }
    return $vendor;
}

=item $xdg->B<get_autostart>() => HASHREF

Search out all XDG autostart files and collect them into a hash
reference.  The keys of the hash are the names of the F<.desktop> files
collected.  Autostart files follow XDG precedence rules for XDG
configuration directories.

Also establishes a hash reference in $xdg->{dirs}{autostart} that
contains all of the directories searched (whether they existed or not)
for use in conjuction with L<Linux::Inotify2(3pm)>.  See
L<XDE::Inotify(3pm)>.

=cut

sub get_autostart {
    my $self = shift;
    my %autostartdirs = ();
    my %files;
    foreach my $d (reverse map {"$_/autostart"} @{$self->{XDG_CONFIG_ARRAY}}) {
	$autostartdirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $f (readdir($dir)) {
	    next unless -f "$d/$f" and $f =~ /\.desktop$/;
	    open (my $fh,"<","$d/$f") or next;
	    my $parsing = 0;
	    my %e = (file=>"$d/$f",id=>$f);
	    my %xl = {};
	    while (<$fh>) {
                if (/^\[([^]]*)\]/) {
		    my $section = $1;
		    if ($section eq 'Desktop Entry') {
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
            $self->{ops}{lang} =~ m{^(..)}; my $short = $1;
            foreach (keys %xl) {
                if (exists $xl{$_}{$self->{ops}{lang}}) {
                    $e{$_} = $xl{$_}{$self->{ops}{lang}};
                }
                elsif (exists $xl{$_}{$short}) {
                    $e{$_} = $xl{$_}{$short};
                }
            }
            $e{Name} = '' unless $e{Name};
            $e{Exec} = '' unless $e{Exec};
            $e{Comment} = $e{Name} unless $e{Comment};
            $files{$f} = \%e;
	}
	closedir($dir);
    }
    # Mark those that are not to be run...
    my $desktop = $self->{XDG_CURRENT_DESKTOP};
    foreach my $e (values %files) {
	unless ($e->{Name}) {
	    $e->{'X-Disable'} = 'true';
	    $e->{'X-Disable-Reason'} = "No Name";
	    next;
	}
	unless ($e->{Exec}) {
	    $e->{'X-Disable'} = 'true';
	    $e->{'X-Disable-Reason'} = "No Exec";
	    next;
	}
	if ($e->{Hidden} and $e->{Hidden} =~ m{true|yes}i) {
	    $e->{'X-Disable'} = 'true';
	    $e->{'X-Disable-Reason'} = "Hidden";
	    next;
	}
	if ($e->{OnlyShowIn} and ";$e->{OnlyShowIn};" !~ /;$desktop;/) {
	    $e->{'X-Disable'} = 'true';
	    $e->{'X-Disable-Reason'} = "Only shown in $e->{OnlyShowIn}";
	    next;
	}
	if ($e->{NotShowIn} and ";$e->{NotShowIn};" =~ /;$desktop;/) {
	    $e->{'X-Disable'} = 'true';
	    $e->{'X-Disable-Reason'} = "Not shown in $e->{NotShowIn}";
	    next;
	}
        unless ($e->{TryExec}) {
            my @words = split(/\s+/,$e->{Exec});
            $e->{TryExec} = $words[0];
        }
        if (my $x = $e->{TryExec}) {
            if ($x =~ m{/}) {
                unless (-x "$x") {
		    $e->{'X-Disable'} = 'true';
		    $e->{'X-Disable-Reason'} = "$x is not executable";
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
		    $e->{'X-Disable'} = 'true';
		    $e->{'X-Disable-Reason'} = "$x is not executable";
                    next;
                }
            }
        }
	$e->{'X-Disable'} = 'false';
    }
    $self->{dirs}{autostart} = \%autostartdirs;
    return \%files;
}

=item $xdg->B<get_xsessions>() => HASHREF

Search out all XDG xsession files and collect them into a hash
reference.  The keys of the hash are the names of the F<.desktop> files
collected.  Session files follow XDG precedence rules for XDG
configuration directories.

Also establishes a hash reference in $xdg->{dirs}{xsessions} that contains
all of the directories search (whether they existed or not) for use in
conjunction with L<Linux::Inotify2(3pm)>.  See L<XDE::Inotify(3pm)>.

=cut

sub get_xsessions {
    my $self = shift;
    my %sessiondirs = ();
    my %files;
    foreach my $d (reverse map {"$_/xsessions"} @{$self->{XDG_DATA_ARRAY}}) {
	$sessiondirs{$d} = 1;
        opendir(my $dir, $d) or next;
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
            $self->{ops}{lang} =~ m{^(..)}; my $short = $1;
            foreach (keys %xl) {
                if (exists $xl{$_}{$self->{ops}{lang}}) {
                    $e{$_} = $xl{$_}{$self->{ops}{lang}};
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
        closedir($dir);
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
    $self->{dirs}{xsessions} = \%sessiondirs;
    return \%sessions;
}

=back

=cut

1;

__END__

=head1 OVERRIDES

I<%OVERRIDES> that are interpreted by this module are:

=over

=item B<XDG_CONFIG_*>

This includes B<XDG_CONFIG_LEGACY>, B<XDG_CONFIG_HOME>,
B<XDG_CONFIG_PREPEND>, B<XDG_CONFIG_DIRS>, B<XDG_CONFIG_APPEND>,
B<XDG_CONFIG_FALLBACK>.  Each takes a colon-separated list of paths
corresponding to XDG configuration directory lookup paths.  The
character C<~> will be replaced with the contents of the B<$HOME>
environtment variable.

=item B<XDG_DATA_*>

This includes B<XDG_DATA_LEGACY>, B<XDG_DATA_HOME>, B<XDG_DATA_PREPEND>,
B<XDG_DATA_DIRS>, B<XDG_DATA_APPEND>, B<XDG_DATA_FALLBACK>.  Each takes
a colon-separated list of paths corresponding to XDG data directory
lookup paths.  The character C<~> will be replaced with the contents of
the B<$HOME> environtment variable.

=item B<XDG_ICON_*>

This includes B<XDG_ICON_LEGACY>, B<XDG_ICON_HOME>, B<XDG_ICON_PREPEND>,
B<XDG_ICON_DIRS>, B<XDG_ICON_APPEND>, B<XDG_ICON_FALLBACK>.  Each takes
a colon-separated list of paths corresponding to icon lookup paths.  The
character C<~> will be replaced with the contents of the B<$HOME>
environtment variable.

=item B<XDG_MENU_PREFIX>, B<XDG_VENDOR_ID>

B<XDG_MENU_PREFIX> specifies the XDG menu prefix.  B<XDG_VENDOR_ID>
specifies the XDG vendor identifier that will be used when determining
the default B<XDG_MENU_PREFIX>.

=item B<XDG_CURRENT_DESKTOP>

Specifies the current desktop session.  This is the all upper-case name
that will be used as the desktop environment when interpreting
C<OnlyShowIn> and C<NotShowIn> F<.desktop> file fields.

=back

=head1 OPTIONS

XDG::Context recognizes the following options, I<%ops>, passed to B<new>:

=over

=item verbose => $boolean

When true, print diagnostic information to standard error during
operation.  The default is false.

=item charset => $charset

Specifies the character set to use on output; defaults to the character
set of the current locale.

=item language => $language

Specifies the language to use on output and to select from available
translations in XDG F<.desktop> files.  Defaults to the value for the
current locale.

=item lang => $lang

Specifies the translation string to use when selecting translations from
XDG F<.desktop> files.  Defaults to the language portion of the
C<language> option, above.

=item desktop => $desktop

Specifies the current XDG desktop environment (e.g. FLUXBOX).  When
unspecified, defaults will be set from environment variables.

=item vendor => $vendor

Specifies the vendor string for branding.  When unspecified, defaults
will be taken from environment variables.

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72
