package ThroneGen::Power;

#
# Each throne has one or more throne powers.
#
# Example: +2 F gems per turn.
#

use Moose;
use namespace::autoclean;

has 'pts' => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);
has 'title' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);


__PACKAGE__->meta->make_immutable;

1;
