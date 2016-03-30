<!-- tmpl_if name='recaptcha' -->
<script src="https://www.google.com/recaptcha/api.js"></script>
<!-- /tmpl_if name='recaptcha' -->


<!-- tmpl_if name='new_user_sent' -->

<div class="container">
  <h1>Account Created</h1>
  <div class="container-fluid">
    <div class="row">
      <div class="col-sm-1 col-md-1">
      </div>
      <div class="col-sm-11 col-md-11">
        <p>Your password has been emailed to <b><!-- tmpl_var name='new_user_email' --></b> - when you receive it, please login using the form at the side of any page.</p>
      </div>
    </div>
  </div>
</div>

<!-- tmpl_else -->

<div class="container">
  <h1>Register An Account</h1>
  <div class="container-fluid">
    <div class="row">
      <div class="col-sm-1 col-md-1">
      </div>
      <div class="col-sm-11 col-md-11">
        <p>Registering an account with us will allow you to post weblog entries, track replies to your comments, and submit articles or polls.</p>
      </div>
    </div>
  </div>
</div>

<div class="container">
  <div id="signupbox" style="margin-top:50px" class="mainbox col-md-6 col-md-offset-3 col-sm-8 col-sm-offset-2">
    <div class="panel panel-info">
      <div class="panel-heading">
        <div class="panel-title">Sign Up</div>
        <div style="float:right; font-size: 85%; position: relative; top:-10px"><a id="signinlink" href="/login/">Sign In</a></div>
      </div>
      <div class="panel-body" >
        <form id="signupform" class="form-horizontal" role="form" method="POST" action="/create/user/">
          <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
          <input type="hidden" name="mode" value="new_user" />

          <div class="form-group">
            <label for="lname" class="col-md-3 control-label">Username</label>
            <div style="margin-bottom: 25px" class="input-group col-md-8">
              <span class="input-group-addon"><i class="glyphicon glyphicon-user"></i></span>
              <input type="text" class="form-control" id="new_user_name" name="new_user_name" placeholder="Your username" value="<!-- tmpl_var name='new_user_name' -->">
            </div>

            <!-- tmpl_if name='blank_username' -->
            <p>You must enter the username you wish to use.</p>
            <!-- /tmpl_if -->
            <!-- tmpl_if name='prev_banned' -->
            <p>The IP address you are using is associated with a previously banned account, you may not register an account.</p>
            <!-- /tmpl_if -->
            <!-- tmpl_if name='bad_ip' -->
            <p>The IP address you are using is listed as a spam-source on <a href="http://blogspam.net/">BlogSpam</a>, you may not register an account.</p>
            <!-- /tmpl_if -->
            <!-- tmpl_if name='already_exists' -->
            <p>Sorry, the username you entered is already in use - please try again with a different username.</p>
            <!-- /tmpl_if -->
            <!-- tmpl_if name='invalid_username' -->
            <p>Sorry, the username you entered is not valid - please use only letters, numbers and '-' or '_'.  Usernames should be no longer than 25 characters in length.</p>
            <!-- /tmpl_if -->

          </div>


          <div class="form-group">
            <label for="email" class="col-md-3 control-label">Email</label>
            <div style="margin-bottom: 25px" class="input-group col-md-8">
              <span class="input-group-addon"><i class="glyphicon glyphicon-envelope"></i></span>
              <input type="text" id="new_user_email" class="form-control" name="new_user_email" placeholder="Your email address" value="<!-- tmpl_var name='new_user_email' -->">
            </div>
            <!-- tmpl_if name='prev_email' -->
            <p>The email address you are using is already associated with an account.</p>
            <!-- /tmpl_if -->
            <!-- tmpl_if name='blank_email' -->
            <p>Sorry, you must enter an email address.</p>
            <!-- /tmpl_if -->
            <!-- tmpl_if name='invalid_email' -->
            <p>Sorry, your email address contained errors: <!-- tmpl_var name='mail_error' -->.</p>
            <!-- /tmpl_if -->
          </div>

          <!-- tmpl_if name='recaptcha' -->
          <div class="form-group">
            <label for="lpass2" class="col-md-3 control-label">ReCAPTCHA</label>
            <div style="margin-bottom: 25px" class="input-group col-md-8">
              <div class="g-recaptcha" data-sitekey="<!-- tmpl_var name='recaptcha' escape='html' -->"></div>
            </div>
          </div>
          <!-- /tmpl_if name='recaptcha' -->

          <div class="form-group">
            <!-- Button -->
            <div class="col-md-offset-3 col-md-9">
              <button id="submit" name="submit" value="Create User" class="btn btn-info">Register</button>
            </div>
          </div>

        </form>
      </div>
    </div>
  </div>
</div>


<!-- /tmpl_if name='new_user_sent' -->
