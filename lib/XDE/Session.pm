package XDE::Session;
use base 
	'XDE::Dual',
	'XDE::Chooser',
	'XDE::Setup',
#	'XDE::Startup',
#	'XDE::Logout',
#	'XDE::Input',
#	'XDE::Setbg',
#	'XDE::Settings',
	;
use strict;
use warnings;

=head1 NAME

XDE::Session - create and manage an XDE session

=head1 SYNOPSIS

 use XDE::Session;

 my $xde = XDE::Session->new(%OVERRIDES,ops=>\%ops);

 $xde->getenv();
 $xde->init();
 $xde->session(\%ops);
 $xde->main();

=head1 DESCRIPTION

B<XDE::Session> provides a module that runs out of the Glib::Mainloop
that will choose the desktop session, setup the user's directories with
the necessary configuration files for the chosen session, execute
preliminary commands, start the window manager, and launch an XDG
autostart session.  It will monitor the session, provide notificaiton
and restart as necessary and initiate logout procedures when detected or
requested.

For detailed behaviour, see L</BEHAVIOUR>.

=head1 METHODS

XDE::Session provides the following methods:

=over

=item $xde = XDE::Session->B<new>(I<%OVERRIDES>,ops=>\I<%ops>) => blessed HASHREF

=cut

sub new {
    return XDE::Dual::new(@_);
}

=item $xde->B<defaults>() => $xde

Internal method to establish defaults for the each of the base
classes, invoked by L<XDG::Context(3pm)> after establishing XDG::Context
and its own defaults.  XDE::Session has no defaults of its own really.
This method should not be called directly.

=cut

sub defaults {
    my $self = shift;
    $self->XDE::Chooser::defaults(@_)	if XDE::Chooser->can('defaults');
    $self->XDE::Setup::defaults(@_)	if XDE::Setup->can('defaults');
#    $self->XDE::Startup::defaults(@_)	if XDE::Startup->can('defaults');
#    $self->XDE::Logout::defaults(@_)	if XDE::Logout->can('defaults');
#    $self->XDE::Input::defaults(@_)	if XDE::Input->can('defaults');
#    $self->XDE::Setbg::defaults(@_)	if XDE::Setbg->can('defaults');
#    $self->XDE::Settings::defaults(@_)	if XDE::Settings->can('defaults');
    return $self;
}

=item $xde->B<_init>() => $xde

Internal method to intialize the module.  Called by L<XDE::Dual(3pm)>
after it performs its own initialization.  We need to intialize all of
the intermediate inherited instances.
The user of this module should call the C<init> method on the
L<XDE::Dual(3pm)> module instead.

=cut

sub _init {
    my $self = shift;
    $self->XDE::Chooser::_init(@_)	if XDE::Chooser->can('_init');
    $self->XDE::Setup::_init(@_)	if XDE::Setup->can('_init');
#    $self->XDE::Startup::_init(@_)	if XDE::Startup->can('_init');
#    $self->XDE::Logout::_init(@_)	if XDE::Logout->can('_init');
#    $self->XDE::Input::_init(@_)	if XDE::Input->can('_init');
#    $self->XDE::Setbg::_init(@_)	if XDE::Setbg->can('_init');
#    $self->XDE::Settings::_init(@_)	if XDE::Settings->can('_init');
    return $self;
}

=item $xde->B<_term>() => $xde

Internal method to terminate the module.  Called by L<XDE::Dual(3pm)>
before it performs its own shutdown.  We need to shutdown all of the
intermediate inherited classes.
The user of this module should call the C<term> method on the
L<XDE::Dual(3pm)> module instead.

=cut

sub _term {
    my $self = shift;
    $self->XDE::Chooser::_term(@_)	if XDE::Chooser->can('_term');
    $self->XDE::Setup::_term(@_)	if XDE::Setup->can('_term');
#    $self->XDE::Startup::_term(@_)	if XDE::Startup->can('_term');
#    $self->XDE::Logout::_term(@_)	if XDE::Logout->can('_term');
#    $self->XDE::Input::_term(@_)	if XDE::Input->can('_term');
#    $self->XDE::Setbg::_term(@_)	if XDE::Setbg->can('_term');
#    $self->XDE::Settings::_term(@_)	if XDE::Settings->can('_term');
    return $self;
}

=item $xde->B<_getenv>() => $xde

Internal method to get information from the environment.  Called by
L<XDE::Context(3pm)> before its performs its own environment checks.
The user of this module should call C<$xde-E<gt>getenv()> instead of
this method.

=cut

sub _getenv {
    my $self = shift;
    $self->XDE::Chooser::_getenv(@_)	if XDE::Chooser->can('_getenv');
    $self->XDE::Setup::_getenv(@_)	if XDE::Setup->can('_getenv');
#    $self->XDE::Startup::_getenv(@_)	if XDE::Startup->can('_getenv');
#    $self->XDE::Logout::_getenv(@_)	if XDE::Logout->can('_getenv');
#    $self->XDE::Input::_getenv(@_)	if XDE::Input->can('_getenv');
#    $self->XDE::Setbg::_getenv(@_)	if XDE::Setbg->can('_getenv');
#    $self->XDE::Settings::_getenv(@_)	if XDE::Settings->can('_getenv');
    return $self;
}

=item $xde->B<_setenv>() => $xde

Internal method to set information into the environment.  Called by
L<XDE::Context(3pm)> after its performs its own snvironment writes.  The
user of this module should call C<$xde-E<gt>setenv()> instead of this
method.

=cut

sub _setenv {
    my $self = shift;
    $self->XDE::Chooser::_setenv(@_)	if XDE::Chooser->can('_setenv');
    $self->XDE::Setup::_setenv(@_)	if XDE::Setup->can('_setenv');
#    $self->XDE::Startup::_setenv(@_)	if XDE::Startup->can('_setenv');
#    $self->XDE::Logout::_setenv(@_)	if XDE::Logout->can('_setenv');
#    $self->XDE::Input::_setenv(@_)	if XDE::Input->can('_setenv');
#    $self->XDE::Setbg::_setenv(@_)	if XDE::Setbg->can('_setenv');
#    $self->XDE::Settings::_setenv(@_)	if XDE::Settings->can('_setenv');
    return $self;
}


=back

=cut

1;

__END__

=head1 BEHAVIOUR

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>, L<XDE::X11(3pm)>

=cut

# vim: sw=4 tw=72
