package X11::ICE;
use strict;
use warnings;

=head1 NAME

X11::ICE -- perl implementation of the X11 ICElib.

=head1 METHODS

The following methods are provided:

=head2 PROTOCOL REGISTRATION

The following modules are used in the library to distinguish between a
client that initiates a C<ProtocolSetup> and a client that responds with
a C<ProtocolReply>:

 X11::ICE::Originator - ICE protocol originator
 X11::ICE::Acceptor   - ICE protocol acceptor

For two clients to exchange messages for a given protocol, each side
must register the protocol with the ICE module.  The purposer of
registration is for each side to obtain a major opcode for the protocol
and to provide callbacks for processing messages and handling
authentication.  There are two separate registration functions:

=over

=item

One to handle the side that does a C<ProtocolSetup>.

=item

One to handle the side that responds with a C<ProtocolReply>.

=back

It is recommended that protocol registration occur before the two
clients establish an ICE connection.  If protocol registration occurs
after an ICE connection is created, there can be a brief interval of
time in which a C<ProtocolSetup> is received, but the protocol is not
registered.  If it is not possible to register a protocol before the
creation of an ICE connection, property precautions should be taken to
avoid the above race conditiion.

=over

=item $ICE->B<RegisterForProtocolSetup>(I<@args>) => I<$major>

Returns the major opcode reserved, I<$major>, or C<undef> if an error
occurred.  To actually activate the protocol, the ProtocolSetup() method
needs to be called with this major opcode.  Once the protocol is
activated, all messages for the protocol should be sent using this major
opcode.

I<@args> are as follows:

=over

=item I<$protocol_name>

A string specifying the name of the protocol to register.

=item I<$vendor>

A vendor string with semantics specified by the protocol.

=item I<$release>

A release string with semantics specified by the protocol.

=item I<$version_recs>

A protocol library may support multiple versions of the same protocol.
The II<$version_recs> argument specifies a list of supported vesions of
the protocol, which are prioritized in decreasing order of preference.
Each version record consists of a major and minor version of the
protocol as well as a callback to be used for processing incoming
messages.

A list of versions and associated callbacks.  This is a reference to an
array of hash references.  Each hash reference in the list refers to a
hash containing the following keys:

 major_version    - major version of the protocol supported
 minor_version    - minor version of the protocol supported
 process_msg_proc - perl CODE reference for message processing
                    callback

The C<process_msg_proc> callback is responsible for processing the set
of messages that can be received by the client that intiiated the
C<ProtocolSetup>.

=item I<$auth>

A list of authentication methods supported.  This is a reference to an
array of hash references.  Each hash reference in the list refers to a
hash containing the following keys:

 name             - name of the authentication method
 proc             - perl CODE reference for authenication

Authentication may be required before the protocol can become active.
The protocol library must register the authentication methods that it
supports with the ICE module.  The I<$auth> list is proritized in
decreasing order of preference.  See L</AUTHENTICATION METHODS>.

=item I<$io_error_proc>

A perl CODE reference used as a callback for errors.  This callback is
invoked if the ICE connection unexpectedly breaks.  You should pass
C<undef> for I<$io_error_proc> if not interested in being notified.  See
L</ERROR HANDLING>.

=back

=item $ICE->B<RegisterForProtocolReply>(I<@args>) => I<$major>

Returns the major opcode reserved or C<undef> if an error occurred.  The
major opcode should be used in all subsequent messages sent for this
protocol.

=over

=item I<$protocol_name>

A string specifying the name of the protocol to register.

=item I<$vendor>

A vendor string with semantics specified by the protocol.

=item I<$release>

A release stirng with semantics specified by the protocol.

=item I<$version_recs>

A protocol library may support multiple versions of the same protocol.
The I<Iversion_recs> argument specifies a list of supported versions of
the protocol, which are proritized in decreasing order of preference.
I<$version_regs> is a reference to any array of hash references.  Each
hash has the following keys:

 major  - major version number
 minor  - minor version number
 proc   - perl CODE reference callback to thbe used for processing
          incoming messages.

=item I<$auth>

=item I<$host_based_auth_proc>

=item I<$protocol_setup_proc>

=item I<$protocol_activate_proc>

=item I<$io_error_proc>

A perl CODE reference used as a callback for errors.  This callback is
invoked if the ICE connection unexpectedly breaks.  You should pass
C<undef> for I<$io_error_proc> if not interested in being notified.  See
L</ERROR HANDLING>.

=back

=back

=cut

1;

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: set sw=4 tw=72 fo=tcqlorn foldmarker==head,=head foldmethod=marker:
