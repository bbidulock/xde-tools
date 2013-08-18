package XDE::Desktop3;
use base qw(XDE::Dual);
use Glib qw(TRUE FALSE);
use strict;
use warnings;

sub new {
    return XDE::Context::new(@_);
}

sub _init {
    my $self = shift;
    my $X = $self->{X};
    $X->init_extensions;
}

sub create_window {
    my ($self,$fn) = @_;
    my $X = $self->{X};
    my $win = $X->new_rsrc;
    $X->CreateWindow($win, $X->root, 'InputOutput',
	    $X->root_depth, 'CopyFromParent',
	    36,36,48,48,0,
#	    override_redirect=>1,
	    background_pixmap=>'None',
#	    background_pixmap=>'ParentRelative',
	    backing_store=>'Always',
	    save_under=>1,
	    event_mask=>$X->pack_event_mask(qw(
		    Exposure ButtonPress ButtonRelease KeyPress
		    KeyRelease StructureNotify SubstructureNotify
		    PropertyChange)),
	);
    $X->GetGeometry($win); # sync with server
    my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($fn);
    my $bitmap = $X->new_rsrc;
    $X->CreatePixmap($bitmap,$X->root,1,(48,48));
    $X->GetGeometry($bitmap); # sync with server
    my $mask = Gtk2::Gdk::Bitmap->foreign_new($bitmap);
#    $pixbuf->render_threshold_alpha($mask,(0,0),(0,0),(48,48),1);
#    $X->ShapeMask($win,Bounding=>'Set',0,0,$bitmap);
#    $X->ShapeMask($win,Clip=>'Set',0,0,$bitmap);
#    $X->GetGeometry($win);
    my $gtk = Gtk2::Gdk::Window->foreign_new($win);
#    my $cr = Gtk2::Gdk::Cairo::Context->create($gtk);
#    $cr->set_source_pixbuf($pixbuf,0,0);
#    $cr->paint;
#    sleep 1;
    $X->MapWindow($win);
    $X->GetGeometry($win);
    $self->{windows}{$win} = [ $pixbuf, $gtk, $mask ];
#    $self->{windows}{$win} = $pixbuf;
    return $win;
}

sub update_window {
    my $self = shift;
    my ($e,$X,$v) = @_;
    my $win = $e->{window};
    return unless $self->{windows}{$win};
    my ($pixbuf,$gtk,$mask) = @{$self->{windows}{$win}};
    $X->ClearArea($win,0,0,0,0,0);
    $X->GetGeometry($win);
    $pixbuf->render_threshold_alpha($mask,(0,0),(0,0),(48,48),1);
    my $bitmap = $mask->get_xid;
    $X->ShapeMask($win,Bounding=>'Set',0,0,$bitmap);
#    $X->ShapeMask($win,Clip=>'Set',0,0,$bitmap);
    $X->GetGeometry($win);
    my $cr = Gtk2::Gdk::Cairo::Context->create($gtk);
    $cr->set_source_pixbuf($pixbuf,0,0);
    $cr->paint;
}

sub event_handler_Expose {
    my $self = shift;
    my ($e,$X,$v) = @_;
    $self->update_window(@_);
}

1;

__END__

# vim: set sw=4 tw=72:
