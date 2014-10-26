use strict;
use warnings;

use Test::More;
use Plack::Test;

BEGIN {
    
    use Dancer2;
    
    set session => undef; # explicit
    set plugins => {
        'HTTP::Auth::Extensible' => {
            realms => {
                realm_one => {
                    scheme => "Basic",
                    provider => "Config",
                    users => (
                      { user => "dave",
                        pass => "beer",
                        name => "David Precious",
                      },
                    )
                }
            }
        }
    };
    
    use Dancer2::Plugin::HTTP::Auth::Extensible;
    no warnings 'uninitialized';

    get '/' => sub { "Index always accessible" };
    
    get '/auth' => http_requires_authentication sub {
        "Welcome to the default realm"
    };

}

my $app = Dancer2->runner->psgi_app;

{
    is (
        ref $app,
        'CODE',
        'Got app'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/');
    my $res = $cb->( $req );
    is (
        $res->content,
        'Index always accessible',
        'Index accessible while not logged in'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/auth');
    my $res = $cb->( $req );
    is (
        $res->code,
        401,
        '401: "Unauthorized" without HTTP Autorization header'
    );
    is (
        $res->headers->header('WWW-Authenticate'),
        'Basic realm="realm_one"',
        'Returns the right "WWW-Authentication" response header'
    );
};


test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/auth');
    $req->authorization_basic ( 'foo', 'bar');
    my $res = $cb->( $req );
    is (
        $res->code,
        401,
        '401: "Unauthorized" without proper credentials'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/auth');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    is (
        $res->code,
        200,
        '200: "OK" using proper credentials'
    );
    is (
        $res->content,
        'Welcome to the default realm',
        'Shows message for authenticated resource'
    );
};

done_testing();
