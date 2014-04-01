package XDG::IconData;
use strict;
use warnings;

sub new {
    my $self = bless {}, shift;
    my $file = $self->{file} = shift;
    return undef unless -f $file;
    open(my $fh, "<", $file) or warn $!;
    return undef unless $fh;
    my $parsing = 0;
    while (<$fh>) {
	if (/^\[/) {
	    if (/^\[Icon Data\]/) {
		$parsing = 1;
	    }
	    elsif (/^\[.*\]/) {
		$parsing = 0;
	    }
	}
	elsif ($parsing and /^([^=]*)=([^[:cntrl:]]*)/) {
	    my ($label,$value) = ($1,$2);
	    $self->{$label} = $value
		unless $label =~ /[[]/;  # skip xlations for now
	}
    }
    close($fh);
    return $self;
}

1;
