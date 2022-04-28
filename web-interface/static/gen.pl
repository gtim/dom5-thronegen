#!/usr/bin/perl

use 5.30.0;
use warnings;

use CGI::Simple;
use List::Util qw/min max/;

use lib '/srv/http/thronegen.illwiki.com/public_html';
use ThroneGen;

# write headers

my $cgi = CGI::Simple->new;
print $cgi->header('application/json');

# clamp GET parameter

my $num_thrones = $cgi->param('n') || 5;
$num_thrones = 5 unless $num_thrones =~ m/^\d+$/;
$num_thrones = min( $num_thrones, 20 );
$num_thrones = max( $num_thrones, 1 );

# generate thrones

my $thronegen = ThroneGen->new( num_thrones => $num_thrones );

# output as JSON

print $thronegen->as_json();
