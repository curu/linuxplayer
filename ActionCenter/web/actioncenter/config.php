<?php
define('DB_HOST','localhost');
define('DB_USER','actionadmin');
define('DB_PASSWORD','the.passwd*_*');
define('DB_SCHEMA','action_center');

$mysqli = new mysqli(DB_HOST,DB_USER,DB_PASSWORD,DB_SCHEMA);

if(mysqli_connect_errno()){
	printf("Connect failed: %s\n", mysqli_connect_error());
    exit();
}
?>
