	<h2>Edit Weblog Entry</h2>
                  <form action="/edit/weblog/<!-- tmpl_var name="id" -->" method="post">
                  <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
                  <input type="hidden" name="mode" value="edit_weblog" />
		  <input type="hidden" name="id" value="<!-- tmpl_var name="id" -->">
                    <p><b>Title:</b> <input name="submit_title" type="text" value="<!-- tmpl_var name='submit_title' -->" size="50" maxlength="50" />
                    <p><b>Tags:</b> <input name="submit_tags" type="text" value="<!-- tmpl_var name='submit_tags' -->" size="50" maxlength="100" />

                    <p><b>Text:</b>
                    <br /><textarea name="submit_body" class="expanding" cols="60" rows="10"><!-- tmpl_var name='submit_body' escape='html' --></textarea></p>

                    <p><b>Comment Options:</b>
	<!-- tmpl_if name='submit_comments' -->
                        <select name="submit_comments">
                        <option value="enabled" selected>Comments Enabled</option>
                        <option value="disabled">Comments Disabled</option>
                        </select>

	<!-- tmpl_else -->
                        <select name="submit_comments">
                        <option value="enabled">Comments Enabled</option>
                        <option value="disabled" selected>Comments Disabled</option>
                        </select>
	<!-- /tmpl_if -->

                    <p><input type="submit" name="submit" value="Save" /></p>
                  </form>
