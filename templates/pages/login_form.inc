<div class="container-fluid">
  <!-- tmpl_if name='http' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Insecure Access</h2></div>
  </div>
  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
      <p><a href="<!-- tmpl_var name='secure' -->">Switch to secure page</a>.</p>
    </div>
  </div>
  <!-- /tmpl_if -->


<div id="loginbox" style="margin-top:50px;" class="mainbox col-md-6 col-md-offset-3 col-sm-8 col-sm-offset-2">
  <div class="panel panel-info" >
    <div class="panel-heading">
      <div class="panel-title">Login</div>
      <div style="float:right; font-size: 80%; position: relative; top:-10px"><a href="/password/sendmail/">Forgot your password?</a></div>
    </div>
    <div style="padding-top:30px" class="panel-body" >

      <div style="display:none" id="login-alert" class="alert alert-danger col-sm-12"></div>

      <form id="loginform" class="form-horizontal" role="form" method="POST" action="/login/">
        <input type="hidden" name="mode" value="login" />
        <div style="margin-bottom: 25px" class="input-group">
          <span class="input-group-addon"><i class="glyphicon glyphicon-user"></i></span>
          <input id="lname" type="text" class="form-control" name="lname" value="" placeholder="Your username ">
        </div>
        <div style="margin-bottom: 25px" class="input-group">
          <span class="input-group-addon"><i class="glyphicon glyphicon-lock"></i></span>
          <input id="lpass" type="password" class="form-control" name="lpass" placeholder="Your password">
        </div>

        <div style="margin-bottom: 25px" class="input-group">
          <p><input name="secure" value="1" type="checkbox"> <a href="/about/Secure%20Login">Bind session to your IP</a></p>
        </div>

        <div style="margin-bottom: 25px" class="input-group">
          <!-- tmpl_if name='http' -->
          <p><input name="ssl" value="1" type="checkbox"> Force SSL use for all pages (<a href="/about/SSL%20Certificate">validate the SSL certificate</a>)</p>
          <!-- tmpl_else -->
          <p><input name="ssl" value="1" type="checkbox" checked> Force SSL use for all pages (<a href="/about/SSL%20Certificate">validate the SSL certificate</a>)</p>
          <!-- /tmpl_if -->
        </div>

        <div style="margin-bottom: 25px" class="input-group pull-right">
          <input type="submit" id="submit" name="submit" value="Login" class="btn btn-info">
        </div>
      </form>

    </div>
  </div>
</div>


</div>
