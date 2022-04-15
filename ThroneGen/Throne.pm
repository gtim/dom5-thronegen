package ThroneGen::Throne;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Carp;
use POSIX qw/ceil/;
use List::Util qw/uniq/;
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
	default => sub {
		my $self = shift;
		local $_;
		my @themes = map { @{ $_->themes } } @{ $self->powers };
		if ( @themes == 0 ) {
			carp "no theme found for throne";
			return 'The Throne of No Theme Found';
		}
		my ( undef, $most_common_theme ) = mode @themes;
		my $word = ThroneGen::ThematicWords->instance->word_on_theme( $most_common_theme );
		return "The Throne of $word";
	}
);
has 'powers' => (
	is => 'ro',
	isa => 'ArrayRef[ThroneGen::Power]',
	lazy => 1,
	default => sub {
		my $self = shift;

		# distribute points
		
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

		# generate powers
		
		local $_;
		my @powers;
		for my $num_tries ( 1..100 ) {
			@powers = map { ThroneGen::PowerGeneratorList->instance->random_power($_) } @pts;
			if ( scalar( uniq map { $_->type } @powers ) == scalar @powers ) {
				# all powers have unique types
				return \@powers;
			}
		}
		croak "no unique power types found for point distribution [@pts] after many tries";
	}
);

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
	print  $fh "#rarity 11 -- lvl1 throne\n";

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

