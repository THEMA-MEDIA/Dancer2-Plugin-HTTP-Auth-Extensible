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
                some_realm => {
#                   scheme => "Basic",
                    provider => "Config",
                    users => [
                      { user => "dave",
                        pass => "beer",
                        name => "David Precious",
                      },
                    ]
                }
            }
        }
    };
    
    use Dancer2::Plugin::HTTP::Auth::Extensible;
    no warnings 'uninitialized';

    get '/' => sub { "Access does not need any authorization" };
    
    get '/auth' => http_requires_authentication sub {
        "Access granted for default realm"
    };

} # BEGIN

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
        $res->code,
        200,
        'Status 200: root resource accessible without login'
    );
    is (
        $res->content,
        'Access does not need any authorization',
        'Delivering: root resource accessible without login'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/auth');
    my $res = $cb->( $req );
    is (
        $res->code,
        401,
        'Status 401: without HTTP-field Autorization'
    );
    is (
        $res->headers->header('WWW-Authenticate'),
        'Basic realm="some_realm"',
        'HTTP-field: WWW-Authentication without HTTP-field Autorization'
    );
    isnt ( # negative testing, we should not get this content
        $res->content,
        'Access granted for default realm',
        'Delivering: without HTTP-field Autorization'
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
        'Status 401: without proper credentials'
    );
    is (
        $res->headers->header('WWW-Authenticate'),
        'Basic realm="some_realm"',
        'HTTP-field: WWW-Authentication without proper credentials'
    );
    isnt ( # negative testing, we should not get this content
        $res->content,
        'Access granted for default realm',
        'Delivering: without proper credentials'
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
        'Status 200: with the right credentials'
    );
    isnt ( # negative testing, we should not be required to authenticate
        $res->headers->header('WWW-Authenticate'),
        'Basic realm="some_realm"',
        'HTTP-field: WWW-Authentication with the right credentials'
    );
    is (
        $res->content,
        'Access granted for default realm',
        'Delivering: with the right credentials'
    );
};

done_testing();
