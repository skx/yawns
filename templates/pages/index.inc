      <!-- tmpl_if name='content' -->
      <!-- tmpl_loop name='articles' -->
         <div class="teaser">
	<h1 class="title"><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name="slug" -->"><!-- tmpl_var name='title' --></a></h1>
	    <div class="tagline">Posted by <a href="/users/<!-- tmpl_var escape='URL' name='byuser' -->"><!-- tmpl_var name='byuser' --></a> on <!-- tmpl_var name='ondate' -->  at <!-- tmpl_var name='attime' --> </div>
	<!-- tmpl_if name="has_tags" -->
	    <div class="tags">
            <!-- tmpl_include name="../includes/tags.template" -->
	    </div>
	<!-- /tmpl_if -->

	    <div class="body"> <!-- tmpl_var name='body' --></div>
            <div class="readmore">( <a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='slug'>">Read <!-- tmpl_var name='words' --> more words</a> ~
                  <!-- tmpl_if name='comment' -->1 comment
                  <!-- tmpl_else --><!-- tmpl_var name='comments' --> comments
                  <!-- /tmpl_if --> posted
	          )</div>
      </div>
      <!-- /tmpl_loop -->


<nav>
<ul class="pager">
  <!-- tmpl_if name='showprev' -->
  <li class="previous"><a href="/start/<!-- tmpl_var name='prevfrom' -->">&lt;&lt;&lt; Previous <!-- tmpl_var name="prevcount" -->  Articles</a></li>
 <!-- /tmpl_if -->
  <!-- tmpl_if name='shownext' -->
  <li class="next"><a href="/start/<!-- tmpl_var name='nextfrom' -->">Next <!-- tmpl_var name="nextcount" --> Articles &gt;&gt;&gt;</a></li>
 <!-- /tmpl_if -->
</ul>
</nav>

      <!-- tmpl_else -->
             <h2>Error</h2>
	    <p>There are no articles to display.</p>
	    <p>This is almost certainly an error, or a new installation of Yawns.   If it is a new installation plase <a href="/create/article">submit an article</a> to get started.</p>
      <!-- /tmpl_if -->
