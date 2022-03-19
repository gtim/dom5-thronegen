package ThroneGen::PowerGeneratorList;

#
# Power Generator List
#

use MooseX::Singleton;
use namespace::autoclean;

use ThroneGen::Power;
use ThroneGen::PowerGenerator;
use List::Util qw/shuffle/;
use Carp;

sub random_generator {
	my $self = shift;
	return $self->generators->[ int rand 0+@{$self->generators} ];
}

sub random_power {
	# generate a random power for the supplied number of points
	my ( $self, $pts ) = @_;
	for my $gen ( shuffle @{$self->generators} ) {
		if ( $gen->can_generate( $pts ) ) {
			return $gen->generate->( $pts );
		}
	}
	# no generator can generate such a power
	croak "asked to generate a $pts-pt power, which no generator is able to";
}


has 'generators' => (
	is => 'ro',
	isa => 'ArrayRef[ThroneGen::PowerGenerator]',
	default => sub { [
		# gem income
		ThroneGen::PowerGenerator->new(
			generate => sub {
				my $pts = shift;
				my $gem = (qw/F W A E S D N/)[int rand 7];
				return ThroneGen::Power->new(
					pts => $pts,
					title => sprintf( '+%d %s gem%s per month', $pts, $gem, ($pts==1?'':'s') ),
				);
			}
		),

		# slave income
		ThroneGen::PowerGenerator->new(
			generate => sub {
				my $pts = shift;
				my $slaves = 3 * $pts;
				return ThroneGen::Power->new(
					pts => $pts,
					title => "+$slaves slaves per month",
				);
			}
		),

		# gold income
		ThroneGen::PowerGenerator->new(
			generate => sub {
				my $pts = shift;
				my $gold = 50 * $pts;
				return ThroneGen::Power->new(
					pts => $pts,
					title => "+$gold gold per month",
				);
			}
		),
	] },
);


__PACKAGE__->meta->make_immutable;

1;
