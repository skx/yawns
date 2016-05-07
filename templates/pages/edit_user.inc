<div class="container-fluid">

  <form action="/edit/user/<!-- tmpl_var name="username" -->" method="post">
    <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
    <input type="hidden" name="mode" value="edit_user" />
    <input type="hidden" name="edit_user" value="<!-- tmpl_var name='username' -->">

    <div class="panel panel-info">
      <div class="panel-heading">
        <h3 class="panel-title">Edit Profile</h3>
      </div>
      <div class="panel-body">
        <div class="row">
          <div class=" col-md-11 col-lg-11">
            <table class="table table-user-information">
              <tbody>
                <tr>
                  <td><b>Your Name:</b></td>
                  <td><input name="realname" type="text" size="50" maxlength="25" value="<!-- tmpl_var name='realname' -->" /></td>
                </tr>
                <tr>
                  <td><b>Private Email:</b></td>
                  <td><input name="realemail" type="text" size="50" maxlength="50" value="<!-- tmpl_var name='realemail' -->" /></td>
                </tr>
                <tr><td></td> <td>Your <b>private</b> email is not displayed publicly and is used to validate your account, and receive comment-notification emails if you enable that feature.</td></tr>
                <tr><td><b>Public Email:</b></td>
                  <td><input name="fakeemail" type="text" size="50" maxlength="50" value="<!-- tmpl_var name='fakeemail' -->" /></td></tr>
	        <tr><td></td>
                  <td>The public email is shown upon your user page, and may be spam-trapped or blank.)</td></tr>
	        <tr><td><b>Homepage:</b></td>
	          <td><input name="url" type="text" size="50" maxlength="100" value="<!-- tmpl_var name='url' -->" /></td></tr>
	        <tr><td valign="top"><b>Bio:</b></td>
	          <td valign="top">
                    <textarea name="bio" cols="100" rows="14"><!-- tmpl_var name='bio' escape='html' --></textarea>
	        </td></tr>
	        <tr><td>&nbsp;</td><td></td></tr>

	        <tr><td valign="top"><b>Sig:</b></td>
	          <td valign="top"><textarea name="sig" cols="80" rows="5"><!-- tmpl_var name='sig' escape='html' --></textarea>
	            <p>(Displayed at the bottom of any comments you make.)</p></td></tr>
	        <tr><td>&nbsp;</td><td></td></tr>

	        <tr><td></td><td><p><input type="submit" name="update" value="Update" /> &nbsp; <input type="reset"  name="reset"  value="Reset"  /></p></td></tr>
            </table>
          </div>
        </div>
      </div>
    </div>
  </form>
</div>
