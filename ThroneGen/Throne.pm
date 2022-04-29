package ThroneGen::Throne;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Carp;
use POSIX qw/ceil/;
use List::Util qw/uniq max/;
use List::MoreUtils qw/mode/;

use ThroneGen::PowerGeneratorList;
use ThroneGen::ThematicWords;

my $Default_Domspread = 2;

has 'pts' => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);
has 'site_id' => (
	# site ID should overwrite an old throne,
	# must be set before writing
	is       => 'rw',
	isa      => 'Int'
);
has 'name' => (
	is     => 'ro',
	isa     => 'Str',
	lazy    => 1,
	builder => '_generate_name',
);
has 'disallowed_names' => (
	# disallowed throne names, e.g. because there's already a throne of that name
	is     => 'ro',
	isa     => 'ArrayRef[Str]',
	default => sub { [] },
);
has 'powers' => (
	is => 'ro',
	isa => 'ArrayRef[ThroneGen::Power]',
	lazy => 1,
	builder => '_generate_powers',
);

sub _generate_name {
	my $self = shift;
	my $attempt = shift // 1;
	local $_;

	# themes weighted by power value
	my @themes = map { ( @{ $_->themes } ) x max( $_->pts, 1 ) } @{ $self->powers };
	if ( @themes == 0 ) {
		carp "no theme found for throne";
		return 'The Throne of No Theme Found';
	}

	# find most common theme (after weights)
	my ( undef, @most_common_themes ) = mode @themes;
	my $most_common_theme = $most_common_themes[ int rand @most_common_themes ];

	# generate throne name on the theme
	my $throne_name = ThroneGen::ThematicWords->instance->throne_name_on_theme( $most_common_theme );

	# check if throne name is allowed
	if ( ! grep { $_ eq $throne_name } @{$self->disallowed_names} ) {
		# allowed
		return $throne_name;
	} elsif ( $attempt < 90 ) {
		# disallowed: try again
		return $self->_generate_name( $attempt + 1 );
	} else {
		# 100th attempt: give up
		$throne_name .= ' ' . int rand 1e5;
		carp "Unable to find a unique name after 90 tries, going with: $throne_name";
		return $throne_name;
	}
}

sub _generate_powers {
	my $self = shift;

	# make point distribution
	
	my @pts;
	my $pts_left = $self->pts;
	# 40% chance for  0 pt power
	push @pts, 0 if rand() < 0.4;
	# 20% chance for -1 pt power
	if ( rand() < 0.2 ) {
		push @pts, -1;
		$pts_left += 1;
	}
	# First power: spend at least half points
	push @pts, _rand_int_between_inclusive( ceil( $pts_left/2 ), $pts_left );
	$pts_left -= $pts[-1];
	# Second power: spend remaining points
	if ( $pts_left > 0 ) {
		unshift @pts, $pts_left;
	}

	# generate powers that fit restrictions
	
	@pts = sort {$b<=>$a} @pts;
	my @powers;

	# generate first power
	@powers = ( ThroneGen::PowerGeneratorList->instance->random_power( pts => shift @pts ) );

	# generate following powers
	for my $pt ( @pts ) {
		my $power;
		my $chance_of_same_theme = ( $pt == 0 ? 0.9 : 0.5 ); # 90% for flavour 0pt powers, otherwise 50%
		if ( rand() < $chance_of_same_theme ) {
			# same theme as first power
			$power = ThroneGen::PowerGeneratorList->instance->random_power(
				pts => $pt,
				disallowed_types => [ map { $_->type } @powers ],
				themes => $powers[0]{themes},
			);
		}
		if ( ! $power ) {
			# either theme not forced, or forced theme did not succeed
			$power = ThroneGen::PowerGeneratorList->instance->random_power(
				pts => $pt,
				disallowed_types => [ map { $_->type } @powers ],
			);
		}
		if ( ! $power ) {
			# did not succeed to generate throne while respecting pts and disallowed types,
			# so we recurse. this should be rare.
			carp "no unique power types found for point distribution [@pts] on first try: recursing";
			return $self->_generate_powers();
		}
		push @powers, $power;
	}
	return \@powers;

	croak "no unique power types found for point distribution [@pts] after many tries";
}

sub _rand_int_between_inclusive {
	my ( $min, $max ) = @_;
	return $min + int( rand( $max - $min + 1 ) );
}

sub write_to_dm {
	my ( $self, $fh ) = @_;
	croak "Throne::write_to_dm called before setting site_id" unless $self->site_id;
	printf $fh "#selectsite %d\n", $self->site_id;
	print  $fh "#clear\n";
	print  $fh "#name \"".$self->name."\"\n";
	print  $fh "#path 8\n";
	print  $fh "#level 0\n";
	print  $fh "#loc 213999 -- unique, allowed everywhere\n";
	print  $fh "#rarity 12 -- lvl 2 throne\n";

	# always-on throne powers 
	for my $power ( @{ $self->powers } ) {
		print $fh $power->dm_unclaimed."\n" if $power->has_dm_unclaimed;
	}

	# claimed-only throne powers
	print  $fh "#claim\n";
	printf $fh "#dominion %d\n", $self->_domspread();
	for my $power ( @{ $self->powers } ) {
		print $fh $power->dm_claimed."\n" if $power->has_dm_claimed;
	}
	print  $fh "#end\n";
	print  $fh "\n";

	# events from throne powers
	for my $power ( @{ $self->powers } ) {
		if ( $power->has_dm_event ) {
			my $event_dm = $power->dm_event;
			my $throne_name = $self->name;
			$event_dm =~ s/THRONE_NAME/$throne_name/g;
			print $fh $event_dm . "\n";
		}
	}
	
	# units from throne powers
	for my $power ( @{ $self->powers } ) {
		print $fh $power->dm_monster . "\n" if $power->has_dm_monster;
	}
}

sub _domspread {
	my $self = shift;
	my $domspread = $Default_Domspread;
	for my $power ( @{ $self->powers } ) {
		if ( $power->dm_increased_domspread ) {
			$domspread += $power->dm_increased_domspread;
		}
	}
	return $domspread;
}


__PACKAGE__->meta->make_immutable;

1;

