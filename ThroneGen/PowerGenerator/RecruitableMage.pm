package ThroneGen::PowerGenerator::RecruitableMage;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use ThroneGen::Power;
use Ref::Util qw/is_arrayref/;
use List::Util qw/uniq/;

extends 'ThroneGen::PowerGenerator';

has '+pts_allowed' => (
	default => sub { [1,2,3,4] },
);

has 'mages' => (
	# mages and associated point costs
	# based on this list: https://github.com/Logg-y/magicgen/tree/master/data/spells/summons/commanders
	# so far, A is covered
	# TODO: these should probably be put in a separate csv file
	# TODO: a simple linter comparing these IDs+names with inspector data files, also checking uniqueness of IDs/names
	is       => 'ro',
	isa      => 'ArrayRef[HashRef]',
	init_arg => undef,
	default  => sub { [
		# X1
		{ pts => 1, name => 'Azure Initiate',             id => 96,   theme => 'water' }, # W1, water-breathing
		{ pts => 1, name => 'Cloud Mage',                 id => 92,   theme => 'air'   }, # A1
		{ pts => 1, name => 'Pyromancer',                 id => 98,   theme => 'fire'  }, # F1
		{ pts => 1, name => 'Revenant',                   id => 98,   theme => 'death' }, # D1, undead

		# X1Y1
		{ pts => 2, name => 'Conjurer',                   id => 94,   theme => ['death', 'blood'] }, # D1B1
		# X2
		{ pts => 2, name => 'Adventurer (F2)',            id => 2328, theme => ['adventure','fire']  },
		{ pts => 2, name => 'Adventurer (D2)',            id => 2329, theme => ['adventure','death'] },
		{ pts => 2, name => 'Animist',                    id => 552,  theme => 'nature'    }, # N2, stealthy
		{ pts => 2, name => 'Azure Mage',                 id => 97,   theme => 'water'     }, # W2, water-breathing
		{ pts => 2, name => 'Necromancer',                id => 310,  theme => 'death'     }, # D2
		{ pts => 2, name => 'Wind Master',                id => 93,   theme => 'air'       }, # A2
		# X1Y1Z1
		{ pts => 2, name => 'Alchemist',                  id => 551,  theme => 'gold'  }, # F1E1S1
		{ pts => 2, name => 'Black Witch',                id => 2361, theme => 'misfortune' }, # D1N1R1
		{ pts => 2, name => 'Magus',                      id => 480,  theme => 'magic'  }, # F1E1S1
		
		# X2 but neater
		{ pts => 3, name => 'Damned Boatswain',           id => 3350, theme => 'death', make_slowrec => 1 }, # A/W/D 2, undead, fear
		{ pts => 3, name => 'Fire Lord',                  id => 389,  theme => 'fire'  }, # F2, slow-rec, mounted, sturdy, combat-caster
		{ pts => 3, name => 'Illusionist',                id => 389,  theme => 'air'   }, # A2, slow-rec, glamour, stealth, hide army
		# X3
		{ pts => 3, name => 'Adept of the Pyriphlegeton', id => 99,   theme => 'fire'   }, # F3, slow-rec
		{ pts => 3, name => 'Hydromancer',                id => 103,  theme => 'water'  }, # W3, slow-rec
		# X2Y1
		{ pts => 3, name => 'Bloodhenge Druid',           id => 122,  theme => 'blood', copy_and_make_slowrec => 1  }, # N1B2
		{ pts => 3, name => 'Enchanter',                  id => 338,  theme => 'nature'  }, # S1N2, slow-rec
		{ pts => 3, name => 'Ice Druid',                  id => 309,  theme => 'cold', copy_and_make_slowrec => 1  }, # W2N1, H1
		{ pts => 3, name => 'Mage of Autumn',             id => 2545, theme => ['earth','death'] }, # E2D1, slow-rec,
		{ pts => 3, name => 'Mage of Spring',             id => 2543, theme => ['air','nature'] }, # A2N1, slow-rec,
		{ pts => 3, name => 'Mage of Summer',             id => 2544, theme => 'fire' }, # F2N1, slow-rec
		{ pts => 3, name => 'Mage of Winter',             id => 2546, theme => 'cold' }, # W2D1, slow-rec
		{ pts => 3, name => 'Moon Mage',                  id => 342,  theme => 'astral' }, # S2D1, slow-rec
		# X2Y1R1
		{ pts => 3, name => 'Wizard of the Crescent Moon',id => 999,  theme => 'water'  }, # W2S1R1, slow-rec
		# misc
		{ pts => 3, name => 'Enchantress',                id => 363,  theme => 'nature'  }, # N2 R1.5, slow-rec
		{ pts => 3, name => 'Giant Shaman',               id => 2640, theme => 'nature', make_slowrec => 1 }, # N2R1, sturdy size 5
		{ pts => 3, name => 'Sorcerer',                   id => 339,  theme => ['magic','death','blood']  }, # D1B1R2, slow-rec
		{ pts => 3, name => 'Sorcerer of the Sands',      id => 2245, theme => 'fire' }, # F1A1E1R1, slow-rec
		{ pts => 3, name => 'Warrior Mage',               id => 875,  theme => 'magic'  }, # R1+R1, mounted, sturdy, combat-caster, TODO better theme
		{ pts => 3, name => 'Wizard (Water)',             id => 302,  theme => 'water'  }, # W1R2, slow-rec
		{ pts => 3, name => 'Wizard (Fire)',              id => 312,  theme => 'fire'  }, # F1R2, slow-rec

		# X3 / X2Y1R1 but neater
		{ pts => 4, name => 'Elludian Moon Mage',         id => 630,  theme => 'astral'  }, # S2D1R1, slow-rec, ethereal, stealthy
		{ pts => 4, name => 'Shadow Seer',                id => 106,  theme => 'astral'  }, # S3, slow-rec, ethereal, stealthy
		# X2Y2 / X2Y2R1 / X2Y1Z1R1
		{ pts => 4, name => 'Adept of the Golden Order',  id => 101,  theme => 'fire'  }, # F2S2R1, slow-rec
		{ pts => 4, name => 'Adept of the Iron Order',    id => 477,  theme => 'earth'  }, # E2S2R1, slow-rec
		{ pts => 4, name => 'Adept of the Silver Order',  id => 100,  theme => 'air'  }, # A2S2R1, slow-rec
		{ pts => 4, name => 'Black Sorceress',            id => 344,  theme => ['magic','astral']  }, # F1E1S2 0.2R, slow-rec
		{ pts => 4, name => 'Blackrose Sorceress',        id => 2362, theme => ['nature','misfortune'] }, # D1N2B1R1, slow-rec
		{ pts => 4, name => 'Circle Master',              id => 95,   theme => ['blood','death'], copy_and_make_slowrec => 1 }, # D2B2
		{ pts => 4, name => 'Crystal Mage',               id => 340,  theme => ['earth','astral']  }, # E2S2, slow-rec,
		{ pts => 4, name => 'Gnome',                      id => 345,  theme => ['earth','nature']  }, # E2N2, slow-rec, glamour, stealthy
		{ pts => 4, name => 'High Magus',                 id => 481,  theme => ['fire','magic']  }, # F2E1S2, slow-rec
		{ pts => 4, name => 'Sorceress',                  id => 343,  theme => ['astral','air','magic']  }, # A2S2 0.2R, slow-rec
		{ pts => 4, name => 'Wormwood Witch',             id => 2358, theme => ['misfortune','air'] }, # A2D1N1R1, slow-rec
		# misc
		{ pts => 4, name => 'Giant Sorcerer',             id => 2641, theme => 'earth', make_slowrec => 1 }, # E2R1, sturdy size 6, grab and swallow
		{ pts => 4, name => 'Lore Master',                id => 479,  theme => 'magic'  }, # R1+R1+#1, slow-rec
		{ pts => 4, name => 'Yeti Shaman',                id => 2642, theme => 'cold', make_slowrec => 1 }, # A2W2, sturdy chassis, high map-move

		# not included
		#{pts => 1, name => 'Hedge Wizard',               id => 1182 }, # N1, underwhelming as N1 tribes are common
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
	] },
);

has '+possible_themes' => (
	default => sub {
		my $self = shift;
		my @possible_themes = 
			uniq sort
			map { is_arrayref( $_ ) ? @$_ : $_ }
			map { $_->{theme} }
			@{ $self->mages };
		return \@possible_themes;
	},
	lazy     => 1,
	required => 0,
	init_arg => undef,
);

has '+generate' => (
	default => sub {
		my $self = shift;
		return sub {
			my $pts = shift;
			local $_;
			
			# pick a mage randomly
			my @mages = @{ $self->mages };
			my @applicable_mages = grep { $_->{pts} == $pts } @mages;
			my %mage = %{ $applicable_mages[ int rand @applicable_mages ] };

			my $type = 'recruitable mage';
			my $title = "recruitable $mage{name}";

			# make power depending on copy/slow-rec requirements
			if ( $mage{copy_and_make_slowrec} ) {
				# copy mage and add slow-rec tag to the copy
				return ThroneGen::Power->new(
					pts => $pts, type => $type, title => $title, themes => $mage{theme}, 
					dm_claimed => "#com \"$mage{name} \"\n",
					dm_monster => "#newmonster -- create a new $mage{name} that is slow-rec\n"
				                     ."#copystats $mage{id}\n"
				                     ."#name \"$mage{name} \"\n"
				                     ."#copyspr $mage{id}\n"
				                     ."#slowrec\n"
				                     ."#end\n",
				);
			} elsif ( $mage{make_slowrec} ) {
				# add slow-rec tag to monster
				return ThroneGen::Power->new(
					pts => $pts, type => $type, title => $title, themes => $mage{theme}, 
					dm_claimed => "#com $mage{id} -- recruitable $mage{name}",
					dm_monster => "#selectmonster $mage{id} -- $mage{name}\n"
				                     ."#slowrec\n"
				                     ."#end\n",
				);
			} else {
				return ThroneGen::Power->new(
					pts => $pts, type => $type, title => $title, themes => $mage{theme}, 
					dm_claimed => "#com $mage{id} -- recruitable $mage{name}",
				);
			}
		}
	},
	lazy => 1,
);

__PACKAGE__->meta->make_immutable;

1;
