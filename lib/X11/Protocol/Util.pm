package X11::Protocol::Util;
use base qw(X11::Protocol::AnyEvent);
use X11::Protocol;
use Encode;
use Encode::Unicode;
use Encode::X11;
use Exporter;
use strict;
use warnings;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 0.01;
@ISA = ('Exporter');

@EXPORT_OK = qw(
        :encdec
        :string
        :text
        :uint
        :int
        :atom
        :bits
        :all

        getWMRootPropertyDecode
        getWMRootPropertyString
        getWMRootPropertyStrings
        getWMRootPropertyTermString
        getWMRootPropertyTermStrings
        getWMRootPropertyUint
        getWMRootPropertyUints
        getWMRootPropertyInt
        getWMRootPropertyInts
        getWMRootPropertyAtom
        getWMRootPropertyAtoms

        getWMPropertyDecode
        getWMPropertyString
        getWMPropertyStrings
        getWMPropertyTermString
        getWMPropertyTermStrings
        getWMPropertyUint
        getWMPropertyUints
        getWMPropertyInt
        getWMPropertyInts
        getWMPropertyAtom
        getWMPropertyAtoms
        getWMPropertyBits

        setWMRootPropertyEncode
        setWMRootPropertyText
        setWMRootPropertyTexts
        setWMRootPropertyTermText
        setWMRootPropertyTermTexts
        setWMRootPropertyString
        setWMRootPropertyStrings
        setWMRootPropertyTermString
        setWMRootPropertyTermStrings
        setWMRootPropertyUint
        setWMRootPropertyUints
        setWMRootPropertyInt
        setWMRootPropertyInts
        setWMRootPropertyAtom
        setWMRootPropertyAtoms

        setWMPropertyEncode
        setWMPropertyText
        setWMPropertyTexts
        setWMPropertyTermText
        setWMPropertyTermTexts
        setWMPropertyString
        setWMPropertyStrings
        setWMPropertyTermString
        setWMPropertyTermStrings
        setWMPropertyUint
        setWMPropertyUints
        setWMPropertyInt
        setWMPropertyInts
        setWMPropertyAtom
        setWMPropertyAtoms
);

%EXPORT_TAGS = (
        ':encdec' => [qw(
                getWMRootPropertyDecode
                getWMPropertyDecode
                setWMRootPropertyEncode
                setWMPropertyEncode
            )],
        ':string' => [qw(
                getWMRootPropertyString
                getWMRootPropertyStrings
                getWMRootPropertyTermString
                getWMRootPropertyTermStrings
                getWMPropertyString
                getWMPropertyStrings
                getWMPropertyTermString
                getWMPropertyTermStrings
                setWMRootPropertyString
                setWMRootPropertyStrings
                setWMRootPropertyTermString
                setWMRootPropertyTermStrings
                setWMPropertyString
                setWMPropertyStrings
                setWMPropertyTermString
                setWMPropertyTermStrings
            )],
        ':text' => [qw(
                setWMRootPropertyText
                setWMRootPropertyTexts
                setWMRootPropertyTermText
                setWMRootPropertyTermTexts
                setWMPropertyText
                setWMPropertyTexts
                setWMPropertyTermText
                setWMPropertyTermTexts
            )],
        ':uint' => [qw(
                getWMRootPropertyUint
                getWMRootPropertyUints
                getWMPropertyUint
                getWMPropertyUints
                setWMRootPropertyUint
                setWMRootPropertyUints
                setWMPropertyUint
                setWMPropertyUints
            )],
        ':int' => [qw(
                getWMRootPropertyInt
                getWMRootPropertyInts
                getWMPropertyInt
                getWMPropertyInts
                setWMRootPropertyInt
                setWMRootPropertyInts
                setWMPropertyInt
                setWMPropertyInts
            )],
        ':atom' => [qw(
                getWMRootPropertyAtom
                getWMRootPropertyAtoms
                getWMPropertyAtom
                getWMPropertyAtoms
                setWMRootPropertyAtom
                setWMRootPropertyAtoms
                setWMPropertyAtom
                setWMPropertyAtoms
            )],
        ':bits' => [qw(
                getWMPropertyBits
            )],
        ':all' => [qw(
                :encdec
                :string
                :text
                :uint
                :int
                :atom
                :bits
            )],
);



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

=item B<getRootProperty>(I<$X>,I<$root>,I<$prop>,I<$type>) => I<$data>, I<$rtype>, I<$format>

Gets a property, I<$prop>, of type, I<$type>, from a root window,
I<$root>, and returns its full-length packed data representation,
I<$data>, type atom name, I<$rtype>, and format, I<$format>.  Returns an
empty list when the property does not exist on the root window, I<$root>.
When zero or unspecified, I<$root> defaults to C<$X-E<gt>root>.  When
unspecified, I<$type> defaults to C<None>.

=cut

sub getRootProperty {
    my($X,$root,$prop,$type) = @_;
    $root = $X->root unless $root;
    my $atom = $X->atom($prop);
    $type = 0 unless $type;
    $type = 0 if $type eq 'None';
    $type = $X->atom($type) unless $type =~ m{^\d+$};
    my($data,$rtype,$format,$after) = $X->GetProperty($root,$atom,$type,0,1);
    return () unless $format;
    if ($after) {
        my $first = $data;
        ($data,$rtype,$format,$after) = $X->GetProperty($root,$atom,$type,1,($after+3)>>2);
        return () unless $format;
        $data = $first.$data;
    }
    return ($data, $rtype, $format);
}

=over

=item B<getWMRootPropertyDecode>(I<$X>,I<$prop>,I<$decode>,I<$root>) => I<$value>

Provides a method for obtaining a decoded property from the root window.
The property has atom name, I<$prop>, and decoder, I<$decode> is a C<CODE>
reference that accepts the packed data as an argument and returns the
decoded data.  This method is used by subsequent methods below:

=cut

sub getWMRootPropertyDecode {
    my ($X,$prop,$decode,$root) = @_;
    if (my($data,$rtype,$format) = getRootProperty($X,$root,$prop)) {
	return &{$decode}($data,$rtype,$format);
    }
    warn "Could not retrieve property $prop!";
    return undef;
}

=over

=item B<getWMRootPropertyString>(I<$X>,I<$prop>,I<$root>) => I<$value>

Returns I<$value> as a single scalar string value.  This method handles
C<STRING>, C<COMPOUND_TEXT> and C<UTF8_STRING> properties.  Any property
of another type is treated as C<UTF8_STRING>.  This method automatically
handles null terminated strings.

=cut

sub getWMRootPropertyString {
    my ($X,$prop,$root) = @_;
    return getWMRootPropertyDecode($X,$prop,sub{
	    my($data,$type,$format) = @_;
	    return Encode::decode('iso-8859-1',unpack('Z*',$data."\x00"))
		if $type eq 'STRING';
	    return Encode::decode('x11-compound-text',unpack('Z*',$data."\x00"))
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return Encode::decode('UTF-8',unpack('Z*',$data."\x00"));
    },$root);
}

=item B<getWMRootPropertyStrings>(I<$X>,I<$prop>,I<$root>) => I<$value>

Returns I<$value> as a reference to an array of strings.  This method
handles C<STRING>, C<COMPOUND_TEXT> and C<UTF8_STRING> properties.  Any
property of another type is treated as C<UTF8_STRING>.  This method
automatically handles null terminated strings (vs. null separated
strings); however, if a list of strings has a zero-length string as the
last element in the list, it will be truncated from the I<$value> array.

=cut

sub getWMRootPropertyStrings {
    my ($X,$prop,$root) = @_;
    return getWMRootPropertyDecode($X,$prop,sub{
	    my($data,$type) = @_;
	    return [ map{Encode::decode('iso-8859-1',$_)} unpack('(Z*)*',$data."\x00") ]
		if $type eq 'STRING';
	    return [ map{Encode::decode('x11-compound-text',$_)} unpack('(Z*)*',$data."\x00") ]
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return [ map{Encode::decode('UTF-8',$_)} unpack('(Z*)*',$data."\x00") ];
    },$root);
}

=item B<getWMRootPropertyTermString>(I<$X>,I<$prop>,I<$root>) => I<$value>

Like getWMRootPropertyString() but for null-terminated strings instead of
null-separated strings.

=cut

sub getWMRootPropertyTermString {
    my ($X,$prop,$root) = @_;
    return getWMRootPropertyDecode($X,$prop,sub{
	    my($data,$type,$format) = @_;
	    return Encode::decode('iso-8859-1',unpack('Z*',$data))
		if $type eq 'STRING';
	    return Encode::decode('x11-compound-text',unpack('Z*',$data))
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return Encode::decode('UTF-8',unpack('Z*',$data));
    },$root);
}

=item B<getWMRootPropertyTermStrings>(I<$X>,I<$prop>,I<$root>) => I<$value>

Like getWMRootPropertyStrings() but for null-terminated strings instead of
null-separated strings.

=cut

sub getWMRootPropertyTermStrings {
    my ($X,$prop,$root) = @_;
    return getWMRootPropertyDecode($X,$prop,sub{
	    my($data,$type) = @_;
	    return [ map{Encode::decode('iso-8859-1',$_)} unpack('(Z*)*',$data) ]
		if $type eq 'STRING';
	    return [ map{Encode::decode('x11-compound-text',$_)} unpack('(Z*)*',$data) ]
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return [ map{Encode::decode('UTF-8',$_)} unpack('(Z*)*',$data) ];
    },$root);
}

=item B<getWMRootPropertyUint>(I<$X>,I<$prop>,I<$root>) => I<$value>

Returns I<$value> as a single scalar unsigned integer value.

=cut

sub getWMRootPropertyUint {
    my ($X,$prop,$root) = @_;
    return getWMRootPropertyDecode($X,$prop,
	sub{ return unpack('L',shift); }, $root);
}

=item B<getWMRootPropertyUints>(I<$X>,I<$prop>,I<$root>) => I<$value>

Returns I<$value> as an reference to an array of unsigned integer values.

=cut

sub getWMRootPropertyUints {
    my ($X,$prop,$root) = @_;
    return getWMRootPropertyDecode($X,$prop,
	sub{ return [ unpack('L*',shift) ]; },$root);
}

=item B<getWMRootPropertyInt>(I<$X>,I<$prop>,I<$root>) => I<$value>

Returns I<$value> as a single scalar integer value.

=cut

sub getWMRootPropertyInt {
    my ($X,$prop,$root) = @_;
    return getWMRootPropertyDecode($X,$prop,
	sub{ return unpack('l',shift); }, $root);
}

=item B<getWMRootPropertyInts>(I<$X>,I<$prop>,I<$root>) => I<$value>

Returns I<$value> as an reference to an array of integer values.

=cut

sub getWMRootPropertyInts {
    my ($X,$prop,$root) = @_;
    return getWMRootPropertyDecode($X,$prop,
	sub{ return [ unpack('l*',shift) ]; },$root);
}

=item B<getWMRootPropertyAtom>(I<$X>,I<$prop>,I<$root>) => I<$value>

Returns I<$value> as a single scalar atom name.

=cut

sub getWMRootPropertyAtom {
    my ($X,$prop,$root) = @_;
    return getWMRootPropertyDecode($X,$prop,
	sub{ return $X->atom_name(unpack('L',shift)); },$root);
}

=item B<getWMRootPropertyAtoms>(I<$X>,I<$prop>,I<$root>) => I<$value>

Returns I<$value> as a reference to a hash of atom names.  Where
I<@atoms> is the list of returned atoms, the hash reference is:

 map{$X->atom_name($_)=>1} @atoms


=cut

sub getWMRootPropertyAtoms {
    my ($X,$prop,$root) = @_;
    return getWMRootPropertyDecode($X,$prop,
	sub{ return { map{$X->atom_name($_)=>1} unpack('L',shift) }; },$root);
}

=back

=back

=item B<getProperty>(I<$X>,I<$win>,I<$prop>,I<$type>) => I<$data>, I<$rtype>, I<$format>

Get a property from a window and return its full-length packed data
representation.  Returns C<undef> if the property does not exist.

Gets a property, I<$prop>, of type, I<$type>, from a window,
I<$window>, and returns its full-length packed data representation,
I<$data>, type atom name, I<$rtype>, and format, I<$format>.  Returns an
empty list when the property does not exist on the window, or when an
error occurs (e.g. I<$window> has been destroyed).  When zero or
unspecified, I<$window> defaults to C<$X-E<gt>root>.  When unspecified,
I<$type> defaults to C<None>.

=cut

sub getProperty {
    my($X,$window,$prop,$type) = @_;
    return () unless $window;
    my $atom = $X->atom($prop);
    $type = 0 unless $type;
    $type = 0 if $type eq 'None';
    $type = $X->atom_($type) unless $type =~ m{^\d+$};
    my($res) = $X->robust_req(GetProperty=>$window,$atom,$type,0,1);
    return () unless ref $res and $res->[2];
    my($data,$rtype,$format,$after) = @$res;
    if ($after) {
        ($res) = $X->robust_req(GetProperty=>$window,$atom,$type,1,($after+3)>>2);
        return () unless ref $res and $res->[2];
        $data .= $ref->[0];
    }
    return ($data, $rtype, $format);
}

=over

=item B<getWMPropertyDecode>(I<$X>,I<$window>,I<$prop>,I<$decode>)

Provides a method for obtaining a decoded property from a specified
window, I<$window>.  When undefined or zero, I<$window> defaults to the
active window.  The property has atom name, I<$prop>, and decoder,
I<$decode> is a C<CODE> reference that accepts the packed data as an
argument and returns the decoded data.  This method is usede by subsequent
methods below:

=cut

sub getWMPropertyDecode {
    my ($X,$window,$prop,$decode) = @_;
    $window = $X->{_NET_ACTIVE_WINDOW} unless $window;
    $window = $X->root unless $window;
    if (my($data,$rtype) = getProperty($X,$window, $prop)) {
	$X->{windows}{$window}{$prop} = &{$decode}($data,$rtype);
    } else {
	delete $X->{windows}{$window}{$prop};
    }
    return $X->{windows}{$window}{$prop};

}

=over

=item B<getWMPropertyString>(I<$X>,I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a single scalar string value.  This method handles
C<STRING>, C<COMPOUND_TEXT> and C<UTF8_STRING> properties.  Any property
of another type is treated as C<UTF8_STRING>.  This method automatically
handles null terminated strings.

=cut

sub getWMPropertyString {
    my ($X,$window,$prop) = @_;
    return getWMPropertyDecode($X,$window,$prop,sub{
	    my($data,$type) = @_;
	    return Encode::decode('iso-8859-1',unpack('Z*',$data."\x00"))
		if $type eq 'STRING';
	    return Encode::decode('x11-compound-text',unpack('Z*',$data."\x00"))
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return Encode::decode('UTF-8',unpack('Z*',$data."\x00"));
    });
}

=item B<getWMPropertyStrings>(I<$X>,I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a reference to an array of strings.  This method
handles C<STRING>, C<COMPOUND_TEXT> and C<UTF8_STRING> properties.  Any
property of another type is treated as C<UTF8_STRING>.  This method
automatically handles null terminated strings (vs. null separated
strings); however, if a list of strings has a zero-length string as the
last element in the list, it will be truncated from the I<$value> array.

=cut

sub getWMPropertyStrings {
    my ($X,$window,$prop) = @_;
    return getWMPropertyDecode($X,$window,$prop,sub{
	    my($data,$type) = @_;
	    return [ map{Encode::decode('iso-8859-1',$_)} unpack('(Z*)*',$data."\x00") ]
		if $type eq 'STRING';
	    return [ map{Encode::decode('x11-compound-text',$_)} unpack('(Z*)*',$data."\x00") ]
		if $type eq 'COMPOUND_TEXT';
	    warn "type '$type' defaults to UTF8_STRING"
		if $type ne 'UTF8_STRING';
	    return [ map{Encode::decode('UTF-8',$_)} unpack('(Z*)*',$data."\x00") ];
    });
}

=item B<getWMPropertyTermString>(I<$X>,I<$prop>,I<$root>) => I<$value>

Like getWMPropertyString() but for null-terminated strings instead of
null-separated strings.

=cut

sub getWMPropertyTermString {
    my ($X,$window,$prop) = @_;
    return getWMPropertyDecode($X,$window,$prop,sub{
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

=item B<getWMPropertyTermStrings>(I<$X>,I<$prop>,I<$root>) => I<$value>

Like getWMPropertyStrings() but for null-terminated strings instead of
null-separated strings.

=cut

sub getWMPropertyTermStrings {
    my ($X,$window,$prop) = @_;
    return getWMPropertyDecode($X,$window,$prop,sub{
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

=item B<getWMPropertyUint>(I<$X>,I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a single scalar unsigned integer value.

=cut

sub getWMPropertyUint {
    my ($X,$window,$prop) = @_;
    return getWMPropertyDecode($X,$window,$prop,
	sub{ return unpack('L',shift); });
}

=item B<getWMPropertyUints>(I<$X>,I<$window>,I<$prop>) => I<$value>

Returns I<$value> as an reference to an array of unsigned integer values.

=cut

sub getWMPropertyUints {
    my ($X,$window,$prop) = @_;
    return getWMPropertyDecode($X,$window,$prop,
	sub{ return [ unpack('L*',shift) ]; });
}

=item B<getWMPropertyInt>(I<$X>,I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a single scalar integer value.

=cut

sub getWMPropertyInt {
    my ($X,$window,$prop) = @_;
    return getWMPropertyDecode($X,$window,$prop,
	sub{ return unpack('l',shift); });
}

=item B<getWMPropertyInts>(I<$X>,I<$window>,I<$prop>) => I<$value>

Returns I<$value> as an reference to an array of integer values.

=cut

sub getWMPropertyInts {
    my ($X,$window,$prop) = @_;
    return getWMPropertyDecode($X,$window,$prop,
	sub{ return [ unpack('l*',shift) ]; });
}

=item B<getWMPropertyAtom>(I<$X>,I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a single scalar atom name.

=cut

sub getWMPropertyAtom {
    my ($X,$window,$prop) = @_;
    return getWMPropertyDecode($X,$window,$prop,
	sub{ return $X->atom_name(unpack('L',shift)); });
}

=item B<getWMPropertyAtoms>(I<$X>,I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a reference to a hash of atom names.  Where
I<@atoms> is the list of returned atoms, the hash reference is:

 map{$X->atom_name($_)=>1} @atoms

=cut

sub getWMPropertyAtoms {
    my ($X,$window,$prop) = @_;
    return getWMPropertyDecode($X,$window,$prop,
	sub{ return { map{$X->atom_name($_)=>1} unpack('L',shift) }; });
}

=item B<getWMPropertyBits>(I<$X>,I<$window>,I<$prop>) => I<$value>

Returns I<$value> as a reference to an array of bit values or C<undef>
when the property, I<$prop>, does not exist on I<$window>.

=cut

sub getWMPropertyBits {
    my ($X,$window,$prop) = @_;
    return getWMPropertyDecode($X,$window,$prop,
	sub{ return [ map{unpack('b*',pack('V',$_))} unpack('L*',shift) ]; });
}

=back

=back

=back

=head2 Setting Properties

The following methods are used to set properties on windows:

=over

=item B<setRootProperty>(I<$X>,I<$prop>,I<$type>,I<$format>,I<$data>)

Set a property on a root window.  C<$X-E<gt>root> is the root window on
which to set the property.
I<$prop> is the name or atom of the property.  I<$type> is the name or
atom of the property type.  I<$format> is 8, 16 or 32 specifying the
format of the property.  I<$data> is the packed data for the property.

=cut

sub setRootProperty {
    my($X,$prop,$type,$format,$data) = @_;
    $prop = $X->atom($prop) unless $prop =~ m{^\d+$};
    $type = $X->atom($type) unless $type =~ m{^\d+$};
    $X->ChangeProperty($X->root,$prop,$type,$format,Replace=>$data);
}

=item B<deleteProperty>(I<$X>,I<$prop>)

Deletes the property with name or atom I<$prop> from the root window,
C<$X-E<gt>root>.

=cut

sub deleteRootProperty {
    my($X,$prop) = @_;
    $prop = $X->atom($prop) unless $prop =~ m{^\d+$};
    $X->DeleteProperty($X->root,$prop);
}

=over

=item B<setWMRootPropertyEncode>(I<$X>,I<$prop>,I<$encode>,I<@args>)

Provides a method for setting an encoded property to the root window.  The
property has atom name, I<$prop>, format, I<$format>, and encoder,
I<$encode> is a C<CODE> reference that accepts the argument, I<$args>, and
returns a type and encoded packed data.  This method is used by subsequent
methods below:

=cut

sub setWMRootPropertyEncode {
    my($X,$prop,$encode,@args) =  @_;
    if (@args) {
	my ($type,$format,$data) = &{$encode}(@args);
	setRootProperty($X,$prop,$type,$format,$data);
    } else {
	deleteRootProperty($X,$prop);
    }
}

=over

=item B<setWMRootPropertyText>(I<$X>,I<$prop>,I<$style>,I<$string>)

Set the property, I<$prop>, to the string value, I<$string>.
I<$style> must be one of C<StringStyle>, C<StdICCStyle>,
C<CompoundTextStyle> or C<Utf8StringStyle>.
The resulting property will be null-separated.

=cut

sub _string_OK {
    my $string = shift;
    Encode::encode('iso-8859-1', $string, Encode::FB_QUIET);
    return (length($string) == 0);
}

sub setWMRootPropertyText {
    my($X,$prop,$style,$string) = @_;
    setWMRootPropertyEncode($X,$prop,sub{
	    my($style,$string) = @_;
	    return STRING=>8,Encode::encode('iso-8859-1',$string)
		if $style eq 'StringStyle' or
		  ($style eq 'StdICCStyle' and _string_OK($string));
	    return COMPOUND_TEXT=>8,Encode::encode('x11-compound-text',$string)
		if $style eq 'StdICCStyle' or $style eq 'CompoundTextStyle';
	    warn "style '$style' defaults to Utf8StringStyle"
		if $style ne 'Utf8StringStyle';
	    return UTF8_STRING=>8,Encode::encode('UTF-8',$string);
    },$style,$string);
}

=item B<setWMRootPropertyTexts>(I<$X>,I<$prop>,I<$style>,I<$strings>)

Set the property, I<$prop>, to the string values, I<$strings>.
I<$style> must be one of C<StringStyle>, C<StdICCStyle>,
C<CompoundTextStyle> or C<Utf8StringStyle>.
The resulting property will be null-separated.

=cut

sub _strings_OK {
    my $strings = shift;
    foreach (@$strings) { return 0 unless _string_OK($_) }
    return 1;
}

sub setWMRootPropertyTexts {
    my($X,$prop,$style,$strings) = @_;
    setWMRootPropertyEncode($X,$prop,sub{
	    my($style,$strings) = @_;
	    return STRING=>8,join(pack('C',0),map{Encode::encode('iso-8859-1',$_)} @$strings)
		if $style eq 'StringStyle' or
		  ($style eq 'StdICCStyle' and _strings_OK($strings));
	    return $style=>8,join(pack('C',0),map{Encode::encode('x11-compound-text',$_)} @$strings)
		if $style eq 'StdICCStyle' or $style eq 'CompoundTextStyle';
	    warn "style '$style' defaults to Utf8StringStyle"
		if $style ne 'Utf8StringStyle';
	    return UTF8_STRING=>8,join(pack('C',0),map{Encode::encode('UTF-8',$_)} @$strings);
    },$style,$strings);
}

=item B<setWMRootPropertyTermText>(I<$X>,I<$prop>,I<$style>,I<$string>)

Set the property, I<$prop>, to the string value, I<$string>.
I<$style> must be one of C<StringStyle>, C<StdICCStyle>,
C<CompoundTextStyle> or C<Utf8StringStyle>.
The resulting property will be null-terminated.

=cut

sub setWMRootPropertyTermText {
    my($X,$prop,$style,$string) = @_;
    setWMRootPropertyEncode($X,$prop,sub{
	    my($style,$string) = @_;
	    return STRING=>8,Encode::encode('iso-8859-1',$string)."\x00"
		if $style eq 'StringStyle' or
		  ($style eq 'StdICCStyle' and _string_OK($string));
	    return COMPOUND_TEXT=>8,Encode::encode('x11-compound-text',$string)."\x00"
		if $style eq 'StdICCStyle' or $style eq 'CompoundTextStyle';
	    warn "style '$style' defaults to Utf8StringStyle"
		if $style ne 'Utf8StringStyle';
	    return UTF8_STRING=>8,Encode::encode('UTF-8',$string)."\x00";
    },$style,$string);
}

=item B<setWMRootPropertyTermTexts>(I<$X>,I<$prop>,I<$style>,I<$strings>)

Set the property, I<$prop>, to the string values, I<$strings>.
I<$style> must be one of C<StringStyle>, C<StdICCStyle>,
C<CompoundTextStyle> or C<Utf8StringStyle>.
The resulting property will be null-terminated.

=cut

sub setWMRootPropertyTermTexts {
    my($X,$prop,$style,$strings) = @_;
    setWMRootPropertyEncode($X,$prop,sub{
	    my($style,$strings) = @_;
	    return STRING=>8,join(pack('C',0),map{Encode::encode('iso-8859-1',$_)} @$strings)."\x00"
		if $style eq 'StringStyle' or
		  ($style eq 'StdICCStyle' and _strings_OK($strings));
	    return $style=>8,join(pack('C',0),map{Encode::encode('x11-compound-text',$_)} @$strings)."\x00"
		if $style eq 'StdICCStyle' or $style eq 'CompoundTextStyle';
	    warn "style '$style' defaults to Utf8StringStyle"
		if $style ne 'Utf8StringStyle';
	    return UTF8_STRING=>8,join(pack('C',0),map{Encode::encode('UTF-8',$_)} @$strings)."\x00";
    },$style,$strings);
}

=item B<setWMRootPropertyString>(I<$X>,I<$prop>,I<$type>,I<$string>)

Set set property, I<$prop>, to the string value, I<$string>.
I<$type> must be one of C<STRING>, C<COMPOUND_TEXT> or C<UTF8_STRING>.
When the resulting property must be null terminated, it may be necessary
to append the null character to the end of the string, I<$string>.

=cut

use constant {
    StyleMapping => {
        STRING=>'StringStyle',
        COMPOUND_TEXT=>'StdICCStyle',
        UTF8_STRING=>'Utf8StringStyle',
    },
};

sub _map_style {
    my $type = shift;
    $type = '' unless $type;
    my $style = StyleMapping()->{$type};
    $style = 'Utf8StringStyle' unless $style;
    return $style;
}

sub setWMRootPropertyString {
    my @args = @_; $arsg[2] = _map_style($args[2]);
    return setWMRootPropertyText(@args);
}

=item B<setWMRootPropertyStrings>(I<$X>,I<$prop>,I<$type>,I<$strings>)

Set set property, I<$prop>, to the string values, I<$strings>.
I<$type> must be one of C<STRING>, C<COMPOUND_TEXT> or C<UTF8_STRING>.
When the resulting property must be null terminated rather than null
separated, it may be necessary to add '' to the end of the list of
strings.

=cut

sub setWMRootPropertyStrings {
    my @args = @_; $arsg[2] = _map_style($args[2]);
    return setWMRootPropertyTexts(@args);
}

=item B<setWMRootPropertyTermString>(I<$X>,I<$prop>,I<$type>,I<$string>)

Like setWMRootPropertyString() except for null-terminated strings instead
of null-separated strings.

=cut

sub setWMRootPropertyTermString {
    my @args = @_; $arsg[2] = _map_style($args[2]);
    return setWMRootPropertyTermText(@args);
}

=item B<setWMRootPropertyTermStrings>(I<$X>,I<$prop>,I<$type>,I<$strings>)

Like setWMRootPropertyStrings() except for null-terminated strings instead
of null-separated strings.

=cut

sub setWMRootPropertyTermStrings {
    my @args = @_; $arsg[2] = _map_style($args[2]);
    return setWMRootPropertyTermTexts(@args);
}

=item B<setWMRootPropertyUint>(I<$X>,I<$prop>,I<$type>,I<$integer>)

Sets the property, I<$prop>, to the integer value, I<$integer>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMRootPropertyUint {
    my($X,$prop,$type,$integer) = @_;
    setWMRootPropertyEncode($X,$prop,sub{
	    my($type,$integer) = @_;
	    return $type, 32, pack('L',$integer);
    },$type,$integer);
}

=item B<setWMRootPropertyUints>(I<$X>,I<$prop>,I<$type>,I<@integers>)

Sets the property, I<$prop>, to the integer values, I<@integers>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMRootPropertyUints {
    my($X,$prop,$type,$integers) = @_;
    setWMRootPropertyEncode($X,$prop,sub{
	    my($type,$integers) = @_;
	    return $type, 32, pack('L*',@$integers);
    },$type,$integer);
}

=item B<setWMRootPropertyInt>(I<$X>,I<$prop>,I<$type>,I<$integer>)

Sets the property, I<$prop>, to the integer value, I<$integer>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMRootPropertyInt {
    my($X,$prop,$type,$integer) = @_;
    setWMRootPropertyEncode($X,$prop,sub{
	    my($type,$integer) = @_;
	    return $type, 32, pack('l',$integer);
    },$type,$integer);
}

=item B<setWMRootPropertyInts>(I<$X>,I<$prop>,I<$type>,I<@integers>)

Sets the property, I<$prop>, to the integer values, I<@integers>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMRootPropertyInts {
    my($X,$prop,$type,$integers) = @_;
    setWMRootPropertyEncode($X,$prop,sub{
	    my($type,$integers) = @_;
	    return $type, 32, pack('l*',@$integers);
    },$type,$integer);
}

=item B<setWMRootPropertyAtom>(I<$X>,I<$prop>,I<$atom>)

Sets the property, I<$prop>, to the atom named I<$atom>.
This results in a C<ATOM> type property.

=cut

sub setWMRootPropertyAtom {
    my($X,$prop,$atom) = @_;
    setWMRootPropertyEncode($X,$prop,sub{
	    return ATOM=>32, pack('L',$X->atom(shift));
    },$atom);
}

=item B<setWMRootPropertyAtoms>(I<$X>,I<$prop>,I<@atoms>)

Sets the property, I<$prop>, to the list of atoms named by I<@atoms>.
This results in a C<ATOM> type property.

=cut

sub setWMRootPropertyAtoms {
    my($X,$prop,$atoms) = @_;
    setWMRootPropertyEncode($X,$prop,sub{
	    return ATOM=>32, pack('L*',map{$X->atom($_)}@{$_[0]});
    },$atoms);
}

=back

=back

=item B<setProperty>(I<$X>,I<$window>,I<$prop>,I<$type>,I<$format>,I<$data>)

Set a property on a window.  I<$window> is the window on which to set the
property; defaults to the default root window when zero or C<undef>.
I<$prop> is the name of the property.  I<$type> is the name of the
property type.  I<$format> is 8, 16 or 32 specifying the format of the
property.  I<$data> is the packed data for the property.

=cut

sub setProperty {
    my($X,$window,$prop,$type,$format,$data) = @_;
    $window = $X->root unless $window;
    $prop = $X->atom($prop) unless $prop =~ m{^\d+$};
    $type = $X->atom($type) unless $type =~ m{^\d+$};
    my($res) = $X->robust_req(ChangeProperty=>$window,$prop,$type,$format,Replace=>$data);
    return ref $res ? 1 : 0;
}

=item B<deleteProperty>(I<$X>,I<$window>,I<$prop>)

Deletes the property named I<$prop> from the window, I<$window>.
I<$window>
defaults to the default root window when zero or C<undef>.

=cut

sub deleteProperty {
    my($X,$window,$prop) = @_;
    $window = $X->root unless $window;
    $prop = $X->atom($prop) unless $prop =~ m{^\d+$};
    my($res) = $X->robust_req(DeleteProperty=>$window,$prop);
    return ref $res ? 1 : 0;
}

=over

=item B<setWMPropertyEncode>(I<$X>,I<$window>,I<$prop>,I<$encode>,I<@args>)

Provides a method for setting an encoded property to the root window.  The
property has atom name, I<$prop>, format, I<$format>, and encoder,
I<$encode> is a C<CODE> reference that accepts the arguments, I<@args>,
and returns encoded packed data.  This method is used by subsequent
methods below:

=cut

sub setWMPropertyEncode {
    my($X,$window,$prop,$encode,@args) = @_;
    if (@args) {
	my($type,$format,$data) = &{$encode}(@args);
	setProperty($X,$window,$prop,$type,$format,$data);
    } else {
	deleteProperty($X,$window,$prop);
    }
}

=over

=item B<setWMPropertyText>(I<$X>,I<$window>,I<$prop>,I<$style>,I<$string>)

Set the property, I<$prop>, to the string value, I<$string>.
I<$style> must be one of C<StringStyle>, C<StdICCStyle>,
C<CompoundTextStyle> or C<Utf8StringStyle>.
The resulting property will be null-separated.

=cut

sub setWMPropertyText {
    my($X,$window,$prop,$style,$string) = @_;
    setWMPropertyEncode($X,$window,$prop,sub{
            my($style,$string) = @_;
            return STRING=>8,Encode::encode('iso-8859-1',$string)
                if $style eq 'StringStyle' or
                  ($style eq 'StdICCStyle' and _string_OK($string));
            return COMPOUND_TEXT=>8,Encode::encode('x11-compound-text',$string)
                if $style eq 'StdICCStyle' or $style eq 'CompoundTextStyle';
            warn "style '$style' defaults to Utf8StringStyle"
                if $style ne 'Utf8StringStyle';
            return UTF8_STRING=>8,Encode::encode('UTF-8',$string);
    },$style,$string);
}

=item B<setWMPropertyTexts>(I<$X>,I<$window>,I<$prop>,I<$style>,I<$string>)

Set the property, I<$prop>, to the string values, I<$strings>.
I<$style> must be one of C<StringStyle>, C<StdICCStyle>,
C<CompoundTextStyle> or C<Utf8StringStyle>.
The resulting property will be null-separated.

=cut

sub setWMPropertyTexts {
    my($X,$window,$prop,$style,$strings) = @_;
    setWMPropertyEncode($X,$window,$prop,sub{
	    my($style,$strings) = @_;
	    return STRING=>8,join(pack('C',0),map{Encode::encode('iso-8859-1',$_)} @$strings)
		if $style eq 'StringStyle' or
		  ($style eq 'StdICCStyle' and _strings_OK($strings));
	    return COMPOUND_TEXT=>8,join(pack('C',0),map{Encode::encode('x11-compound-text',$_)} @$strings)
		if $style eq 'StdICCStyle' or $style eq 'CompoundTextStyle';
	    warn "style '$style' defaults to Utf8StringStyle"
		if $style ne 'Utf8StringStyle';
	    return UTF8_STRING=>8,join(pack('C',0),map{Encode::encode('UTF-8',$_)} @$strings);
    },$style,$strings);
}

=item B<setWMPropertyTermText>(I<$X>,I<$window>,I<$prop>,I<$style>,I<$string>)

Set the property, I<$prop>, to the string value, I<$string>.
I<$style> must be one of C<StringStyle>, C<StdICCStyle>,
C<CompoundTextStyle> or C<Utf8StringStyle>.
The resulting property will be null-terminated.

=cut

sub setWMPropertyTermText {
    my($X,$window,$prop,$style,$string) = @_;
    setWMPropertyEncode($X,$window,$prop,sub{
            my($style,$string) = @_;
            return STRING=>8,Encode::encode('iso-8859-1',$string)."\x00"
                if $style eq 'StringStyle' or
                  ($style eq 'StdICCStyle' and _string_OK($string));
            return COMPOUND_TEXT=>8,Encode::encode('x11-compound-text',$string)."\x00"
                if $style eq 'StdICCStyle' or $style eq 'CompoundTextStyle';
            warn "style '$style' defaults to Utf8StringStyle"
                if $style ne 'Utf8StringStyle';
            return UTF8_STRING=>8,Encode::encode('UTF-8',$string)."\x00";
    },$style,$string);
}

=item B<setWMPropertyTermTexts>(I<$X>,I<$window>,I<$prop>,I<$style>,I<$string>)

Set the property, I<$prop>, to the string values, I<$strings>.
I<$style> must be one of C<StringStyle>, C<StdICCStyle>,
C<CompoundTextStyle> or C<Utf8StringStyle>.
The resulting property will be null-terminated.

=cut

sub setWMPropertyTermTexts {
    my($X,$window,$prop,$style,$strings) = @_;
    setWMPropertyEncode($X,$window,$prop,sub{
	    my($style,$strings) = @_;
	    return STRING=>8,join(pack('C',0),map{Encode::encode('iso-8859-1',$_)} @$strings)."\x00"
		if $style eq 'StringStyle' or
		  ($style eq 'StdICCStyle' and _strings_OK($strings));
	    return COMPOUND_TEXT=>8,join(pack('C',0),map{Encode::encode('x11-compound-text',$_)} @$strings)."\x00"
		if $style eq 'StdICCStyle' or $style eq 'CompoundTextStyle';
	    warn "style '$style' defaults to Utf8StringStyle"
		if $style ne 'Utf8StringStyle';
	    return UTF8_STRING=>8,join(pack('C',0),map{Encode::encode('UTF-8',$_)} @$strings)."\x00";
    },$style,$strings);
}

=item B<setWMPropertyString>(I<$X>,I<$window>,I<$prop>,I<$type>,I<$string>)

Set set property, I<$prop>, to the string value, I<$string>.
I<$type> must be one of C<STRING>, C<COMPOUND_TEXT> or C<UTF8_STRING>.
When the resulting property must be null terminated, it may be necessary
to append the null character to the end of the string, I<$string>.

=cut

sub setWMPropertyString {
    my @args = @_; $args[3] = _map_style($args[3]);
    return setWMPropertyText(@args);
}

=item B<setWMPropertyStrings>(I<$X>,I<$window>,I<$prop>,I<$strings>)

Set set property, I<$prop>, to the string values, I<$strings>.
I<$type> must be one of C<STRING>, C<COMPOUND_TEXT> or C<UTF8_STRING>.
When the resulting property must be null terminated rather than null
separated, it may be necessary to add '' to the end of the list of
strings.

=cut

sub setWMPropertyStrings {
    my @args = @_; $args[3] = _map_style($args[3]);
    return setWMPropertyTexts(@args);
}

=item B<setWMPropertyTermString>(I<$X>,I<$window>,I<$prop>,I<$type>,I<$string>)

Like setWMPropertyString() except for null-terminated strings instead
of null-separated strings.

=cut

sub setWMPropertyTermString {
    my @args = @_; $args[3] = _map_style($args[3]);
    return setWMPropertyTermText(@args);
}

=item B<setWMPropertyTermStrings>(I<$X>,I<$window>,I<$prop>,I<$type>,I<$strings>)

Like setWMPropertyStrings() except for null-terminated strings instead
of null-separated strings.

=cut

sub setWMPropertyTermStrings {
    my @args = @_; $args[3] = _map_style($args[3]);
    return setWMPropertyTermText(@args);
}

=item B<setWMPropertyUint>(I<$X>,I<$window>,I<$prop>,I<$type>,I<$integer>)

Sets the property, I<$prop>, to the integer value, I<$integer>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMPropertyUint {
    my($X,$window,$prop,$type,$integer) = @_;
    setWMPropertyEncode($X,$window,$prop,sub{
	    my($type,$integer) = @_;
	    return $type, 32, pack('L',$integer);
    },$type,$integer);
}

=item B<setWMPropertyUints>(I<$X>,I<$window>,I<$prop>,I<@integers>)

Sets the property, I<$prop>, to the integer values, I<@integers>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMPropertyUints {
    my($X,$window,$prop,$type,$integers) = @_;
    setWMPropertyEncode($X,$window,$prop,sub{
	    my($type,$integers) = @_;
	    return $type, 32, pack('L*',@$integers);
    },$type,$integer);
}

=item B<setWMPropertyInt>(I<$X>,I<$window>,I<$prop>,I<$type>,I<$integer>)

Sets the property, I<$prop>, to the integer value, I<$integer>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMPropertyInt {
    my($X,$window,$prop,$type,$integer) = @_;
    setWMPropertyEncode($X,$window,$prop,sub{
	    my($type,$integer) = @_;
	    return $type, 32, pack('l',$integer);
    },$type,$integer);
}

=item B<setWMPropertyInts>(I<$X>,I<$window>,I<$prop>,I<@integers>)

Sets the property, I<$prop>, to the integer values, I<@integers>, of type,
I<$type>.  I<$prop> and I<$type> are atom names as a scalar string.  This
results in a property of type, I<$type>.

=cut

sub setWMPropertyInts {
    my($X,$window,$prop,$type,$integers) = @_;
    setWMPropertyEncode($X,$window,$prop,sub{
	    my($type,$integers) = @_;
	    return $type, 32, pack('l*',@$integers);
    },$type,$integer);
}

=item B<setWMPropertyAtom>(I<$X>,I<$window>,I<$prop>,I<$atom>)

Sets the property, I<$prop>, to the atom named I<$atom>.
This results in a C<ATOM> type property.

=cut

sub setWMPropertyAtom {
    my($X,$window,$prop,$atom) = @_;
    setWMPropertyEncode($X,$window,$prop,sub{
	    return ATOM=>32,pack('L',$X->atom(shift));
    },$atom);
}

=item B<setWMPropertyAtoms>(I<$X>,I<$window>,I<$prop>,I<$atoms>)

Sets the property, I<$prop>, to the list of atoms named by I<@$atoms>.
This results in a C<ATOM> type property.

=cut

sub setWMPropertyAtoms {
    my($X,$window,$prop,$atoms) = @_;
    setWMPropertyEncode($X,$window,$prop,sub{
	    return ATOM=>32,pack('L*',map{$X->atom($_)}@{$_[0]});
    },$atoms);
}

=back

=back

=back

=head2 Sending Events

The following methods are used for sending events:

=over

=item B<clientMessage>(I<$X>,I<$targ>,I<$win>,I<$type>,I<$data>)

Send a client message to a window, I<$targ>, with the specified window as
I<$win>, client message type the atom name I<$type>, and 20-bytes of
packed client message data, I<$data>.  The mask used is C<StrutureNotify>
and C<SubstructureNotify>.

=cut

sub clientMessage {
    my($X,$window,$type,$data) = @_;
    $window = $X->root unless $window;
    $type = $X->atom($type) unless $type =~ m{^\d+$};
    $X->SendEvent($X->root, 0,
	    $X->pack_event_mask(qw(
		    StructureNotify
		    SubstructureNotify
		    SubstructureRedirect)),
	    $X->pack_event(
		name=>'ClientMessage',
		window=>$window,
                type=>$type,
		format=32,
                data=>$data));
}

=back

=cut

1;

__END__

=head1 IMPORTS

Any public subroutine can be imported.  Some tags have been defined as
follows:

=over

=item :encdec

Special encoding and decoding subroutines as follows:

    getWMRootPropertyDecode
    getWMPropertyDecode
    setWMRootPropertyEncode
    setWMPropertyEncode

=item :string

String encoding and decoding subroutines as follows:

    getWMRootPropertyString
    getWMRootPropertyStrings
    getWMRootPropertyTermString
    getWMRootPropertyTermStrings
    getWMPropertyString
    getWMPropertyStrings
    getWMPropertyTermString
    getWMPropertyTermStrings
    setWMRootPropertyString
    setWMRootPropertyStrings
    setWMRootPropertyTermString
    setWMRootPropertyTermStrings
    setWMPropertyString
    setWMPropertyStrings
    setWMPropertyTermString
    setWMPropertyTermStrings

=item :text

Text encoding and decoding subroutines as follows:

    setWMRootPropertyText
    setWMRootPropertyTexts
    setWMRootPropertyTermText
    setWMRootPropertyTermTexts
    setWMPropertyText
    setWMPropertyTexts
    setWMPropertyTermText
    setWMPropertyTermTexts

=item :uint

Unsigned integer encoding and decoding subroutines as follows:

    getWMRootPropertyUint
    getWMRootPropertyUints
    getWMPropertyUint
    getWMPropertyUints
    setWMRootPropertyUint
    setWMRootPropertyUints
    setWMPropertyUint
    setWMPropertyUints

=item :int

Signed integer encoding and decoding subroutines as follows:

    getWMRootPropertyInt
    getWMRootPropertyInts
    getWMPropertyInt
    getWMPropertyInts
    setWMRootPropertyInt
    setWMRootPropertyInts
    setWMPropertyInt
    setWMPropertyInts

=item :atom

Atom encoding and decoding subroutines as follows:

    getWMRootPropertyAtom
    getWMRootPropertyAtoms
    getWMPropertyAtom
    getWMPropertyAtoms
    setWMRootPropertyAtom
    setWMRootPropertyAtoms
    setWMPropertyAtom
    setWMPropertyAtoms

=item :bits

Bits encoding and decoding subroutines as follows:

    getWMPropertyBits

=item :all

All exportable subroutines.

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::Protocol(3pm)>,
L<X11::Protocol::AnyEvent(3pm)>.

# vim: set sw=4 tw=74 fo=tcqlorn:
