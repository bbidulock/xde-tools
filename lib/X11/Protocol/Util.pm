package X11::Protocol::Util;
use base qw(X11::Protocol::AnyEvent);
use X11::Protocol;
use Encode;
use Encode::Unicode;
use Encode::X11;
use strict;
use warnings;
use vars '$VERSION';
$VERSION = 0.01;

=head1 NAME

X11::Protocol::Util - utility methods for window manager hints

=head1 SYNOPSIS

 package MyPackage;
 use base qw(X11::Protocol::Util);

=head1 DESCRIPTION

This module provides some base utility functions for use with the
L<X11::Protocol::ICCCM(3pm)> module.

=head1 METHODS

The module provides the following methods:

=head2 Getting Properties

The following methods are used to get properties from windows:

=over

=item $X->B<getProperty>(I<$win>,I<$prop>,I<$type>,I<$format>) => I<$type>, I<$data>

Get a property from a window and return its full-length packed data
representation.  Returns C<undef> if the property does not exist.

=cut

sub getProperty {
    my($X,$win,$prop,$type) = @_;
    $win = $X->root unless $win;
    my $atom = $X->atom($prop);
    $type = 0 unless $type;
    my($data,$error);
    $error = $X->robust_req(GetProperty=>$win, $atom, $type, 0, 1);
    if (ref $error eq 'ARRAY') {
	my ($val,$rtype,$format,$after) = @$error;
	if ($val) {
	    if ($after) {
		my $part = $val;
		$error = $X->robust_request(GetProperty=>
			$win, $atom, $type, 1, (($after+3)>>2));
		if (ref $error eq 'ARRAY') {
		    ($val) = @$error;
		    return ($part.$val, $self->atom_name($rtype));
		}
	    } else {
		return ($val, $self->atom_name($rtype));
	    }
	}
    }
    warn sprintf "Could not get property %s for window 0x%x", $prop, $win
	if $X->{ops}{verbose};
    return ();
}

=item $X->B<getWMRootPropertyDecode>(I<$prop>,I<$decode>) => I<$value>

Provides a method for obtaining a decoded property from the root window.
The property has atom name, I<$prop>, and decoder, I<$decode> is a C<CODE>
reference that accepts the packed data as an argument and returns the
decoded data.  This method is used by subsequent methods below:

=cut

sub getWMRootPropertyDecode {
    my ($self,$prop,$decode) = @_;
    if (my($data,$rtype) = $self->getProperty(0,$prop)) {
	$self->{$prop} = &{$decode}($data,$rtype);
    } else {
	warn "Could not retrieve property $prop!";
	delete $self->{$prop};
    }
    return $self->{$prop};
}

=over

=item $X->B<getWMRootPropertyString>(I<$prop>) => I<$value>

Returns I<$value> as a single scalar string value.  This method handles
C<STRING>, C<COMPOUND_TEXT> and C<UTF8_STRING> properties.  Any property
of another type is treated as C<UTF8_STRING>.  This method automatically
handles null terminated strings.

=cut

sub getWMRootPropertyString {
    my ($self,$prop) = @_;
    return $self->getWMRootPropertyDecode($prop,sub{
	    my($data,$type) = @_;
	    return Encode::decode('iso-8859-1',unpack('Z*',$data))
		if $type eq 'STRING';
	    return Encode::decode('x11-compound-text',unpack('Z*',$data))
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return Encode::decode('UTF-8',unpack('Z*',$data));
    });
}

=item $X->B<getWMRootPropertyStrings>(I<$prop>) => I<$value>

Returns I<$value> as a reference to an array of strings.  This method
handles C<STRING>, C<COMPOUND_TEXT> and C<UTF8_STRING> properties.  Any
property of another type is treated as C<UTF8_STRING>.  This method
automatically handles null terminated strings (vs. null separated
strings); however, if a list of strings has a zero-length string as the
last element in the list, it will be truncated from the I<$value> array.

=cut

sub getWMRootPropertyStrings {
    my ($self,$prop) = @_;
    return $self->getWMRootPropertyDecode($prop,sub{
	    my($data,$type) = @_;
	    return [ map{Encode::decode('iso-8859-1',$_)} unpack('(Z*)*',$data) ]
		if $type eq 'STRING';
	    return [ map{Encode::decode('x11-compound-text',$_)} unpack('(Z*)*',$data) ]
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return [ map{Encode::decode('UTF-8',$_)} unpack('(Z*)*',$data) ];
    });
}

=item $X->B<getWMRootPropertyInt>(I<$prop>) => I<$value>

Returns I<$value> as a single scalar integer value.

=cut

sub getWMRootPropertyInt {
    my ($self,$prop) = @_;
    return $self->getWMRootPropertyDecode($prop,
	sub{ return unpack('L',shift); });
}

=item $X->B<getWMRootPropertyInts>(I<$prop>) => I<$value>

Returns I<$value> as an reference to an array of integer values.

=cut

sub getWMRootPropertyInts {
    my ($self,$prop) = @_;
    return $self->getWMRootPropertyDecode($prop,
	sub{ return [ unpack('L*',shift) ]; });
}

=item $X->B<getWMRootPropertyAtom>(I<$prop>) => I<$value>

Returns I<$value> as a single scalar atom name.

=cut

sub getWMRootPropertyAtom {
    my ($self,$prop) = @_;
    return $self->getWMRootPropertyDecode($prop,
	sub{ return $self->atom_name(unpack('L',shift)); });
}

=item $X->B<getWMRootPropertyAtoms>(I<$prop>) => I<$value>

Returns I<$value> as a reference to an array of atom names.

=cut

sub getWMRootPropertyAtoms {
    my ($self,$prop) = @_;
    return $self->getWMRootPropertyDecode($prop,
	sub{ return { map{$self->atom_name($_)=>1} unpack('L',shift) }; });
}

=back

=item $X->B<getWMPropertyDecode>(I<$window>,I<$prop>,I<$decode>)

Provides a method for obtaining a decoded property from a specified
window, I<$window>.  When undefined or zero, I<$window> defaults to the
active window.  The property has atom name, I<$prop>, and decoder,
I<$decode> is a C<CODE> reference that accepts the packed data as an
argument and returns the decoded data.  This method is usede by subsequent
methods below:

=cut

sub getWMPropertyDecode {
    my ($self,$window,$prop,$decode) = @_;
    $window = $self->{_NET_ACTIVE_WINDOW} unless $window;
    $window = $self->root unless $window;
    if (my($data,$rtype) = $self->getProperty($window, $prop)) {
	$self->{windows}{$window}{$prop} = &{$decode}($data,$rtype);
    } else {
	delete $self->{windows}{$window}{$prop};
    }
    return $self->{windows}{$window}{$prop};

}

=over

=item $X->B<getWMPropertyString>(I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a single scalar string value.  This method handles
C<STRING>, C<COMPOUND_TEXT> and C<UTF8_STRING> properties.  Any property
of another type is treated as C<UTF8_STRING>.  This method automatically
handles null terminated strings.

=cut

sub getWMPropertyString {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,sub{
	    my($data,$type) = @_;
	    return Encode::decode('iso-8859-1',unpack('Z*',$data))
		if $type eq 'STRING';
	    return Encode::decode('x11-compound-text',unpack('Z*',$data))
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return Encode::decode('UTF-8',unpack('Z*',$data));
    });
}

=item $X->B<getWMPropertyStrings>(I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a reference to an array of strings.  This method
handles C<STRING>, C<COMPOUND_TEXT> and C<UTF8_STRING> properties.  Any
property of another type is treated as C<UTF8_STRING>.  This method
automatically handles null terminated strings (vs. null separated
strings); however, if a list of strings has a zero-length string as the
last element in the list, it will be truncated from the I<$value> array.

=cut

sub getWMPropertyStrings {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,sub{
	    my($data,$type) = @_;
	    return [ map{Encode::decode('iso-8859-1',$_)} unpack('(Z*)*',$data) ]
		if $type eq 'STRING';
	    return [ map{Encode::decode('x11-compound-text',$_)} unpack('(Z*)*',$data) ]
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return [ map{Encode::decode('UTF-8',$_)} unpack('(Z*)*',$data) ];
    });
}

=item $X->B<getWMPropertyInt>(I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a single scalar integer value.

=cut

sub getWMPropertyInt {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return unpack('L',shift); });
}

=item $X->B<getWMPropertyInts>(I<$window>,I<$prop>) => I<$value>

Returns I<$value> as an reference to an array of integer values.

=cut

sub getWMPropertyInts {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return [ unpack('L*',shift) ]; });
}

=item $X->B<getWMPropertyAtom>(I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a single scalar atom name.

=cut

sub getWMPropertyAtom {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return $self->atom_name(unpack('L',shift)); });
}

=item $X->B<getWMPropertyAtoms>(I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a reference to an array of atom names.

=cut

sub getWMPropertyAtoms {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return { map{$self->atom_name($_)=>1} unpack('L',shift) }; });
}

=item $X->B<getWMPropertyBits>(I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a reference to an array of bit values or C<undef>
when the property, I<$prop>, does not exist on I<$window>.

=cut

sub getWMPropertyBits {
    my ($self,$window,$prop) = @_;
    return $self->getWMPropertyDecode($window,$prop,
	sub{ return [ map{unpack('b*',pack('V',$_))} unpack('L*',shift) ]; });
}

=back

=back

=head2 Setting Properties

The following methods are used to set properties on windows:

=over

=item $X->B<setProperty>(I<$win>,I<$prop>,I<$type>,I<$format>,I<$data>)

Set a property on a window.  I<$win> is the window on which to set the
property; defaults to the default root window when zero or C<undef>.
I<$prop> is the name of the property.  I<$type> is the name of the
property type.  I<$format> is 8, 16 or 32 specifying the format of the
property.  I<$data> is the packed data for the property.

=cut

sub setProperty {
    my($X,$win,$prop,$type,$format,$data) = @_;
    $win = $X->root unless $win;
    $X->ChangeProperty($win,
	    $X->atom($prop),
	    $X->atom($type),
	    $format, Replace=>$data);
    $X->flush;
}

=item $X->B<deleteProperty>(I<$win>,I<$prop>)

Deletes the property named I<$prop> from the window, I<$win>.  I<$win>
defaults to the default root window when zero or C<undef>.

=cut

sub deleteProperty {
    my($X,$win,$prop) = @_;
    $win = $X->root unless $win;
    $X->DeleteProperty($win,$X->atom($prop));
    $X->flush;
}

=item $X->B<setWMRootPropertyEncode>(I<$prop>,I<$format>,I<$encode>,I<@args>)

Provides a method for setting an encoded property to the root window.  The
property has atom name, I<$prop>, format, I<$format>, and encoder,
I<$encode> is a C<CODE> reference that accepts the argument, I<$args>, and
returns a type and encoded packed data.  This method is used by subsequent
methods below:

=cut

sub setWMRootPropertyEncode {
    my($self,$prop,$format,$encode,@args) =  @_;
    if (@args) {
	my ($type,$data) = &{$encode}(@args);
	$self->setProperty(0,$prop,$type,$format,$data);
    } else {
	$self->deleteProperty(0,$prop);
    }
}

=over

=item $X->B<setWMRootPropertyString>(I<$prop>,I<$type>,I<$string>)

Set set property, I<$prop>, to the string value, I<$string>.
I<$type> must be one of C<STRING>, C<COMPOUND_TEXT> or C<UTF8_STRING>.
When the resulting property must be null terminated, it may be necessary
to append the null character to the end of the string, I<$string>.

=cut

sub _string_OK {
    my $string = shift;
    Encode::encode('iso-8859-1', $string, Encode::FB_QUIET);
    return (length($string) == 0);
}

sub setWMRootPropertyString {
    my($self,$prop,$type,$string) = @_;
    $self->setWMRootPropertyEncode($prop,8,sub{
	    my($type,$string) = @_;
	    return STRING=>Encode::encode('iso-8859-1',$string)
		if $type eq 'STRING' or
		  ($type eq 'COMPOUND_TEXT' and _string_OK($string));
	    return $type=>Encode::encode('x11-compound-text',$string)
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return UTF8_STRING=>Encode::encode('UTF-8',$string);
    },$type,$string);
}

=item $X->B<setWMRootPropertyStrings>(I<$prop>,I<$type>,I<$strings>)

Set set property, I<$prop>, to the string values, I<$strings>.
I<$type> must be one of C<STRING>, C<COMPOUND_TEXT> or C<UTF8_STRING>.
When the resulting property must be null terminated rather than null
separated, it may be necessary to add '' to the end of the list of
strings.

=cut

sub _strings_OK {
    my $strings = shift;
    foreach (@$strings) { return 0 unless _string_OK($_) }
    return 1;
}

sub setWMRootPropertyStrings {
    my($self,$prop,$type,$strings) = @_;
    $self->setWMRootPropertyEncode($prop,8,sub{
	    my($type,$strings) = @_;
	    return STRING=>join(pack('C',0),map{Encode::encode('iso-8859-1',$_)} @$strings)
		if $type eq 'STRING' or
		  ($type eq 'COMPOUND_TEXT' and _strings_OK($strings));
	    return $type=>join(pack('C',0),map{Encode::encode('x11-compound-text',$_)} @$strings)
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return UTF8_STRING=>join(pack('C',0),map{Encode::encode('UTF-8',$_)} @$strings);
    },$type,$strings);
}

=item $X->B<setWMRootPropertyInt>(I<$prop>,I<$type>,I<$integer>)

Sets the property, I<$prop>, to the integer value, I<$integer>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMRootPropertyInt {
    my($self,$prop,$type,$integer) = @_;
    $self->setWMRootPropertyEncode($prop,32,sub{
	    my($type,$integer) = @_;
	    return $type, pack('L',$integer);
    },$type,$integer);
}

=item $X->B<setWMRootPropertyInts>(I<$prop>,I<$type>,I<@integers>)

Sets the property, I<$prop>, to the integer values, I<@integers>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMRootPropertyInts {
    my($self,$prop,$type,$integers) = @_;
    $self->setWMRootPropertyEncode($prop,32,sub{
	    my($type,$integers) = @_;
	    return $type, pack('L*',@$integers);
    },$type,$integer);
}

=item $X->B<setWMRootPropertyAtom>(I<$prop>,I<$atom>)

Sets the property, I<$prop>, to the atom named I<$atom>.
This results in a C<ATOM> type property.

=cut

sub setWMRootPropertyAtom {
    my($self,$prop,$atom) = @_;
    $self->setWMRootPropertyEncode($prop,32,sub{
	    return ATOM=>pack('L',$self->atom(shift));
    },$atom);
}

=item $X->B<setWMRootPropertyAtoms>(I<$prop>,I<@atoms>)

Sets the property, I<$prop>, to the list of atoms named by I<@atoms>.
This results in a C<ATOM> type property.

=cut

sub setWMPropertyAtoms {
    my($self,$prop,$atoms) = @_;
    $self->setWMRootPropertyEncode($prop,32,sub{
	    return ATOM=>pack('L*',map{$self->atom($_)}@{$_[0]});
    },$atoms);
}

=back

=item $X->B<setWMPropertyEncode>(I<$prop>,I<$format>,I<$encode>,I<@args>)

Provides a method for setting an encoded property to the root window.  The
property has atom name, I<$prop>, format, I<$format>, and encoder,
I<$encode> is a C<CODE> reference that accepts the arguments, I<@args>,
and returns encoded packed data.  This method is used by subsequent
methods below:

=cut

sub setWMPropertyEncode {
    my($self,$window,$prop,$format,$encode,@args) = @_;
    if (@args) {
	my($type,$data) = &{$encode}(@args);
	$self->setProperty($window,$prop,$type,$format,$data);
    } else {
	$self->deleteProperty($window,$prop);
    }
}

=over

=item $X->B<setWMPropertyString>(I<$window>,I<$prop>,I<$type>,I<$string>)

Set set property, I<$prop>, to the string value, I<$string>.
I<$type> must be one of C<STRING>, C<COMPOUND_TEXT> or C<UTF8_STRING>.
When the resulting property must be null terminated, it may be necessary
to append the null character to the end of the string, I<$string>.

=cut

sub setWMPropertyString {
    my($self,$window,$prop,$type,$string) = @_;
    $self->setWMPropertyEncode($window,$prop,8,sub{
	    my($type,$string) = @_;
	    return STRING=>Encode::encode('iso-8859-1',$string)
		if $type eq 'STRING' or
		  ($type eq 'COMPOUND_TEXT' and _string_OK($string));
	    return $type=>Encode::encode('x11-compound-text',$string)
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return UTF8_STRING=>Encode::encode('UTF-8',$string);
    },$type,$string);
}

=item $X->B<setWMPropertyStrings>(I<$window>,I<$prop>,I<@strings>)

Set set property, I<$prop>, to the string values, I<$strings>.
I<$type> must be one of C<STRING>, C<COMPOUND_TEXT> or C<UTF8_STRING>.
When the resulting property must be null terminated rather than null
separated, it may be necessary to add '' to the end of the list of
strings.

=cut

sub setWMPropertyStrings {
    my($self,$window,$prop,$type,$strings) = @_;
    $self->setWMPropertyEncode($window,$prop,8,sub{
	    my($type,$strings) = @_;
	    return STRING=>join(pack('C',0),map{Encode::encode('iso-8859-1',$_)} @$strings)
		if $type eq 'STRING' or
		  ($type eq 'COMPOUND_TEXT' and _strings_OK($strings));
	    return $type=>join(pack('C',0),map{Encode::encode('x11-compound-text',$_)} @$strings)
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return UTF8_STRING=>join(pack('C',0),map{Encode::encode('UTF-8',$_)} @$strings);
    },$type,$strings);
}

=item $X->B<setWMPropertyInt>(I<$window>,I<$prop>,I<$type>,I<$integer>)

Sets the property, I<$prop>, to the integer value, I<$integer>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMPropertyInt {
    my($self,$window,$prop,$type,$integer) = @_;
    $self->setWMPropertyEncode($window,$prop,32,sub{
	    my($type,$integer) = @_;
	    return $type, pack('L',$integer);
    },$type,$integer);
}

=item $X->B<setWMPropertyInts>(I<$window>,I<$prop>,I<@integers>)

Sets the property, I<$prop>, to the integer values, I<@integers>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMPropertyInts {
    my($self,$window,$prop,$type,$integers) = @_;
    $self->setWMPropertyEncode($window,$prop,32,sub{
	    my($type,$integers) = @_;
	    return $type, pack('L*',@$integers);
    },$type,$integer);
}

=item $X->B<setWMPropertyAtom>(I<$window>,I<$prop>,I<$atom>)

Sets the property, I<$prop>, to the atom named I<$atom>.
This results in a C<ATOM> type property.

=cut

sub setWMPropertyAtom {
    my($self,$window,$prop,$atom) = @_;
    $self->setWMPropertyEncode($window,$prop,32,sub{
	    return ATOM=>pack('L',$self->atom(shift));
    },$atom);
}

=item $X->B<setWMPropertyAtoms>(I<$window>,I<$prop>,I<$atoms>)

Sets the property, I<$prop>, to the list of atoms named by I<@$atoms>.
This results in a C<ATOM> type property.

=cut

sub setWMPropertyAtoms {
    my($self,$window,$prop,$atoms) = @_;
    $self->setWMPropertyEncode($window,$prop,32,sub{
	    return ATOM=>pack('L*',map{$self->atom($_)}@{$_[0]});
    },$atoms);
}

=back

=back

=head2 Sending Events

The following methods are used for sending events:

=over

=item $X->B<clientMessage>(I<$targ>,I<$win>,I<$type>,I<$data>)

Send a client message to a window, I<$targ>, with the specified window as
I<$win>, client meesage type the atom name I<$type>, and 20-bytes of
packed client message data, I<$data>.  The mask used is C<StrutureNotify>
and C<SubstructureNotify>.

=cut

sub clientMessage {
    my($X,$target,$window,$type,$data) = @_;
    $target = $X->root unless $target;
    $window = $X->root unless $window;
    $X->SendEvent($target, 0,
	    $X->pack_event_mask(qw(
		    StructureNotify
		    SubstructureNotify
		    SubstructureRedirect)),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$window,
		format=$format,
		type=>
	    ));
    $X->flush;
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::Protocol(3pm)>,
L<X11::Protocol::AnyEvent(3pm)>.

# vim: set sw=4 tw=74 fo=tcqlorn:
