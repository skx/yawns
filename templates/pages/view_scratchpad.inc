<ol class="breadcrumb">
  <li><a href="/users/<!-- tmpl_var name="view" -->"><!-- tmpl_var name="view" --></a></li>
  <li><a href="/users/<!-- tmpl_var name="view" -->/scratchpad">Scratchpad</a></li>
</ol>

<!-- tmpl_if name="empty" -->
<div class="row">
  <div class="col-sm-1 col-md-1"></div>
  <div class="col-sm-11 col-md-10">
    <p>The scratchpad for <!-- tmpl_var name='view' --> is currently empty.</p>
  </div>
  <div class="col-sm-1 col-md-1"></div>
</row>

<!-- tmpl_else -->

<!-- tmpl_if name="edit" -->
<p>As this is your scratchpad you may <a href="/edit/scratchpad/<!-- tmpl_var name="view" -->">edit it</a>.</p>
<!-- /tmpl_if -->

<!-- tmpl_if name="private" -->
<div class="row">
  <div class="col-sm-1 col-md-1"></div>
  <div class="col-sm-11 col-md-10">
   <p>The scratchpad for <!-- tmpl_var name='view' --> is currently set to private, meaning only they can view it.</p>
  </div>
  <div class="col-sm-1 col-md-1"></div>
</div>

<!-- tmpl_else -->

<div class="row">
  <div class="col-sm-1 col-md-1"></div>
  <div class="col-sm-11 col-md-10">
   <!-- tmpl_var name='scratchpad' -->
  </div>
  <div class="col-sm-1 col-md-1"></div>
</div>
<!-- /tmpl_if -->
<!-- /tmpl_if -->
