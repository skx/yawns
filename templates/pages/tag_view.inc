<script type="text/javascript">

//
//  If we have fragment in the URL load that up type of tags.
//
//
function setupView()
{
    loc  = location.href;
    frag = loc.indexOf("#");

    if ( frag > 0 )
    {
        updateView(loc.substring( frag + 1 ) );
    }

}


//
//  "Bold" the link of the type we've clicked.
//
function updateLinks( type )
{
   $(".linkable").css( "font-weight", "normal" )
   $("#link_" + type ).css( "font-weight", "bold" );
   $( "#heading" ).text( "Tag Cloud : " +  $("#link_" + type).text() );
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


<div class="container-fluid">
  <h1 id="heading">Tag Cloud</h1>
  <div class="row">
    <div class="col-sm-1 col-md-1"></div>
    <div class="col-sm-11 col-md-10">

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
   <div id="all_tags"><p><!-- tmpl_include name='../includes/all_tags.template' --></p></div>

<!-- tmpl_else -->
      <p>No tags have been added to this site yet.</p>
<!-- /tmpl_if -->

   </div>
   <div class="col-sm-1 col-md-1"></div>
   </div>
   </div>
