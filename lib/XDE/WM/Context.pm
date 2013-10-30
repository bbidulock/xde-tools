package XDE::WM::Context;
use base XDE::Context;
use File::Path;
use strict;
use warnings;

=head1 NAME

XDE::WM::Context - establish an XDE Window Manager environment context

=head1 SYNOPSIS

 use XDE::WM::Context;

 my $xde = XDE::WM::Context->new(%OVERRIDES,\%ops);

 $xde->getenv();
 $xde->setenv();

=head1 DESCRIPTION

=cut

use constant {
    MYENV => [qw(
	FLUXBOX_SYSDIR
	FLUXBOX_USRDIR
	FLUXBOX_RCFILE
	FLUXBOX_STYLEF
	BLACKBOX_SYSDIR
	BLACKBOX_USRDIR
	BLACKBOX_RCFILE
	BLACKBOX_STYLEF
	OPENBOX_SYSDIR
	OPENBOX_USRDIR
	OPENBOX_RCFILE
	OPENBOX_STYLEF
	ICEWM_SYSDIR
	ICEWM_USRDIR
	ICEWM_RCFILE
	ICEWM_STYLEF
	PEKWM_SYSDIR
	PEKWM_ETCDIR
	PEKWM_USRDIR
	PEKWM_RCFILE
	PEKWM_STYLEF
	JWM_SYSDIR
	JWM_USRDIR
	JWM_RCFILE
	JWM_STYLEF
	FVWM_SYSDIR
	FVWM_USRDIR
	FVWM_RCFILE
	FVWM_STYLEF
	AFTERSTEP_SYSDIR
	AFTERSTEP_USRDIR
	AFTERSTEP_RCFILE
	AFTERSTEP_STYLEF
	METACITY_SYSDIR
	METACITY_USRDIR
	METACITY_RCFILE
	METACITY_STYLEF
	WMX_SYSDIR
	WMX_USRDIR
	WMX_RCFILE
	WMX_STYLEF
	FVWM_USERDIR
	ICEWM_PRIVCFG
	GNUSTEP_USER_ROOT
    )],
};

=head1 METHODS

The following methods are provided:

=over

=item $xde = XDE::WM::Context->B<new>(I<%OVERRIDES>,ops=>\I<%ops>)

Creates a new instance of an XDE::WM::Context object and returnes a
bless hash reference.  The XDE::WM::Context module uses the
L<XDG::Context(3pm)> module as a base, so the C<%OVERRIDES> are simply
passed to the L<XDG::Context(3pm)> module.  When an options hash,
I<%ops>, is passed to the method, it is initialized with default option
values.  See L</OPTIONS> for detailes on the options recognized by this
module.

=cut

sub new {
    return XDE::Context::new(@_);
}

=item $Xde->B<xde_wm_default>() => $xde

Internal method to establish defaults for the XDE::WM::Context object
without invoking the defaults of the superior module: used for multiple
inheritance.  Normally called by the B<default> method of this package
or a derived package.  Establishes a wide range of XDG and XDE session
parameters and defaults.
This method may or may not be indempotent.

=cut

sub xde_wm_default {
    my $self = shift;
    # set up fluxbox defaults
    $self->{FLUXBOX_SYSDIR} = ''
	unless $self->{FLUXBOX_SYSDIR};
    $self->{FLUXBOX_SYSDIR} = '/usr/share/fluxbox'
	unless $self->{FLUXBOX_SYSDIR};
    $self->{FLUXBOX_USRDIR} = ''
	unless $self->{FLUXBOX_USRDIR};
    $self->{FLUXBOX_USRDIR} = "$self->{HOME}/.fluxbox"
	unless $self->{FLUXBOX_USRDIR};
    $self->{FLUXBOX_RCFILE} = ''
	unless $self->{FLUXBOX_RCFILE};
    $self->{FLUXBOX_RCFILE} = "$self->{FLUXBOX_USRDIR}/init"
	unless $self->{FLUXBOX_RCFILE};
    $self->{FLUXBOX_STYLEF} = ''
	unless $self->{FLUXBOX_STYLEF};
    $self->{FLUXBOX_STYLEF} = $self->{FLUXBOX_RCFILE}
	unless $self->{FLUXBOX_STYLEF};
    # set up blackbox defaults
    $self->{BLACKBOX_SYSDIR} = ''
	unless $self->{BLACKBOX_SYSDIR};
    $self->{BLACKBOX_SYSDIR} = '/usr/share/blackbox'
	unless $self->{BLACKBOX_SYSDIR};
    $self->{BLACKBOX_USRDIR} = ''
	unless $self->{BLACKBOX_USRDIR};
    $self->{BLACKBOX_USRDIR} = "$self->{HOME}/.blackbox"
	unless $self->{BLACKBOX_USRDIR};
    $self->{BLACKBOX_RCFILE} = ''
	unless $self->{BLACKBOX_RCFILE};
    $self->{BLACKBOX_RCFILE} = "$self->{HOME}/.blackboxrc"
	unless $self->{BLACKBOX_RCFILE};
    $self->{BLACKBOX_STYLEF} = ''
	unless $self->{BLACKBOX_STYLEF};
    $self->{BLACKBOX_STYLEF} = $self->{BLACKBOX_RCFILE}
	unless $self->{BLACKBOX_STYLEF};
    # set up openbox defaults
    $self->{OPENBOX_SYSDIR} = ''
	unless $self->{OPENBOX_SYSDIR};
    $self->{OPENBOX_SYSDIR} = '/usr/share/openbox'
	unless $self->{OPENBOX_SYSDIR};
    $self->{OPENBOX_USRDIR} = ''
	unless $self->{OPENBOX_USRDIR};
    $self->{OPENBOX_USRDIR} = "$self->{XDG_CONFIG_HOME}/openbox"
	unless $self->{OPENBOX_USRDIR};
    $self->{OPENBOX_RCFILE} = ''
	unless $self->{OPENBOX_RCFILE};
    $self->{OPENBOX_RCFILE} = "$self->{OPENBOX_USRDIR}/rc.xml"
	unless $self->{OPENBOX_RCFILE};
    $self->{OPENBOX_STYLEF} = ''
	unless $self->{OPENBOX_STYLEF};
    $self->{OPENBOX_STYLEF} = $self->{OPENBOX_RCFILE}
	unless $self->{OPENBOX_STYLEF};
    # set up icewm defaults
    $self->{ICEWM_SYSDIR} = ''
	unless $self->{ICEWM_SYSDIR};
    $self->{ICEWM_SYSDIR} = '/usr/share/icewm'
	unless $self->{ICEWM_SYSDIR};
    $self->{ICEWM_PRIVCFG} = ''
	unless $self->{ICEWM_PRIVCFG};
    $self->{ICEWM_PRIVCFG} = "$self->{HOME}/.icewm"
	unless $self->{ICEWM_PRIVCFG};
    $self->{ICEWM_USRDIR} = ''
	unless $self->{ICEWM_USRDIR};
    $self->{ICEWM_USRDIR} = $self->{ICEWM_PRIVCFG}
	unless $self->{ICEWM_USRDIR};
    $self->{ICEWM_RCFILE} = ''
	unless $self->{ICEWM_RCFILE};
    $self->{ICEWM_RCFILE} = "$self->{ICEWM_USRDIR}/preferences"
	unless $self->{ICEWM_RCFILE};
    $self->{ICEWM_STYLEF} = ''
	unless $self->{ICEWM_STYLEF};
    $self->{ICEWM_STYLEF} = "$self->{ICEWM_USRDIR}/theme"
	unless $self->{ICEWM_STYLEF};
    # set up pekwm defaults
    $self->{PEKWM_SYSDIR} = ''
	unless $self->{PEKWM_SYSDIR};
    $self->{PEKWM_SYSDIR} = '/usr/share/pekwm'
	unless $self->{PEKWM_SYSDIR};
    $self->{PEKWM_USRDIR} = ''
	unless $self->{PEKWM_USRDIR};
    $self->{PEKWM_USRDIR} = "$self->{HOME}/.pekwm"
	unless $self->{PEKWM_USRDIR};
    $self->{PEKWM_RCFILE} = ''
	unless $self->{PEKWM_RCFILE};
    $self->{PEKWM_RCFILE} = "$self->{PEKWM_USRDIR}/config"
	unless $self->{PEKWM_RCFILE};
    $self->{PEKWM_STYLEF} = ''
	unless $self->{PEKWM_STYLEF};
    $self->{PEKWM_STYLEF} = $self->{PEKWM_RCFILE}
	unless $self->{PEKWM_STYLEF};
    # set up jwm defaults
    $self->{JWM_SYSDIR} = ''
	unless $self->{JWM_SYSDIR};
    $self->{JWM_SYSDIR} = '/usr/share/fluxbox'
	unless $self->{JWM_SYSDIR};
    $self->{JWM_USRDIR} = ''
	unless $self->{JWM_USRDIR};
    $self->{JWM_USRDIR} = "$self->{HOME}/.fluxbox"
	unless $self->{JWM_USRDIR};
    $self->{JWM_RCFILE} = ''
	unless $self->{JWM_RCFILE};
    $self->{JWM_RCFILE} = "$self->{JWM_USRDIR}/init"
	unless $self->{JWM_RCFILE};
    $self->{JWM_STYLEF} = ''
	unless $self->{JWM_STYLEF};
    $self->{JWM_STYLEF} = $self->{JWM_RCFILE}
	unless $self->{JWM_STYLEF};
    return $self;
}

=item $xde->B<getenv>()

Read environment variables into the context and recalculate defaults.
Environment variables examined are a number of variables typcially set
by L<xde-session(1p)> and those described under
L<XDE::Context(3pm)/getenv>.  Also calls C<_getenv> of the derived class
when available.  This method may or may not be idempotent.

=cut

sub getenv {
    my $self = shift;
    if (my $sub = $self->can('_getenv')) { &$sub($self,@_) }
    foreach (@{&MYENV}) { $self->{$_} = $ENV{$_} }
    return $self->SUPER::getenv(@_);
}

1;

__END__

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>,
L<XDG::Context(3pm)>,
L<XDE(3pm)>.

=cut

# vim: set sw=4 tw=72 fo=tcqlorn:
