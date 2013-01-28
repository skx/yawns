backend web1 { .host = "212.110.179.73";
               .port = "8080";
               .probe = {
                   .url       = "/cache.txt";
                   .interval  = 15s;
                   .timeout   = 5s;
                   .window    = 5;
                   .threshold = 3;
             }}

backend web2 { .host = "212.110.179.74";
               .port = "8080";
               .probe = {
                   .url       = "/cache.txt";
                   .interval  = 15s;
                   .timeout   = 5s;
                   .window    = 5;
                   .threshold = 3;
             }}

backend web3 { .host = "212.110.179.75";
               .port = "8080";
               .probe = {
                   .url       = "/cache.txt";
                   .interval  = 15s;
                   .timeout   = 5s;
                   .window    = 5;
                   .threshold = 3;
             }}

backend web4 { .host = "212.110.179.70";
               .port = "8080";
               .probe = {
                   .url       = "/cache.txt";
                   .interval  = 15s;
                   .timeout   = 5s;
                   .window    = 5;
                   .threshold = 3;
             }}


director default_director round-robin {
  { .backend = web1; }
  { .backend = web2; }
  { .backend = web3; }
  { .backend = web4; }
}

acl admin {
    "127.0.0.1";
    "212.110.179.65"/28;
}


include "blacklist.vcl";


sub vcl_recv
{

    if (client.ip ~ blacklist ) {
           error 403 "You're blacklisted";
    }

    # the round-robin behaviour
    set req.backend = default_director;

    #
    # Pound will add this for HTTPS.
    #
    if (req.http.x-forwarded-for) {
         # nop
    } else {
        set req.http.X-Forwarded-For = client.ip;
    }

    # Allow the backend to serve up stale content if it is responding slowly.
    if (! req.backend.healthy) {
       set req.grace = 60m;
    } else {
       set req.grace = 15s;
    }

    # Ignore all "POST" requests - nothing cacheable there
    if (req.request == "POST") {
           return (pass);
    }

    if (req.http.Cookie == "") {
      remove req.http.Cookie;
    }

    if ( req.url ~ "(articles.rdf|atom.xml|headlines.rdf)$" ) {
         unset req.http.Cookie;
        return( lookup );
    }

    # Always cache the following file types for all users.
    if (req.url ~ "(?i)\.(png|gif|jpeg|jpg|txt|ico|swf|css|js|html|htm)(\?[a-z0-9]+)?$") {
         unset req.http.Cookie;
    }

    # Handle compression correctly. Different browsers send different
    # "Accept-Encoding" headers, even though they mostly all support the same
    # compression mechanisms. By consolidating these compression headers into
    # a consistent format, we can reduce the size of the cache and get more hits.
    # @see: http:// varnish.projects.linpro.no/wiki/FAQ/Compression
    if (req.http.Accept-Encoding) {
      if (req.http.Accept-Encoding ~ "gzip") {
        # If the browser supports it, we'll use gzip.
        set req.http.Accept-Encoding = "gzip";
      }
      else if (req.http.Accept-Encoding ~ "deflate") {
        # Next, try deflate if it is supported.
        set req.http.Accept-Encoding = "deflate";
      }
      else {
        # Unknown algorithm. Remove it and send unencoded.
        unset req.http.Accept-Encoding;
      }
    }

    if (req.request == "PURGE") {
        if (!client.ip ~ admin) {
            error 405 "Not allowed.";
    return (lookup);
        }
    }
}


sub vcl_fetch
{
    # allow cached content to live on, even when stale.
    set beresp.grace = 80m;

    # Use anonymous, cached pages if all backends are down.
    if (!req.backend.healthy) {
         unset req.http.Cookie;
    }

    if (req.url ~ "(?i)\.(png|gif|jpeg|jpg|txt|ico|swf|css|js|html|htm)(\?[a-z0-9]+)?$") {
       unset beresp.http.set-cookie;
       unset beresp.http.expires;
       set beresp.http.cache-control = "max-age = 604800";
       set beresp.ttl = 72000s;
    }

    # if the TTL is less then two minutes set it to be 1m for stuff
    # that is non-cacheable and 5m otherwise
    if (beresp.ttl < 120s) {
       if (beresp.http.Cache-Control ~ "(private|no-cache|no-store)") {
         set beresp.ttl = 60s;
       }
       else {
         set beresp.ttl = 300s;
       }
    }

    # if the back-end gives an error don't retry that one again for 10s.
    if (beresp.status == 500) {
      set beresp.saintmode = 10s;
      return(restart);
    }
     if (beresp.ttl <= 0s ||
         beresp.http.Set-Cookie ||
         beresp.http.Vary == "*") {
		/*
		 * Mark as "Hit-For-Pass" for the next minute.
		 */
		set beresp.ttl = 60 s;
		return (hit_for_pass);
     }
     return (deliver);
}

sub vcl_hit {
    if (req.request == "PURGE") {
        purge;
        error 200 "Purged.";
    }
}

sub vcl_miss {
    if (req.request == "PURGE") {
        purge;
        error 404 "Not in cache";
    }
}

sub vcl_pipe {
  set bereq.http.connection = "close";
  if (req.http.X-Forwarded-For) {
      set bereq.http.X-Forwarded-For = req.http.X-Forwarded-For;
  }
  else {
      set bereq.http.X-Forwarded-For = regsub(client.ip, ":.*", "");
  }
}

sub vcl_pass {
  set bereq.http.connection = "close";
  if (req.http.X-Forwarded-For) {
      set bereq.http.X-Forwarded-For = req.http.X-Forwarded-For;
  }
  else {
      set bereq.http.X-Forwarded-For = regsub(client.ip, ":.*", "");
  }
}

#
sub vcl_hash {
    hash_data(req.url);

    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }

    if (req.http.Cookie ) {
        hash_data(req.http.Cookie);
    }

    return (hash);
}


sub vcl_deliver {
  # Display hit/miss info
  if (obj.hits > 0) {
     set resp.http.X-Cache = "HIT";
     set resp.http.X-Cache-Hits = obj.hits;
  }
  else {
     set resp.http.X-Cache = "MISS";
  }

  # Remove the Varnish/Apache headers
  remove resp.http.X-Varnish;
  remove resp.http.Server;

  # Display my header
  set resp.http.X-Is-Debian-Awesome = "HELL YES";

  # Remove custom error header
  return (deliver);
}

#
sub vcl_error {
     set obj.http.Content-Type = "text/html; charset=utf-8";
     set obj.http.Retry-After = "5";
     synthetic {"
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
 <html>
   <head>
     <title>"} + obj.status + " " + obj.response + {"</title>
   </head>
   <body>
     <h1>Cache Error "} + obj.status + " " + obj.response + {"</h1>
     <p>"} + obj.response + {"</p>
     <h3>Guru Meditation:</h3>
     <p>XID: "} + req.xid + {"</p>
     <hr>
     <p>Varnish cache server</p>
   </body>
 </html>
"};
    return (deliver);
}
#
# sub vcl_init {
# 	return (ok);
# }
#
# sub vcl_fini {
# 	return (ok);
# }
