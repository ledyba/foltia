#!/usr/bin/perl
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
#schedulecheck.pl
#
#DB��ͽ�󤫤����Ū��ͽ�󥭥塼����Ф��ޤ�
#
# DCC-JPL Japan/foltia project
#
#

use DBI;
#use DBD::Pg;
use DBD::SQLite;
use Schedule::At;
use Time::Local;

$path = $0;
$path =~ s/schedulecheck.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}

require "foltialib.pl";

#XML���å�&����
system("$toolpath/perl/getxml2db.pl");

#ͽ������õ��
$now = &epoch2foldate(time());
$now = &epoch2foldate($now);
$checkrangetime = $now   + 15*60;#15ʬ��ޤ�
$checkrangetime =  &epoch2foldate($checkrangetime);

$dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;

$sth = $dbh->prepare($stmt{'schedulecheck.1'});
	$sth->execute();
 @titlecount= $sth->fetchrow_array;

 if ($titlecount[0]  == 0 ){
exit;
}else{
    $sth = $dbh->prepare($stmt{'schedulecheck.2'});
	$sth->execute();
while (($tid,$stationid  ) = $sth->fetchrow_array()) {
#���塼������
system ("$toolpath/perl/addatq.pl $tid $stationid  ");
&writelog("schedulecheck  $toolpath/perl/addatq.pl $tid $stationid ");

}#while

#EPG����
system("$toolpath/perl/epgimport.pl");
}
