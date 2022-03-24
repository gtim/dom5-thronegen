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

		# scrying
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2,3],
			generate => sub {
				my $pts = shift;
				my $scry_range = ( $pts == 1 ? 6 : 10 );
				my $scry_duration = ( $pts <= 2 ?  1 : 3 );
				return ThroneGen::Power->new(
					pts => $pts,
					type => "enter to scry",
					title => "priest can enter to scry, range $scry_range for $scry_duration turn".($scry_duration>1?'s':''),
					dm_claimed => "#scry $scry_duration\n#scryrange $scry_range",
				);
			}
		),

		# ritual discounts
		ThroneGen::PowerGenerator->new(
			pts_allowed => [2,5,8],
			generate => sub {
				my $pts = shift;
				my %discount = ( 2 => 10, 5 => 20, 8 => 30 );
				my $discount = $discount{$pts} || croak "unspecified ritual discount for $pts pts";
				my $school = (qw/conj alt evo const ench thau blood/)[ int rand 7 ];
				return ThroneGen::Power->new(
					pts => $pts,
					type => "ritual discount",
					title => ucfirst($school) . " ritual discount $discount%",
					dm_claimed => sprintf( '#%scost %d%%', $school, $discount ),
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
				# TODO: many of these should probably be copied and made slow-to-recruit
				my @mages = (
					# X1
					{ pts => 1, name => 'Azure Initiate',             id => 96   }, # W1, water-breathing
					{ pts => 1, name => 'Cloud Mage',                 id => 92   }, # A1
					{ pts => 1, name => 'Hedge Wizard',               id => 1182 }, # N1
					{ pts => 1, name => 'Pyromancer',                 id => 98   }, # F1
					{ pts => 1, name => 'Revenant',                   id => 98   }, # D1, undead

					# X1Y1
					{ pts => 2, name => 'Conjurer',                   id => 94   }, # D1B1
					# X2
					{ pts => 2, name => 'Adventurer (F2)',            id => 2328 },
					{ pts => 2, name => 'Adventurer (D2)',            id => 2329 },
					{ pts => 2, name => 'Animist',                    id => 552  }, # N2, stealthy
					{ pts => 2, name => 'Azure Mage',                 id => 97   }, # W2, water-breathing
					{ pts => 2, name => 'Necromancer',                id => 310  }, # D2
					{ pts => 2, name => 'Wind Master',                id => 93   }, # A2
					# X1Y1Z1
					{ pts => 2, name => 'Alchemist',                  id => 551  }, # F1E1S1
					{ pts => 2, name => 'Black Witch',                id => 2361 }, # D1N1R1
					{ pts => 2, name => 'Magus',                      id => 480  }, # F1E1S1
					
					# X2 but neater
					{ pts => 3, name => 'Damned Boatswain',           id => 3350 }, # A/W/D 2, undead, fear
					{ pts => 3, name => 'Fire Lord',                  id => 389  }, # F2, slow-rec, mounted, sturdy, combat-caster
					{ pts => 3, name => 'Illusionist',                id => 389  }, # A2, slow-rec, glamour, stealth, hide army
					# X3
					{ pts => 3, name => 'Adept of the Pyriphlegeton', id => 99   }, # F3, slow-rec
					{ pts => 3, name => 'Hydromancer',                id => 103  }, # W3, slow-rec
					# X2Y1
					{ pts => 3, name => 'Bloodhenge Druid',           id => 122  }, # N1B2
					{ pts => 3, name => 'Enchanter',                  id => 338  }, # S1N2, slow-rec
					{ pts => 3, name => 'Ice Druid',                  id => 309  }, # W2N1, H1
					{ pts => 3, name => 'Mage of Autumn',             id => 2545 }, # E2D1, slow-rec
					{ pts => 3, name => 'Mage of Spring',             id => 2543 }, # A2N1, slow-rec
					{ pts => 3, name => 'Mage of Summer',             id => 2544 }, # F2N1, slow-rec
					{ pts => 3, name => 'Mage of Winter',             id => 2546 }, # W2D1, slow-rec
					{ pts => 3, name => 'Moon Mage',                  id => 342  }, # S2D1, slow-rec
					# X2Y1R1
					{ pts => 3, name => 'Wizard of the Crescent Moon',id => 999  }, # W2S1R1, slow-rec
					# misc
					{ pts => 3, name => 'Enchantress',                id => 363  }, # N2 R1.5, slow-rec
					{ pts => 3, name => 'Giant Shaman',               id => 2640 }, # N2R1, sturdy size 5
					{ pts => 3, name => 'Sorcerer',                   id => 339  }, # D1B1R2, slow-rec
					{ pts => 3, name => 'Sorcerer of the Sands',      id => 2245 }, # F1A1E1R1, slow-rec
					{ pts => 3, name => 'Warrior Mage',               id => 875  }, # R1+R1, mounted, sturdy, combat-caster
					{ pts => 3, name => 'Wizard (Water)',             id => 302  }, # W1R2, slow-rec
					{ pts => 3, name => 'Wizard (Fire)',              id => 312  }, # F1R2, slow-rec

					# X3 / X2Y1R1 but neater
					{ pts => 4, name => 'Elludian Moon Mage',         id => 630  }, # S2D1R1, slow-rec, ethereal, stealthy
					{ pts => 4, name => 'Shadow Seer',                id => 106  }, # S3, slow-rec, ethereal, stealthy
					# X2Y2 / X2Y2R1 / X2Y1Z1R1
					{ pts => 4, name => 'Adept of the Golden Order',  id => 101  }, # F2S2R1, slow-rec
					{ pts => 4, name => 'Adept of the Iron Order',    id => 477  }, # E2S2R1, slow-rec
					{ pts => 4, name => 'Adept of the Silver Order',  id => 100  }, # A2S2R1, slow-rec
					{ pts => 4, name => 'Black Sorceress',            id => 344  }, # F1E1S2 0.2R, slow-rec
					{ pts => 4, name => 'Blackrose Sorceress',        id => 2362 }, # D1N2B1R1, slow-rec
					{ pts => 4, name => 'Circle Master',              id => 95   }, # D2B2
					{ pts => 4, name => 'Crystal Mage',               id => 340  }, # E2S2, slow-rec
					{ pts => 4, name => 'Gnome',                      id => 345  }, # E2N2, slow-rec, glamour, stealthy
					{ pts => 4, name => 'High Magus',                 id => 481  }, # F2E1S2, slow-rec
					{ pts => 4, name => 'Sorceress',                  id => 343  }, # A2S2 0.2R, slow-rec
					{ pts => 4, name => 'Wormwood Witch',             id => 2358 }, # A2D1N1R1, slow-rec
					# misc
					{ pts => 4, name => 'Giant Sorcerer',             id => 2641 }, # E2R1, sturdy size 6, grab and swallow
					{ pts => 4, name => 'Lore Master',                id => 479  }, # R1+R1+#1, slow-rec
					{ pts => 4, name => 'Yeti Shaman',                id => 2642 }, # A2W2, sturdy chassis, high map-move

					# not included
					#{pts => 2, name => 'Adventurer (N2)',            id => 2327 }, # #autohealer too strong
					#{pts => 4, name => 'Cyclops',                    id => 156  }, # E3, chassis too strong 
					#{pts => 4, name => 'Dust Priest',                id => 1978 }, # too many paths
					#{pts => 4, name => 'Enchantress#364',            id => 364  }, # too many paths
					#{pts => 4, name => 'Ether Lord',                 id => 737  }, # too many paths, too cool
					#{pts => 4, name => 'Faery Queen',                id => 627  }, # too many paths, too cool
					#{pts => 3, name => 'Flame Spirit',               id => 2626 }, # hard to evaluate
					#{pts => 3, name => 'Golem',                      id => 471  }, # hard to evaluate
					#{pts => 3, name => 'Hamadryad'                   id => 3066 }, # immobile
					#{pts => 4, name => 'Ivy King',                   id => 931  }, # common summon
					#Kokythiad
					#Lamia queen
					#Lampad
					#Lich
					#Mound Fiend
					#Naiad
					#Released Sage
					#Sea King
					#Spectral Mage
					#Treelord
					#Troll King
					#Troll Seithberender
					#{ pts => 3, name => 'Troll Shaman',               id => 2220 }, # D1N1R1, regen, sturdy
					#Unfrozen Mage
					#Vampire Lord
					#Vastness
					#Worm Mage
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
