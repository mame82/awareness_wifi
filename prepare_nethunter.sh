#!/bin/bash

# Tauthor: MaMe82
# This script has to run outside chroot once (using android Terminal emulator with su rights)
# to prepare nethunter for running apps and commands outside chroot
#
# 1) It creates /system/bin/exec_root_cmd, which is basically a copy of bootkali, capable
#    of running custom shell commands
#
# 2) It creates /system/bin/am2, a modified version of am (Activity Manage), which is able
#    to start Android Actions / Intents from within the nethunter chroot
# 
# To using this command in a meaningful way relies on preinstalled jackpal.androidterm (delivered
# with nethunter), thus running a new AndroidTerm which issues a command outside chroot get's
# possible using am2
# If this way is taken to run exec_root_command form a new Androidterm, we are able to start
# commands in nethunter chroot, which are using a new TerminalWindow (comes in handy, when
# using with custom access-point, which usually starts new gnome-terminals for secondary
# commands
#
# example: /system/bin/am2 start -a jackpal.androidterm.RUN_SCRIPT -e jackpal.androidterm.iInitialCommand "su -c 'bootkali kalimenu'"
# 
#
# 1 and 2 are not implemented yet, cause using jackpal.androidterm to start new Tab via intent isn't possible
# (has to be done by hand
# 
# 3) To make sudo work within nethunter, we need to change the filesystem mount, because /data is mounted
#    with 'nosuid' set. We have to remount /data (without suid) from Android root shell, to circumvent that issue 

function remount_nethunter_without_nosuid
{
	mount -o remount,rw,nodev,noatime,errors=panic,user_xattr,barrier=1,journal_async_commit,data=ordered,noauto_da_alloc,discard /data
}

function remount_nethunter_with_nosuid
{
        mount -o remount,rw,nosuid,nodev,noatime,errors=panic,user_xattr,barrier=1,journal_async_commit,data=ordered,noauto_da_alloc,discard /data
}

remount_nethunter_without_nosuid
