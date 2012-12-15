<script type="text/javascript">

//
//  If we have fragment in the URL load that up type of tags.
//
//  Either way update the recent tags every 2 seconds.
//
function setupView()
{
    loc  = location.href;
    frag = loc.indexOf("#");

    if ( frag > 0 )
    {
        updateView(loc.substring( frag + 1 ) );
    }

    setTimeout('updateRecent();', 2000);
}


//
//  "Bold" the link of the type we've clicked.
//
function updateLinks( type )
{
   $(".linkable").css( "font-weight", "normal" )
   $("#link_" + type ).css( "font-weight", "bold" );
}


//
//  Update the recent tags.
//
function updateRecent()
{
    $("#recent_tags").load("/ajax/tags/recent",
                          function () { setTimeout("updateRecent();", 60000); } )

}


//
//  Update the view to be comprised of only tags of the appropriate
// type.
//
function updateView( type )
{
    // show the progress.
    $("#progress" ).show();

    $("#all_tags").load( "/ajax/tags/type/" + type,
                         function() { $("#progress").hide(),
                          updateLinks(type) } )
}

$(document).ready(function(){ setupView(); } );


</script>


      <h1>Tag Cloud</h1>
      <p>Here you can see the list of <a href="/tag/">all tags</a> which our registered users have applied to the content upon this site.</p>
<!-- tmpl_if name='all_tags' -->
      <p>If you wish you can restrict the view to only those tags which have been applied to
<a href="#a" onClick="updateView('a');" class="linkable" id="link_a">articles</a>,
<a href="#p" onClick="updateView('p');" class="linkable" id="link_p">polls</a>,
 or
<a href="#w" onClick="updateView('w');" class="linkable" id="link_w">weblog entries</a>.
</p>
<div id="progress" style="display:none;">
  <img src="/images/progress.gif" alt="Loading .."/>
</div>
<!-- /tmpl_if -->

<!-- tmpl_if name='all_tags' -->
	<div id="all_tags"><p>
      <!-- tmpl_include name='../includes/all_tags.template' -->
	</p></div>

<!-- tmpl_else -->
      <p>No tags have been added to this site yet.</p>
<!-- /tmpl_if -->

      <p>Some <a href="/about/FAQ%20:%20Tags">tag help</a> is available via the <a href="/about/FAQ">site FAQ</a>.</p>

