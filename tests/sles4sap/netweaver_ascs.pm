# SUSE's SLES4SAP openQA tests
#
# Copyright © 2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Checks NetWeaver's ASCS installation as performed by sles4sap/nw_ascs_install
# Requires: sles4sap/nw_ascs_install, ENV variable SAPADM
# Maintainer: Alvaro Carvajal <acarvajal@suse.de>

use base "opensusebasetest";
use testapi;
use utils;
use strict;

sub run {
    my ($self)       = @_;
    my $output       = '';
    my $pscmd        = "ps auxw | grep ASCS | grep -vw grep";
    my $prev_console = $testapi::selected_console;

    select_console 'root-console';

    # The SAP Admin was set in sles4sap/nw_ascs_install
    my $sapadmin = get_required_var('SAPADM');
    my $sid = uc(substr($sapadmin, 0, 3));

    # Allow SAP Admin user to inform status via $testapi::serialdev
    assert_script_run "chown $sapadmin /dev/$testapi::serialdev";

    type_string "su - $sapadmin\n";

    $output = script_output "sapcontrol -nr 00 -function GetVersionInfo";
    die "sapcontrol: GetVersionInfo API failed\n\n$output" unless ($output =~ /GetVersionInfo[\r\n]+OK/);

    $output = script_output "sapcontrol -nr 00 -function GetInstanceProperties | grep ^SAP";
    die "sapcontrol: GetInstanceProperties API failed\n\n$output" unless ($output =~ /SAPSYSTEM.+SAPSYSTEMNAME.+SAPLOCALHOST/s);

    $output =~ /SAPSYSTEMNAME, Attribute, ([A-Z][A-Z0-9]{2})/m;
    die "sapcontrol: SAP administrator [$sapadmin] does not match with System SID [$1]" if ($1 ne $sid);

    $output = script_output "sapcontrol -nr 00 -function Stop";
    die "sapcontrol: Stop API failed\n\n$output" unless ($output =~ /Stop[\r\n]+OK/);

    $output = script_output "sapcontrol -nr 00 -function StopService";
    die "sapcontrol: StopService API failed\n\n$output" unless ($output =~ /StopService[\r\n]+OK/);

    script_run "$pscmd | wc -l ; $pscmd";
    save_screenshot;

    $output = script_output "sapcontrol -nr 00 -function StartService $sid";
    die "sapcontrol: StartService API failed\n\n$output" unless ($output =~ /StartService[\r\n]+OK/);

    $output = script_output $pscmd;
    my @olines = split(/\n/, $output);
    die "sapcontrol: wrong number of processes running after an StartService\n\n" . @olines unless (@olines == 1);
    die "sapcontrol failed to start the service" unless ($output =~ /^$sapadmin.+sapstartsrv/);

    $output = script_output "sapcontrol -nr 00 -function Start";
    die "sapcontrol: Start API failed\n\n$output" unless ($output =~ /Start[\r\n]+OK/);

    $output = script_output $pscmd;
    @olines = split(/\n/, $output);
    die "sapcontrol: failed to start the instance" unless (@olines > 1);

    # Rollback changes to $testapi::serialdev and close the window
    type_string "exit\n";
    assert_script_run "chown $testapi::username /dev/$testapi::serialdev";

    # Return to previous console
    select_console($prev_console, await_console => 0);
    ensure_unlocked_desktop if ($prev_console eq 'x11');
}

1;
# vim: set sw=4 et:
