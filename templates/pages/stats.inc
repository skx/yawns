      <h1><!-- tmpl_var name='sitename' --> :  Site Statistics</h1>
      <p>This page contains various statistics and "records" of the site, and its contents.</p>

	          <h2>Most popular articles</h2>
		  <blockquote>
		  <ol>
                  <!-- tmpl_loop name='popular_articles' -->
                  <li><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='slug' -->"><!-- tmpl_var name='title' --></a>
		  <ul>
		  <li>Posted by <a href="/users/<!-- tmpl_var name='author' -->"><!-- tmpl_var name='author' --></a> on <!-- tmpl_var name='ondate' --> (Read <!-- tmpl_var name='readcount' --> times)</li>
		  </ul></li>
                  <!-- /tmpl_loop -->
	  	  </ol>
		  </blockquote>

	          <h2>Most active discussions</h2>
		  <blockquote>
		  <ol>
                  <!-- tmpl_loop name='active_articles' -->
                  <li><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='slug' -->"><!-- tmpl_var name='title' --></a>
		  <ul>
		  <li>Posted by <a href="/users/<!-- tmpl_var name='author' -->"><!-- tmpl_var name='author' --></a> on <!-- tmpl_var name='ondate' --> (<!-- tmpl_var name='comments' --> comments)</li>
		  </ul></li>
                  <!-- /tmpl_loop -->
		  </ol>
		  </blockquote>

		  <h2>Longest articles</h2>
		  <blockquote>
		  <ol>
                  <!-- tmpl_loop name='longest_articles' -->
                  <li><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='slug' -->"><!-- tmpl_var name='title' --></a>
		  <ul>
		  <li>Posted by <a href="/users/<!-- tmpl_var name='author' -->"><!-- tmpl_var name='author' --></a> on <!-- tmpl_var name='ondate' --> (<!-- tmpl_var name='words' --> words)</li>
		  </ul></li>
                  <!-- /tmpl_loop -->
		  </ol>
		  </blockquote>

		  <a name="totals"></a>
		  <h2>Totals</h2>
		  <blockquote>
		  <table>
		    <tr>
		      <td>
		        Total Articles posted:
		      </td>
		      <td align="right">
		        <!-- tmpl_var name='article_count' -->
		      </td>
		    </tr>
		    <tr>
		      <td>
		        Total Registered users:
		      </td>
		      <td align="right">
                        <!-- tmpl_var name='user_count' -->
		      </td>
		    </tr>
		    <tr>
		      <td>
			Comments posted:
		      </td>
		      <td align="right">
		        <!-- tmpl_var name='comment_count' -->
		      </td>
		    </tr>
		    <tr>
		      <td>
			Weblogs posted:
		      </td>
		      <td align="right">
		        <!-- tmpl_var name='weblog_count' -->
		      </td>
		    </tr>
		  </table>
		  </blockquote>
