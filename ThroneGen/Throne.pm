package ThroneGen::Throne;

use Moose;
use namespace::autoclean;

use ThroneGen::PowerGeneratorList;

has 'pts' => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
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



__PACKAGE__->meta->make_immutable;

1;

