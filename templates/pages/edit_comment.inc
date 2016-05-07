<h2>Edit Comment</h2>
<!-- tmpl_if name='saved' -->
<p>The comment has been saved.</p>
<!-- tmpl_if name="link" -->
<p>You can see the updated <a href="<!-- tmpl_var name="link"-->">comment here</a>.</p>
<!-- /tmpl_if -->

<!-- tmpl_else -->

<form action="/" method="post">
  <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
  <input type="hidden" name="mode" value="edit_comment">
  <input type="hidden" name="comment_id" value="<!-- tmpl_var name="id" -->">
  <input type="hidden" name="article_id" value="<!-- tmpl_var name="article_id" -->">
  <input type="hidden" name="weblog_id" value="<!-- tmpl_var name="weblog_id" -->">
  <input type="hidden" name="poll_id" value="<!-- tmpl_var name="poll_id" -->">

  <p><b>Title:</b>
    <br /><input name="submit_title" type="text" value="<!-- tmpl_var name='submit_title' -->" />

  <p><b>Text:</b>
    <br /><textarea name="submit_body" cols="60" rows="10"><!-- tmpl_var name='submit_body' escape='html' --></textarea></p>
  <p><input type="submit" name="submit" value="save" /></p>
</form>
<!-- /tmpl_if -->
