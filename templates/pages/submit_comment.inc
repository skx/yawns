
                  <!-- tmpl_if name='confirm' -->
		      <h2>Comment Posted</h2>

		    <p>Your comment was posted successfully.</p>

		  <!-- tmpl_if name='onpoll' -->
		    <p>If you <a href="/polls/<!-- tmpl_var
name='onpoll' -->">return to the poll you were viewing</a>, your
		    comment should have already been added (if you can't
		    see it, try reloading the page).</p>
                    <!-- tmpl_if name='anon' -->
		    <p>If you <a href="/create/user">create an account</a> you can track any response your comment might generate.</p>
                    <!-- /tmpl_if -->
                    <!-- /tmpl_if -->
	          <!-- tmpl_if name='onarticle' -->
		    <p>If you <a href="/articles/<!-- tmpl_var
name='onarticle' -->">return to the story you were reading</a>, your
		    comment should have already been added (if you can't
		    see it, try reloading the page).</p>
                    <!-- tmpl_if name='anon' -->
		    <p>If you <a href="/create/user">create an account</a> you can track any response your comment might generate.</p>
                    <!-- /tmpl_if -->
	          <!-- /tmpl_if -->
	          <!-- tmpl_if name='onweblog' -->
		    <p>If you <a href="<!-- tmpl_var name='weblog_link' -->">return to the weblog entry you were reading</a>, your
		    comment should have already been added (if you can't
		    see it, try reloading the page).</p>
	          <!-- /tmpl_if -->

                  <!-- tmpl_else -->
                  <!-- tmpl_if name='new' -->
      <h1>Add Comment</h1>
                  <form action="/comment/add" method="post">
                  <input type="hidden" name="mode" value="add_comment" />
                  <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
                    <!-- tmpl_if name='anon' -->
                    <p><b>You are not currently  logged in.</b>  If you do not
		    have a user account then please consider
		    <a href="/create/user">creating one</a>
		    and logging in before you post your comment.  This will allow you to track replies to your comment, and take part in the site much more freely.</p>
                    <!-- /tmpl_if -->
                    <p>To add your comment, fill in all the boxes below and then preview it to make sure you're happy with the way that it looks.</p>
		   <!-- /tmpl_if -->

	          <!-- tmpl_if name='oncomment' -->
		   <!-- tmpl_if name='onarticle' -->
			  <p>This is the comment you were replying to, attached to the article <a href="/articles/<!-- tmpl_var name="onarticle" -->"><!-- tmpl_var name="title" --></a>:</p>
		   <!-- /tmpl_if -->
		   <!-- tmpl_if name='onpoll' -->
			  <p>This is the comment you were replying to, attached to the poll <a href="/polls/<!-- tmpl_var name="onpoll" -->"><!-- tmpl_var name="title" --></a></p>
		   <!-- /tmpl_if -->
		   <!-- tmpl_if name='onweblog' -->
			  <p>This is the comment you were replying to, attached to the weblog <a href="<!-- tmpl_var name="weblog_link" -->"><!-- tmpl_var name="title" --></a></p>
		   <!-- /tmpl_if -->
		  <hr />
	<blockquote>
                  <table tyle="border: solid;"><tr><td>
<div class="comment">
  <div class="link">
 			<!-- tmpl_if name='onpoll' -->
                        #<a href="/polls/<!-- tmpl_var name="onpoll" -->#comment_<!-- tmpl_var name="oncomment" -->"><!-- tmpl_var name="oncomment" --></a>
			<!-- /tmpl_if -->
			<!-- tmpl_if name='onarticle' -->
                        #<a href="/articles/<!-- tmpl_var name="onarticle" -->#comment_<!-- tmpl_var name="oncomment" -->"><!-- tmpl_var name="oncomment" --></a>
			<!-- /tmpl_if -->
			<!-- tmpl_if name='onweblog' -->
                        #<a href="<!-- tmpl_var name='weblog_link' -->#comment_<!-- tmpl_var name="oncomment" -->"><!-- tmpl_var name="oncomment" --></a>
			<!-- /tmpl_if -->
  </div>
  <div class="title"><!-- tmpl_var name='parent_subject' --></div>
 <div class="tagline">
 Posted by <a href="/users/<!-- tmpl_var escape='url' name='parent_author' -->"><!-- tmpl_var name='parent_author' --></a> <!-- tmpl_if name="parent_ip" --> (<!-- tmpl_var name="parent_ip" -->)<!-- /tmpl_if --> on <!-- tmpl_var name='parent_date' -->  at <!-- tmpl_var name='parent_time' --> </div>
 <div class="body">
                              <!-- tmpl_var name='parent_body' -->
 </div>
</div>
                  </td></tr></table>
		  </blockquote>

	          <hr />
		  <!-- /tmpl_if -->

		  <!-- tmpl_if name='preview' -->
<h2>Comment Preview</h2>
	          <p>Your comment currently looks like this:</p>
		  <blockquote>
                  <table style="border: solid;" width="100%">
                   <tr>
		   <td>
<div class="comment">
  <div class="link">#?</div>
  <div class="title"><!-- tmpl_var name='submit_title' --></div>

 <div class="tagline">
 Posted by <a href="/users/<!-- tmpl_var escape='url' name='username' -->"><!-- tmpl_var name='username' --></a> <!-- tmpl_if name='modifier' --><!-- tmpl_var name='modifier' --><!-- /tmpl_if --> <!-- tmpl_if name="ip" --> (<!-- tmpl_var name="ip" -->)<!-- /tmpl_if --> on <!-- tmpl_var name='submit_ondate' -->  at <!-- tmpl_var name='submit_attime' --> </div>
 <div class="body">
  <!-- tmpl_var name='preview_body' -->
 </div>

		   </td>
                  </table>
		  </blockquote>
		  <!-- /tmpl_if -->

		  <!-- tmpl_if name='new' -->
		  <table>
		  <tr><td><b>Username:</b></td><td><!-- tmpl_var name='username' --></td></tr>
		  <tr><td><b>Title:</b></td><td><input name="submit_title" type="text" size="65" maxlength="75" value="<!-- tmpl_var name='submit_title' -->" /></td></tr>
		  <tr><td colspan="2"><b>Your Comment:</b></td></tr>
		  <tr><td colspan="2">
                    <textarea name="submit_body" cols="80" class="expanding" rows="5"><!-- tmpl_var name='submit_body' --></textarea></td></tr>
		  <tr><td valign="top"><p><b>Posting Format:</b></td>
		      <td>
<!-- tmpl_include name="../includes/formatting-types.template" -->
                      </td></tr>
                  <tr><td></td><td>
		    <input type="submit" name="submit" value="Preview" /> &nbsp;
                    <input name="onarticle"    type="hidden" value="<!-- tmpl_var name='onarticle' -->" />
                    <input name="onweblog"    type="hidden" value="<!-- tmpl_var name='onweblog' -->" />
                    <input name="onpoll"    type="hidden" value="<!-- tmpl_var name='onpoll' -->" />
	            <input name="oncomment"    type="hidden" value="<!-- tmpl_var name='oncomment' -->" />
</td></tr>
	</table>
		   <p><a href="/about/Comments">Inappropriate comments</a> will be removed.</p>
                  <!-- tmpl_else -->
	            <p>If you wish to make a minor change please do so below, and preview again.  Once you're happy with it you can submit it with the "Confirm" button.</p>

                    <form action="/comment/add" method="post">
                    <input type="hidden" name="mode" value="add_comment" />
                    <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />

		  <table>
		  <tr><td><b>Username:</b></td><td><!-- tmpl_var name='username' --></td></tr>
		  <tr><td><b>Title:</b></td><td><input name="submit_title" type="text" size="65" maxlength="75" value="<!-- tmpl_var name='submit_title' -->" /></td></tr>
		  <tr><td colspan="2"><b>Your Comment:</b></td></tr>
		  <tr><td colspan="2">
                    <textarea name="submit_body" cols="80" rows="5" class="expanding"><!-- tmpl_var name='submit_body' --></textarea></td></tr>
		  <tr><td valign="top"><p><b>Posting Format:</b></td>
		      <td>
<!-- tmpl_include name="../includes/formatting-types.template" -->
                      </td></tr>
                  <tr><td></td><td>
                    <input type="submit" name="submit" value="Preview" /> &nbsp;

		    <input type="submit" name="submit" value="Confirm" />

                    <input name="onarticle"    type="hidden" value="<!-- tmpl_var name='onarticle' -->" />
                    <input name="onweblog"    type="hidden" value="<!-- tmpl_var name='onweblog' -->" />
                    <input name="onpoll"    type="hidden" value="<!-- tmpl_var name='onpoll' -->" />
	            <input name="oncomment"    type="hidden" value="<!-- tmpl_var name='oncomment' -->" />
</td></tr>
	</table>

<p>Your comment remains your own property and you retain the copyright - however by clicking on the <tt>Confirm</tt> button you give your permission for us to publish the comment on this website along with any discussion which might arise from it.</p>


		    <!-- /tmpl_if -->
                  <!-- /tmpl_if -->
                  </form>

<!-- tmpl_unless name='confirm' -->
<p>Some help on <a href="/about/Entry%20Formatting">entry formatting</a> is available</p>
<!-- /tmpl_unless -->
