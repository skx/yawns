<div class="container-fluid">

<div class="row">
  <div class="col-sm-1 col-md-1"></div>
  <div class="col-sm-1 col-md-11">

         <form action="/edit/user/<!-- tmpl_var name="username" -->" method="post">
       <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
       <input type="hidden" name="mode" value="edit_user" />
       <input type="hidden" name="edit_user" value="<!-- tmpl_var name='username' -->">

    <div class="panel panel-info">
      <div class="panel-heading">
        <h3 class="panel-title">Edit Your Profile</h3>
      </div>
      <div class="panel-body">
        <div class="row">
          <div class="col-md-3 col-lg-3 " align="center"> <!-- tmpl_if name='gravitar' --><img alt="User Pic" src="<!-- tmpl_var name='gravitar' -->" class="img-circle img-responsive"><!-- /tmpl_if --> </div>
          <div class=" col-md-9 col-lg-9 ">
            <table class="table table-user-information">
              <tbody>
                <tr>
                  <td>Real Name:</td>
                  <td><input name="realname"  type="text" size="50" maxlength="25" value="<!-- tmpl_var name='realname' -->" /></td>
                </tr>
                <tr>
                  <td>Private Email:</td>
                  <td><input name="realemail" type="text" size="50" maxlength="50" value="<!-- tmpl_var name='realemail' -->" /></td>
                </tr>
                <tr><td></td> <td>(This is not displayed publicly and is used to validate your account, and receive comment notification emails if you enable that feature.)</td></tr>
                <tr><td><b>Public Email:</b></td>
                  <td><input name="fakeemail" type="text" size="50" maxlength="50" value="<!-- tmpl_var name='fakeemail' -->" /></td></tr>
	        <tr><td></td>
                  <td>(Displayed upon your user page, may be spam trapped or blank.)</td></tr>
	        <tr><td><b>Homepage:</b></td>
	          <td><input name="url" type="text" size="50" maxlength="100" value="<!-- tmpl_var name='url' -->" /></td></tr>
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
          </div>
        </div>
      </div>
    </div>
         </form>
  </div>
