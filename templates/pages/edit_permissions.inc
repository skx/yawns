<!-- tmpl_if name='editted' -->
<h1>User Updated</h1>
<p><a href="/users/<!-- tmpl_var name='edit' escape='html' -->"><!-- tmpl_var name='edit' escape='html' --></a> has been updated.</p>
<p>See the <a href="/edit/permissions/<!-- tmpl_var name='edit' -->">updated user-permissions</a>.</p>
<!-- tmpl_else -->

 <h1>Edit User Permissions</h1>
<p>Here you can edit the permissions available to <a href="/users/<!-- tmpl_var name='edit' escape='html' -->"><!-- tmpl_var name='edit' escape='html' --></a>.</p>
 <form method="POST" action="/">
  <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />  
  <input type="hidden" name="edit_permissions" value="<!-- tmpl_var name='edit' -->" />
 
 <ul>
 <!-- tmpl_loop name='permissions_loop' -->
    <li><input type="checkbox" name="edit_perm_<!-- tmpl_var name='perm' escape='html' -->" value="1" <!-- tmpl_if name='selected' -->checked<!-- /tmpl_if -->> <!-- tmpl_var name='perm' --></li>
 <!-- /tmpl_loop -->
 </ul>
 <input type="submit" name="change_permissions" value="submit">
 </form>

<!-- /tmpl_if -->
