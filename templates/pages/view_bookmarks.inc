<ol class="breadcrumb">
  <li><a href="/users/<!-- tmpl_var name="viewusername" -->"><!-- tmpl_var name="viewusername" --></a></li>
  <li><a href="/users/<!-- tmpl_var name="viewusername" -->/bookmarks">Bookmarks</a></li>
</ol>

<div class="container-fluid">

<!-- tmpl_if name='has_bookmarks' -->


<!-- tmpl_if name='article_bookmarks' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Bookmarked Articles</h2></div>
  </div>

  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
   <ul class="list-unstyled">
   <!-- tmpl_loop name='article_bookmarks' -->
   <li><a href="/article/<!-- tmpl_var name='uid' -->/<!-- tmpl_var name='slug' -->"><!-- tmpl_var name='title' --></a> <!-- tmpl_if name='delete' -->[<a href="/delete/bookmark/<!-- tmpl_var name='gid' -->/<!-- tmpl_var name='session' -->" title="Delete this bookmark">x</a>]<!-- /tmpl_if --></li>
   <!-- /tmpl_loop -->
   </ul>
   </div></div>
   <!-- /tmpl_if -->

   <!-- tmpl_if name='poll_bookmarks' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Bookmarked Polls</h2></div>
  </div>

  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
   <ul class="list-unstyled">
   <!-- tmpl_loop name='poll_bookmarks' -->
   <li><a href="/polls/<!-- tmpl_var name='id' -->"><!-- tmpl_var name='title' --></a> <!-- tmpl_if name='delete' -->[<a href="/delete/bookmark/<!-- tmpl_var name='gid' -->/<!-- tmpl_var name='session' -->" title="Delete this bookmark">x</a>]<!-- /tmpl_if --></li>
   <!-- /tmpl_loop -->
  </ul>
   </div></div>
  <!-- /tmpl_if -->

   <!-- tmpl_if name='weblog_bookmarks' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Bookmarked Weblogs</h2></div>
  </div>

  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
   <ul class="list-unstyled">
   <!-- tmpl_loop name='weblog_bookmarks' -->
   <li><a href="/users/<!-- tmpl_var name='owner' -->/weblog/<!-- tmpl_var name='link' -->"><!-- tmpl_var name='title' --></a> <!-- tmpl_if name='delete' -->[<a href="/delete/bookmark/<!-- tmpl_var name='gid' -->/<!-- tmpl_var name='session' -->" title="Delete this bookmark">x</a>]<!-- /tmpl_if --></li>
   <!-- /tmpl_loop -->
   </ul>
   </div></div>
   <!-- /tmpl_if -->

<!-- tmpl_else -->

<!-- tmpl_if name='is_owner' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>No Bookmarks</h2></div>
  </div>

  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
     <p>You have no bookmarks defined.</p>
    </div>
   </div>
<!-- tmpl_else -->

  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>No Bookmarks</h2></div>
  </div>

  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
     <p>The user <a href="/users/<!-- tmpl_var name='viewusername' -->"><!-- tmpl_var name='viewusername' --></a> has no bookmarks.</p>
    </div>
   </div>
<!-- /tmpl_if -->

<!-- /tmpl_if -->
</div>
