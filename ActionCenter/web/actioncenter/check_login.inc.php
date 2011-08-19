<?php
require_once 'config.php';

//user must login first
session_start();

if(!isset($_SESSION['uid'])){
	echo <<<EOF
	<script type="text/javascript">
		if(window.top != window.self){
			window.top.location.href = location
		}
	</script>
EOF;
	die('ACCESS DENIED!');
}

?>
