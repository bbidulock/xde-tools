package XDE::Desktop::Icon::Link;
use base qw(XDE::Desktop::Icon::Shortcut2);
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Icon::Link -- a C<Link> F<.desktop> file

=head1 SYNOPSIS

=head1 DESCRIPTION

This modules provides the methods and attributes unique to a C<Link>
type F<.desktop> file.

Desktop entry keys for this type are:

=over

=item Type (mandatory, generic)

For applications, this field must have a value of C<Link>.

=item Version (generic)

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

=over

=item $shortcut = XDE::Desktop::Icon::Link->B<new>(I<$desktop>,I<$filename>)

Creates an instance of an XDE::Desktop::Icon::Link object.  A link
corresponds to a freedesktop.org F<.desktop> file.  C<$desktop> is an
instance of an L<XDE::Desktop2(3pm)> object, and C<$filename> is the
full path and file name of the F<.desktop> file to which the link
corresponds.

This method identifies the icon and label associated with the link
and then calls XDE::Desktop::Icon2->new_from_entry() to create the
desktop icon.  The icon is determined from the C<Icon> entry in the
F<.desktop> file and the label is determined from the C<Name> entry.

Any invalid link file will be represented simply as a
XDE::Desktop::Icon::File instance instead.

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
    return XDE::Desktop::Icon2::new_from_entry($filename,\%e);
}

1;

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Desktop(3pm)>, L<XDE::Desktop::Icon(3pm)>

=cut


__END__

# vim: set sw=4 tw=72:
