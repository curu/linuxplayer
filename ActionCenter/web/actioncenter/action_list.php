<?php
require_once 'check_login.inc.php';

$sql = sprintf('SELECT `id`,`name`,`description` FROM `action` WHERE `id`  IN '
	.' ( SELECT `action_id` FROM `user_action` WHERE `user_id` = %d )' , $_SESSION['uid']);
$result = mysqli_query ( $GLOBALS ['mysqli'], $sql );
?>
<html>
<head>
<title>Action Center - Action list</title>
<link href="css/style.css" rel="stylesheet" type="text/css"></link>
</head>
<body>
<?php if($result->num_rows == 0): ?>
<h3>No action available to you</h3>
<?php else: ?>
<table class="record_table">
<thead>
<tr><th>Action</th><th>Description</th><th>Execute</th></tr>
</thead>
<tbody>
<?php
while (($row = $result->fetch_assoc ()) != false ) :
	printf("<tr>\n");
	printf('<td class="first-child">%s</td>', $row['name']);
	printf('<td>%s</td>', $row['description']);
	printf('<td><a href="action_do.php?id=%d">Execute</a></td>', $row['id']);
	printf("\n</tr>\n");
endwhile; 
?>
</tbody>
</table>
<?php endif; ?>
</body>
</html>