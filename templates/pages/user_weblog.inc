<div class="container-fluid">
  <!-- tmpl_if name="error" -->
  <h1>No Entries Found</h1>
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-10">
      <!-- tmpl_if name='is_owner' -->
      <p>You've not yet written any weblog entries, but if you like you may <a href="/create/weblog">create a new entry</a>.</p>
      <!-- tmpl_else -->
      <p><a href="/users/<!-- tmpl_var name='viewusername' escape='html' -->"><!-- tmpl_var name='viewusername' escape='html' --></a> has made no weblog entries.</p>
      <!-- /tmpl_if -->
    </div>
    <div class="col-sm-1 col-md-1"></div>
  </div>
  <!-- tmpl_else -->

  <h1>Weblogs for <!-- tmpl_var name='viewusername' --></h1>
  <!-- tmpl_if name='entries' --> <p class="right"> <a href="/weblog/feeds/<!-- tmpl_var name="viewusername" -->"><img src="/images/xml.gif" alt="XML Logo" width="36" height="14"></a></p> <!-- /tmpl_if -->

  <!-- tmpl_if name='is_owner' -->
  <p>As this is your weblog you may <a href="/create/weblog">create a new entry</a>.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_loop name='entries' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-10">
      <div class="weblog">
        <!-- link -->
        <div class="link">#<a href="/users/<!-- tmpl_var escape='url' name='user' -->/weblog/<!-- tmpl_var name='item_id' -->"><!-- tmpl_var name='item_id' --></a></div>
        <!-- title -->
	<div class="title"><!-- tmpl_if name="title" --><a href="/users/<!-- tmpl_var name="user" -->/weblog/<!-- tmpl_var name="item_id" -->"><!-- tmpl_var name='title' --></a><!-- /tmpl_if --> </div>
        <!-- tagline -->
	<div class="tagline">Posted by <a href="/users/<!-- tmpl_var escape='url' name='user' -->"><!-- tmpl_var name='user' --></a> on <!-- tmpl_var name='ondate' --> at <!-- tmpl_var name='attime' --></div>
	<div class="tags"><span id="current_tags_<!-- tmpl_var name='item_id' -->">
            <!-- tmpl_include name="../includes/tags.template" -->
        </span></div>
	<div class="body">
          <!-- tmpl_var name='bodytext' -->
	</div>

	<div class="links">
          [<!-- tmpl_if name="comment_count" --><a href="/users/<!-- tmpl_var name="user" -->/weblog/<!-- tmpl_var name="item_id" -->#comments"><!-- tmpl_var name="comment_count" --> Comment<!-- tmpl_if name="plural" -->s<!-- /tmpl_if --></a>  <!-- tmpl_else -->0 Comments <!-- /tmpl_if -->
	  <!-- tmpl_if name="comments_enabled" -->
          | <a href="/comment/onweblog/<!-- tmpl_var name="gid" -->">Add Comment</a>
          <!-- /tmpl_if -->
          | <a href="/comment/feed/onweblog/<!-- tmpl_var name='gid' -->" title="Subscribe to comments on this weblog entry."><img src="/images/xml.gif" title="Subscribe to comments on this weblog entry." alt="XML logo" width="36" height="14"></a>
          ]
	</div>

      </div>
    </div>
    <div class="col-sm-1 col-md-1"></div>

  </div>
  <p>&nbsp;</p>
  <!-- /tmpl_loop -->

  <nav>
    <ul class="pager">
      <!-- tmpl_if name='show_prev' -->
      <li class="previous"><a href="/users/<!-- tmpl_var name='viewusername' -->/weblog/start/<!-- tmpl_var name='show_prev' -->"><span aria-hidden="true">&larr;</span> Older</a></li>
      <!-- /tmpl_if -->
      <!-- tmpl_if name='show_next' -->
      <li class="next"><a href="/users/<!-- tmpl_var name='viewusername' -->/weblog/start/<!-- tmpl_var name='show_next' -->">Newer <span aria-hidden="true">&rarr;</span></a></li>
      <!-- /tmpl_if -->
    </ul>
  </nav>
  <!-- /tmpl_if -->  <!-- matches error -->

</div>
