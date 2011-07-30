#!/usr/bin/perl
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
#addatq.pl
#
#TID�ȶ�ID��������atq�������
# addatq.pl <TID> <StationID> [DELETE]
# DELETE�ե饰���Ĥ��Ⱥ���Τ߹Ԥ�
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
$path =~ s/addatq.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}

require "foltialib.pl";

#�����������뤫?
$tid = $ARGV[0] ;
$station = $ARGV[1];

if (($tid eq "" )|| ($station eq "")){
	#�������ʤ��м¹Ԥ��줿�顢��λ
	print "usage;addatq.pl <TID> <StationID> [DELETE]\n";
	exit;
}

#DB����(TID��StationID����PID��)
$dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;

if ($station == 0){
    $sth = $dbh->prepare($stmt{'addatq.1'});
    $sth->execute($tid);
}else{
    $sth = $dbh->prepare($stmt{'addatq.2'});
    $sth->execute($tid, $station);
}
 @titlecount = $sth->fetchrow_array;
#���������

#2�ʾ���ä���
if ($titlecount[0]  >= 2){
    #����Ͽ�꤬�ޤޤ�Ƥ��뤫Ĵ�٤�
    $kth = $dbh->prepare($stmt{'addatq.3'});
    $kth->execute($tid);
 	@reservecounts = $kth->fetchrow_array;

	if($reservecounts[0] >= 1 ){#�ޤޤ�Ƥ�����
		if($tid == 0){
		#����ΰ�������SID 0���ä���
	    #����Ͽ�����ͽ��
#		&writelog("addatq  DEBUG; ALL STATION RESERVE. TID=$tid SID=$station $titlecount[0] match:$stmt{'addatq.3'}");
		&addcue;
		}else{
		#�ۤ�������Ͽ��addatq��ͽ������Ƥ���뤫��ʤˤ⤷�ʤ�
#		&writelog("addatq  DEBUG; SKIP OPERSTION. TID=$tid SID=$station $titlecount[0] match:$stmt{'addatq.3'}");
		exit;
  		}#end if �դ��ޤ�Ƥ�����
	}#endif 2�İʾ�	
}elsif($titlecount[0]  == 1){
		&addcue;
}else{
    &writelog("addatq  error; reserve impossible . TID=$tid SID=$station $titlecount[0] match:$stmt{'addatq.3'}");
}

#�����
# if ($titlecount[0]  == 1 ){
# 	& addcue;
# }else{
#&writelog("addatq  error record TID=$tid SID=$station $titlecount[0] match:$stmt{'addatq.3'}");
#}

sub addcue{

if ($station == 0){
	$sth = $dbh->prepare($stmt{'addatq.addcue.1'});
	$sth->execute($tid);
}else{
	$sth = $dbh->prepare($stmt{'addatq.addcue.2'});
	$sth->execute($tid, $station);
}
 @titlecount= $sth->fetchrow_array;
$bitrate = $titlecount[2];#�ӥåȥ졼�ȼ���

#PID���
    $now = &epoch2foldate(time());
    $twodaysafter = &epoch2foldate(time() + (60 * 60 * 24 * 2));
#���塼�����ľ��2����ޤ�
if ($station == 0 ){
	$sth = $dbh->prepare($stmt{'addatq.addcue.3'});
	$sth->execute($tid, $now, $twodaysafter);
}else{
#stationID����recch
	$stationh = $dbh->prepare($stmt{'addatq.addcue.4'});
	$stationh->execute($station);
@stationl =  $stationh->fetchrow_array;
$recch = $stationl[1];

	$sth = $dbh->prepare($stmt{'addatq.addcue.5'});
	$sth->execute($tid, $station, $now, $twodaysafter);
    }
 
while (($pid ,
$tid ,
$stationid ,
$countno,
$subtitle,
$startdatetime,
$enddatetime,
$startoffset ,
$lengthmin,
$atid ) = $sth->fetchrow_array()) {

if ($station == 0 ){
#stationID����recch
	    $stationh = $dbh->prepare($stmt{'addatq.addcue.6'});
	    $stationh->execute($stationid);
@stationl =  $stationh->fetchrow_array;
$recch = $stationl[1];
}
#���塼����
	#�ץ�����ư��������ȳ��ϻ����-1ʬ
$atdateparam = &calcatqparam(300);
$reclength = $lengthmin * 60;
#&writelog("TIME $atdateparam COMMAND $toolpath/perl/tvrecording.pl $recch $reclength 0 0 $bitrate $tid $countno");
#���塼���
 Schedule::At::remove ( TAG => "$pid"."_X");
	&writelog("addatq remove $pid");
if ( $ARGV[2] eq "DELETE"){
	&writelog("addatq remove  only $pid");
}else{
	Schedule::At::add (TIME => "$atdateparam", COMMAND => "$toolpath/perl/folprep.pl $pid" , TAG => "$pid"."_X");
	&writelog("addatq TIME $atdateparam   COMMAND $toolpath/perl/folprep.pl $pid ");
}
##processcheckdate 
#&writelog("addatq TIME $atdateparam COMMAND $toolpath/perl/schedulecheck.pl");
}#while



}#endsub
