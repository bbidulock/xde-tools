package XDE::X11::StartupNotification;
use base qw(XDE::X11);
use POSIX qw(setsid getpid :sys_wait_h);
use strict;
use warnings;

=head1 NAME

XDE::X11::StartupNotification -- perform XDG startup notification

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

=item $sn = XDE::X11::StartupNotification->B<new>() => blessed HASHREF

=cut

sub new {
	my $self = XDE::X11->new(@_);
	chomp(my $hostname = `hostname`);
	my $sn = $self->{sn} = {
	    win => $self->new_rsrc,
	    hostname => $hostname,
	    pid => getpid(),
	    ts => gettimeofday(),
	};
	$self->atom('_NET_STARTUP_INFO_BEGIN');
	$self->atom('_NET_STARTUP_INFO');
	my $win = $sn->{win} = $self->new_rsrc;
	$self->CreateWindow($sn->{win} ,$self->root, 'InputOutput',
	    $self->root_depth, 'CopyFromParent', (0,0), 1,1, 0);
	return $self;
}

=item $sn->B<newsnid>() => SCALAR

Obtains a new unique startup notification id.

=cut

sub newsnid {
	my $self = shift;
	my $sn = $self->{sn};
	my $now = gettimeofday();
	$now = $now + 1 while $now <= $sn->{ts};
	$sn->{ts} = $now;
	return "$sn->{hostname}+$sn->{pid}+$sn->{ts}";
}

=item $sn->B<send_sn>(I<$msg>)

Internal method to
send a packed startup notification message.

We cannot use Gtk2 for this purpose because Gtk2 always sends its
messages with an event mask of C<StructureNotify> instead of the
C<PropertyChange> mask that is required by the XDG startup notification
specification.  So we use L<X11::Protocol(3pm)> throughout.

=cut

sub send_sn {
    my ($self,$msg) = @_;
    my $pad = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";
    $self->SendEvent($self->root,0,
	$self->pack_event_mask('PropertyChange'),
	$self->pack_event(
	    name => 'ClientMessage',
	    window => $self->{sn}{win},
	    type => $self->atom('_NET_STARTUP_INFO_BEGIN'),
	    format => 8,
	    data => substr($msg.$pad,0,20),
	));
}

=item B<sn_quote>($txt) => $quoted_txt

Internal method to
quote parameter C<$txt> according to XDG startup notification rules.

=cut

sub sn_quote {
    my $txt = shift;
    $txt =~ s{\\}{\\\\}g if $txt =~ m{\\};
    $txt =~ s{"}{\\"}g   if $txt =~ m{"};
    $txt =~ "\"$txt\""   if $txt =~ m{ };
    return $txt;
}

=item $sn->B<send_sn_new>(I<$id>,{I<%msg_hash>})

Internal method to
send a startup notification C<new> message.  C<%msg_hash> contains a
hash of the valid startup notification fields.  The C<new> message
requires the C<ID>, C<NAME> and C<SCREEN> fields, and may optionally
contain the C<BIN>, C<ICON>, C<DESKTOP>, C<TIMESTAMP>, C<DESCRIPTION>,
C<WMCLASS> and C<SILENT> fields.

=cut

sub send_sn_new {
    my ($self,$id,$msg) = @_;
    my $txt = 'new:';
    $txt .= ' ID='.sn_quote($id);
    $txt .= ' NAME='.sn_quote($msg->{NAME});
    $txt .= ' SCREEN='.sn_quote($msg->{SCREEN});
    foreach (qw(BIN ICON DESKTOP TIMESTAMP DESCRIPTION WMCLASS SILENT PID)) {
	$txt .= " $_=".sn_quote($msg->{$_}) if $msg->{$_};
    }
    $txt .= "\0";
    $self->send_sn($txt);
}

=item $sn->B<send_sn_change>(I<$id>,{I<%msg_hash>})

Internal method to
send a startup notification C<change> message.  C<%msg_hash> contains a
hash of the valid startup notification fields.  The C<change> message
requires the C<ID> field, and may optionally contain the C<NAME>,
C<SCREEN>, C<BIN>, C<ICON>, C<DESKTOP>, C<TIMESTAMP>, C<DESCRIPTION>,
C<WMCLASS> and C<SILENT> fields.

=cut

sub send_sn_change {
    my ($self,$id,$msg) = @_;
    my $txt = 'change:';
    $txt .= ' ID='.sn_quote($id);
    foreach (qw(NAME SCREEN BIN ICON DESKTOP TIMESTAMP DESCRIPTION WMCLASS SILENT PID)) {
	$txt .= " $_=".sn_quote($msg->{$_}) if $msg->{$_};
    }
    $txt .= "\0";
    $self->send_sn($txt);
}

=item $sn->B<send_sn_remove>(I<$id>)

Internal method to
send a startup notification C<remove> message.  C<$id> is the startup
notification identifier.

=cut

sub send_sn_remove {
    my ($self,$id) = @_;
    my $txt = 'remove:';
    $txt .= ' ID='.sn_quote($id);
    $txt .= "\0";
    $self->send_sn($txt);
}

=item $sn->B<startup>(I<$de>)

Starts the desktop entry specified by C<$de>.  C<$de> must be a hash
reference where the key fields are the keys of the F<.desktop> entry
according to XDG specifications and the values are the translated field
values.

=cut

sub startup {
    my ($self,$de) = @_;
    my $sn = $self->{sn};
    return unless $de and ref($de) =~ /HASH/;
    return unless $de->{Exec};
    my ($notify,$wmclass,$id,$msg) = (0,'','');
    if ($de->{StartupNotify} and
	$de->{StartupNotify} =~ m{^(true|yes|1)}i) {
	$notify = 1;
    }
    if ($de->{StartupWMClass}) {
	$wmclass = $de->{StartupWMClass};
    }
    if ($notify or $wmclass) {
	$id = $self->newsnid();
	$ENV{DESKTOP_STARTUP_ID} = $id;
	$de->{ID} = $id;
	$msg = {
	    ID=>$id,
	    NAME=>$de->{Name}, # FIXME: convert to ASCII
	    SCREEN=>0,
	};
	$msg->{BIN} = $de->{TryExec} if $de->{TryExec};
	$msg->{ICON} = $de->{Icon} if $de->{Icon};
	$msg->{DESKTOP} = 0; # XXX: should be current desktop
	$msg->{TIMESTAMP} = 0; # XXX: should be server timestamp
	$msg->{DESCRIPTION} = $de->{Comment} if $de->{Comment}; # FIXME: translate
	$msg->{WMCLASS} = $wmclass if $wmclass;
	if ($de->{NoDisplay} and $de->{NoDisplay} =~ m{^(true|yes|1)$}i) {
	    $msg->{SILENT} = 1;
	} else {
	    $msg->{SILENT} = 0;
	}
    }
    my $child = fork();
    return unless defined $child;
    if ($child) {
	# we are the parent
	$de->{WATCHER} = Glib::Child->watch_add($child,
	    sub{ $self->childexit(@_) }, $de);
	$de->{PID} = $child;
	$sn->{tasks}{$child} = $de;
	$sn->{notify}{$id} = $de if $notify;
	push @{$sn->{wmclass}{$wmclass}}, $de if $wmclass;
	if ($msg) {
	    $msg->{PID} = $child;
	    $self->send_sn_new($id,$msg);
	}
	return $child;
    }
    else {
	# we are the child
    }
}


=back

=cut

1;

# vim: sw=4 tw=72
