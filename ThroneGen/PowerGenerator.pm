package ThroneGen::PowerGenerator;

#
# Power Generators generate random throne powers subject to point requirement
#
# Example: +gem per turn generator
#

use Moose;
use namespace::autoclean;

has 'pts_min' => (
	is      => 'ro',
	isa     => 'Int',
	default => 1,
);
has 'pts_max' => (
	is      => 'ro',
	isa     => 'Int',
	default => 20,
);
has 'generate' => (
	is       => 'ro',
	isa      => 'CodeRef', 
	required => 1,
	# in: exact number of pts to generate a throne power for
	# return: a ThroneGen::Power
);


__PACKAGE__->meta->make_immutable;

1;

