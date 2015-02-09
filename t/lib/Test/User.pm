package Test::User;

use Test::Exception;
use Test::More;
use Try::Tiny;
use Test::Roo::Role;
use DateTime;

test 'simple user tests' => sub {

    diag Test::User;

    my $self = shift;

    # make sure there is no mess and stash user fixture count
    $self->clear_users;
    my $user_count = $self->users->count;

    my $schema = $self->ic6s_schema;

    my $rset_user = $schema->resultset('User');

    my ( $data, $result );

    throws_ok(
        sub { $rset_user->create( {} ) },
        qr/username cannot be unde/,
        "fail User create with empty hashref"
    );

    throws_ok(
        sub { $rset_user->create( { username => undef } ) },
        qr/username cannot be unde/,
        "fail User create with undef username"
    );

    throws_ok(
        sub { $rset_user->create( { username => 'MixedCase' } ) },
        qr/username must be lowercase/,
        "fail User create with mixed case username"
    );

    throws_ok(
        sub { $rset_user->create( { username => '' } ) },
        qr/username cannot be empty string/,
        "fail User create with empty string username"
    );

    lives_ok(
        sub {
            $result =
              $rset_user->create( { username => 'nevairbe@nitesi.de' } );
        },
        "create user"
    );

    throws_ok(
        sub { $rset_user->create( { username => 'nevairbe@nitesi.de' } ) },
        qr/DBI Exception/i,
        "fail to create duplicate username"
    );

    throws_ok(
        sub { $result->update( { username => 'MixedCase' } ) },
        qr/username must be lowercase/,
        "Fail to change username to mixed case"
    );

    lives_ok( sub { $result->delete }, "delete user" );

    cmp_ok( $rset_user->count, '==', $user_count, "user count is $user_count" );
    my $role_count = $schema->resultset('Role')->count;

    $data = {
        username => 'nevairbe@nitesi.de',
        email    => 'nevairbe@nitesi.de',
        password => 'nevairbe',
    };

    lives_ok( sub { $result = $rset_user->create($data) }, "create user" );

    like( $result->password, qr/^\$2a\$14\$.{53}$/,
        "Check password hash has correct format" );

    cmp_ok( $result->user_roles->count, '==', 1, "user has 1 user_roles" );
    cmp_ok( $result->roles->first->name, 'eq', 'user', "role is 'user'" );
    cmp_ok( $rset_user->count, '==', ++$user_count,
        "we have $user_count users" );
    cmp_ok( $schema->resultset('UserRole')->count,
        '==', $user_count, "$user_count user role" );
    cmp_ok( $schema->resultset('Role')->count,
        '==', $role_count, "$role_count roles" );

    lives_ok( sub { $result->delete }, "delete user" );

    cmp_ok( $rset_user->count, '==', --$user_count,
        "we have $user_count users" );
    cmp_ok( $schema->resultset('UserRole')->count,
        '==', $user_count, "$user_count user role" );
    cmp_ok( $schema->resultset('Role')->count,
        '==', $role_count, "$role_count roles" );

    # cleanup
    $self->clear_users;
};

test 'user attribute tests' => sub {

    my $self = shift;

    my $count;

    my $user = $self->users->first;

    # add attribute attibute value relationship
    $user->add_attribute( 'hair_color', 'blond' );

    my $hair_color = $user->find_attribute_value('hair_color');

    ok( $hair_color eq 'blond', "Testing AttributeValue." )
      || diag "hair_color: " . $hair_color;

    # change user attribute_value
    $user->update_attribute_value( 'hair_color', 'red' );

    $hair_color = $user->find_attribute_value('hair_color');

    ok( $hair_color eq 'red', "Testing AttributeValue." )
      || diag "hair_color: " . $hair_color;

    # use find_attribute_value object
    $user->add_attribute( 'fb_token', '10A' );
    my $av_object = $user->find_attribute_value( 'fb_token', { object => 1 } );

    my $fb_token = $av_object->value;

    ok( $fb_token eq '10A', "Testing AttributeValue." )
      || diag "fb_token: " . $fb_token;

    # delete user attribute
    $user->delete_attribute( 'hair_color', 'red' );

    my $del = $user->search_related('user_attributes')
      ->search_related('user_attribute_values');

    ok( $del->count eq '1', "Testing user_attribute_values count." )
      || diag "user_attribute_values count: " . $del->count;

    # return all attributes for $user with search_attributes method
    $user->add_attribute( 'favorite_color', 'green' );
    $user->add_attribute( 'first_car',      '64 Mustang' );

    my $attr = $user->search_attributes;

    ok( $attr->count eq '3', "Testing User Attribute count." )
      || diag "User Attribute count: " . $del->count;

    # cleanup
    lives_ok(
        sub { $user->user_attributes->delete_all },
        "delete_all on user->user_attributes"
    );
};

test 'user role tests' => sub {

    my $self   = shift;
    my $schema = $self->ic6s_schema;
    my $rset_user = $schema->resultset('User');

    # use roles fixture
    $self->roles;

    my ( $admin1, $admin2 );
    my $rset_role = $schema->resultset("Role");

    my $role_admin  = $rset_role->find( { name => 'admin' } );
    my $role_user   = $rset_role->find( { name => 'user' } );
    my $role_editor = $rset_role->find( { name => 'editor' } );

    lives_ok( sub { $admin1 = $self->users->find( { username => 'admin1' } ) },
        "grab admin1 user from fixtures" );

    lives_ok(
        sub { $admin1->set_roles( [ $role_admin, $role_user, $role_editor ] ) },
        "Add admin1 to admin, user and editor roles"
    );

    lives_ok( sub { $admin2 = $self->users->find( { username => 'admin2' } ) },
        "grab admin2 user from fixtures" );

    lives_ok( sub { $admin2->set_roles( [ $role_user, $role_editor ] ) },
        "Add admin2 to user and editor roles" );

    # count via m2m
    cmp_ok( $admin1->roles->count, '==', 3, "admin1 has 3 roles" );
    cmp_ok( $admin2->roles->count, '==', 2, "admin2 has 2 roles" );

    # test reverse relationship

    my %users_expected = (
        user   => { count => 2 },
        admin  => { count => 1 },
        editor => { count => 2 },
    );

    foreach my $name ( keys %users_expected ) {
        my $role     = $rset_role->find( { name => $name } );
        my $count    = $role->users->count;
        my $expected = $users_expected{$name}->{count};

        if ( $name eq 'user' ) {
            $expected = $rset_user->count;
        }
        cmp_ok( $count, '==', $expected, "Test user count for role " . $name );
    }

    # cleanup
    $self->clear_roles;
};

test 'password reset' => sub {

    my $self   = shift;
    my $schema = $self->ic6s_schema;

    my ( $user, $token, $dt );

    # make sure our test user starts off nice and clean

    lives_ok( sub { $user = $self->users->first }, "get a user" );

    lives_ok( sub { $user->reset_expires(undef) },
        "set reset_expires to undef" );

    lives_ok( sub { $user->reset_token(undef) }, "set reset_token to undef" );
    
    # simple reset token tests

    lives_ok( sub { $token = $user->reset_token_generate }, "get reset token" );

    ok(
        $user->reset_token_verify($token),
        "reset_token_verify on token is true"
    );

    like( $token, qr/^\w{22}_\w{32}$/, "token with checksum looks good" );

    $token =~ m/^(\w+)_/;

    cmp_ok( $1, 'eq', $user->reset_token,
        "token matches reset_token in db" );

    $dt = DateTime->now->add( hours => 23 );

    cmp_ok( $user->reset_expires, '>', $dt,
        "reset_expires is > 23 hours in the future" );

    $dt->add( hours => 1 );

    cmp_ok( $user->reset_expires, '<=', $dt,
        "reset_expires is <= 24 hours in the future" );

    # test failure after new token is generated

    lives_ok( sub { $user->reset_token_generate }, "get new reset token" );

    ok(
        !$user->reset_token_verify($token),
        "old token with checksum no longer valud"
    );

    # test failure on changed password

    lives_ok( sub { $token = $user->reset_token_generate }, "get reset token" );

    ok(
        $user->reset_token_verify($token),
        "reset_token_verify on token is true"
    );

    lives_ok( sub { $user->password('anewpassword') }, "change user password" );

    ok(
        !$user->reset_token_verify($token),
        "token with checksum no longer valud"
    );

    # 48 hour duration

    lives_ok(
        sub {
            $token = $user->reset_token_generate( duration => { hours => 48 } );
        },
        "get reset token with 48 hour duration"
    );

    like( $token, qr/^\w{22}_\w{32}$/, "token with checksum looks good" );

    ok(
        $user->reset_token_verify($token),
        "reset_token_verify on token is true"
    );

    $dt = DateTime->now->add( hours => 47 );

    cmp_ok( $user->reset_expires, '>', $dt,
        "reset_expires is > 47 hours in the future" );

    $dt->add( hours => 1 );

    cmp_ok( $user->reset_expires, '<=', $dt,
        "reset_expires is <= 48 hours in the future" );

    # undef duration

    lives_ok(
        sub {
            $token = $user->reset_token_generate( duration => undef );
        },
        "get reset token with undef duration"
    );

    like( $token, qr/^\w{22}_\w{32}$/, "token with checksum looks good" );

    ok(
        $user->reset_token_verify($token),
        "reset_token_verify on token is true"
    );

    ok( !$user->reset_expires, "reset_expires is undef" );

    # more entropy

    lives_ok(
        sub {
            $token = $user->reset_token_generate( entropy => 256 );
        },
        "get reset token with 256 bits of entropy"
    );

    like( $token, qr/^\w{43}_\w{32}$/, "token with checksum looks good" );

    ok(
        $user->reset_token_verify($token),
        "reset_token_verify on token is true"
    );

    # bad args to methods

    throws_ok( sub { $user->reset_token_generate( entropy => "QW" ) },
        qr/bad value for entropy/, "bad entropy arg to reset_token_generate");

    throws_ok( sub { $user->reset_token_generate( duration => "QW" ) },
        qr/must be a hashref/, "bad duration arg to reset_token_generate");

    throws_ok( sub { $user->reset_token_verify( "QW" ) },
        qr/Bad argument/, "bad arg reset_token_verify QW");

    throws_ok( sub { $user->reset_token_verify( "QW_" ) },
        qr/Bad argument/, "bad arg reset_token_verify QW_");

    $token =~ m/^(\w+)_(\w+)$/;

    ok(
        !$user->reset_token_verify($1),
        "reset_token_verify fails for token without checksum"
    );

    ok(
        !$user->reset_token_verify($2),
        "reset_token_verify fails for checksum without token"
    );

    # cleanup
    $self->clear_users;
};

1;
