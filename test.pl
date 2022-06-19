# temp script for testing

use 5.30.0;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use ThroneGen::PowerGenerator::Simple;

my $pg = ThroneGen::PowerGenerator::Simple->new(
	pts => -1,
	type => "temple checks per month",
	title => "one less temple check per month",
	themes => 'piety',
	dm_increased_domspread => -1,
	boring => 1,
);
say $pg;
say $pg->generate->(-1);
