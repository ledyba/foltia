<?php
/*
 Anime recording system foltia
 http://www.dcc-jpl.com/soft/foltia/

foltia_config2.php

��Ū
�������ե������2�Ĥ�Ǥ���


 DCC-JPL Japan/foltia project

*/

        $toolpath = "/server/www/foltia" ; //��php�ץǥ��쥯�ȥ꤬����ѥ�
		$recfolderpath = '/recorded';	//Ͽ��ե��������¸��Υѥ���
		$httpmediamappath = '/foltia/recorded'; //�֥饦�����鸫����Ͽ��ե�����Τ�����֡�
		$recunits = 2;					//��ܥ��ʥ�����ץ��㥫���ɥ����ͥ��

		$protectmode = 0; //̤����:(�֥饦�������ͽ������ػߤ���ʤɤ��ݸ�⡼�ɤ�ư��ޤ�)
		$demomode = 0; //̤����:(�桼�����󥿡��ե���������ư���ǥ�⡼�ɤ�ư��ޤ�)
		$useenvironmentpolicy = 0 ;//�Ķ��ݥꥷ����Ȥ����ɤ���
		$environmentpolicytoken = "";//�Ķ��ݥꥷ���Υѥ���ɤ�Ϣ�뤵��륻�����ƥ�������
		$perltoolpath = $toolpath ;//perl�Ǥν������ΰ��֡��ǥե���ȤǤ�php��Ʊ������
		$usedigital = 1;//Friio�ʤɤǥǥ�����Ͽ��򤹤뤫 1:���� 0:���ʤ�

// �ǡ����١�����³����
// define("DSN", "pgsql:host=localhost dbname=foltia user=foltia password= ");
define("DSN", "sqlite:/server/data/foltia/foltia.sqlite");

//        $mylocalip = "192.168.0.177" ; //ư���Ƥ��뵡����IP���ɥ쥹

?>
