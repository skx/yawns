             <h1>Edit Submission</h1>

         <!-- tmpl_if name='saved' -->
		  <p>The submission was <a href="/view/submission/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">updated successfully</a>.</p>
         <!-- tmpl_else -->
	 <p>Here you can edit the pending submission prior to it being approved or rejected.</p>
         <p><a href="/about/Article%20Editing">Some brief help</a> is available.</p>

		  <form action="/edit/submission/<!-- tmpl_var name="id" -->/<!-- tmpl_var name='session' -->" method="post">
                  <input type="hidden" name="id" value="<!-- tmpl_var name='id' -->" />
                  <input type="hidden" name="mode" value="submission_edit" />
                  <input type="hidden" name="save_pending" value="1" />
	          <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />

	          <table>
                  <tr><td><b>Title</b></td><td><input type="text" name="atitle" value="<!-- tmpl_var name="atitle" -->" /> </td></tr>
                  <tr><td><b>Current Tags</b></td><td><input type="text" name="tags" value="<!-- tmpl_var name="tags" -->" /> (Tags are separated by commas)</td></tr>
                  <tr><td><b>Author</b></td><td><input type="text" name="author" value="<!-- tmpl_var name="author" -->" /> </td></tr>
                  <tr><td valign="top"><b>Content:</b></td>
                  <td><textarea name="bodytext" rows="20" cols="60"><!-- tmpl_var name='submission_body' escape='html' --></textarea></td></tr>

                  <tr><td></td><td><input type="submit" value="Save Changes" />&nbsp;<input type="reset" /></td></tr>
	</table>
		  </form>
	<!-- /tmpl_if -->
