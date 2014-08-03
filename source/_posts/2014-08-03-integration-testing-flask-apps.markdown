---
layout: post
title: "Integration testing Flask apps"
date: 2014-08-03 10:40:14 -1000
comments: false
categories: [python, testing, pytest]
---
[Pytest fixtures](http://pytest.org/latest/fixture.html) are pretty amazing, and I end up writing quick and dirty fixtures all the time for my tests.  I just wrote a quickie pytest fixture for integration testing flask apps.  Here's how you use it:

```
import requests

def test_request_tasks(server):
    assert requests.get(server + '/tasks').status_code == 200
```

Pytest will fork and run your app in another process, and you can request urls using your http library of choice (hahaha, there is [only one correct choice](http://docs.python-requests.org/en/latest/)).

OK, I warned you that this is quick-and-dirty, so here it is:

```
@pytest.yield_fixture()
def server():
    PORT = 12345
    pid = os.fork()
    if pid == 0:
        app.run(port=PORT)
    else:
        while True:
            try:
                requests.get('http://localhost:{0}'.format(PORT))
                break
            except requests.ConnectionError:
                continue
    yield 'http://localhost:{0}'.format(PORT)
    os.kill(pid, signal.SIGTERM)
```

A couple things to note:

The port is just hardcoded to 12345, if you got motivated you could have the forked process bind to port 0, which will return a handy random free port, then use a pipe to communicate back to the main process and let it know the port number.  That's WORK though.

Also I'm using  SIGTERM to kill the process, which can actually be ignored by the process if it is feeling frisky.  So you can swap that out for SIGKILL if you run into problems.  Here's a little more on [SIGKILL vs SIGTERM](http://major.io/2010/03/18/sigterm-vs-sigkill/)

This method is adapted from [Matt O'Donnel's unittest method here](http://www.mavenrd.com/blog/integration-testing-in-flask-1/)

