package ThroneGen::ThematicWords;

use MooseX::Singleton;
use namespace::autoclean;
use Carp;

has 'words' => (
	is => 'ro',
	isa => 'HashRef',
	default => sub { {
		# TODO move words to data file
		fire => ['Fire','Flames','Brass','Summer','the Sun','Deserts','Dragons','the Phoenix','Magma','Scorching Winds', 'Scorching Storms','Suns','Rage','Gold','Rubies','Sunlight','Volcanoes','Heat'],
		air => ['Air','the Sky'],
		water => ['Water','the Ocean'],
		earth => ['Earth','Earthquakes'],
		astral => ['Pearls','Time'],
		death => ['Death','Shadows'],
		nature => ['Nature','Forests'],
		blood => ['Blood'],
	} },
);

sub word_on_theme {
	my ( $self, $theme ) = @_;
	croak "unknown theme: $theme" unless exists $self->words->{$theme};
	my $words = $self->words->{$theme};
	return $words->[ int rand @$words ];
}


__PACKAGE__->meta->make_immutable;

1;

