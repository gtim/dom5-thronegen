package ThroneGen::PowerGenerator::WallMage;

use Moose;
use MooseX::StrictConstructor;
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
			93   => [ 'Wind Master', 'air' ],
			97   => [ 'Azure Mage', 'water' ],
			99   => [ 'Adept of Pyriphlegeton', 'fire' ],
			100  => [ 'Adept of the Silver Order', 'air' ],
			101  => [ 'Adept of the Golden Order', 'fire' ],
			103  => [ 'Hydromancer', 'water' ],
			106  => [ 'Shadow Seer', 'astral' ],
			156  => [ 'Cyclops', 'earth' ],
			299  => [ 'Wight Mage', 'death' ],
			309  => [ 'Ice Druid', 'cold' ],
			310  => [ 'Necromancer', 'death' ],
			340  => [ 'Crystal Mage', ['earth','astral'] ],
			341  => [ 'Illusionist', 'air' ],
			342  => [ 'Moon Mage', 'astral' ],
			343  => [ 'Sorceress', ['astral','air','magic'] ],
			345  => [ 'Gnome', ['earth', 'nature'] ],
			363  => [ 'Enchantress', 'nature' ],
			389  => [ 'Fire Lord', 'fire' ],
			439  => [ 'Mound Fiend', 'death' ],
			477  => [ 'Adept of the Iron Order', 'earth' ],
			481  => [ 'High Magus', ['fire','magic'] ],
			519  => [ 'Troll King', 'earth' ],
			529  => [ 'Sea Father', 'water' ],
			552  => [ 'Animist', 'nature' ],
			580  => [ 'Sea King', 'water' ],
			627  => [ 'Faery Queen', 'nature' ],
			630  => [ 'Elludian Moon Mage', 'astral' ],
			737  => [ 'Ether Lord', ['astral','death'] ],
			931  => [ 'Ivy King', 'nature' ],
			999  => [ 'Wizard of the Crescent Moon', 'water' ],
			1226 => [ 'Naiad', ['water','nature'] ],
			1477 => [ 'Kokythiad', ['death','water'] ],
			1539 => [ 'Ghost Mage', ['death','earth'] ],
			1540 => [ 'Ghost Mage', ['death','fire'] ],
			2221 => [ 'Troll Seithberender', ['nature','death'] ],
			2358 => [ 'Wormwood Witch', ['misfortune','air'] ],
			2543 => [ 'Mage of Spring', ['air','nature'] ],
			2544 => [ 'Mage of Summer', 'fire' ],
			2545 => [ 'Mage of Autumn', ['earth','death'] ],
			2546 => [ 'Mage of Winter', 'cold' ],
			2626 => [ 'Flame Spirit', 'fire' ],
			2640 => [ 'Giant Shaman', 'nature' ],
			2641 => [ 'Giant Sorcerer', 'earth' ],
			2642 => [ 'Yeti Shaman', 'cold' ],
		);
		my @mage_ids = keys %mages;
		my $mage_id = $mage_ids[ int rand( 0+@mage_ids ) ];
		my $mage_name = $mages{$mage_id}[0];
		my $mage_theme = $mages{$mage_id}[1];
		return ThroneGen::Power->new(
			pts => 0,
			type => "wall mage",
			title => "$mage_name defends wall during storm",
			themes => $mage_theme,
			dm_unclaimed => "#wallcom $mage_id -- $mage_name"
		);
	} }
);

__PACKAGE__->meta->make_immutable;

1;

