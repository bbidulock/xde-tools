package XDE::Settings;
use base qw(XDE::Dual);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Xsettings -- manage XSETTINGS for the XDE desktop

=head1 SYNOPSIS

 use XDE::Xsettings;

 my $xde = XDE::Xsettings->new();
 $xde->init;
 $xde->set_settings(%hash);
 $xde->main;

=head1 DESCRIPTION

Provides a module that runs out of the Glib::Mainloop that will manage
the XSETTINGS on a lightweight destop and monitor for changes.

=head1 METHODS

=over

=cut

=item $xde = XDE::Xsettings->B<new>(I<%OVERRIDES>)

Creates an instance of an XDE::Xsettings object.  The XDE::Xsettings
modules uses the L<XDE::Context(3pm)> module as a base, so the
C<%OVERRIDES> are simply passed to the L<XDE::Context(3pm)> module.

=cut

sub new {
    return XDE::Context::new(@_);
}

=item $xde->B<_init>()

Performs initialization for just this module.  Called after
L<XDE::Dual(3pm)> is fully initialized.

Initialization routine that is called like Gtk2->init.  It establishes
the X11::Protocol connection to the X Server and determines the initial
values and settings for the root window of each screen of the display
for later management of XSETTINGS.

Called internally by B<new> to setup the XSETTINGS instance.  It
establishes a window on each screen and attempts to assume management of
the _XSETTINGS_S[n] selection for each screen (n).  It also monitors for
structure notifications on each screen's root window as well as on its
own windows.  It monitors for property change notifications on each
screen's root window and on any window that ultimately owns the
_XSETTINGS_S[n] selection.

=cut

sub _init {
    my $self = shift;
    my $X = $self->{X};
    my $emask = $X->pack_event_mask('StructureNotify','PropertyChange');
    my $smask = $X->pack_event_mask('StructureNotify');
    my $pmask = $X->pack_event_mask('PropertyChange');
    my $manager = $X->atom('MANAGER');
    my $screens = scalar(@{$X->{screens}});
    my $time = 0;
    $self->{owns} = 0;
    for (my $n=0;$n<$screens;$n++) {
	my $screen = $X->{screens}[$n];
	my $win = $self->{windows}[$n] = $X->new_rsrc;
	$X->CreateWindow($win, $screen->{root}, 'InputOutput',
		$screen->{root_depth}, 'CopyFromParent', (0, 0),
		1, 1, 0, event_mask=>$smask);
	$X->ChangeWindowAttributes($screen->{root}, event_mask=>$emask);
	my $name = "_XSETTINGS_S$n";
	my $selection = $X->atom($name);
	my $owner = $self->{owners}[$n] = $X->GetSelectionOwner($selection);
	warn sprintf("Selection %s has owner 0x%08x",$name,$owner) if $owner and $owner ne 'None';
	if ($owner eq 'None' or ($self->{ops}{takeover} and $owner != $win)) {
	    $X->SetSelectionOwner($selection,$win,$time);
	    $owner = $self->{owners}[$n] = $X->GetSelectionOwner($selection);
	}
	if ($owner == $win) {
	    $self->{owns} += 1;
	    $X->SendEvent($X->root,FALSE,$smask,$X->pack_event(
		    name=>'ClientMessage', type=>$manager, format=>32,
		    data=>pack('LLLLL',$time,$selection,$win,0,0)));
	}
	elsif ($owner eq 'None') {
	    warn sprintf("Selection %s ownership failed",$name);
	}
	else {
	    warn sprintf("Selection %s ownership failed to 0x%08x",$name,$owner) if $self->{ops}{takeover};
	    $X->ChangeWindowAttributes($owner, event_mask=>$pmask);
	}
    }
}

=item $xde->B<_term>()

Performs termination just for this module.  Called before
C<XDE::X11-E<gt>term()> is called.

B<XDE::Settings> needs to write its configuration back to the
configuration file before exit.

=cut

sub _term {
    my $self = shift;
    my $X = $self->{X};
    $self->get_settings(); # grab it once before exiting
    my $verbose = $self->{ops}{verbose};
    my $config = $self->{config};
    my $filename = $self->{ops}{filename};
    print STDERR "Writing to filename '%s' on exit\n", $filename;
    open(my $fh,">",$filename) or return;
    foreach my $section (sort keys %config) {
	printf $fh "\n[%s]\n", $section;
	my $fields = $config->{$section};
	foreach (sort keys %$fields) {
	    printf $fh "%s=%s\n", $_, $fields->{$_};
	}
    }
    close($fh);
    return $self;
}

sub get_settings {
    my $self = shift;
    my $X = $self->{X};
    my $verbose = $self->{ops}{verbose};
    my $config = $self->{config};
    $config = $self->{config} = {
	Xsettings=>{},
    } unless $config;
    $config->{Xsettings} = {} unless $config->{Xsettings};
}

=item $xset->B<read_rgb_txt>() => HASHREF

Attempts to read the F<rgb.txt> file from a number of locations in the
following order: F</usr/lib/X11/rgb.txt>, F</etc/X11/rgb.txt>,
F</usr/share/tightvnc/rgb.txt>, F</usr/share/vim/vim73/rgb.txt>.  The
first file discovered is read and each color name is converted to a
#RRRRGGGGBBBBAAAA format.  This hash is saved internally and used to
lookup colors by name.

=cut

sub read_rgb_txt {
    my $self = shift;
    my @files = (
	    '/usr/lib/X11/rgb.txt',
	    '/etc/X11/rgb.txt',
	    '/usr/share/tightvnc/rgb.txt',
	    '/usr/share/vim/vim73/rgb.txt',
    );
    my %rgb = ();
    my $file;
    foreach my $f (@files) {
	if (-f $_) {
	    $file = $f;
	    open(my $fh,"<",$file) or next;
	    while (<$fh>) { chomp;
		next if m{^!};
		my @vals = split(/\s+/,$_,4);
		next unless $vals[0] =~ m|^\d{1,3}$| and
			    $vals[1] =~ m|^\d{1,3}$| and
			    $vals[2] =~ m|^\d{1,3}$| and
			    $vals[3];
		my $name = $vals[3];
		$vals[3] = 255;
		$rgb{$name} = sprintf "#%04X%04X%04X%04X", map{$_*257}@vals;
	    }
	    close($fh);
	}
    }
    $self->{rgb} = \%rgb;
    return \%rgb;
}

=item $xset->B<get_color>(I<$color>) => SCALAR #RRRRGGGGBBBBAAAA

Attempts to convert the color, C<$color>, into a normalized color format
scalar of the form C<#RRRRGGGGBBBBAAAA> where all letters represent
hexadecimal digits.  Format recognized on input are: C<#RRGGBB>,
C<#RRGGBBAA>, C<#RRRRGGGGBBBB>, C<#RRRRGGGGBBBBAAAA>, C<rgb: RR/GG/BB>,
C<rgb: ColorName>, and C<ColorName>.  If the color conversion fails, the
color C<#FFFFFFFFFFFFFFFF> (opaque white) is returned.

=cut

sub get_color {
    my ($self,$color) = @_;
    my $val = '#FFFFFFFFFFFFFFFF';
    if ($color =~ m|^\#([0-9A-Fa-f]{2}){3,4}|) {
	my @rgba = ($1,$2,$3,$4);
	$rgba[3] = 'ff' unless defined $4;
	@rgba = (map{hex($_)*257}@rgba);
	$val = sprintf "#%04X%04X%04X%04X", @rgba;
    }
    elsif ($color =~ m|^\#([0-9A-Fa-f]{4}){3,4}|) {
	my @rgba = ($1,$2,$3,$4);
	$rgba[3] = 'ffff' unless defined $4;
	@rgba = (map{hex($_)}@rgba);
	$val = sprintf "#%04X%04X%04X%04X", @rgba;
    }
    elsif ($color =~ m|^rgb: ([0-9A-Za-z]{2})/([0-9A-Za-z]{2})/([0-9A-Za-z]{2})$|) {
	my @rgba = ($1,$2,$3,'ff');
	@rgba = (map{hex($_)*257}@rgba);
	$val = sprintf "#%04X%04X%04X%04X", @rgba;
    }
    elsif ($color =~ m|^rgb: (.*)$|) {
	$val = $self->{rgb}{$1} if $self->{rgb}{$1};
    }
    elsif ($self->{rgb}{$color}) {
	$val = $self->{rgb}{$color};
    }
    return $val;
}

=item $xde->B<convert>(I<\%newset>,I<$serial>) => $changed

Addes the set of XSETTINGS C<\%newset> into the current settings with
serial number C<$serial>.  It returns the number of XSETTINGS that were
actually changed.  If the number of XSETTINGS changed is zero, there is
no need to change the B<_XSETTINGS_SETTINGS> property or perform client
actions on the changed.

The C<\%newset> hash reference referes to a hash that has keys that are
the XSETTINGS names.   An optional character, C<i>, C<s>, or C<c> can be
prefixed to the XSETTING name to specify clearly whether the setting is
an integer, string or color respectively.  The values of the hash can
beither be plain scalars, or can be an arrayref of the form:

 [ $type, $name, $serial, $value ]

wehre C<$type> is the SETTING_TYPE (0 => integer, 1 => string, 2 =>
color); C<$name> is the SETTING_NAME, C<$serial> is the serial number of
the last change, and C<$value> is the scalar integer or string value, or
the color in C<#RRRRGGGGBBBBAAAA> format.

=cut

sub convert {
    my ($self,$nset,$serial) = @_;
    my $changed = 0;
    my $oset = $self->{xset}{settings};
    $oset = $self->{xset}{settings} = {} unless $oset;
    foreach my $key (keys %$nset) {
	my $val = $nset->{$key};
	my @newval;
	if (ref($val) eq 'ARRAY') {
	    @newval = @$val;
	}
	elsif ($key =~ s{^i}{}) {
	    @newval = ( 0, $key, $serial, $val );
	}
	elsif ($key =~ s{^s}{}) {
	    @newval = ( 1, $key, $serial, $val );
	}
	elsif ($key =~ s{^c}{}) {
	    # about the only thing that we have to put a 'c' in front of
	    # is a bare rgb color name
	    $val = $self->get_color($val));
	    @newval = ( 2, $key, $serial, $val );
	}
	elsif ($val =~ m|^-?\d+$|) {
	    @newval = ( 0, $key, $serial, $val );
	}
	elsif ($val =~ m{^(\#|rgb:)}) {
	    $val = $self->get_color($val));
	    @newval = ( 2, $key, $serial, $val );
	}
	else {
	    @newval = ( 1, $key, $serial, $val );
	}
	unless ($oset->{$key} and
		$oset->{$key}[0] eq $newval[0] and
		$oset->{$key}[3] eq $newval[3]) {
	    $oset->{$key} = \@newval;
	    $changed += 1;
	}
    }
    return $changed;
}

=item $xde->B<pack_xsettings>(I<$serial>) => $pack

=cut

sub pack_xsettings {
    my ($self,$serial) = @_;
    my $xset = $self->{xset}{settings};
    $xset = $self->{xset}{settings} = {} unless $xset;
    my $nset = scalar(keys %$xset);
    my $pack = '';
    $pack .= pack('CxxxLL',$byte_order,$serial,$nset);
    foreach my $key (keys %$xset) {
	my @vals = @{$xset->{$key}};
	my $klen = length($vals[1]);
	$pack .= pack('CxS',$vals[0],$klen);
	$pack .= substr($vals[1]."\0\0\0\0",0,$klen+(-$klen&3));
	$pack .= pack('L',$vals[2]);
	if ($vals[0] == 0) {
	    $pack .= pack('l',$vals[3]);
	}
	elsif ($vals[0] == 1) {
	    my $vlen = length($vals[3]);
	    $pack .= pack('L',$vlen);
	    $pack .= substr($vals[3]."\0\0\0\0",0,$vlen+(-$vlen&3));
	}
	elsif ($vals[0] == 2) {
	    $pack .= pack('SSSS',
		    hex(substr($vals[3],1,4)),
		    hex(substr($vals[3],5,4)),
		    hex(substr($vals[3],9,4)),
		    hex(substr($vals[3],13,4)));
	}
    }
    return $pack;
}

=item $xde->B<unpack_xsettings>(I<$data>) => (\I<%xset>,I<$serial>)

=cut

sub unpack_xsettings {
    my ($self,$data) = @_;
    my %xset = ();
    my $len = length($data);
    my $off = 0;
    return undef unless $len - $off >= 12;
    my ($byte_order,$serial,$nset) = unpack('CxxxLL',substr($data,$off,12)); $off += 12;
    while ($nset) {
	last unless $len - $off >= 4;
	my ($type,$klen) = unpack('CxS',substr($data,$off,4)); $off += 4;
	last unless $len - $off >= 4 + $klen;
	my $key = substr($data,$off,$klen); $off += $klen + (-$klen&3);
	last unless $len - $off >= 4;
	my ($last_serial) = unpack('L',substr($data,$off,4)); $off += 4;
	last if $type > 2;
	my $value;
	if ($type == 0) {
	    last unless $len - $off >= 4;
	    $value = unpack('l',substr($data,$off,4)); $off += 4;
	}
	elsif ($type == 1) {
	    last unless $len - $off >= 8;
	    my $vlen = unpack('L',substr($data,$off,4)); $off += 4;
	    last unless $len - $off >= $vlen + (-$vlen&3);
	    $value = substr($data,$off,$vlen); $off += $vlen + (-$vlen&3);
	}
	elsif ($type == 2) {
	    last unless $len - $off >= 8;
	    $value = sprintf("#%04X%04X%04X%04X",
		unpack('SSSS',substr($data,$off,8))); $off += 8;
	}
	$xset{$key} = [ $type, $key, $last_serial, $value ];
	$nset -= 1;
    }
    return \%xset unless wantarray;
    return (\%xset,$serial);
}

=item $xde->B<change_xsettings>()

Changes the XSETTINGS in the B<_XSETTINGS_SETTINGS> property on the
manager window.

=cut

sub change_xsettings {
    my $self = shift;
    my $X = $self->{X};
    my $data = $self->pack_xsettings($self->{serial});
    $self->{serial} += 1;
    $X->ChangeProperty($self->{win},$X->atom('_XSETTINGS_SETTINGS'),
	    $X->atom('_XSETTINGS_SETTINGS'), 8, 'Replace', $data);

}

sub event_handler_PropertyNotify_XSETTINGS_SETTINGS {
    my ($self,$e,$X,$v) = @_;
    if ($v) {
	printf STDERR "%s:\n", $e->{name};
	printf STDERR "  time => %d\n", $e->{time};
	printf STDERR "  atom => %s\n", $X->atom_name($e->{atom});
	printf STDERR "  state => %s\n", $e->{state};
	printf STDERR "  window => 0x%08x\n", $e->{window};
	printf STDERR "  code => %d\n", $e->{code};
    }
}
sub event_handler_SelectionClear {
    my ($self,$e,$X,$v) = @_;
    if ($v) {
	printf STDERR "%s:\n", $e->{name};
    }
}
sub event_handler_SelectionRequest {
    my ($self,$e,$X,$v) = @_;
    if ($v) {
	printf STDERR "%s:\n", $e->{name};
	printf STDERR "  time => %d\n", $e->{time};
	printf STDERR "  owner => 0x%08x\n", $e->{owner};
	printf STDERR "  requestor => 0x%08x\n", $e->{requestor};
	printf STDERR "  selection => %s\n", $X->atom_name($e->{selection});
	printf STDERR "  target => %s\n", $e->{target} eq 'None' ? 'None' : $X->atom_name($e->{target});
	printf STDERR "  property => %s\n", $e->{property} eq 'None' ?  'None' : $X->atom_name($e->{property});
    }
}
sub event_handler_SelectionNotify {
    my ($self,$e,$X,$v) = @_;
    if ($v) {
	printf STDERR "%s:\n", $e->{name};
	printf STDERR "  time => %d\n", $e->{time};
	printf STDERR "  requestor => 0x%08x\n", $e->{requestor};
	printf STDERR "  selection => %s\n", $X->atom_name($e->{selection});
	printf STDERR "  target => %s\n", $e->{target} eq 'None' ? 'None' : $X->atom_name($e->{target});
	printf STDERR "  property => %s\n", $e->{property} eq 'None' ?  'None' : $X->atom_name($e->{property});
    }
}
sub event_handler_CreateNotify {
    my ($self,$e,$X,$v) = @_;
    if ($v) {
	printf STDERR "%s:\n", $e->{name};
	printf STDERR "  parent => 0x%08x\n", $e->{parent};
	printf STDERR "  window => 0x%08x\n", $e->{window};
	printf STDERR "  x => %d\n", $e->{x};
	printf STDERR "  y => %d\n", $e->{y};
	printf STDERR "  width => %d\n", $e->{width};
	printf STDERR "  height => %d\n", $e->{height};
	printf STDERR "  border-width => %d\n", $e->{border_width};
	printf STDERR "  override-redirect => %s\n", $e->{override_redirect};
    }
}
sub event_handler_DestroyNotify {
    my ($self,$e,$X,$v) = @_;
    if ($v) {
	printf STDERR "%s:\n", $e->{name};
	printf STDERR "  event => 0x%08x\n", $e->{event};
	printf STDERR "  window => 0x%08x\n", $e->{window};
    }
}
sub event_handler_ClientMessage {
    my ($self,$e,$X,$v) = @_;
    if ($v) {
	printf STDERR "%s:\n", $e->{name};
	printf STDERR "  code => %d\n", $e->{code};
	printf STDERR "  window => 0x%08x\n", $e->{window};
	printf STDERR "  type => %s\n", $X->atom_name($e->{type});
	printf STDERR "  format => %d\n", $e->{format};
	printf STDERR "  data => %s\n", join(' ',unpack('H*',$e->{data}));
    }
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72
