package t::lib::TestSub;

use Test::More;

sub test_the_app_sub {
    my $sub = sub {

        my $cb = shift;

        # First, without being logged in, check we can access the index page, but not
        # stuff we need to be logged in for:

        my $req = HTTP::Request->new( GET => '/');
        is (
            $cb->($req)->content,
            'Index always accessible',
            'Index accessible while not logged in'
        );

        {
            my $req = HTTP::Request->new( GET => '/loggedin');
            my $res = $cb->( $req );

            is( $res->code, 302, '[GET /loggedin] Correct code' );

            is(
                $res->headers->header('Location'),
                'http://localhost/login?return_url=%2Floggedin',
                '/loggedin redirected to login page when not logged in'
            );
        }

        {
            my $req = HTTP::Request->new( GET => '/beer');
            my $res = $cb->( $req );

            is( $res->code, 302, '[GET /beer] Correct code' );

            is(
                $res->headers->header('Location'),
                'http://localhost/login?return_url=%2Fbeer',
                '/beer redirected to login page when not logged in'
            );
        }

        {
            my $req = HTTP::Request->new( GET => '/regex/a');
            my $res = $cb->( $req );

            is( $res->code, 302, '[GET /regex/a] Correct code' );

            is(
                $res->headers->header('Location'),
                'http://localhost/login?return_url=%2Fregex%2Fa',
                '/regex/a redirected to login page when not logged in'
            );
        }

        # OK, now check we can't log in with fake details

        {
            my $req = HTTP::Request->new( POST => '/login');
            $req->uri->query_form( username => 'foo', password => 'bar' );
            my $res = $cb->( $req );

            is( $res->code, 401, 'Login with fake details fails');
        }

        my $cookie_jar;

        # ... and that we can log in with real details

        {
            my $req = HTTP::Request->new( POST => '/login');
            $req->uri->query_form( username => 'dave', password => 'beer' );
            my $res = $cb->( $req );

            is( $res->code, 302, 'Login with real details succeeds');

            # Get cookie with session id
            my $cookie = $res->header('Set-Cookie');
            $cookie =~ s/^(.*?);.*$/$1/s;
            ok ($cookie, "Got the cookie: $cookie");
            $cookie_jar = $cookie;
        }

        # Now we're logged in, check we can access stuff we should...

        {
            my $req = HTTP::Request->new( GET => '/loggedin');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is ($res->code, 200, 'Can access /loggedin now we are logged in');

            is ($res->content, 'You are logged in',
                'Correct page content while logged in, too');
        }

        {
            my $req = HTTP::Request->new( GET => '/name');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is ($res->content, 'Hello, David Precious',
                'Logged in user details via logged_in_user work');

        }

        {
            my $req = HTTP::Request->new( GET => '/roles');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is ($res->content, 'BeerDrinker,Motorcyclist', 'Correct roles for logged in user');
        }

        {
            my $req = HTTP::Request->new( GET => '/roles/bob');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is ($res->content, 'CiderDrinker', 'Correct roles for other user in current realm');
        }

        # Check we can request something which requires a role we have....
        {
            my $req = HTTP::Request->new( GET => '/beer');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is ($res->code, 200, 'We can request a route (/beer) requiring a role we have...');
        }

        # Check we can request a route that requires any of a list of roles, one of
        # which we have:
        {
            my $req = HTTP::Request->new( GET => '/anyrole');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is ($res->code, 200,
                "We can request a multi-role route requiring with any one role");
        }

        {
            my $req = HTTP::Request->new( GET => '/allroles');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is ($res->code, 200,
                "We can request a multi-role route with all roles required");
        }

        # And also a route declared as a regex (this should be no different, but
        # melmothX was seeing issues with routes not requiring login when they should...

        {
            my $req = HTTP::Request->new( GET => '/regex/a');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is ($res->code, 200, "We can request a regex route when logged in");
        }

        {
            my $req = HTTP::Request->new( GET => '/piss/regex');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is ($res->code, 200, "We can request a route requiring a regex role we have");
        }

        # ... but can't request something requiring a role we don't have

        {
            my $req = HTTP::Request->new( GET => '/piss');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is ($res->code, 302,
                "Redirect on a route requiring a role we don't have");

            is ($res->headers->header('Location'),
                'http://localhost/login/denied?return_url=%2Fpiss',
                "We cannot request a route requiring a role we don't have");
        }

        # Check the realm we authenticated against is what we expect

        {
            my $req = HTTP::Request->new( GET => '/realm');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is($res->code, 200, 'Status code on /realm route.');
            is($res->content, 'config1', 'Authenticated against expected realm');
        }

        # Now, log out

        {
            my $req = HTTP::Request->new( POST => '/logout');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is($res->code, 200, 'Logging out returns 200');
        }

        # Check we can't access protected pages now we logged out:

        {
            my $req = HTTP::Request->new( GET => '/loggedin');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is($res->code, 302, 'Status code on accessing /loggedin after logout');

            is($res->headers->header('Location'),
               'http://localhost/login?return_url=%2Floggedin',
               '/loggedin redirected to login page after logging out');
        }

        {
            my $req = HTTP::Request->new( GET => '/beer');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is($res->code, 302, 'Status code on accessing /beer after logout');

            is($res->headers->header('Location'),
               'http://localhost/login?return_url=%2Fbeer',
               '/beer redirected to login page after logging out');
        }

        # OK, log back in, this time as a user from the second realm

        {
            my $req = HTTP::Request->new( POST => '/login');
            $req->uri->query_form( username => 'burt', password => 'bacharach' );
            my $res = $cb->( $req );

            is($res->code, 302, 'Login as user from second realm succeeds');

            # Get cookie with session id
            my $cookie = $res->header('Set-Cookie');
            $cookie =~ s/^(.*?);.*$/$1/s;
            ok ($cookie, "Got the cookie: $cookie");
            $cookie_jar = $cookie;
        }


        # And that now we're logged in again, we can access protected pages

        {
            my $req = HTTP::Request->new( GET => '/loggedin');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is($res->code, 200, 'Can access /loggedin now we are logged in again');
        }

        # And that the realm we authenticated against is what we expect
        {
            my $req = HTTP::Request->new( GET => '/realm');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is($res->code, 200, 'Status code on /realm route.');
            is($res->content, 'config2', 'Authenticated against expected realm');
        }

        {
            my $req = HTTP::Request->new( GET => '/roles/bob/config1');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is($res->code, 200, 'Status code on /roles/bob/config1 route.');
            is($res->content, 'CiderDrinker', 'Correct roles for other user in current realm');
        }

        # Now, log out again
        {
            my $req = HTTP::Request->new( POST => '/logout');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is($res->code, 200, 'Logged out again');
        }

        # Now check we can log in as a user whose password is stored hashed:
        {
            my $req = HTTP::Request->new( POST => '/login');
            $req->uri->query_form( username => 'hashedpassword', password => 'password' );
            my $res = $cb->( $req );

            is($res->code, 302, 'Login as user with hashed password succeeds');

            # Get cookie with session id
            my $cookie = $res->header('Set-Cookie');
            $cookie =~ s/^(.*?);.*$/$1/s;
            ok ($cookie, "Got the cookie: $cookie");
            $cookie_jar = $cookie;
        }

        # And that now we're logged in again, we can access protected pages
        {
            my $req = HTTP::Request->new( GET => '/loggedin');
            $req->header('Cookie' => $cookie_jar);
            my $res = $cb->( $req );

            is($res->code, 200, 'Can access /loggedin now we are logged in again');
        }

        # Check that the redirect URL can be set when logging in
        {
            my $req = HTTP::Request->new( POST => '/login');
            $req->uri->query_form(
                username => 'dave',
                password => 'beer',
                return_url => '/foobar',
            );
            my $res = $cb->( $req );

            is($res->code, 302, 'Status code for login with return_url');

            is($res->headers->header('Location'),
               'http://localhost/foobar',
               'Redirect after login to given return_url works');
        }
    }
};

1;
