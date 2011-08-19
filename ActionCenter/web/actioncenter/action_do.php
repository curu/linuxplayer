<?php
require_once 'check_login.inc.php';

//check if user have right to do this action
$action_id = (int)$_GET['id'];
$sql = sprintf('SELECT * FROM `user_action` WHERE `user_id` = %d AND `action_id` = %d' , 
		$_SESSION['uid'], $action_id);
$result = mysqli_query ( $GLOBALS ['mysqli'], $sql );

$error_msg = "";
if(!$result->num_rows){
	$error_msg = "<h2 style='color:red'>You don't have right to execute this action!</h2>";
}
//submit action 
$sql_submit = sprintf('INSERT INTO `history` (`action_id`, `user_id`) '
	. 'VALUES (%d, %d )', $action_id, $_SESSION['uid']);
$result = mysqli_query ( $GLOBALS ['mysqli'], $sql_submit );
if(!$result){
	$error_msg = "<h2 style='color:red'>Action submit failed: DB error</h2>";
}else{
	$task_id = mysqli_insert_id($GLOBALS['mysqli']);
	header("Location: action_status.php?taskid=$task_id");
}
?>
<html>
<head>
<title>Action Center - Execute action</title>
<link href="css/style.css" rel="stylesheet" type="text/css"></link>
</head>
<body>
<?php if ($error_msg):?>
<div style="font-size: 18px; font-style: bold;"><?php echo $error_msg; ?></div>
<?php endif;?>
</body>
</html>