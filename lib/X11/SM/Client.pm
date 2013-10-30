package X11::SM::Client;
use strict;
use warnings;

=head1 NAME

X11::SM::Client - implements the client functions of the X Session Management Library

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

The following methods are provided:

=over

=item $client = X11::SM::Client->B<new>(I<$ids>, I<$prev>, I<$maj>, I<$min>)

=over

=item I<$ids>

The network identifiers of the session manager.  This is a scalar comma
separated list of network identifiers in the same format as described in
the XSMP for the B<SESSION_MANAGER> environment variable.  The following
is normally valid:

 $client = X11::SM::Client->new($ENV{SESSION_MANAGER});

=item I<$prev>

Specifies the previous client id for which the client is being restored.
When C<undef>, a new client id is requested.

=item I<$maj>

Specifies the highest major version of the XSMP the application
supports.  When C<undef>, the default is major version C<1>.
(There is only one version of the specification: 1.0.)
Do not specify this, it is unnecessary.

=item I<$min>

Specifies the highest minor version number of the XSMP the application
supports for the specified C<$maj>.  When C<undef>, the default is
minor version C<0>.
(There is only one version of the specification: 1.0.)
Do not specify this, it is unnecessary.

=back

=item $client->B<ClientID>() => $client_id

Returns the client id assigned by the session manager.

=cut

=item $client->B<SaveYourself>(I<$save_type>, I<$shut_down>, I<$interact_style>, I<$fast>)

=over

=item I<$save_type>

=cut

use constant {
    SaveLocal  => 0,
    SaveGlobal => 1,
    SaveBoth   => 2,
};

=item I<$shut_down>

A boolean value that indicates whether a shutdown is being performed.
WHen true, a shutdown is being performed; false, a checkpoint is being
performed.

=item I<$interact_style>

=cut

use constant {
    InteractStyleNone   => 0,
    InteractStyleErrors => 1,
    InteractStyleAny    => 2,
};

=over

=item C<InteractStyleNone>

=item C<InteractStyleErrors>

=item C<InteractStyleAny>

=back

=item I<$fast>

=back

=item $client->B<Die>()

The session manager sends a C<Die> message to a client when it wants it
to die.  This method is invoked when the message is received.  The
client should respond by calling C<$client-E<gt>CloseConnection>.  A
session manager that behaves properly will send a C<Save Yourself>
message before the C<Die> message.

=item $client->B<SaveComplete>()

=item $client->B<ShutdownCancelled>()

=item $client->B<SetProperties>()

=item $client->B<SaveYourselfDone>()

=item $client->B<InteractRequest>()

=item $client->B<InteractDone>()

=item $client->B<GetProperties>()

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::SM(3pm)>,
L<X11::ICE(3pm)>,
L<X11::Protocol(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
