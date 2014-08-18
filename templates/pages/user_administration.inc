
       <h1>User Administration</h1>
	<p>From here you may search the <!-- tmpl_var name="count" --> registered users.</p>

<dl>
<dt>Username</dt>
<dd>
	<form action="/user/admin" method="post">
        <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
        <input type="hidden" name="mode" value="user_admin">
	<input type="text" name="username">
	<input type="hidden" name="user_admin">
	</form>
</dd>
<dt>Email</dt>
<dd>
	<form action="/user/admin" method="post">
        <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
        <input type="hidden" name="mode" value="user_admin">
	<input type="text" name="email">
	<input type="hidden" name="user_admin">
	</form>
</dd>
<dt>Homepage</dt>
<dd>
	<form action="/user/admin" method="post">
        <input type="hidden" name="mode" value="user_admin">
        <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
	<input type="text" name="homepage">
	<input type="hidden" name="user_admin">
	</form>
</dd>
<dt>Permissions</dt>
<dd>
	<form action="/user/admin" method="post">
        <input type="hidden" name="mode" value="user_admin">
        <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
        <select name="permission">
<!-- tmpl_loop name='permissions_loop' -->
        <option value="<!-- tmpl_var name='perm' escape='html' -->"><!-- tmpl_var name='perm' --></option>
<!-- /tmpl_loop -->
        </select>
	<input type="hidden" name="user_admin">
        <input type="submit" value="search">
        </form>
</dd>
</dl>

<!-- tmpl_if name="search" -->

   <!-- tmpl_if name="results" -->
     <table>
	<tr><td><b>Username</b></td><td><b>Homepage</b></td><td><b>Email</b></td></tr>
     <!-- tmpl_loop name="results" -->
        <tr><td><a href="/users/<!-- tmpl_var name="username" -->"><!-- tmpl_var name="username" --></a></td>
	    <td><!-- tmpl_if name="url" --><a href="<!-- tmpl_var name="url" -->"><!-- tmpl_var name="url" --></a><!-- /tmpl_if --></td>
	    <td><!-- tmpl_var name="realemail" --></td>
	</tr>
     <!-- /tmpl_loop -->
     </table>
   <!-- tmpl_else -->
     <p>No results were found.</p>
   <!-- /tmpl_if -->

<!-- /tmpl_if -->
