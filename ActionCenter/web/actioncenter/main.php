<?php
require_once 'config.php';
require_once 'User.php';

require_once 'check_login.inc.php';
?>

<html>
<body>
<center><br><br><h2>
<?php 
$user = User::getByID($_SESSION['uid']);
$who = $user->realname ? $user->realname : $user->username;
echo "Welcome,  $who !";
?>
</h2></center>
</body>
</html>