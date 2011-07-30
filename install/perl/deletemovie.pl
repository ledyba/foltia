#!/usr/bin/perl
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
#
#deletemovie.pl
#
#�ե�����̾�������ꡢ��������򤹤�
#�Ȥꤢ������./mita/�ذ�ư
#
#
# DCC-JPL Japan/foltia project
#
#
use DBI;
#use DBD::Pg;
use DBD::SQLite;

$path = $0;
$path =~ s/deletemovie.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}

require "foltialib.pl";

#�����������뤫?
$fname = $ARGV[0] ;
if ($fname eq "" ){
	#�������ʤ��м¹Ԥ��줿�顢��λ
	print "usage;deletemovie.pl <FILENAME>\n";
	exit;
}

#�ե�����̾�����������å�
if ($fname =~ /.m2p$|.m2t$|.MP4$|.aac$/){

}else{
#	print "deletemovie invalid filetype.\n";
	&writelog("deletemovie invalid filetype:$fname.");
	exit (1);
}

#DB�����
$dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;

#�ե�����¸�ߥ����å�
my $tid = &mp4filename2tid($fname);
my $mp4dirname = &makemp4dir($tid);
if (-e "$recfolderpath/$fname"){
	$filemovepath = $recfolderpath;
}elsif(-e "$mp4dirname/$fname"){
	$filemovepath = $mp4dirname;
}else{
#	print "deletemovie file not found.$recfolderpath/$fname\n";
	&writelog("deletemovie file not found:$fname.");
	exit (1);
}

#���ɺ������ 
if ($rapidfiledelete  > 0){ #./mita/�ذ�ư
	system ("mv $filemovepath/$fname $recfolderpath/mita/");
	&writelog("deletemovie mv filemovepath/$fname $recfolderpath/mita/.");
}else{ #¨�����
	system ("rm $filemovepath/$fname ");
	&writelog("deletemovie rm $filemovepath/$fname ");


}



