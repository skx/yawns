-- MySQL dump 10.15  Distrib 10.0.13-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: yawns
-- ------------------------------------------------------
-- Server version	10.0.13-MariaDB-1~wheezy

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `about_pages`
--

DROP TABLE IF EXISTS `about_pages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `about_pages` (
  `id` varchar(50) NOT NULL DEFAULT '',
  `bodytext` mediumtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `adverts`
--

DROP TABLE IF EXISTS `adverts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `adverts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` varchar(25) NOT NULL DEFAULT '',
  `active` char(1) DEFAULT 'n',
  `link` varchar(255) NOT NULL DEFAULT '',
  `linktext` varchar(255) NOT NULL DEFAULT '',
  `text` mediumtext NOT NULL,
  `clicked` int(11) NOT NULL DEFAULT '0',
  `shown` int(11) NOT NULL DEFAULT '0',
  `display` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `articles`
--

DROP TABLE IF EXISTS `articles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `articles` (
  `id` int(11) NOT NULL DEFAULT '0',
  `title` varchar(65) DEFAULT NULL,
  `author` varchar(25) NOT NULL DEFAULT '',
  `ondate` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `leadtext` mediumtext NOT NULL,
  `bodytext` mediumtext NOT NULL,
  `words` int(11) NOT NULL DEFAULT '0',
  `comments` int(11) NOT NULL DEFAULT '0',
  `readcount` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  FULLTEXT KEY `name` (`bodytext`,`leadtext`,`title`),
  FULLTEXT KEY `title` (`title`,`bodytext`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bookmarks`
--

DROP TABLE IF EXISTS `bookmarks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bookmarks` (
  `gid` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `id` int(11) NOT NULL DEFAULT '0',
  `type` char(1) DEFAULT NULL,
  PRIMARY KEY (`gid`),
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=24802 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent` int(11) NOT NULL DEFAULT '0',
  `title` varchar(75) DEFAULT NULL,
  `author` varchar(25) NOT NULL DEFAULT '',
  `ondate` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `body` mediumtext,
  `ip` varchar(30) DEFAULT NULL,
  `root` int(11) NOT NULL DEFAULT '0',
  `type` char(1) NOT NULL DEFAULT '',
  `score` int(11) DEFAULT '5',
  PRIMARY KEY (`type`,`root`,`id`),
  KEY `scr_auth` (`score`,`author`),
  KEY `auth` (`author`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sender` varchar(25) NOT NULL DEFAULT '',
  `recipient` varchar(25) NOT NULL DEFAULT '',
  `bodytext` mediumtext NOT NULL,
  `status` enum('new','read','deleted') NOT NULL DEFAULT 'new',
  `sent` datetime DEFAULT NULL,
  `replied` datetime DEFAULT NULL,
  PRIMARY KEY (`id`,`recipient`),
  KEY `recipient` (`recipient`),
  KEY `sender` (`sender`),
  KEY `status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=10206 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notifications` (
  `username` varchar(25) NOT NULL DEFAULT '',
  `event` varchar(15) NOT NULL DEFAULT '',
  `type` enum('none','message','email') NOT NULL DEFAULT 'email',
  PRIMARY KEY (`username`,`event`),
  KEY `type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `permissions`
--

DROP TABLE IF EXISTS `permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(25) NOT NULL DEFAULT '',
  `permission` varchar(25) NOT NULL DEFAULT '0',
  PRIMARY KEY (`username`,`permission`),
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=42245 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `poll_anon_voters`
--

DROP TABLE IF EXISTS `poll_anon_voters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `poll_anon_voters` (
  `ip_address` varchar(40) NOT NULL DEFAULT '',
  `poll_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ip_address`,`poll_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `poll_answers`
--

DROP TABLE IF EXISTS `poll_answers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `poll_answers` (
  `id` int(11) NOT NULL DEFAULT '0',
  `poll_id` int(11) NOT NULL DEFAULT '0',
  `answer` varchar(100) NOT NULL DEFAULT '',
  `votes` int(11) DEFAULT '0',
  PRIMARY KEY (`id`,`poll_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `poll_questions`
--

DROP TABLE IF EXISTS `poll_questions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `poll_questions` (
  `id` int(11) NOT NULL DEFAULT '0',
  `survey_id` int(11) NOT NULL DEFAULT '0',
  `question` varchar(100) NOT NULL DEFAULT '',
  `total_votes` int(11) DEFAULT '0',
  `author` varchar(11) DEFAULT NULL,
  `ondate` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `poll_submissions`
--

DROP TABLE IF EXISTS `poll_submissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `poll_submissions` (
  `id` int(11) NOT NULL DEFAULT '0',
  `author` varchar(25) NOT NULL DEFAULT '',
  `ip` varchar(30) DEFAULT NULL,
  `question` varchar(100) NOT NULL DEFAULT '',
  `ondate` date DEFAULT NULL,
  KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `poll_submissions_answers`
--

DROP TABLE IF EXISTS `poll_submissions_answers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `poll_submissions_answers` (
  `id` int(11) NOT NULL DEFAULT '0',
  `poll_id` int(11) NOT NULL DEFAULT '0',
  `answer` varchar(100) NOT NULL DEFAULT '',
  KEY `poll_id` (`poll_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `poll_voters`
--

DROP TABLE IF EXISTS `poll_voters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `poll_voters` (
  `username` varchar(25) NOT NULL DEFAULT '',
  `poll_id` int(11) NOT NULL DEFAULT '0',
  `answer_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`username`,`poll_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `preferences`
--

DROP TABLE IF EXISTS `preferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `preferences` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `pref_name` varchar(25) DEFAULT '',
  `pref_value` varchar(125) DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `pref_name` (`pref_name`)
) ENGINE=InnoDB AUTO_INCREMENT=5059 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `scratchpads`
--

DROP TABLE IF EXISTS `scratchpads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scratchpads` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `content` mediumtext,
  `security` enum('public','private') NOT NULL DEFAULT 'public',
  PRIMARY KEY (`id`),
  KEY `security` (`security`)
) ENGINE=InnoDB AUTO_INCREMENT=5118 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `submissions`
--

DROP TABLE IF EXISTS `submissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `submissions` (
  `id` int(11) NOT NULL DEFAULT '0',
  `user_id` int(11) DEFAULT NULL,
  `title` varchar(65) DEFAULT NULL,
  `ondate` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `bodytext` mediumtext NOT NULL,
  `ip` varchar(30) DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT '0',
  `tag` varchar(25) NOT NULL DEFAULT '',
  `root` int(11) NOT NULL DEFAULT '0',
  `type` char(1) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`,`type`,`root`),
  KEY `id` (`user_id`),
  KEY `tag` (`tag`),
  KEY `root` (`root`)
) ENGINE=InnoDB AUTO_INCREMENT=15373 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tips`
--

DROP TABLE IF EXISTS `tips`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tips` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `ondate` datetime DEFAULT NULL,
  `title` varchar(100) DEFAULT NULL,
  `tip` mediumtext NOT NULL,
  `score` int(11) DEFAULT '5',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=144 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `username` varchar(25) NOT NULL DEFAULT '',
  `password` varchar(32) DEFAULT NULL,
  `realemail` varchar(50) NOT NULL DEFAULT '',
  `fakeemail` varchar(50) DEFAULT NULL,
  `realname` varchar(50) DEFAULT NULL,
  `url` varchar(100) DEFAULT NULL,
  `sig` varchar(250) DEFAULT NULL,
  `bio` mediumtext,
  `joined` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `headlines` int(11) DEFAULT '1',
  `polls` int(11) DEFAULT '1',
  `viewadverts` int(11) DEFAULT '1',
  `blogs` int(11) DEFAULT '1',
  `suspended` tinyint(4) DEFAULT '0',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip` varchar(35) DEFAULT NULL,
  `salt` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=142552 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `weblogs`
--

DROP TABLE IF EXISTS `weblogs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `weblogs` (
  `username` varchar(25) NOT NULL DEFAULT '',
  `ondate` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `title` varchar(50) DEFAULT NULL,
  `bodytext` mediumtext,
  `id` int(11) DEFAULT NULL,
  `gid` int(11) NOT NULL AUTO_INCREMENT,
  `comments` int(11) DEFAULT '0',
  `readcount` int(11) DEFAULT '0',
  `score` int(11) DEFAULT '5',
  PRIMARY KEY (`gid`),
  KEY `ondate` (`ondate`),
  KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=17855 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-08-24 11:21:39
