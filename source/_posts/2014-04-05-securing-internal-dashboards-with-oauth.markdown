---
layout: post
title: "Securing Internal Dashboards with Oauth"
date: 2014-04-04 17:05
comments: true
categories: devops oauth2
---

At [Real Geeks](http://www.github.com/realgeeks/) we have lots of internal dashboards:  [Graphite](/blog/2013/07/18/10-things-i-learned-deploying-graphite/), [Logstash](http://logstash.net/), [Munin](http://munin-monitoring.org/), and some other internal tools with status pages.  Obviously, I didn't want these open to the public.  I was using one of two different ways of restricting access, and both of them didn't work very well.

# Failed Technique #1: Require a password
The first technique I was using was to set up HTTP Basic Auth passwords for our employees, using a hashed password file sitting on the server.  This was relatively simple to set up, but also a huge pain.  Every time someone forgot their password, I would have to update the server configuration (by SSHing into the server, later by changing the Puppet configuration).  When we add or remove employees it's a manual process.  Unless you have the server running on HTTPS, their passwords are sent over plain text.

# Failed Technique #2: Restrict access with a firewall to IP addresses
I also tried by restricting access to these dashboards by requiring a certain IP address in the firewall.  This solves some of the problems with technique #1 but also introduces new ones.  Employees working from home or on their phones couldn't access the dashboards.  This could probably be solved by having an office VPN but setting that up just for dashboard access is a lot of work.  Also, sometimes our office IP address would change, which again requires a bunch of configuration changes.  Our firewall rules filled up with a bunch of random residential IP addresses so employees could get online from home.

# The solution: Oauth
After feeling the pain for awhile, I knew there had to be a better way.  All of our technical employees have accounts on the [Real Geeks Github Organization](http://www.github.com/realgeeks/).  Github also has an oauth2 provider.  If you're not familiar with Oauth2, it's the technique used by those "Log in with Google/Facebook/etc" buttons you see on a lot of websites.  It allows a website to delegate the authentication and account management to another service, in my case, Github.

The next challenge would be to come up with a way to add Oauth2 support to all of my projects.  I didn't want to have to run forks of Graphite, Logstash, and Munin.  I wanted my solution to be easy to deploy and be lightweight.  I also wanted it to be secure.

After a bit of thinking and searching around, I found [google_auth_proxy](https://github.com/bitly/google_auth_proxy).  It's an open-source project written in Go that *almost* solves my problem.  It acts as a guardian that sits in front of your application, requiring the user to authenticate with the Google Oauth2 server before allowing them to continue. Once they have authenticated with Google, it stores a session in an HMAC-signed cookie and allows the requests to proxy through to the backend.

The only problem is, google_oauth_proxy only works with Google oauth servers.  So, I forked it and made a new project [oauth_proxy](https://github.com/kevin1024/oauth_proxy).  oauth_proxy is intended to work with any oauth2 provider, not just google.  Since it's written in go, it compiles to a static binary that can be easily deployed.

Here is an example invocation of the oauth_proxy server:

```
/oauth_proxy --client-id="f4dddfabbebe5ba" --client-secret="ecb0561717bbf29956f" --upstream="http://localhost:8080/" --cookie-secret="secretsecret" --login-url="https://github.com/login/oauth/authorize" --redirect-url="http://localhost:4180/oauth2/callback/" --redemption-url="https://github.com/login/oauth/access_token --oauth-scope=user, --user-verification-command=/bin/verify_github_team.py"
```

The client ID and client secret come from the Github oauth control panel.  Upstream points to the upstream server that I'm protecting, it should only be listening on localhost.  The cookie secret is used to sign the session cookie.  The login URL is the token generation endpoint of the oauth provider, and the redirect URL should point to the redirect url on oauth_proxy (it's always /oauth2/callback, but the hostname changes depending on your server).  Finally, the redemption URL is your oauth2 provider's token redemption URL where the code from the redirect URL gets posted and exchanged for an access token.  

# Getting fancy with auth tokens

Sometimes, getting an auth token from the oauth2 provider is not sufficient to gain access to your backend. For example, maybe you want to make sure that the person authenticating belongs to a specific Github organization. For this, you can create a user verification command. You can see an example script in contrib that verifies that a given access token belongs to a user in a specific organization.  In order for this script to work, I have to request the "user" scope from github.

# Notes

This was my first time using Go, but I found it fairly simple to figure out what was going on.  The `go fmt` command is pretty amazing, especially for a Go beginner with no idea about Go style.  I would like to eventually improve the login screen since it's just a small button in the corner that says "login", pretty boring.  There are probably a lot of improvements to be made (better support for other oauth providers?) so please send a pull request!
