
<div class="container-fluid">
  <h1><!-- tmpl_var name='title' --></h1>
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11">
      <!-- tmpl_var name='article_body' -->
    </div>
  </div>

<!-- tmpl_if name="may_edit" -->
 <p>
  [
   <a href="/edit/about/<!-- tmpl_var name="title" escape="html" -->">Edit this page</a>
  |
   <a href="http://validator.w3.org/check?uri=referer">Validate Page</a>
  ]
 </p>
<!-- /tmpl_if name='may_edit'-->

</div>
