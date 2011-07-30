#!/usr/bin/perl
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
#addpidatq.pl
#
#PID�������atq������롣folprep.pl���饭�塼�����ϤΤ���˻Ȥ���
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
$path =~ s/addpidatq.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}

require "foltialib.pl";


#�����������뤫?
$pid = $ARGV[0] ;
if ($pid eq "" ){
	#�������ʤ��м¹Ԥ��줿�顢��λ
	print "usage;addpidatq.pl <PID>\n";
	exit;
}


#DB����(PID)
$dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;

$sth = $dbh->prepare($stmt{'addpidatq.1'});
$sth->execute($pid);
 @titlecount= $sth->fetchrow_array;
 
 if ($titlecount[0]  == 1 ){
    $sth = $dbh->prepare($stmt{'addpidatq.2'});
    $sth->execute($pid);
 @titlecount= $sth->fetchrow_array;
$bitrate = $titlecount[0];#�ӥåȥ졼�ȼ���
if ($titlecount[1] >= 1){
	$usedigital = $titlecount[1];#�ǥ�����ͥ��ե饰
}else{
	$usedigital = 0;
}

#PID���
    $now = &epoch2foldate(time());

#stationID����recch
    $stationh = $dbh->prepare($stmt{'addpidatq.3'});
    $stationh->execute($pid);
    @stationl =  $stationh->fetchrow_array();
$recch = $stationl[0];
if ($recch eq ""){
	&writelog("addpidatq ERROR recch is NULL:$stmt{'addpidatq.3'}.");
	exit 1;
}
if ($stationl[1] => 1){
	$digitalch = $stationl[1];
}else{
	$digitalch = 0;
}
if ($stationl[2] => 1){
	$digitalstationband = $stationl[2];
}else{
	$digitalstationband = 0;
}
    $sth = $dbh->prepare($stmt{'addpidatq.4'});
    $sth->execute($pid);
($pid ,
$tid ,
$stationid ,
$countno,
$subtitle,
$startdatetime,
$enddatetime,
$startoffset ,
$lengthmin,
$atid ) = $sth->fetchrow_array();
# print "$pid ,$tid ,$stationid ,$countno,$subtitle,$startdatetime,$enddatetime,$startoffset ,$lengthmin,$atid \n";

if($now< $startdatetime){#������̤������դʤ�
#�⤷�����ϻ��郎15ʬ�ܾ���ʤ�ƥ��塼
$startafter = &calclength($now,$startdatetime);
&writelog("addpidatq DEBUG \$startafter $startafter \$now $now \$startdatetime $startdatetime");

if ($startafter > 14 ){

#���塼���
 Schedule::At::remove ( TAG => "$pid"."_X");
	&writelog("addpidatq remove que $pid");


#���塼����
	#�ץ�����ư��������ȳ��ϻ����-5ʬ
$atdateparam = &calcatqparam(300);
	Schedule::At::add (TIME => "$atdateparam", COMMAND => "$toolpath/perl/folprep.pl $pid" , TAG => "$pid"."_X");
	&writelog("addpidatq TIME $atdateparam   COMMAND $toolpath/perl/folprep.pl $pid ");
}else{
$atdateparam = &calcatqparam(60);
$reclength = $lengthmin * 60;

#���塼���
 Schedule::At::remove ( TAG => "$pid"."_R");
	&writelog("addpidatq remove que $pid");

if ($countno eq ""){
	$countno = "0";
}

Schedule::At::add (TIME => "$atdateparam", COMMAND => "$toolpath/perl/recwrap.pl $recch $reclength $bitrate $tid $countno $pid $stationid $usedigital $digitalstationband $digitalch" , TAG => "$pid"."_R");
	&writelog("addpidatq TIME $atdateparam   COMMAND $toolpath/perl/recwrap.pl $recch $reclength $bitrate $tid $countno $pid $stationid $usedigital $digitalstationband $digitalch");

}#end #�⤷�����ϻ��郎15ʬ�ܾ���ʤ�ƥ��塼

}else{
&writelog("addpidatq drop:expire $pid $startafter $now $startdatetime");
}#������̤������դʤ�

}else{
print "error record TID=$tid SID=$station $titlecount[0] match:$DBQuery\n";
&writelog("addpidatq error record TID=$tid SID=$station $titlecount[0] match:$DBQuery");

}#end if ($titlecount[0]  == 1 ){


