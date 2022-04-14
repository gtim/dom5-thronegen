package ThroneGen::PowerGeneratorList;

#
# Power Generator List
#

use MooseX::Singleton;
use namespace::autoclean;

use ThroneGen::Power;
use ThroneGen::PowerGenerator;
use ThroneGen::PowerGenerator::Simple;
use ThroneGen::PowerGenerator::RecruitableMage;
use ThroneGen::PowerGenerator::WallMage;

use List::Util qw/shuffle/;
use Carp;
use POSIX qw/round/;

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
		# recruitable mage
		ThroneGen::PowerGenerator::RecruitableMage->new(),

		# gem income
		ThroneGen::PowerGenerator->new(
			generate => sub {
				my $pts = shift;
				my $gem_id = int rand 7;
				my $gem_str = (qw/F A W E S D N/)[$gem_id];
				my $theme =  {F => 'fire', A => 'air', W => 'water', E => 'earth', S => 'astral', D => 'death', N => 'nature' }->{$gem_str};
				return ThroneGen::Power->new(
					pts => $pts,
					type => "$gem_str per month",
					title => sprintf( '+%d %s gem%s per month', $pts, $gem_str, ($pts==1?'':'s') ),
					themes => $theme,
					dm_claimed => "#gems $gem_id $pts",
				);
			}
		),

		# slave income
		# 2.5 slaves per pt, round result randomly
		ThroneGen::PowerGenerator->new(
			generate => sub {
				my $pts = shift;
				my $slaves = round( 2.5 * $pts + rand()-0.5 );
				return ThroneGen::Power->new(
					pts => $pts,
					type => "slaves per month",
					title => "+$slaves slaves per month",
					themes => 'blood',
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
					title => sprintf( '%+d gold per month', $gold ),
					themes => 'gold',
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
				my $plural_s = $candles == 1 ? '' : 's';
				return ThroneGen::Power->new(
					pts => $pts,
					type => "temple checks per month",
					title => "$candles additional temple check$plural_s per month",
					dm_increased_domspread => $candles,
					themes => 'piety',
				);
			}
		),
		ThroneGen::PowerGenerator::Simple->new(
			pts => -1,
			type => "temple checks per month",
			title => "one less temple check per month",
			dm_increased_domspread => -1,
		),

		# improve nation scales: order/prod/growth/luck/magic
		ThroneGen::PowerGenerator->new(
			pts_allowed => [2,4,6],
			generate => sub {
				my $pts = shift;
				my $scale_points = $pts/2;
				my @scales = (
					{ name => 'order',        cmd => 'goddomchaos',      inverted => 1 },
					{ name => 'productivity', cmd => 'goddomlazy',       inverted => 1 },
					{ name => 'growth',       cmd => 'goddomdeath',      inverted => 1 },
					{ name => 'luck',         cmd => 'goddommisfortune', inverted => 1 },
					{ name => 'magic',        cmd => 'goddomdrain',      inverted => 1 },
				);
				my %scale = %{ $scales[ int rand @scales ] };
				my $dm_cmd = sprintf '#%s %d', $scale{cmd}, $scale_points * ($scale{inverted}?-1:1);
				return ThroneGen::Power->new(
					pts => $pts,
					type => "increase $scale{name} in nation",
					title => "+$scale_points $scale{name} scale in nation",
					themes => $scale{name},
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
					themes => 'scrying',
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
				my $theme = 'magic';
				$theme = 'blood' if $school eq 'blood';
				$theme = 'productivity' if $school eq 'const';
				return ThroneGen::Power->new(
					pts => $pts,
					type => "ritual discount",
					title => ucfirst($school) . " ritual discount $discount%",
					themes => $theme,
					dm_claimed => "#${school}cost $discount",
				);
			}
		),


		#
		# ritual range bonus
		#
		# single path +2: 1 pt
		# single path +3: 2 pt
		# elemental/sorcery +1: 1pt 
		# elemental/sorcery +2: 2pt 
		# elemental/sorcery +3: 3pt 
		# all +1: 2pt 
		# all +2: 4pt 
		
		# ritual range bonus, single path
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2],
			generate => sub {
				my $pts = shift;
				my $path = (qw/fire air water earth astral death nature blood/)[ int rand 8 ];
				my $range = $pts+1;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "ritual range bonus",
					title => ucfirst($path) . " ritual range +$range",
					themes => $path,
					dm_claimed => "#${path}range $range",
				);
			}
		),
		# ritual range bonus, elemental/sorcery
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2,3],
			generate => sub {
				my $pts = shift;
				my $paths = (qw/element sorcery/)[ int rand 2 ];
				my $range = $pts;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "ritual range bonus",
					title => ucfirst($paths) . " ritual range +$range",
					themes => 'magic',
					dm_claimed => "#${paths}range $range",
				);
			}
		),
		# ritual range bonus, all paths
		ThroneGen::PowerGenerator->new(
			pts_allowed => [2,4],
			generate => sub {
				my $pts = shift;
				my $range = $pts/2;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "ritual range bonus",
					title => "ritual range +$range",
					themes => 'magic',
					dm_claimed => "#allrange $range",
				);
			}
		),


		# Adventure site
		ThroneGen::PowerGenerator::Simple->new(
			pts => 1,
			type => "adventure ruin",
			title => "adventure ruin (15% success)",
			dm_unclaimed => "#adventureruin 15",
			themes => 'adventure',
		),

		# Gain XP for commander + units
		# TODO add themes
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2,3],
			generate => sub {
				my $pts = shift;
				my $xp = 8 * $pts;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "gain xp",
					title => "enter to gain $xp xp",
					dm_unclaimed => "#xp $xp",
				);
			}
		),

		# Call God bonus
		ThroneGen::PowerGenerator->new(
			pts_allowed => [2,4],
			generate => sub {
				my $pts = shift;
				my $callgod = $pts/2;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "call god",
					title => "+$callgod Call God bonus",
					dm_claimed => "#recallgod $callgod",
					themes => 'piety',
				);
			}
		),

		# dominions conflict bonus
		ThroneGen::PowerGenerator->new(
			pts_allowed => [2,4],
			generate => sub {
				my $pts = shift;
				my $conflictbonus = $pts/2;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "dom conflict bonus",
					title => "+$conflictbonus Dominion conflict bonus",
					dm_claimed => "#domwar $conflictbonus",
					themes => 'piety',
				);
			}
		),

		# permanent temple
		ThroneGen::PowerGenerator::Simple->new(
			pts => 1,
			type => "permanent temple",
			title => "free permanent temple when claimed",
			dm_event => "#newevent\n"
				   ."#msg \"As the throne is claimed, a temple to ##godname## springs from the ground. [THRONE_NAME]\"\n"
				   ."#nation -2 -- province owner\n"
				   ."#rarity 5 -- checked every turn\n"
				   ."#req_site 1 -- only happens to province specified in msg\n"
				   ."#req_temple 0 -- requires lack of temple\n"
				   ."#req_claimedthrone 1 -- throne must be claimed\n"
				   ."#req_pop0ok -- happens in dead provinces as well\n"
				   ."#temple 1 -- constructs a temple\n"
				   ."#end\n",
			themes => 'piety',
		),

		#
		#
		# Blesses
		#
		#

		# bless resists
		# TODO add themes
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2],
			generate => sub {
				my $pts = shift;
				my $res = 5 * $pts;
				my $element_cmd = (qw/fire cold shock pois/)[int rand 4];
				my $element_full = $element_cmd eq 'pois' ? 'poison' : $element_cmd;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "bless",
					title => "Blessed get +$res $element_full resistance",
					dm_claimed => "#bless${element_cmd}res $res",
				);
			}
		),

		# bless atk/def/prec/morale/reinvig/hp/undying
		# TODO add themes
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2,3],
			generate => sub {
				my $pts = shift;
				my %stats = (
					att      => 'attack',
					def      => 'defense',
					prec     => 'precision',
					mor      => 'morale',
					reinvig  => 'reinvigoration',
					hp       => 'hp',
					dtv      => 'undying',
				);
				my $stat = _random_element( keys %stats );
				return ThroneGen::Power->new(
					pts => $pts,
					type => "bless",
					title => "Blessed get +$pts $stats{$stat}",
					dm_claimed => "#bless$stat $pts",
				);
			}
		),
		
		# bless darkvision
		# TODO add themes
		ThroneGen::PowerGenerator->new(
			pts_allowed => [2,4],
			generate => sub {
				my $pts = shift;
				my $dv = $pts/2 * 50;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "bless",
					title => "Blessed get darkvision +$dv",
					dm_claimed => "#blessdarkvis $dv",
				);
			}
		),
		
		# bless awe
		ThroneGen::PowerGenerator::Simple->new(
			pts => 6,
			type => "bless",
			title => "Blessed get Awe +1",
			themes => 'awe',
			dm_claimed => "#blessawe 1",
		),
		
		# bless animal awe
		# TODO add themes
		ThroneGen::PowerGenerator::Simple->new(
			pts => 2,
			type => "bless",
			title => "Blessed get Animal Awe +1",
			dm_claimed => "#blessanimawe 1",
		),

		#
		#
		# Negative effects
		#
		#
		
		# less gold income
		ThroneGen::PowerGenerator::Simple->new(
			pts => -1,
			type => "gold per month",
			title => '-100 gold per month',
			dm_claimed => "#gold -100",
		),
		# cause unrest
		ThroneGen::PowerGenerator::Simple->new(
			pts => -1,
			type => "unrest",
			title => "causes 10 unrest per month",
			themes => 'turmoil',
			dm_claimed => "#decunrest -10",
		),
		# curse
		ThroneGen::PowerGenerator::Simple->new(
			pts => -1,
			type => "curse",
			title => "curses 1% of units in province per month",
			themes => 'death',
			dm_claimed => "#curse 1",
		),
		# horror mark
		ThroneGen::PowerGenerator::Simple->new(
			pts => -1,
			type => "horror mark",
			title => "horror marks 1% of units in province per month",
			themes => 'horror',
			dm_claimed => "#horrormark 1",
		),
		# reduced supply
		ThroneGen::PowerGenerator::Simple->new(
			pts => -1,
			type => "supply",
			title => "-150 supply",
			dm_unclaimed => "#supply -150",
		),
		# reduced resources
		ThroneGen::PowerGenerator::Simple->new(
			pts => -1,
			type => "resources",
			title => "-100 resources",
			themes => 'sloth',
			dm_unclaimed => "#res -100",
		),

		#
		# 0pt-powers
		#
		
		# province scale
		ThroneGen::PowerGenerator->new(
			pts_allowed => [0],
			generate => sub {
				my %cmds = (
					'Turmoil'      => '#incscale 0',
					'Sloth'        => '#incscale 1',
					'Cold'         => '#incscale 2',
					'Death'        => '#incscale 3',
					'Misfortune'   => '#incscale 4',
					'Drain'        => '#incscale 5',
					'Order'        => '#decscale 0',
					'Productivity' => '#decscale 1',
					'Heat'         => '#decscale 2',
					'Growth'       => '#decscale 3',
					'Luck'         => '#decscale 4',
					'Magic'        => '#decscale 5',
				);
				my $scale = _random_element( keys %cmds );
				return ThroneGen::Power->new(
					pts => 0,
					type => "province scale",
					title => "Increases $scale in province",
					themes => lc($scale),
					dm_unclaimed => $cmds{$scale},
				);
			},
		),
		
		# wall mage
		# TODO add themes
		ThroneGen::PowerGenerator::WallMage->new(),



	] },
);

sub _random_element {
	# return random element from list
	return $_[ int rand( 0+@_ ) ];
}


__PACKAGE__->meta->make_immutable;

1;
