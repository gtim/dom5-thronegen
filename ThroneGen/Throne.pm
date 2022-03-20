package ThroneGen::Throne;

use Moose;
use namespace::autoclean;
use Carp;

use ThroneGen::PowerGeneratorList;

has 'pts' => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);
has 'site_id' => (
	# site ID should overwrite an old throne,
	# must be set before writing
	is       => 'rw',
	isa      => 'Int'
);
has 'powers' => (
	is => 'ro',
	isa => 'ArrayRef[ThroneGen::Power]',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $power = ThroneGen::PowerGeneratorList->instance->random_power($self->pts);
		return [ $power ];
	}
);

sub write_to_dm {
	my ( $self, $fh ) = @_;
	croak "Throne::write_to_dm called before setting site_id" unless $self->site_id;
	printf $fh "#selectsite %d\n", $self->site_id;
	print  $fh "#clear\n";
	printf $fh "#name \"The Throne of Site ID %d\"\n", $self->site_id;
	print  $fh "#path 8\n";
	print  $fh "#level 0\n";
	print  $fh "#loc 213999 -- unique, allowed everywhere\n";
	print  $fh "#rarity 11 -- lvl1 throne\n";
	print  $fh "#claim\n";
	print  $fh "#dominion 2\n";
	for my $power ( @{ $self->powers } ) {
		print $fh $power->dm_claimed."\n" if $power->has_dm_claimed;
	}
	print  $fh "#end\n";
	print  $fh "\n";
}


__PACKAGE__->meta->make_immutable;

1;

