
  <div id="loginbox" style="margin-top:50px;" class="mainbox col-md-6 col-md-offset-3 col-sm-8 col-sm-offset-2">
    <div class="panel panel-info" >
      <div class="panel-heading">
        <div class="panel-title">Login</div>
        <div style="float:right; font-size: 80%; position: relative; top:-10px"><a href="/password/sendmail/">Forgot your password?</a></div>
      </div>
      <div class="panel-body" >

        <form id="loginform" class="form-horizontal" role="form" method="POST" action="/login/">
          <input type="hidden" name="mode" value="login" />

          <div class="form-group">
            <label for="lname" class="col-md-3 control-label">Username</label>
            <div style="margin-bottom: 25px" class="input-group col-md-8">
              <input type="text" id="lname" class="form-control" name="lname" placeholder="Your username">
            </div>
         </div>

        <div class="form-group">
         <label for="lpass" class="col-md-3 control-label">Password</label>
         <div style="margin-bottom: 25px" class="input-group col-md-8">
              <input type="password" id="lpass" class="form-control" name="lpass" placeholder="Your password">
         </div>
        </div>

        <div class="form-group">
         <label for="secure" class="col-md-3 control-label">Options</label>
         <div style="margin-bottom: 25px" class="input-group col-md-8">
             <input name="secure" value="1" type="checkbox"> <a href="/about/Secure%20Login">Bind session to your IP.</a>
        </div>

          <div class="form-group">
            <div class="col-md-offset-3 col-md-9">
            <input type="submit" id="submit" name="submit" value="Login" class="btn btn-info">
          </div>
          </div>
        </form>

      </div>
    </div>
  </div>
