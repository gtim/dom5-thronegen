# temp script for testing

use 5.30.0;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use ThroneGen::PowerGenerator::Simple;

my $pg = ThroneGen::PowerGenerator::Simple->new(
	pts => -1,
	type => "resources",
	title => "-100 resources",
	dm_unclaimed => "#res -100",
);
say $pg;
say $pg->generate;
say $pg->generate->(-1);
