
	<!-- tmpl_if name="error" -->
	<h1>Entry Not Found</h1>
        <blockquote>
	<p>The weblog entry you are trying to reach does not exist!</p>
	<p>See <a href="/users/<!-- tmpl_var name="user" -->/weblog">all weblog entries</a> made by <a href="/users/<!-- tmpl_var name="user" -->"><!-- tmpl_var name="user"--></a>.</p>
        </blockquote>
<table width="100%">
 <tr>
  <td align="left">
	<!-- tmpl_if name='error_prev' -->
            <a href="/users/<!-- tmpl_var name="user" -->/weblog/<!-- tmpl_var name="error_prev" -->">&lt;&lt;&lt; Previous</a>
	<!-- /tmpl_if -->
  </td>
  <td align="right">
	<!-- tmpl_if name='error_next'>
	     <a href="/users/<!-- tmpl_var name="user" -->/weblog/<!-- tmpl_var name="error_next" -->">Next &gt;&gt;&gt;</a>
	<!-- /tmpl_if -->
  </td>
 </tr>
</table>

	<!-- tmpl_else -->

       <h1>Weblog entry #<!-- tmpl_var name="item" --> for <!-- tmpl_var name='user' --></h1>
<div class="navigation">
	<p>See <a href="/users/<!-- tmpl_var name="user" -->/weblog">all weblog entries</a> made by <a href="/users/<!-- tmpl_var name="user" -->"><!-- tmpl_var name="user"--></a>.</p>
        <p align="right"> <a href="/weblog/feeds/<!-- tmpl_var name="user" -->"><img src="/images/xml.gif" alt="XML logo" width="36" height="14"></a></p>
</div>

       <!-- tmpl_if name='entries' -->
       <!-- tmpl_loop name='entries' -->
	<div class="weblog">
         <!-- link -->
         <div class="link">#<a href="/users/<!-- tmpl_var escape='url' name='user' -->/weblog/<!-- tmpl_var name='item_id' -->"><!-- tmpl_var name='item_id' --></a></div>
         <!-- title -->
	<div class="title"><!-- tmpl_if name="title" --><!-- tmpl_var name='title' --><!-- /tmpl_if --> </div>
	<!-- tagline -->
	<div class="tagline">Posted by <a href="/users/<!-- tmpl_var escape='url' name='user' -->"><!-- tmpl_var name='user' --></a> on <!-- tmpl_var name='ondate' --> at <!-- tmpl_var name='attime' --> <!-- tmpl_if name="edit" -->(<a href="/edit/weblog/<!-- tmpl_var name="item_id" -->">Edit Entry</a>)<!-- /tmpl_if --></div>

<!-- tag start -->
  <!-- tmpl_include name='../includes/view_add_tag.template' -->
<!-- tag end -->


	<div class="body">
                      <!-- tmpl_var name='bodytext' -->
	</div>

	<div class="links">
            [<!-- tmpl_if name='edit' -->Read <!-- tmpl_var name='read' --> times | <!-- /tmpl_if --> <!-- tmpl_if name="comment_count" --><a href="#comments"><!-- tmpl_var name="comment_count" --> Comment<!-- tmpl_if name="plural" -->s<!-- /tmpl_if --></a>  <!-- tmpl_else -->0 Comments <!-- /tmpl_if -->

<!-- tmpl_if name='reportable' -->
    | <a href="/report/weblog/<!-- tmpl_var name='gid' -->/<!-- tmpl_var name='session' -->" onClick="return( confirm('Are you sure you wish to flag this weblog entry for review?') );" >Report Entry</a>
<!-- /tmpl_if -->

	<!-- tmpl_if name="comments_enabled" -->
| <a href="/comment/onweblog/<!-- tmpl_var name="gid" -->">Add Comment</a>
        <!-- /tmpl_if -->
      | <a href="/comment/feed/onweblog/<!-- tmpl_var name='gid' -->" title="Subscribe to comments on this weblog entry."><img src="/images/xml.gif" title="Subscribe to comments on this weblog entry." alt="XML logo" width="36" height="14"></a>
        ]

<table width="100%">
 <tr>
  <td align="left">
	<!-- tmpl_if name='prev' -->
            <a href="/users/<!-- tmpl_var name="user" -->/weblog/<!-- tmpl_var name="prev" -->">&lt;&lt;&lt; Previous</a>
	<!-- /tmpl_if -->
  </td>
  <td align="right">
	<!-- tmpl_if name='next'>
	     <a href="/users/<!-- tmpl_var name="user" -->/weblog/<!-- tmpl_var name="next" -->">Next &gt;&gt;&gt;</a>
	<!-- /tmpl_if -->
  </td>
 </tr>
</table>

</div>


	</div>
<p></p>

	<p>&nbsp;</p>
	    <!-- /tmpl_loop -->

       <!-- /tmpl_if -->


	<!-- tmpl_if name="comment_count" -->
	<h2 id="comments">Comments on this Entry</h2><p></p>
	<!-- /tmpl_if -->
        <!-- tmpl_var name="comment_text" -->

	<!-- /tmpl_if -->  <!-- matches error -->
