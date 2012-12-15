	<!-- tmpl_if name='saved' -->

      <p>Your <a href="/users/<!-- tmpl_var name="username" -->/scratchpad">scratchpad text</a> has now been saved.</p>
	<!-- tmpl_else -->
	<p><b>What is a Scratchpad?</b></p>
	<blockquote>
	<p>A scratchpad is a place for users to leave notes which they wish other visitors to be able to read.  It can be updated as frequently or infrequently as you wish, and is linked to from each comment you make.</p>
	<p>It is less permanent than <a href="/create/weblog">creating weblog entries</a>.</p>
        <p>If you wish to just keep notes for yourself, or articles which are still in progress then you can choose to make the contents of your scratchpad private.</p>
	</blockquote>

       <!-- Change scratchpad form. -->
       <form action="/edit/scratchpad/<!-- tmpl_var name='username' -->" method="post">
       <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
       <input type="hidden" name="edit_scratchpad" value="<!-- tmpl_var name='username' -->">

        <textarea name="text" cols="80" rows="20"><!-- tmpl_var name='text' --></textarea>
	<p>
<!-- tmpl_if name="private" -->
                        <select name="security">
                        <option value="public">Public Scratchpad</option>
                        <option value="private" selected>Private Scratchpad</option>
                        </select>
<!-- tmpl_else -->
                        <select name="security">
                        <option value="private">Private Scratchpad</option>
                        <option value="public" selected>Public Scratchpad</option>

                        </select>
<!-- /tmpl_if -->

<input type="submit" name="save" value="Save" /> &nbsp; <input type="reset"  name="reset"  value="Reset"  /></p>
                </form>

	<!-- /tmpl_if -->
