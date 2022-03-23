#!/usr/bin/perl

use 5.30.0;
use warnings;

use CGI::Simple;

use lib '/srv/http/thronegen.illwiki.com/public_html';
#use lib '../..';
use ThroneGen::Throne;
use ThroneGen::DM;

# write headers

my $cgi = CGI::Simple->new;
print $cgi->header('text/plain');

# generate five 5pt thrones

my @thrones = map { ThroneGen::Throne->new( pts => 5 ) } ( 1..5 );

# print thrones

for my $throne ( @thrones ) {
	say "Throne";
	say "  " . $_->title for ( @{$throne->powers} );
	say "";
}
