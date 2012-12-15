
<!-- tmpl_if name='confirm' -->        
  <h1>Link Added</h1>
   <p>Link added.</p>
   <p>View <a href="/articles/<!-- tmpl_var name="article_id" -->">updated article</a>.</p>

<!-- tmpl_else -->
   <h1>Add related link to <!-- tmpl_var name="article_title" --></h1>

   <form action="/" method="post">
   <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
   <table>
  <tr><td><input type="hidden" name="add_related" value="<!--tmpl_var name="article_id">" /></td><td></td></tr>
  <tr><td><b>Link: </b></td><td><input type="text" name="link" size="40" /> </td></tr>
  <tr><td></td><td></td></tr>
  <tr><td><b>Title: </b></td><td><input type="text" name="title" size="40" /> </td></tr>
  <tr><td></td><td align="right"><input type="submit" name="submit_related" value="Add" /> </td></tr>
  </table></form>

<!-- /tmpl_if name='confirm' -->


