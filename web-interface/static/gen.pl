#!/usr/bin/perl

use 5.30.0;
use warnings;

use CGI::Simple;
use JSON qw/encode_json/;

use lib '/srv/http/thronegen.illwiki.com/public_html';
#use lib '../..';
use ThroneGen::Throne;
use ThroneGen::DM;

# write headers

my $cgi = CGI::Simple->new;
print $cgi->header('application/json');

# generate five 5pt thrones

my @thrones = map { ThroneGen::Throne->new( pts => 4 ) } ( 1..5 );

#
# make JSON
#

# thrones
my @j_thrones;
for my $throne ( @thrones ) {
	my $j_throne = {
		pts => $throne->pts,
		powers => [
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
