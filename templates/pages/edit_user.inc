
	<!-- tmpl_if name="saved" -->
	<p>Your details have been saved.</p>
	<!-- tmpl_else -->

	<p>This page allows you to edit the information which is known about you and displayed upon <a href="/users/<!-- tmpl_var name="username" -->">your user page</a>.</p>

       <!-- Change user information form. -->
       <form action="/edit/user/<!-- tmpl_var name="username" -->" method="post">
       <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
       <input type="hidden" name="mode" value="edit_user" />
       <input type="hidden" name="edit_user" value="<!-- tmpl_var name='username' -->">
       <table>
       <tr><td><b>Real name:</b></td>
           <td><input name="realname"  type="text" size="50" maxlength="25" value="<!-- tmpl_var name='realname' -->" /></td></tr>
       <tr><td></td><td>(Displayed on your user page)</td></tr>
	<tr><td>&nbsp;</td><td></td></tr>
	<tr><td><b>Private Email:</b></td>
            <td><input name="realemail" type="text" size="50" maxlength="50" value="<!-- tmpl_var name='realemail' -->" /></td></tr>
	<tr><td></td>
        <td>(This is not displayed publicly and is used to validate your account, and receive comment notification emails if you enable that feature.)</td></tr>
	<tr><td>&nbsp;</td><td></td></tr>
	<tr><td><b>Public Email:</b></td>
            <td><input name="fakeemail" type="text" size="50" maxlength="50" value="<!-- tmpl_var name='fakeemail' -->" /></td></tr>
	<tr><td></td>
        <td>(Displayed upon your user page, may be spam trapped or blank.)</td></tr>
	<tr><td>&nbsp;</td><td></td></tr>
	<tr><td><b>Homepage:</b></td>
	    <td><input name="url" type="text" size="50" maxlength="100" value="<!-- tmpl_var name='url' -->" /></td></tr>
	<tr><td>&nbsp;</td><td></td></tr>

	<tr><td valign="top"><b>Bio:</b></td>
	    <td valign="top">
               <textarea name="bio" cols="80" rows="10"><!-- tmpl_var name='bio' --></textarea>
	    </td></tr>
	<tr><td>&nbsp;</td><td></td></tr>

	<tr><td valign="top"><b>Sig:</b></td>
	    <td valign="top"><textarea name="sig" cols="80" rows="5"><!-- tmpl_var name='sig' --></textarea>
	<p>(Displayed at the bottom of any comments you make.)</p></td></tr>
	<tr><td>&nbsp;</td><td></td></tr>

	<tr><td></td><td><p><input type="submit" name="update" value="Update" /> &nbsp; <input type="reset"  name="reset"  value="Reset"  /></p></td></tr>
</table>
                </form>

	<!-- /tmpl_if -->

