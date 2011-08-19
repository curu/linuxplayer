<?php

class User {
	
	private $uid;
	private $fields;
	
	public function __construct() {
		$this->uid = NULL;
		$this->fields = array('username'=>'',
							  'realname'=>'',
							  'password'=>'',
							  'email'=>'',
							  'isActive'=>true
		);
	}
	
	public function __get($field){
		if($field == 'uid'){
			return $this->uid;
		}else{
			return $this->fields[$field];
		}
	}
	
	public function __set($field,$value){
		if(array_key_exists($field,$this->fields)){
			$this->fields[$field] = $value;
		}
	}
	
	public static function validateUsername($username){
		return preg_match('/^[a-z0-9]{2,50}$/i',$username);
	}
	
	public static function validateEmail($email){
		return filter_var($email,FILTER_VALIDATE_EMAIL);
	}
	
	public static function getByID($uid){
		$user = new User();
		$query = sprintf("SELECT `login`,`name`,`password`,`email`,`is_active`".
						 " FROM `user` WHERE `id` = %d",$uid);
		$result = mysqli_query($GLOBALS['mysqli'],$query);
		if($result->num_rows){
			$row = $result->fetch_assoc();
			$user->username = $row['login'];
			$user->realname = $row['name'];
			$user->password = $row['password'];
			$user->email = $row['email'];
			$user->isActive = $row['is_active'];
			$user->uid = $uid;
			
			$result->free();
		}
		return $user;
	}
	
	public static function getByUsername($username){
		$user = new User();
		$query = sprintf("SELECT `id`,`name`,`password`,`email`,`is_active`".
						 " FROM `user` WHERE `login` = '%s'",$username);
		$result = mysqli_query($GLOBALS['mysqli'],$query);
		if($result->num_rows){
			$row = $result->fetch_assoc();
			$user->uid = $row['id'];
			$user->realname = $row['name'];
			$user->password = $row['password'];
			$user->email = $row['email'];
			$user->isActive = $row['is_active'];
			$user->username = $username;
			
			$result->free();
		}
		return $user;
	}
	
	//save record to database
	public function save(){
		if($this->uid){
			$query = sprintf('UPDATE `user` SET `login` = "%s",'.
				'`name` = "%s",`password` = "%s", `email` = "%s",'.
				'`is_active` = %d WHERE `id` = %d',
				mysqli_real_escape_string($GLOBALS['mysqli'],$this->username),
				mysqli_real_escape_string($GLOBALS['mysqli'],$this->realname),
				mysqli_real_escape_string($GLOBALS['mysqli'],$this->password),
				mysqli_real_escape_string($GLOBALS['mysqli'],$this->email),
				$this->isActive,
			mysqli_real_escape_string($GLOBALS['mysqli'],$this->uid));
				
			return mysqli_query($GLOBALS['mysqli'],$query);
		}else{
			$query = sprintf('INSERT INTO user(`login`,`name`,`password`,'.
				'`email`,`is_active`) VALUES("%s","%s","%s","%s",%d)',
				mysqli_real_escape_string($GLOBALS['mysqli'],$this->username),
				mysqli_real_escape_string($GLOBALS['mysqli'],$this->realname),
				mysqli_real_escape_string($GLOBALS['mysqli'],$this->password),
				mysqli_real_escape_string($GLOBALS['mysqli'],$this->email),
				$this->isActive);
			if(mysqli_query($GLOBALS['mysqli'],$query)){
				$this->uid = mysqli_insert_id($GLOBALS['mysqli']);
				return true;
			}else{
				return false;
			}
			
		}
	}
	
	public static function delete($uid){
		$query = sprintf('DELETE FROM `user` WHERE `id` = %d',$uid);
		return mysqli_query($GLOBALS['mysqli'],$query);
	}
	
	public function setActive(){
		$this->isActive = true;
		$this->save();
	}
	
	public function setInactive(){
		$this->isActive = false;
		$this->save();
	}
	
	
	
}

?>