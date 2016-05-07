
<!-- tmpl_if name='confirm' -->
 <h2 class="title">Article Updated</h2>

 <p><a href="/">Return to the front page</a> or go to the updated <a href="/articles/<!-- tmpl_var name='article_id'-->"><!-- tmpl_var name='edit_title'--></a> article.</p>
 <!-- tmpl_else -->
 <h2 class="title">Edit Article</h2>
   <form action="/edit/article/<!-- tmpl_var name='article_id' -->" method="post">
   <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
   <input type="hidden" name="mode" value="edit_article" />

   <p>Please make your changes to the article,  once you are happy with your changes click on 'Confirm' to save them.</p>
   <p>When an article is editted both the webmaster and the author of the article will be sent an email containing a context-diff of the changes applied.</p>
   <input name="edit_ondate" type="hidden" value="<!-- tmpl_var name='edit_ondate' -->" />
   <input name="edit_attime" type="hidden" value="<!-- tmpl_var name='edit_attime' -->" />
                  <input name="id" type="hidden" value="<!-- tmpl_var name="article_id"-->" />
   <p><b>Author:</b>
   <br /><input name="edit_username" type="text" size="66" maxlength="66" value="<!-- tmpl_var name='edit_username' -->" /></p>

   <p><b>Title:</b><br />
   <input name="edit_title" type="text" size="66" maxlength="66" value="<!-- tmpl_var name='edit_title' -->" /></p>

   <p><b>Note</b>:  Please do not edit the initial paragraph - this is used for display upon the front page, and in the RSS feed.</p>
   <textarea name="edit_body" cols="120" rows="40"><!-- tmpl_var name='edit_body' escape='html'  --></textarea></p>

   <p><input type="submit" name="stage" value="Confirm" /> </p>
   <!-- /tmpl_if -->
   </form>
