<div class="container-fluid">
  <h1 id="heading">Tag Cloud</h1>
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-10">

<!-- tmpl_if name='all_tags' -->

    <div id="all_tags"><p><!-- tmpl_include name='../includes/all_tags.template' --></p></div>

<!-- tmpl_else -->
      <p>No tags have been added to this site yet.</p>
<!-- /tmpl_if -->

   </div>
   <div class="col-sm-1 col-md-1"></div>
   </div>
   </div>
