package XDE::Desktop::Icon::Link;
use base qw(XDE::Desktop::Icon::Shortcut);
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Icon::Link -- a C<Link> F<.desktop> file

=head1 SYNOPSIS

 my $desktop = XDE::Desktop->new();
 my $filename = q{somefile.desktop};
 my ($x,$y) = (0,0);
 my $icon = XDE::Desktop::Icon::Link->new($desktop,$filename,$x,$y);

=head1 DESCRIPTION

This modules provides the methods and attributes unique to a C<Link>
type F<.desktop> file.

Desktop entry keys for this type are:

=over

=item Type (mandatory, generic) => Link

=item Version (generic) => 1.0

=item Name (mandatory, generic)

=item GenericName (generic)

=item NoDisplay (generic)

=item Comment (generic)

=item Icon (generic)

=item Hidden (generic)

=item OnlyShowIn, NotShowIn (generic)

=item URL (link only)

=back

=head1 METHODS

The following methods are provided:

=over

=item B<new> XDE::Desktop::Icon::Link I<$desktop>,I<$filename> => $icon

Creates an instance of an XDE::Desktop::Icon::Link object.  A link
corresponds to a freedesktop.org F<.desktop> file.  C<$desktop> is an
instance of an L<XDE::Desktop(3pm)> object, and C<$filename> is the
full path and file name of the F<.desktop> file to which the link
corresponds.

This method identifies the icon and label associated with the link
and then calls C<XDE::Desktop::Icon-E<gt>new_from_entry()> to create the
desktop icon.  The icon is determined from the C<Icon> entry in the
F<.desktop> file and the label is determined from the C<Name> entry.

Any invalid link file will be represented simply as a
L<XDE::Desktop::Icon::File(3pm)> instance instead.

=cut

sub new {
    my ($type,$desktop,$filename) = @_;
    my $d = $filename; $d =~ s{/[^/]*$}{};
    my $f = $filename; $f =~ s{.*/}{};
    return undef unless -f "$d/$f" and $f =~ /\.desktop$/;
    my %e = $desktop->get_entry($d,$f,'Desktop Entry');
    return undef unless %e;
    my $id = $f; $id =~ s{\.desktop$}{};
    $e{Name} = $id unless $e{Name};
    $e{Exec} = '' unless $e{Exec};
    $e{Comment} = $e{Name} unless $e{Comment};
    $e{Icon} = $id unless $e{Icon};
    $e{Icon} =~ s{\.(png|jpg|xpm|svg|jpeg)$}{};
    return XDE::Desktop::Icon::new_from_entry($filename,\%e);
}

1;

=back

See L<XDE::Desktop::Icon::Shortcut(3pm)/METHODS> for additional
inherited methods.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Desktop(3pm)>, L<XDE::Desktop::Icon(3pm)>

=cut


__END__

# vim: set sw=4 tw=72:
