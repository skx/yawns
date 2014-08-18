<!-- tmpl_if name='error' -->
<h1>Error</h1>
<p>Sorry, the username and/or email address you entered is not in our records - please try again.</p>
<!-- tmpl_else -->


<!-- tmpl_if name='submit' -->
<h1>Password Link Mailed</h1>
<p>A link to change your password securely has now been mailed to the address associated with your account.</p>
<p>If you do not receive this in the next thirty minutes or so please contact the webmaster.</p>

<!-- tmpl_else -->


<h1>Forgotten Password?</h1>
     <form action="/password/sendmail" method="post">
      <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
      <input type="hidden" name="mode" value="reset_password" />
                    <p><b>Username:</b>
                    <br /><input name="the_user_name" type="text" size="25" maxlength="25" /></p>

                    <p><b>Email Address:</b>
                    <br /><input name="the_user_email" type="text" size="50" maxlength="50" /></p>

                    <p>Please enter either the username or the email address that you used when you created your account.  This will allow us to send you a mail to the registered email address to reset your password.</p>

                    <p><input type="submit" name="submit" value="Send" /> &nbsp;
                  </form>
        <!-- /tmpl_if -->
        <!-- /tmpl_if -->
