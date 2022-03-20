use 5.30.0;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use ThroneGen::Throne;
use ThroneGen::DM;

# generate thrones
my @thrones;
push @thrones, ThroneGen::Throne->new( pts => 3) for ( 1..5 );

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
