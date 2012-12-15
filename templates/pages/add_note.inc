
<!-- tmpl_if name='confirm' -->
<h2>Note Added</h2>
<p>You can now:</p>
<ul>
<li><a href="/view/submission/<!-- tmpl_var name='id' -->">Return to the submission</a></li>
<li><a href="/submission/list">Return to the submission list</a>.</li>
<li><a href="/">Return home</a></li>
</ul>

<!-- tmpl_else -->
<h2>Add Submission Note</h2>
<p>Here you can add a note to <a href="/view/submission/<!-- tmpl_var name='id' -->">the submission</a>.</p>

<form action="/" method="post">
<input type="hidden" name="add_submission_note" value="1" />
<input type="hidden" name="id" value="<!-- tmpl_var name='id' -->" />
<textarea rows="5" name="note" cols="50">
</textarea>
<input type="submit" name="add_note" value="Add Note">
</form>
<!-- /tmpl_if -->
