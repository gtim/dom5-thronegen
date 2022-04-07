package ThroneGen::PowerGenerator::WallMage;

use Moose;
use namespace::autoclean;
use ThroneGen::Power;
use Carp;

extends 'ThroneGen::PowerGenerator';

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;
	croak 'TG::PG::WallMage constructor given arguments' unless 0+@_ == 0;
	return $class->$orig( pts_allowed => [0] );
};

has '+generate' => (
	default => sub { sub {
		my %mages = (
			93 => 'Wind Master',
			97 => 'Azure Mage',
			99 => 'Adept of Pyriphlegeton',
			100 => 'Adept of the Silver Order',
			101 => 'Adept of the Golden Order',
			103 => 'Hydromancer',
			106 => 'Shadow Seer',
			156 => 'Cyclops',
			299 => 'Wight Mage',
			309 => 'Ice Druid',
			310 => 'Necromancer',
			340 => 'Crystal Mage',
			341 => 'Illusionist',
			342 => 'Moon Mage',
			343 => 'Sorceress',
			345 => 'Gnome',
			363 => 'Enchantress',
			389 => 'Fire Lord',
			439 => 'Mound Fiend',
			477 => 'Adept of the Iron Order',
			481 => 'High Magus',
			519 => 'Troll King',
			529 => 'Sea Father',
			552 => 'Animist',
			580 => 'Sea King',
			627 => 'Faery Queen',
			630 => 'Elludian Moon Mage',
			737 => 'Ether Lord',
			931 => 'Ivy King',
			999 => 'Wizard of the Crescent Moon',
			1226 => 'Naiad',
			1477 => 'Kokythiad',
			1539 => 'Ghost Mage',
			1540 => 'Ghost Mage',
			2221 => 'Troll Seithberender',
			2358 => 'Wormwood Witch',
			2543 => 'Mage of Spring',
			2544 => 'Mage of Summer',
			2545 => 'Mage of Autumn',
			2546 => 'Mage of Winter',
			2626 => 'Flame Spirit',
			2640 => 'Giant Shaman',
			2641 => 'Giant Sorcerer',
			2642 => 'Yeti Shaman',
		);
		my @mage_ids = keys %mages;
		my $mage_id = $mage_ids[ int rand( 0+@mage_ids ) ];
		my $mage_name = $mages{$mage_id};
		return ThroneGen::Power->new(
			pts => 0,
			type => "wall mage",
			title => "$mage_name defends wall during storm",
			dm_unclaimed => "#wallcom $mage_id -- $mage_name"
		);
	} }
);

__PACKAGE__->meta->make_immutable;

1;

