#!/usr/bin/perl
#usage recwrap.pl ch length(sec) [bitrate(5)] [TID] [NO] [PID] [stationid] [digitalflag] [digitalband] [digitalch] 
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
#
#�쥳���ǥ��󥰥�å�
#at����ƤӽФ��졢tvrecording��ƤӽФ�Ͽ��
#���Τ���MPEG4�ȥ饳���ƤӽФ�
#
# DCC-JPL Japan/foltia project
#

use DBI;
#use DBD::Pg;
use DBD::SQLite;
use Schedule::At;
use Time::Local;
use Jcode;

$path = $0;
$path =~ s/recwrap.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}

require "foltialib.pl";
#�����������뤫?
$recch = $ARGV[0] ;
if ($recch eq "" ){
	#�������ʤ��Ǽ¹Ԥ��줿�顢��λ
	print "usage recwrap.pl  ch length(sec) [bitrate(5)] [TID] [NO] [PID]\n";
	exit;
}

$recch = $ARGV[0] ;
$reclength = $ARGV[1] ;
$bitrate  = $ARGV[2] ;
$tid  = $ARGV[3] ;
$countno  = $ARGV[4] ;
$pid = $ARGV[5] ;
$stationid = $ARGV[6] ;
$usedigital = $ARGV[7] ;
$digitalstationband = $ARGV[8] ;
$digitalch= $ARGV[9] ;

#DB�����
$dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;


if ($usedigital == 1){
	$extension = ".m2t";#TS�γ�ĥ��
}else{
	$extension = ".m2p";#MPEG2�γ�ĥ��
}
if ($recch == -2 ){ #�饸����
	$extension = ".aac";#MPEG2�γ�ĥ��
}

$outputfile = strftime("%Y%m%d-%H%M", localtime(time + 60));
chomp($outputfile);

if ($tid == 0){
	if ($usedigital == 1){
		$outputfilename = "0--".$outputfile."-".$digitalch.$extension;
		$mp4newstylefilename = "-0--".$outputfile."-".$digitalch;
	}else{
		$outputfilename = "0--".$outputfile."-".$recch.$extension;
		$mp4newstylefilename = "-0--".$outputfile."-".$recch;
	}
}else{
	if ($countno == 0){
		$outputfilename = $tid ."--".$outputfile.$extension;
		$mp4newstylefilename = "-" . $tid ."--".$outputfile;
	}else{
		$outputfilename = $tid ."-".$countno."-".$outputfile.$extension;
		$mp4newstylefilename = "-" . $tid ."-".$countno."-".$outputfile;
	}
}

if ($recch == -2 ){ #�饸����
# stationID����radiko���̻Ҥ����
$sth = $dbh->prepare($stmt{'recwrap.8'});
$sth->execute($stationid);
 @stationline= $sth->fetchrow_array;
$radikostationname = $stationline[3];

$oserr = system("$toolpath/perl/digitalradiorecording.pl $radikostationname $reclength $outputfilename");
$oserr = $oserr / 256;
&writelog("recwrap DEBUG radiko rec finished. $oserr");

# aac�ե�����̾��foltia_subtitlePID�쥳���ɤ˽񤭹���
$sth = $dbh->prepare($stmt{'recwrap.1'});
$sth->execute($outputfilename, $pid);
&writelog("recwrap DEBUG UPDATEDB $stmt{'recwrap.1'}");
&changefilestatus($pid,$FILESTATUSTRANSCODEMP4BOX);

# aac�ե�����̾��foltia_m2pfilesPID�쥳���ɤ˽񤭹���
$sth = $dbh->prepare($stmt{'recwrap.2'});
$sth->execute($outputfilename);
&writelog("recwrap DEBUG UPDATEDB $stmt{'recwrap.2'}");


}else{#��饸���ɤʤ�

if ($usedigital == 1){
#�ǥ�����ʤ�
&writelog("recwrap RECSTART DIGITAL $digitalstationband $digitalch $reclength $stationid 0 $outputfilename $tid $countno friio");
#Ͽ��
    $starttime = time();
$oserr = system("$toolpath/perl/digitaltvrecording.pl $digitalstationband $digitalch $reclength $stationid 0 $outputfilename $tid $countno friio");
$oserr = $oserr / 256;

if ($oserr == 1){
	&writelog("recwrap ABORT recfile exist. [$outputfilename] $digitalstationband $digitalch $reclength $stationid 0  $outputfilename $tid $countno");
	exit;
}elsif ($oserr == 2){
	&writelog("recwrap ERR 2:Device busy;retry.");
	&continuousrecordingcheck;#�⤦������������Ȥ�kill
	sleep(2);
	$oserr = system("$toolpath/perl/digitaltvrecording.pl $digitalstationband $digitalch $reclength $stationid N $outputfilename $tid $countno friio");
	$oserr = $oserr / 256;
	if ($oserr == 2){
	&writelog("recwrap ERR 2:Device busy;Giving up digital recording.");
		if ($recunits > 0 ){
		}else{
			exit;
		}
	}
}elsif ($oserr == 3){
&writelog("recwrap ABORT:ERR 3");
exit ;
}
}else{ # NOT $usedigital == 1
	if ($recunits > 0 ){
	#��⥳�����
	# $haveirdaunit = 1;��⥳��Ĥʤ��Ǥ뤫�ɤ�����ǧ
	if ($haveirdaunit == 1){
	# Ͽ������ͥ뤬0�ʤ�
		if ($recch == 0){
	# &�Ĥ�����Ʊ����changestbch.pl�ƤӽФ�
		&writelog("recwrap Call Change STB CH :$pid");
		system ("$toolpath/perl/changestbch.pl $pid &");
		}#end if
	}#end if
	
	if($recch == -10){
	#������ɤʤ�
		&writelog("recwrap Not recordable channel;exit:PID $pid");
		exit;
		}#end if
	# ���ʥ�Ͽ��
	&writelog("recwrap RECSTART $recch $reclength 0 $outputfilename $bitrate $tid $countno $pid $usedigital $digitalstationband $digitalch");
	
	#Ͽ��
	#system("$toolpath/perl/tvrecording.pl $recch $reclength 0 $outputfile $bitrate $tid $countno");
		$starttime = time();
	
	$oserr = system("$toolpath/perl/tvrecording.pl $recch $reclength 0 $outputfilename $bitrate $tid $countno");
	$oserr = $oserr / 256;
	if ($oserr == 1){
		&writelog("recwrap ABORT recfile exist. [$outputfilename] $recch $reclength 0 0 $bitrate $tid $countno $pid");
		exit;
	}
#�ǥХ����ӥ�����¨�ष�Ƥʤ�������
$now = time();
	if ($now < $starttime + 100){ #Ͽ��ץ�����ư���Ƥ���100�ð������äƤ��Ƥ���
    $retrycounter = 0;
		while($now < $starttime + 100){
			if($retrycounter >= 5){
				&writelog("recwrap WARNING  Giving up recording.");
				last;
			}
		&writelog("recwrap retry recording $now $starttime");
		#���ʥ�Ͽ��
	$starttime = time();
if($outputfilename =~ /.m2t$/){
	$outputfilename =~ s/.m2t$/.m2p/;
}
$oserr = system("$toolpath/perl/tvrecording.pl $recch $reclength N $outputfilename $bitrate $tid $countno");
	$now = time();
$oserr = $oserr / 256;
			if ($oserr == 1){
				&writelog("recwrap ABORT recfile exist. in resume process.[$outputfilename] $recch $reclength 0 0 $bitrate $tid $countno $pid");
				exit;
			}# if
		$retrycounter++;
		}# while
	} # if 

	&writelog("recwrap RECEND [$outputfilename] $recch $reclength 0 0 $bitrate $tid $countno $pid");

	}#end if $recunits > 0
}#endif #�ǥ�����ͥ��ե饰


# m2p�ե�����̾��PID�쥳���ɤ˽񤭹���
$sth = $dbh->prepare($stmt{'recwrap.1'});
$sth->execute($outputfilename, $pid);
&writelog("recwrap DEBUG UPDATEDB $stmt{'recwrap.1'}");
&changefilestatus($pid,$FILESTATUSRECEND);

# m2p�ե�����̾��PID�쥳���ɤ˽񤭹���
$sth = $dbh->prepare($stmt{'recwrap.2'});
$sth->execute($outputfilename);
&writelog("recwrap DEBUG UPDATEDB $stmt{'recwrap.2'}");

# Starlight breaker��������ץ����������

#if (-e "$toolpath/perl/captureimagemaker.pl"){
#	&writelog("recwrap Call captureimagemaker $outputfilename");
#&changefilestatus($pid,$FILESTATUSCAPTURE);
#	system ("$toolpath/perl/captureimagemaker.pl $outputfilename");
#&changefilestatus($pid,$FILESTATUSCAPEND);
#}

}#��饸����

# MPEG4 ------------------------------------------------------
#MPEG4�ȥ饳��ɬ�פ��ɤ���
$sth = $dbh->prepare($stmt{'recwrap.3'});
$sth->execute($tid);
 @psptrcn= $sth->fetchrow_array;
if ($psptrcn[0]  == 1 ){#�ȥ饳������
#	&writelog("recwrap Launch ipodtranscode.pl");
#	exec ("$toolpath/perl/ipodtranscode.pl");
#	exit;
}#PSP�ȥ饳�󤢤�

sub continuousrecordingcheck(){
    my $now = time() + 60 * 2;
&writelog("recwrap DEBUG continuousrecordingcheck() now $now");
my @processes =`ps ax | grep -e recpt1 -e recfriio`; #foltiaBBS �⤦������λ�������ȤΥץ�����kill ����� 2010ǯ08��05��03��19ʬ33�� ��Ƽ� Nis 

my $psline = "";
my @processline = "";
my $pid = "";
my @pid;
my $sth;
foreach (@processes){
	if (/recpt1|friiodetect/) {
		if (/^.[0-9]*\s/){
			push(@pid, $&);
		}#if
	}#if
}#foreach

if (@pid > 0){
my @filenameparts;
my $tid = "";
my $startdate = "";
my $starttime = "";
my $startdatetime = "";
my @recfile;
my $endtime = "";
my $endtimeepoch = "";
foreach $pid (@pid){
#print "DEBUG  PID $pid\n";
&writelog("recwrap DEBUG continuousrecordingcheck() PID $pid");

	my @lsofoutput = `/usr/sbin/lsof -p $pid`;
	my $filename = "";
	#print "recfolferpath $recfolderpath\n";
	foreach (@lsofoutput){
		if (/m2t/){
		@processline = split(/\s+/,$_);
		$filename = $processline[8];
		$filename =~ s/$recfolderpath\///;
		&writelog("recwrap DEBUG continuousrecordingcheck()  FILENAME $filename");
		# 1520-9-20081201-0230.m2t
		@filenameparts = split(/-/,$filename);
		$tid = $filenameparts[0];
		$startdate = $filenameparts[2];
		$starttime = $filenameparts[3];
		@filenameparts = split(/\./,$starttime);
		$startdatetime = $startdate.$filenameparts[0];
		#DB����Ͽ�������ȤΥǡ���õ��
		    &writelog("recwrap DEBUG continuousrecordingcheck() $stmt{'recwrap.7'}");
		    $sth = $dbh->prepare($stmt{'recwrap.7'});
	&writelog("recwrap DEBUG continuousrecordingcheck() prepare");
		    $sth->execute($tid, $startdatetime);
	&writelog("recwrap DEBUG continuousrecordingcheck() execute");
	@recfile = $sth->fetchrow_array;
	&writelog("recwrap DEBUG continuousrecordingcheck() @recfile  $recfile[0] $recfile[1] $recfile[2] $recfile[3] $recfile[4] $recfile[5] $recfile[6] $recfile[7] $recfile[8] $recfile[9] ");
	#��λ����
	$endtime = $recfile[4];
	$endtimeepoch = &foldate2epoch($endtime);
	&writelog("recwrap DEBUG continuousrecordingcheck() $recfile[0] $recfile[1] $recfile[2] $recfile[3] $recfile[4] $recfile[5] endtimeepoch $endtimeepoch");
	if ($endtimeepoch < $now){#�ޤ�ʤ���������Ȥʤ�
		#kill
		system("kill $pid");
		&writelog("recwrap recording process killed $pid/$endtimeepoch/$now");
	}else{
		&writelog("recwrap No processes killed: $endtimeepoch/$now");
	}
		}#endif m2t
	}#foreach lsofoutput
}#foreach
}else{
#print "DEBUG fecfriio NO PID\n";
&writelog("recwrap No recording process killed.");
}
}#endsub



