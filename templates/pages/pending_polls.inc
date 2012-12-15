      <h1>Poll Submissions</h1>

	<p>These are the pending polls.  They will remain in this queue until they are posted to the front-page or rejected.</p>

      <!-- tmpl_if name='polls' -->

      <!-- tmpl_loop name='polls' -->

<div class="pending_polls">
 <div class="title"><!-- tmpl_var name='question' --></div>
  <div class="tagline">By <a href="/users/<!-- tmpl_var escape='URL' name='author' -->"><!-- tmpl_var name='author' --></a> submitted on <!-- tmpl_var name='ondate' --> <!-- tmpl_if name="ip" -->[<!-- tmpl_var name="ip" -->]<!-- /tmpl_if --></div>

  <div class="answers">
        <table>
<!-- tmpl_loop name='poll_answers' -->
        <tr><td><!-- tmpl_var name='id' -->. <!-- tmpl_var name='answer' -->
           </td>
           <td class="pollresult">
           &nbsp;<img src="/images/pollbarleft.gif" alt="&lt;" /><img src="/images/pollbar.gif" alt="-"  height="20" width="<!-- tmpl_var name='width' -->" /><img src="/images/pollbarright.gif" alt="&gt;" /></td>
	</tr>
<!-- /tmpl_loop -->
        </table>
  </div>

   <div class="admin">
           [ <a href="/submissions/polls/edit/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Edit</a> |
           <a href="/submissions/polls/delete/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Delete</a> |
           <a href="/submissions/polls/post/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Post</a> ]
   </div>
 </div>
<p></p>
     <!-- /tmpl_loop -->

      <!-- tmpl_else -->
	<h2>No Pending Polls</h2>
	<p>There are no pending polls, why not <a href="/create/poll">create one</a>?</p>
      <!-- /tmpl_if -->
