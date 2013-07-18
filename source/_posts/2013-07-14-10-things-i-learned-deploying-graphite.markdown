---
layout: post
title: "10 Things I Learned Deploying Graphite"
date: 2013-07-14 17:04
comments: true
published: false
categories: graphite
---

* list element with functor item
{:toc}

Graphite and I have a long, sordid history.  You might even say "we go way back."  It all started when reading [the amazing blog post introducing StatsD by Etsy's engineering team](http://codeascraft.com/2011/02/15/measure-anything-measure-everything/).  If you haven't read it yet, I recommend it as it is a nice illustration of why you would want to install Graphite.  If you've read it already, you probably have been meaning to get Graphite going but haven't gotten around to it.

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

I think the main reason is that *django is a pain in the ass to deploy*. After noodling around with this for awhile, I figured out a pretty good way to deploy Graphite, and have made [a puppet module](https://github.com/kevin1024/graphite-puppet) for installing Graphite on a RHEL6 or Centos6 server.

The reason this works so well is that the EPEL repository (if you use Centos or RHEL you pretty much *have* to install EPEL) has, awesomely, packaged Graphite.  It's actually in 3 packages: `python-whisper`, `python-carbon`, and `graphite-web`.  The packages make a few assumptions, and after a bit of trial-and-error I was able to figure out what they were expecting.

 * Graphite and Carbon get installed in the system site-packages directory (/usr/lib/python2.6/site-packages/)
 * Graphite and Carbon expect their config files to end up in /etc/
 * You have to run `manage.py syncdb` after configuring the database in /etc/.  This database is just used for a few things on the front-end, not actual graph data, so you don't have to worry too much about using a real database.  I just used sqlite.
 * Apache will be configured to serve Graphite on port 80
 * You also need memcached running for some reason

You will probably also want to add some HTTP basic auth so creepers don't start creeping your graphs.  The puppet module will do that for you.


# 2. Graphite is more powerful than Munin

In the beginning, there was [RRDtool](http://oss.oetiker.ch/rrdtool/).  Chances are, you have seen and/or are currently staring at an RRDTool graph right now. 

{% img center /images/graphite/rrdtool.png Look familiar? %} 

For years, I've been using a project called [Munin](http://munin-monitoring.org/).  Munin is by far one of my favorite tools.  It is beautiful in its simplicity.  Each of your servers that you are monitoring runs a process called `munin-node`, and on your main graph server, you run a cron job that connects to all these servers and requests data about them periodically.  Then it writes this info out into an RRDTool database and generates a graph, as well as an HTML file pointing to all the graphs it has generated.

The `munin-node` daemon that runs on all your servers is incredibly lightweight, the network protocol is easy to debug, and writing plugins is a joy.  However, the graphs that are generated are just static images.

Graphite lets you manipulate your graphs in ways I never dreamed of when I  was using Munin.  You can run functions on your graphs to change the time scale, summarize the data, and mash together several graphs into a frankengraph *at will*.


# 3. There must be 50 ways to feed your Graphite

Once you manage to get Graphite running, there are a lot of great ways to get more data into it.  Feeding more and more of data into Graphite became a bit of an obsession for me.

## statsd
StatsD is the big daddy that started it all, and it works great.  It's written in nodejs, so you'll need that running on your server.  The key thing that StatsD is doing is listening to UDP packets (see the "Why UDP" section in the [Etsy blog post](http://codeascraft.com/2011/02/15/measure-anything-measure-everything/) for more on this) and batching them up before sending the statistics into Graphite.  I use it to send all my application-level statistics.  

Also, for some reason there are a zillion client libraries for StatsD. For Python, I like [this one](https://github.com/jsocol/pystatsd) (`pip install statsd`)

## collectd
Collectd is a daemon that runs on each of your servers and reports back info to Graphite.  It comes with a bunch of plugins and [there are a zillion more for specialized servers](http://collectd.org/wiki/index.php/Table_of_Plugins) that help you track more statistics.  Collectd is in EPEL, but it's a pretty old version.  Also, Collectd doesn't talk directly to Graphite.  The best way I found to set it up is with bucky

## bucky
Bucky is a Python daemon that listens for both StatsD *and* collectd packets, and sends them to Graphite.  So it's a replacement for StatsD but it also knows how to use Collectd metrics.  It is pretty great and easy to deploy.  It's also on the EPEL repository, so it's only a `yum install` away on Centos/RHEL.

## logster
Etsy also has this [logster](https://github.com/etsy/logster) project which is a Python script that can tail your log files and generate metrics to send back to Graphite.  I haven't actually tried it but it looks interesting.  They don't seem to have many [parsers](https://github.com/etsy/logster/tree/master/logster/parsers) though so I think you'll have to implement some of your own.  [Logstash](http://logstash.net/) can also send to Graphite.

There are [many more](https://graphite.readthedocs.org/en/latest/tools.html) ways to feed Graphite in the docs.

# 4. Make sure that your StatsD flush interval is at least as long as your Graphite interval

This is probably the most important lesson I learned.

What the heck is a StatsD flush interval?  Remember how I said that StatsD batches up sending statistics to Graphite?  Well, you can configure how often StatsD sends those batches.  By default the flush interval is 10 seconds.  So every 10 seconds, StatsD is sends a batch of metrics to Graphite.

What happens if you start sending stats faster than Graphite's highest resolution?  Graphite will start dropping metrics.

Let's say you're tracking clicks on a button that says "Kevin is Awesome".  This is a very tempting button, so people click it about 5 times a second.

StatsD starts batching things: 10 seconds of people mashing the button means that each batch will have 50 clicks in it.

However, let's say that Graphite's interval is set to a minute.  That means that during that minute, we will have sent 6 batches of 50 clicks for a total of 300 clicks.  However, Graphite will only record one of those batches, so it will only record 50 clicks instead of 100.

To make this concept a little easier to understand, here is a little
Processing sketch I whipped that simulates the process.  Events are
generated at `Event Generation Rate`.  Those show up in the bottom box.
They are also sent into StatsD as they happen.  Next, events are flushed
from StatsD into the Graphite Buffer at `StatsD Flush Rate`.  Finally,
events are written from the Graphite buffer to disk at the `Graphite
Storage Interval`.  Feel free to play around with the number to see how
they affect the count.  If your `StatsD Flush Rate` is smaller than the `Graphite Storage Interval`, you can see how stats start to get lost.  Let it run for awhile and see how the number of events that make it into Graphite (top box) is much lower than the amount that actually happened (bottom box)

{% include widgets/graphite.html %}



# 5. Turning off legacy namespacing

Once you start exploring the data sent into Graphite, you'll probably notice that your counter values are stored twice.  Depending on your version of graphite and whether you have turned off something called `legacyNamespace`, they will either be in a folder called "stats_counts" as well as in the "stats" folder, or they will be the "stats/counters" folder.

I think it makes more sense to have all the statsd metrics contained in the "statsd" folder.  In order to do this, you have to set the `legacyNamespace` configuration option to false (it defaults to true).

For the rest of this article, I'll assume that you have turned off legacy namespacing and refer to the counter values with their non-legacy names.

But why are there two versions of the same counter stats, each with different values?  That brings us to the next lesson I learned:

# 6. The difference between yourstat.count and yourstat.rate

In StatsD, counters keep track of events that happen, as opposed to gauges, which keep track of a value that fluctuates.  There are really two interesting things about counts that we might want to graph.  

  * How many times did this thing happen?
  * At what rate is this thing happening?

Yourstat.count keeps the total number of times that this event happened,
and Yourstat.rate keeps the rate that this thing happens *per second*.

Since Yourstat.count is actually keeping track of the number of times
that a thing happened, it can also be thought of as a rate, but instead
of happening *per second*, it's happening *per (your graphite storage
interval*. This is because the number of times something happens is
flushed to disk every time the Graphite storage interval happens.

Ah, but how do you configure the storage interval?  Glad you asked!

# 7. Setting up retention

Graphite lets you be *insanely* specific about how long you want data
kept around.  You can decide to keep one metric at per-second resolution
for a year, and another metric at per-day resolution for a month.  You
can even keep a metric at high resolution for a few days, and then
reduce the resolution as it ages.  Lower resolutions require less space
on disk.

Retention is configured in a file called `storage-schemas.conf`.
You can read more about it here in [the official
documentation](http://graphite.readthedocs.org/en/latest/config-carbon.html#storage-schemas-conf) but here is an example:

```
[nginx_requests]
pattern = nginx\.requests\.count$
retentions = 1s:7d,1m:30d,15m:5y
```

This rule is named nginx_requests and matches all stats with the pattern
`nginx\.requests\.count$`.  It will keep 1 second resolution for 7 days,
1 minute resolution for 30 days, after that, and 15 minute resolution
for 5 years after that.

It's also interesting that the data files that store this information
have a fixed size after creation.  This is good since they won't explode
and fill up your disk while you're on vacation.  However, that means
that if you ever want to change the retention of your metrics after
you've started collecting them, you wil need to resize the databases on
disk manually.  There is a command called `whisper-resize.py` that can
do this.

# 8. Aggregating data: What??

Here's something potentially confusing that falls out of letting you
define your retention rates with such complicated schemes:  You have to
drop your resolution when you transition from higher resolution to lower
resolution.  This means throwing away data.  This process is called
*aggregation*.

Normally, this works fine and you don't even care about it.   However,
there are a couple subtle situations that can trip you up.

If you have a rate metric, which keeps track of, for example, the number
of times somebody signed up on your website per second, and you want to
convert it to the number of times *per minute*, you can just take the
rate from each of the 60 seconds in a minute and average it.  This is
the default method.  However, what happens if you have a bunch of `null`
values in your graph for that minute?  Let's say your network was
malfunctioning for 59 seconds, so you didn't record any event, and in
the last second, you record 100 signups.  Is it fair to say that you
were getting an average of 100 signups the whole time?  Probably not.
But if you only lost 1 second of data, you might be a lot more
comfortable with that average.  By default, you need at least 50% of the
data to be non-null to store this average value.  This is configurable
by changing a setting called `xFilesFactor`, which is pretty much my favorite variable name ever.  Why?  No reason.

{% img left /images/graphite/xfiles.jpg %}

The other thing that can trip you up is aggregating *counts*.  What
happens when we average 60 seconds of counts?  Well, we lose around
1/60th of the events that happened.  So for count statistics, we
actually want to *sum* the number of times that something happened.  You
can set this with the `aggregationMethod` in `storage-aggregation.conf`

# 9. hitcount() vs summarize()

I had a bit of trouble figuring out the difference between the
`hitcount()` function and the `summarize()` function in Graphite, so
here it is:

* `hitcount()` is used for *rate* variables to turn them into *counts*,
  as well as changing the resolution of a graph.
* `summarize()` just changes the resolution of the graph.

# 10. Holy crap there are a lot of Graphite Dashboards

Finally, if you would like a better-looking Graphite dashboard, there
are a lot of alternative dashboards out there.  [Graphite has a great
API](http://graphite.readthedocs.org/en/1.0/url-api.html) and you can
just add &format=json to the end of any graph image and get the JSON
data out of it.  [Here are just a few of them in a nice
summary](http://dashboarddude.com/blog/2013/01/23/dashboards-for-graphite/)

