<!-- tmpl_if name='submit' -->

<h1> Password Updated</h1>

<p>Your password has been updated.  Please login now.</p>

<!-- tmpl_else -->

<h1>Secure Password Reset</h1>

<p>If you've received an email directing you to this page then
 you may now securely change your password.</p>

<form action="/" method="post">
  <input type="hidden" name="mode" value="change_password" />
  <input type="hidden" name="user" value="<!-- tmpl_var name='user' -->">
  <input type="hidden" name="magic" value="<!-- tmpl_var name='magic' -->">
<table>
<tr><td><b>New Password:</b></td>
    <td><input type="password" name="newpass" value="" /></td></tr>
<tr><td>&nbsp;</td>
    <td><input type="submit" name="changey" value="Change Password"></td></tr>
</tr>
</table>
</form>
<!-- /tmpl_if -->
