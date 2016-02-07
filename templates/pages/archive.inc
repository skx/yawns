

<blockquote>

  <!-- tmpl_if name='articles' -->
  <!-- tmpl_loop name='articles' -->
      <div class="container-fluid">
        <h1>Archive for <!-- tmpl_var name='year' --></h1>
        <div class="row">
          <div class="col-sm-1 col-md-1"></div>
          <div class="col-sm-11 col-md-11">
            <h2><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='slug' -->"><!-- tmpl_var name='title' --></a></h2>
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
</blockquote>

<!-- tmpl_if name='show_archive_year' -->
<h2>Past Years</h2>
<p>&nbsp;</p>
<ul>
<!-- tmpl_loop name='show_archive_year' -->
<li><a href="/archive/<!-- tmpl_var name='year' -->"><!-- tmpl_var name='year' --></a></li>
<!-- /tmpl_loop -->
</ul>
</blockquote>
<!-- /tmpl_if name='show_archive_year' -->

<p>&nbsp;</p>
