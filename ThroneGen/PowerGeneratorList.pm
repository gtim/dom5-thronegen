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
				my $gem_id = int rand 7;
				my $gem_str = (qw/F A W E S D N/)[$gem_id];
				return ThroneGen::Power->new(
					pts => $pts,
					type => "$gem_str per month",
					title => sprintf( '+%d %s gem%s per month', $pts, $gem_str, ($pts==1?'':'s') ),
					dm_claimed => "#gems $gem_id $pts",
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
					type => "slaves per month",
					title => "+$slaves slaves per month",
					dm_claimed => "#gems 7 $slaves",
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
					type => "gold per month",
					title => "+$gold gold per month",
					dm_claimed => "#gold $gold",
				);
			}
		),

		# dom spread
		ThroneGen::PowerGenerator->new(
			pts_allowed => [2,4,6,8,10,12,14,16,18,20],
			generate => sub {
				my $pts = shift;
				my $candles = $pts/2;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "extra temple checks per month",
					title => "$candles additional temple checks per month",
					dm_increased_domspread => $candles,
				);
			}
		),
	] },
);


__PACKAGE__->meta->make_immutable;

1;
