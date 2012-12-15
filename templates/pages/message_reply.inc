<script>
$(document).ready (function() {
	$('textarea.expanding').autogrow({
	});

});
</script>

<h1>Reply to <a href="/view/message/<!-- tmpl_var name='id' -->">message</a> from <a href="/users/<!-- tmpl_var name='sender' escape='html' -->"><!-- tmpl_var name='sender' escape='html' --></a></h1>
<!-- tmpl_if name='empty' -->
<p>You cannot send an empty reply!</p>
<!-- /tmpl_if -->
<p></p>

<form action="/reply/to/<!-- tmpl_var name='id' -->" method="post">
 <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />

 <input type="hidden" name="message_reply" value="<!-- tmpl_var name='id' -->">

<textarea name="text" rows="5" class="expanding" cols="60">
</textarea>
<p><input type="submit" name="send" value="send"></p>
</form>

<p>This facility is still new so you are encouraged to <a href="/create/message/Steve">leave feedback</a>.</p>
