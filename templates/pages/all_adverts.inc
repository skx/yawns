<!-- tmpl_if name='by_user' -->
      <h1>Adverts by <!-- tmpl_var name='user' --></h1>
<!-- tmpl_else -->
      <h1>All Community Adverts</h1>
<!-- /tmpl_if -->

<!-- tmpl_if name='error' -->
<!-- tmpl_if name='by_user' -->
   <p><a href="/users/<!-- tmpl_var name='user' -->"><!-- tmpl_var name='user' --></a> has no adverts registered upon this site.</p>
<!-- tmpl_else -->
  <p>There are currently no <a href="/about/FAQ%20:%20Site%20Adverts#user">community adverts</a> active upon this site.</p>
  <p>Why not <a href="/create/advert">create one</a> relevant to Debian System Administrators?</p>
<!-- /tmpl_if -->
<!-- tmpl_else -->

<!-- tmpl_if name='by_user' -->
     <p>These are the adverts which have been posted by <a href="/users/<!-- tmpl_var name='user' -->"><!-- tmpl_var name='user' --></a>.</p>
<!-- tmpl_else -->
      <p>Here you can see each of the active <a href="/about/FAQ%20:%20Site%20Adverts#user">community adverts</a>.</p>
<!-- /tmpl_if -->



        <!-- tmpl_loop name='adverts' -->
        <div style="text-align: center;">
         <table>
        <tr><td width="200"></td>
<td align="left" valign="top" width="200">
             <p>By <a href="/users/<!-- tmpl_var name='owner' escape="html" -->"><!-- tmpl_var name='owner' escape='html' --></a>.</p>
<!-- tmpl_if name='stats' -->
        <p><a href="/adverts/<!-- tmpl_var name='id' -->">View details</a>.</p>
<!-- /tmpl_if -->
</td>
           <td width="200" align="left">
           <div class="advert" style="border: solid 1px;" onClick="document.location.href='/follow/<!-- tmpl_var name='id' -->';" onMouseOver="this.style.cursor='pointer'; window.status='<!-- tmpl_var name='link' -->';" onMouseOut="window.status='';">
        <p style="text-align: center;"><a href="/follow/<!-- tmpl_var name='id' -->"><!-- tmpl_var name='linktext' --></a></p>
        <!-- tmpl_var name='text' -->
        <p style="text-align: center;"><a href="/follow/<!-- tmpl_var name='id' -->"><!-- tmpl_var name='linktext' --></a></p>
        </div>
         </td></tr>
         </table>
        </div>
        <p></p>
        <!-- /tmpl_loop -->

<!-- /tmpl_if -->
