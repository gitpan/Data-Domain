#!perl

use Test::More tests => 2;

use lib "../lib";

use Data::Domain qw/:all !Date/, ;

ok(Int(),         'Int was imported');
ok(!eval{Date()}, 'Date was not imported');


