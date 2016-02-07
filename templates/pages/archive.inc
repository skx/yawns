
<h1>Archive for <!-- tmpl_var name='year' --></h1>

<blockquote>

  <!-- tmpl_if name='articles' -->
  <!-- tmpl_loop name='articles' -->
  <dl>
    <dt><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='slug' -->"><!-- tmpl_var name='title' --></a></dt>
    <dd><!-- tmpl_var name='teaser' --></dd>
  </dl>
  <!-- /tmpl_loop -->
  <!-- tmpl_else -->
  <p>No articles for that year.</p>
  <!-- /tmpl_if -->
</blockquote>

<!-- tmpl_if name='show_archive_year' -->
<h2>Past Years</h2>
<p>&nbsp;</p>
<ul class="list-group row">
<!-- tmpl_loop name='show_archive_year' -->
<li class="list-group-item col-xs-1"></li>
<li class="list-group-item col-xs-5"><a href="/archive/<!-- tmpl_var name='year' -->"><!-- tmpl_var name='year' --></a></li>
<!-- /tmpl_loop -->
</ul>
<!-- /tmpl_if name='show_archive_year' -->

<p>&nbsp;</p>
