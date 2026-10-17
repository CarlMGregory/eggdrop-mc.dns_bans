##
# DNS Bans v1.2.1
#  by MC_8 - Carl M. Gregory <mc8@purehype.net>
#  This script will only run on eggdrop 1.5.5 or greater.
#  This script requires the DNS Module.  If it isn't loaded when this script is
#    loaded, it will try to load it for you.
#
#    R.I.P. Mom, To always be remembered; Nancy Marie Gregory.
#
# My Website - http://mc.purehype.net:81/
# Have a bug?  http://mc.purehype.net:81/bugzilla/
##

##
# This script will DNS channel users hostname/ip and evaluate to see if there in the
# banlist, regardless of ip or hostname banning.
# Example:  Say you ban 24.72.12.*, and someone enters the channel with a hostname
#           of poached.eggheads.org.  poached.eggheads.org's DNS entry is
#           24.72.12.134, so the user would be considered banned and treated as such.
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

# What flagged users do you want to exempt?  Set this to "" to exempt no one.  Flag
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
#                  replacements as does hostname.
set mc_dnsb(banmask) 13


## SVS Client (Script Version Service) v3.0.1 ##
# Once a day, the SVS Client will connect to MC_8's SVS Server to determine if there
# is a newer version of this script available.  This will only notify users of the ne
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
set mc_dnsb(version)     "v1.2.1"
set mc_dnsb(svs:script)  "dnsbans"
set mc_dnsb(svs:version) "001002001000"
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


# Error system, v3.0
proc mc:dnsb:error {command error arg} {
	global mc_dnsb version lastbind errorInfo
	putlog "Error in script $mc_dnsb(script) $mc_dnsb(version)."
	putlog "    Error System: v3.0"
	putlog "       Last Bind: [expr {[info exists lastbind] ? $lastbind : "-NULL-"}]"
	putlog "         Command: $command"
	putlog "       Arguments: $arg"
	putlog "       Error Msg: $error"
	putlog "    Egg. Version: [expr {[info exists version] ? $version : "-NULL-"}]"
	putlog "     TCL Version: [info tclversion]"
	putlog "  TCL Patchlevel: [info patchlevel]"
	putlog "*** Please submit this bug so MC_8 can fix it.  Visit"
	putlog "*** http://mc.purehype.net:81/bugzilla/ to properly report the bug."
	putlog "*** Please include ALL info. in the bug report, including the next(s)."
	error $errorInfo
}

proc mc:dnsb:errchk {command arg} {
	if {![catch {eval $command $arg} return]} {return $return}
	mc:dnsb:error $command $return $arg
	return 0
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
		if {[regexp -- (.*)@(.*) [getchanhost $nick $chan] dummy ident host]} {
			dnslookup [list $host] mc:dnsb:dnsreturn \
				[list $host $nick $ident $hand $chan $cache(chanban)]
		}
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
	}; pushmode $chan +b [mc:dnsb:maskhostbytype $nick!$ident@$oh $mc_dnsb(banmask)]
}


## More Tools quick procs.
## -- http://mc.purehype.net:81/script_info.tcl?script=moretools

# badargs <args> <min_llength> <max_llength|end> <argNames>
#     version:
#       v1.0
proc mc:dnsb:badargs {{args ""}} {
	if {[llength $args] < 4} {
		error {
			wrong # args: should be "mc:dnsb:badargs args min_llength max_llength argNames"
		}
	}

	set index 0
	foreach varName [list args min max names] {
		set check_$varName [lindex $args $index]
		incr index
	}

	if {[regexp -- {([^0-9])} $check_min -> bad]} {
		error "bad number \"$bad\" in: $check_min"
	}
	if {[regexp -- {([^0-9])} $check_max -> bad] && ($check_max != "end")} {
		error "bad number \"$bad\" in: $check_max"
	}

	# Make sure $check_args is in list format, if not then make it so.
	# Were not going to use 2list here, don't want to evoke a 'too many nested calls
	# to Tcl_EvalObj' error since '2list' uses on this proc.
	if {[catch {llength $check_args} llength]} {
		set check_args [split $check_args]
		set llength $check_args
	}

	if {($llength < $check_min) || (($llength != "end") && ($llength > $check_max))} {
		if {[info level] == "1"} {return 1}
		error "wrong # args: should be \"[lindex [info level -1] 0] $check_names\""
	}; return 0
}

# unlist <argsList> [varName1] [varName2] ... [varNameN]
#     version:
#       v1.0
proc mc:dnsb:unlist {{args ""}} {
	mc:dnsb:badargs $args 1 end "argsList ?varName varName ...?"
	set argList [lindex $args 0]
	set argList [expr {([catch {llength $argList}])?[split $argList]:$argList}]
	set argNames [lrange $args 1 end]
	if {![llength $argNames]} {
		return [expr {(![catch {llength $argList}])?
			[join $argList]:$argList}]
	}
	for {set index 0} {$index < [llength $argNames]} {incr index 1} {
		set argName     [lindex $argNames $index]
		set argListItem [lindex $argList  $index]

		set argName_ [expr {([catch {llength $argName}])?[split $argName]:$argName}]
		set setTo   [lindex $argName_ 1]
		set argName [lindex $argName_ 0]

		if {$argName == ""} {continue}

		upvar 1 $argName var

		if {[expr $index+1] > [llength $argList]} {
			if {[llength $argName_] == "2"} {set var $setTo}
		} else {
			if {$argName == "args"} {
				set var [lrange $argList $index end]
				incr index [expr [llength $var]-1]
			} else {set var $argListItem}
		}
	}; return $index
}

# maskhostbytype <nick!ident@host.domain> [type]
#     version:
#       v2.0
proc mc:dnsb:maskhostbytype {{args ""}} {
	mc:dnsb:badargs $args 1 2 "nick!ident@host.domain ?type?"
	mc:dnsb:unlist $args nuhost type


	set type [expr {($type == "")?5:$type}]
	if {![regexp -- {^1?[0-9]$} $type]} {
		set valid "0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 {or 19}"
		error "bad type \"$type\": must be [join $valid ", "]"
	}

	# Define the maximum length the ircd allows for an ident.  Standard is 9, however I
	# made it to a variable incase someone wants to change it up.
	set ident_max-length 9

	# Define the maximum length the ircd allows for a hostname/ ip.  Standard is 63,
	# however I made it to a variable incase someone wants to change it up.
	set host_max-length 63

	if {![regexp -- {^(.*?)!((.*)@(.*))$} $nuhost -> nick uhost ident host]} {
		error "invalid nick!ident@host.domain: $nuhost"
	}

	set maskhost 1
	if {[string length $type] == "2"} {
		# Type must be 10-19.
		if {[info tclversion] < "8.1"} {
			set re_syntax_1 {([12][0-9][0-9]|[1-9][0-9]|[1-9])}
			set re_syntax_2 {([12][0-9][0-9]|[1-9][0-9]|[0-9])}
		} else {
			set re_syntax_1 {([12]\d{2}|[1-9][0-9]|[1-9])}
			set re_syntax_2 {([12]\d{2}|[1-9][0-9]|[0-9])}
		}
		set re_syntax ^$re_syntax_1\\.$re_syntax_2\\.$re_syntax_2\\.$re_syntax_2\$

		if {![regexp -- $re_syntax $host]} {
			regsub -all -- {[0-9]} $host ? host
			set maskhost 0
		}; set type [string index $type 1]
	}

	# Previous version used regexp instead of these string matches.  String match in
	# this case is ~3 microseconds faster.
	if {[string match {[0-4]} $type]} {set nick *}
	if {[string match {[2479]} $type]} {set ident *}
	if {[string match {[1368]} $type]} {regsub -- {^~?(.*)$} $ident *\\1 ident}
	if {[string match {[3489]} $type] && $maskhost} {
		set host [lindex [split [maskhost $host] @] end]
	}

	if {[set length [string length $ident]] > ${ident_max-length}} {
		set ident *[string range $ident [expr $length-${ident_max-length}] end]
	}
	if {[set length [string length $host]] > ${host_max-length}} {
		set host *[string range $host [expr $length-${host_max-length}] end]
	}

	return $nick!$ident@$host
}

# chanflag <channel> <flag>
#     version:
#       v3.1
proc mc:dnsb:chanflag {{args ""}} {
	mc:dnsb:badargs $args 2 2 "channel flag"
	mc:dnsb:unlist $args channel flag

	if {![validchan $channel]} {error "no such channel record"}

	# Try the 'channel' commands' 'get' option first, it's faster since it is written
	# in C by the eggdrop development team.
	if {![catch {channel get $channel $flag} output]} {return $output}

	set temp(chaninfo) [string tolower [channel info $channel]]
	if {[lsearch -exact $temp(chaninfo) +[string tolower $flag]] >= "0"} {return 1}
	return 0
}

## End of More Tools quick procs.


## SVS v3.0.1
set mc_dnsb(svs:client_version) "v3.0.1"
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
	global mc_dnsb tcl_platform
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
# v1.2.1 (09.20.02)
#  MC_8 - blood_x - Fixed 'invalid command name "mc:dnsb:maskhostbytype"'.
#                   Bugzilla number: 155
#  MC_8 -         - Upgraded SVS Client.  v3.0 -> v3.0.1
#  MC_8 -         - Fixed 10 spelling errors.
#  MC_8 -         - Added `unlist` tcl command.  none -> v1.0
#  MC_8 -         - Added `badargs` tcl command.  none -> v1.0
#  MC_8 -         - Upgraded `chanflag` tcl command.  v3.0 -> v3.1
#  MC_8 -         - Upgraded `masktype` tcl command, changed name to
#                   `maskhostbytype`.  v1.3 -> v2.0
#  MC_8 -         - Upgraded Error Catching System.  v2.1.1 -> v3.0
#  MC_8 - blood_x - Fixed 'can't read "host": no such variable'.
#                   Bugzilla number: 139
#
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
#                  adds a ban on the fly, I'm pretty sure there going to enter the
#                  correct ban.  The time binding only checked excessive situations
#                  that rarely happened, and took up cpu time in doing so.
#  MC_8 -        - Recoded join/ mode/ dnsreturn proc, more efficient/faster.
#  MC_8 -        - Added `exempt:op` and `exempt:voice` settings.
#  MC_8 -        - Changed how it detects the dns module, more efficient.
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
#  MC_8 - - Rewrote the procs a bit to make it run a little more efficient.
#
# v1.0 (03.17.01)
#  MC_8 - KatzEye - Fixed, `Tcl error [mc:dnsb:dnsreturn]: invalid command name
#                   "???"`.
#  MC_8 -         - Inital Release
##
