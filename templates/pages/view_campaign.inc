<!-- tmpl_if name='error' -->
     <h1>Advert Campaign not found</h1>
     <p>Advertising campaigns are purged from  the database shortly after they have been completed.</p>   

<!-- tmpl_else -->

      <h1>Advert Campaign #<!-- tmpl_var name='advert_id' --></h1>
<p>Below is the data for the specified advert.</p>
<table>
<tr><td>Owner</td>
    <td><a href="/users/<!-- tmpl_var name='advert_owner' escape='html' -->"><!-- tmpl_var name='advert_owner' --></a></td>
</tr>

<tr><td>Link</td>
    <td><a href="<!-- tmpl_var name='advert_link' -->"><!-- tmpl_var name='advert_link_title' escape='html' --></a></td>
</tr>

<tr><td>Viewed</td>
    <td>Shown <!-- tmpl_var name='shown' --> / <!-- tmpl_var name='max' --></td>
</tr>

<tr><td>Clicked</td>
    <td><!-- tmpl_var name='clicked' --></td>
</tr>

<tr><td>Click Rate</td>
    <td><!-- tmpl_var name='clickthrough' -->%</td>
</tr>

<tr><td>Status</td>
    <td><!-- tmpl_var name='status' --></td>
</tr>
</table>

<!-- /tmpl_if -->
