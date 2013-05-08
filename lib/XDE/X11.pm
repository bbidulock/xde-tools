package XDE::X11;
require X11::Protocol;
use base qw(X11::Protocol);
use Glib;
use Gtk2;

sub new {
    my $self = X11::Protocol::new(@_);
    return $self unless $self;
    $self->{event_handler} = 'queue';
    $self->{error_handler} = \&XDE::X11::_handle_error;
    $self->set_handler;
    return $self;
}

sub fh {
    my $self = shift;
    return $self->{connection}->fh;
}

sub fd {
    my $self = shift;
    return fileno($self->fh);
}

sub unset_handler {
    my $self = shift;
    my $tag = delete $self->{watcher};
    Glib::Source->remove($tag) if $tag;
    return $tag;
}

sub set_handler {
    my $self = shift;
    $self->unset_handler;
    my $tag = $self->{watcher} = Glib::IO->add_watch($self->fd, 'in',
	    sub{$self->_handle_input(@_)});
    return $tag;
}

sub _handle_input {
    my $self = shift;
    return Glib::SOURCE_CONTINUE;
}

sub _handle_error {
    my $self = 
}
