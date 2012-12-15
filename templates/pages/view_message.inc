<!-- tmpl_if name='error' -->
<h1>Message Not Found</h1>
<p>The message you were looking for no longer exists, or belongs to another user.</p>

<!-- tmpl_else -->
<!-- tmpl_loop name='message' -->
<h1>Message from <a href="/users/<!-- tmpl_var name='from' -->"><!-- tmpl_var name='from' --></a></h1>

<!-- <p>From: <!-- tmpl_var name='to' --></p> -->
<p>Sent: <!-- tmpl_var name='sent' --></p>
<pre rows="20" cols="60" readonly="1">
<!-- tmpl_var name='text' -->
</pre>
<p>[ <a href="/view/messages">Close</a> <!-- tmpl_if name='replyable' -->| <a href="/reply/to/<!-- tmpl_var name='id' -->">Reply</a> <!-- /tmpl_if --> | <a href="/delete/message/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Delete</a> ]</p>
<!-- /tmpl_loop -->
<!-- /tmpl_if -->

<p>This facility is still new so you are encouraged to <a href="/create/message/Steve">leave feedback</a>.</p>
<p>(Old messages are automatically deleted 30 days after they are read.)</p>

