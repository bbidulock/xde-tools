package XDE::Gtk2;
use base qw(XDE::Glib);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Gtk2 -- a Gtk2 implementation object for an XDE context

=head1 DESCRIPTION

Provides a package based on L<XDE::Glib(3pm)> that provides a
L<Gtk2(3pm)> implementation object for the L<XDE(3pm)> context.  This
package integrates the L<Gtk2(3pm)> main event loop into an L<XDE(3pm)>
context.

=head1 METHODS

=over

=cut

=item $xde = B<new> XDE::Gtk2 I<%OVERRIDES> => blessed HASHREF

Obtains a new B<XDE::Gtk2> object.  For the use of I<%OVERRIDES> see
L<XDE::Context(3pm)>.  This package is based on the L<XDE::Glib(3pm)>
package and simply calls its C<new> method with all arguments intact.

=cut

sub new {
    return XDE::Glib::new(@_);
}

=item $xde->B<init>()

Use this function instead of C<Gtk2-E<gt>init> to initialize the Gtk2
toolkit using the environment from the L<XDE::Context(3pm)> object.
The client must call C<$xde-E<gt>setenv()> before calling this method.

=cut

sub init {
    my $self = shift;
    # $self->setenv();  # so Gtk2 sees the proper environment variables
    my %ops = %{$self->{ops}};
    # Do this before Gtk2->init so that we can set the proper theme
    # file.
    if ($ops{theme}) {
	my $gtk2rcs = $self->get_gtk2rcs;
	if (exists $gtk2rcs->{$ops{theme}}) {
	}
    }
    Gtk2->init;
    my $theme = Gtk2::IconTheme->get_default;
    if ($self->{XDG_ICON_PREPEND} or $self->{XDG_ICON_APPEND}) {
	if ($self->{XDG_ICON_PREPEND}) {
	    foreach (reverse split(/:/,$self->{XDG_ICON_PREPEND})) {
		$theme->prepend_search_path($_);
	    }
	}
	if ($self->{XDG_ICON_APPEND}) {
	    foreach (split(/:/,$self->{XDG_ICON_APPEND})) {
		$theme->append_search_path($_);
	    }
	}
    }
    $theme->signal_connect_swapped(changed=>sub{shift->icon_theme_changed(@_)},$self);
}

=item $xde->B<main>()

Use this function instead of C<Gtk2-E<gt>main> to run the event loop.

=cut

sub main {
    my $self = shift;
    unshift @{$self->{retval}}, undef;
    $SIG{TERM} = sub{Gtk2->main_quit};
    $SIG{INT}  = sub{Gtk2->main_quit};
    $SIG{QUIT} = sub{Gtk2->main_quit};
    Gtk2->main;
    return shift @{$self->{retval}};
}

=item $xde->B<main_quit>(I<$retval>)

Use this function instead of C<Gtk2-E<gt>main_quit>.

=cut

sub main_quit {
    my $self = shift;
    $self->{retval}[0] = shift if @{$self->{retval}};
    Gtk2->main_quit;
}

=item $xde->B<get_gtk2rcs>() => HASHREF or (HASHREF, HASHREF)

Search out all L<Gtk2(3pm)> themes directories and collect L<Gtk2(3pm)>
themes into a hash reference.  The keys of the hash are the names of the
names of the theme subdirectory in which the F<gtk2rc> file resided.
Themes follow XDG precedence rules for XDG data directories.

Also establishes a hash reference in $xde-E<gt>{dirs}{gtkrc} that contains
all of the directories searched (whether they existed or not) for use in
conjunction with L<Linux::Inotify2(3pm)>, (see L<XDE::Notify(3pm)>).  In
a list context, both the file hash and directory hash references are
returned.

=cut

sub get_gtk2rcs {
    my $self = shift;
    my %gtk2rcdirs = ();
    my %gtk2rcs = ();
    foreach my $d (reverse map {"$_/themes"} @{$self->{XDG_DATA_ARRAY}}) {
	$gtk2rcdirs{$d} = 1;
	opendir(my $dir, $d) or next;
	foreach my $s (readdir($dir)) {
	    next if $s eq '.' or $s eq '..';
	    next unless -d "$d/$s";
	    my $f = "$d/$s/gtk-2.0/gtkrc";
	    next unless -f $f;
	    $gtk2rcs{$s} = $f;
	}
	closedir($dir);
    }
    $self->{dirs}{gtk2rc} = \%gtk2rcdirs;
    $self->{objs}{gtk2rc} = \%gtk2rcs;
    return (\%gtk2rcs,\%gtk2rcdirs) if wantarray;
    return \%gtk2rcs;
}

=item $xde->B<icon_theme_changed>(I<$theme>) = Glib event flag

Processes C<changed> signals on the L<Gtk2::IconTheme(3pm)>.  Not meant
to be called directly.  The derived module can override this method if
it is interested in receiving notification of theme changes.
L<XDE::MenuGen(3pm)> or L<XDE::TrayMenu(3pm)> might want to regenerate
the menu when the icon theme changes.

=cut

sub icon_theme_changed {
    my ($self,$theme) = @_;
    return Gtk2::EVENT_PROPAGATE;
}

=item $xde->B<get_icon>(I<$size>,I<$stock>,I<@choices>) => Gtk2::Image

Retrieve a L<Gtk2::Image(3pm)> for a specified icon with size, C<$size>,
possible names (in order of preference), C<@choices>, and fall-back
stock icon name, C<$stock>.  Returns a L<Gtk2::Image(3pm)> or C<undef>
if neither an image in C<@choices> nor the C<$stock> icon could be found
in the icon theme.

=cut

sub get_icon {
    my ($self,$size,$stock,@choices) = @_;
    my $theme = Gtk2::IconTheme->get_default;
    foreach (@choices) {
	if ($theme->has_icon($_)) {
	    print STDERR "Found icon $_\n" if $self->{ops}{verbose};
	    return Gtk2::Image->new_from_icon_name($_,$size);
	}
    }
    print STDERR "Using stock $stock\n" if $self->{ops}{verbose};
    return Gtk2::Image->new_from_stock($stock,$size);
}

=back

=cut

1;

__END__

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Context(3pm)>,
L<XDE::Glib(3pm)>,
L<Linux::Inotify2(3pm)>,
L<XDE::Notify(3pm)>,
L<XDE::MenuGen(3pm)>,
L<XDE::TrayMenu(3pm)>,
L<Gtk2::Image(3pm)>.

=cut

# vim: sw=4 tw=72 nocin
