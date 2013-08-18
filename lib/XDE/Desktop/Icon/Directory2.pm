package XDE::Desktop::Icon::Directory2;
use base qw(XDE::Desktop::Icon2);
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Icon::Directory2 -- desktop directory (take 2)

=head1 SYNOPSIS

 my $dtop = XDE::Desktop->new(\%OVERRIDES);
 my $icon = XDE::Desktop::Icon::Directory->new($desktop,$path);

=head1 DESCRIPTION

A desktop icon object for a directory.  Directories are, by default,
represented by folder icons and have a label of the same name as the
subdirectory.  The action associated with desktop icon directories is
opening the directory using a file manager.  Per the desktop entry
specification, a directory can contain a desktop entry file of type
C<Directory> named simply F<.directory>.  This file can specify how to
display the directory on the desktop.  Such an entry will have the
following key fields:

=over

=item C<Type>:

Always C<Directory>.  This is a required field.

=item C<Version>:

Always C<1.0>.  Not required.

=item C<Name>:

The specific visible name of the directory to be displayed in the label
text under the directory icon.  This is a required field.

=item C<GenericName>:

A generic name for the directory.  Not normally displayed.

=item C<NoDisplay>:

Meas this application exists but do not display it in the menus.  By
menus, application launcher menus is meant.  This would not normally
appear in a F<Desktop> directory entry and can largely be ignored.

=item C<Comment>:

Tooltip for the directory.

=item C<Icon>:

Indicates the icon to display.  When this field is not specified or the
corresponding icon cannot be found, a F<folder> icon is shown by
default.

=item C<Hidden>:

When true, it means that the DE should treat the directory as though it
does not exist.  We may have an option to show them anyway.

=item C<OnlyShowIn>, C<NotShowIn>:

A list of strings identifying the environments that should display/not
display a given desktop entry.  Only one of these keys, either
C<OnlyShowIn> or C<NotShowIn>, may appear in a group.  This is basically
compared against the DE name as it appears in C<$XDG_CURRENT_DESKTOP>;
however, we might provide a I<Show All> option to shown them anyways.

=back


Note that this is an implementation class that is not expected to be
used directly, but is to be called from XDE::Desktop.

=head1 METHODS

This module provides the following methods:

=over

=item $directory = XDE::Desktop::Icon::Directory->B<new>(I<$desktop>,I<$directory>)

Creates an instance of an XDE::Desktop::Icon::Directory object.  A
directory corresponds to a normal directory under the F<Desktop>
directory that may be opened with a file manager.  C<$desktop> is an
instance of an XDE::Desktop object, and C<$directory> is the full path
to the subdirectory.

This method identifies the icon (full path) and label associated with
the directory.  The icon is the directory icon under the icon theme; the
label is simply the directory name.

=cut

sub new {
    my ($type,$desktop,$directory) = @_;
    return undef unless -d $directory;
    my $d = $directory; $d =~s{/+$}{};
    my $f = '.directory';
    my %e = $desktop->get_entry($d,$f,'Desktop Entry');
    my $id = $d; $id =~ s{^.*/}{};
    $e{Type} = 'Directory' unless $e{Type};
    $e{Name} = $id unless $e{Name};
    $e{Comment} = "Open subdirectory $e{Name}" unless $e{Comment};
    $e{MimeType} = $desktop->get_mime_type($directory);
    $e{id} = $e{file} if $e{file};
    $e{id} = $e{MimeType} unless $e{id};
    $e{file} = "$d/$f" unless $e{file};
    $e{Icon} = 'folder' unless $e{Icon};
    return XDE::Desktop::Icon2::new_from_entry($type,$directory,\%e);
}

=item $icon->B<props>()

Launch a window showing the directory properties.

=cut

sub props {
    my $self = shift;
    # TODO: finish this...
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
