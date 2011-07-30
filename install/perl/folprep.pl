#!/usr/bin/perl
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
#folprep.pl
#
#at����ƤФ�ơ���Ū���Ȥ�����Ƥ��ʤ�����ǧ���ޤ�
#���������ǻ��郎15ʬ�ʾ���ʤ����folprep�Υ��塼������ޤ�
#���ǻ��郎15ʬ����ʤ����ǻ����Ͽ�襭�塼������ޤ�
#
#����:PID
#
# DCC-JPL Japan/foltia project
#
#
use DBI;
#use DBD::Pg;
use Schedule::At;
use Time::Local;


$path = $0;
$path =~ s/folprep.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}

require "foltialib.pl";


#PIDõ��
my $pid = $ARGV[0];

#�����������뤫?
if ($pid eq "" ){
	#�������ʤ��м¹Ԥ��줿�顢��λ
	print "usage;folprep.pl <PID>\n";
	exit;
}

my $stationid = "";
if ($pid <= 0){#EPGϿ��/�������Ͽ��
	#EPG���� & DB����
	$dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;
	$stationid = &pid2sid($pid);
	&writelog("folprep DEBUG epgimport.pl $stationid");
	system("$toolpath/perl/epgimport.pl $stationid");
}else{#����ܤ���Ͽ��
	#XML���å� & DB����
	&writelog("folprep DEBUG getxml2db.pl");
	system("$toolpath/perl/getxml2db.pl");
}

#���塼������
&writelog("folprep  $toolpath/perl/addpidatq.pl $pid");
system("$toolpath/perl/addpidatq.pl $pid");

