<!-- tmpl_if name='updated' -->

<h1>Poll Updated</h1>

<p>Poll <!-- tmpl_var name='poll_id' --> has been updated.</p>
<p>Return the the <a href="/submissions/polls">pending poll list</a>.</p>

<!-- tmpl_else -->
       <h1>Edit Poll</h1>

<form action="/" method="post">
<input type="hidden" name="mode" value="poll_edit" />
<input type="hidden" name="id"        value="<!-- tmpl_var name='poll_id' -->" />
<input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
<table>
<tr><td>Question</td><td><input type="text" name="question" value="<!-- tmpl_var name='question' escape='html' -->"</td></tr>
<tr><td>By</td><td><input type="text" name="author" value="<!-- tmpl_var name='author' escape='html' -->"</td></tr>
<tr><td valign="top">Answers</td><td valign="top">
<!-- tmpl_loop name='answers' -->
<!-- tmpl_var name='id' --> <input type="text" name="answer_<!-- tmpl_var name='id' -->" value="<!-- tmpl_var name='answer' escape='html' -->" size="30"> <br />
<!-- /tmpl_loop -->
</td></tr>
</table>
<input type="submit" name="submit" value="Update Poll" />
</form>

<!-- /tmpl_if -->
