
<!-- tmpl_if name='error' -->
<h1>Submission Not Found</h1>

<p>The submission you attempted to access was not found in the <a href="/submission/list">submissions queue</a>.</p>

<!-- tmpl_else -->

             <h1>View Submission</h1>

<p>Here you can view or edit the article prior to submission.</p>

	 <table>
           <tr><td><b>Title</b></td><td><!-- tmpl_var name="title" --> </td></tr>
           <tr><td><b>Current Tags</b></td><td>
<!-- tmpl_if name='has_tags' -->
            <!-- tmpl_include name="../includes/tags.template" -->
<!-- tmpl_else -->
<p>There are no tags currently set.</p>
<!-- /tmpl_if -->
           </td></tr>
	   <tr><td><b>Author</b></td><td><a href="/users/<!-- tmpl_var name='author' escape='html' -->"><!-- tmpl_var name="author" --></a> [<!-- tmpl_var name="ip" escape='html' -->]</td></tr>
           <tr><td valign="top"><b>Content:</b></td>
            <td valign="top"><!-- tmpl_var name='submission_body' --></td></tr>


<!-- tmpl_if name='article_admin' -->
<tr><td valign="top"><b>Actions</b></td><td>
 <ul>
    <li><a href="/edit/submission/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Edit</a></li>
    <li><a href="/post/submission/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Post</a></li>
    <li><a href="/reject/submission/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Delete</a></li>
    </ul>
</td>
<!-- tmpl_else -->
  <!-- tmpl_if name='is_author' -->
          <tr><td></td><td align="right"><a href="/edit/submission/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Edit Submission</a>.</td></tr>
  <!-- /tmpl_if -->
<!-- /tmpl_if -->

	</table>
<p></p>

<!-- /tmpl_if -->
