package ThroneGen::ThematicWords;

use MooseX::Singleton;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use Carp;
use YAML qw//;
use Data::Dumper qw(Dumper);
use Scalar::Util qw/reftype/;
use List::Util qw/all/;

has 'words' => (
	is => 'ro',
	isa => 'HashRef',
	default => sub {
		return YAML::LoadFile( 'ThroneGen/data/thematic_words.yaml' );
	},
);

subtype 'Themes',
	as 'ArrayRef[Str]',
	where {
		my $tw = ThroneGen::ThematicWords->instance;
		return all { exists $tw->words->{$_} } @$_;
	},
	message { "invalid themes: " . join( ', ', @$_ ) };

coerce 'Themes',
	from 'Str',
	via { [ $_ ] };

sub word_on_theme {
	my ( $self, $theme ) = @_;
	# theme string must correspond to themes defined in thematic_words.yaml

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

