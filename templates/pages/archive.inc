
	<h1>Archive for <!-- tmpl_var name='month_name' --> <!-- tmpl_var name='year' --></h1>

	<blockquote>

	<!-- tmpl_if name='articles' -->
      <!-- tmpl_loop name='articles' -->
      <!-- tmpl_if name='new_month' -->
	<!-- tmpl_if name='show_month' -->
	<!-- tmpl_else -->
	<h3><a href="/archive/<!-- tmpl_var name='year' -->/<!-- tmpl_var name='month' -->"><!-- tmpl_var name='name' --></a></h3>
	<!-- /tmpl_if -->
	<!-- /tmpl_if -->
	<!-- tmpl_if name='show_month' -->
	<dl>
	<dt><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='slug' -->"><!-- tmpl_var name='title' --></a></dt>
	<dd><!-- tmpl_var name='teaser' --></dd>
	</dl>
	<!-- /tmpl_if -->
      <!-- /tmpl_loop -->
	<!-- tmpl_else -->
	<p>No articles for that month.</p>
	<!-- /tmpl_if -->

	</blockquote>

        <!-- tmpl_if name='month_view' -->

<div class="row">
 <span class="left">
	<!-- tmpl_if name='show_prev_month' -->
	<a href="/archive/<!-- tmpl_var name='year' -->/<!-- tmpl_var name='prev_month' -->">Previous Month</a>
	<!-- tmpl_else -->
	  <!-- tmpl_if name='show_prev_year' -->
          <a href="/archive/<!-- tmpl_var name='prev_year' -->/12">Previous Year</a>
	  <!-- tmpl_else -->
	  &nbsp;
	  <!-- /tmpl_if -->
	<!-- /tmpl_if -->
 </span>
 <span class="right">
	<!-- tmpl_if name='show_next_month' -->
	<a href="/archive/<!-- tmpl_var name='year' -->/<!-- tmpl_var name='next_month' -->">Next Month</a>
	<!-- tmpl_else -->
	  <!-- tmpl_if name='show_next_year' -->
          <a href="/archive/<!-- tmpl_var name='next_year' -->/1">Next Year</a>
	  <!-- tmpl_else -->
	  &nbsp;
	  <!-- /tmpl_if -->
	<!-- /tmpl_if -->
 </span>
<div class="clear"> </div>
</div>
	<!-- /tmpl_if -->
<p>&nbsp;</p>

