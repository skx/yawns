<script>
$(document).ready (function() {
	$('textarea.expanding').autogrow({
	});

});
</script>

	<h2>Edit Weblog Entry</h2>
                  <!-- tmpl_if name='saved' -->
		    <p>Your weblog entry has been updated.</p>
		    <p>You can see <a href="/users/<!-- tmpl_var name="username" -->/weblog/<!-- tmpl_var name="id" -->">your updated entry here</a>.</p>

                  <!-- tmpl_else -->

                  <form action="/edit/weblog/<!-- tmpl_var name="id" -->" method="post">
                  <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
                  <input type="hidden" name="mode" value="edit_weblog" />
		  <input type="hidden" name="id" value="<!-- tmpl_var name="id" -->">
                    <p><b>Title:</b> <input name="submit_title" type="text" value="<!-- tmpl_var name='submit_title' -->" size="50" maxlength="50" />
                    <p><b>Tags:</b> <input name="submit_tags" type="text" value="<!-- tmpl_var name='submit_tags' -->" size="50" maxlength="100" />

                    <p><b>Text:</b>
                    <br /><textarea name="submit_body" class="expanding" cols="60" rows="10"><!-- tmpl_var name='submit_body' --></textarea></p>

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
	<p>If you wish you can <a href="/delete/weblog/<!-- tmpl_var name="id" -->">delete this entry</a>.</p>

		    <!-- /tmpl_if -->
