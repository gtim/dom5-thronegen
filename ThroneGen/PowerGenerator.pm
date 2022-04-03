package ThroneGen::PowerGenerator;

#
# Power Generators generate random throne powers subject to point requirement
#
# Example: +gem per turn generator
#

use Moose;
use namespace::autoclean;
use List::Util qw/any/;

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
has 'pts_allowed' => (
	# explicit list of pts values that can be generated.
	# overrides pts_min, pts_max if set
	is      => 'ro',
	isa     => 'ArrayRef[Int]',
);
has 'generate' => (
	is       => 'ro',
	isa      => 'CodeRef', 
	required => 1,
	# in: exact number of pts to generate a throne power for
	# return: a ThroneGen::Power
);

sub can_generate {
	# checks if the generator can generate a power for the supplied number of points
	my ( $self, $pts ) = @_;
	# check pts_allowed
	if ( $self->pts_allowed ) {
		return any { $_ == $pts } @{$self->pts_allowed};
	}
	# check min/max
	return 0 if $pts < $self->pts_min || $pts > $self->pts_max;
	# else: all OK
	return 1;
}


__PACKAGE__->meta->make_immutable;

1;

