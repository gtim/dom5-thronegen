package ThroneGen::PowerGenerator;

#
# Power Generators generate random throne powers subject to point requirement
#
# Example: +gem per turn generator
#

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use List::Util qw/any/;
use Ref::Util qw/is_arrayref/;
use ThroneGen::ThematicWords;

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
	# in: exact number of pts to generate a throne power for
	# return: a ThroneGen::Power
	is       => 'ro',
	isa      => 'CodeRef', 
	required => 1,
);
has 'possible_themes' => (
	# all possible themes that can be generated
	# all themes must not be possible for all pts imputs
	is       => 'ro',
	isa      => 'Themes',
	#required => 1,
	coerce   => 1,
);
has 'weight' => (
	# relative non-normalised chance to be picked
	is => 'ro',
	isa => 'Num',
	default => 1,
);

sub can_generate_pts {
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

sub can_generate_themes {
	# checks if the generator can generate a power with at least one of the supplied themes
	my ( $self, $themes ) = @_;
	my @requested_themes = is_arrayref( $themes ) ? @$themes : $themes;
	for my $requested_theme ( @requested_themes ) {
		for my $possible_theme ( @{ $self->possible_themes } ) {
			return 1 if $possible_theme eq $requested_theme;
		}
	}
	return 0;
}


__PACKAGE__->meta->make_immutable;

1;

