<!-- tmpl_if name='bogus' -->
      <h1>Poll Ignored</h1>
<p>Poll questions, and answers, should not contain HTML markup or links.</p>
<p>Your submission has been rejected.</p>

<!-- tmpl_else -->

      <!-- tmpl_if name='confirm' -->
      <h1>Poll Submitted</h1>
      <p>Polls are typically changed after either a week of no significant activity, or after 1000 votes have been cast.</p>
      <p>This may mean that your poll is not going to be used for some time, so your patience is appreciated.</p>
      <!-- tmpl_else -->

      <!-- tmpl_if name="preview" -->

      <!-- tmpl_if name="error" -->
       <h1>Poll Blank</h1>
       <p>The poll you submitted had no question, or was missing several
         answers.</p>
       <p>Please correct this mistake and submit again.</p>

      <!-- tmpl_else -->

      <h1>Poll Preview</h1>
      <p>Here is what your poll looks like, if you are happy with it please confirm your submission.  Otherwise you may repeat your preview until you are happy with it.</p>

	<h3>&nbsp;<!-- tmpl_var name='question' --></h3>
        <p style="text-align:right;">By <a href="/users/<!-- tmpl_var escape='url' name='author' -->"><!-- tmpl_var name='author' --></a></p>

	<table>
	<!-- tmpl_if name='answer1' -->
        <tr><td><!-- tmpl_var name='answer1' --></td>
                      <td class="pollresult">
                        &nbsp;<img src="/images/pollbarleft.gif" alt="&lt;" /><img src="/images/pollbar.gif" alt="-"  height="20" width="20" /><img src="/images/pollbarright.gif" alt="&gt;" /></td>
	</tr>
	<!-- /tmpl_if -->
	<!-- tmpl_if name='answer2' -->
        <tr><td><!-- tmpl_var name='answer2' --></td>
                      <td class="pollresult">
                        &nbsp;<img src="/images/pollbarleft.gif" alt="&lt;" /><img src="/images/pollbar.gif" alt="-"  height="20" width="40" /><img src="/images/pollbarright.gif" alt="&gt;" /></td>
	</tr>
	<!-- /tmpl_if -->
	<!-- tmpl_if name='answer3' -->
        <tr><td><!-- tmpl_var name='answer3' --></td>
                      <td class="pollresult">
                        &nbsp;<img src="/images/pollbarleft.gif" alt="&lt;" /><img src="/images/pollbar.gif" alt="-"  height="20" width="60" /><img src="/images/pollbarright.gif" alt="&gt;" /></td>
	</tr>
	<!-- /tmpl_if -->
	<!-- tmpl_if name='answer4' -->
        <tr><td><!-- tmpl_var name='answer4' --></td>
                      <td class="pollresult">
                        &nbsp;<img src="/images/pollbarleft.gif" alt="&lt;" /><img src="/images/pollbar.gif" alt="-"  height="20" width="80" /><img src="/images/pollbarright.gif" alt="&gt;" /></td>
	</tr>
	<!-- /tmpl_if -->
	<!-- tmpl_if name='answer5' -->
        <tr><td><!-- tmpl_var name='answer5' --></td>
                      <td class="pollresult">
                        &nbsp;<img src="/images/pollbarleft.gif" alt="&lt;" /><img src="/images/pollbar.gif" alt="-"  height="20" width="100" /><img src="/images/pollbarright.gif" alt="&gt;" /></td>
	</tr>
	<!-- /tmpl_if -->
	<!-- tmpl_if name='answer6' -->
        <tr><td><!-- tmpl_var name='answer6' --></td>
                      <td class="pollresult">
                        &nbsp;<img src="/images/pollbarleft.gif" alt="&lt;" /><img src="/images/pollbar.gif" alt="-"  height="20" width="120" /><img src="/images/pollbarright.gif" alt="&gt;" /></td>
	</tr>
	<!-- /tmpl_if -->
	<!-- tmpl_if name='answer7' -->
        <tr><td><!-- tmpl_var name='answer7' --></td>
                      <td class="pollresult">
                        &nbsp;<img src="/images/pollbarleft.gif" alt="&lt;" /><img src="/images/pollbar.gif" alt="-"  height="20" width="140" /><img src="/images/pollbarright.gif" alt="&gt;" /></td>
	</tr>
	<!-- /tmpl_if -->
	<!-- tmpl_if name='answer8' -->
        <tr><td><!-- tmpl_var name='answer8' --></td>
                      <td class="pollresult">
                        &nbsp;<img src="/images/pollbarleft.gif" alt="&lt;" /><img src="/images/pollbar.gif" alt="-"  height="20" width="160" /><img src="/images/pollbarright.gif" alt="&gt;" /></td>
	</tr>
	<!-- /tmpl_if -->
	</table>
        <!-- /tmpl_if -->
	<hr />

      <!-- tmpl_else -->
      <h1>Submit A Poll</h1>
      <p>Here you can submit a poll for inclusion upon this site.  Polls are typically posted every time there are more than 1000 votes upon the current poll, or after ten days.</p>
      <p>Please consider your audience before suggesting a poll to ensure it will be either relevant or interesting to them.</p>

      <!-- /tmpl_if -->
  <form action="/create/poll" method="post">
  <input type="hidden" name="mode" value="submit_poll" />
  <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
  <dl>
  <dt>Poll question:</dt>
  <dd><input type="text" name="question" value="<!-- tmpl_var name="question" -->" size="40" /></dd>
  <dt>Choice 1:</dt>
  <dd><input type="text" name="answer1"  value="<!-- tmpl_var name="answer1" -->" size="40" /></dd>
  <dt>Choice 2:</dt>
  <dd><input type="text" name="answer2"  value="<!-- tmpl_var name="answer2" -->"  size="40" /></dd>
  <dt>Choice 3:</dt>
  <dd><input type="text" name="answer3" value="<!-- tmpl_var name="answer3" -->"  size="40" /></dd>
  <dt>Choice 4:</dt>
  <dd><input type="text" name="answer4" value="<!-- tmpl_var name="answer4" -->"  size="40" /></dd>
  <dt>Choice 5:</dt>
  <dd><input type="text" name="answer5" value="<!-- tmpl_var name="answer5" -->"  size="40" /></dd>
  <dt>Choice 6:</dt>
  <dd><input type="text" name="answer6" value="<!-- tmpl_var name="answer6" -->"  size="40" /></dd>
  <dt>Choice 7:</dt>
  <dd><input type="text" name="answer7" value="<!-- tmpl_var name="answer7" -->"  size="40" /></dd>
  <dt>Choice 8:</dt>
  <dd><input type="text" name="answer8" value="<!-- tmpl_var name="answer8" -->"  size="40" /></dd>
  <dt></dt>
  <dd><input type="submit" name="submit" value="Preview">
  <!-- tmpl_if name='preview' -->
  <!-- tmpl_if name='error' -->
  <!-- tmpl_else -->
   <input type="submit" name="submit" value="Confirm">
  <!-- /tmpl_if -->
  <!-- /tmpl_if -->
 </dd>
  </dl>

  </form>
	<!-- /tmpl_if -->
<!-- /tmpl_if -->
