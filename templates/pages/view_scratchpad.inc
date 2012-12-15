      <h1>Scratchpad for : <a href="/users/<!-- tmpl_var name="view" -->"><!-- tmpl_var name="view" --></a></h1>
	<p></p>
	<!-- tmpl_if name="empty" -->
           <p>The scratchpad for <!-- tmpl_var name='view' --> is currently empty.</p>
	<!-- tmpl_else -->

           <!-- tmpl_if name="private" -->
           <p>The scratchpad for <!-- tmpl_var name='view' --> is currently set to private, meaning only they can view it..</p>
           <!-- tmpl_else -->

	     <!-- tmpl_var name='scratchpad' -->

           <!-- /tmpl_if -->
	<!-- /tmpl_if -->
	
	<!-- tmpl_if name="edit" -->
	<hr />
	<p>As this is your scratchpad you may <a href="/edit/scratchpad/<!-- tmpl_var name="view" -->">edit it</a>.</p>
	<!-- /tmpl_if -->
