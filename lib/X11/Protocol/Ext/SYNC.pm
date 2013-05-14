
# The X Sychronization Extension Protocol
package X11::Protocol::Ext::XSYNC;

use X11::Protocol qw(make_num_hash);
use Carp;
use strict;
use warnings;
use vars '$VERSION';
$VERSION = 0.01;

=head1 NAME

X11::Protocol::Ext::XSYNC -- Perl extention module for X Synchronization Extension Protocol

=head1 SYNOPSIS

 use X11::Protocol;
 $x = X11::Protocol->new($ENV{DISPLAY});
 $x->init_extension('XSYNC') or die;

=head1 DESCRIPTION

This module is used by the L<X11::Protocol(3pm)> module to participate
in the synchronization extension to the X protocol, allowing
time synchronization between clients and to absolute real-time sources
per the L<X Synchronization Extension Protocol>, a copy of which can be
obtained from L<http://www.x.org/releases/X11R7.7/doc/xextproto/sync.pdf>.

This manual page does not attempt to document the protocol itself, see
the specification for that.  It documents the L</CONSTANTS>,
L</REQUESTS>, L</EVENTS> and L</ERRORS> that are added to the
L<X11::Protocol(3pm)> module.

=cut

sub new
{
    my $self = bless {}, shift;
    my ($x, $request_base, $event_base, $error_base) = @_;
    
=head1 CONSTANTS

B<X11::Protocol::Ext::XSYNC> provides the following symbolic constants:

 ValueType  => [ 'Absolute', 'Relative' ]
 TestType   => [ 'PositiveTransition', 'NegativeTransition',
	         'PositiveCommparison', 'NegativeComparison' ]
 AlarmState => [ 'Active', 'Inactive', 'Destroyed' ]

=cut

 $x->{ext_const}{ValueType}  = [ qw(Absolute Relative) ];
 $x->{ext_const}{TestType}   = [ qw(PositiveTransition
				    NegativeTransition
				    PositiveComparison
				    NegativeComparison) ];
 $x->{ext_const}{AlarmState} = [ qw(Active Inactive Destroyed) ];

 $x->{ext_const_num}{$_} = {make_num_hash($x->{ext_const}{$_})}
     foreach (qw(ValueType TestType AlarmState));

=head1 ERRORS

B<X11::Protocol::Ext::XSYNC> provides the folowing bad resource errors:
C<Counter>, C<Alarm>, C<Fence>.

=cut
    {
	my $i = $error_base;
	foreach (qw(Counter Alarm Fence)) {
	    $x->{ext_const}{Error}[$i] = $_;
	    $x->{ext_const_num}{Error}{$_} = $i;
	    $x->{ext_error_type}[$i] = 1; # bad resource
	}
    }

=head1 REQUESTS

B<X11::Protocol::Ext::XSYNC> provides the following requests:

=cut
    $x->{ext_request}{$request_base} =
    [
=pod

 $X->XsyncQueryVersion()
 =>
 ($major,$minor)
=cut
	[XsyncQueryVersion => sub{	#  0
	    pack('xxSCCxx',2,3,1);
	}, sub {
	    unpack('xxxxxxxxCCxxxxxxxxxxxxxxxxxxxxxx',$_[1]);
	}],
=pod

 $X->ListSystemCounters()
 =>
 ( [ $counter,$resolution_hi,$resolution_lo ], ... )
=cut
	[ListSystemCounters => sub{	#  1
	    pack('xxS',0);
	}, sub {
	    my ($x,$data) = @_;
	    my ($llen,@counters) =
		unpack('xxxxxxxxlxxxxxxxxxxxxxxxxxxxx',$data);
	    my $counters = substr($data,32);
	    while ($llen>0 and length($counters)>=16) {
		my ($counter,$reshi,$reslo,$len,$name) =
		    unpack('LLLS',$counters);
		$counters = substr($counters,14);
		$name = substr($counters,0,$len);
		$counters = substr($counters,$len+(-$len&3));
		push @counters, [ $counter, $res_hi, $res_lo, $name, ];
	    }
	    return (@counters);
	}],
=pod

 $X->CreateCounter($id,($initial_value_hi,$initial_value_lo))
=cut
	[CreateCounter => sub{		#  2
	    pack('xxSLLL',4,$_[1..3]);
	}],
=pod

 $X->SetCounter($counter,($value_hi,$value_lo))
=cut
	[SetCounter => sub{		#  3
	    pack('xxSLLL',4,$_[1..3]);
	}],
=pod

 $X->ChangeCounter($counter,($amount_hi,$amount_lo))
=cut
	[ChangeCounter => sub{		#  4
	    pack('xxSLLL',4,$_[1..3]);
	}],
	undef,				#  5
=pod

 $X->DestroyCounter($counter)
 =>
 ($counter_hi,$counter_lo)
=cut
	[DestroyCounter => sub{		#  6
	    pack('xxSL',2,$_[1]);
	}, sub {
	    unpack('xxxxxxxxLLxxxxxxxxxxxxxxxx',$_[1]);
	}],
=pod

 $X->Await([$trigger,($thresh_hi,$thresh_lo)], ...)
=cut
	[Await => sub{			#  7
	    shift; join('',pack('xxS',(1+7*scalar(@_))),
		       map{pack('a[20]LL',@$_)}@_);
	}],
=pod

 $X->CreateAlarm($id,
    counter=>$counter,
    value_type=>$value_type,
    value=>[$value_hi,$value_lo],
    test_type=>$test_type,
    delta=>[$delta_hi,$delta_lo],
    events=>$events)
=cut
	[CreateAlarm => sub{		#  8
	    my ($x,$id,%values) = @_;
	    my ($i,$mask,$pack,$n) = (0,0,'',0);
	    foreach (qw(counter value_type value test_type delta events)) {
		if ($values{$_}) {
		    $mask |= (1<<$i);
		    $values{$_} = $x->num('ValueType',$values{$_})
			if $_ eq 'value_type';
		    $values{$_} = $x->num('TestType',$values{$_})
			if $_ eq 'test_type';
		    $values{$_} = $x->num('Bool',$values{$_})
			if $_ eq 'events';
		    if ($_ eq 'delta' or $_ eq 'value') {
			$pack .= pack('LL',@{$values{$_}});
		    } else {
			$pack .= pack('L',$values{$_});
		    }
		    $n++;
		}
	    }
	    pack('xxSL',3+$n,$id) . $pack;
	}],
=pod

 $X->ChangeAlarm($id,
    counter=>$counter,
    value_type=>$value_type,
    value=>[$value_hi,$value_lo],
    test_type=>$test_type,
    delta=>[$delta_hi,$delta_lo],
    events=>$events)
=cut
	[ChangeAlarm => sub{		#  9
	    my ($x,$id,%values) = @_;
	    my ($i,$mask,$pack,$n) = (0,0,'',0);
	    foreach (qw(counter value_type value test_type delta events)) {
		if ($values{$_}) {
		    $mask |= (1<<$i);
		    $values{$_} = $x->num('ValueType',$values{$_})
			if $_ eq 'value_type';
		    $values{$_} = $x->num('TestType',$values{$_})
			if $_ eq 'test_type';
		    $values{$_} = $x->num('Bool',$values{$_})
			if $_ eq 'events';
		    if ($_ eq 'delta' or $_ eq 'value') {
			$pack .= pack('LL',@{$values{$_}});
		    } else {
			$pack .= pack('L',$values{$_});
		    }
		    $n++;
		}
	    }
	    pack('xxSL',3+$n,$id) . $pack;
	}],
=pod

 $X->QueryAlarm($alarm)
 =>
 ($trigger,($delta_hi,$delta_lo),$events,$state)
=cut
	[QueryAlarm => sub{		# 10
	    pack('xxSL',2,$_[1]);
	}, sub {
	    my $x = shift;
	    @_ = unpack('xxxxxxxxa[20]LLCCxx',shift);
	    $_[-2] = $x->num('Bool',$_[-2]);
	    $_[-1] = $x->num('AlarmState',$_[-1]);
	    @_;
	}],
=pod

 $X->DestroyAlarm($alarm)
=cut
	[DestroyAlarm => sub{		# 11
	    pack('xxSL',2,$_[1]);
	}],
=pod

 $X->SetPriority($id,$priority)
=cut
	[SetPriority => sub{		# 12
	    pack('xxSLl',3,$_[1..2]);
	}],
=pod

 $X->GetPriority($id)
 =>
 ($priority)
=cut
	[GetPriority => sub{		# 13
	    pack('xxSL',1,$_[1]);
	}, sub {
	    unpack('xxxxxxxxlxxxxxxxxxxxxxxxxxxxx',$_[1]);
	}],
=pod

 $X->CreateFence($drawable,$id,$initially_triggered)
=cut
	[CreateFence => sub{		# 14
	    $_[3] = $_[0]->num('Bool',$_[3]);
	    pack('xxSLLCxxx',4,$_[1..3]);
	}],
=pod

 $X->TriggerFence($id)
=cut
	[TriggerFence => sub{		# 15
	    pack('xxSL',2,$_[1]);
	}],
=pod

 $X->ResetFence($id)
=cut
	[ResetFence => sub{		# 16
	    pack('xxSL',2,$_[1]);
	}],
=pod

 $X->DestroyFence($id)
=cut
	[DestroyFence => sub{		# 17
	    pack('xxSL',2,$_[1]);
	}],
=pod

 $X->QueryFence($id)
 =>
 ($triggered)
=cut
	[QueryFence => sub{		# 18
	    pack('xxSL',2,$_[1]);
	}, sub {
	    $_[0]->num('Bool',unpack('xxxxxxxxCxxxxxxxxxxxxxxxxxxxxxxx',$_[1]));
	}],
=pod

 $X->AwaitFence(@ids)
=cut
	[AwaitFence => sub{		# 19
	    shift; pack('xxSL*',1+scalar(@_),@_);
	}],
    ];

    for (my $i=0;$i<scalar(@{$x->{ext_requests}{$request_base}});$i++) {
	my $req = $x->{ext_requests}{$request_next}[$i];
	next unless $req;
	$x->{ext_request_num}{$req->[0]} = [$request_base, $i];
    }

=head1 EVENTS

B<X11::Protocol::Ext::XSYNC> provides the following events:

 CounterNotify => {
     counter=>$counter,
     wait_value=>[$wait_value_hi,$wait_value_lo],
     counter_value=>[$counter_value_hi,$counter_value_lo],
     time=>$time,
     count=>$count,
     destroyed=>'True'|'False' }
=cut
    $x->{ext_const}{Events}[$event_base+0] = 'CounterNotify';
    $x->{ext_events}[$event_base+0] = [sub{
	my ($x,$data,%h) = @_;
	@_ = unpack('xxxxLLLLLLSCx',$data);
	$h{counter} = $_[0];
	$h{wait_value} = [$_[1..2]];
	$h{counter_value} = [$_[3..4]];
	$h{time} = $_[5];
	$h{count} = $_[6];
	$h{destroyed} = $x->num('Bool',$_[7]);
	return %h;
    }, sub{
	my ($x,%h) = @_;
	my $data = pack('xxxxLLLLLLSCx', $h{counter}, @{$h{wait_value}},
			@{$h{counter_value}}, $h{time}, $h{count},
			$x->num('Bool',$h{destroyed}));
	return ($data,1);
    }];
=pod

 AlarmNotify => {
     alarm=>$alarm,
     counter_value=>[$counter_value_hi,$counter_value_lo],
     alarm_value=>[$alarm_value_hi,$alarm_value_lo],
     time=>$time,
     state=>$state} # 'AlarmState'
=cut
    $x->{ext_const}{Events}[$event_base+1] = 'AlarmNotify';
    $x->{ext_events}[$event_base+1] = [sub{
	my ($x,$data,%h) = @_;
	@_ = unpack('xxxxLLLLLLCxxx',$data);
	$h{alarm} = $_[0];
	$h{counter_value} = [$_[1..2]];
	$h{alarm_value} = [$_[3..4]];
	$h{time} = $_[5];
	$h{state} = $x->num('AlarmState', $_[5]);
	return %h;
    }, sub{
	my ($x,%h) = @_;
	my $data = pack('xxxxLLLLLLCxxx', $h{alarm},
	                @{$h{counter_value}}, @{$h{alarm_value}},
			$h{time}, $x->num('AlarmState', $h{state}));
	return ($data,1);
    }];

    ($self->{major},$self->{minor}) = $x->req('XsyncQueryVersion');
    if ($self->{major} != 3) {
	carp "Wrong XSYNC version ($self->{major} != 3)";
	return 0;
    }
    return $self;
}

1;
__END__

=head1 BUGS

Probably lots: this module has not been thoroughly tested.  At least it
loads and initializes on server supporting the correct version.

=head1 AUTHOR

Brian Bidulock <bidulock@openss7.org>

=head1 SEE ALSO

L<perl(1)>,
L<X11::Protocol(3pm)>,
L<X Synchronization Extension Protocol|http://www.x.org/releases/X11R7.7/doc/xextproto/sync.pdf>.

=cut

# vim: sw=4 tw=72
