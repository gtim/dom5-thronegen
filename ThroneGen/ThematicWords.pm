package ThroneGen::ThematicWords;

use MooseX::Singleton;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use Carp;
use YAML qw//;
use Data::Dumper qw(Dumper);
use Ref::Util qw/is_hashref is_arrayref is_ref/;
use List::Util qw/all any/;

has 'words' => (
	is => 'ro',
	isa => 'HashRef',
	builder => '_load_words',
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

sub _load_words {
	my $words = YAML::LoadFile( 'ThroneGen/data/thematic_words.yaml' );
	# aliases
	$words->{heat} = $words->{fire}; 
	# validate yaml structure
	for my $theme ( keys %$words ) {
		croak "Theme '$theme' is not a hashref" unless is_hashref $words->{$theme};
		croak "Theme '$theme' has neither 'of' nor 'adjective' words" unless exists( $words->{$theme}{of} ) || exists $words->{$theme}{adjective};
		for my $word_type ( qw/of adjective/ ) {
			if ( exists( $words->{$theme}{$word_type} ) ) {
				local $_;
				croak "Theme '$theme' has non-arrayref '$word_type'" unless is_arrayref $words->{$theme}{$word_type};
				croak "Theme '$theme'->'$word_type' contains zero entries" if @{$words->{$theme}{$word_type}} == 0;
				croak "Theme '$theme'->'$word_type' contains references" if any {is_ref($_)} @{$words->{$theme}{$word_type}};
			}
		}
	}
	return $words;
}

sub throne_name_on_theme {
	my ( $self, $theme ) = @_;
	# theme string must correspond to themes defined in thematic_words.yaml

	croak "unknown theme: $theme" unless exists $self->words->{$theme};

	# pick a random appropriate word
	my @words;
	for my $word_type ( qw/of adjective/ ) {
		last unless exists $self->words->{$theme}{$word_type};
		local $_;
		push @words, map { [ $_, $word_type ] } @{ $self->words->{$theme}{$word_type} };
	}
	my $word = $words[ int rand @words ];
	if ( $word->[1] eq 'of' ) {
		return "The Throne of $word->[0]";
	} elsif ( $word->[1] eq 'adjective' ) {
		return "The $word->[0] Throne";
	} else {
		croak "Uknown word type for theme '$theme': $word->[1]";
	}
}


__PACKAGE__->meta->make_immutable;

1;

