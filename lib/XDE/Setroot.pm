package XDE::Setroot;
use X11::Protocol;
use strict;
use warnings;

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

