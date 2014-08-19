<!-- tmpl_if name='id' -->
  <h1><!-- tmpl_var name='id' --></h1>
<!-- tmpl_else -->
  <h1>Edit 'About' Pages</h1>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='confirm' -->
  <p><a href="/about/<!-- tmpl_var name="page" -->"><!-- tmpl_var name="page" --> page</a> updated successfully.</p>
  <!-- /tmpl_if -->


  <!-- tmpl_unless name='id' -->
  <form action="/edit/about" method="post">
    <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
    <p><input type="hidden" name="mode" value="edit_about" />
      <b>Select page: </b>
      <select name="page">
	<!-- tmpl_loop name='about_pages' -->
	<option value="<!-- tmpl_var name='id' -->"><!-- tmpl_var name="id" --></option>
	<!-- /tmpl_loop -->
      </select>&nbsp;
      <input type="submit" value="Edit" />
    </p>
  </form>
<p> - OR -
</p>
<p><b>Create new page: </b>
</p>
<!-- /tmpl_unless -->
<form action="/edit/about" method="post">
  <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />

  <p><input type="hidden" name="mode" value="edit_about" />
    <input type="hidden" name="pagename" value="<!-- tmpl_var name='id' -->" />
    <b>Name:&nbsp;</b><input type="text" size="25" maxlength="50" value="<!-- tmpl_var name='id' -->" name="page" />
  </p>
  <p><b>Content:</b>
    <br /><textarea name="bodytext" rows="20" cols="60"><!-- tmpl_var name='about_body' --></textarea>
  </p>
  <p><input type="submit" name="submit" value="Save Changes" />&nbsp;<input type="reset" />
  </p>
</form>
