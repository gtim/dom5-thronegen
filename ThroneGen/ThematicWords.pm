package ThroneGen::ThematicWords;

use MooseX::Singleton;
use namespace::autoclean;
use Carp;
use YAML qw//;
use Data::Dumper qw(Dumper);

has 'words' => (
	is => 'ro',
	isa => 'HashRef',
	default => sub {
		return YAML::LoadFile( 'ThroneGen/data/thematic_words.yaml' );
	},
);

sub word_on_theme {
	my ( $self, $theme ) = @_;
	croak "unknown theme: $theme" unless exists $self->words->{$theme};
	my $words = $self->words->{$theme};
	return $words->[ int rand @$words ];
}


__PACKAGE__->meta->make_immutable;

1;

