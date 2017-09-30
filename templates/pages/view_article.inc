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
    <p>&nbsp;</p>

    <nav>
      <ul class="pager">
        <!-- tmpl_if name='showprev' -->
        <li class="previous"><a href="/article/<!-- tmpl_var name='prev' -->/<!-- tmpl_var name='prevarticleslug' -->">&lt;&lt;&lt; <!-- tmpl_var name='prevarticle' --></a></li>
        <!-- /tmpl_if -->
        <!-- tmpl_if name='shownext' -->
        <li class="next"><a href="/article/<!-- tmpl_var name='next' -->/<!-- tmpl_var name='nextarticleslug' -->"><!-- tmpl_var name='nextarticle' --> &gt;&gt;&gt;</a>
          <!-- /tmpl_if -->
      </ul>
    </nav>
  </div>
</div>

<p>&nbsp;</p>
<div class="share"></div>
<p>&nbsp;</p>

<p></p>
<div class="advert">
  <center>
<script async src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
<ins class="adsbygoogle"
     style="display:block"
     data-ad-format="autorelaxed"
     data-ad-client="ca-pub-1910202134166551"
     data-ad-slot="6097394608"></ins>
<script>
     (adsbygoogle = window.adsbygoogle || []).push({});
</script>
  </center>
</div>

<!-- tmpl_if name="comments" -->
<hr />
<!-- tmpl_var name="comment_text" -->
<!-- /tmpl_if -->

<!-- /tmpl_if -->  <!-- Closing tag for if_error -->
