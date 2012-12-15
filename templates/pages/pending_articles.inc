
<!-- tmpl_if name='empty' -->
      <h1>No Article Submissions</h1>
      <p>There are currently no articles in the submissions queue.</p>
      <p>Please <a href="/create/article">create an article</a>.</p>
<!-- tmpl_else -->

      <h1>Article Submissions</h1>

	<p>This is the submissions queue, containing all the pending articles.  Articles here are editable by anybody who can view this page as well as the original author.</p>
	<p>There is <a href="/about/Article%20Administration">some brief help</a> available for working with this queue as well as <a href="/submission/feed">an RSS feed</a> of pending articles.</p>
<blockquote>
<dl>
<!-- tmpl_loop name='pending_list' -->
<dt><a href="/view/submission/<!-- tmpl_var name='id' -->"><!-- tmpl_var name='title' --></a> by <a href="/users/<!-- tmpl_var name='byuser' -->"><!-- tmpl_var name='byuser' --></a> [<!-- tmpl_var name='ip' -->]</dt>
<dd>
<!-- tmpl_var name='lead_text' -->
</dd>
<!-- /tmpl_loop -->
</dl>
</blockquote>
<!-- /tmpl_if -->
