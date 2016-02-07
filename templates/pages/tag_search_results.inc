
<ol class="breadcrumb">
  <li><a href="/tag">Tags</a></li>
  <li class="current"><a href="/tag/<!-- tmpl_var name='tag' escape='html' -->"><!-- tmpl_var name='tag' escape='html' --></a></li>
</ol>


<!-- tmpl_if name='empty' -->

  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>No Results</h2></div>
  </div>

  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
    <p>Unfortunately there are no entries tagged &quot;<!-- tmpl_var name='tag' escape='html' -->&quot;.</p>
    <p>Please see the site <a href="/tag">tag cloud</a> for a list of tags which have been used.</p>
    </div>
   </div>

<!-- tmpl_else -->

<p class="right"><a href="/tag/feeds/<!-- tmpl_var name='tag' escape='html'-->"><img src="/images/xml.gif" alt="XML logo" width="36" height="14"></a></p>




<!-- tmpl_if name='articles' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Matching Articles</h2></div>
  </div>

  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
   <ul class="list-unstyled">
 <!-- tmpl_loop name='articles' -->
 <li><a href="<!-- tmpl_var name='link' -->"><!-- tmpl_var name='title' --></a></li>
 <!-- /tmpl_loop -->
 </ul>
   </div>
   </div>
<!-- /tmpl_if -->




<!-- tmpl_if name='polls' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Matching Polls</h2></div>
  </div>

  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
   <ul class="list-unstyled">
 <!-- tmpl_loop name='polls' -->
 <li><a href="<!-- tmpl_var name='link' -->"><!-- tmpl_var name='title' --></a></li>
 <!-- /tmpl_loop -->
 </ul>
   </div>
   </div>
<!-- /tmpl_if -->

<!-- tmpl_if name='submissions' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Matching Submissions</h2></div>
  </div>

  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
   <ul class="list-unstyled">
 <!-- tmpl_loop name='submissions' -->
 <li><a href="<!-- tmpl_var name='link' -->"><!-- tmpl_var name='title' --></a></li>
 <!-- /tmpl_loop -->
 </ul>
   </div>
   </div>
<!-- /tmpl_if -->



<!-- tmpl_if name='weblogs' -->
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Matching Weblogs</h2></div>
  </div>

  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
   <ul class="list-unstyled">
 <!-- tmpl_loop name='weblogs' -->
 <li><a href="<!-- tmpl_var name='link' -->"><!-- tmpl_var name='title' --></a></li>
 <!-- /tmpl_loop -->
 </ul>
   </div>
   </div>
<!-- /tmpl_if -->


<!-- tmpl_if name='related_tags' -->

  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11"><h2>Related Tags</h2></div>
  </div>

  <div class="row">
    <div class="col-sm-1 col-md-2"></div>
    <div class="col-sm-1 col-md-10">
<p>
<!-- tmpl_loop name='related_tags' -->
<a href="/tag/<!-- tmpl_var name='tag' escape='html' -->"><!-- tmpl_var name='tag' escape='html' --></a><!-- tmpl_if name="__last__" -->.<!-- tmpl_else -->, <!-- /tmpl_if -->
<!-- /tmpl_loop name='related_tags' -->
</p>
        </div></div>

<!-- /tmpl_if -->


<!-- /tmpl_if -->
</div>
