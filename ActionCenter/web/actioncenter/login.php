<?php 
require_once 'config.php';
require_once 'User.php';
session_start();
$msg = "";
//perform login logic
if(isset($_POST['login'])){
	if(isset($_POST['username']) && isset($_POST['password'])){
		$username = trim($_POST['username']);
		$password = trim($_POST['password']);
		
		$user = User::getByUsername($username);
		if($user->uid && !$user->isActive){
			die("Account disabled!");
		}
		if($user->uid && $user->password == md5($password)){
			$_SESSION['uid'] = $user->uid;
			header("Location: index.php");
			//exit();
		}
		else {
		$msg = '<span style="color:red;font-size:18px; margin: 0 auto;">Username or Password is incorrect</span>';
		}
	}
}
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN">
<html>
<head>





	
	<title>-- pineapple design limited client login --- Web Project Action Center</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Action Center - login</title>

<script src="http://www.google-analytics.com/ga.js" type="text/javascript"></script>

<link rel="shortcut icon" href="images/favicon.ico">


<link href="css/style.css" rel="stylesheet" type="text/css">
	
    
     <!--seo start-->
<meta name="keywords" content="icon designer, webdesign, Hong Kong Famous Designer, server maintainence, website architecture, website development, website designer, interface design, email marketing, web development, web site design, brand development, corporate website design, design studio, flash animation, interactive design, logo design, wordpress designer, cms, crm " />

<meta name="description" content="PINEAPPLE DESIGN LIMITED based in Hong Kong, a bouique scale design studio. Our services from creative idea to final product, included graphic design, web design, interface design, logos, web marketing, corporate identities, ecommerce and backend solutions. For more information, please feel free to contact us at info@pineappledesign.com.hk, or contact directly at (852) 23762766. " />


<!-- Pineapple Design Limited-->
<meta name="author" content="Pineapple Design Limited (http://www.pineappledesign.com.hk)" />

<meta name="copyright" content="copyright 1999-2009 Pineapple Design Limited" />

<meta name="robots" content="index, follow " />

<meta http-equiv="content-language" content="en" />

<!-- google webmaster -->
<meta name="verify-v1" content="ep3jZ6AI9gUPGBnyjI3CkPjkhaQ7SEO3/+zhFNuu8FA=" >
    
    

<style type="text/css">
body {
	background-color: #c4c4c4;
}
</style>
</head>
<body>
<div class="login_bg">

<br>
<table width="934" border="0" align="center" cellpadding="0" cellspacing="0">
  <tr></tr>
</table>
<!--<table width="934" border="0" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <td height="20"><a name="top1"></a></td>
  </tr>
</table>-->
<div style="margin:120px 0 50px 0;">
<form action="login.php" name="login" id="login" method="post">
<table width="925" border="0" align="center" cellpadding="0" cellspacing="0">
  <tr valign="top">
    <td height="108" align="center"><table width="394" border="0" cellpadding="0" cellspacing="2" >
      <tr>
        <td align="center"  valign="top" >
          <?php echo $msg; ?>
          <br>
          <table width="90%" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td width="16%" align="right" valign="middle"  class="text_guide"><strong> username</strong></td>
              <td width="22%" align="left" valign="middle"><p>
                <label>
                  <input type="text" name="username" id="username">
                  </label>
                <br>
                </p></td>
              </tr>
            <tr align="center" valign="middle">
              <td align="right" class="text_guide"><strong>password</strong></td>
              <td width="22%" align="left" valign="middle"><input type="password" name="password" id="password"></td>
              </tr>
            <tr align="center" valign="middle">
              <td class="text_guide">&nbsp;</td>
              <td width="22%" align="left" valign="middle"><input type="submit" name="submit" value="Login">
                <input type="reset" name="reset" value="Reset">
                <input type="hidden" name="login" value="login">
                </td>
              </tr>
            </table><br>
          </td>
      </tr>
    </table></td>
  </tr>
</table>
</form>
</div>
</div>
<div class="alignleft" style="font-size: 10px; font-family: Arial, Helvetica, sans-serif; text-align: center; padding-top: 0px; margin: 0 auto;">copyright 2010 pineapple design limited
			 
  </div>  

<br>
</body>
</html>
