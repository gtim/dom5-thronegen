package ThroneGen::DM;

use Moose;
use namespace::autoclean;
use Carp;

use ThroneGen::PowerGeneratorList;

# Dom5 Throne IDs are sequential
my $First_Throne_ID = 1103;
my $Last_Throne_ID  = 1157;

has 'thrones' => (
	is       => 'ro',
	isa      => 'ArrayRef[ThroneGen::Throne]',
	required => 1,
);
has 'fh' => (
	is       => 'ro',
	isa      => 'FileHandle',
	default  => sub { \*STDOUT },
);

sub write {
	my $self = shift;

	$self->write_header();

	my $throne_id = $First_Throne_ID;
	for my $throne ( @{$self->thrones} ) {
		croak "more thrones than vanilla thrones" if $throne_id > $Last_Throne_ID;
		$throne->site_id( $throne_id );
		$throne->write_to_dm( $self->fh );
		$throne_id++;
	}

	$self->write_disable_throne_IDs( $throne_id..$Last_Throne_ID );

}

sub write_header {
	my $self = shift;
	print {$self->fh} "#modname \"ThroneGen\"\n";
	print {$self->fh} "#description \"TODO\"\n";
	print {$self->fh} "#version 0.1\n";
	print {$self->fh} "\n";
}

sub write_disable_throne_IDs {
	my ( $self, @throne_ids ) = @_;
	for my $throne_id ( @throne_ids ) {
		if ( $throne_id < $First_Throne_ID || $throne_id > $Last_Throne_ID ) {
			carp "ordered to disable non-vanilla throne #$throne_id";
		}
		printf {$self->fh} "#selectsite %d\n", $throne_id;
		print  {$self->fh} "#rarity 5\n";
		print  {$self->fh} "#end\n";
	}
}


__PACKAGE__->meta->make_immutable;

1;


