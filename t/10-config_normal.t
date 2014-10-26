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
                    users => [
                      { user => "dave",
                        pass => "beer",
                        name => "David Precious",
                        roles => [ 'BeerDrinker', 'Motorcyclist' ],
                      },
                      { user => "bob",
                        pass => "cider",
                        name => "Bob Smith",
                        roles => [ 'Ciderdrinker' ],
                      },
                    ]
                },
                realm_two => {
                    scheme => "Basic",
                    provider => "Config",
                    users => [
                     { user => "burt",
                       pass => "bacharach",
                     },
                     { user => "hashedpassword",
                       pass => "{SSHA}+2u1HpOU7ak6iBR6JlpICpAUvSpA/zBM",
                     },
                   ]
                }
            }
        }
    };
    
    use Dancer2::Plugin::HTTP::Auth::Extensible;
    no warnings 'uninitialized';
    
    get '/realm_one' => http_requires_authentication 'realm_one' => sub {
        "Welcome to realm ONE"
    };
    
    get '/realm_two' => http_requires_authentication 'realm_two' => sub {
        "Welcome to realm TWO"
    };
    
    get '/realm_bad' => http_requires_authentication 'realm_bad' => sub {
        "Welcome to realm BAD" # we are not suposed to get here
    };
    
    get '/realm'     => http_requires_authentication                sub {
        "Welcome to the default realm"
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
    my $req = HTTP::Request->new( GET => '/realm');
    my $res = $cb->( $req );
    is (
        $res->code,
        500,
        '500: "Internal server Error" when there is no realm to choose'
    );
    is (
        $res->content,
        'Internal Server Error: "multiple realms without default"',
        'Nice error message when not abble to choose default realm'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/realm_one');
    my $res = $cb->( $req );
    is (
        $res->code,
        401,
        '401: "Unauthorized" is the correct status code'
    );
    is (
        $res->headers->header('WWW-Authenticate'),
        'Basic realm="realm_one"',
        'Returns the right "WWW-Authentication" response header for realm ONE'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/realm_two');
    my $res = $cb->( $req );
    is (
        $res->code,
        401,
        '401: "Unauthorized" is the correct status code'
    );
    is (
        $res->headers->header('WWW-Authenticate'),
        'Basic realm="realm_two"',
        'Returns the right "WWW-Authentication" response header for realm TWO'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/realm_bad');
    my $res = $cb->( $req );
    is (
        $res->code,
        500,
        '500: "Internal server Error" when there is a bad realm to choose'
    );
    is (
        $res->content,
        'Internal Server Error: "required realm does not exist: \'bad\'"',
        'Nice error message when choosing a bad realm name'
    );
};

done_testing();
