
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

<p>&nbsp;</p>

