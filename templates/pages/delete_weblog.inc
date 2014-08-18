<!-- tmpl_if name='removed' -->
<h2>Entry Removed</h2>
<p>Your weblog entry has been removed.</p>
<p>Return to <a href="/users/<!-- tmpl_var name="username" -->/weblog">your weblogs</a>.</p>
<!-- tmpl_else -->

<h2>Delete Weblog Entry</h2>
<form action="/delete/weblog/<!-- tmpl_var name="id" -->" method="post">
  <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
  <input type="hidden" name="mode" value="delete_weblog" />
  <input type="hidden" name="id" value="<!-- tmpl_var name='id' -->" />
  <p><input type="submit" name="submit" value="Yes Really Delete" /> <input type="submit" name="submit" value="No Keep It" /></p>
</form>
<!-- /tmpl_if -->
