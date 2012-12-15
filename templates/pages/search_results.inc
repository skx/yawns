		<!-- tmpl_if name='results' -->

<!-- tmpl_if name='author_search' -->
<h1>Search Results</h1>
<p>You searched for articles written by <a href="/users/<!-- tmpl_var name='author_search' escape="html" -->"><!-- tmpl_var name='author_search' --></a>.</p>
<!-- /tmpl_if -->

<!-- tmpl_if name='search_for' -->
<h1>Search Results</h1>
<p>You searched for articles matching "<tt><!-- tmpl_var name='search_for' escape="html" --></tt>" <!-- tmpl_if name="search_titles" -->in their titles<!-- /tmpl_if -->.</p>
<!-- /tmpl_if -->

<!-- tmpl_loop name='results' -->
  <div class="teaser">
  <h2 class="title"><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name="slug">"><!-- tmpl_var name='title' --></a></h2>
  <div class="tagline"><!-- tmpl_if name='score' -->Score: <!-- tmpl_var name='score' --> posted <!-- tmpl_else -->Posted<!-- /tmpl_if --> by <a href="/users/<!-- tmpl_var escape='URL' name='author' -->"><!-- tmpl_var name='author' --></a>  on <!-- tmpl_var name='ondate' --></div>
  <!-- tmpl_if name="has_tags" -->
  <div class="tags">
  <!-- tmpl_include name="../includes/tags.template" -->
  </div>
  <!-- /tmpl_if -->
  <div class="body"> <!-- tmpl_var name='teaser' --></div>
  <div class="readmore"><a href="/article/<!-- tmpl_var name='id' -->/<!-- tmpl_var name="slug">">Read more</a></div>

  </div>

<!-- /tmpl_loop -->

                <!-- tmpl_else -->
	<h1>Search Results</h1>
        <p>Sorry, no matching articles were found.</p>
		<!-- /tmpl_if -->
