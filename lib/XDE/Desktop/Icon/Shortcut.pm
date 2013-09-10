package XDE::Desktop::Icon::Shortcut;
use base qw(XDE::Desktop::Icon);
use XDE::Desktop::Icon::Application;
use XDE::Desktop::Icon::Link;
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Icon::Shortcut -- desktop shortcut

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=item $shortcut = XDE::Desktop::Icon::Shortcut->B<new>(I<$desktop>,I<$filename>,I<$x>,I<$y>)

Creates an instance of an XDE::Desktop::Icon::Shortcut object.  A
shortcut corresponds to a freedesktop.org F<.desktop> file.
C<$desktop> is an instance of an XDE::Desktop object, and C<$filename>
is the full path and file name of the F<.desktop> file to which the
shortcut corresponds.  C<$x> and C<$y> are the x- and y-coordinates of
the upper-left corner of the cell on which to render the icon and label.

This method identifies the icon and label associated with the shortcut
and then calls XDE::Desktop::Icon->new() to create the desktop icon.
The icon is determined from the C<Icon> entry in the F<.desktop> file
and the label is determined from the C<Name> entry.

Any invalid shortcut file will be represented simply as a
XDE::Desktop::Icon::File instance instead.

=cut

sub new {
    my ($type,$desktop,$filename) = @_;
    return undef unless -f $filename;
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
    $e{Type} = 'Application' unless $e{Type} or $e{Type} eq 'XSession';
    if ($e{Type} eq 'Application') {
	return XDE::Desktop::Icon::Application->new_from_entry($filename,\%e);
    }
    if ($e{Type} eq 'Link') {
	return XDE::Desktop::Icon::Link->new_from_entry($filename,\%e);
    }
    warn "Wrong desktop entry type $e{Type}: falling back to file.";
    return XDE::Desktop::Icon::File->new($desktop,$filename);
}

=item $shortcut->B<launch>()

This method performs the default click action associated with the
shortcut.

=cut

sub launch {
    my $self = shift;
    my $command = $self->{entry}{Exec};
    $command = 'false' unless $command;
    $command =~ s{%[dDnNickvmfFuU]}{}g;
    print STDERR "START $command\n";
    system "$command &";
}

sub click {
    return shift->launch(@_);
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
