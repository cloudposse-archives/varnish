changequote({{,}})dnl
define(VARNISH_BACKEND_HOST, {{localhost}})dnl
define(VARNISH_BACKEND_PORT, {{80}})dnl
define(VARNISH_BACKEND_FIRST_BYTE_TIMEOUT, {{600s}})dnl
vcl 4.0;
import std;

# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.

# 
# Default backend definition.  Set this to point to your content
# server.
# 
backend cluster {
  .host = "VARNISH_BACKEND_HOST";
  .port = "VARNISH_BACKEND_PORT";
  .first_byte_timeout = VARNISH_BACKEND_FIRST_BYTE_TIMEOUT;
  #.probe = { 
  #  .url = "/robots.txt"; 
  #  .timeout = 25000ms; 
  #  .interval = 5s; 
  #  .window = 4; 
  #  .threshold = 3; 
  #  .request =
  #          "GET /robots.txt HTTP/1.1"
  #          "Host: mocktheweb.com"
  #          "Connection: close";
  #}

}

# 
# Below is a commented-out copy of the default VCL logic.  If you
# redefine any of these subroutines, the built-in logic will be
# appended to your code.
sub vcl_recv {

  set req.backend_hint = cluster;

  if (req.restarts == 0) {
    if (req.http.x-forwarded-for) {
        set req.http.X-Forwarded-For =
      req.http.X-Forwarded-For + ", " + client.ip;
    } else {
        set req.http.X-Forwarded-For = client.ip;
    }
  }

  if(req.url ~ "^/wp-.*\.php" || req.url ~ "^/xmlrpc\.php$") {
    if(!req.http.User-Agent || req.http.User-Agent ~ "^$") {
      return (synth(403, "Invalid request"));
    }
  }

  if (req.method != "GET" &&
    req.method != "HEAD" &&
    req.method != "PUT" &&
    req.method != "POST" &&
    req.method != "TRACE" &&
    req.method != "OPTIONS" &&
    req.method != "DELETE") {
      /* Non-RFC2616 or CONNECT which is weird. */
      return (pipe);
  }
  if (req.method != "GET" && req.method != "HEAD") {
      /* We only deal with GET and HEAD by default */
      return (pass);
  }
  if (req.http.Authorization || req.http.Cookie) {
      /* Not cacheable by default */
      return (pass);
  }
  return (hash);
}

sub vcl_pipe {
  # Note that only the first request to the backend will have
  # X-Forwarded-For set.  If you use X-Forwarded-For and want to
  # have it set for all requests, make sure to have:
  # set bereq.http.connection = "close";
  # here.  It is not set by default as it might break some broken web
  # applications, like IIS with NTLM authentication.
  return (pipe);
}

sub vcl_pass {
  return (fetch);
}

sub vcl_hash {
  hash_data(req.url);
  if (req.http.host) {
      hash_data(req.http.host);
  } else {
      hash_data(server.ip);
  }
  return (lookup);
}

sub vcl_hit {
  return (deliver);
}

sub vcl_miss {
  return (fetch);
}

sub vcl_backend_response {
  if (beresp.ttl <= 0s ||
      beresp.http.Set-Cookie ||
      beresp.http.Surrogate-control ~ "no-store" ||
      (!beresp.http.Surrogate-Control &&
        beresp.http.Cache-Control ~ "no-cache|no-store|private") ||
      beresp.http.Vary == "*") {
        /*
        * Mark as "Hit-For-Pass" for the next 2 minutes
        */
        set beresp.ttl = 120s;
        set beresp.uncacheable = true;
  }
  return (deliver);
}

sub vcl_deliver {
  return (deliver);
}

sub vcl_backend_error {
  set beresp.http.Content-Type = "text/html; charset=utf-8";
  set beresp.http.Retry-After = "5";
  synthetic( {"
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>"} + beresp.status + " " + beresp.reason + {"</title>
  </head>
  <body>
    <h1>Error "} + beresp.status + " " + beresp.reason + {"</h1>
    <p>"} + beresp.reason + {"</p>
    <h3>Guru Meditation:</h3>
    <p>XID: "} + bereq.xid + {"</p>
    <hr>
    <p>Varnish cache server</p>
  </body>
</html>
    "});
  return (deliver);
}

sub vcl_init {
	return (ok);
}

sub vcl_fini {
	return (ok);
}
