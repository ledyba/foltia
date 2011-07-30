#!/usr/bin/perl
#
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
# epgimport.pl
#
# EPG����ɽ����
# ts���������epgdump��ͳ��epg�ơ��֥�˥���ݡ��Ȥ��ޤ���
# ������xmltv2foltia.pl��Ƥ�Ǽºݤ��ɲý�����Ԥ��ޤ���
#
# usage 
# epgimport.pl [long]  #long���Ĥ��Ȱ콵��ʬ
# epgimport.pl [stationid]  #������ID����Ǥ��Υ����ͥ����û���֤Ǽ���
#
# DCC-JPL Japan/foltia project
#

use DBI;
#use DBD::Pg;
use DBD::SQLite;
#use Schedule::At;
#use Time::Local;
use Jcode;

$path = $0;
$path =~ s/epgimport.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}

require "foltialib.pl";

my $ontvcode = "";
my $channel = "";
my @date = ();
my $recpt1path = $toolpath . "/perl/tool/recpt1"; #�ۤ��Υ���ץ���ǥХ�����äƤ�ͤϥ������ѹ�
my $epgdumppath = $toolpath ."/perl/tool"; #epgdump�Τ���ǥ��쥯�ȥ�
my $xmloutpath = "/tmp";
my %stations;
my $uset = "";
my $usebs = "";
my $usecs = "";
my $stationid = "" ;
my $rectime = 0;
my $bsrectime = 0;
my $cs1rectime = 0;
my $cs2rectime = 0;


#�����������뤫?
if ( $ARGV[0] eq "long" ){
	#Ĺ������ɽ����
	$rectime = 60;
	$bsrectime = 120;
	$cs1rectime = 60;
	$cs2rectime = 60;
}elsif( $ARGV[0] > 0 ){
	$stationid = $ARGV[0]; 
	$rectime = 3;
	$bsrectime = 36;
	$cs1rectime = 15;
	$cs2rectime = 5;
}else{
	#û������ɽ����
	$rectime = 3;
	$bsrectime = 36;
	$cs1rectime = 15;
	$cs2rectime = 5;
}
#�ǡ��������
#3��   16350 Aug 10 16:21 __27-epg-short.xml
#12��  56374 Aug 10 16:21 __27-epg-long.xml
#60�� 127735 Aug 10 16:23 __27-epg-velylong.xml

#��ʣ��ư��ǧ
$processes =  &processfind("epgimport.pl");
if ($processes > 1 ){
&writelog("epgimport processes exist. exit:");
exit;
}


$dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;

#�ɻ��꤬����ʤ顢ñ�������ɻ���⡼��
if ($stationid > 0){
	$sth = $dbh->prepare($stmt{'epgimport.1'});
	$sth->execute($stationid);
	@data = $sth->fetchrow_array();
	unless($data[0] == 1){#�ɤο���1�Ǥʤ���а۾ｪλ
		&writelog("epgimport ERROR Invalid station id ($stationid).");
		exit 1;
	}else{
	$sth = $dbh->prepare($stmt{'epgimport.2'});
	$sth->execute($stationid);
	@data = $sth->fetchrow_array();
	$channel = $data[0];
	$ontvcode = $data[1];
	if ($channel > 0){
		&writelog("epgimport DEBUG Single station mode (ch:$channel / $ontvcode).");
	}else{#�饸���ɤʤɤξ��
		&writelog("epgimport ABORT SID $stationid is not Digital TV ch.");
		exit;
	}#endif �饸���ɤ��ɤ���
	}#end unless($data[0] == 1
}#endif $stationid > 0

#�ϥǥ�----------------------------------------
#�����ɳ�ǧ
if ($channel >= 13 && $channel <= 62){#�ɻ��꤬����ʤ�
	$stations{$channel} = $ontvcode;
	$uset = 1;
}elsif($channel >= 100){
	$uset = 0; #�ϥǥ��ϰϳ��ζ�
}else{
	$sth = $dbh->prepare($stmt{'epgimport.3'});
	$sth->execute();
	
	while (@data = $sth->fetchrow_array()) {
		$stations{$data[0]} = $data[1];
	}#end while 
	$uset = 1;
}#end if

if ($uset == 1){
foreach $channel ( keys %stations ) {
	$ontvcode = $stations{$channel};
	#print "$ontvcode $digitalch\n";
	&chkrecordingschedule;
	#print "$recpt1path $channel $rectime $recfolderpath/__$channel.m2t\n";
	$oserr = `$recpt1path $channel $rectime $recfolderpath/__$channel.m2t`;
	#print "$epgdumppath/epgdump $ontvcode $recfolderpath/__$channel.m2t $xmloutpath/__$channel-epg.xml\n";
	$oserr = `$epgdumppath/epgdump $ontvcode $recfolderpath/__$channel.m2t $xmloutpath/__$channel-epg.xml`;
	#print "cat $xmloutpath/__$channel-epg.xml | $toolpath/perl/xmltv2foltia.pl\n";
	$oserr = `cat $xmloutpath/__$channel-epg.xml | $toolpath/perl/xmltv2foltia.pl`;
	unlink "$recfolderpath/__$channel.m2t";
	unlink "$xmloutpath/__$channel-epg.xml";
}#end foreach
}#endif

#BS----------------------------------------
#�����ɳ�ǧ
if ($channel >= 100 && $channel <= 222 ){#�ɻ��꤬����ʤ�
	$usebs = 1;
}elsif($channel >= 13 && $channel <= 62){
	$usebs = 0;	#�ϥǥ��ɻ���ξ�硢�����åס�
}elsif($channel >= 223){
	$usebs = 0;	#CS�ɻ���ξ��⥹���å�
}else{
	$sth = $dbh->prepare($stmt{'epgimport.4'});
	$sth->execute();
	@data = $sth->fetchrow_array();
	if ($data[0] > 0 ){
		$usebs = 1;
	}
}#end if

if ($usebs == 1){
	#$ontvcode = $stations{$channel};
	$channel = 211;
	#print "$ontvcode $digitalch\n";
	&chkrecordingschedule;
	#print "$recpt1path $channel $bsrectime $recfolderpath/__$channel.m2t\n";
	$oserr = `$recpt1path $channel $bsrectime $recfolderpath/__$channel.m2t`;
	#print "$epgdumppath/epgdump /BS $recfolderpath/__$channel.m2t $xmloutpath/__$channel-epg.xml\n";
	$oserr = `$epgdumppath/epgdump /BS $recfolderpath/__$channel.m2t $xmloutpath/__$channel-epg.xml`;
	#print "cat $xmloutpath/__$channel-epg.xml | $toolpath/perl/xmltv2foltia.pl\n";
	$oserr = `cat $xmloutpath/__$channel-epg.xml | $toolpath/perl/xmltv2foltia.pl`;
	unlink "$recfolderpath/__$channel.m2t";
	unlink "$xmloutpath/__$channel-epg.xml";
}else{
	&writelog("epgimport DEBUG Skip BS.$channel:$usebs");
}



#CS----------------------------------------
#if ( $ARGV[0] eq "long" ){ #û����Ͽ��ʤ�۾�˽Ť��Ϥʤ�ʤ����Ȥ�ȯ������
#�����ɳ�ǧ
if ($channel >= 223  ){#�ɻ��꤬����ʤ�
	$usecs = 1;
}else{
	$sth = $dbh->prepare($stmt{'epgimport.5'});
	$sth->execute();
	@data = $sth->fetchrow_array();
	if ($data[0] > 0 ){
		$usecs = 1;
	}
}#end if

if ($usecs == 1){
#�쵤��Ͽ�褷��
	$channela = "CS8";
	#print "$ontvcode $digitalch\n";
	&chkrecordingschedule;
	#print "$recpt1path $channela $bsrectime $recfolderpath/__$channela.m2t\n";
	$oserr = `$recpt1path $channela $cs1rectime $recfolderpath/__$channela.m2t`;

	$channelb = "CS24";
	&chkrecordingschedule;
	#print "$recpt1path $channelb $bsrectime $recfolderpath/__$channelb.m2t\n";
	$oserr = `$recpt1path $channelb $cs2rectime $recfolderpath/__$channelb.m2t`;

#���֤Τ�����epgdump�ޤȤ�Ƥ��Ȥޤ路
	#print "nice -n 19 $epgdumppath/epgdump /CS $recfolderpath/__$channela.m2t $xmloutpath/__$channela-epg.xml\n";
	$oserr = `$epgdumppath/epgdump /CS $recfolderpath/__$channela.m2t $xmloutpath/__$channela-epg.xml`;
	#print "cat $xmloutpath/__$channela-epg.xml | $toolpath/perl/xmltv2foltia.pl\n";
	$oserr = `cat $xmloutpath/__$channela-epg.xml | $toolpath/perl/xmltv2foltia.pl`;
	unlink "$recfolderpath/__$channela.m2t";
	unlink "$xmloutpath/__$channela-epg.xml";

	#print "nice -n 19 $epgdumppath/epgdump /CS $recfolderpath/__$channelb.m2t $xmloutpath/__$channelb-epg.xml\n";
	$oserr = `$epgdumppath/epgdump /CS $recfolderpath/__$channelb.m2t $xmloutpath/__$channelb-epg.xml`;
	#print "cat $xmloutpath/__$channelb-epg.xml | $toolpath/perl/xmltv2foltia.pl\n";
	$oserr = `cat $xmloutpath/__$channelb-epg.xml | $toolpath/perl/xmltv2foltia.pl`;
	unlink "$recfolderpath/__$channelb.m2t";
	unlink "$xmloutpath/__$channelb-epg.xml";
}else{
	&writelog("epgimport DEBUG Skip CS.");
}#endif use 
#}else{
#	if ($channel >= 223  ){#�ɻ��꤬����ʤ�
#		&writelog("epgimport ERROR CS Station No. was ignored. CS EPG get long mode only.");
#	}
#}#end if long


sub chkrecordingschedule{
#����ͽ��ޤǶ᤯�ʤä��顢���塼�ʡ��Ȥ��ĤŤ��ʤ��褦��EPG��������
my $now = time() ;
my $fiveminitsafter = time() + 60 * 4;
my $rows = -2;
$now = &epoch2foldate($now);
$fiveminitsafter = &epoch2foldate($fiveminitsafter);

#Ͽ��ͽ�����
$sth = $dbh->prepare($stmt{'epgimport.6'});
$sth->execute($now,$fiveminitsafter,$now,$fiveminitsafter);

while (@data = $sth->fetchrow_array()) {
#
}#end while 

$rows = $sth->rows;

if ($rows > 0 ){
	&writelog("epgimport ABORT The recording schedule had approached.");
	exit ;
}else{
	&writelog("epgimport DEBUG Near rec program is $rows.:$now:$fiveminitsafter");
}#end if 
}#endsub chkrecordingschedule

