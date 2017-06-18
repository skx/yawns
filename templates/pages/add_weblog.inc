		<h1>Add New Weblog Entry</h1>


        <!-- tmpl_if name='preview' -->

		  <blockquote>
	          <p>Your weblog entry currently looks like this:</p>

                  <table style="border: solid;">
                   <tr>
                      <th align="left">
<!-- tmpl_if name="submit_title" --> <h3><!-- tmpl_var name='submit_title' --></h3><!-- /tmpl_if -->
<p>By <a href="/users/<!-- tmpl_var escape='url' name='username' -->"><!-- tmpl_var name='username' --></a>
<!-- tmpl_if name="ip" -->
 (<!-- tmpl_var name="ip" -->)
<!-- /tmpl_if -->
 on <!-- tmpl_var name='submit_ondate' --> at <!-- tmpl_var name='submit_attime' --></p>
                      </th>
                    </tr>
                    <tr>
                      <td class="outline" colspan="2">
                        <table>
                          <tr>
                            <td>
                              <!-- tmpl_var name='preview_body' -->
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
		  </blockquote>

        <!-- /tmpl_if -->

                  <!-- tmpl_if name='confirm' -->
		    <p>Your new weblog entry has been saved - click
		    <a href="/users/<!-- tmpl_var name='username' -->/weblog">here</a>
		    to see it.</p>
                  <!-- tmpl_else -->
                  <!-- tmpl_if name='new' -->
                  <form action="/create/weblog" method="post">
                    <input type="hidden" name="mode" value="add_weblog">
                    <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
                    <p>To add a new entry to your weblog here on the
		    <!-- tmpl_var name='sitename' --> website, fill in all the boxes
		    below then click the 'Preview' button.  Once you have
		    double-checked it and confirmed that you want to save it,
		    <a href="/users/<!-- tmpl_var name='username' escape='url' -->/weblog">your weblog</a> will be updated to include the new entry.</p>
                  <!-- tmpl_else -->
                  <form action="/create/weblog" method="post">
                  <input type="hidden" name="mode" value="add_weblog">
          <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
<!-- tmpl_if name='blank_body' -->
<b>Error</b>
<blockquote>
<p>Your weblog entry is empty.  Empty entries are not allowed.</p>
</blockquote>
<!-- /tmpl_if -->
<!-- tmpl_if name='blank_title' -->
<b>Error</b>
<blockquote>
<p>Your weblog title is empty.  Empty titles are not allowed.</p>
</blockquote>
<!-- /tmpl_if -->

                    <p>If the entry above is correct, and you would like to
		    save it, then click on the 'Confirm' button below.
                    </p>
	            <p>If you wish to change the entry then make your changes and repeat the preview.</p>

<table>
<tr><td><b>Title:</b></td><td><input name="submit_title" size="50" maxlength="50" type="text" value="<!-- tmpl_var name='submit_title' -->" /></td></tr>

<tr><td colspan="2"><p><b>Weblog Text:</b></td></tr>
<tr><td colspan="2"><textarea name="submit_body" class="expanding" cols="80" rows="5"><!-- tmpl_var name='submit_body' escape='html' --></textarea></td></tr>
</table>
                  <!-- /tmpl_if -->
		  <!-- tmpl_if name='new' -->
<table>
<tr><td><b>User:</b></td><td><!-- tmpl_var name='username' --></td></tr>
<tr><td><b>Title:</b></td><td><input name="submit_title" type="text" size="50" maxlength="50" /></td></tr>
<tr><td colspan="2"><b>Weblog Text:</b></td></tr>
<tr><td colspan="2"><textarea name="submit_body" cols="80" rows="5" class="expanding"></textarea></td></tr>
</table>

                    <table>
                    <tr><td><b>Comment Options:</b></td><td>
                        <select name="comments">
                        <option value="enabled">Comments Enabled</option>
                        <option value="disabled">Comments Disabled</option>
                        </select>
                        </td></tr>
		    </table>

                    <p><input type="submit" name="submit" value="Preview" /></p>
                  <!-- tmpl_else -->
                    <table>
                    <tr><td><b>Comment Options:</b></td><td>

<!-- tmpl_if name='comments_enabled' -->
                        <select name="comments">
                        <option value="enabled" selected>Comments Enabled</option>
                        <option value="disabled">Comments Disabled</option>
                        </select>
<!-- tmpl_else -->
                        <select name="comments">
                        <option value="enabled">Comments Enabled</option>
                        <option value="disabled" selected>Comments Disabled</option>
                        </select>
<!-- /tmpl_if -->
                        </td></tr>
                    <tr><td></td><td><input type="submit" name="submit" value="Preview" /> &nbsp; <input type="submit" name="submit" value="Confirm" /></td></tr>
		    </table>

		    <!-- /tmpl_if -->
<hr />


<!-- tmpl_if name='new' -->
<p><b>Tip:</b></p>
<blockquote>
<p>If you add the special <tt>&lt;cut&gt;</tt> tag your entry will be truncated at that point when it is included in the RSS feed<!-- tmpl_if name='planet_site' --> and also when it is syndicated upon <a href="<!-- tmpl_var name='planet_url' -->" title="Planet <!-- tmpl_var name='sitename' -->">the planet</a><!-- /tmpl_if -->.</p>
</blockquote>
<!-- /tmpl_if -->

                  <!-- /tmpl_if -->
                  </form>
