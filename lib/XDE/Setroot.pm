package XDE::Setroot;
use X11::Protocol;
use strict;
use warnings;

=head1 NAME

XDE::Setroot -- set the root window background

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides an L<X11::Protocol(3pm)> based program to set the root window.

=head1 METHODS

=over

=cut

use constant {
    ATOMS => [qw(
	ESETROOT_PMAP_ID
	_XROOTPMAP_ID
	_XSETROOT_ID
	_XROOTMAP_ID
	_NET_NUMBER_OF_DESKTOPS
	_NET_CURRENT_DESKTOP
	PIXMAP
    )],
};

sub new {
    my $self = bless {}, shift;
    my $X = $self->{X} = X11::Protocol->new();
    $self->{atoms}{$_} = $X->atom($_) foreach (@{&ATOMS});
    $X->SetCloseDownMode('RetainTemporary');
    return $self;
}

1;

__END__

=back

=head1 BUGS

This module is not yet implemented.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::Protocol(3pm)>

=cut
