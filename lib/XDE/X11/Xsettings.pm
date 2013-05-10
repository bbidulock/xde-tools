package XDE::X11::Xsettings;
use base qw(XDE:X11);
use Glib qw(TRUE FALSE);
use strict;
use warnings;

=head1 NAME

XDG::X11::Xsettings -- and XDG XSETTINGS daemon/client for XDE

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 METHODS

=over

=cut

=item $xset = XDE::X11::Xsettings->B<new>(I<\%ops>,I<@XOPTS>) => blessed HASHREF

Creates a new XSETTINGS instance.  C<@XOPTS> are options that are passed
directly to L<X11::Protocol(3pm)>.  C<\%ops> are options that are
intepreted by XDE::X11::Xsettings.  The only current option is C<takeover>
which, when set true, indicates that XDE::X11::Xsettings is to takeover the
manager selection for _XSETTINGS_S[n] from another XSETTINGS daemon if
it can.

=cut

sub new {
    my ($type,$ops) = (shift,shift);
    my $self = XDE::X11::new($type,@_);
    my $xset = $self->{xset} = {};
    $ops = {} unless $ops;
    $xset->{ops} = $ops;
    $self->setup_xsettings;
    $self->read_rgb_text;
    return $self;
}

=item $xset->B<setup_xsettings>()

Called internally by B<new> to setup the XSETTINGS instance.  It
establishes a window on each screen and attempts to assume management of
the _XSETTINGS_S[n] selection for each screen (n).  It also monitors for
structure notifications on each screen's root window as well as on its
own windows.  It monitors for property change notifications on each
screen's root window and on any window that ultimately owns the
_XSETTINGS_S[n] selection.

=cut

sub setup_xsettings {
    my $self = shift;
    my $xset = $self->{xset};
    my $ops = $xset->{ops};
    my $emask = $self->pack_event_mask('StructureNotify','PropertyChange');
    my $smask = $self->pack_event_mask('StructureNotify');
    my $pmask = $self->pack_event_mask('PropertyChange');
    my $manager = $self->atom('MANAGER');
    my $time = 0;
    $xset->{owns} = 0;
    for (my $n=0;$n<@{$self->{screens}};$n++) {
	$self->choose_screen($n);
	my $win = $xset->{windows}[$n] = $self->new_rsrc;
	$self->CreateWindow($win, $self->root, 'InputOutput',
		$self->root_depth, 'CopyFromParent', (0, 0), 1, 1, 0,
		event_mask=>$smask);
	$self->ChangeWindowAttributes($self->root, event_mask=>$emask);
	my $name = "_XSETTINGS_S$n";
	my $selection = $self->atom($name);
	my $owner = $xset->{owners}[$n] = $self->GetSelectionOwner($selection);
	warn sprintf("Selection %s has owner 0x%08x",$name,$owner) if $owner;
	if ($owner == 0 or ($ops->{takeover} and $owner != $win)) {
	    $self->SetSelectionOwner($selection,$win,$time);
	    $owner = $xset->{owners}[$n] = $self->GetSelectionOwner($selection);
	}
	if ($owner == $win) {
	    $xset->{owns} += 1;
	    $self->SendEvent($self->root,FALSE,$smask,$self->pack_event(
		    name=>'ClientMessage', type=>$manager, format=>32,
		    data=>pack('LLLLL',$time,$selection,$win,0,0)));
	}
	elsif ($owner == 0) {
	    warn sprintf("Selection %s ownership failed",$name);
	}
	else {
	    warn sprintf("Selection %s ownership failed to 0x%08x",$name,$owner) if $ops->{takeover};
	    $self->ChangeWindowAttributes($owner, event_mask=>$pmask);
	}
    }
}

sub input {
    my $self = shift;

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

=item $changed = $xset->B<convert>(I<\%newset>,I<$serial>)

Adds the set of XSETTINGS C<\%newset> into the current settings with
serial number C<$serial>.  It returnes the number of XSETTINGS that were
actually changed.  If the number of XSETTINGS changed is zero, there is
no need to change the _XSETTINGS_SETTINGS property or perform client
actions on the change.

The C<\%newset> hash reference refers to a hash that has keys that are
the XSETTINGS names.  An optional character, C<i>, C<s>, or C<c> can be
prefixed to the XSETTING name to specify clearly whether the setting is
an integer, string or color respectively.  The values of the hash can
either be plain scalars, or can be an arrayref of the form

 [ $type, $name, $serial, $value ]

where C<$type> is the SETTING_TYPE (0 => integer, 1 => string, 2 =>
color), C<$name> is the SETTTING_NAME, C<$serial> is the serial number
of the last change, and C<$value> is the scalar integer or string value,
or the color in C<#RRRRGGGGBBBBAAAA> format.

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

sub change_xsettings {
    my $self = shift;
    my $X = $self->{X};
    my $data = $self->pack_xsettings($self->{serial});
    $self->{serial} += 1;
    $X->ChangeProperty($self->{win}, $X->atom('_XSETTINGS_SETTINGS'),
	    $X->atom('_XSETTINGS_SETTINGS'), 8, 'Replace', $data);
}

sub event {
    my ($self,$event) = @_;
    my $handler = "event_$event->{name}";
    $self->$handler($event) if $self->can($handler);
}
sub event_PropertyNotify {
    my ($self,$event) = @_;
    my $X = $self->{X};
    my $win = $self->{win};
    my $root = $X->root;
}
sub event_SelectionClear {
    my ($self,$event) = @_;
    my $X = $self->{X};
    my $win = $self->{win};
    my $root = $X->root;
    my $time = $event->{time};
    my $owner = $event->{owner};
    my $selection = $event->{selection};
}
sub event_SelectionRequest {
    my ($self,$event) = @_;
    my $X = $self->{X};
    my $win = $self->{win};
    my $root = $X->root;
    my $time = $event->{time};
    my $owner = $event->{owner};
    my $requestor = $event->{requestor};
    my $selection = $event->{selection};
    my $target = $event->{target};
    my $property = $event->{property};
}
sub event_SelectionNotify {
    my ($self,$event) = @_;
    my $X = $self->{X};
    my $win = $self->{win};
    my $root = $X->root;
}
sub event_ClientMessage {
    my ($self,$event) = @_;
    my $X = $self->{X};
    my $win = $self->{win};
    my $root = $X->root;
}

=item $xset->B<_handle_event>($event)

Internal routine for handling events.  Called whenever the
X11::Protocol::Connection receives an event when no reply was expected.

=cut

sub _handle_event {
    my ($self,$event) = @_;
}

=item $xset->B<_handle_error>($error)

Internal routine for handling errors.  Called whenever the
X11::Protocol::Connection receives an error when no reply was expected.

=cut

sub _handle_error {
    my ($self,$error) = @_;
}

=back

=cut

1;

# vim: sw=4 tw=72
