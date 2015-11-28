	<!-- tmpl_if name='error' -->
       <h1>Error</h1>
       <p>The username you have specified <tt><!-- tmpl_var name="viewusername" --></tt> doesn't exist.</p>
	<!-- tmpl_else -->

	<!-- tmpl_if name='suspended' -->
	<h1>Invalid Username</h1>
	<blockquote>
	<p>The user <tt><!-- tmpl_var name='viewusername' --></tt> has been suspended from this site.</p>
	</blockquote>

<!-- tmpl_if name="edit_user" -->
	<p><a href="/edit/user/<!-- tmpl_var name="viewusername" -->">Edit this Suspended User</a>.</p>
<!-- /tmpl_if -->

	<!-- tmpl_else -->

	<h1>User Information for: <!-- tmpl_var name='viewusername' --></h1>

<!-- tmpl_if name='is_owner' -->
  <p>As this is your user-page you <a href="/edit/user/<!-- tmpl_var name='viewusername' -->">can change the information</a> that it is displayed here.</p>
<!-- /tmpl_if -->

<!-- tmpl_if name="extra_options" -->
<hr />
<p align="right">
<!-- /tmpl_if -->
  <!-- tmpl_if name='send_message' -->
   [<a href="/create/message/<!-- tmpl_var name='viewusername' escape='html' -->">Send message</a>]
  <!-- /tmpl_if -->
<!-- tmpl_if name="edit_user" -->
   [<a href="/edit/user/<!-- tmpl_var name="viewusername" -->">Edit user</a>]<!-- /tmpl_if -->
<!-- tmpl_if name="edit_user_permissions" -->
   [<a href="/edit/permissions/<!-- tmpl_var name="viewusername" -->">Edit Permissions</a>]<!-- /tmpl_if -->
<!-- tmpl_if name='extra_options' -->
</p>
<!-- /tmpl_if -->


	<p></p>
	<table>
         <!-- tmpl_if name='showname' -->
         <tr><td><b>Real name:</b></td><td><!-- tmpl_var name='realname' escape='html' -->	 <!-- /tmpl_if -->
         </td></tr>

         <!-- tmpl_if name='showemail' -->
         <tr><td></td><td><a href="mailto:<!-- tmpl_var name='fakeemail' -->"><!-- tmpl_var name='fakeemail' --></a></td></tr>
         <!-- /tmpl_if -->
         <!-- tmpl_if name='showurl' -->
         <tr><td></td><td><a href="<!-- tmpl_var name='url' -->" rel="nofollow"><!-- tmpl_var name='url' --></a></td></tr>
         <!-- /tmpl_if -->

	<!-- tmpl_if name='show_scratchpad'-->
	<tr><td>&nbsp;</td><td>&nbsp;</td></tr>
	 <tr><td><b>Scratchpad</b></td><td>
	  <a href="/users/<!--tmpl_var name='viewusername'>/scratchpad">Scratchpad</a></td>	</tr>
         <!-- /tmpl_if -->

        <!-- tmpl_if name='show_bookmarks' -->
	 <tr><td></td>
	     <td><a href="/users/<!-- tmpl_var name='viewusername' -->/bookmarks">Bookmarks</a></td></tr>
        <!-- /tmpl_if -->

	<!-- tmpl_if name='weblogs'-->
         <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
	 <tr><td><b>Weblogs</b></td><td>
	  <a href="/users/<!--tmpl_var name='viewusername'>/weblog"><!-- tmpl_var name="weblogs" --> <!-- tmpl_if name="weblog_plural" -->Entries<!-- tmpl_else -->Entry<!-- /tmpl_if --></a>  <a href="/weblog/feeds/<!-- tmpl_var name="viewusername" -->"><img src="/images/xml.gif" alt="XML logo" width="36" height="14"></a></td>	</tr>
         <!-- /tmpl_if -->


         <!-- tmpl_if name='showbio' -->
         <tr><td><p></p></td><td><p></p></td></tr>
         <tr><td valign="top"><b>Bio:</b></td>
             <td valign="top"><!-- tmpl_var name='bio' --></td></tr>
         <!-- /tmpl_if -->

         <!-- tmpl_unless name='anon' -->
         <!-- tmpl_if name='articles' -->
	 <tr><td><p></p></td><td><p></p></td></tr>
         <tr><td valign="top" colspan="2"><b>Recent articles:</b>
		<ul>
                      <!-- tmpl_loop name='articles' -->
                      <li><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='slug' -->"><!-- tmpl_var name='title' --></a>
                      <ul>
                      <li>Posted on <!-- tmpl_var name='ondate' -->.</li>
                      </ul></li>
                      <!-- /tmpl_loop -->
		    </ul></td></tr>
         <tr><td valign="top"><p></p></td>
             <td valign="top"><b>Total articles</b>: <!-- tmpl_var name="article_count" --> <!-- tmpl_if name='edit_user' -->[<a href="/search/byauthor/<!-- tmpl_var name='viewusername' -->">View All</a>]<!-- /tmpl_if --></td></tr>

         <!-- /tmpl_if -->

         <!-- tmpl_if name='comments' -->
	 <tr><td><p></p></td><td><p></p></td></tr>
         <tr><td valign="top" colspan="2"><b>Recent comments:</b>
		<ul>
                      <!-- tmpl_loop name='comments' -->
		<!-- tmpl_if name='is_poll'-->
                      <li><a href="/polls/<!-- tmpl_var name='poll' -->#comment_<!-- tmpl_var name='id' -->"><!-- tmpl_var name='title' --></a>
		<!-- /tmpl_if -->
		<!-- tmpl_if name="article" -->
                      <li><a href="/articles/<!-- tmpl_var name='article' -->#comment_<!-- tmpl_var name='id' -->"><!-- tmpl_var name='title' --></a>
		<!-- /tmpl_if -->
		<!-- tmpl_if name="weblog_link" -->
                      <li><a href="<!-- tmpl_var name="weblog_link" -->#comment_<!-- tmpl_var name='id' -->"><!-- tmpl_var name='title' --></a>
		<!-- /tmpl_if -->
                <ul>
                <li>Posted on <!-- tmpl_var name='ondate' -->.</li>
                </ul></li>
                      <!-- /tmpl_loop -->
		    </ul>                    </td></tr>
         <tr><td valign="top"><p></p></td>
             <td valign="top"><b>Total comments</b>: <!-- tmpl_var name="comment_count" -->
                    <p>Recent comments: <a href="/recent/comments/<!-- tmpl_var name='viewusername' escape='html'-->"><img src="/images/xml.gif" width="36" height="14" alt="Recent comments by <!-- tmpl_var name='viewusername' escape='html' -->"></a></p>

</td></tr>
                  <!-- /tmpl_if -->
                  <!-- /tmpl_unless -->
        </table>

	<!-- /tmpl_if -->
	<!-- /tmpl_if -->

<!-- tmpl_if name="extra_options" -->
<hr />
<p align="right">
<!-- /tmpl_if -->
  <!-- tmpl_if name='send_message' -->
   [<a href="/create/message/<!-- tmpl_var name='viewusername' escape='html' -->">Send message</a>]
  <!-- /tmpl_if -->
<!-- tmpl_if name="edit_user" -->
   [<a href="/edit/user/<!-- tmpl_var name="viewusername" -->">Edit user</a>]<!-- /tmpl_if -->
<!-- tmpl_if name="edit_user_permissions" -->
   [<a href="/edit/permissions/<!-- tmpl_var name="viewusername" -->">Edit Permissions</a>]<!-- /tmpl_if -->
<!-- tmpl_if name='extra_options' -->
</p>
<!-- /tmpl_if -->
