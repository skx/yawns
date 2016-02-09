<!-- tmpl_if name='error' -->

<div class="container-fluid">
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>No Match</h2></div>
  </div>
  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-11 col-md-10">
      <p>Sorry, the username and/or email address you entered is not in our records - please try again.</p>
    </div>
  </div>
</div>
<!-- tmpl_else -->


<!-- tmpl_if name='submit' -->

<div class="container-fluid">
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>No Match</h2></div>
  </div>
  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-11 col-md-10">
      <p>A link to change your password securely has now been mailed to the address associated with your account.</p>
      <p>If you do not see this in the next thirty minutes or so please check your SPAM folder.</p>
    </div>
  </div>
</div>

<!-- tmpl_else -->


<div class="container-fluid">
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Forgotten Password</h2></div>
  </div>
  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-11 col-md-10">


    <div id="loginbox" style="margin-top:50px;" class="mainbox col-md-6 col-md-offset-2 col-sm-10 col-sm-offset-2">
      <div class="panel panel-info" >
	<div class="panel-heading">
	  <div class="panel-title">Password Reset</div>
	</div>
	<div style="padding-top:30px" class="panel-body" >
	    <p>Please enter <b>either</b> your username or your email address.</p>

	  <form action="/password/sendmail" method="post">
	    <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
	    <input type="hidden" name="mode" value="reset_password" />
            <div style="margin-bottom: 10px" class="input-group">
              <span class="input-group-addon"><i class="glyphicon glyphicon-user"></i></span>
              <input id="the_user_name" type="text" class="form-control" name="the_user_name" value="" placeholder="Your username">
            </div>
            <div style="margin-bottom: 10px" class="input-group">
              <span class="input-group-addon"><i class="glyphicon glyphicon-envelope"></i></span>
              <input id="the_user_email" type="text" class="form-control" name="the_user_email" placeholder="Your email address">
            </div>
            <div style="margin-bottom: 10px" class="input-group pull-right">
              <input type="submit" id="submit" name="submit" value="Reset" class="btn btn-info">
        </div>
      </form>

    </div>
  </div>
</div>

<!-- /tmpl_if -->
<!-- /tmpl_if -->
