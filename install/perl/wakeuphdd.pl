#!/usr/bin/suidperl

$ENV{'PATH'}='/sbin';
print `hdparm --idle-immediate /dev/sdb`;
