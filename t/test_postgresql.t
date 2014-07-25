#!perl

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use Test::Roo;
with 'Role::Fixtures', 'Role::PostgreSQL', 'Test::BaseAttribute', 'Test::Expire', 'Test::Message', 'Test::Payment', 'Test::Tax', 'Test::Variant', 'Test::Zone';

run_me;

done_testing;
