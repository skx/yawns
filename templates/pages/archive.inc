  <!-- tmpl_if name='articles' -->
      <div class="container-fluid">
        <h1>Archive for <!-- tmpl_var name='year' --></h1>
        <!-- tmpl_loop name='articles' -->
        <div class="row">
          <div class="col-sm-1 col-md-1"></div>
          <div class="col-sm-11 col-md-11">
            <h3><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='slug' -->"><!-- tmpl_var name='title' --></a></h3>
          </div>
        </div>
        <div class="row">
          <div class="col-sm-1 col-md-2"></div>
          <div class="col-sm-11 col-md-10"><!-- tmpl_var name='teaser' --></div>
        </div>
        <!-- /tmpl_loop -->
      </div>
  <!-- tmpl_else -->
  <div class="container-fluid">
    <h1>Archive for <!-- tmpl_var name='year' --></h1>
    <p>No articles for this year.</p>
  </div>
  <!-- /tmpl_if -->


<!-- tmpl_if name='show_archive_year' -->

      <div class="container-fluid">
        <h1>Previous Archives</h1>
        <p>
<!-- tmpl_loop name='show_archive_year' -->
<a href="/archive/<!-- tmpl_var name='year' -->"><!-- tmpl_var name='year' --></a><!-- tmpl_unless name="__last__" -->, <!-- /tmpl_unless -->
<!-- /tmpl_loop -->
        </p>
      </div>
<!-- /tmpl_if name='show_archive_year' -->

<p>&nbsp;</p>
