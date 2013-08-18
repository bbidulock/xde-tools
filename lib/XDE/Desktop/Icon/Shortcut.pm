package XDE::Desktop::Icon::Shortcut;
use base qw(XDE::Desktop::Icon);
use X11::Protocol;
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Icon::Shortcut -- desktop shortcut

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=item $shortcut = XDE::Desktop::Icon::Shortcut->B<new>(I<$desktop>,I<$filename>,I<$x>,I<$y>)

Creates an instance of an XDE::Desktop::Icon::Shortcut object.  A
shortcut corresponds to a freedesktop.org F<.desktop> file.
C<$desktop> is an instance of an XDE::Desktop object, and C<$filename>
is the full path and file name of the F<.desktop> file to which the
shortcut corresponds.  C<$x> and C<$y> are the x- and y-coordinates of
the upper-left corner of the cell on which to render the icon and label.

This method identifies the icon and label associated with the shortcut
and then calls XDE::Desktop::Icon->new() to create the desktop icon.
The icon is determined from the C<Icon> entry in the F<.desktop> file
and the label is determined from the C<Name> entry.

Any invalid shortcut file will be represented simply as a
XDE::Desktop::Icon::File instance instead.

=cut

sub new {
    my ($type,$desktop,$filename,$x,$y) = @_;
    return undef unless -f $filename;
    open (my $fh, "<", $filename) or warn $!;
    return undef unless $fh;
    my $parsing = 0;
    my $id = $filename;
    $id =~ s{^.*\/}{}; $id =~ s{\.desktop$}{};
    my %e = (file=>$filename,id=>$id);
    my %xl = ();
    while (<$fh>) {
	if (/^\[([^]]*)\]/) {
	    my $section = $1;
	    if ($section eq 'Desktop Entry') {
		$parsing = 1;
	    } else {
		$parsing = 0;
	    }
	}
	elsif ($parsing and /^([^=\[]+)\[([^=\]]+)\]=([^[:cntrl:]]*)/) {
	    $xl{$1}{$2} = $3;
	}
	elsif ($parsing and /^([^=]*)=([^[:cntrl:]]*)/) {
	    $e{$1} = $2 unless exists $e{$1};
	}
    }
    close($fh);
    $desktop->{ops}{lang} =~ m{^(..)}; my $short = $1;
    foreach (keys %xl) {
	if (exists $xl{$_}{$desktop->{ops}{lang}}) {
	    $e{$_} = $xl{$_}{$desktop->{ops}{lang}};
	}
	elsif (exists $xl{$_}{$short}) {
	    $e{$_} = $xl{$_}{$short};
	}
    }
    $e{Name} = $id unless $e{Name};
    $e{Exec} = '' unless $e{Exec};
    $e{Comment} = $e{Name} unless $e{Comment};
    $e{Icon} = $id unless $e{Icon};
    $e{Icon} =~ s{\.(png|jpg|xpm|svg|jpeg)$}{};
    my $self = XDE::Desktop::Icon::new($type,$desktop,$e{Icon},$e{Name},$id);
    $self->{entry} = \%e;
    return $self;
}

=item $shortcut->B<open>()

This method performs the default open action associated with the
shortcut.

=cut

sub open {
}

=item $shortcut->B<popup>(I<$event>)

This method pops up a menu associated with the shortcut.

=cut

sub popup {
    my $self = shift;
    my ($e,$X,$v) = @_;
    print STDERR "Popping up ", ref($self), " menu, time $e->{time}.\n";
    my $menu = $self->{menu};
    unless ($menu) {
	$menu = Gtk2::Menu->new;
	$menu->signal_connect(map=>sub{
		my $menu = shift;
		my $window = $menu->get_toplevel;
		$window->set_opacity(0.92) if $window;
		return Gtk2::EVENT_PROPAGATE;
	});
	my $item = Gtk2::TearoffMenuItem->new;
	$item->show_all;
	$menu->append($item);

	$item = Gtk2::ImageMenuItem->new;
	$item->set_label('Launch');
	my $image = Gtk2::Image->new_from_icon_name('gtk-execute','menu');
	$item->set_image($image) if $image;
	my $command = $self->{entry}{Exec};
	$command = 'false' unless $command;
	$item->signal_connect(activate=>sub{
		system "$command &";
	});
	$item->show_all;
	$menu->append($item);

	$item = Gtk2::SeparatorMenuItem->new;
	$item->show_all;
	$menu->append($item);
	$menu->visible(Glib::TRUE);
	$self->{menu} = $menu;
    }
    $menu->popup(undef,undef,undef,undef,$e->{detail},$e->{time});
}

1;

=back

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<XDE::Desktop(3pm)>, L<XDE::Desktop::Icon(3pm)>

=cut


__END__

# vim: set sw=4 tw=72:
