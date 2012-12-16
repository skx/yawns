
	<!-- tmpl_if name="saved" -->
	<p>Your preferences and notification options have now been saved.</p>

	<!-- tmpl_if name="password_saved" -->
	<p>Your password was also updated.</p>
	<!-- /tmpl_if -->

	<!-- tmpl_if name="password_simple" -->
	<p>Your password <b>was not updated</b> - it was too simple.</p>
	<!-- /tmpl_if -->

	<!-- tmpl_if name="password_mismatch" -->
	<p>Your password <b>was not updated</b> - the two passwords you entered were not identical.</p>
	<!-- /tmpl_if -->

	<!-- tmpl_else -->
	<p>This page allows you to customise the way you view this site, and how notifications are passed to you.</p>

       <!-- Change user preferences form. -->
       <form action="/edit/prefs/<!-- tmpl_var name="username" -->" method="post">
       <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
       <input type="hidden" name="edit_prefs" value="<!-- tmpl_var name='username' -->">


       <table>
       <tr><td width="50%" valign="top">

       <fieldset>
         <legend><b>Sidebar Options:</b></legend>

<p>
                <!-- tmpl_if name="viewpolls" -->
                <input type="checkbox" name="viewpolls" value="1" checked> View polls
                <!-- tmpl_else -->
                <input type="checkbox" name="viewpolls" value="1"> View polls
                <!-- /tmpl_if -->
</p>

<p>
                <!-- tmpl_if name="wantblogs" -->
                <input type="checkbox" name="viewblogs" value="1" checked> View weblogs
                <!-- tmpl_else -->
                <input type="checkbox" name="viewblogs" value="1"> View weblogs
                <!-- /tmpl_if -->

</p>
            </fieldset>

            </td>
            <td width="50%" valign="top">
            <fieldset>
            <legend><b>View Adverts:</b></legend>
<p>
                <!-- tmpl_if name="wantadverts" -->
                <input type="checkbox" name="wantadverts" value="1" checked>  View text adverts.
                <!-- tmpl_else -->
                <input type="checkbox" name="wantadverts" value="1"> View text adverts.
                <!-- /tmpl_if -->
</p>
		<p><a href="/about/FAQ%20:%20Site%20Adverts">Why do we have adverts?</a></p>
                </fieldset>

            </td>
            </tr></table>

            <p>&nbsp;</p>
            <fieldset>
            <legend><b>Notification Options</b></legend>
            <table>
<!-- tmpl_if name='article_admin' -->
        <tr><td valign="top"><b>Article Submissions:</b></td>
            <td>
              <select name="submissions">
                <option value="none" <!-- tmpl_if name='submissions_none' -->SELECTED<!-- /tmpl_if -->>No notification</option>
                <option value="email" <!-- tmpl_if name='submissions_email' -->SELECTED<!-- /tmpl_if -->>Email</option>
                </select>
              <p>Notifications of new article submissions.</p>
	    </td></tr>

<!-- /tmpl_if -->
        <tr><td valign="top"><b>Article Replies:</b></td>
            <td>
              <select name="article">
                <option value="none" <!-- tmpl_if name='article_none' -->SELECTED<!-- /tmpl_if -->>No notification</option>
                <option value="message" <!-- tmpl_if name='article_message' -->SELECTED<!-- /tmpl_if -->>Site Message</option>
                <option value="email" <!-- tmpl_if name='article_email' -->SELECTED<!-- /tmpl_if -->>Email</option>
                </select>
              <p>Notifications of replies to articles you have posted.</p>
	    </td></tr>

        <tr><td valign="top"><b>Comment Replies:</b></td>
            <td>
              <select name="comment">
                <option value="none" <!-- tmpl_if name='comment_none' -->SELECTED<!-- /tmpl_if -->>No notification</option>
                <option value="message" <!-- tmpl_if name='comment_message' -->SELECTED<!-- /tmpl_if -->>Site Message</option>
                <option value="email" <!-- tmpl_if name='comment_email' -->SELECTED<!-- /tmpl_if -->>Email</option>
                </select>
              <p>Notification of replies to comments you post.</p>
	    </td></tr>

        <tr><td valign="top"><b>Weblog Replies:</b></td>
            <td>
              <select name="weblog">
                <option value="none" <!-- tmpl_if name='weblog_none' -->SELECTED<!-- /tmpl_if -->>No notification</option>
                <option value="message" <!-- tmpl_if name='weblog_message' -->SELECTED<!-- /tmpl_if -->>Site Message</option>
                <option value="email" <!-- tmpl_if name='weblog_email' -->SELECTED<!-- /tmpl_if -->>Email</option>
                </select>
              <p>Notification of replies to weblog entries you post.</p>
              </td></tr>
            </table>
            </fieldset>


            <p>&nbsp;</p>
         <fieldset>
         <legend><b>Password Change:</b></legend>
         <p>Leave these blank <i>unless</i> you wish to change your password.</p>
         <table>
         <tr><td>New Password</td><td><p><input name="pw1" type="password" size="25" maxlength="25" /></p></td></tr>
         <tr><td>Confirm Password</td><td><p><input name="pw2" type="password" size="25" maxlength="25" /></p></td></tr>
        </table>
        </fieldset>

            <p>&nbsp;</p>
<p><input type="submit" name="update" value="Update" />&nbsp;<input type="reset"  name="reset"  value="Reset"  /></p>
                </form>

	<!-- /tmpl_if -->
