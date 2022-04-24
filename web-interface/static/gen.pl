#!/usr/bin/perl

use 5.30.0;
use warnings;

use CGI::Simple;
use JSON qw/encode_json/;
use List::Util qw/min max/;

use lib '/srv/http/thronegen.illwiki.com/public_html';
#use lib '../..';
use ThroneGen::Throne;
use ThroneGen::DM;

# write headers

my $cgi = CGI::Simple->new;
print $cgi->header('application/json');

# generate n 4pt thrones

my $num_thrones = $cgi->param('n') || 5;
$num_thrones = 5 unless $num_thrones =~ m/^\d+$/;
$num_thrones = min( $num_thrones, 20 );
$num_thrones = max( $num_thrones, 1 );
my @thrones = map { ThroneGen::Throne->new( pts => 4 ) } ( 1..$num_thrones );

#
# make JSON
#

# thrones
my @j_thrones;
for my $throne ( @thrones ) {
	my $j_throne = {
		name => $throne->name,
		pts => $throne->pts,
		powers => [
			sort { $b->{pts} <=> $a->{pts} }
			map { {
				pts => $_->pts,
				title => $_->title,
			} } @{$throne->powers}
		]
	};
	push @j_thrones, $j_throne;
}

# dm
my $dm_content;
open( my $fh, '>', \$dm_content) or die $!;
ThroneGen::DM->new(
	thrones => \@thrones,
	fh => $fh,
)->write();

# json encode and output
print encode_json( {
	thrones => \@j_thrones,
	dm => $dm_content,
} );
