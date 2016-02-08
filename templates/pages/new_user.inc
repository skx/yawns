<!-- tmpl_if name='recaptcha' -->
<script src="https://www.google.com/recaptcha/api.js"></script>
<!-- /tmpl_if name='recaptcha' -->


<!-- tmpl_if name='new_user_sent' -->
<h1>New Account Created</h1>


<p>Your password has been emailed to <b><!-- tmpl_var name='new_user_email' --></b> - when you receive it, please login using the form at the side of any page.</p>

<!-- tmpl_else -->

<h1>Create a new user account</h1>

<p>To register an account please fill out the following details:</p>
<form action="/create/user" method="post">
  <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
  <input type="hidden" name="mode" value="new_user" />
  <table>
    <tr>
      <td valign="top"><b>Username:</b></td>
      <td><input name="new_user_name" type="text" size="25" maxlength="25" value="<!-- tmpl_var name="new_user_name" -->"/>
        <!-- tmpl_if name='blank_username' -->
        <p>You must enter the username you wish to use.</p>
        <!-- /tmpl_if -->
        <!-- tmpl_if name='prev_banned' -->
        <p>The IP address you are using is associated with a previously banned account - you may not re-register.</p>
        <!-- /tmpl_if -->
        <!-- tmpl_if name='bad_ip' -->
        <p>The IP address you are using is listed as a spam-source on <a href="http://blogspam.net/">BlogSpam</a>.</p>
        <!-- /tmpl_if -->
        <!-- tmpl_if name='prev_email' -->
        <p>The email address you are using is already associated with an account.</p>
        <!-- /tmpl_if -->
        <!-- tmpl_if name='invalid_username' -->
        <p>Sorry, the username you entered is not valid - please use only letters, numbers and '-' or '_'.  Usernames should be no longer than 25 characters in length.</p>
        <!-- /tmpl_if -->

        <!-- tmpl_if name='already_exists' -->
        <p>Sorry, the username you entered is already in use - please try again with a different username.</p>
        <!-- /tmpl_if -->
      </td>
    </tr>

    <tr>
      <td valign="top"><b>Email Address:</b></td>
      <td><input name="new_user_email" type="text" size="50" maxlength="50" value="<!-- tmpl_var name="new_user_email" -->"/>
        <!-- tmpl_if name='blank_email' -->
        <p>Sorry, you must enter an email address.</p>
        <!-- /tmpl_if -->
        <!-- tmpl_if name='invalid_email' -->
        <p>Sorry, your email address contained errors: <!-- tmpl_var name='mail_error' -->.</p>
        <!-- /tmpl_if -->
    </td></tr>

    <!-- tmpl_if name='recaptcha' -->
    <tr><td></td><td><div class="g-recaptcha" data-sitekey="<!-- tmpl_var name='recaptcha' escape='html' -->"></div></td></tr>
    <!-- /tmpl_if name='recaptcha' -->

    <tr><td></td><td>
        <p><input type="submit" name="submit" value="Create User" /> &nbsp;
</form>
</td></tr></table>
<p>Your email address is needed to send you your password.  If you wish you can also receive email notification of new replies to any articles and comments you post.</p>
<p>Please make sure it is a valid email address and you have entered it correctly, if you make a mistake you will create an account you cannot use - and you will have to choose another username.</p>
<p>We do not and will not sell, trade, or otherwise disclose our users' email addresses to anyone, for any reason, ever.  Your email address will not be displayed publicly upon the website, unless you choose to add it yourself.</p>

<!-- /tmpl_if name='new_user_sent' -->
