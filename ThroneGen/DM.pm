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
has 'dm_id' => (
	# randomly generated ID (not a seed)
	is => 'ro',
	isa => 'Str',
	default => sub {
		my @symbols = ('a'..'z', 0..9);
		return join '', map { $symbols[int rand @symbols] } 1..6;
	}
);

sub write {
	my $self = shift;

	# assigne thrones site IDs
	my $throne_id_first_unused;
	{
		my $throne_id = $First_Throne_ID;
		for my $throne ( @{$self->thrones} ) {
			croak "more thrones than vanilla thrones" if $throne_id > $Last_Throne_ID;
			$throne->site_id( $throne_id );
			$throne_id++;
		}
		$throne_id_first_unused = $throne_id;
	}

	# write header
	$self->write_header();

	# write thrones
	$_->write_to_dm( $self->fh ) for ( @{$self->thrones} );

	# disable unused thrones
	$self->write_disable_throne_IDs( $throne_id_first_unused..$Last_Throne_ID );

}

sub write_header {
	my $self = shift;
	printf {$self->fh} "#modname \"ThroneGen #%s\"\n", $self->dm_id;
	print  {$self->fh} "#description \"" . $self->description . "\"\n";
	print  {$self->fh} "#version 0.2\n";
	print  {$self->fh} "\n";
}

sub description {
	my $self = shift;
	my $desc = "Replaces all thrones with randomly generated ones. The thrones included with this instance are:\n\n";
	for my $throne ( @{$self->thrones} ) {
		$desc .= $throne->name . "\n";
		$desc .= "- " . $_->title . "\n" for ( @{$throne->powers} );
	}
	$desc .= "\n";
	$desc .= "You can generate new ones at thronegen.illwiki.com.";
	return $desc;
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


