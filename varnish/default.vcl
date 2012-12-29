
#
# Default backend definition.
# 
backend default {
    .host = "127.0.0.1";
    .port = "8080";
    .connect_timeout = 600s;
    .first_byte_timeout = 600s;
    .between_bytes_timeout = 600s;
    .max_connections = 800;
}

# 
# Below is a commented-out copy of the default VCL logic.  If you
# redefine any of these subroutines, the built-in logic will be
# appended to your code.
# 
sub vcl_recv {
  # Ignore all "POST" requests - nothing cacheable there
  if (req.request == "POST") {
      return (pass);
  }

  if (req.http.Accept-Encoding) {
    if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
        # No point in compressing these
        remove req.http.Accept-Encoding;
    } elsif (req.http.Accept-Encoding ~ "gzip") {
        set req.http.Accept-Encoding = "gzip";
    } elsif (req.http.Accept-Encoding ~ "deflate") {
        set req.http.Accept-Encoding = "deflate";
    } else {
        # unknown algorithm
        remove req.http.Accept-Encoding;
    }
  }

  # In the event of a backend overload (HA!),
  # serve stale objects for up to two minutes
  set req.grace = 10m;

  # Remove cookies from most kinds of static objects, since we want
  # all of these things to be cached whenever possible.
  if (req.url ~ "\.(png|gif|jpeg|jpg|ico|swf|css|js|html|htm|woff|ttf|eot|svg)(\?[a-zA-Z0-9\=\.\-]+)?$") {
      remove req.http.Cookie;
  }

  if (req.http.Cookie == "") {
      remove req.http.Cookie;
  }

  # Tell Varnish to use X-Forwarded-For, to set "real"
  # IP addresses on all requests
  remove req.http.X-Forwarded-For;
  set req.http.X-Forwarded-For = req.http.rlnclientipaddr;
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

sub vcl_fetch {
  set beresp.grace = 10m;

  # Strip cookies before static items are inserted into cache.
  if (req.url ~ "\.(png|gif|jpg|swf|css|js|ico|html|htm|woff|eof|ttf|svg)$") {
      remove beresp.http.set-cookie;
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
}

# 
sub vcl_hash {
     set req.hash += req.url;
     if (req.http.host) {
         set req.hash += req.http.host;
     } else {
         set req.hash += server.ip;
     }
     if (req.http.Cookie ) {
         set req.hash += req.http.Cookie;
     }
   
     return (hash);
}
 
sub vcl_fetch {
     if (!beresp.cacheable) {
         return (pass);
     }
     if (beresp.http.Set-Cookie) {
         return (pass);
     }
     return (deliver);
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

  # Remove the Varnish header
  remove resp.http.X-Varnish;

  # Display my header
  set resp.http.X-Are-Dinosaurs-Awesome = "HELL YES";

  # Remove custom error header
  remove resp.http.MyError;
  return (deliver);
}
 
sub vcl_error {
     set obj.http.Content-Type = "text/html; charset=utf-8";
     synthetic {"
 <?xml version="1.0" encoding="utf-8"?>
 <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
 <html>
   <head>
     <title>"} obj.status " " obj.response {"</title>
   </head>
   <body>
     <h1>Error "} obj.status " " obj.response {"</h1>
     <p>"} obj.response {"</p>
     <h3>Guru Meditation:</h3>
     <p>XID: "} req.xid {"</p>
     <hr>
     <p>Varnish cache server</p>
   </body>
 </html>
 "};
     return (deliver);
 }
