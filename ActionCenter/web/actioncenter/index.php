<?php
session_start();

if(!isset($_SESSION['uid'])){
	header("Location: login.php");
	exit();
}

?>
<html>
<head>
<title>Action Center</title>
</head>
<frameset cols="180,*" id="mainFrameset">
        <frame frameborder="0" id="nav"
        src="nav.php"
        name="frame_nav" />
        <frame frameborder="0" id="content"
        src="main.php"
        name="content" />
</frameset>
</html>
