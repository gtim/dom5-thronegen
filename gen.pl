use 5.30.0;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use ThroneGen qw/@power_generators/;

say "Some sample powers:";

for my $pg ( @power_generators ) {
	for my $pts ( 1..3 ) {
		say $pg->generate->($pts)->title;
	}
}
