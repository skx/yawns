<!-- tmpl_if name='custom_error' -->
  <!-- tmpl_if name='no_such_user' -->
  <h1>No Such User</h1>
  <p>The specified username does not exist.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='suspended' -->
  <h1>Suspended</h1>
  <p>You've been suspended.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='invalid_session' -->
  <h1>Invalid Form Submission</h1>
  <p>The form submission you made was invalid, due to a missing/incorrect session token.</p>
  <p>Please <a href="/users/Steve">report a bug</a> if you think you're seeing this in error.</p>
  <h2>Cookies Required</h2>
  <p>To use this site you must have cookies enabled; if you have them disabled this would explain the failure above.</p>
  <p>I will endeavor to update thing so that this is no longer a requirement in the near future, however this is <i>not</i> a priority, so it may take a while to happen.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='session_ip_changed' -->
  <h1>IP Address Changed</h1>
  <p>You chose to login to this site in a secure manner.  This means that your login session is tied to your IP address.</p>
  <p>The IP address of your current connection doesn't match that you had when you logged in initially (<!-- tmpl_var name='session_ip' escape='html' -->).</p>
  <!-- /tmpl_if -->


  <!-- tmpl_if name='comment_reported' -->
  <h1>Thank You</h1>
  <p>The comment has now been flagged and if enough other site users report it then it will be removed shortly.</p>
  <p>Otherwise a site administrator will take a look at it shortly.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='weblog_reported' -->
  <h1>Thank You</h1>
  <p>The weblog entry has now been flagged as potentially abusive, spamming, or otherwise unsuitable.</p>
  <p>Entries will never be deleted, however those which are flagged will be hidden from the sites display by default.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='submission_posted' -->
  <h1>Submission Posted</h1>
  <p>The specified article has now been posted live to the <a href="/">front page</a>.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='submission_rejected' -->
  <h1>Submission Deleted</h1>
  <p>The specified article has now been removed from the <a href="/submission/list">submissions queue</a>.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='advert_deleted' -->
  <h1>Advert Deleted</h1>
  <p>The advert has now been removed and deleted.</p>
  <p>See the <a href="/adverts/pending">updated advert list</a>.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='advert_enabled' -->
  <h1>Advert Enabled</h1>
  <p>The advert has now been enabled, and will be in circulation shortly.</p>
  <p>See the <a href="/adverts/all">enabled adverts</a>.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='advert_disabled' -->
  <h1>Advert Disabled</h1>
  <p>The advert has now been disabled, and will no longer be shown.</p>
  <p>See the <a href="/adverts/all">enabled adverts</a>.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='too_fast' -->
<h1>Slow Down</h1>
<p>It has been less than a minute (60 seconds) since your last comment was successfully posted.  Please wait a while before attempting to post a new comment.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='already_logged_in' -->
  <h1>Already Logged In!</h1>
  <p>You're attempting to conduct an operation that shouldn't be conducted by a logged in user.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='load_too_high' -->
  <h1>Server On Fire!</h1>
  <p>The load upon this server is currently too high to service your request, so it has been denied in the interests of security.</p>
  <p>Please retry your request again later.</p>

  <!-- /tmpl_if -->

  <!-- tmpl_if name='admin_only' -->
  <h1>Restricted Operation:  Denied</h1>
  <p>The operation you attempted to complete is restricted to site administrators only.</p>
  <p>If you are already a site administrator, and you don't believe you should be seeing this message, then please contact <a href="/users/Steve">Steve</a>.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='login_required' -->
  <h1>You Must Login</h1>
  <p>This section is restricted to registered users of the site who are logged in.</p>
  <p>Please login using the menu to the right of this page, and attempt this operation again.</p>
  <p>If you do not already have an account on this site you can <a href="/create/user">create one here</a>.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='article_too_old' -->
  <h1>Article Too Old</h1>
  <p>The article you are attempting to edit is too old.  Only articles still included on the front page may be editted.</p>
  <p>If things have changed only a little please leave your update as a comment.</p>
  <p>If sufficient time has passed that the article is completely outdated you may wish to <a href="/create/article">contribute a replacement</a>.</p>
  <!-- /tmpl_if -->


  <!-- tmpl_if name='ip_blacklisted' -->
  <h1>IP Blacklisted</h1>
  <p>The IP address you're viewing this website has been blacklisted.  This is almost certainly a result of you viewing the site from behind a Tor proxy server.</p>
  <p>If you wish to submit your comment please <a href="/create/user">create an account</a> and login.</p>
  <p>If you are logged in your IP address will not be blocked from posting comments.</p>
  <!-- /tmpl_if -->


  <!-- tmpl_if name='duplicate_comment' -->
  <h1>Duplicate Comment</h1>
  <blockquote>
   <p>You appear to have already posted that comment - this could be because you hit "reload" or "refresh", or it could be because of a site bug.</p>
   <p>Please return to the article/weblog/poll you were visiting and see if your comment is already present - if it is then you're done, if not then please report as a bug.</p>
 <!-- /tmpl_if -->

  <!-- tmpl_if name='bad_words' -->
  <h1>Speak Nicely!</h1>
  <p>The comment you attempted to post contains some word(s) which have been blacklisted - we try to keep things clean here, so if you reword your comment you should be able to post it later.</p>
  <p>The specific term that triggered this action is: <!-- tmpl_var name="stop_word" --></p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='is_troll' -->
  <h1>Trippity Trippity Trippity!</h1>
  <p>You have previously submitted comments which have been flagged by our users, and may no longer post anonymous comments.</p>
  <p>If you wish to submit your comment please <a href="/create/user">create an account</a> and login.</p>
  <p>If you are logged in you will be able to leave comments.</p>
  <!-- /tmpl_if -->


  <!-- tmpl_if name='bayasian_filter' -->
  <h1>Bayasian Filter Alert</h1>
  <p>The comment you attempted to submit has triggered one of our input filters and has been discarded.</p>
  <p>If you wish to submit your comment please <a href="/create/user">create an account</a> and login.</p>
  <p>If you are logged in you will be able to leave comments.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='anonylink' -->
  <h1>Links Detected</h1>
  <p>The comment you attempted to submit contains a link, and such comments may only be made by registered users.</p>
  <!-- /tmpl_if -->

  <!-- tmpl_if name='blogspam' -->
  <h1>BlogSpam Detected</h1>
  <p>The comment you attempted to submit has triggered the filtering provided by <a href="http://blogspam.net/">http://blogspam.net/</a>.</p>
  <p>If you wish to submit your comment please <a href="/create/user">create an account</a> and login - you may press "back" to return to your comment.</p>
  <p>If you are logged in you will be able to leave comments.</p>
  <!-- /tmpl_if -->

<!-- tmpl_else -->

 <h1>Access Denied</h1>
 <p>You do not have permission to complete the operation you attempted.</p>


  <p>The action you conducted has not got a specific error message associated with it.</p>
  <p>If you don't understand why you are seeing this page please contact the webmaster with an explaination of what you were doing prior to being shown this page.</p>

<!-- /tmpl_if -->

