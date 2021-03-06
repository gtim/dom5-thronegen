package ThroneGen;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Carp;
use JSON qw/encode_json/;
use List::Util qw/any/;
use POSIX qw/ceil/;
use feature 'say';

use ThroneGen::Throne;
use ThroneGen::DM;

has 'num_thrones' => (
	is       => 'ro',
	isa      => 'Int',
	default  => 5,
);

has 'thrones' => (
	is       => 'ro',
	isa      => 'ArrayRef[ThroneGen::Throne]',
	builder  => '_generate_thrones',
	init_arg => undef,
	lazy     => 1,
);

sub _generate_thrones {
	my $self = shift;
	my $pts_per_throne = 4;
	local $_;

	my @thrones;
	my $num_darkvis_thrones = 0;
	my $max_darkvis_thrones = ceil( $self->num_thrones / 8 ); 

	for ( 1..$self->num_thrones ) {

		my $throne_candidate = ThroneGen::Throne->new(
			pts => $pts_per_throne,
			disallowed_names => [ map { $_->name } @thrones ],
		);

		# ensure there's not too many darkvision thrones
		# this should probably be implemented as a TG::Power member 
		if ( any { defined $_->dm_claimed && $_->dm_claimed =~ m/\#blessdarkvis / } @{$throne_candidate->powers} ) {
			if ( $num_darkvis_thrones + 1 > $max_darkvis_thrones ) {
				carp "too many darkvis thrones (already had $num_darkvis_thrones/$max_darkvis_thrones): regenerating last one";
				redo;
			} else {
				$num_darkvis_thrones++;
			}
		}

		push @thrones, $throne_candidate;
	}

	return \@thrones;
}

#
# Output 
#

sub print_thrones {
	my $self = shift;
	for my $throne ( @{$self->thrones} ) {
		say $throne->name;
		say "  " . $_->title for ( $throne->outputfriendly_powers );
		say "";
	}
}

sub as_json {
	# print as JSON, ready to use by the svelte web interface
	my $self = shift;

	# thrones

	my @json_thrones;
	for my $throne ( @{$self->thrones} ) {
		my $json_throne = {
			name => $throne->name,
			pts => $throne->pts,
			powers => [
				map { {
					pts => $_->pts,
					title => $_->title,
				} } $throne->outputfriendly_powers
			]
		};
		push @json_thrones, $json_throne;
	}
	
	# dm JSON
	
	my $dm_content;
	open( my $fh, '>', \$dm_content) or die $!;
	$self->write_dm( $fh );
	close $fh or die $!;
	
	# return

	return encode_json( {
		thrones => \@json_thrones,
		dm => $dm_content,
	} );
}

sub write_dm {
	my ( $self, $fh ) = @_;
	my $dm = ThroneGen::DM->new(
		thrones => $self->thrones,
		fh => $fh,
	);
	$dm->write();
}


__PACKAGE__->meta->make_immutable;

1;
