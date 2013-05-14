package XDE::Gtk2;
use base qw(XDE::Glib);
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Gtk2 -- a Gtk2 implementation object for an XDE context

=cut

=head1 METHODS

=over

=cut

=item $xde = XDE::Gtk2->new(%OVERRIDES) => blessed HASHREF

Obtains a new B<XDE::Gtk2> object.  For the use of I<%OVERRIDES> see
L<XDE::Context(3pm)>.

=cut

sub new {
    return XDE::Glib::new(@_);
}

=item $xde->init()

Use this function instead of C<Gtk2->init> to initialize the Gtk2
toolkit using the environment from the L<XDE::Context(3pm)> object.

=cut

sub init {
    my $self = shift;
    $self->setenv();  # so Gtk2 sees the proper environment variables
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

=item $xde->main()

Use this function instead of C<Gtk2->main> to run the event loop.

=cut

sub main {
    my $self = shift;
    push @{$self->{retval}}, undef;
    $SIG{TERM} = sub{Gtk2->main_quit};
    Gtk2->main;
    return pop @{$self->{retval}};
}

=item $xde->B<icon_theme_changed>(I<$theme>) = Glib event flag

Processes C<changed> signals on the Gtk2::IconTheme.  Not meant to be
called directly.  The derived module can override this method if it is
interested in receiving notification of theme changes.
L<XDE::MenuGen(3pm)> or L<XDE::TrayMenu(3pm)> might want to regenerate
the menu when the icon theme changes.

=cut

sub icon_theme_changed {
    my ($self,$theme) = @_;
    return Gtk2::EVENT_PROPAGATE;
}

=item $xde->B<get_gtk2rcs>() => HASHREF or (HASHREF, HASHREF)

Search out all Gtk2 themes directories and collect Gtk2 themes into a
hash reference.  The keys of the hash are the names of the names of the
theme subdirectory in which the gtk2rc file resided.  Themes follow XDG
precedence rules for XDG data directories.

Also establishes a hash reference in $xde->{dirs}{gtkrc} that contains
all of the directories search (whether they existed or not) for use in
conjunction with L<Linux::Inotify2(3pm)>.  In a list context, both the
file hash and directory hash are returned.

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

=back

=cut

1;

# vim: sw=4 tw=72 nocin
