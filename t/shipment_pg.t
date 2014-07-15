#!perl

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use Test::Roo;
with 'Test::Populate', 'Test::Shipment', 'Role::PostgreSQL';

run_me;

done_testing;
