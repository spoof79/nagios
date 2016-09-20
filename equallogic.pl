#!/usr/bin/perl -w
#script to check eql FS stats and status, works on version 8+?
#Written by Micha Toma, 2016 for Projectplace and Naemon
# Edit as you will, but leave this text.
# mihnea.toma@gmail.com

#USAGE
#     ./check_eql_fs.pl -H hostname -C community -s sharename -w 90 -c 95
#     CRITICAL:  sharename - 97 % used (320 GB free) | 'used'=7858, 'size'=8179, 'free'=320, 'percent used'=97%;90;96
##Requires
# FluidFS-MIB.txt  download this by ftp from your san/nas. or from equallogics homepage.

### Gather input from user
#############################
my $check_type;
my $warn = 0;
my $crit = 0;
my $int;
my $oidint;

while(@ARGV) {
        my $temp = shift(@ARGV);
        if("$temp" eq '-H') {
                $host = shift(@ARGV);
        } elsif("$temp" eq '-C') {
                $snmpc = shift(@ARGV);
        } elsif("$temp" eq '-s') {
                $share = shift(@ARGV);
        } elsif("$temp" eq '-w') {
                $warn = shift(@ARGV);
        } elsif("$temp" eq '-c') {
                $crit = shift(@ARGV);
        } else {
                print("You forgot something?");
        }
}

@sysname = `snmpwalk -m /root/.snmp/mibs/FluidFS-MIB.txt -v2c -c $snmpc $host FLUIDFS-MIB::nASVolumeIndex | cut -d' ' -f 4`;
foreach $line (@sysname)  {
        $oid = $line;
        $name = `snmpwalk -O qv -m /root/.snmp/mibs/FluidFS-MIB.txt -v2c -c $snmpc $host FLUIDFS-MIB::nASVolumeVolumeName.$oid`;
        $name =~ m/\"(.*?)\"/;
        $name = $1;
        if ($share eq $name) {
                $size= `snmpwalk -m /root/.snmp/mibs/FluidFS-MIB.txt -v2c -c $snmpc $host FLUIDFS-MIB::nASVolumeSizeMB.$oid`;
                $size =~ m/\"(\d+)\"/;
                $size= int($1/1000);
                $used= `snmpwalk -m /root/.snmp/mibs/FluidFS-MIB.txt -v2c -c $snmpc $host FLUIDFS-MIB::nASVolumeUsedSpaceMB.$oid`;
                $used =~ m/\"(.*?)\"/;
                $used= int($1/1000);
                $left = $size-$used;
                $perc = ($left / $size) * 100;
                $perc = int($perc);
                $perc = 100 - $perc;
                if ($perc <= $warn) {
                        $stat = 0;
                        $msg = "OK: $name - $perc % used ($left GB free)";
                }
                if ($perc >= $warn and $perc < $crit) {
                        $stat=1;
                        $msg = "WARNING:  $name - $perc % used ($left GB free)";
                }
                if ($perc >= $crit) {
                        $stat=2;
                        $msg = "CRITICAL:  $name - $perc % used ($left GB free)";
                }

                $perf = "'used'=$used, 'size'=$size, 'free'=$left, 'percent used'=$perc%;$warn;$crit";
        }

}
print "$msg | $perf\n";
exit($stat);
