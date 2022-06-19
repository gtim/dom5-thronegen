package ThroneGen::PowerGenerator::GemIncome;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use ThroneGen::Power;

extends 'ThroneGen::PowerGenerator';

	# 0 pt -> 1-2 gem
	# 1 pt -> 2-3 gems
	# 2 pts -> 3-4 gems

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;
	return $class->$orig(
		pts_allowed => [0,1,2],
		generate => sub {
			my $pts = shift;
			my @pts_to_gems = (
				(rand() > 0.5 ? 1 : 2),
				(rand() > 0.5 ? 2 : 3),
				(rand() > 0.5 ? 3 : 4),
			);
			my $num_gems = $pts_to_gems[$pts];
			my $gem_id = int rand 7;
			my $gem_str = (qw/F A W E S D N/)[$gem_id];
			my $theme =  {
				F => 'fire',
				A => 'air',
				W => ['water','cold'],
				E => 'earth',
				S => 'astral',
				D => ['death','darkness'],
				N => ['nature','growth'],
			}->{$gem_str};
			return ThroneGen::Power->new(
				pts => $pts,
				type => "$gem_str per month",
				title => sprintf( '+%d %s gem%s per month', $num_gems, $gem_str, ($num_gems==1?'':'s') ),
				themes => $theme,
				dm_claimed => "#gems $gem_id $num_gems",
			);
		},
		possible_themes => [qw/fire air water earth astral death nature/],
		@_,
	);
};


__PACKAGE__->meta->make_immutable;

1;
