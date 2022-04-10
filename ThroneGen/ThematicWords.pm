package ThroneGen::ThematicWords;

use MooseX::Singleton;
use namespace::autoclean;
use Carp;
use YAML qw//;
use Data::Dumper qw(Dumper);
use Scalar::Util qw/reftype/;

has 'words' => (
	is => 'ro',
	isa => 'HashRef',
	default => sub {
		return YAML::LoadFile( 'ThroneGen/data/thematic_words.yaml' );
	},
);

sub word_on_theme {
	my ( $self, $theme ) = @_;
	# theme: string or arrayref of strings
	# string must correspond to themes defined in thematic_words.yaml

	# if multiple themes, pick one at random
	if ( reftype($theme) && reftype($theme) eq 'ARRAY' ) {
		$theme = $theme->[ int rand @$theme ];
	}
	
	# alias
	if ( $theme eq 'heat' ) {
		$theme = 'fire';
	}
	croak "unknown theme: $theme" unless exists $self->words->{$theme};

	# pick a random appropriate word
	my $words = $self->words->{$theme};
	return $words->[ int rand @$words ];
}


__PACKAGE__->meta->make_immutable;

1;

