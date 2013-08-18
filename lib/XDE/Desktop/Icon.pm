package XDE::Desktop::Icon;
use XDE::Desktop::Image;
use X11::Protocol;
use Glib qw(TRUE FALSE);
use Gtk2;
use strict;
use warnings;

=head1 NAME

XDE::Desktop::Icon -- base class for desktop icons

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

=item XDE::Desktop::Icon->B<new>(I<$desktop>,I<$icon_name>,I<$label>) => $Icon

Create a new instance of an XDE::Desktop::Icon.  This base class
constructor is meant to be called only from the derived classes
L<XDE::Desktop::Icon::Shortcut(3pm)>,
L<XDE::Desktop::Icon::Directory(3pm)> and
L<XDE::Desktop::Icon::File(3pm)>.  C<$desktop> is an instance of an
L<XDE::Desktop(3pm)> providing the content for the icon, C<$icon_name>,
which is the icon name to provide, and I<$label> is the label to use for
the desktop icon.

=cut

sub new {
    my ($type,$desktop,$names,$label,$id) = @_;
     #print STDERR "-> Creating desktop icon for '$names' and '$label'\n";
    my $self = bless {
	X=>$desktop->{X},
	id=>$id,
	names=>$names,
	label=>$label,
	format=>$desktop->{format},
	argb32=>$desktop->{argb32},
	visual=>$desktop->{visual},
    }, $type;

    $self->{image} = $desktop->get_image($names,$id);

    return $self;
}

=item $icon->B<create>() => $xid

Create a window for the desktop icon.  Returns the XID of the window,
C<$xid>, which is also accesible as C<$icon-E<gt>{window}>.

=cut

sub create {
    my $self = shift;
    return $self->{window} if $self->{window};
    my $X = $self->{X};
    $self->{x} = -72;
    $self->{y} = -72;
    $self->{window} = $X->new_rsrc;
    $X->CreateWindow($self->{window},$X->root,'InputOutput',
	    0,'CopyFromParent',
	    $self->{x},$self->{y},72,72,0,
	    background_pixmap=>'ParentRelative',
	    backing_store=>'Always',
	    override_redirect=>1,
#	    save_under=>0,
	    event_mask=>$X->pack_event_mask(qw(
		    Exposure
		    VisibilityChange
		    EnterWindow
		    LeaveWindow
	    )),
#	    do_not_propagate_mask=>0,
	    colormap=>'CopyFromParent',
	);
    $X->GetGeometry($self->{window}); # XSync
    $self->{gtkwin} = Gtk2::Gdk::Window->foreign_new($self->{window});
    $self->{gtkwin}->set_events([qw(button-press-mask button-motion-mask
		button-release-mask)]);
    $self->{wpict} = $X->new_rsrc;
    $X->RenderCreatePicture($self->{wpict},$self->{window},$self->{format});
    $X->ShapeMask($self->{window},'Boundary','Set',12,12,$self->{image}{bitmap});
    return $self->{window};
}

=item $icon->B<DESTROY>()

Destroy a desktop icon.  This must destroy the X window resource.

=cut

sub DESTROY {
    my $self = shift;
    if (my $X = delete $self->{X}) {
	$X->RenderFreePicture(delete $self->{wpict}) if $self->{wpict};
	$X->DestroyWindow(delete $self->{window}) if $self->{window};
    }
}

=item $icon->B<update>()

Updates the display of the icon on the screen.  This method has no
effect unless the window is visible.

=cut

sub update_noflush {
    my ($self) = @_;
    my $X = $self->{X};
    if ($self->{visible}) {
	$X->ClearArea($self->{window},0,0,0,0,0);
	$X->RenderComposite('Over',$self->{image}{ipict},$self->{image}{mpict},$self->{wpict},(0,0),(0,0),(12,12),(48,48));
    }
}

sub update {
    my $self = shift;
    $self->update_noflush(@_);
    $self->{X}->flush;
}

sub expose_noflush {
    my ($self,$e) = @_;
    my $X = $self->{X};
    $X->RenderComposite('Over',$self->{image}{ipict},$self->{image}{mpict},$self->{wpict},
	    ($e->{x}-12,$e->{y}-12),
	    ($e->{x}-12,$e->{y}-12),
	    ($e->{x},$e->{y}),
	    ($e->{width},$e->{height}));
}

sub expose {
    my $self = shift;
    $self->expose_noflush(@_);
    $self->{X}->flush;
}

sub visible_noflush {
    my ($self,$state) = @_;
    if ($state eq 'FullyObscured') {
	$self->{visible} = 0;
    } else {
	unless ($self->{visible}) {
	    $self->{visible} = 1;
	    $self->update_noflush;
	}
    }
}

sub visible {
    my $self = shift;
    $self->visible_noflush(@_);
    $self->{X}->flush;
}

=item $icon->B<show>()

Shows the desktop icon for this instance.  This shows the desktop icon,
but only if it is not already visible.  This method has no effect when
the desktop icon is already visible.

=cut

sub show_noflush {
    my ($self) = @_;
    my $X = $self->{X};
    $X->ConfigureWindow($self->{window},stack_mode=>'Below');
    $X->MapWindow($self->{window});
}

sub show {
    my $self = shift;
    $self->show_noflush(@_);
    $self->{X}->flush;
}

=item $icon->B<hide>()

Hides the desktop icon for this instance.  This simply withdraws the
window for the desktop icon.  This method has no effect when the desktop
icon is not visible.

=cut

sub hide_noflush {
    my $self = shift;
    my $X = $self->{X};
    $X->UnmapWindow($self->{window});
}

sub hide {
    my $self = shift;
    $self->hide_noflush(@_);
    $self->{X}->flush;
}

=item $icon->B<place>(I<$x>,I<$y>)

Moves the desktop icon to the specified position, C<$x> and C<$y>, but
only if the icon is truly changing position.

=cut

sub place_noflush {
    my ($self,$x,$y) = @_;
    my $X = $self->{X};
    $X->ConfigureWindow($self->{window},x=>$x,y=>$y);
    $self->{x} = $x;
    $self->{y} = $y;
    $self->update_noflush;
}

sub place {
    my $self = shift;
    $self->place_noflush(@_);
    $self->{X}->flush;
}

sub enter {
    my ($self,$e,$X,$v,$desktop) = @_;
    printf STDERR "Entering window 0x%x: %s\n", $self->{window},
	   $self->{label};
    $desktop->{showtip} = $self->{label};
    $desktop->{ttipwin}->trigger_tooltip_query;
}

sub leave {
    my ($self,$e,$X,$v,$desktop) = @_;
    printf STDERR "Leaving window 0x%x: %s\n", $self->{window},
	   $self->{label};
    $desktop->{showtip} = undef;
    $desktop->{ttipwin}->trigger_tooltip_query;
}

sub press {
    my $self = shift;
    my ($e,$X,$v) = @_;
    if ($e->{detail} == 2) {
	# button 2 was pressed
	$self->{button2} = $e;
	$e->{drag_x} = $self->{x};
	$e->{drag_y} = $self->{y};
    }
    elsif ($e->{detail} == 3) {
	# button 3 was pressed
	$self->{button3} = $e;
    }
}

sub motion {
    my ($self,$e,$X,$v) = @_;
    if (my $b = $self->{button2}) {
	my $x = $b->{drag_x} + $e->{root_x} - $b->{root_x};
	my $y = $b->{drag_y} + $e->{root_y} - $b->{root_y};
	$self->place($x,$y);
    }
}

sub release {
    my $self = shift;
    my ($e,$X,$v) = @_;
    if ($e->{detail} == 2) {
	delete $self->{button2};
    }
    elsif ($e->{detail} == 3) {
	delete $self->{button3};
	$self->popup(@_)
	    if $self->can('popup');
    }
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
