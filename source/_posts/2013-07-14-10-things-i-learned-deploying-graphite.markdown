---
layout: post
title: "10 Things I Learned Deploying Graphite"
date: 2013-07-14 17:04
comments: true
published: false
categories: graphite
---
Graphite and I have a long, sordid history.  You might even say "we go way back."  It all started when reading [the amazing blog post introducing StatsD by Etsy's engineering team](http://codeascraft.com/2011/02/15/measure-anything-measure-everything/).  If you haven't read it yet, I recommend it as it is a nice illustration of why you would want to install Graphite.  If you've read it already, you probably have been meaning to get it going but have never gotten around to it.

{% img center /images/graphite/powerplant.jpg Admit it, you wish you worked here %}

Basically, what Graphite does is makes you feel like the badass engineer working on some kind of huge industrial process that you wish you were!  Why should the nuclear engineers get the awesome dashboards:

Here is what Graphite looks like:

{% img /images/graphite/graphite.png Almost as cool %}

Having quick access to all these statistics helps you be more productive.  But there is quite a bit of work go get off the ground.  That brings me to item #1:

# 1. Deploying Graphite is a huge pain in the ass

Graphite is such a strange beast.  It was developed at Orbitz (maybe to track how many airlines still give out free peanuts?) and is open-sourced under the Apache license.  It is written in Python and is actually made up of 3 main parts:

1. Graphite-web: A Django project that provides a GUI for graphite.  This is what you see when you visit a Graphite install in your browser.  It also has an admin area that lets you set up users that are allowed to create and save graphs.  You can deploy this like any other Django app via wsgi.
2. Carbon: Carbon is a daemon that runs constantly in the background.  Its main job is to take in statistics from the network and write them to disk.  It also does something both complicated and fascinating called "aggregation" which I will explore later.  Carbon will also be replaced eventually by its successor, [Ceres](https://github.com/graphite-project/ceres)
3. Whisper: Whisper is a time-series database file format.  It doesn't actually run as a server or anything, it's just a standard format for storing time-series data.  These databases are a fixed size, and once the data gets old it falls off the other end.  Whisper is a replacment for RRDTool, which I will talk about later.

I have tried and failed a few times getting Graphite into a state where it could be deployed automatically, and I usually gave up going "wow this tool is hard to deploy, and Munin is good enough anyway" so I kept giving up.  

## Why is deploying Graphite a huge pain in the ass?

So glad you asked.  I think the main reason is that *django is a pain in the ass to deploy*. After noodling around with this for awhile, I figured out a pretty good way to deploy Graphite, and have made [a puppet module](https://github.com/kevin1024/graphite-puppet) for installing Graphite on a RHEL6 or Centos6 server.

The reason this works so well is that the EPEL repository (if you use Centos or RHEL you pretty much *have* to install EPEL) has, awesomely, packaged Graphite.  It's actually in 3 packages: `python-whisper`, `python-carbon`, and `graphite-web`.  The packages make a few assumptions, and after a bit of trial-and-error I was able to figure out what they were expecting.

 * Graphite and Carbon get installed in the system site-packages directory (/usr/lib/python2.6/site-packages/)
 * Graphite and Carbon expect their config files to end up in /etc/
 * You have to run `manage.py syncdb` after configuring the database in /etc/.  This database is just used for a few things on the front-end, not actual graph data, so you don't have to worry too much about using a real database.  I just used sqlite.
 * Apache will be configured to serve Graphite on port 80

You will probably also want to add some HTTP basic auth so creepers don't start creeping your graphs.  The puppet module will do that for you.


# 2. Graphite is more powerful than Munin

In the beginning, there was [RRDtool](http://oss.oetiker.ch/rrdtool/).  Chances are, you have seen and/or are currently staring at an RRDTool graph right now. 

{% img center /images/graphite/rrdtool.png Look familiar? %} 

For years, I've been using a project called [Munin](http://munin-monitoring.org/).  Munin is by far one of my favorite tools.  It is beautiful in its simplicity.  Each of your servers that you are monitoring runs a process called `munin-node`, and on your main graph server, you run a cron job that connects to all these servers and requests data about them periodically.  Then it writes this info out into an RRDTool database and generates a graph, as well as an HTML file pointing to all the graphs it has generated.

The `munin-node` daemon that runs on all your servers is incredibly lightweight, the network protocol is easy to debug, and writing plugins is a joy.  However, the graphs that are generated are just static images.

Graphite lets you manipulate your graphs in ways I never dreamed of when I  was using Munin.  You can run functions on your graphs to change the time scale, summarize the data, and mash together several graphs into a frankengraph *at will*.


# 2. Make sure that your StatsD flush interval is the same as your graphite interval
# 3. The difference between statsd_counts and statsd
# 4. Turning off legacy namespacing
# 5. Setting up retention
# 6. Aggregating data: WTF
# 7. hit count versus summarize
# 8. Holy crap there are a lot of StatsDs
# 9. Holy crap there are a lot of Graphite Dashboards
# 10. Graphite is amazing
