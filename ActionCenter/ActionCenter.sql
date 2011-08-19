--
-- Table structure for table `action`
--

DROP TABLE IF EXISTS `action`;
CREATE TABLE `action` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(45) NOT NULL,
  `command` varchar(255) NOT NULL,
  `description` varchar(45) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name_UNIQUE` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;

--
-- Table structure for table `history`
--

DROP TABLE IF EXISTS `history`;
CREATE TABLE `history` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `action_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `submit_time` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `last_update` timestamp NULL default NULL,
  `status` enum('NEW','PROCESSING','SUCCESS','FAIL') NOT NULL default 'NEW',
  `stdout` text,
  `stderr` text,
  PRIMARY KEY  (`id`),
  KEY `h_fk_user` (`user_id`),
  KEY `h_fk_action` (`action_id`),
  CONSTRAINT `h_fk_action` FOREIGN KEY (`action_id`) REFERENCES `action` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `h_fk_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=357 DEFAULT CHARSET=latin1 COMMENT='action history';

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `login` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL,
  `name` varchar(50) default NULL,
  `email` varchar(100) default NULL,
  `is_active` tinyint(1) NOT NULL default '1',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `login_UNIQUE` (`login`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

--
-- Table structure for table `user_action`
--

DROP TABLE IF EXISTS `user_action`;
CREATE TABLE `user_action` (
  `user_id` int(10) unsigned NOT NULL,
  `action_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`user_id`,`action_id`),
  KEY `fk_user` (`user_id`),
  KEY `fk_action` (`action_id`),
  CONSTRAINT `fk_action` FOREIGN KEY (`action_id`) REFERENCES `action` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
