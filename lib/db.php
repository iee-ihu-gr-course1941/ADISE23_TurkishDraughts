<?php

$host='localhost';
$db = 'adise2023';
$user='iee2019079';
$pass='';

if(gethostname()=='users.iee.ihu.gr') {
	$mysqli = new mysqli($host, $user, $pass, $db, null, '/home/student/iee/2019/iee2019079/mysql/run/mysql.sock');
} else {
    $mysqli = new mysqli($host, $user, $pass, $db);
}

if ($mysqli->connect_errno) {
    echo "Failed to connect to MySQL: (" . 
    $mysqli-> connect_errno . ") " . $mysqli->connect_error;
}?>