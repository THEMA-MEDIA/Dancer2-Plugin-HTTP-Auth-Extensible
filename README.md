Dancer2::Plugin::HTTP::Auth
===========================

A Plugin for doing simple Authentication for REST applications with Dancer2

Synopsis
========

    use Dancer2;
    use Dancer2::Plugin::HTTP::Auth;
    
    get '/users' => require_authentication => sub { ... };
    
    get '/beer' => require_role 'BeerDrinker' => sub { ... };

    get '/drink' => require_any_role [qw(BeerDrinker VodaDrinker)] => sub {
        ...
    };


Description
===========

HTTP is a Stateless protocol
----------------------------

Most of the Dancer2 Plugins that deal with Authentication & Authorization are session based.
This plugin will be totaly 'stateless' and adhere to the HTTP standard that expects a
HTTP Authorization: header in the request, which needs to provide valid credentials according to
[RFC 2616 §14.8: Authorization](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.8),
independent of what Method being called.

That means that with every request that needs authorisation, that the header needs to be provided.
The server DOES NOT retain state through any settings, there is no session management build for that.

This Module will provide 'Basic' and 'Digest' authentication schema's

401 (Unauthorized) instead of /login
------------------------------------

Since Dancer2 is a leightweight Web framework to rapidly build good web-sites and web-applications,
it also means that 'all' of the Auth plugins for Dancer2 basicly do the same thing when authorization
is needed... they all provide a redirect to a `/login` one way or the other.

HTTP::Auth simply returns a response with Status: 401 (Unauthorized). That response will also have a
response header 'WWW-Authenticate'. In old school www, that caused that simple authentication window to
pop-up that asked to enter your credentials for a specific realm. (still nothing wrong with that is it?)
For REST api user-agents, it means it has to resend the same request but now with credentials. Modules
like `LWP` do have mechanisms to automaticly resend those. 

Keywords / Methods
==================

* require_authentication
* require_role
* require_any_role
* require_all_roles
* authenticated_user
* user_has_role
* user_is_authenticated

Other things to work on are providers and authetication schema's.

Configuration
=============

this is how the `confg.yml` should look like:

    plugins:
        HTTP::Authorize:
            realms:
                example:
                    authenticate: Digest
                    provider: Example
                config:
                    authenticate: Basic
                    provider: Config
                    users:
                        - user: 'beerdrinker'
                          pass: 'password'
                          name: 'Beer drinker'
                          roles:
                            - BeerDrinker
                        - user: 'vodkadrinker'
                          pass: 'password'
                          name: 'Vodka drinker'
                          roles:
                            - VodkaDrinker

Does this look familiar ? This comes from Dancer2::Plugin::Auth::Extensible!
And I have no clue yet on how to implement all, but I am willing to stick to this setup.

Unlike the usual Dancer2::Plugin::Auth::Extensible, there will be no redirect pages, but the next HTTP status messages will be generated:

* 401: Unauthorized (including a WWW-Authenticate header)
* 403: Forbidden

Release Notes
=============

The first release will only check for authentication, not for authorization, that also means that there will be no roles to check
