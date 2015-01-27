#!/usr/bin/perl
#
# Written By    : <Robin.Peter@gmail.com>
# Created On    : Thu Feb 24 14:08:48 IST 2012
# Modified On	: Thu Aug  8 14:57:24 PDT 2013
# Program Name  : na-nfs-top.pl
# Version 	: 2.2.1
#
#------------------------------------------------------------------#
use strict;
use Socket;	
use Net::LDAP;
use lib "/lib/NetApp";
use NaServer;
use NaElement;
#------------------------------------------------------------------#
my $sfiler    = $ARGV[0];
my $maxclient = $ARGV[1];
if ($maxclient eq '' ) {
    $maxclient = 20;
}
#------------------------------------------------------------------#
sub connect_netapp {
    my $filer   = shift;
    my $fi1er   = NaServer->new($filer, 1, 20);
    if ( !defined ($filer) ) {
        my $outa    = $filer->set_server_type("FILER");
        my $reason  = $outa->results_reason();
        print "Unable to set server type 'FILER'. $reason\n";
        exit 2;
	}
    if ( !defined ($filer) ) {
        my $outb    = $filer->set_style("HOSTS");
        my $reason  = $outb->results_reason();
        print "Unable to set auth style 'HOSTS'. $reason\n";
        exit 2;
    }
    if ( !defined ($filer) ) {
        my $outc    = $filer->set_transport_type("HTTP");
        my $reason  = $outc->results_reason();
        print "Unable to set transport type 'HTTP'. $reason\n";
        exit 2;
    }
    if ( !defined ($filer) ) {
        my $outd    = $filer->set_timeout(60);
        my $reason  = $outd->results_reason();
        print "Unable to set connection timeout '60'. $reason\n";
        exit 2;
    }
    return $fi1er;
}
#------------------------------------------------------------------#
sub nfs_stats_top_start {
    my $nfs_details;
    my $ss = connect_netapp($sfiler);
    my $outa = $ss->invoke("nfs-stats-top-clients-list-iter-start", "maxclients", $maxclient);
    if ($outa->results_status() eq "failed"){
        print($outa->results_reason() ."\n");
        exit (-2);
    }
	my $records = $outa->child_get_int("records");
	my $tag = $outa->child_get_int("tag");

    my $outb = $ss->invoke("nfs-stats-top-clients-list-iter-next", "maximum", $records, "tag", $tag);
    if ($outb->results_status() eq "failed"){
        print($outb->results_reason() ."\n");
        exit (-2);
    }
    my $nfs_info = $outb->child_get("nfs-top");
    my @result = $nfs_info->children_get();
    system("clear");
    print "TOT_NFS\tGETATTR\tLOOKUP\tREDLINK\tREAD\tWRITE\tCREATE\tREMOVE\tREADDIR\tCLIENT_HOSTNAME\n";
    foreach my $i (@result){
        my $client_info	= $i->child_get_string("client-info");
        $client_info =~ s/(:|f)//g;
        my $ipaddr = inet_aton($client_info);
        my $hostname = gethostbyaddr($ipaddr, AF_INET);
        my $total_ops = $i->child_get_int("total-ops");
        my $getattr_ops = $i->child_get_int("getattr-ops");
        my $lookup_ops = $i->child_get_int("lookup-ops");
        my $readlink_ops = $i->child_get_int("readlink-ops");
        my $read_ops = $i->child_get_int("read-ops");
        my $write_ops = $i->child_get_int("write-ops");
        my $create_ops = $i->child_get_int("create-ops");	
        my $remove_ops = $i->child_get_int("remove-ops");
        my $readdir_ops = $i->child_get_int("readdir-ops");
        if (!$hostname) {
            $hostname = $client_info;
        }
        print "$total_ops\t$getattr_ops\t$lookup_ops\t$readlink_ops\t$read_ops\t$write_ops\t$create_ops\t$remove_ops\t$readdir_ops\t$hostname\n";
    }
    my $outc = $ss->invoke("nfs-stats-top-clients-list-iter-end", "tag", $tag);
    if ($outc->results_status() eq "failed"){
        print($outc->results_reason() ."\n");
        exit (-2);
    }
    my $outd = $ss->invoke("nfs-stats-zero-stats");
    if ($outd->results_status() eq "failed"){
        print($outd->results_reason() ."\n");
        exit (-2);
    }	
}
#------------------------------------------------------------------#
while ( $ARGV[0] eq $sfiler ) {
    nfs_stats_top_start($sfiler);
    sleep(2);
}
#------------------------------------------------------------------#
#EOF
