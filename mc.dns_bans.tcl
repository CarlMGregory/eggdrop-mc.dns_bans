##
# DNS Bans v1.2
#  by MC_8 - Carl M. Gregory <mc8@purehype.net>
#  This script will only run on eggdrop 1.5.5 or greater.
#  This script requires the DNS Module.  If it isn't loaded when this script is
#    loaded, it will try to load it for you.
#
# My Website - http://mc.purehype.net:81/
# Have a bug?  http://mc.purehype.net:81/bugzilla/
##

##
# This script will DNS channel users hostname/ip and evaluate to see if there in the
# banlist, regardless of ip or hostname banning.
# Example:  Say you ban 24.72.12.*, and someone enters the channel with a hostname
#           of poached.eggheads.org.  poached.eggheads.org's DNS entry is
#           24.72.12.134, so the user would be considered ban'd and treated as such.
#           Same in reverse (ban *.eggheads.org would ban 24.72.12.134).
##

##
# The history log has been moved to the very bottom of this script.
##

##
# Commands (dcc)
##
# chanset <#channel> <+/->mc.dnsbans
#   This will enable (+) or disable (-) the script for the specific channel.
##

##
# Settings
##
#

# [0=no/1=yes] Do you want to exempt opped users in the channel?
set mc_dnsb(exempt:op) 1

# [0=no/1=yes] Do you want to exempt voiced users in the channel?
set mc_dnsb(exempt:voice) 0

# What flaged users do you want to exempt?  Set this to "" to exempt no one.  Flag
# syntax is:  <global>|<channel>
set mc_dnsb(exempt:flag) "ob|o"

# If a user is found to match a ban, reversed in DNS (ip <> host), what banmask
# would you like the script to ban with?
#      0 - *!user@host.domain
#      1 - *!*user@host.domain
#      2 - *!*@host.domain
#      3 - *!*user@*.domain
#      4 - *!*@*.domain
#      5 - nick!user@host.domain
#      6 - nick!*user@host.domain
#      7 - nick!*@host.domain
#      8 - nick!*user@*.domain
#      9 - nick!*@*.domain
#     You can also specify a type of 10 to 19 which correspond to masks
#     0 to 9.  But if the host.domain is a;
#       hostname = Instead of using a * wildcard to replace portions of
#                  the host.domain, it replaces the numbers in the
#                  host.domain with a '?' (question mark) wildcard
#       ip       = It will mask as normal, with no '?' (question mark)
#                  replacments as does hostname.
set mc_dnsb(banmask) 13


## SVS Client (Script Version Service) v3.0 ##
# Once a day, the SVS Client will connect to MC_8's SVS Server to determin if there
# is a newer version of this script avilable.  This will only notify users of the ne
# version via a note.  It's up to the owner of the bot to download, adjust settings
# then install the script.

# If a newer version is found, whom do you want to notify?  The notification is sent
# via a note.  Seperate each user with a space, or set this to "" to disable SVS
# notification.  For those whom know TCL; do not put this in list format, keep it in
# string format.
set mc_dnsb(svs:notify) "MC_8"

# Would you like to restrict the concept of a new version to stable releases only?
#   0 = No, inform of both stable and beta release versions.
#   1 = Yes, inform of only stable release versions.
set mc_dnsb(svs:mode) 0

##

##
# TCL Coding below, do not proceed.
##

#Script:dnsb

set mc_dnsb(script)      "DNS Bans"
set mc_dnsb(version)     "v1.2"
set mc_dnsb(svs:script)  "dnsbans"
set mc_dnsb(svs:version) "001002000000"
set mc_dnsb(svs:server)  "mc.purehype.net"
set mc_dnsb(svs:port)    "81"
set mc_dnsb(svs:get)     "/svs_client_interface.tcl"
set mc_dnsb(svs:query)   "svs=$mc_dnsb(svs:script)&version=$mc_dnsb(svs:version)"

catch {unset temp}
if {![info exists numversion] || ($numversion < "1050500")} {
	set temp(tag) "$mc_dnsb(script) $mc_dnsb(version)"
	putlog "$temp(tag) by MC_8 will only work on eggdrop 1.5.5 or greater."
	putlog "$temp(tag)  will not work with eggdrop $version."
	putlog "$temp(tag)  not loaded."
	return 1
}

set temp(loaded) 0
foreach temp(module) [modules] {
	if {[lindex $temp(module) 0] == "dns"} {
		set temp(loaded) 1
		break
	}
}
if {!$temp(loaded)} {
	if {[catch {loadmodule dns} error]} {
		set temp(tag) "$mc_dnsb(script) $mc_dnsb(version)"
		putlog "$temp(tag) by MC_8 requires the DNS module."
		putlog "$temp(tag)  Could not auto load the DNS module, error:"
		foreach line [split $error \n] {
			putlog "$temp(tag)    $line"
		}
		putlog "$temp(tag)  not loaded."
		return 1
	}
}

setudef flag mc.dnsbans


# Error system, v2.1.1
proc mc:dnsb:error {bindproc error {arg ""}} {
	global mc_dnsb version lastbind
	putlog "Error in script $mc_dnsb(script) $mc_dnsb(version)."
	putlog "    Error System: v2.1.1"
	putlog "       Last Bind: [expr {[info exists lastbind] ? $lastbind : "-NULL-"}]"
	putlog "       Procedure: $bindproc"
	putlog "       Arguments: $arg"
	putlog "    Egg. Version: [expr {[info exists version] ? $version : "-NULL-"}]"
	putlog "     TCL Version: [info tclversion]"
	putlog "  TCL Patchlevel: [info patchlevel]"
	putlog "*** Please submit this bug so MC_8 can fix it.  Visit"
	putlog "*** http://mc.purehype.net:81/bugzilla/ to properly report the bug."
	putlog "*** Please include ALL information in the bug report, including the next"
	putlog "***	line(s) all the way down to where it mentions the Tcl error."
	error $error
}

proc mc:dnsb:errchk {command arg} {
	if {[catch {eval $command $arg} return]} {
		mc:dnsb:error $command $return $arg
		return 0
	}; return $return
}
# ^

bind join - * mc:dnsb:join
proc mc:dnsb:join {nick uhost hand chan} {
	return [mc:dnsb:errchk mc:dnsb:join_ [list $nick $uhost $hand $chan]]
}
proc mc:dnsb:join_ {nick uhost hand chan} {
	if {![mc:dnsb:chanflag $chan mc.dnsbans]} {return 0}
	global mc_dnsb
	if {[isbotnick $nick]} {
		set nick [chanlist $chan]
		set uhost ""
		set hand ""
		foreach item $nick {
			lappend uhost [getchanhost $item $chan]
			lappend hand [nick2hand $item $chan]
		}
	} else {
		set nick [list $nick]
		set uhost [list $uhost]
		set hand [list $hand]
	}
	foreach ircnick $nick userhost $uhost handle $hand {
		if {([matchattr $handle $mc_dnsb(exempt:flag) $chan] &&
		     ($mc_dnsb(exempt:flag) != "")) || [isbotnick $ircnick]} {continue}
		regexp -- (.*)@(.*) $uhost dummy ident host
		dnslookup [list $host] mc:dnsb:dnsreturn [list $host $ircnick $ident $handle\
			$chan]
	}
}

bind mode - "% +b" mc:dnsb:mode
proc mc:dnsb:mode {nick uhost hand chan mc {victim ""}} {
	return [mc:dnsb:errchk mc:dnsb:mode_ [list $nick $uhost $hand $chan $mc $victim]]
}
proc mc:dnsb:mode_ {nick uhost hand chan mc victim} {
	if {![mc:dnsb:chanflag $chan mc.dnsbans]} {return 0}
	global mc_dnsb
	if {$nick == ""} {
		set cache(chanban) [list [list $victim $uhost 0]]
	} else {
		set cache(chanban) [list [list $victim $nick!$uhost 0]]
	}
	foreach nick [chanlist $chan] {
		set hand [nick2hand $nick $chan]
		if {($mc_dnsb(exempt:op) && [isop $nick $chan]) ||
		    ($mc_dnsb(exempt:voice) && [isvoice $nick $chan]) ||
		    (($mc_dnsb(exempt:flag) != "") &&
		     [matchattr $hand $mc_dnsb(exempt:flag) $chan])} {continue}
		regexp -- (.*)@(.*) [getchanhost $nick $chan] dummy ident host
		dnslookup [list $host] mc:dnsb:dnsreturn [list $host $nick $ident $hand	$chan \
			$cache(chanban)]
	}; return 1
}

proc mc:dnsb:dnsreturn {ip host status eval nick ident hand chan {addition ""}} {
	return [mc:dnsb:errchk mc:dnsb:dnsreturn_ [list $ip $host $status $eval $nick \
		$ident $hand $chan $addition]]
}
proc mc:dnsb:dnsreturn_ {ip host status eval nick ident hand chan addition} {
	global mc_dnsb botnick
	if {!$status || ![onchan $nick $chan] || ![isop $botnick $chan] ||
	    ![mc:dnsb:chanflag $chan mc.dnsbans] ||
	    ($mc_dnsb(exempt:op) && [isop $nick $chan]) ||
	    ($mc_dnsb(exempt:voice) && [isvoice $nick $chan]) ||
	    (($mc_dnsb(exempt:flag) != "") &&
	     [matchattr $hand $mc_dnsb(exempt:flag) $chan])} {return 0}
	if {$ip == $eval} {
		set rh $host
		set oh $ip
	} else {
		set rh $ip
		set oh $host
	}
	if {![set temp(isban) [matchban $nick!$ident@$rh $chan]]} {
		foreach ban "$addition [chanbans $chan]" {
			set temp(1) [string tolower [lindex $ban 0]]
			if {[string match $temp(1) [string tolower $nick!$ident@$rh]]} {
				set temp(isban) 1
				break
			}
		}; if {!$temp(isban)} {return 0}
	}; pushmode $chan +b [mc:dnsb:masktype $nick!$ident@$oh $mc_dnsb(banmask)]
}

# v1.3  -- mc.moretools proc
proc mc:dnsb:masktype {nuhost type} {
	set ident_max-length 9
	set host_max-length 63
	scan $nuhost {%[^!]!%s} nick uhost
	set temp(split_uhost) [split $uhost @]
	set temp(1) [expr [llength $temp(split_uhost)]-2]
	set ident [join [lrange $temp(split_uhost) 0 $temp(1)] @]
	set host [lindex $temp(split_uhost) end]
	set maskhost 1
	if {[regexp -- {^1[0-9]$} $type]} {
		set temp(w) {([0-9][0-9]?[0-9]?)}
		set temp(x) "^$temp(w)\\.$temp(w)\\.$temp(w)\\.$temp(w)\$"
		if {!(([regexp -- $temp(x) $host temp(1) a b c d]) &&
		     ($a > 0 && $a <= 255 && $b <= 255 && $c <= 255 && $d <= 255))} {
			regsub -all -- {[0-9]} $host ? host
			set maskhost 0
		}
		set type [string index $type 1]
	}
	if {[regexp -- {^[0-4]$} $type]} {set nick "*"}
	if {[regexp -- {^[2479]$} $type]} {set ident "*"}
	if {[regexp -- {^[1368]$} $type]} {regsub -- {^~?(.*)$} $ident *\\1 ident}
	if {[regexp -- {^[3489]$} $type]} {
		if {$maskhost} {set host [lindex [split [maskhost $host] @] end]}
	}
	if {[set cache(x) [string length $ident]] > ${ident_max-length}} {
		set ident "*[string range $ident [expr $cache(x)-${ident_max-length}] end]"
	}
	if {[set cache(x) [string length $host]] > ${host_max-length}} {
		set host "*[string range $host [expr $cache(x)-${host_max-length}] end]"
	}
	return [format "%s!%s@%s" $nick $ident $host]
}

# v3.0  -- mc.moretools proc
proc mc:dnsb:chanflag {channel flag} {
	if {![catch {channel get $channel $flag} catch]} {return $catch}
	set temp(1) [string tolower [channel info $channel]]
	if {[lsearch -exact $temp(1) +[string tolower $flag]] >= "0"} {return 1}
	return 0
}

## SVS v3.0
set mc_dnsb(svs:client_version) "v3.0"
if {![info exists mc_dnsb(svs:mode)] ||
    ![regexp -- {^(1|0)$} $mc_dnsb(svs:mode)]} {
	set mc_dnsb(svs:mode) 0
}
if {![info exists mc_dnsb(svs:notify)]} {
	if {![info exists owner]} {set owner ""}
	set mc_dnsb(svs:notify) $owner
}

bind time - "00 00 *" mc:dnsb:do_svs
proc mc:dnsb:do_svs {{args ""}} {
	global mc_dnsb
	if {[catch {
	        socket -async $mc_dnsb(svs:server) $mc_dnsb(svs:port)
	           } sid]} {
		putloglev d * "$mc_dnsb(script): SVS socket error: $sid"
		return 1
	}

	# This block of code is to get a standard User-Agent line of information, as
	# proposed in http://www.mozilla.org/build/revised-user-agent-strings.html
	foreach array_name [list platform os osVersion machine] {
		set temp($array_name) [lindex [array get tcl_platform $array_name] 1]
	}
	switch -- $temp(platform) {
		windows {
			switch -- $temp(os) {
				Windows {set temp(2) Win$temp(osVersion)}
				"Windows 95" {
					if {$temp(osVersion) < "4.10"} {
						set temp(2) Win95
					} else {
						set temp(2) Win98
					}
				}
				"Windows 98" {set temp(2) Win98}
				"Windows NT" {
					if {$temp(osVersion) >= "5.0"} {
						set temp(2) "Windows NT $temp(osVersion)"
					} else {
						set temp(2) WinNT$temp(osVersion)
					}
				}
				default {
					set temp(2) "$temp(os) $temp(osVersion)"
				}
			}
		}
		unix {
			set temp(2) "unix $temp(machine)"
		}
		macintosh {
			set temp(2) $temp(machine)
		}
		default {
			set temp(2) "$temp(os) $temp(osVersion) $temp(machine)"
		}
	}
	set temp(user_agent) "Mozilla/5.001 ($temp(platform); U; $temp(2); en) "
	append temp(user_agent) "Gecko/25250101 $mc_dnsb(svs:script)/"
	append temp(user_agent) "$mc_dnsb(svs:version) SVS_Client/"
	append temp(user_agent) "$mc_dnsb(svs:client_version)"
	# ^

	fconfigure $sid -blocking 0 -buffering line
	set tout [after 60000 "mc:dnsb:svs_talk $sid timeout"]
	fileevent $sid readable "mc:dnsb:svs_talk $sid $tout"
	puts $sid "GET $mc_dnsb(svs:get)?$mc_dnsb(svs:query) HTTP/1.0\
	         \nHost: $mc_dnsb(svs:server):$mc_dnsb(svs:port)\
	         \nUser-Agent: $temp(user_agent)\n"
	flush $sid
}

proc mc:dnsb:svs_talk {sid tout} {
	global mc_dnsb
	set array [list svs temp $sid]
	if {$tout == "timeout"} {
		set temp(1) "$mc_dnsb(svs:server):$mc_dnsb(svs:port)"
		putloglev d * \
			"$mc_dnsb(script): SVS Warning: Timed out connecting to $temp(1)."
		catch {unset mc_dnsb($array)}
		close $sid
		return 0
	}
	if {[eof $sid]} {
		catch {unset mc_dnsb($array)}
		close $sid
		return 1
	}
	gets $sid get
	after cancel $tout
	if {![info exist mc_dnsb($array)]} {
		if {$get == ""} {set mc_dnsb($array) 1}
		return -1
	}
	if {($get == "") || [catch {llength $get}]} {
		return -2
	}
	switch -- [lindex $get 0] {
		003 {
			set temp(reply) [lrange $get 1 end]
			set temp(reply:0) [lindex $temp(reply) 0]
			set temp(reply:1) [lindex $temp(reply) 1]
			set temp(reply:2) [lindex $temp(reply) 2]
			set temp(reply:3) [lindex $temp(reply) 3]
			set temp(reply:4) [lindex $temp(reply) 4]
			set temp(reply:5) [lindex $temp(reply) 5]
			if {$temp(reply:0) != $mc_dnsb(svs:script)} {
				set temp(1) "wanted $mc_dnsb(svs:script), got $temp(reply:0)"
				putloglev d * "$mc_dnsb(script): SVS Error: $temp(1)"
				unset mc_dnsb($array)
				close $sid
				return -3
			}
			if {$mc_dnsb(svs:mode)} {
				set temp(svs:version) [string range $mc_dnsb(svs:version) 0 8]999
			} else {
				set temp(svs:version) [string range $mc_dnsb(svs:version) 0 11]
			}
			if {$temp(reply:1) > $temp(svs:version)} {
				set temp(note) $temp(reply:5)
				regsub -all -- %0 $temp(note) $temp(reply:0) temp(note)
				regsub -all -- %1 $temp(note) $temp(reply:1) temp(note)
				regsub -all -- %2 $temp(note) $temp(reply:2) temp(note)
				regsub -all -- %3 $temp(note) $temp(reply:3) temp(note)
				regsub -all -- %4 $temp(note) $temp(reply:4) temp(note)
				regsub -all -- %version $temp(note) $mc_dnsb(version) temp(note)
				foreach temp(to) [split $mc_dnsb(svs:notify) ",; "] {
					if {[string trim $temp(to)] == ""} {continue}
					regsub -- %nick $temp(note) $temp(to) temp(note2)
					set temp(lunotes) [notes $temp(to) -[notes $temp(to)]]]
					if {[string match *$temp(note2)* $temp(lunotes)]} {
						set temp(found_note) 0
						foreach temp(unote) $temp(lunotes) {
							if {$temp(note2) == [lindex $temp(unote) 2]} {
								set temp(found_note) 1
								break
							}
						}
						if {$temp(found_note)} {continue}
					}
					set temp(error) "sending note to $temp(to) -> "
					switch -- [sendnote SVS $temp(to) $temp(note2)] {
						0 {
							if {![validuser $temp(to)]} {
								append temp(error) "invalid user"
							} else {append temp(error) "unknown error"}
							putloglev d * \
								"$mc_dnsb(script): SVS sendnote error: $temp(error)"
						}
						3 {
							append temp(error) "notebox too full"
							putloglev d * \
								"$mc_dnsb(script): SVS sendnote error: $temp(error)"
						}
					}
				}
			}
			unset mc_dnsb($array)
			close $sid
			return 2
		}
	}
}
## ^

putlog "$mc_dnsb(script) $mc_dnsb(version) by MC_8 loaded."

##
# History  ( <Fixed by> - [Found by] - <Info> )
##
# v1.2 (02.14.02)
#  MC_8 -        - Upgraded `chanflag` proc.  v2.0 -> v3.0
#  MC_8 -        - Upgraded `masktype` proc.  v1.0 -> v1.3
#  MC_8 -        - Upgraded SVS Client.  v2.0 -> v3.0
#  MC_8 -        - Added Error Catching System.  none -> v2.1.1
#  MC_8 - Randy  - Fixed '[mc:dnsb:join]: list element in braces followed by "b133d"
#                  instead of space'.
#                  Bugzilla bug: 57
#  MC_8 -        - Fixed 'Tcl error [mc:dnsb:dnsreturn]: can't read
#                  "mc_dnsb(isban)": no such variable'.
#                  Bugzilla bug: 43
#  MC_8 -        - Upgraded `chanflag` proc.  v1.0 -> v2.0
#  MC_8 -        - Removed the time binding.  I don't think we need this; if someone
#                  adds a ban on the fly, I'm pretty sure there gonna enter the
#                  correct ban.  The time binding only checked excessive situations
#                  that rarly happened, and took up cpu time in doing so.
#  MC_8 -        - Recoded join/ mode/ dnsreturn proc, more effecent/faster.
#  MC_8 -        - Added `exempt:op` and `exempt:voice` settings.
#  MC_8 -        - Changed how it detects the dns module, more effecent.
#  MC_8 - Niklas - Fixed 'invalid command name "mc:dnbs:time"', bot crash.
#                  Bugzilla bug: 40
#
# v1.1 (11.14.01)
#  MC_8 - - Upgraded SVS Client.  v1.2 -> v2.0.
#  MC_8 - - Added a time bind.  If I cannot detect .+ban's over a sharenet then I'll
#           just scan the channel once every 10 min's.
#  MC_8 - - Added mc.dnsbans channel flag.
#  MC_8 - - Removed unused replace, findip, filt, unfilt and findchanuser proc.
#  MC_8 - - Updated the masktype and chanflag proc.
#  MC_8 - - Rewrote the procs a bit to make it run a little more effecent.
#
# v1.0 (03.17.01)
#  MC_8 - KatzEye - Fixed, `Tcl error [mc:dnsb:dnsreturn]: invalid command name
#                   "???"`.
#  MC_8 -         - Inital Release
##
