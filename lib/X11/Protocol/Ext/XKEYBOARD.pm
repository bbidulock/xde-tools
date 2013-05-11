
# The X Keyboard Extension
package X11::Protocol::Ext::XKEYBOARD;

# Note: this is not a complete implementation of the XKEYBOARD extension, but
#	is sufficient for getting and setting controls and requesting
#	and receiving events.

use X11::Protocol qw(pad padding padded make_num_hash);
use Carp;

use strict;
use vars '$VERSION';

$VERSION = 0.01;

sub new
{
    my $self = bless {}, shift;
    my($x, $request_num, $event_num, $error_num) = @_;

    # Events

    $x->{ext_conts}{Events}[$event_num] = 'XkbNotify';

    # Requests

    $x->{ext_request}{$request_num} =
    [
	[XkbUseExtension => sub{
	    my $self = shift;
	    return pack('LL',1,0); # we support version 1.0
	}, sub{
	    my $self = shift;
	    return unpack("xxxxxxxxLLxxxxxxxxxxxxxxx", shift);
	}],
	[XkbSelectEvents => sub{
	}, sub{
	}],
	undef, # op-code 2 is not defined
	[XkbBell => sub{
	}, sub{
	}],
	[XkbGetState => sub{
	}, sub{
	}],
	[XkbLatchLockState => sub{
	}, sub{
	}],
	[XkbGetControls => sub{
	}, sub{
	}],
	[XkbSetControls => sub{
	}, sub{
	}],
	[XkbGetMap => sub{
	}, sub{
	}],
	[XkbSetMap => sub{
	}, sub{
	}],
	[XkbGetCompatMap => sub{
	}, sub{
	}],
	[XkbSetCompatMap => sub{
	}, sub{
	}],
	[XkbGetIndicatorState => sub{
	}, sub{
	}],
	[XkbGetIndicatorMap => sub{
	}, sub{
	}],
	[XkbSetIndicatorMap => sub{
	}, sub{
	}],
	[XkbGetNamedIndicator => sub{
	}, sub{
	}],
	[XkbSetNamedIndicator => sub{
	}, sub{
	}],
	[XkbGetNames => sub{
	}, sub{
	}],
	[XkbSetNames => sub{
	}, sub{
	}],
	[XkbGetGeometry => sub{
	}, sub{
	}],
	[XkbSetGeometry => sub{
	}, sub{
	}],
	[XkbPerClientFlags => sub{
	}, sub{
	}],
	[XkbListComponents => sub{
	}, sub{
	}],
	[XkbGetKbdByName => sub{
	}, sub{
	}],
	[XkbGetDeviceInfo => sub{
	}, sub{
	}],
	[XkbSetDeviceInfo => sub{
	}, sub{
	}],
    ];
    # op-code 26 thru 100 are not defined
    $x->{ext_request}{$request_num}[101] =
	[XkbSetDebuggingFlags => sub{
	}, sub{
	}];

    for my $i (0 .. $#{$x->{ext_request}{$request_num}}) {
	$x->{ext_request_num}{$x->{ext_request}{$request_num}[$i][0]}
	= [$request_num, $i]
	if $x->{ext_request}{$request_num}[$i];
    }
    my ($self->{major},$self->{minor}) = $x->req('KbdUseExtension');
    if ($self->{major} != 1) {
	carp "Wrong XKEYBOARD version ($self->{major} != 1)";
	return 0;
    }
    return $self;
}

1;
__END__

=head1 NAME

X11::Protocol::Ext::XDB - Perl module for X Keyboard Extension

=head1 SYNOPSIS

  use X11::Protocol;
  $x = X11::Protocol->new($ENV{DISPLAY});
  $x->init_extension('XKEYBOARD') or die;

=head1 DESCRIPTION

=head1 SYMBOLIC CONSTANTS

=head1 REQUESTS

This extension adds several requests, called as shown below:

 $x->XkbUseExtension($major, $minor)
 =>
 ($major, $minor)

 $x->XkbGetControls()
 =>

 $x->XkbSetControls()
 =>

=head1 EVENTS

The following events are added by the extension.  See the I<Protocol
Specification> for more information on the contents of the events.
B<XkbNewKeyboardNotify>,
B<XkbMapNotify>,
B<XkbStateNotify>,
B<XkbControlsNotify>,
B<XkbIndicatorStateNotify>,
B<XkbIndicatorMapNotify>,
B<XkbNamesNotify>,
B<XkbCompatMapNotify>,
B<XkbBellNotify>,
B<XkbActionNotify>,
B<XkbAccessXNotify>,
B<XkbExtensionDeviceNotify>.

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>.

=head1 SEE ALSO

L<perl(1)>,
L<X11::Protocol>,
I<The X Keyboard Extension: Protocol Specification, Protocol Version
1.0/Document Revision 1.0 (X Consortium Standard)>

=cut

# vim: sw=4 tw=72
