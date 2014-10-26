package t::lib::TestApp;

use Dancer2;



set session => 'simple';
set plugins => { 'HTTP::Auth::Extensible' => { provider => 'Example' } };

use Dancer2::Plugin::HTTP::Auth::Extensible;
no warnings 'uninitialized';


get '/' => sub {
    "Index always accessible";
};

get '/loggedin' => http_require_authentication sub  {
    "You are logged in";
};

get '/name' => http_require_authentication sub {
    return "Hello, " . http_authenticated_user->{name};
};

get '/roles' => http_require_authentication sub {
    return join ',', sort @{ user_roles() };
};

get '/roles/:user' => http_require_authentication sub {
    my $user = param 'user';
    return join ',', sort @{ user_roles($user) };
};

get '/roles/:user/:realm' => http_require_authentication sub {
    my $user = param 'user';
    my $realm = param 'realm';
    return join ',', sort @{ user_roles($user, $realm) };
};

get '/realm' => http_require_authentication sub {
    return session->read('logged_in_user_realm');
};

get '/beer' => http_require_role BeerDrinker => sub {
    "You can have a beer";
};

get '/piss' => http_require_role BearGrylls => sub {
    "You can drink piss";
};

get '/piss/regex' => http_require_role qr/beer/i => sub {
    "You can drink piss now";
};

get '/anyrole' => http_require_any_role ['Foo','BeerDrinker'] => sub {
    "Matching one of multiple roles works";
};

get '/allroles' => http_require_all_roles ['BeerDrinker', 'Motorcyclist'] => sub {
    "Matching multiple required roles works";
};

get qr{/regex/(.+)} => http_require_authentication sub {
    return "Matched";
};


1;
