package XDG::IconTheme;
use strict;
use warnings;

=head1 NAME

XDG::IconTheme - read XDG index.theme files

=head1 SYNOPSIS

 my $theme = new XDG::IconTheme($filename);

=head1 DESCRIPTION

The XDG::IconTheme module provides the ability to read and interpret the
data contained in an XDG compliant F<index.theme> file.  It is used by
L<XDG::Icons(3pm)> to read theme files.

=head1 METHODS

The XDG::IconTheme package has the following methods:

=over

=item XDG::IconTheme->B<new>($filename) => XDG::IconTheme

Creates a new XDG::IconTheme from the specified filename.

=cut

sub new {
    my $self = bless {}, shift;
    my $file = $self->{file} = shift;
    return undef unless -f $file;
    open(my $fh, "<", $file) or warn $!;
    return undef unless $fh;
    my $parsing = 0;
    my $directory;
    while (<$fh>) {
	if (/^\[/) {
	    if (/^\[Icon Theme\]/) {
		$parsing = 1;
		$directory = undef;
	    }
	    elsif (/^\[(.*)\]/) {
		$parsing = 1;
		$directory = $1;
		$self->{dirs}{$directory} = {};
	    }
	}
	elsif ($parsing and /^([^=]*)=([^[:cntrl:]]*)/) {
	    my ($label,$value) = ($1,$2);
	    if ($directory) {
		$self->{dirs}{$directory}{$label} = $value
		    unless $label =~ /[[]/;  # skip xlations for now
	    } else {
		$self->{$label} = $value
		    unless $label =~ /[[]/;  # skip xlations for now
	    }
	}
    }
    close($fh);
    return $self;
}

=item $theme->B<Directories>() => list

Lists the subdirectories defined by the icon theme (from the
C<Directories> key in the index.theme keyfile).

=cut

sub Directories {
    my $self = shift;
    return () unless $self->{Directories};
    return split(/,/,$self->{Directories});
}

=item $theme->B<DirectoryMatchesSize>($subdir,$iconsize) => boolean

Tests whether the specified theme directory, C<$subdir>, matches the
integer icon size, C<$iconsize>.
This method is an implementation of the pseudo-code of the same name
provided by L<http://freedesktop.org>.

=cut

sub DirectoryMatchesSize {
    my ($self,$subdir,$iconsize) = @_;
    if (my $dir = $self->{dirs}{$subdir}) {
	$dir->{MaxSize} = $dir->{Size} unless $dir->{MaxSize};
	$dir->{MinSize} = $dir->{Size} unless $dir->{MinSize};
	$dir->{Threshold} = 2 unless $dir->{Threshold};
	if ($dir->{Type} eq 'Fixed') {
	    return ($dir->{Size} == $iconsize);
	}
	if ($dir->{Type} eq 'Scaled') {
	    return (($dir->{MinSize} <= $iconsize) and
		    ($iconsize <= $dir->{MaxSize}));
	}
	if ($dir->{Type} eq 'Threshold') {
	    return ((($dir->{Size} - $dir->{Threshold}) <= $iconsize) and
		    ($iconsize <= ($dir->{Size} + $dir->{Threshold})));
	}
    }
    return 0;
}

=item $theme->B<DirectorySizeDistance>($subdir,$iconsize) => integer

Determines the size distance of an icon of size C<$iconsize> from the
icons contained in the theme directory C<$subdir>.
This method is an implementation of the pseudo-code of the same name
provided by L<http://freedesktop.org>.

=cut

sub DirectorySizeDistance {
    my ($self,$subdir,$iconsize) = @_;
    if (my $dir = $self->{dirs}{$subdir}) {
	$dir->{MaxSize} = $dir->{Size} unless $dir->{MaxSize};
	$dir->{MinSize} = $dir->{Size} unless $dir->{MinSize};
	$dir->{Threshold} = 2 unless $dir->{Threshold};
	if ($dir->{Type} eq 'Fixed') {
	    return abs($dir->{Size} - $iconsize);
	}
	if ($dir->{Type} eq 'Scaled') {
	    if ($iconsize < $dir->{MinSize}) {
		return ($dir->{MinSize} - $iconsize);
	    }
	    if ($iconsize > $dir->{MaxSize}) {
		return ($iconsize - $dir->{MaxSize});
	    }
	    return 0;
	}
	if ($dir->{Type} eq 'Threshold') {
	    if ($iconsize < ($dir->{Size} - $dir->{Threshold})) {
		return ($dir->{MinSize} - $iconsize);
	    }
	    if ($iconsize > ($dir->{Size} + $dir->{Threshold})) {
		return ($iconsize - $dir->{MaxSize});
	    }
	    return 0;
	}
    }
}

1;

=back

=head1 SEE ALSO

L<XDG::Icons(3pm)>

=cut
