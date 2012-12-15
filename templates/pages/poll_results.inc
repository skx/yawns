                  <!-- tmpl_if name='anon_voted' -->
                  <p>    An anonymous user from your IP address 
                        (<!-- tmpl_var name='anon_voted' -->) has already 
                        voted, and so your vote has been ignored.
                  </p>
                  <p>    If you have not already voted in this poll then it 
                        was probably someone else using the same ISP as you.</p>
		  <p>To avoid this problem in future, please <a href="/create/user">create a user account</a> and login - then you will always be able to vote, and you will also be able to change your vote if you wish.</p>
		  <p>&nbsp;</p>
                  <!-- /tmpl_if -->

		  <!-- tmpl_if name='prev_vote' -->
                  <p>You had already voted in this poll, for "<!-- tmpl_var name='prev_vote' -->".</p>
		  <p>Your vote has now been changed to "<!-- tmpl_var name='new_vote' -->".</p>
                  <!-- /tmpl_if -->

		  <!-- tmpl_if name="error" -->
		  <p>The poll you have chosen doesn't exist, please check your links, or return to the front-page to see the current poll.</p>
		  <!-- tmpl_else -->

<div class="poll">

		<h3 class="title"><!-- tmpl_var name='question' --></h3>
	        <div class="tagline"><p>Submitted by <a href="/users/<!-- tmpl_var escape='url' name='byuser' -->"><!-- tmpl_var name='byuser' --></a><!-- tmpl_if name='date' --> on <!-- tmpl_var name='ondate' --><!-- /tmpl_if --></p></div>

<!-- tag start -->
  <!-- tmpl_include name='../includes/view_add_tag.template' -->
<!-- tag end -->


<p>&nbsp;</p>

                  <table class="layout">
                  <!-- tmpl_loop name='results' -->
                    <tr>
                      <td class="pollanswer">
                        <!-- tmpl_var name='answer' -->
                      </td>
                      <td class="pollresult">
                        &nbsp;<img src="/images/pollbarleft.gif" alt="&lt;" /><img src="/images/pollbar.gif" alt="-"  height="20" width="<!-- tmpl_var name='width' -->" /><img src="/images/pollbarright.gif" alt="&gt;" />&nbsp;<!-- tmpl_var name='percent' -->%</td><td align="right"><!-- tmpl_var name='votes' -->&nbsp;vote<!-- tmpl_if name='plural' -->s<!-- /tmpl_if -->
                      </td>
                    </tr>
                    <!-- /tmpl_loop -->
	<tr><td></td><td></td><td align="right">Total <!-- tmpl_var name="total" --> votes</td></tr>
                  </table>

</div>  <!-- poll -->

<p></p>

<!-- Navigation stuff -->
<div class="row">
 <span class="left">
   <!-- tmpl_if name='enabled'-->
    <a href="/comment/onpoll/<!-- tmpl_var name='poll' -->">Add Comment</a>
   <a href="/comment/feed/onpoll/<!-- tmpl_var name='poll' -->" title="Subscribe to comments on this poll."><img src="/images/xml.gif" title="Subscribe to comments on this poll." alt="XML logo" width="36" height="14"></a>
   <!-- /tmpl_if -->
 </span>
 <span class="right">
 </span>
 <div class="spacer"> </div>
</div>

<div class="row">
 <span class="left" style="white-space: nowrap;">
  <!-- tmpl_if name='prev' -->
   <a href="/polls/<!-- tmpl_var name='prev_num' -->">&lt;&lt;&lt; <!-- tmpl_var name='prev' --></a>
  <!-- /tmpl_if -->
 </span>
 <span class="right" style="white-space: nowrap;">
  <!-- tmpl_if name='next' -->
   <a href="/polls/<!-- tmpl_var name='next_num' -->"><!-- tmpl_var name='next' --> &gt;&gt;&gt;</a>
  <!-- /tmpl_if -->
 </span>
 <div class="spacer"> </div>
</div>
<p></p>
		  <!-- /tmpl_if -->

<!-- tmpl_if name="comments" -->
  <!-- tmpl_var name="comment_text" -->
<!-- /tmpl_if -->
