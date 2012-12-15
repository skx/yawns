
<!-- tmpl_if name='sent' -->
<h1>Message Sent</h1>

<p>Your message has been sent to <a href="/users/<!-- tmpl_var name='recipient' escape='html' -->"><!-- tmpl_var name='recipient' escape='html' --></a>.</p>

<!-- tmpl_else -->

<h1>Send A Message</h1>

<!-- tmpl_if name='empty' -->
<p>Error - you cannot send an empty message.  Please try again:</p>
<!-- /tmpl_if -->

<script>
$(document).ready (function() {
	$('textarea.expanding').autogrow({
	});

});
</script>
<form action="/create/message/<!-- tmpl_var name='recipient' -->" method="post">
 <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />

<p>To: <input type="text" name="send_message" value="<!-- tmpl_var name='recipient' -->" /></p>
<textarea name="text" rows="5" cols="60" class="expanding">
</textarea>
<p><input type="submit" name="send" value="send"></p>
</form>

<!-- /tmpl_if -->
