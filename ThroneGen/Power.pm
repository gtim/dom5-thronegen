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
has 'type' => (
	# one throne can't have multiple powers of the same type
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);
has 'title' => (
	# human-readable title of throne power
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

# dm_* attributes have direct effect on the generated .dm

has 'dm_claimed'  => (
	is        => 'ro',
	isa       => 'Str',
	predicate => 'has_dm_claimed',
);
has 'dm_increased_domspread'  => (
	is        => 'ro',
	isa       => 'Int',
);


__PACKAGE__->meta->make_immutable;

1;
