package ThroneGen::PowerGenerator::Simple;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use ThroneGen::Power;

extends 'ThroneGen::PowerGenerator';

# Simple power generator for static powers
# Arguments passed along to ThroneGen::Power

has '+generate' => (
	default => sub {
		my $self = shift;
		my $power_args = $self->_power_arguments;
		return sub {
			ThroneGen::Power->new(%$power_args);
		}
	}
);

has '_power_arguments' => (
	is =>  'ro',
	isa => 'HashRef',
);


around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;
	my %args = @_;
	return $class->$orig(
		pts_allowed => [ $args{pts} ],
		_power_arguments => \%args,
	);
};


__PACKAGE__->meta->make_immutable;

1;
