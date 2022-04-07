use 5.30.0;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use ThroneGen::Throne;
use ThroneGen::DM;

# generate five 5pt thrones

my @thrones = map { ThroneGen::Throne->new( pts => 4 ) } ( 1..3 );

# print thrones

for my $throne ( @thrones ) {
	say "Throne";
	say "  " . $_->title for ( @{$throne->powers} );
	say "";
}

# write .dm

open( my $fh, '>', '../tg.dm' ) or die $!;
my $dm = ThroneGen::DM->new(
	thrones => \@thrones,
	fh => $fh,
);
$dm->write();
close $fh or die $!;
