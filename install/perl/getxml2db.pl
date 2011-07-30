#!/usr/bin/perl
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
# usage :getxml2db [long]
#����ܤ���������<http://cal.syoboi.jp/>�������ȥǡ���XML�������foltia DB�˥���ݡ��Ȥ���
#
#���ץ����
#long:2����ʬ�����ࡣ���Υ⡼�ɤǰ������󤻤Ф褤�Ǥ��礦��
#
# DCC-JPL Japan/foltia project
#
#

use LWP::Simple;
use Jcode;
use Time::Local;
use DBI;
#use DBD::Pg;
use DBD::SQLite;
use Digest::MD5 qw(md5_hex);

$path = $0;
$path =~ s/getxml2db.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}
require "foltialib.pl";


$processes =  &processfind("getxml2db.pl");
if ($processes > 1 ){
#print "process  found:$processes\n";
&writelog("getxml2db   processes exist. exit:");
exit;
}else{
#print "process NOT found:$processes\n";
&writelog("getxml2db  Normal launch.");
}

# http://sites.google.com/site/syobocal/spec/cal_chk-php
#if ($ARGV[0]  eq "long"){
#	$uri="http://cal.syoboi.jp/cal_chk.php";
#	#$uri="http://syobocal.orz.hm/cal_chk.php";
#	&writelog("getxml2db  use long mode.");
#}else{
#	$uri="http://cal.syoboi.jp/cal_chk.xml";
#	#$uri="http://syobocal.orz.hm/cal_chk.xml";
#}
$uri = "http://cal.syoboi.jp/cal_chk.php?days=";
$uri .= ($ARGV[0] eq "long")? 14: 7;

$dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;

$dbh->{AutoCommit} = 0;

# If-Modified-Since�Ȥ��褦���ѹ�#2008/11/14 
my  $CacheDir = '/tmp/shobocal';
if (! -e $CacheDir) {
	mkdir $CacheDir or die "cannot create $CacheDir: $!";
}
my $cache = sprintf("%s/%s.xml", $CacheDir, Digest::MD5::md5_hex($uri));
LWP::Simple::mirror($uri, $cache) or die "cannot get content from $uri";
open(SHOBO, "<$cache");
my (@line) = <SHOBO>;
close(SHOBO);
#my ($content) = get("$uri");
#if ($content eq ""){
#&writelog("getxml2db   no responce from $uri, exit:");
#	exit;#����ܤ��뤬����Ƥ���ʤ�
#}
#my (@line) = split(/\n/, $content);

foreach(@line){
s/\xef\xbd\x9e/\xe3\x80\x9c/g; #wavedash
s/\xef\xbc\x8d/\xe2\x88\x92/g; #hyphenminus
s/&#([0-9A-Fa-f]{2,6});/(chr($1))/eg; #'ͷ����5D&#039;s'�Ȥ��ο��ͻ����б���

Jcode::convert(\$_,'euc','utf8'); 

#<ProgItem PID="21543" TID="528" StTime="20041114213000" EdTime="20041114220000" ChName="AT-X" Count="4" StOffset="0" SubTitle="������衢����ʥ��" Title="���Ȥ����ȡ��꡼ ŷ�ȤΤ��ä�" ProgComment=""/>
if (/^<ProgItem /){
s/<ProgItem //i;
s/\"\/>/\" /i;
s/\"[\s]/\";\n/gio;
s/\'/\\'/gio;
s/\"/\'/gio;
#s/[\w]*=/\$item{$&}=/gio;
#s/\=}=/}=/gio;
s/(\w+)=/\$item{$1}=/gio;#by foltiaBBS

#$item{PID}='21543';
#$item{TID}='528';
#$item{StTime}='20041114213000';
#$item{EdTime}='20041114220000';
#$item{ChName}='AT-X';
#$item{Count}='4';
#$item{StOffset}='0';
#$item{SubTitle}='������衢����ʥ��';
#$item{Title}='���Ȥ����ȡ��꡼ ŷ�ȤΤ��ä�';
#$item{ProgComment}='';
eval("$_");
#Jcode::convert(\$item{Title},'euc');

$programtitlename = $item{Title};
$programtitlename =~ s/\&lt\;/</gi;
$programtitlename =~ s/\&gt\;/>/gi;
$programtitlename =~ s/\&amp\;/\&/gi;
#	$programtitle = $dbh->quote($programtitlename);
	$programtitle = $programtitlename;

#Jcode::convert(\$item{ChName},'euc');
#Jcode::convert(\$item{SubTitle},'euc');

#$programSubTitle = $dbh->quote($item{SubTitle});
$programSubTitle = $item{SubTitle};
$programSubTitle =~ s/\&lt\;/</gi;
$programSubTitle =~ s/\&gt\;/>/gi;
$programSubTitle =~ s/\&amp\;/\&/gi;
#	$programSubTitle = $dbh->quote($programSubTitle);

$offsetmin = $item{StOffset}/60;
$edtime = &syobocaldate2foltiadate($item{EdTime});
$sttime = &syobocaldate2foltiadate($item{StTime});
$length = &calclength($sttime,$edtime);
$recstartdate = &calcoffsetdate($sttime ,$offsetmin );
$recenddate = &calcoffsetdate($edtime ,$offsetmin );

$stationid = &getstationid($item{ChName});
#���֥����ȥ��ɲ�-------------------------------------------------
#���Ȥ����뤫��ǧ
	$sth = $dbh->prepare($stmt{'getxml2db.1'});
	$sth->execute($item{TID});
 @titlecount= $sth->fetchrow_array;
 
 if ($titlecount[0] == 0){
#�ʤ�����ɲ�

#200412012359
$nomalstarttime = substr($sttime,8,4);

	    $sth = $dbh->prepare($stmt{'getxml2db.2'});
	    $oserr = $sth->execute($item{TID}, $programtitle, '', $nomalstarttime, $length, '', '', 3, 1, '', '');
	    &writelog("getxml2db  ADD TV Progtam:$item{TID}:$programtitle");
}else{
#2006/2/26 
#���ä��顢�����ȥ��ǧ����
	    $sth = $dbh->prepare($stmt{'getxml2db.3'});
	    $sth->execute($item{TID});
 @titlearray = $sth->fetchrow_array;
#�����ʤɤ���Ƥ���update
#print "$titlearray[0] / $programtitle\n";
 if ($titlearray[0] ne "$programtitlename" ){
		$sth = $dbh->prepare($stmt{'getxml2db.4'});
		$oserr = $sth->execute($programtitle, $item{TID});
	&writelog("getxml2db  UPDATE TV Progtam:$item{TID}:$programtitle");
 }#end if update
}# end if TID


#PID�����뤫��ǧ
	$sth = $dbh->prepare($stmt{'getxml2db.5'});
	$sth->execute($item{'TID'}, $item{'PID'});
 @subticount= $sth->fetchrow_array;
 if ($subticount[0]  >= 1){
	#PID���ä����񤭹���
#�����Ǥ���ʥ��顼�ФƤ�
#	DBD::Pg::st execute failed: ERROR:  invalid input syntax for type bigint: "" at /home/foltia/perl/getxml2db.pl line 147.
#UPDATE  foltia_subtitle  SET stationid = '42',countno = '8',subtitle = '���ԹԤ��ޤ�' ,startdatetime = '200503010035'  ,enddatetime = '200503010050',startoffset  = '0' ,lengthmin = '15' WHERE tid = '550' AND pid =  '26000' 
if ($item{Count} == ""){
		$sth = $dbh->prepare($stmt{'getxml2db.6'});
		$oserr = $sth->execute($stationid, undef, $programSubTitle, $recstartdate, $recenddate, $offsetmin, $length, $item{'TID'}, $item{'PID'});
}else{
		$sth = $dbh->prepare($stmt{'getxml2db.7'});
		$oserr = $sth->execute($stationid, $item{'Count'}, $programSubTitle,  $recstartdate, $recenddate, $offsetmin, $length, $item{'TID'}, $item{'PID'});
	    }
 }else{
	#�ʤ�����ɲ�
	
	#���ä����������ϥ��ե��åȤ��줿����!
	#���Τޤޥ��塼���������
	if ($item{Count} eq ""){
		$sth = $dbh->prepare($stmt{'getxml2db.8'});
		$oserr = $sth->execute($item{'PID'}, $item{'TID'}, $stationid, undef, $programSubTitle, $recstartdate, $recenddate, $offsetmin, $length);
	}else{
		$sth = $dbh->prepare($stmt{'getxml2db.9'});
		$oserr = $sth->execute($item{'PID'}, $item{'TID'}, $stationid, $item{'Count'}, $programSubTitle, $recstartdate, $recenddate, $offsetmin, $length);
	}
}

#print "$DBQuery\n\n\n";
#debug 20050803
#&writelog("getxml2db $DBQuery");


}#if
}#foreach

$oserr = $dbh->commit;
##	$dbh->disconnect();
