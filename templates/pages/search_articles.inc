<!-- tmpl_if name='submit' -->

<h1>Search results: <!-- tmpl_var name='terms' escape='html' --></h1>
<blockquote>
<ul>
<!-- tmpl_loop name='results' -->
 <li><a href="/article/<!-- tmpl_var name='id' -->/"><!-- tmpl_var name='title' escape='html' --></a></li>
<!-- /tmpl_loop -->
</ul>
</blockquote>
<!-- tmpl_else -->
<h1>Site Search</h1>
<blockquote>
 <form method="post" action="/">
  <input type="hidden" name="search" value="1">
  <input type="text" name="q" value="">
  <input type="submit" name="sbt" value="search">
 </form>
</blockquote>
<!-- /tmpl_if name='may_edit'-->
