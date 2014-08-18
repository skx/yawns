         <!-- tmpl_if name='preview' -->
        <h1>Advert Preview</h1>

           <div class="advert" style="border: solid 1px;" onmouseover="this.style.cursor='pointer';">
        <p style="text-align: center;"><a href="<!-- tmpl_var name='submit_link' escape="html"-->"><!-- tmpl_var name='submit_link_text' --></a></p>
        <!-- tmpl_var name='submit_copy' -->
        <p style="text-align: center;"><a href="<!-- tmpl_var name='submit_link' escape="html"-->"><!-- tmpl_var name='submit_link_text' --></a></p>
        </div>
        <!-- /tmpl_if -->



<!-- tmpl_if name='confirm' -->
<h1>Advert Submitted</h1>
<p>Thank you for your submission.  It has been entered into the queue, and will be reviewed soon by our editorial volunteers.  When they approve it, it will appear on the main site, and you'll be able to track the click-throughs.</p>

                  <!-- tmpl_else -->
                  <!-- tmpl_if name='new' -->
	            <h1>Submit An Advert</h1>
                  <form action="/create/advert" method="post">
                  <input type="hidden" name="mode" value="create_advert" />
       <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
<p>To submit your advert to this site fill in all the fields below then click the 'Preview' button.</p>

<p>Once you have made your submission it will enter a queue where it will stay until it has been checked by the webmaster.  Adverts are going to be published only as time permits and their duration will depend upon how long it takes them to reach 5000 impressions.</p>

<p>Depending on how the advert trial goes I may increase the default from 5000, if you'd like <i>your</i> advert to run for longer feel free to <a href="/users/Steve">get in touch</a> - donations would probably help <img src="/images/emoticons/wink.gif" width="15" height="15" alt=";)"></p>

                  <!-- tmpl_else -->
                  <form action="/create/advert" method="post">
                  <input type="hidden" name="mode" value="create_advert" />
       <input type="hidden" name="session" value="<!-- tmpl_var name='session' -->" />
                    <p>If the preview above is correct and you would like it to be published on the site, then click on the 'Confirm' button below.</p>


	<table>
	<tr><td><b>Link:</b></td><td><input type="text" name="submit_link" value="<!-- tmpl_var name='submit_link' -->" size="70"></td></tr>
	<tr><td><b>Link Title:</b></td><td><input type="text" name="submit_link_text" value="<!-- tmpl_var name='submit_link_text' -->" size="70"></td></tr>
	<tr><td><b>Advert Text:</b></td><td><input type="text" name="submit_copy" value="<!-- tmpl_var name='submit_copy' -->" size="80"></td></tr>
	</table>
                  <!-- /tmpl_if -->
		  <!-- tmpl_if name='new' -->

	<table>
	<tr><td><b>Link:</b></td><td><input type="text" name="submit_link" size="70" value="http://"></td></tr>
	<tr><td><b>Link Title:</b></td><td><input type="text" name="submit_link_text" size="70" value="Link Title"></td></tr>
	<tr><td><b>Advert Text:</b></td><td><input type="text" name="submit_copy" size="80" value="<p>Line one</p><p>Line Two</p>" ></td></tr>
	</table>
	<p><input type="submit" name="add_advert" value="Preview" /> </p>

                  <!-- tmpl_else -->
	<p><input type="submit" name="add_advert" value="Preview" /> &nbsp; <input type="submit" name="add_advert" value="Confirm" /></p>

		    <!-- /tmpl_if -->
                  <!-- /tmpl_if -->
                  </form>
