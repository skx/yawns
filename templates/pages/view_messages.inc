
<script type="text/javascript">


//
//  View a specific message.
//
function viewMessage(id)
{
    //
    //  Are we closing?
    //
    if ( ! $('#msg_'  +id ).is(':hidden') )
    {
        // Hide the message.
	$("#msg_" + id).hide();
        $("#body_" + id).val( "" );

        // Finished.
        return;
    }
    else
    {
        //  close all open messages
        $(".message").hide()
    }
    $("#progress_" + id ).show();


    //
    // Make an AJAX request.
    //
    $("#body_" + id).load(
                      "/ajax/getmessage/" + id ,
                      function() {
                      $("#status_" + id).val( "" );
                      $("#msg_" + id).show();
                      $("#progress_" + id ).hide() } );
 }
</script>

<h1>Messages for <!-- tmpl_var name='username' --></h1>

<!-- tmpl_if name='empty' -->
<p>You have no site messages to display.</p>

<!-- tmpl_else -->
<p>Here you can see the site messages which have been sent to you:</p>

<table class="messages" width="80%" cellspacing="0">
  <tr class="header"><th><b>From</b></th><th class="messageleft"><b>Received</b></th><th class="messageleft"><b>Replied</b></th></tr>
<!-- tmpl_loop name='messages' -->

 <tr onmouseover="this.bgColor='yellow'; this.style.cursor='pointer';" onmouseout="this.bgColor='white'" onClick="viewMessage(  <!-- tmpl_var name='id' -->); return false">
  <td><a href="/view/message/<!-- tmpl_var name='id' -->" onClick="viewMessage(  <!-- tmpl_var name='id' -->); return false;"><!-- tmpl_var name='from' escape="html" --></a> <span id='status_<!-- tmpl_var name='id' -->' style="color: red;"><!-- tmpl_if name='new' -->New!<!-- /tmpl_if --></span> <span id="progress_<!-- tmpl_var name='id' -->" style="display: none;"><img src="/images/progress.gif" alt="Loading .."/></span>
</td>
  <td class="messageleft"><!-- tmpl_var name='sent' --></td>
  <td class="messageleft"><!-- tmpl_if name='replied' --><!-- tmpl_var name='replied' --><!-- /tmpl_if --></td>
 </tr>
 <tr>
  <td colspan="3">
<div style="display: none;" id="msg_<!-- tmpl_var name='id' -->" class="message">
<pre id="body_<!-- tmpl_var name='id' -->" rows="20" readonly="1" cols="70">
</pre>
<p>[ <a href="/view/message/<!-- tmpl_var name='id' -->">View Message</a> <!-- tmpl_if name='replyable' -->| <a href="/reply/to/<!-- tmpl_var name='id' -->" onClick="$('#reply_'+<!-- tmpl_var name='id' -->).show(); return false;">Reply</a><!-- /tmpl_if --> | <a href="/delete/message/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Delete</a> ]</p>

<div id="reply_<!-- tmpl_var name='id' -->" style="display: none;">

  <form action="/reply/to/<!-- tmpl_var name='id' -->" method="post" name="reply_form_<!-- tmpl_var name='id' -->">
  <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />

  <input type="hidden" name="message_reply" value="<!-- tmpl_var name='id' -->" />
  <input type="hidden" name="send" value="send" />
<textarea name="text" style="width: 90%" rows="7">
</textarea>
 <p>[ <a href="" onClick="document.reply_form_<!-- tmpl_var name='id' -->.submit(); $('#reply_' + <!-- tmpl_var name='id' -->).hide(); return false;" >Send Reply</a> | <a href="" onClick="$('#reply_' + <!-- tmpl_var name='id' -->).hide(); return false;">Cancel Reply</a> ]</p>

  </form>
</div>
</td>
</div>
 </tr>
<!-- /tmpl_loop -->
  </table>

<!-- /tmpl_if -->

<p>This facility is still new so you are encouraged to <a href="/create/message/Steve">leave feedback</a>.</p>
<p>(Old messages are automatically deleted 30 days after they are read.)</p>
