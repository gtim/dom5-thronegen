package ThroneGen::PowerGenerator::Simple;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use ThroneGen::Power;
use Carp;

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
	for my $required_arg ( qw/pts type title themes/ ) {
		croak "$required_arg not defined in TG::PG::Simple constructor (title: $args{title})" unless defined $args{$required_arg};
	}

	my %weight_arg = ();
	if ( exists $args{weight} ) {
		%weight_arg = ( weight => $args{weight} );
		delete $args{weight}
	}

	return $class->$orig(
		pts_allowed => [ $args{pts} ],
		possible_themes => $args{themes},
		%weight_arg,
		_power_arguments => \%args,
	);
};


__PACKAGE__->meta->make_immutable;

1;
