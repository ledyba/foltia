#!/usr/bin/perl
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
#
# envpolicyupdate.pl
#
# �Ķ��ݥꥷ�����ѻ���.htpasswd����Ԥ��롣
#
#
# DCC-JPL Japan/foltia project
#
#

use DBI;
#use DBD::Pg;
use DBD::SQLite;

$path = $0;
$path =~ s/envpolicyupdate.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}

require "foltialib.pl";

# �Ķ��ݥꥷ����ȤäƤ��뤫PHP����ե����ե��������
$returnparam = getphpstyleconfig("useenvironmentpolicy");
eval "$returnparam\n";

if ($useenvironmentpolicy == 1){
$returnparam = getphpstyleconfig("environmentpolicytoken");
eval "$returnparam\n";

    $dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;

    $envph = $dbh->prepare($stmt{'envpolicyupdate.1'});
	$envph->execute();

#�ʤ���ФĤ���
unless (-e "$toolpath/.htpasswd"){
	$oserr = `touch $toolpath/.htpasswd`;
}else{
	$oserr = `mv $toolpath/.htpasswd $toolpath/htpasswd_foltia_old`;
	$oserr = `touch $toolpath/.htpasswd`;
}

while (@ref = $envph->fetchrow_array ){

if ($ref[0] == 0){
#�桼�����饹
#0:�ø�������
#1:������:ͽ�������ե��������������
#2:���Ѽ�:EPG�ɲá�ͽ���ɲä������
#3:�ӥ奢��:�ե������������ɤ������
#4:������:���󥿡��ե������������

	$htpasswd = "$ref[2]";
}else{
	$htpasswd = "$ref[2]"."$environmentpolicytoken";
}

$oserr = `htpasswd -b $toolpath/.htpasswd $ref[1] $htpasswd`;


}#end while
&writelog("envpolicyupdate htpasswd updated.");

}#endif 