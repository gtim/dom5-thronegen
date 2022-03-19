use 5.30.0;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use ThroneGen::Throne;

for my $i ( 1..5 ) {
	my $throne = ThroneGen::Throne->new( pts => 3);
	say "Throne #$i";
	say "  " . $_->title for ( @{$throne->powers} );
	say "";
}
