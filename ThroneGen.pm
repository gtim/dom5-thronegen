package ThroneGen;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Carp;
use JSON qw/encode_json/;
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
	my @thrones = map { ThroneGen::Throne->new( pts => 4 ) } ( 1..$self->num_thrones );
	return \@thrones;
}

#
# Output 
#

sub print_thrones {
	my $self = shift;
	for my $throne ( @{$self->thrones} ) {
		say $throne->name;
		say "  " . $_->title for ( @{$throne->powers} );
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
				sort { $b->{pts} <=> $a->{pts} }
				map { {
					pts => $_->pts,
					title => $_->title,
				} } @{$throne->powers}
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
