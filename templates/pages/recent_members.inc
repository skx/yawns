<h1>Recently Site Members</h1>

<p>This page lists the users who have joined the site in the past <!-- tmpl_var name="count" --> days.</p>
<p>View users joining in the past <a href="/recent/users/1">1</a>, <a href="/recent/users/2">2</a>, or <a href="/recent/users/7">7</a> days.</p>


<table>

<tr><td><b>Username</b></td><td></td>
    <td><b>Joined</b></td>
    <td><b>URL</b></td></tr>

<!-- tmpl_loop name="users" -->

<tr>
 <td><a href="/users/<!-- tmpl_var name="username" -->"><!-- tmpl_var name="username" --></a></td><td><!-- tmpl_if name='commentcount' -->[<!-- tmpl_var name='commentcount' -->]<!-- /tmpl_if --></td>
<td><!-- tmpl_var name="joined" --></td>
<td>
  <!-- tmpl_if name="homepage" -->
	 <a href="<!-- tmpl_var name="homepage" -->"><!-- tmpl_var name="homepage" --></a>
  <!-- /tmpl_if -->
</td>
</tr>
<!-- /tmpl_loop -->
</table>
