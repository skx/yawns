<ol class="breadcrumb">
  <li><a href="/polls/">Polls</a></li>
  <li><a href="/polls/<!-- tmpl_var name='poll' -->">Poll #<!-- tmpl_var name='poll' --></a></li>
</ol>


<div class="container-fluid">
  <h1>Archive for <!-- tmpl_var name='year' --></h1>
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11">
      <ul>
        <!-- tmpl_loop name='poll_archive' -->
        <li><a href="/polls/<!-- tmpl_var name='id' -->"><!-- tmpl_var name='question' --></a></li>
        <!-- /tmpl_loop -->
      </ul>
    </div>
  </div>
</div>
