<?php
require_once 'check_login.inc.php';

//check if user have right to query status of this action
if(!isset($_GET['taskid'])){
	die("Invalid argument") ;
}
$task_id = (int)$_GET['taskid'];
$sql = sprintf('SELECT * FROM `history` WHERE `id` = %d AND `user_id` = %d' , 
		$task_id, $_SESSION['uid']);
$result = mysqli_query ( $GLOBALS ['mysqli'], $sql );

$error_msg = "";
if(!$result->num_rows){
	$error_msg = "<h2 style='color:red'>You don't have right to query status of this action!</h2>";
}else{
	$row = $result->fetch_assoc ();
	$status = $row['status'];
}
?>
<html>
<head>
<?php if ($status == 'NEW' || $status == 'PROCESSING'):?>
<meta http-equiv="refresh" content="2">
<?php endif;?>
<title>Action Center - Action list</title>
<link href="css/style.css" rel="stylesheet" type="text/css"></link>
</head>
<body>
<?php if ($error_msg):?>
<div style="font-size: 18px; font-weight: bold;"><?php echo $error_msg; ?></div>
<?php 
else:
	switch ($status) {
		case 'NEW':
			$status_msg = "Waiting ...";
			break;
		case 'PROCESSING':
			$status_msg = "Processing ...";
			break;
		case 'FAIL':
			$status_msg = "<span style='color:red;'>Failed</span>";
			break;
		case 'SUCCESS':
			$status_msg = "<span style='color:green;'>Finished successfully</span>";
			break;
		default:
			$status_msg = "This should never happen.";
	}
?>
<h3>Action status:</h3>
<div style="font-weight: bold; margin-bottom: 10px;"><?php echo $status_msg; ?></div>
<div>task id: <em><?php echo $row['id'];?></em> last update time: <em><?php echo $row['last_update'];?></em></div>
<?php
endif;
?>
</body>
</html>