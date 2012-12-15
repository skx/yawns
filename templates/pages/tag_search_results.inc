<script type="text/javascript">

//
//  Reload the recent tags every few seconds
//
function loadRecent()
{
    $("#recent_tags").load("/ajax/tags/recent",
                            function (text) {
                              setTimeout("loadRecent();", 60000);
                            });
}

//
//  Start the loading on page-load
//
$(document).ready(function(){ loadRecent(); } );
</script>


<h1>Tag Search</h1>

<div class="tag_search">

<!-- tmpl_if name='empty' -->
<p>Unfortunately there are no entries tagged &quot;<!-- tmpl_var name='tag' escape='html' -->&quot;.</p>
<p>Please see the site <a href="/tag">tag cloud</a> for a list of tags which have been used.</p>
<!-- tmpl_else -->
<p>You may subscribe to a feed of items which <a href="/tag/feeds/<!-- tmpl_var name='tag' escape='html'-->">are tagged <!-- tmpl_var name='tag' escape='html' --></a>: <a href="/tag/feeds/<!-- tmpl_var name='tag' escape='html'-->"><img src="/images/xml.gif" alt="XML logo" width="36" height="14"></a></p>

<dl>

<!-- tmpl_if name='articles' -->
<dt class="toggle">Matching Articles</dt>
<dd>
 <ul>
 <!-- tmpl_loop name='articles' -->
 <li><a href="<!-- tmpl_var name='link' -->"><!-- tmpl_var name='title' --></a></li>
 <!-- /tmpl_loop -->
 </ul>
</dd>
<!-- /tmpl_if -->



<!-- tmpl_if name='polls' -->
<dt class="toggle">Matching Polls</dt>
<dd>
 <ul>
 <!-- tmpl_loop name='polls' -->
  <li><a href="<!-- tmpl_var name='link' -->"><!-- tmpl_var name='title' --></a></li>
 <!-- /tmpl_loop -->
 </ul>
 </dd>
<!-- /tmpl_if -->

<!-- tmpl_if name='submissions' -->
<dt class="toggle">Matching Submissions</dt>
<dd>
 <ul>
 <!-- tmpl_loop name='submissions' -->
 <li><a href="<!-- tmpl_var name='link' -->"><!-- tmpl_var name='title' --></a></li>
 <!-- /tmpl_loop -->
 </ul>
 </dd>
<!-- /tmpl_if -->


<!-- tmpl_if name='weblogs' -->
<dt class="toggle">Matching Weblog Entries</dt>
<dd>
 <ul>
 <!-- tmpl_loop name='weblogs' -->
 <li><a href="<!-- tmpl_var name='link' -->"><!-- tmpl_var name='title' --></a></li>
 <!-- /tmpl_loop -->
 </ul>
</dd>
<!-- /tmpl_if -->

</dl>

<!-- tmpl_if name='related_tags' -->
<h2>Related Tags</h2>
<blockquote>
<p>
<!-- tmpl_loop name='related_tags' -->
<a href="/tag/<!-- tmpl_var name='tag' escape='html' -->"><!-- tmpl_var name='tag' escape='html' --></a><!-- tmpl_if name="__last__" -->.<!-- tmpl_else -->, <!-- /tmpl_if -->
<!-- /tmpl_loop name='related_tags' -->
</p>
</blockquote>
<!-- /tmpl_if -->


<!-- /tmpl_if -->
</div>
<script src="/js/dl-toggles.js" type="text/javascript"></script>
