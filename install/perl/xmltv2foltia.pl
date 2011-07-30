#!/usr/bin/perl 
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
# xmltv2foltia.pl 
#
# XMLTV���ܸ��Ƿ�����XML�������ꡢEPG�ǡ����١������������ޤ���
# ���ʥ������XMLTV�����Ѥ��Ƥ��ޤ����������ߤ�epgimport.pl����Ѥ��ޤ���
#
# usage
# cat /tmp/__27-epg.xml | /home/foltia/perl/xmltv2foltia.pl
#
# DCC-JPL Japan/foltia project
#
#

#use LWP::Simple;
#use Encode qw(from_to);
#use encoding 'euc-jp', STDIN=>'utf8', STDOUT=>'euc-jp' ; # ɸ������:utf8 
# http://www.lr.pi.titech.ac.jp/~abekawa/perl/perl_unicode.html
use Jcode;
#use Data::Dumper; 
use Time::Local;
use DBI;
#use DBD::Pg;
use DBD::SQLite;

$path = $0;
$path =~ s/xmltv2foltia.pl$//i;
if ($path ne "./"){
push( @INC, "$path");
}
require "foltialib.pl";

$currentworkdate = "" ;
$currentworkch = "" ;
$today = strftime("%Y%m%d", localtime);
$todaytime = strftime("%Y%m%d%H%M", localtime);
@deleteepgid = ();

# DB Connect
$dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;

while(<>){
#print $_;
s/\xef\xbd\x9e/\xe3\x80\x9c/g; #wavedash
s/\xef\xbc\x8d/\xe2\x88\x92/g; #hyphenminus
s/&#([0-9A-Fa-f]{2,6});/(chr($1))/eg; #'ͷ����5D&#039;s'�Ȥ��ο��ͻ����б���

Jcode::convert(\$_,'euc','utf8');
#    from_to($_, "utf8","euc-jp");
if(/<channel/){

#  <channel id="0031.ontvjapan.com">
#    <display-name lang="ja_JP">�Σȣ����</display-name>
#    <display-name lang="en">NHK</display-name>
#  </channel>

	s/^[\s]*//gio;
	s/<channel//i;
	#s/\"\/>/\" /i;
	s/\"\>/\" /i;
	s/\"[\s]/\";\n/gio;
	s/[\w]*=/\$channel{$&}=/gio;
	s/\=}=/}=/gio;
	chomp();
	eval("$_");
#print Dumper($_) ;

}elsif(/<display-name lang=\"ja_JP/){
	s/^[\s]*//gio;
	chomp();
	$channel{ja}  = &removetag($_);
	#print Dumper($_) ;
	#print "$result  \n";
}elsif(/<display-name lang=\"en/){
	s/^[\s]*//gio;
	chomp();
	$channel{en}  = &removetag($_);
	#print Dumper($_) ;
	#print "$result  \n";

}elsif(/<\/channel>/){
# foltia �ɥꥹ�Ȥ˺ܤäƤʤ������ɤ��ɲä��ʤ�

#	print "$channel{id}
#$channel{ja}
#$channel{en}
#-------------------------------\n";

	$channel{id} = "";
	$channel{ja} = "";
	$channel{en} = "";

}elsif (/<programme /){

# <programme start="20051112210000 +0900" stop="20051112225100 +0900" channel="0007.ontvjapan.com">
#    <title lang="ja_JP">���˥磻�ɷ��</title>
#    <sub-title lang="ja_JP">�ֵ�̿�Ρ����Ĥ�����۵޽�ư���Ƿ�ʪ�ҳ��θ���ˤʤ��ɻ���?�ռ������δ��ԤȾ�ǯ�����������</sub-title>
#    <desc lang="ja_JP">������ͺ���ܡ����ܹ����ġ�����ҡ�����εƸ����ƣ���졡����դߤ����дݸ���Ϻ�����ߵ��ᡡ�����Τޤ����</desc>
#    <category lang="ja_JP">�ɥ��</category>
#    <category lang="en">series</category>
#  </programme>

	s/<programme //i;
	#s/\"\/>/\" /i;
	s/\"\>/\" /i;
	s/\"[\s]/\";\n/gio;
	s/[\w]*=/\$item{$&}=/gio;
	s/\=}=/}=/gio;
	chomp();
	eval("$_");
	#print Dumper($_) ;
	#print "$item{start}/$item{stop}/$item{channel}\n";
	

}elsif(/<sub-title /){
	s/^[\s]*//gio;
	chomp();
	$item{subtitle}  = &removetag($_);
	#print Dumper($_) ;
	#print "$result  \n";

}elsif(/<title /){
	s/^[\s]*//gio;
	chomp();
	$item{title}  = &removetag($_);
	$titlebackup = $item{title};
	$item{title} =~ s/��.*?��//g;#�ڲ�ۤȤ�
	$item{title} =~ s/\[.*?\]//g;#[��]�Ȥ� 
#	$item{title} =~ s/��.??��//g;#�ڲ�ۤȤ�
#	$item{title} =~ s/\[.??\]//g;#[��]�Ȥ� 
	if ($item{title} eq ""){
		# WOWOW��<title lang="ja_JP">��̵��</title>����ʥߥ����Ȥ����ꡢ�����ȥ����ˤʤäƤ��ޤ����Ȥ�����
		$item{title} = $titlebackup;
	}
	#print Dumper($_) ;
	#print "$result  \n";

}elsif(/<desc /){
	s/^[\s]*//gio;
	chomp();
	$item{desc}  = &removetag($_);
	#print Dumper($_) ;
	#print "$result  \n";

}elsif(/<category lang=\"ja_JP/){
	s/^[\s]*//gio;
	chomp();
	$item{category} = &removetag($_);
	
	if ($item{category} =~ /����/){
	$item{category} = "information";
	}elsif ($item{category} =~ /��̣������/){
	$item{category} = "hobby";
	}elsif ($item{category} =~ /����/){
	$item{category} = "education";
	}elsif ($item{category} =~ /����/){
	$item{category} = "music";
	}elsif ($item{category} =~ /���/){
	$item{category} = "stage";
	}elsif ($item{category} =~ /�ǲ�/){
	$item{category} = "cinema";
	}elsif ($item{category} =~ /�Х饨�ƥ�/){
	$item{category} = "variety";
	}elsif ($item{category} =~ /�˥塼������ƻ/){
	$item{category} = "news";
	}elsif ($item{category} =~ /�ɥ��/){
	$item{category} = "drama";
	}elsif ($item{category} =~ /�ɥ����󥿥꡼������/){
	$item{category} = "documentary";
	}elsif ($item{category} =~ /���ݡ���/){
	$item{category} = "sports";
	}elsif ($item{category} =~ /���å�/){
	$item{category} = "kids";
	}elsif ($item{category} =~ /���˥ᡦ�û�/){
	$item{category} = "anime";
	}elsif ($item{category} =~ /����¾/){
	$item{category} = "etc";
	}else{
	$item{category} = "etc";
	}
	
	#print Dumper($_) ;
	#print "$result  \n";


}elsif(/<\/programme>/){
#��Ͽ�����ϥ�����
#&writelog("xmltv2foltia DEBUG call chkerase $item{'start'},$item{'channel'}");
#�����	#&chkerase($item{'start'}, $item{'channel'});
	&replaceepg($item{'start'}, $item{'channel'},$item{'stop'});
	if ($item{'subtitle'} ne "" ){
	    $registdesc = $item{'subtitle'}." ".$item{'desc'};
}else{
	    $registdesc = $item{'desc'};
}
	&registdb($item{'start'},$item{'stop'},$item{'channel'},$item{'title'},$registdesc ,$item{'category'});

#	print "$item{start}
#$item{stop}
#$item{channel}
#$item{title}
#$item{desc}
#$item{category}
# -------------------------------\n";

	$item{start} = "";
	$item{stop} = "";
	$item{channel} = "";
	$item{title} = "";
	$item{subtitle} = "";
	$item{desc} = "";
	$item{category} = "";
	$registdesc = "";
}# endif
}# while
&commitdb;


#end
################

sub replaceepg{
#�ä�EPG��ID��������ɲä��ޤ�
my $foltiastarttime = $_[0]; # 14��
my $ontvepgchannel =  $_[1];
my $foltiaendtime = $_[2]; # 14��
my @data = ();

$foltiastarttime = substr($foltiastarttime,0,12); # 12�塡200508072254
$foltiaendtime   = substr($foltiaendtime,0,12); # 12�塡200508072355

$sth = $dbh->prepare($stmt{'xmltv2foltia.replaceepg.1'});
my $now = &epoch2foldate(time());
$sth->execute($foltiastarttime , $foltiaendtime , $ontvepgchannel);
while (@data = $sth->fetchrow_array()) {
	push(@deleteepgid,$data[0]);
	#&writelog("xmltv2foltia DEBUG push(\@deleteepgid,$data[0]);");
}#end while 

#��񤭤�ä�
$sth = $dbh->prepare($stmt{'xmltv2foltia.replaceepg.2'});
$sth->execute($foltiastarttime , $foltiaendtime , $ontvepgchannel);
while (@data = $sth->fetchrow_array()) {
	push(@deleteepgid,$data[0]);
	#&writelog("xmltv2foltia DEBUG push(\@deleteepgid,$data[0]);");
}#end while 

}#endsub replaceepg

sub registdb{
my $foltiastarttime = $_[0];
my $foltiaendtime = $_[1];
my $channel = $_[2];
my $title = $_[3];
my $desc = $_[4];
my $category = $_[5];

#Encode::JP::H2Z::z2h(\$string);
$title = jcode($title)->tr('��-�ڣ�-����-�����������ʡˡ��ܡ��ݡ����������䡩���Ρ��ϡ������Сáѡ�','A-Za-z0-9!#$%&()*+,-./:;<=>?@[\]^_`{|} ');
$desc = jcode($desc)->tr('��-�ڣ�-����-�����������ʡˡ��ܡ��ݡ����������䡩���Ρ��ϡ������Сáѡ�','A-Za-z0-9!#$%&()*+,-./:;<=>?@[\]^_`{|} ');
#$title = jcode($title)->tr('��-�ڣ�-����-�����������ʡˡ��ܡ��ݡ����������䡩���Ρ��ϡ������Сá�','A-Za-z0-9!#$%&()*+,-./:;<=>?@[\]^_`{|}');
#$desc = jcode($desc)->tr('��-�ڣ�-����-�����������ʡˡ��ܡ��ݡ����������䡩���Ρ��ϡ������Сá�','A-Za-z0-9!#$%&()*+,-./:;<=>?@[\]^_`{|}');

#&writelog("xmltv2foltia DEBUG $foltiastarttime:$foltiaendtime");
$foltiastarttime = substr($foltiastarttime,0,12);
$foltiaendtime = substr($foltiaendtime,0,12);

#if($foltiaendtime > $todaytime){#���Ȥ˾�äƤ��������̵��ﹹ��
# epgid��AUTOINCREMENT���ѹ����� #2010/8/10 
#	$sth = $dbh->prepare($stmt{'xmltv2foltia.registdb.1'});
#		$sth->execute();
#	 @currentepgid = $sth->fetchrow_array;
#	 
#	if ($currentepgid[0] < 1 ){
#		$newepgid = 1;
#	}else{
#		$newepgid = $currentepgid[0]; 
#		$newepgid++; 
#	}
#&writelog("xmltv2foltia DEBUG $currentepgid[0] /  $newepgid");
my $lengthmin = &calclength($foltiastarttime , $foltiaendtime);

#print "xmltv2foltia DEBUG :INSERT INTO foltia_epg VALUES ($newepgid, $foltiastarttime, $foltiaendtime, $lengthmin, $channel, $title, $desc, $category)\n";
push (@foltiastarttime,$foltiastarttime);
push (@foltiaendtime,$foltiaendtime); 
push (@lengthmin,$lengthmin); 
push (@channel,$channel); 
push (@title,$title); 
push (@desc,$desc);
push (@category,$category);
#	$sth = $dbh->prepare($stmt{'xmltv2foltia.registdb.2'});
#	$sth->execute($newepgid, $foltiastarttime, $foltiaendtime, $lengthmin, $channel, $title, $desc, $category) || warn "error: $newepgid, $foltiastarttime, $foltiaendtime, $lengthmin, $channel, $title, $desc, $category\n";
# &writelog("xmltv2foltia DEBUG $DBQuery");
#}else{
#&writelog("xmltv2foltia DEBUG SKIP $foltiastarttime:$foltiaendtime");
#}#̤�褸��ʤ�����������ʤ�

}#end sub registdb

sub commitdb{
$dbh->{AutoCommit} = 0;
#print Dumper(\@dbarray);
my $loopcount = @foltiastarttime;
my $i = 0;

#���
foreach $delid (@deleteepgid){
	$sth = $dbh->prepare($stmt{'xmltv2foltia.commitdb.1'});
	$sth->execute( $delid ) || warn "$delid\n";
	#&writelog("xmltv2foltia DEBUG $stmt{'xmltv2foltia.commitdb.1'}/$delid");
}
#�ɲ�
for ($i=0;$i<$loopcount;$i++){
	$sth = $dbh->prepare($stmt{'xmltv2foltia.commitdb.2'});
	$sth->execute( $foltiastarttime[$i],$foltiaendtime[$i], $lengthmin[$i], $channel[$i], $title[$i], $desc[$i], $category[$i]) || warn "error: $foltiastarttime, $foltiaendtime, $lengthmin, $channel, $title, $desc, $category\n";
	#&writelog("xmltv2foltia DEBUG $stmt{'xmltv2foltia.commitdb.2'}/$foltiastarttime[$i],$foltiaendtime[$i], $lengthmin[$i], $channel[$i], $title[$i], $desc[$i], $category[$i]");
}# end for
$dbh->commit;
$dbh->{AutoCommit} = 1;
}#end sub commitdb

sub removetag(){
my $str = $_[0];

# HTML����������ɽ�� $tag_regex
my $tag_regex_ = q{[^"'<>]*(?:"[^"]*"[^"'<>]*|'[^']*'[^"'<>]*)*(?:>|(?=<)|$(?!\n))}; #'}}}}
my $comment_tag_regex =
    '<!(?:--[^-]*-(?:[^-]+-)*?-(?:[^>-]*(?:-[^>-]+)*?)??)*(?:>|$(?!\n)|--.*$)';
my $tag_regex = qq{$comment_tag_regex|<$tag_regex_};


my    $text_regex = q{[^<]*};

 my   $result = '';
    while ($str =~ /($text_regex)($tag_regex)?/gso) {
      last if $1 eq '' and $2 eq '';
      $result .= $1;
      $tag_tmp = $2;
      if ($tag_tmp =~ /^<(XMP|PLAINTEXT|SCRIPT)(?![0-9A-Za-z])/i) {
        $str =~ /(.*?)(?:<\/$1(?![0-9A-Za-z])$tag_regex_|$)/gsi;
        ($text_tmp = $1) =~ s/</&lt;/g;
        $text_tmp =~ s/>/&gt;/g;
        $result .= $text_tmp;
      }
    }


return $result ;

} # end sub removetag