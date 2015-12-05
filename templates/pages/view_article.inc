<!-- tmpl_if name="error" -->
      <h1>Error</h1>
	<p>The article you've specified doesn't exist.</p>
      <!-- tmpl_else -->

<script type="text/javascript" src="/js/jquery.socialshareprivacy.min.js"></script>
<script type="text/javascript">
  <!--//--><![CDATA[//><!--
$.fn.socialSharePrivacy.settings.path_prefix = '/';

$(function() {
     $('.share').socialSharePrivacy();
});
  //--><!]]>
</script>


       <div class="article">
       <!-- headline + section name -->
       <h2 class="title"><!-- tmpl_var name='article_title' --></h2>

       <div class="tagline"><p>Posted by  <!-- tmpl_if name="suspended" -->suspended user <strike><!-- tmpl_var name='article_byuser' --></strike><!-- tmpl_else --><a href="/users/<!-- tmpl_var escape='url' name='article_byuser' -->"><!-- tmpl_var name='article_byuser' --></a><!-- /tmpl_if --> on <!-- tmpl_var name='article_ondate' -->  at <!-- tmpl_var name='article_attime' --> </p></div>


<!-- tag start -->
  <!-- tmpl_include name='../includes/view_add_tag.template' -->
<!-- tag end -->

       <!-- tmpl_var name='article_body' -->

<!-- tmpl_if name='article_id' -->
<div style="text-align: right;">
</div>
<!-- /tmpl_if -->

<div class="navigation">
	<div class="row">
        <span class="left">
	<a href="/comment/onarticle/<!-- tmpl_var name='article_id' -->">Add Comment</a>
 <a href="/comment/feed/onarticle/<!-- tmpl_var name='article_id' -->"><img src="/images/xml.gif" title="Subscribe to comments on this article." alt="XML logo" width="36" height="14"></a></span>
         <span class="right">
         </span>
	<div class="spacer"> </div>
	</div>


	<p>&nbsp;</p>
         <div class="row">
	  <span class="left">
           <!-- tmpl_if name='showprev' -->
            <a href="/article/<!-- tmpl_var name='prev' -->/<!-- tmpl_var name='prevarticleslug' -->">&lt;&lt;&lt; <!-- tmpl_var name='prevarticle' --></a>
           <!-- /tmpl_if -->
          </span>
          <span class="right">
           <!-- tmpl_if name='shownext' -->
            <a href="/article/<!-- tmpl_var name='next' -->/<!-- tmpl_var name='nextarticleslug' -->"><!-- tmpl_var name='nextarticle' --> &gt;&gt;&gt;</a>
           <!-- /tmpl_if -->
          </span>
	<div class="spacer"> </div>
        </div>

	</div>
</div>

<p>&nbsp;</p>
 <div class="share"></div>
<p>&nbsp;</p>

<!-- tmpl_if  name="show_adverts" -->

	<!-- tmpl_if name="google_adverts" -->
	<p></p>
	<div class="advert">
	<center>
	<script type="text/javascript"><!--
	google_ad_client = "pub-1910202134166551";
	google_ad_width = 728;
	google_ad_height = 90;
	google_ad_format = "728x90_as";
	google_ad_type = "text_image";
	google_ad_channel ="4454478967";
	//--></script>
	<script type="text/javascript"
	  src="//pagead2.googlesyndication.com/pagead/show_ads.js">
	</script>
	</center>

        <!-- tmpl_unless name="logged_in" -->
	  <p  style="text-align: right;"><a href="/about/FAQ%20:%20Site%20Adverts">Why are these adverts here?</a></p>
        <!-- /tmpl_unless -->
	</div>
	<!-- /tmpl_if -->
<!-- tmpl_else -->
	<!-- Adverts Removed -->
<!-- /tmpl_if -->

<!-- tmpl_if name="comments" -->
 <hr />
 <!-- tmpl_var name="comment_text" -->
<!-- /tmpl_if -->

<!-- /tmpl_if -->  <!-- Closing tag for if_error -->
