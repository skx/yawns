<!-- tmpl_if name='preview' -->
  <h1>Article Preview</h1>
  <p></p>
  <div class="article">
    <h2 class="title"> <!-- tmpl_var name='preview_title' --></h2>
    <div class="tagline">Posted by <a href="/users/<!-- tmpl_var name='username' -->"><!-- tmpl_var name='username' --></a> on <!-- tmpl_var name='submit_ondate' -->  at <!-- tmpl_var name='submit_attime' --> </div>
    <div class="body">
      <!-- tmpl_var name='preview_body' -->
    </div>
  </div>
  <hr />
<!-- /tmpl_if -->


<!-- tmpl_if name='confirm' -->
<h1>Article Submitted</h1>
<p>Thank you for your submission.  It has been entered into the queue, and will be reviewed soon by our editorial volunteers.  When they approve it, it will appear on the main site for everyone to read and discuss.</p>

<!-- tmpl_unless name='anon' -->

<h2>Pending Article</h2>

<p>Until your article is published, or rejected, it will <a href="/view/submission/<!-- tmpl_var name='submission_id' -->/<!-- tmpl_var name='session' -->">be visible</a> in the article queue.</p>

<p>You're welcome to perform minor <a href="/edit/submission/<!-- tmpl_var name='submission_id' -->/<!-- tmpl_var name='session' -->">editing of your submission</a> before it is approved, or rejected.</p>
<!-- /tmpl_unless -->


<h2>Add Some Tags?</h2>
<p>Now that your article has been entered into the submission queue you can add some initial tags if you wish.</p>
<p>Tags should be short, simple, descriptive words or phrases which will help catagorise your article.</p>

<!-- tag start -->
  <!-- tmpl_include name='../includes/view_add_tag.template' -->
<!-- tag end -->


<p><a href="/">Return to the front page</a>.</p>

<!-- tmpl_else -->
<!-- tmpl_if name='new' -->
<h1>Submit An Article</h1>
<form action="/create/article" method="post">
  <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
  <input type="hidden" name="mode" value="submit_article" />
  <!-- tmpl_if name='anon' -->
  <p><b>You are currently not logged in.</b>  If you do not
    have a user account then please consider
    <a href="/create/user">creating one</a>
    and logging in before you submit your article.  By creating an account to make your submission you provide a point of contact in case any substantial editting is required.  Having an account also allows you to receive notification of any comments posted in response to it (this is optional, you may edit your preferences to enable or disable notifications.)</p>
  <!-- /tmpl_if -->
  <p>To submit your article to this site fill in all the fields below then click the 'Preview' button, if this is the first time you have submitted an article it is suggested that you <a href="/about/Contributing">read the guidelines before submitting your piece</a>.</p>

  <p>Once you have made your submission it will enter a queue where it will stay until it has been checked by the webmaster.  Most articles are posted within a few days.</p>
  <p><b>Note</b> that this is a site concerned with <a href="http://www.debian.org/">Debian GNU/Linux</a> - articles focussing upon other distributions are unlikely to be featured, unless the meat of the article is portable.</p>
  <p>Some help on <a href="/about/Entry%20Formatting">entry formatting</a> is available</p>
  <!-- tmpl_else -->
  <form action="/create/article" method="post">
    <input type="hidden" name="mode" value="submit_article" />
    <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
    <p>If the preview above is correct and you would like it to be published on the site, then click on the 'Confirm' button below.</p>
    <p>If you have minor edits to perform you may make them below, and preview again until you are happy with it.</p>
    <p><b>Title</b>: <input name="submit_title" type="text" value="<!-- tmpl_var name='submit_title' -->" size="50" maxlength="65"/></p>
    <textarea name="submit_body" cols="80" rows="40"><!-- tmpl_var name='submit_body'  --></textarea></p>
<!-- /tmpl_if -->
<!-- tmpl_if name='new' -->

<table>
  <tr><td><b>Author:</b></td><td><!-- tmpl_var name='username' --></td></tr>
  <tr><td><b>Title:</b></td><td><input name="submit_title" type="text" size="50" maxlength="65" /></td></tr>
  <tr><td colspan="2"><b>Article Body:</b></td></tr>
  <tr><td colspan="2"><textarea name="submit_body" cols="80" rows="40"></textarea></td></tr>
  <tr><td valign="top"><b>Posting Format</b></td><td>
      <!-- tmpl_include name="../includes/formatting-types.template" -->

  </td></tr>
  <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
  <tr><td></td><td><input type="submit" name="submit" value="Preview" /></td><td></td></tr>
</table>
<!-- tmpl_else -->

<table>
  <tr><td valign="top"><b>Posting Format</b></td><td>
      <!-- tmpl_include name="../includes/formatting-types.template" -->
</td></tr></table>
<p><input type="submit" name="submit" value="Preview" /> &nbsp; <input type="submit" name="submit" value="Confirm" /></p>

<p>Your article remains your own property and you retain the copyright - however by clicking on the Confirm button you do give your permission for us to publish the article here on this website along with any discussion that might arise from it.</p>
<p>This <b>does not</b> in any way stop you from republishing the article in any other locations, or websites.  It is <i>your work</i> and you may do as you wish with it.</p>
<p>We reserve the right to make minor editorial changes (spelling, grammar, formatting, etc) but will always consult with you before making any larger changes, so long as you have supplied a contact email address.</p>
<p>Some help on <a href="/about/Entry%20Formatting">entry formatting</a> is available</p>
<!-- /tmpl_if -->
<!-- /tmpl_if -->
</form>


