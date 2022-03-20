package ThroneGen::Power;

#
# Each throne has one or more throne powers.
#
# Example: +2 F gems per turn.
#

use Moose;
use namespace::autoclean;

has 'pts' => (
	is        => 'ro',
	isa       => 'Int',
	required  => 1,
);
has 'title' => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);
has 'dm_claimed'  => (
	is        => 'ro',
	isa       => 'Str',
	predicate => 'has_dm_claimed',
);


__PACKAGE__->meta->make_immutable;

1;
