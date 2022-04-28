use 5.30.0;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use ThroneGen;

# generate thrones

my $thronegen = ThroneGen->new( num_thrones => 3 );

# print thrones to STDOUT

$thronegen->print_thrones;

# write DM

open( my $fh, '>', '../tg.dm' ) or die $!;
$thronegen->write_dm( $fh );
close $fh or die $!;

