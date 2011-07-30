#!/usr/bin/perl
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
#usage ;mklocalizeddir.pl [TID]
# Mac OS X Localized�ե����ޥåȤ˽�򤷤���¤��Ͽ��ǥ��쥯�ȥ���롣
# ����:[Mac OS X 10.2�Υ����饤����ǽ] http://msyk.net/macos/jaguar-localize/
#
# DCC-JPL Japan/foltia project
#
#


use Jcode;
use DBI;
#use DBD::Pg;
use DBD::SQLite;

$path = $0;
$path =~ s/mklocalizeddir.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}
require "foltialib.pl";

#�����������뤫?
$tid =  $ARGV[0] ;
if ($tid eq "" ){
	#�������ʤ��м¹Ԥ��줿�顢��λ
	print "usage mklocalizeddir.pl [TID]\n";
	exit;
}


#���Υǥ��쥯�ȥ꤬�ʤ����
if (-e "$recfolderpath/$tid.localized"){

}else{


#.localized��ʸ�������

#��³
    $dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;

#����
    $sth = $dbh->prepare($stmt{'mklocalizeddir.1'});
    $sth->execute($tid);
 @subticount= $sth->fetchrow_array;
$title = $subticount[0] ;
$titleeuc = $title ;
 Jcode::convert(\$title , 'utf8', 'euc', "z");


	mkdir ("$recfolderpath/$tid.localized",0755);
	mkdir ("$recfolderpath/$tid.localized/.localized",0755);
	mkdir ("$recfolderpath/$tid.localized/mp4",0755);
	mkdir ("$recfolderpath/$tid.localized/m2p",0755);
	open (JASTRING,">$recfolderpath/$tid.localized/.localized/ja.strings")  || die "Cannot write ja.strings.\n";
	print JASTRING "\"$tid\"=\"$title\";\n";
	close(JASTRING);

&writelog("mklocalizeddir $tid $titleeuc");

}#unless �����������뤫?

