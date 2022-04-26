package ThroneGen::PowerGeneratorList;

#
# Power Generator List
#

use MooseX::Singleton;
use MooseX::StrictConstructor;
use namespace::autoclean;

use ThroneGen::Power;
use ThroneGen::PowerGenerator;
use ThroneGen::PowerGenerator::Simple;
use ThroneGen::PowerGenerator::RecruitableMage;
use ThroneGen::PowerGenerator::WallMage;

use List::Util qw/shuffle any/;
use List::Util::WeightedChoice qw/choose_weighted/;
use Ref::Util qw/is_arrayref/;
use Carp;
use POSIX qw/round/;

sub random_power {
	# generate a random power, subject to restrictions
	# argument: hash with optional keys:
	#   pts: exact number of points for power
	#   themes: themes, at least one theme from list must be present in power theme list
	#   disallowed_types arrayref of types not allowed
	
	my $self = shift;
	my %criteria = @_;
	local $_;

	my @valid_generators = @{$self->generators};
	if ( exists $criteria{pts} ) {
		@valid_generators = grep { $_->can_generate_pts( $criteria{pts} ) } @valid_generators;
	}
	if ( exists $criteria{themes} ) {
		@valid_generators = grep { $_->can_generate_themes( $criteria{themes} ) } @valid_generators;
	}

	while ( @valid_generators > 0 ) {

		# choose a weighted-random generator
		my $gen_i = choose_weighted( [0..$#valid_generators], [map { $_->weight } @valid_generators] );
		my $gen = splice @valid_generators, $gen_i, 1;

		# this generator can fulfill pts+themes criteria: try to generate
		# this is not guaranteed to succeed as:
		#   - themes might be chosen randomly
		#   - disallowed types are checked later
		#   - the requested pts/disallowed_types might not even allow for the requested theme
		for ( 1..100 ) {
			my $power = $gen->generate->( $criteria{pts} );
			if ( exists $criteria{themes} && ! _do_themes_overlap( $power->themes, $criteria{themes} ) ) {
				# themes don't overlap; try again
				next;
			}
			if ( exists $criteria{disallowed_types} && any { $_ eq $power->type } @{$criteria{disallowed_types}} ) {
				# type is disallowed: try again
				next;
			}
			return $power;
		}
	}
	# no generator can generate such a power
	carp sprintf( "did not succeed generating power: { pts: %s, themes: %s, disallowed types: %s }",
		$criteria{pts} // 'unspecified',
		exists($criteria{themes}) ? ( is_arrayref($criteria{themes}) ? join('|',@{$criteria{themes}}) : $criteria{themes} ) : '-',
		exists($criteria{disallowed_types}) ? join(', ', @{$criteria{disallowed_types}}) : '-',
	);
	return 0;
}

sub _do_themes_overlap {
	# TODO: temporary function to be removed when Themes object is introduced
	my ( $themes1, $themes2 ) = @_;
	my @themes1 = is_arrayref( $themes1 ) ? @$themes1 : $themes1;
	my @themes2 = is_arrayref( $themes2 ) ? @$themes2 : $themes2;
	for my $t1 ( @themes1 ) {
		for my $t2 ( @themes2 ) {
			return 1 if $t1 eq $t2;
		}
	}
	return 0;
}


has 'generators' => (
	is => 'ro',
	isa => 'ArrayRef[ThroneGen::PowerGenerator]',
	default => sub { [
		# recruitable mage
		ThroneGen::PowerGenerator::RecruitableMage->new( weight => 2 ),

		# gem income
		# 1/2/3/4 pts => 1/2/3/4 gems,
		ThroneGen::PowerGenerator->new(
			generate => sub {
				my $pts = shift;
				my $num_gems = $pts;
				my $gem_id = int rand 7;
				my $gem_str = (qw/F A W E S D N/)[$gem_id];
				my $theme =  {F => 'fire', A => 'air', W => 'water', E => 'earth', S => 'astral', D => 'death', N => 'nature' }->{$gem_str};
				return ThroneGen::Power->new(
					pts => $pts,
					type => "$gem_str per month",
					title => sprintf( '+%d %s gem%s per month', $num_gems, $gem_str, ($num_gems==1?'':'s') ),
					themes => $theme,
					dm_claimed => "#gems $gem_id $num_gems",
				);
			},
			possible_themes => [qw/fire air water earth astral death nature/],
			weight => 4,
		),

		# slave income
		# 2.5 slaves per pt, round result randomly
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2],
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
			},
			possible_themes => 'blood',
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
			},
			possible_themes => 'gold',
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
			},
			possible_themes => 'piety',
		),
		ThroneGen::PowerGenerator::Simple->new(
			pts => -1,
			type => "temple checks per month",
			title => "one less temple check per month",
			themes => 'piety',
			dm_increased_domspread => -1,
		),

		# improve nation scales: order/prod/growth/luck/magic
		ThroneGen::PowerGenerator->new(
			pts_allowed => [3,6,9],
			generate => sub {
				my $pts = shift;
				my $scale_points = $pts/3;
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
			},
			possible_themes => [qw/order productivity growth luck magic/],
			weight => 2,
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
			},
			possible_themes => 'scrying',
			weight => 0.5,
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
			},
			possible_themes => [qw/magic blood productivity/],
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
		# all +2: 3pt 
		
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
			},
			possible_themes => [qw/fire air water earth astral death nature blood/],
			weight => 0.3,
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
			},
			possible_themes => 'magic',
			weight => 0.3,
		),
		# ritual range bonus, all paths
		ThroneGen::PowerGenerator->new(
			pts_allowed => [2,3],
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
			},
			possible_themes => 'magic',
			weight => 0.3,
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
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2,3],
			generate => sub {
				my $pts = shift;
				my $xp = 8 * $pts;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "gain xp",
					title => "enter to gain $xp xp",
					themes => 'battle',
					dm_unclaimed => "#xp $xp",
				);
			},
			possible_themes => 'battle',
		),

		# Call God bonus
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2],
			generate => sub {
				my $pts = shift;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "call god",
					title => "+$pts Call God bonus",
					dm_claimed => "#recallgod $pts",
					themes => 'piety',
				);
			},
			possible_themes => 'piety',
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
			},
			possible_themes => 'piety',
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
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2],
			generate => sub {
				my $pts = shift;
				my $res = 5 * $pts;
				my $element_cmd = (qw/fire cold shock pois/)[int rand 4];
				my $element_full = $element_cmd eq 'pois' ? 'poison' : $element_cmd;
				my %themes = ( fire => 'heat', cold => 'cold', shock => 'air', pois => 'poison' );
				return ThroneGen::Power->new(
					pts => $pts,
					type => "bless",
					title => "Blessed get +$res $element_full resistance",
					themes => $themes{$element_cmd},
					dm_claimed => "#bless${element_cmd}res $res",
				);
			},
			possible_themes => [qw/heat cold air poison/],
			weight => 2,
		),

		# bless atk/def/prec/morale/reinvig/hp/undying
		ThroneGen::PowerGenerator->new(
			pts_allowed => [1,2,3],
			generate => sub {
				my $pts = shift;
				my %stats = ( # blesscommand -> [ human-readable word, theme ]
					att      => ['attack',         'battle'         ],
					def      => ['defense',        'battle'         ],
					prec     => ['precision',     ['battle','air' ] ],
					mor      => ['morale',         'awe'            ],
					reinvig  => ['reinvigoration', 'growth'         ],
					hp       => ['hp',             'growth'         ],
					dtv      => ['undying',        'death'          ],
				);
				my $stat = _random_element( keys %stats );
				my $word = $stats{$stat}[0];
				my $theme = $stats{$stat}[1];
				return ThroneGen::Power->new(
					pts => $pts,
					type => "bless",
					title => "Blessed get +$pts $word",
					themes => $theme,
					dm_claimed => "#bless$stat $pts",
				);
			},
			possible_themes => [qw/battle air awe growth death/],
			weight => 2,
		),
		
		# bless darkvision
		ThroneGen::PowerGenerator->new(
			pts_allowed => [2,4],
			generate => sub {
				my $pts = shift;
				my $dv = $pts/2 * 50;
				return ThroneGen::Power->new(
					pts => $pts,
					type => "bless",
					title => "Blessed get darkvision +$dv",
					themes => 'darkness',
					dm_claimed => "#blessdarkvis $dv",
				);
			},
			possible_themes => 'darkness',
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
		ThroneGen::PowerGenerator::Simple->new(
			pts => 2,
			type => "bless",
			title => "Blessed get Animal Awe +1",
			themes => 'awe',
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
			themes => 'sloth',
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
			themes => 'misfortune',
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
			themes => 'death', # TODO find a better theme
			dm_unclaimed => "#supply -150",
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
			possible_themes => [qw/turmoil sloth cold death misfortune drain order productivity heat growth luck magic/],
		),
		
		# wall mage
		ThroneGen::PowerGenerator::WallMage->new(),

		# reduced resources
		ThroneGen::PowerGenerator::Simple->new(
			pts => 0,
			type => "resources",
			title => "-100 resources",
			themes => 'sloth',
			dm_unclaimed => "#res -100",
			weight => 0.3,
		),

		# improved resources
		ThroneGen::PowerGenerator::Simple->new(
			pts => 0,
			type => "resources",
			title => "+100 resources",
			themes => 'productivity',
			dm_unclaimed => "#res 100",
			weight => 0.3,
		),


	] },
);

sub _random_element {
	# return random element from list
	return $_[ int rand( 0+@_ ) ];
}


__PACKAGE__->meta->make_immutable;

1;
