<div class="container-fluid">
  <!-- tmpl_if name='http' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Insecure Access</h2></div>
  </div>
  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
      <p>You're accesing this page over HTTP, rather than using the secure access method.  You should probably switch <a href="<!-- tmpl_var name='secure' -->">to the secure version</a> of this page.</p>
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

          <div class="form-group">
            <label for="lname" class="col-md-3 control-label">Username</label>
            <div style="margin-bottom: 25px" class="input-group col-md-8">
              <span class="input-group-addon"><i class="glyphicon glyphicon-user></i></span>
              <input type="text" id="lname" class="form-control" name="lname" placeholder="Your username">
            </div>
          </div>

          <div class="form-group">
            <label for="lpass" class="col-md-3 control-label">Password</label>
            <div style="margin-bottom: 25px" class="input-group col-md-8">
              <span class="input-group-addon"><i class="glyphicon glyphicon-lock></i></span>
              <input type="password" id="lpass" class="form-control" name="lpass" placeholder="Your password">
            </div>
          </div>

        <div style="margin-bottom: 10px" class="input-group">
          <p><input name="secure" value="1" type="checkbox"> <a href="/about/Secure%20Login">Bind session to your IP.</a></p>
        </div>

        <div style="margin-bottom: 10px" class="input-group pull-right">
          <input type="submit" id="submit" name="submit" value="Login" class="btn btn-info">
        </div>
      </form>

    </div>
  </div>
</div>


</div>
