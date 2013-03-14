<!-- tmpl_if name='terms' -->
<h1>Search results: <!-- tmpl_var name='terms' escape='html' --></h1>
<!-- tmpl_else -->
<h1>Site Search</h1>
<!-- /tmpl_if -->

<!-- tmpl_if name='terms' -->
<blockquote>
<ul>
<!-- tmpl_loop name='results' -->
 <li><a href="/article/<!-- tmpl_var name='id' -->/"><!-- tmpl_var name='title' escape='html' --></a></li>
<!-- /tmpl_loop -->
</ul>
</blockquote>
<!-- /tmpl_if -->

<blockquote>
 <form method="post" action="/">
  <input type="hidden" name="search" value="1">
  <input type="text" name="q" value="<!-- tmpl_if name='terms' --><!-- tmpl_var name='terms' escape='html' --><!-- /tmpl_if -->">
  <input type="submit" name="sbt" value="search">
 </form>
</blockquote>
