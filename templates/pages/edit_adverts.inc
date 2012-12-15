<h1>Edit Community Adverts</h1>

<!-- tmpl_if name='error' -->
  <p>There are currently no community adverts active upon this site.</p>
  <p>Why not <a href="/create/advert">create one</a>?</p>

<!-- tmpl_else -->
  <p>Here you may edit the state of the various adverts, both those <a href="/adverts/all">which are currently active</a>, or those yet pending.</p>


   <!-- tmpl_loop name='adverts' -->
     <div style="text-align: center;">
       <table width="400">
       <tr><td valign="top" align="left" width="400">
           <p>By <a href="/users/<!-- tmpl_var name='owner' escape="html" -->"><!-- tmpl_var name='owner' escape='html' --></a></p>
           <p>State: <!-- tmpl_var name='state' --></p>
           <ul>
           <li><a href="/adverts/enable/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Enable Advert</a></li>
           <li><a href="/adverts/disable/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Disable Advert</a></li>
           <li><a href="/adverts/delete/<!-- tmpl_var name='id' -->/<!-- tmpl_var name='session' -->">Delete Advert</a></li>
           <li><a href="/adverts/<!-- tmpl_var name='id' -->">Track Stats</a></li>
           </ul>
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
