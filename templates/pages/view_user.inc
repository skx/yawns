<div class="container-fluid">
<!-- tmpl_if name="extra_options" -->
<p align="right">
  <!-- /tmpl_if -->
  <!-- tmpl_if name="edit_user" -->[<a href="/edit/user/<!-- tmpl_var name="viewusername" -->">Edit user</a>]<!-- /tmpl_if -->
  <!-- tmpl_if name="edit_user_permissions" -->[<a href="/edit/permissions/<!-- tmpl_var name="viewusername" -->">Edit Permissions</a>]<!-- /tmpl_if -->
  <!-- tmpl_if name='extra_options' -->
</p>
<!-- /tmpl_if -->


<!-- tmpl_if name='missing_user' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Invalid Username</h2></div>
  </div>
  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
      <p>The username you have specified <tt><!-- tmpl_var name="viewusername" --></tt> doesn't exist.</p>
    </div>
  </div>
<!-- /tmpl_if -->

<!-- tmpl_if name='suspended_user' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Suspended User</h2></div>
  </div>
  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
      <p>The user <tt><!-- tmpl_var name='viewusername' --></tt> has been suspended from this site.</p>
    </div>
  </div>
<!-- /tmpl_if -->

<!-- tmpl_if name='show_user' -->
<ol class="breadcrumb">
  <li><a href="/users/<!-- tmpl_var name="viewusername" -->/"><!-- tmpl_var name="viewusername" --></a></li>
</ol>
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-1 col-md-11">

<!-- tmpl_if name='is_owner' -->
<p>As this is your user-page you <a href="/edit/user/<!-- tmpl_var name='viewusername' -->">can change the information</a> that it is displayed here.</p>
<!-- /tmpl_if -->

<table cellspacing="5" cellpadding="5">
  <!-- tmpl_if name='showname' -->
  <tr><td><p>&nbsp;</p></td><td><p>&nbsp;</p></td></tr>
  <tr><td><b>Real name:</b></td><td><!-- tmpl_var name='realname' escape='html' --></td></tr>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='showemail' -->
  <tr><td><p>&nbsp;</p></td><td><p>&nbsp;</p></td></tr>
  <tr><td></td><td><a href="mailto:<!-- tmpl_var name='fakeemail' -->"><!-- tmpl_var name='fakeemail' --></a></td></tr>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='showurl' -->
  <tr><td><p>&nbsp;</p></td><td><p>&nbsp;</p></td></tr>
  <tr><td></td><td><a href="<!-- tmpl_var name='url' -->" rel="nofollow"><!-- tmpl_var name='url' --></a></td></tr>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='show_scratchpad'-->
  <tr><td><p>&nbsp;</p></td><td><p>&nbsp;</p></td></tr>
  <tr><td><b>Scratchpad</b></td><td>
      <a href="/users/<!--tmpl_var name='viewusername'>/scratchpad">Scratchpad</a></td>	</tr>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='show_bookmarks' -->
  <tr><td><p>&nbsp;</p></td><td><p>&nbsp;</p></td></tr>
  <tr><td></td>
    <td><a href="/users/<!-- tmpl_var name='viewusername' -->/bookmarks">Bookmarks</a></td></tr>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='weblogs'-->
  <tr><td><p>&nbsp;</p></td><td><p>&nbsp;</p></td></tr>
  <tr><td><b>Weblogs</b></td><td>
      <a href="/users/<!--tmpl_var name='viewusername'>/weblog"><!-- tmpl_var name="weblogs" --> <!-- tmpl_if name="weblog_plural" -->Entries<!-- tmpl_else -->Entry<!-- /tmpl_if --></a>
  </td>	</tr>
  <!-- /tmpl_if -->
</table>

<!-- tmpl_if name='showbio' -->
  <p>&nbsp;</p>
  <!-- tmpl_var name='bio' -->
  <p>&nbsp;</p>
<!-- /tmpl_if -->

    </div>
  </div>


  <!-- tmpl_unless name='anon' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-1 col-md-5">
      <!-- tmpl_if name='comments' -->
      <p><b>Recent comments:</b></p>
      <ul class="list-unstyled">
        <!-- tmpl_loop name='comments' -->
	<!-- tmpl_if name='is_poll'-->
        <li><a href="/polls/<!-- tmpl_var name='poll' -->#comment_<!-- tmpl_var name='id' -->"><!-- tmpl_var name='title' --></a>
	  <!-- /tmpl_if -->
	  <!-- tmpl_if name="article" -->
        <li><a href="/articles/<!-- tmpl_var name='article' -->#comment_<!-- tmpl_var name='id' -->"><!-- tmpl_var name='title' --></a>
	  <!-- /tmpl_if -->
	  <!-- tmpl_if name="weblog_link" -->
        <li><a href="<!-- tmpl_var name="weblog_link" -->#comment_<!-- tmpl_var name='id' -->"><!-- tmpl_var name='title' --></a>
	  <!-- /tmpl_if -->
          <ul>
            <li>Posted on <!-- tmpl_var name='ondate' -->.</li>
        </ul></li>
        <!-- /tmpl_loop -->
      </ul>
      <p>Total comments: <!-- tmpl_var name="comment_count" --></p>
      <p>Recent comments: <a href="/recent/comments/<!-- tmpl_var name='viewusername' escape='html'-->"><img src="/images/xml.gif" width="36" height="14" alt="Recent comments by <!-- tmpl_var name='viewusername' escape='html' -->"></a></p>
      <!-- /tmpl_if -->
    </div>

    <div class="col-sm-1 col-md-5">
      <!-- tmpl_if name='articles' -->
      <p><b>Recent articles:</b></p>
      <ul class="list-unstyled">
        <!-- tmpl_loop name='articles' -->
        <li><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='slug' -->"><!-- tmpl_var name='title' --></a>
          <ul>
            <li>Posted on <!-- tmpl_var name='ondate' -->.</li>
        </ul></li>
        <!-- /tmpl_loop -->
      </ul>
      <p>Total articles: <!-- tmpl_var name="article_count" --> <!-- tmpl_if name='edit_user' -->[<a href="/search/byauthor/<!-- tmpl_var name='viewusername' -->">View All</a>]<!-- /tmpl_if --></p>
      <!-- /tmpl_if -->
    </div>
    <div class="col-sm-1 col-md-1"></div>
  </div>
  <!-- /tmpl_unless -->
  <!-- /tmpl_if -->
</div>
