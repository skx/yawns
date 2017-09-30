<!-- tmpl_if name='error' -->
<div class="container-fluid">
  <h1>Poll Error</h1>
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11">
      <div class="alert alert-danger">
        <p>The poll you have chosen doesn't exist, please check your links, or return to the front-page to see the current poll.</p>
        <p>&nbsp;</p>
      </div>
    </div>
  </div>
</div>
<!-- tmpl_else -->


<ol class="breadcrumb">
  <li><a href="/polls/">Polls</a></li>
  <li><a href="/polls/<!-- tmpl_var name='poll' -->">Poll #<!-- tmpl_var name='poll' --></a></li>
</ol>

<div class="container-fluid">
  <h1><!-- tmpl_var name='question' --></h1>
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-11">
      <div class="tagline"><p>Submitted by <a href="/users/<!-- tmpl_var escape='url' name='byuser' -->"><!-- tmpl_var name='byuser' --></a><!-- tmpl_if name='date' --> on <!-- tmpl_var name='ondate' --><!-- /tmpl_if --></p></div>

      <!-- tag start -->
      <!-- tmpl_include name='../includes/view_add_tag.template' -->
      <!-- tag end -->

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

    <p>&nbsp;</p>

    <!-- tmpl_if name='anon_voted' -->
    <div class="alert alert-info">
      <p>An anonymous user from your IP address (<!-- tmpl_var name='anon_voted' -->) has already voted, and so your vote has been ignored.  To avoid this problem in future, please <a href="/create/user">create a user account</a> and login.</p>
      <p>&nbsp;</p>
    </div>
    <!-- /tmpl_if -->

    <!-- tmpl_if name='prev_vote' -->
    <div class="alert alert-info">
      <p>You had already voted in this poll, for "<!-- tmpl_var name='prev_vote' -->", your vote has now been changed to "<!-- tmpl_var name='new_vote' -->".</p>
      <p>&nbsp;</p>
    </div>
    <!-- /tmpl_if -->


    <!-- tmpl_if name='enabled'-->
    <!-- /tmpl_if -->

    <p>&nbsp;</p>

    <nav>
      <ul class="pager">
        <!-- tmpl_if name='prev' -->
        <li class="previous"><a href="/polls/<!-- tmpl_var name='prev_num' -->">&lt;&lt;&lt; <!-- tmpl_var name='prev' --></a></li>
        <!-- /tmpl_if -->
        <!-- tmpl_if name='next' -->
        <li class="next"><a href="/polls/<!-- tmpl_var name='next_num' -->"><!-- tmpl_var name='next' --> &gt;&gt;&gt;</a></li>
        <!-- /tmpl_if -->
      </ul>
    </nav>
    <p>&nbsp;</p>

    <!-- tmpl_if name="comments" -->
    <!-- tmpl_var name="comment_text" -->
    <!-- /tmpl_if -->
  </div>
</div>
<!-- /tmpl_if name='error' -->
