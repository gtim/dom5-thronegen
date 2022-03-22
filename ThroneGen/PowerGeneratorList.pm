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

		# improve nation scales: order/prod/growth/luck/magic
		ThroneGen::PowerGenerator->new(
			pts_allowed => [2,4,6],
			generate => sub {
				my $pts = shift;
				my $scale_points = $pts/2;
				my @scales = (
					{ name => 'order',      cmd => 'goddomchaos',      inverted => 1 },
					{ name => 'production', cmd => 'goddomlazy',       inverted => 1 },
					{ name => 'growth',     cmd => 'goddomdeath',      inverted => 1 },
					{ name => 'luck',       cmd => 'goddommisfortune', inverted => 1 },
					{ name => 'magic',      cmd => 'goddomdrain',      inverted => 1 },
				);
				my %scale = %{ $scales[ int rand @scales ] };
				my $dm_cmd = sprintf '#%s %d', $scale{cmd}, $scale_points * ($scale{inverted}?-1:1);
				return ThroneGen::Power->new(
					pts => $pts,
					type => "increase $scale{name} in nation",
					title => "+$scale_points $scale{name} scale in nation",
					dm_claimed => $dm_cmd,
				);
			}
		),

		# recruitable mage
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2,3,4],
			generate => sub {
				my $pts = shift;
				# mages and associated point costs
				# based on this list: https://github.com/Logg-y/magicgen/tree/master/data/spells/summons/commanders
				# so far, A is covered
				# TODO: these should probably be put in a separate csv file
				# TODO: a simple linter comparing these IDs+names with inspector data files, also checking uniqueness of IDs/names
				my @mages = (
					# X1
					{ pts => 1, name => 'Azure Initiate',             id => 96   }, # W1, water-breathing
					{ pts => 1, name => 'Cloud Mage',                 id => 92   }, # A1

					# X1Y1
					{ pts => 2, name => 'Conjurer',                   id => 94   }, # D1B1
					# X2
					{ pts => 2, name => 'Adventurer (F2)',            id => 2328 },
					{ pts => 2, name => 'Adventurer (D2)',            id => 2329 },
					{ pts => 2, name => 'Animist',                    id => 552  }, # N2, stealthy
					{ pts => 2, name => 'Azure Mage',                 id => 97   }, # W2, water-breathing
					# X1Y1Z1
					{ pts => 2, name => 'Alchemist',                  id => 551  }, # F1E1S1
					{ pts => 2, name => 'Black Witch',                id => 2361 }, # D1N1R1
					
					# X2 with neat feature
					{ pts => 3, name => 'Damned Boatswain',           id => 3350 }, # A/W/D 2, undead, fear
					# X3
					{ pts => 3, name => 'Adept of the Pyriphlegeton', id => 99   }, # F3, slow-rec
					# X2Y1
					{ pts => 3, name => 'Bloodhenge Druid',           id => 122  }, # N1B2

					# X2Y2 / X2Y2R1 / X2Y1Z1R1
					{ pts => 4, name => 'Adept of the Golden Order',  id => 101  }, # F2S2R1, slow-rec
					{ pts => 4, name => 'Adept of the Iron Order',    id => 477  }, # E2S2R1, slow-rec
					{ pts => 4, name => 'Adept of the Silver Order',  id => 100  }, # A2S2R1, slow-rec
					{ pts => 4, name => 'Blackrose Sorceress',        id => 2362 }, # D1N2B1R1, slow-rec
					{ pts => 4, name => 'Circle Master',              id => 95   }, # D2B2
					{ pts => 4, name => 'Crystal Mage',               id => 340  }, # E2S2, slow-rec

					# not included
					#{pts => 2, name => 'Adventurer (N2)',            id => 2327 }, # #autohealer too strong
					#{pts => 4, name => 'Cyclops',                    id => 156  }, # E3, chassis too strong 
					#{pts => 4, name => 'Dust Priest',                id => 1978 }, # too many paths
				);
				my @applicable_mages = grep { $_->{pts} == $pts } @mages;
				my %mage = %{ $applicable_mages[ int rand @applicable_mages ] };
				return ThroneGen::Power->new(
					pts => $pts,
					type => "recruitable mage",
					title => "recruitable $mage{name}",
					dm_claimed => "#com $mage{id} -- recruitable $mage{name}"
				);
			}
		),
	] },
);


__PACKAGE__->meta->make_immutable;

1;
