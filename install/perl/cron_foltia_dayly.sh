#!/bin/sh
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
# ����¹ԥ���ֵ��ҥե����롣
#cron��1��1�����ټ¹Ԥ���Ȥ褤�Ǥ��礦��
#
# DCC-JPL Japan/foltia project
#

#�ǥ�������������콵��ʬ��EPG�����
/server/www/foltia/perl/epgimport.pl long

# XMLTV��Ĥ��ä�EPG����ɽ����ݡ���(���ʥ����ѵ����)
#
#/usr/bin/perl  /usr/bin/tv_grab_jp | /home/foltia/perl/xmltv2foltia.pl
# 2�Ĥζ�����Ȥ��褦�ʾ��
#/usr/bin/perl  /usr/bin/tv_grab_jp --config-file ~/.xmltv/tv_grab_jp.conf.jcom  | /home/foltia/perl/xmltv2foltia.pl
#/usr/bin/perl  /usr/bin/tv_grab_jp --config-file ~/.xmltv/tv_grab_jp.conf.tvk  | /home/foltia/perl/xmltv2foltia.pl

#Ͽ��ե�����ȥơ��֥���������򹹿�
/server/www/foltia/perl/updatem2pfiletable.pl

#2������Υ������塼������
/server/www/foltia/perl/getxml2db.pl long

