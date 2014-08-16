<h1>Advanced Login Options</h1>
<p>Here you can choose your login options for the site.</p>
<!-- tmpl_if name='http' -->
<p><a href="<!-- tmpl_var name='secure' -->">Switch to secure page</a>.</p>
<!-- /tmpl_if -->

 <form action="/login" method="post">
 <input type="hidden" name="mode" value="login">

<table>
<tr><td><b>Username</b>:</td><td><p><input name="lname" type="text" size="14" maxlength="25" /></p></td></tr>
 <tr><td><b>Password</b>:</td><td><p><input name="lpass" type="password" size="15" maxlength="25" /></p></td></tr>
 <tr><td valign="top"><b>Advanced</b>:</td><td>
 <p><input name="secure" value="1" type="checkbox"> <a href="/about/Secure%20Login">Bind session to your IP</a></p>
<!-- tmpl_if name='http' -->
 <p><input name="ssl" value="1" type="checkbox"> Force SSL use for all pages (<a href="/about/SSL%20Certificate">validate the SSL certificate</a>)</p>
<!-- tmpl_else -->
 <p><input name="ssl" value="1" type="checkbox" checked> Force SSL use for all pages (<a href="/about/SSL%20Certificate">validate the SSL certificate</a>)</p>
<!-- /tmpl_if -->
 </td></tr>
 <tr><td></td><td valign="top"> <p><input type="submit" name="submit" value="Login" /></p></td></tr>
 </table>
 </form>
