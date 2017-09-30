
<!-- tmpl_if name="error" -->
<ol class="breadcrumb">
  <li><a href="/users/<!-- tmpl_var name="user" -->/"><!-- tmpl_var name="user" --></a></li>
  <li><a href="/users/<!-- tmpl_var name="user" -->/weblog">Blog</a></li>
  <li class="active"><a href="/users/<!-- tmpl_var name='user' -->/weblog/<!-- tmpl_var name='item' -->">#<!-- tmpl_var name="item" --></a></li>
</ol>

<div class="row">
  <div class="col-sm-1 col-md-1"></div>
  <div class="col-sm-11 col-md-10">
  <p>The weblog entry you are trying to reach does not exist!</p>
  </div>
  <div class="col-sm-1 col-md-1"></div>
</div>

<!-- tmpl_else -->

<ol class="breadcrumb">
  <li><a href="/users/<!-- tmpl_var name="user" -->"><!-- tmpl_var name="user" --></a></li>
  <li><a href="/users/<!-- tmpl_var name="user" -->/weblog">Blog</a></li>
  <li class="active"><a href="/users/<!-- tmpl_var name='user' -->/weblog/<!-- tmpl_var name='item' -->">#<!-- tmpl_var name="item" --></a></li>
</ol>

<p align="right"> <a href="/weblog/feeds/<!-- tmpl_var name="user" -->"><img src="/images/xml.gif" alt="XML logo" width="36" height="14"></a></p>

<!-- tmpl_if name='entries' -->
<!-- tmpl_loop name='entries' -->
<div class="row">
  <div class="col-sm-1 col-md-1"></div>
  <div class="col-sm-11 col-md-10">
    <div class="weblog">
      <div class="link">#<a href="/users/<!-- tmpl_var escape='url' name='user' -->/weblog/<!-- tmpl_var name='item_id' -->"><!-- tmpl_var name='item_id' --></a></div>
      <div class="title"><!-- tmpl_if name="title" --><!-- tmpl_var name='title' --><!-- /tmpl_if --> </div>
      <div class="tagline">Posted by <a href="/users/<!-- tmpl_var escape='url' name='user' -->"><!-- tmpl_var name='user' --></a> on <!-- tmpl_var name='ondate' --> at <!-- tmpl_var name='attime' --> <!-- tmpl_if name="edit" --><a href="/delete/weblog/<!-- tmpl_var name="item_id" -->">Delete</a> / <a href="/edit/weblog/<!-- tmpl_var name="item_id" -->">Edit</a><!-- /tmpl_if --></div>
      <!-- tmpl_include name='../includes/view_add_tag.template' -->
      <div class="body"><!-- tmpl_var name='bodytext' --></div>
      <div class="links">
        [<!-- tmpl_if name="comment_count" --><a href="#comments"><!-- tmpl_var name="comment_count" --> Comment<!-- tmpl_if name="plural" -->s<!-- /tmpl_if --></a>  <!-- tmpl_else -->0 Comments <!-- /tmpl_if -->
        <!-- tmpl_if name='reportable' -->
        | <a href="/report/weblog/<!-- tmpl_var name='gid' -->/<!-- tmpl_var name='session' -->" onClick="return( confirm('Are you sure you wish to flag this weblog entry for review?') );" >Report Entry</a>
        <!-- /tmpl_if -->
	<!-- tmpl_if name="comments_enabled" -->
        <!-- /tmpl_if -->
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
	           <a href="/users/<!-- tmpl_var name='user' -->/weblog/<!-- tmpl_var name='next' -->">Next &gt;&gt;&gt;</a>
              <!-- /tmpl_if -->
            </td>
          </tr>
        </table>
      </div>
    </div>
    <div class="col-sm-1 col-md-1"></div>
  </div>
</div>
<p>&nbsp;</p>

<!-- /tmpl_loop -->

<!-- /tmpl_if -->


  <!-- tmpl_if name="comment_count" -->
  <h1 id="comments">Comments on this Entry</h1><p></p>
  <!-- /tmpl_if -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-10"><!-- tmpl_var name="comment_text" --></div>
    <div class="col-sm-1 col-md-1"></div>
  </div>

  <!-- /tmpl_if -->  <!-- matches error -->
