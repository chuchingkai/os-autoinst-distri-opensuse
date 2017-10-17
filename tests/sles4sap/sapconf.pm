# SUSE's openQA tests
#
# Copyright © 2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: sapconf availability and basic commands to tuned-adm
# Maintainer: Alvaro Carvajal <acarvajal@suse.de>

use base "opensusebasetest";
use testapi;
use utils;
use strict;

sub run {
    my ($self)       = @_;
    my $prev_console = $testapi::selected_console;
    my $output       = '';

    select_console 'root-console';

    $output = script_output "sapconf status";
    my $statusregex
      = 'tuned.service - Dynamic System Tuning Daemon.+'
      . 'Loaded: loaded \(/usr/lib/systemd/system/tuned.service;.+'
      . 'Active: active \(running\).+'
      . 'Starting Dynamic System Tuning Daemon.+'
      . 'Started Dynamic System Tuning Daemon.$';
    die "Command 'sapconf status' output is not recognized" unless ($output =~ m|$statusregex|s);

    foreach my $cmd (qw(start hana b1 ase sybase bobj)) {
        $output = script_output "sapconf $cmd";
        die "Command 'sapconf $cmd' output is not recognized" unless ($output =~ /Forwarding action to tuned\-adm.$/);
    }

    # Return to previous console
    select_console($prev_console, await_console => 0);
    ensure_unlocked_desktop if ($prev_console eq 'x11');
}

1;
# vim: set sw=4 et:
