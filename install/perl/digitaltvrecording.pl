#!/usr/bin/perl
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
#digitaltvrecording.pl
# PT1,PT2,friio��Ϥ���Ȥ���ǥ�����Ͽ��ץ�����ƤӤ���Ͽ��⥸�塼�롣
#
#usage digitaltvrecording.pl bandtype ch length(sec) [stationid] [sleeptype] [filename] [TID] [NO] [unittype]
#����
#bandtype : 0:�ϥǥ� 1:BS�ǥ����� 2:CS�ǥ�����
#ch :Ͽ������ͥ� (�ϥǥ��Ϥ��Τޤ��Ϥ���BS/CS�ǥ�����ϴ���Ū�˥����ͥ� BS1/BS2�ʤ�Ʊ��������)
#length(sec) :Ͽ���ÿ� [ɬ�ܹ���]
#[stationid] :foltia stationid
#[sleeptype] :0��N N�ʤ饹�꡼�פʤ���Ͽ��
#[filename] :���ϥե�����̾
#[TID] :����ܤ��륿���ȥ�ID
#[NO] :�������Ȥ������ÿ�
#[unittype] :friio��friioBS����˥ǥ���塼�ʤ�HDUS���ʤ�(̤����)
#
# DCC-JPL Japan/foltia project
#
#

$path = $0;
$path =~ s/digitaltvrecording.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}

#tvConfig.pl -------------------------------
$extendrecendsec = 10;							#recording end second. 
#$startupsleeptime = 52;					#process wait(MAX60sec)
$startupsleeptime = 32;					#process wait(MAX60sec)
#-------------------------------

require 'foltialib.pl';

 &writelog("digitaltvrecording: DEBUG $ARGV[0] $ARGV[1] $ARGV[2] $ARGV[3] $ARGV[4] $ARGV[5] $ARGV[6] $ARGV[7] $ARGV[8]");


#����
&prepare;
#�⤷Ͽ�褬���äƤ��顢�ߤ��
#$reclengthsec = &chkrecprocess();
#&setbitrate;
#&chkextinput;
#$reclengthsec = $reclengthsec + $extendrecendsec ;

&calldigitalrecorder;

&writelog("digitaldigitaltvrecording:RECEND:$bandtype $recch $lengthsec $stationid $sleeptype $filename $tid $countno $unittype
");

# -- ����ʲ����֥롼���� ----------------------------


sub prepare{

#�������顼����
$bandtype = $ARGV[0] ;
$recch = $ARGV[1] ;
$lengthsec = $ARGV[2] ;
$stationid = $ARGV[3] ;
$sleeptype = $ARGV[4] ;
$filename = $ARGV[5] ;
$tid = $ARGV[6] ;
$countno = $ARGV[7] ;
$unittype = $ARGV[8] ; 

if (($bandtype eq "" )|| ($recch eq "")|| ($lengthsec eq "")){
	print "usage digitaltvrecording.pl bandtype ch length(sec) [stationid] [sleeptype] [filename] [TID] [NO] [unittype]\n";
	exit;
}

#HDD�򵯤���
my $hdd_sleep_time = time();
&writelog("digitaltvrecording: DEBUG WAKEUPHDD");
&writelog(`$toolpath/perl/wakeuphdd.pl`);
$hdd_sleep_time = time() - $hdd_sleep_time + 1;

my $intval = $recch % 10; # 0��9 sec
my $startupsleep = $startupsleeptime - $intval - $hdd_sleep_time; #  18��27 sec
$reclengthsec = $lengthsec + (60 - $startupsleep) + 1; #

if ( $sleeptype ne "N"){
	&writelog("digitaltvrecording: DEBUG SLEEP $startupsleeptime:$intval:$startupsleep:$reclengthsec");
	sleep ( $startupsleep);
	#2008/08/12_06:39:00 digitaltvrecording: DEBUG SLEEP 17:23:-6:367
}else{
	&writelog("digitaltvrecording: DEBUG RAPID START");
}
## recfriio ���Τؤ�ɤ��ʤäƤ��?
#if ($recunits > 1){
#my $deviceno = $recunits - 1;#3�纹���ΤȤ�/dev/video2����Ȥ�
#	$recdevice = "/dev/video$deviceno";
#	$recch = $ARGV[0] ;
#}else{
##1�纹��
#	$recdevice = "/dev/video0";
#	$recch = $ARGV[0] ;
#}

$outputpath = "$recfolderpath"."/";

if ($countno eq "0"){
	$outputfile = $outputpath.$tid."--";
}else{
	$outputfile = $outputpath.$tid."-".$countno."-";
}
#2���ܰʹߤΥ���åפǥե�����̾���꤬���ä���
	if ($filename  ne ""){

		$outputfile = $filename ;
		$outputfile = &filenameinjectioncheck($outputfile);
		$outputfilewithoutpath = $outputfile ;
		$outputfile = $outputpath.$outputfile ;
		&writelog("digitaltvrecording: DEBUG FILENAME ne null \$outputfile $outputfile ");
	}else{
	$outputfile .= strftime("%Y%m%d-%H%M", localtime(time + 60));
		chomp($outputfile);
		$outputfile .= ".m2t";
		$outputfilewithoutpath = $outputfile ;
		&writelog("digitaltvrecording:  DEBUG FILENAME is null \$outputfile $outputfile ");
	}


@wday_name = ("Sun","Mon","Tue","Wed","Thu","Fri","Sat");
$sleepcounter = 0;
$cmd="";

#���Ͽ��ʤɴ���Ʊ̾�ե����뤬���ä�������
if ( -e "$outputfile" ){
	if ( -s "$outputfile" ){
	&writelog("digitaltvrecording :ABORT :recfile $outputfile exist.");
	exit 1;
	}
}

}#end prepare


#------------------------------------------------------------------------------------
#
sub calldigitalrecorder{
#
#��friio�ȹ�friio��PT1�б�
#2008/10/23 recfriio4���ͤ��ѹ� 
#
my $oserr = 0;
my $originalrecch = $recch;
my $pt1recch =  $recch;
my $errorflag = 0;
if ($bandtype == 0){
# �ϥǥ� friio

}elsif($bandtype == 1){
# BS/CS friio
		#recfriiobs�ѥ����ͥ��ޥå�
		if ($recch == 101) {
			$bssplitflag = $recch;
			$recch = "b10";#22 : NHK BS1/BS2 
		}elsif($recch == 102){
			$bssplitflag = $recch;
			$recch = "b10";#22 : NHK BS1/BS2 
		}elsif($recch == 103){
			$recch = "b11";#23 : NHK hi  
		}elsif($recch == 141){
			$recch = "b8";# 20 : BS-NTV  
		}elsif($recch == 151){
			$recch = "b1";#13 : BS-Asahi 
		}elsif($recch == 161){
			$recch = "b2";#14 : BS-i  
		}elsif($recch == 171){
			$recch = "b4";#16 : BS-Japan 
		}elsif($recch == 181){
			$recch = "b9";#21 : BS-Fuji 
		}elsif($recch == 191){
			$recch = "b3";#15 : WOWOW 
		}elsif($recch == 192){
			$recch = "b3";#15 : WOWOW 
		}elsif($recch == 193){
			$recch = "b3";#15 : WOWOW 
		}elsif($recch == 200){
			$recch = "b6";# b6 # Star Channel
		}elsif($recch == 211){
			$recch = "b5";#17 : BS11  
		}else{
			$recch = "b7";#19 : TwellV 
		}
#PT1�Ϥ��Τޤ��̤�

}elsif($bandtype == 2){
# recpt1�ǤΤ�ư���ǧ
		if($recch == 335){
		$pt1recch = "CS8";#335ch�����å����ơ������ HD
	}elsif($recch == 237){
		$pt1recch = "CS2";#237ch���������������ͥ� �ץ饹
	}elsif($recch == 239){
		$pt1recch = "CS2";#239ch�����ܱǲ���������ͥ�HD
	}elsif($recch == 306){
		$pt1recch = "CS2";#306ch���ե��ƥ��CSHD
	}elsif($recch == 100){
		$pt1recch = "CS4";#100ch��e2�ץ��
	}elsif($recch == 256){
		$pt1recch = "CS4";#256ch��J sports ESPN
	}elsif($recch == 312){
		$pt1recch = "CS4";#312ch��FOX
	}elsif($recch == 322){
		$pt1recch = "CS4";#322ch�����ڡ�������TV
	}elsif($recch == 331){
		$pt1recch = "CS4";#331ch�������ȥ�����ͥåȥ��
	}elsif($recch == 194){
		$pt1recch = "CS4";#194ch�����󥿡�������TV
	}elsif($recch == 334){
		$pt1recch = "CS4";#334ch���ȥ����󡦥ǥ����ˡ�
	}elsif($recch == 221){
		$pt1recch = "CS6";#221ch����ǥ����ͥ� 
	}elsif($recch == 222){
		$pt1recch = "CS6";#222ch���������
	}elsif($recch == 223){
		$pt1recch = "CS6";#223ch�������ͥ�NECO
	}elsif($recch == 224){
		$pt1recch = "CS6";#224ch���β�����ͥե��롦���ޥ���
	}elsif($recch == 292){
		$pt1recch = "CS6";#292ch���������������ͥ�
	}elsif($recch == 238){
		$pt1recch = "CS6";#238ch���������������ͥ� ���饷�å�
	}elsif($recch == 310){
		$pt1recch = "CS6";#310ch�������ѡ����ɥ��TV
	}elsif($recch == 311){
		$pt1recch = "CS6";#311ch��AXN
	}elsif($recch == 343){
		$pt1recch = "CS6";#343ch���ʥ���ʥ른������ե��å������ͥ�
	}elsif($recch == 055){
		$pt1recch = "CS8";#055ch������å� �����ͥ�
	}elsif($recch == 228){
		$pt1recch = "CS10";#228ch���������ͥ�
	}elsif($recch == 800){
		$pt1recch = "CS10";#800ch�����������HD800
	}elsif($recch == 801){
		$pt1recch = "CS10";#801ch�����������801
	}elsif($recch == 802){
		$pt1recch = "CS10";#802ch�����������802
	}elsif($recch == 260){
		$pt1recch = "CS12";#260ch����������ա������ͥ�
	}elsif($recch == 303){
		$pt1recch = "CS12";#303ch���ƥ�ī�����ͥ�
	}elsif($recch == 323){
		$pt1recch = "CS12";#323ch��MTV 324ch����ͤβ�������TV���ߥ塼���å�������
	}elsif($recch == 352){
		$pt1recch = "CS12";#352ch��ī���˥塼������
	}elsif($recch == 353){
		$pt1recch = "CS12";#353ch��BBC���ɥ˥塼��
	}elsif($recch == 354){
		$pt1recch = "CS12";#354ch��CNNj
	}elsif($recch == 361){
		$pt1recch = "CS12";#361ch�����㥹�ȡ����� ����ե��᡼�����
	}elsif($recch == 251){
		$pt1recch = "CS14";#251ch��J sports 1
	}elsif($recch == 252){
		$pt1recch = "CS14";#252ch��J sports 2
	}elsif($recch == 253){
		$pt1recch = "CS14";#253ch��J sports Plus
	}elsif($recch == 254){
		$pt1recch = "CS14";#254ch��GAORA
	}elsif($recch == 255){
		$pt1recch = "CS14";#255ch����������Asports��
	}elsif($recch == 305){
		$pt1recch = "CS16";#305ch�������ͥ���
	}elsif($recch == 333){
		$pt1recch = "CS16";#333ch�����˥᥷������X(AT-X)
	}elsif($recch == 342){
		$pt1recch = "CS16";#342ch���ҥ��ȥ꡼�����ͥ�
	}elsif($recch == 290){
		$pt1recch = "CS16";#290ch��TAKARAZUKA SKYSTAGE
	}elsif($recch == 803){
		$pt1recch = "CS16";#803ch�����������803
	}elsif($recch == 804){
		$pt1recch = "CS16";#804ch�����������804
	}elsif($recch == 240){
		$pt1recch = "CS18";#240ch���ࡼ�ӡ��ץ饹HD
	}elsif($recch == 262){
		$pt1recch = "CS18";#262ch������եͥåȥ��
	}elsif($recch == 314){
		$pt1recch = "CS18";#314ch��LaLa HDHV
	}elsif($recch == 258){
		$pt1recch = "CS20";#258ch���ե��ƥ��739
	}elsif($recch == 302){
		$pt1recch = "CS20";#302ch���ե��ƥ��721
	}elsif($recch == 332){
		$pt1recch = "CS20";#332ch�����˥ޥå���
	}elsif($recch == 340){
		$pt1recch = "CS20";#340ch���ǥ������Х꡼�����ͥ�
	}elsif($recch == 341){
		$pt1recch = "CS20";#341ch�����˥ޥ�ץ�ͥå�
	}elsif($recch == 160){
		$pt1recch = "CS22";#160ch��C-TBS�����륫������ͥ�
	}elsif($recch == 161){
		$pt1recch = "CS22";#161ch��QVC
	}elsif($recch == 185){
		$pt1recch = "CS22";#185ch���ץ饤��365.TV
	}elsif($recch == 293){
		$pt1recch = "CS22";#293ch���ե��ߥ꡼���
	}elsif($recch == 301){
		$pt1recch = "CS22";#301ch��TBS�����ͥ�
	}elsif($recch == 304){
		$pt1recch = "CS22";#304ch���ǥ����ˡ��������ͥ�
	}elsif($recch == 325){
		$pt1recch = "CS22";#325ch��MUSIC ON! TV
	#}elsif($recch == 330){
	#	$pt1recch = "CS22";#330ch�����å����ơ������  #HD���ˤ��2010/4�ѹ�
	}elsif($recch == 351){
		$pt1recch = "CS22";#351ch��TBS�˥塼���С���
	}elsif($recch == 257){
		$pt1recch = "CS24";#ch�����ƥ�G+
	}elsif($recch == 291){
		$pt1recch = "CS24";#ch��fashiontv
	}elsif($recch == 300){
		$pt1recch = "CS24";#ch�����ƥ�ץ饹
	}elsif($recch == 320){
		$pt1recch = "CS24";#ch���¤餮�β��ڤ����ʡ������ߥ塼���å�TV
	}elsif($recch == 321){
		$pt1recch = "CS24";#ch��MusicJapan TV
	}elsif($recch == 350){
		$pt1recch = "CS24";#ch�����ƥ�NEWS24
	}# end if CS��ޥå�

}else{
	&writelog("digitaltvrecording :ERROR :Unsupported and type (digital CS).");
	exit 3;
}

# PT1
# b25,recpt1�����뤫��ǧ
	if  (-e "$toolpath/perl/tool/recpt1"){
		if ($bandtype >= 1){ #BS/CS�ʤ�
		&writelog("digitaltvrecording DEBUG recpt1 --b25 --sid $originalrecch  $pt1recch $reclengthsec $outputfile   ");
		$oserr = system("$toolpath/perl/tool/recpt1 --b25 --sid $originalrecch $pt1recch $reclengthsec $outputfile  ");
		}else{ #�ϥǥ�
		&writelog("digitaltvrecording DEBUG recpt1 --b25  $originalrecch $reclengthsec $outputfile  ");
		$oserr = system("$toolpath/perl/tool/recpt1 --b25  $originalrecch $reclengthsec $outputfile  ");
		}
		$oserr = $oserr >> 8;
			if ($oserr > 0){
			&writelog("digitaltvrecording :ERROR :PT1 is BUSY.$oserr");
			$errorflag = 2;
			}
	}else{ # ���顼 recpt1������ޤ���
		&writelog("digitaltvrecording :ERROR :recpt1  not found. You must install $toolpath/tool/b25 and $toolpath/tool/recpt1.");
	$errorflag = 1;
	}
# friio
if ($errorflag >= 1 ){
# b25,recfriio�����뤫��ǧ
	if  (-e "$toolpath/perl/tool/recfriio"){
	
	if (! -e "$toolpath/perl/tool/friiodetect"){
		system("touch $toolpath/perl/tool/friiodetect");
		system("chown foltia:foltia $toolpath/perl/tool/friiodetect");
		system("chmod 775 $toolpath/perl/tool/friiodetect");
		&writelog("digitaltvrecording :DEBUG make lock file.$toolpath/perl/tool/friiodetect");
	}
		&writelog("digitaltvrecording DEBUG recfriio --b25 --lockfile $toolpath/perl/tool/friiodetect $recch $reclengthsec $outputfile  ");
		$oserr = system("$toolpath/perl/tool/recfriio --b25 --lockfile $toolpath/perl/tool/friiodetect $recch $reclengthsec $outputfile  ");
		$oserr = $oserr >> 8;
			if ($oserr > 0){
			&writelog("digitaltvrecording :ERROR :friio is BUSY.$oserr");
			exit 2;
			}

#BS1/BS2�ʤɤΥ��ץ�åȤ�
if ($bssplitflag == 101){
	if (-e "$toolpath/perl/tool/TsSplitter.exe"){
	# BS1		
	system("wine $toolpath/perl/tool/TsSplitter.exe  -EIT -ECM  -EMM  -OUT \"$outputpath\" -HD  -SD2 -SD3 -1SEG  -LOGFILE -WAIT2 $outputfile");
	$splitfile = $outputfile;
	$splitfile =~ s/\.m2t$/_SD1.m2t/;
		if (-e "$splitfile"){
		system("rm -rf $outputfile ; mv $splitfile $outputfile");
		&writelog("digitaltvrecording DEBUG rm -rf $outputfile ; mv $splitfile $outputfile: $?.");
		}else{
		&writelog("digitaltvrecording ERROR File not found:$splitfile.");
		}
	}else{
	&writelog("digitaltvrecording ERROR $toolpath/perl/tool/TsSplitter.exe not found.");
	}
}elsif($bssplitflag == 102){
	if (-e "$toolpath/perl/tool/TsSplitter.exe"){
	# BS2		
	system("wine $toolpath/perl/tool/TsSplitter.exe  -EIT -ECM  -EMM  -OUT \"$outputpath\" -HD  -SD1 -SD3 -1SEG  -LOGFILE -WAIT2 $outputfile");
	$splitfile = $outputfile;
	$splitfile =~ s/\.m2t$/_SD2.m2t/;
		if (-e "$splitfile"){
		system("rm -rf $outputfile ; mv $splitfile $outputfile");
		&writelog("digitaltvrecording DEBUG rm -rf $outputfile ; mv $splitfile $outputfile: $?.");
		}else{
		&writelog("digitaltvrecording ERROR File not found:$splitfile.");
		}
	}else{
	&writelog("digitaltvrecording ERROR $toolpath/perl/tool/TsSplitter.exe not found.");
	}
}else{
	&writelog("digitaltvrecording DEBUG not split TS.$bssplitflag");
}# endif #BS1/BS2�ʤɤΥ��ץ�åȤ�

	}else{ # ���顼 recfriio������ޤ���
		&writelog("digitaltvrecording :ERROR :recfriio  not found. You must install $toolpath/perl/tool/b25 and $toolpath/perl/tool/recfriio:$errorflag");
	#exit 1;
	exit $errorflag;
	}
}#end if errorflag
}#end calldigitalrecorder


