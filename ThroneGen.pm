package ThroneGen;

use 5.30.0;
use warnings;
use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/@power_generators/;

use ThroneGen::PowerGenerator;
use ThroneGen::Power;

our @power_generators = (

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

);
