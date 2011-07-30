#!/usr/bin/perl
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
#usage singletranscode.pl [563-1-20051022-1830.m2p] (PATH�ʤ���)
#
#�ȥ饳���å�
#����˥��ƥʥ���
# �ե�����̾���Ť��ޤ�
#
#faac�ǻɤ������ffmpeg�Ĥ��ä��̤Υȥ饳����ƤߤƤ�褤�Ǥ��礦
#
#./ffmpeg -i ~/php/tv/962-2-20061014-0209.m2p -vcodec xvid -croptop 8 -cropbottom 8 -cropleft 8 -cropright 14 -s 320x240 -b 300 -bt 128 -r 14.985 -bufsize 192 -maxrate 512 -minrate 0 -deinterlace -acodec aac -ab 128 -ar 24000 -ac 2 ~/php/tv/962.localized/mp4/M4V-962-2-20061014-0209.MP4
#
#�Ť�
# ffmpeg -i  ../../563-1-20051022-1830.m2p  -f psp -r 14.985 -s 320x240 -b  300 -ar 24000 -ab 32 M4V00001.MP4 
#
# ���ԥȥ饳������ʳ����ޥ��
# /usr/local/bin/ffmpeg -y -i $1 -vcodec xvid -croptop 8 -cropbottom 8 -cropleft  8 -cropright 14 -s 320x240 -b 300 -bt 128 -r 14.985  -hq -nr -qns -bufsize 192 -maxrate 512 -minrate 0 -deinterlace  -acodec pcm_s16le -ar 24000 -ac 2 -f m4v $TMP_M4V -f s16le $TMP_S16
#
#
# DCC-JPL Japan/foltia project
#
#


use DBI;
#use DBD::Pg;
use DBD::SQLite;
use Schedule::At;
use Time::Local;
use Jcode;

$path = $0;
$path =~ s/singletranscode.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}

require "foltialib.pl";
#�����������뤫?
$outputfile =  $ARGV[0] ;
if ($outputfile eq "" ){
	#�������ʤ��м¹Ԥ��줿�顢��λ
	print "usage singletranscode.pl  srcMPEG2file [PID] [pspdir] [aspect 3|16] [title]\n";
	print "Ex. singletranscode.pl  514-2-20050701-2400.m2p 32961 [pspdir] [aspect 3|16] [title]\n";
	exit;
}
$outputfilename = $outputfile;
@fullarg = split(/\//,$outputfile );
$outputfile = pop( @fullarg );
@tid = split(/-/,$outputfile );
$tid = $tid[0];
$countno = $tid[1];

chomp($outputfile);
$outputfile =~ s/\.m2p//;

		$mp4newstylefilename = "-".$outputfile ;


# -- recwrap����ۤȤ�ɥ��ԡ�

#PSP�ȥ饳��ɬ�פ��ɤ���
$dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;

if ($ARGV[1] != ""){
	$pid = $ARGV[1] ;
}else{
    $sth = $dbh->prepare($stmt{'singletranscode.1'});
    $sth->execute($ARGV[0]);
 @pidarray = $sth->fetchrow_array;
	unless ($pidarray[0]  == "" ){
		$pid = $pidarray[0]
	}else{
		&writelog("singletranscode undefined ; PID (Not found m2p file $ARGV[0])");
	}

}#endif pid


#���ɲ���ʬ

$sth = $dbh->prepare($stmt{'singletranscode.2'});
$sth->execute($tid, $countno);
 @subticount= $sth->fetchrow_array;
 unless ($subticount[0]  >= 1){

    $sth = $dbh->prepare($stmt{'singletranscode.3'});
    $sth->execute($tid);
 @subticount= $sth->fetchrow_array;

 unless ($subticount[0]  >= 1){

	print "This file not included in DB.\n";
	print "Fill parameter ;usage  singletranscode.pl  srcMPEG2file [pspdir] [aspect 3|16] [title]\n";
	exit;

}
}
sleep(10);
#���ɲ���ʬ�����ޤ�



# Starlight breaker��������ץ����������
if (-e "$toolpath/perl/captureimagemaker.pl"){
	&writelog("singletranscode Call captureimagemaker $outputfilename");
	system ("$toolpath/perl/captureimagemaker.pl $outputfilename");
}



# PSP ------------------------------------------------------
#PSP�ȥ饳��ɬ�פ��ɤ���
$sth = $dbh->prepare($stmt{'singletranscode.4'});
$sth->execute($tid);
 @psptrcn= $sth->fetchrow_array;
 if ($psptrcn[0]  == 1 ){#�ȥ饳������


#PSP�ࡼ�ӡ��ǥ��쥯�ȥ꤬���뤫�ɤ���
 
#TID��100�ʾ��3��ξ��Ϥ��Τޤ�
my $pspfilnamehd = "";

	$pspfilnamehd = $tid;
$pspdirname = "$tid.localized/";
$pspdirname = $recfolderpath."/".$pspdirname;

#�ʤ���к��
unless (-e $pspdirname ){
	system("$toolpath/perl/mklocalizeddir.pl $tid");
	#&writelog("singletranscode mkdir $pspdirname");
}
$pspdirname = "$tid.localized/mp4/";
$pspdirname = $recfolderpath."/".$pspdirname;
#�ʤ���к��
unless (-e $pspdirname ){
	mkdir $pspdirname ,0777;
	#&writelog("singletranscode mkdir $pspdirname");
}

#�ե�����̾����
if ($mp4filenamestyle == 1){# 1;���狼��䤹���ե�����̾
 $pspfilname = $mp4newstylefilename ;
 
}else{##0:PSP �ե����०����ver.2.80������ȸߴ�������ĥե�����̾
#���ե����̾[100MNV01]��100����ʬ���ѹ���(100��999)��
# MP_ROOT �� 100MNV01 �� M4V00001.MP4��ư���
#��         ��        �� M4V00001.THM�ʥ���ͥ���ˢ�ɬ�ܤǤϤʤ�

#�ե�����̾����
#�ե�����̾���� #�����르�ꥺ��
#TID 0000-3599�ޤ�[3��]
#�ÿ� 00-999�ޤ�[2��]

my $pspfilnameft = "";
my $pspfilnameyearhd = "";
my $pspfilnameyearft = "";

$btid = $tid % 3600;
# print "$btid\n";

if($btid >= 0 && $btid < 1000){

	$pspfilnamehd = sprintf("%03d",$btid);

}elsif ($btid >= 1000 && $btid < 3600){
	$pspfilnameyearhd = substr($btid, 0, 2);
	$pspfilnameyearhd =~ s/10/A/;
	$pspfilnameyearhd =~ s/11/B/;
	$pspfilnameyearhd =~ s/12/C/;
	$pspfilnameyearhd =~ s/13/D/;
	$pspfilnameyearhd =~ s/14/E/;
	$pspfilnameyearhd =~ s/15/F/;
	$pspfilnameyearhd =~ s/16/G/;
	$pspfilnameyearhd =~ s/17/H/;
	$pspfilnameyearhd =~ s/18/I/;
	$pspfilnameyearhd =~ s/19/J/;
	$pspfilnameyearhd =~ s/20/K/;
	$pspfilnameyearhd =~ s/21/L/;
	$pspfilnameyearhd =~ s/22/M/;
	$pspfilnameyearhd =~ s/23/N/;
	$pspfilnameyearhd =~ s/24/O/;
	$pspfilnameyearhd =~ s/25/P/;
	$pspfilnameyearhd =~ s/26/Q/;
	$pspfilnameyearhd =~ s/27/R/;
	$pspfilnameyearhd =~ s/28/S/;
	$pspfilnameyearhd =~ s/29/T/;
	$pspfilnameyearhd =~ s/30/U/;
	$pspfilnameyearhd =~ s/31/V/;
	$pspfilnameyearhd =~ s/32/W/;
	$pspfilnameyearhd =~ s/33/X/;
	$pspfilnameyearhd =~ s/34/Y/;
	$pspfilnameyearhd =~ s/35/Z/;
	
$pspfilnameyearft = substr($btid, 2, 2);
$pspfilnameyearft = sprintf("%02d",$pspfilnameyearft);
$pspfilnamehd = $pspfilnameyearhd . $pspfilnameyearft;

}

# �ÿ�
if (0 < $countno && $countno < 100 ){
# 2��
	$pspfilnameft = sprintf("%02d",$countno);
}elsif(100 <= $countno && $countno < 1000 ){
# 3��
	$pspfilnameft = sprintf("%03d",$countno); # �ÿ�3��
	$pspfilnamehd = substr($pspfilnamehd, 0, 2); # TID ��塡���1�Х�����Ȥ�
}elsif(1000 <= $countno && $countno < 10000 ){
# 4��
	$pspfilnameft = sprintf("%04d",$countno); # �ÿ�4��
	$pspfilnamehd = substr($pspfilnamehd, 0, 1); # TID 1�塡���2�Х�����Ȥ�


}elsif($countno == 0){
#�����ॹ����פ��ǿ���MP4�ե�����̾����
my $newestmp4filename = `cd $pspdirname ; ls -t *.MP4 | head -1`;
 if ($newestmp4filename =~ /M4V$tid/){
		$nowcountno = $' ;#'
		$nowcountno++;
		$pspfilnameft = sprintf("%02d",$nowcountno);
	while (-e "$pspdirname/M4V".$pspfilnamehd.$pspfilnameft.".MP4"){
		$nowcountno++;
		$pspfilnameft = sprintf("%02d",$nowcountno);	
	print "File exist:$nowcountno\n";
	}
#print "NeXT\n";
}else{
# 0�ξ�硡���ֹ��100������������
# week number of year with Monday as first day of week (01..53)
#���ä����ɾ��0��
#	my $weeno = `date "+%V"`;
#	$weeno = 100 - $weeno ;
#	$pspfilnameft = sprintf("%02d",$weeno);
	$pspfilnameft = sprintf("%02d",0);
#print "WEEKNO\n";
}

}

my $pspfilname = $pspfilnamehd.$pspfilnameft  ;
# print "$pspfilname($pspfilnamehd/$pspfilnameft)\n";
}# endif MP4�ե�����̾����style�ʤ�

&writelog("singletranscode TRCNSTART vfr4psp.sh $recfolderpath/$outputfilename $pspfilname $pspdirname $psptrcn[1]");
#�ȥ饳�󳫻�
system("$toolpath/perl/transcode/vfr4psp.sh $recfolderpath/$outputfilename $pspfilname $pspdirname $psptrcn[1]");

&writelog("singletranscode TRCNEND  vfr4psp.sh $recfolderpath/$outputfilename $pspfilname $pspdirname $psptrcn[1]");

#��Ŭ��

    $sth = $dbh->prepare($stmt{'singletranscode.5'});
    $sth->execute($tid, $countno);
 @programtitle = $sth->fetchrow_array;

if ( $countno == "0" ){
	$pspcountno = "";
}else{
	$pspcountno = $countno ;
}
&writelog("singletranscode OPTIMIZE  mp4psp -p $pspdirname/M4V$pspfilname.MP4   -t  '$psptrcn[2] $pspcountno $programtitle[0]' ");
Jcode::convert(\$programtitle[0],'euc');
system ("/usr/local/bin/mp4psp -p $pspdirname/M4V$pspfilname.MP4   -t  '$psptrcn[2] $pspcountno $programtitle[0]'") ;


#����͡���

# mplayer -ss 00:01:20 -vo jpeg:outdir=/home/foltia/php/tv/443MNV01 -ao null -sstep 1 -frames 3  -v 3 /home/foltia/php/tv/443-07-20050218-0030.m2p
#2005/02/22_18:30:05 singletranscode TRCNSTART vfr4psp.sh /home/foltia/php/tv/447-21-20050222-1800.m2p 44721 /home/foltia/php/tv/447MNV01 3
&writelog("singletranscode THAMJ  mplayer -ss 00:01:20 -vo jpeg:outdir=$pspdirname -ao null -sstep 1 -frames 3  -v 3 $recfolderpath/$outputfilename ");
system ("mplayer -ss 00:01:20 -vo jpeg:outdir=$pspdirname -ao null -sstep 1 -frames 3  -v 3 $recfolderpath/$outputfilename");
&writelog("singletranscode THAMI  convert -crop 160x120+1+3 -resize 165x126\! $pspdirname/00000002.jpg $pspdirname/M4V$pspdirname.THM ");

if (-e "$pspdirname/M4V".$pspfilname.".THM"){
	$timestamp = strftime("%Y%m%d-%H%M%S", localtime);
chomp $timestamp;
	system("convert -crop 160x120+1+3 -resize 165x126\! $pspdirname/00000002.jpg $pspdirname/M4V".$pspfilname.".THM.".$timestamp.".THM");

}else{
	system("convert -crop 160x120+1+3 -resize 165x126\! $pspdirname/00000002.jpg $pspdirname/M4V".$pspfilname.".THM");
}
# rm -rf 00000001.jpg      
# convert -resize 160x120\! 00000002.jpg M4V44307.THM
# rm -rf 00000002.jpg  
system("rm -rf $pspdirname/0000000*.jpg ");

# MP4�ե�����̾��PID�쥳���ɤ˽񤭹���
unless ($pid eq ""){
	$sth = $dbh->prepare($stmt{'singletranscode.6'});
	$sth->execute("M4V$pspfilname.MP4", $pid);
	&writelog("singletranscode UPDATEsubtitleDB $stmt{'singletranscode.6'}");
}else{
&writelog("singletranscode PID not found");
}
# MP4�ե�����̾��foltia_mp4files����
    $sth = $dbh->prepare($stmt{'singletranscode.7'});
    $sth->execute($tid, "M4V$pspfilname.MP4");
    &writelog("singletranscode UPDATEmp4DB $stmt{'singletranscode.7'}");

}#PSP�ȥ饳�󤢤�
