package ThroneGen::Throne;

use Moose;
use namespace::autoclean;
use Carp;
use POSIX qw/ceil/;
use List::Util qw/uniq/;

use ThroneGen::PowerGeneratorList;

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
has 'powers' => (
	is => 'ro',
	isa => 'ArrayRef[ThroneGen::Power]',
	lazy => 1,
	default => sub {
		my $self = shift;
		my @pts;
		# First power: spend at least half points
		push @pts, _rand_int_between_inclusive( ceil( $self->pts/2 ), $self->pts );
		# Second power: spend remaining points
		if ( $self->pts - $pts[0] > 0 ) {
			push @pts, $self->pts - $pts[0];
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
	printf $fh "#name \"The Throne of Site ID %d\"\n", $self->site_id;
	print  $fh "#path 8\n";
	print  $fh "#level 0\n";
	print  $fh "#loc 213999 -- unique, allowed everywhere\n";
	print  $fh "#rarity 11 -- lvl1 throne\n";
	print  $fh "#claim\n";
	printf $fh "#dominion %d\n", $self->_domspread();
	for my $power ( @{ $self->powers } ) {
		print $fh $power->dm_claimed."\n" if $power->has_dm_claimed;
	}
	print  $fh "#end\n";
	print  $fh "\n";
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

