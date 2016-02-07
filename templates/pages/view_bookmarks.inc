<ol class="breadcrumb">
  <li><a href="/users/<!-- tmpl_var name="viewusername" -->"><!-- tmpl_var name="viewusername" --></a></li>
  <li><a href="/users/<!-- tmpl_var name="viewusername" -->/bookmarks">Bookmarks</a></li>
</ol>


<!-- tmpl_if name='has_bookmarks' -->

   <!-- tmpl_if name='article_bookmarks' -->
<h3>Bookmarked Articles</h3>
   <ul>
   <!-- tmpl_loop name='article_bookmarks' -->
   <li><a href="/article/<!-- tmpl_var name='uid' -->/<!-- tmpl_var name='slug' -->"><!-- tmpl_var name='title' --></a> <!-- tmpl_if name='delete' -->[<a href="/delete/bookmark/<!-- tmpl_var name='gid' -->/<!-- tmpl_var name='session' -->" title="Delete this bookmark">x</a>]<!-- /tmpl_if --></li>
   <!-- /tmpl_loop -->
   </ul>
   <!-- /tmpl_if -->

   <!-- tmpl_if name='poll_bookmarks' -->
<h3>Bookmarked Polls</h3>
  <ul>
   <!-- tmpl_loop name='poll_bookmarks' -->
   <li><a href="/polls/<!-- tmpl_var name='id' -->"><!-- tmpl_var name='title' --></a> <!-- tmpl_if name='delete' -->[<a href="/delete/bookmark/<!-- tmpl_var name='gid' -->/<!-- tmpl_var name='session' -->" title="Delete this bookmark">x</a>]<!-- /tmpl_if --></li>
   <!-- /tmpl_loop -->
  </ul>
  <!-- /tmpl_if -->

   <!-- tmpl_if name='weblog_bookmarks' -->
<h3>Bookmarked Weblogs</h3>
   <ul>
   <!-- tmpl_loop name='weblog_bookmarks' -->
   <li><a href="/users/<!-- tmpl_var name='owner' -->/weblog/<!-- tmpl_var name='link' -->"><!-- tmpl_var name='title' --></a> <!-- tmpl_if name='delete' -->[<a href="/delete/bookmark/<!-- tmpl_var name='gid' -->/<!-- tmpl_var name='session' -->" title="Delete this bookmark">x</a>]<!-- /tmpl_if --></li>
   <!-- /tmpl_loop -->
   </ul>
   <!-- /tmpl_if -->

<!-- tmpl_else -->

<!-- tmpl_if name='is_owner' -->
 <p>You currently have no bookmarks defined, to create one visit an article, poll, or weblog of interest.</p>
<!-- tmpl_else -->
 <p>The user <a href="/users/<!-- tmpl_var name='viewusername' -->"><!-- tmpl_var name='viewusername' --></a> has no bookmarks.</p>
<!-- /tmpl_if -->

<!-- /tmpl_if -->
