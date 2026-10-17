##
# DNS Bans v1.1 by MC_8 - Carl M. Gregory <mc8@purehype.net>
#  This script will only work on eggdrop 1.5.5 or greater.
#
# My SVS Website - http://mc.purehype.net:81/
##

##
# This script will DNS channel users hostname/ip and evaluate to see if there
# in the banlist.  Example:  Say you ban 24.72.12.*, and someone enters the
# channel with a hostname of poached.eggheads.org.  poached.eggheads.org's
# DNS entry is 24.72.12.134, so the user would be considered ban'd and treated
# as such.  Same in reverse (ban *.eggheads.org would ban 24.72.12.134).
##

##
# History
##
# v1.1 (11.14.01)
#  MC_8 - Upgraded SVS from v1.2 to v2.0.
#  MC_8 - Added a time bind.  If I cannot detect .+ban's over a sharenet then
#         I'll just scan the channel once every 10 min's.
#  MC_8 - Added mc.dnsbans channel flag.
#  MC_8 - Removed unused replace, findip, filt, unfilt and findchanuser proc.
#  MC_8 - Updated the masktype and chanflag proc.
#  MC_8 - Rewrote the procs a big to make it run a little more effecent.
#
# v1.0 (03.17.01)
#  MC_8 - KatzEye - Fixed, `Tcl error [mc:dnsb:dnsreturn]: invalid 
#                   command name "???"`.
#  MC_8 - Inital Release
##

##
# Settings
##

# Note:
#  There is one setting you set from dcc chat with the bot using .chanset.
#   <+/->mc.dnsbans  Setting this to +mc.dnsban on the specific channel
#                    will enable the channel to to use this script.
#
#  Example from dcc chat with the bot:
#   .chanset #channel +mc.dnsbans


# What flaged users are exempt from ban reversing?  Set this to "" to
# exempt no one.
#  Flag syntax is:  <global>|<channel>
set mc_dnsb(ign) "ob|o"

# If a user is found to match a ban, reversed in DNS (ip <> host), what
# banmask would you like the script to ban?
#      0 - *!user@host.domain
#      1 - *!*user@host.domain
#      2 - *!*@host.domain
#      3 - *!*user@*.domain
#      4 - *!*@*.domain
#      5 - nick!user@host.domain (utterly useless, just returns <hostmask>)
#      6 - nick!*user@host.domain
#      7 - nick!*@host.domain
#      8 - nick!*user@*.domain
#      9 - nick!*@*.domain
#     You can also specify a type of 10 to 19 which correspond to masks 0 
#     to 9.  But if the host.domain is a;
#       hostname = Instead of using a * wildcard to replace portions of the
#                  host.domain, it replaces the numbers in the host.domain 
#                  with a '?' (question mark) wildcard
#       ip       = It will mask as normal, with no '?' (question mark)
#                  replacments as does hostname.
set mc_dnsb(banmask) 13


## MC SVS (Script Version Service) v2.0 ##
# Do you want the bot to connection to MC_8's SVS to see if there are newer versions
# of this script avilable?  It will only tell you -- It's up to you to get the newest
# version (I decided not to auto update the code, there may be new features in the
# newest script that may require your attention).
# 0=no/1=yes
set mc_dnsb(svs:enabled) 1

# Once a day the script will check with the SVS -- this specifies when
# that should happen.  The setting should be the hour (military).
# examples:
#  set mc_dnsb(svs:check) 0   ;#This is at Midnight
#  set mc_dnsb(svs:check) 5   ;#This is at 5am
#  set mc_dnsb(svs:check) 13  ;#This is at 1pm
#  set mc_dnsb(svs:check) 23  ;#This is at 11pm
set mc_dnsb(svs:check) 3

# Upon finding a newer version of this script, who do you want this script
# to send a note to telling them of this newer version?
# If more than 1 user is to be notified, seperate each user with a
# ' ' (space).
set mc_dnsb(svs:notify) "MC_8"

# Do you want even beta version notified to whomever you have set?  Or just
# stable releases of the script?
#  0 = Tell me about all version, even beta versions.
#  1 = Just tell me about new stable versions.
set mc_dnsb(svs:stableonly) 0




## Coding starts here, please do not proceed in editing past this point.

set mc_dnsb(script)      "DNS Bans"
set mc_dnsb(version)     "v1.1"
set mc_dnsb(svs:script)  "dnsbans"
set mc_dnsb(svs:version) "001001000000"
set mc_dnsb(svs:server)  "mc.purehype.net"
set mc_dnsb(svs:port)    "81"
set mc_dnsb(svs:get)     "/"
set mc_dnsb(svs:query)   "svs=$mc_dnsb(svs:script)&version=$mc_dnsb(svs:version)"

if {$numversion < "1050500"} {
 putlog "$mc_dnsb(script) $mc_dnsb(version) by MC_8 will only work on eggdrop 1.5.5 or greater."
 putlog "$mc_dnsb(script) $mc_dnsb(version)  will not work with eggdrop $version."
 putlog "$mc_dnsb(script) $mc_dnsb(version)  not loaded."
 return 1
}

setudef flag mc.dnsbans; set temp 0

foreach mod [modules] {if {[lindex $mod 0] == "dns"} {set temp 1;break}}
if {!$temp} {
 if {[catch {loadmodule dns} error]} {
  putlog "$mc_dnsb(script) $mc_dnsb(version) by MC_8 requires the DNS module."
  putlog "$mc_dnsb(script) $mc_dnsb(version) did not find the DNS module loaded and failed when trying to auto load it."
  putlog "   When trying to load DNS module:"
  putlog "     $error"
  putlog "$mc_dnsb(script) $mc_dnsb(version) not loaded."
  return 1
 }
}

bind join - * mc:dnsb:join
proc mc:dnsb:join {nick uhost hand chan} {
 global mc_dnsb botnick
 if {![mc:dnsb:chanflag $chan mc.dnsbans]} {return 0}
 scan $uhost {%[^@]@%s} ident host
 if {[string tolower $nick] == [string tolower $botnick]} {
  foreach nick [chanlist $chan] {
   set hand [nick2hand $nick]
   if {([matchattr $hand $mc_dnsb(ign) $chan]) && ($mc_dnsb(ign) != "")} {continue}
   scan [getchanhost $nick $chan] {%[^@]@%s} ident host
   dnslookup [list $host] mc:dnsb:dnsreturn [list $host] [list $nick] [list $ident] [list $hand] [list $chan]
  }; return 1
 }
 if {([matchattr $hand $mc_dnsb(ign) $chan]) && ($mc_dnsb(ign) != "")} {return 0}
 dnslookup [list $host] mc:dnsb:dnsreturn [list $host] [list $nick] [list $ident] [list $hand] [list $chan]
}

bind mode - "% +b" mc:dnsb:mode
proc mc:dnsb:mode {nick uhost hand chan mc {victim ""}} {
 if {![mc:dnsb:chanflag $chan mc.dnsbans]} {return 0}
 global mc_dnsb
 foreach nick [chanlist $chan] {
  set hand [nick2hand $nick]
  if {([matchattr $hand $mc_dnsb(ign) $chan]) && ($mc_dnsb(ign) != "")} {continue}
  scan [getchanhost $nick $chan] {%[^@]@%s} ident host
  if {$nick == ""} {set nick $uhost}
  dnslookup [list $host] mc:dnsb:dnsreturn [list $host] [list $nick] [list $ident] [list $hand] [list $chan] "{[list $victim $nick]}"
 }; return 1
}

proc mc:dnsb:dnsreturn {ip host status eval nick ident hand chan {addition ""}} {
 global mc_dnsb botnick
 if {(!$status) || (![onchan $nick $chan]) || (![isop $botnick $chan]) ||
     (![mc:dnsb:chanflag $chan mc.dnsbans])} {return 0}
 if {$ip == $eval} {set host $ip; set rhost $host} \
 else {set host $host; set rhost $ip}
 set banmask [mc:dnsb:masktype $nick!$ident@$host $mc_dnsb(banmask)]
 set isban 0
 foreach ban "[banlist] [banlist $chan]" {
  if {[string match [string tolower [lindex $ban 0]] [string tolower $nick!$ident@$rhost]]} {
   set reason [lindex $ban 1]; set isban 1; break
  }
 }
 if {!$isban} {
  set isban 0
  foreach ban "$addition [chanbans $chan]" {
   if {![string match [string tolower [lindex $ban 0]] [string tolower $nick!$ident@$rhost]]} {continue}
   scan [lindex $ban 1] {%[^!]} setby
   set reason ""; set isban 1; break
  };if {!$isban} {return 0}
 }
 putserv "MODE $chan +b $banmask"
 if {[mc:dnsb:chanflag $chan enforcebans]} {
  if {$reason == ""} {set x ""} else {set x " :$reason"}
  putserv "KICK $chan $nick$x"
 }
}

bind time - "?0 *" mc:dnsb:time
proc mc:dnsb:time {{args ""}} {
 global server botnick
 if {$server != ""} {
  foreach channel [channels] {
   mc:dnsb:join $botnick [getchanhost $botnick $channel] [nick2hand $botnick $channel] $channel
  }
 }
}; mc:dnbs:time

proc mc:dnsb:masktype {hostmask type} {
 set ident_max-length 9
 set host_max-length 63
 scan $hostmask {%[^!]!%[^@]@%s} nick ident host
 set maskhost 1
 if {[regexp -- {^1[0-9]$} $type]} {
  if {!([regexp -- {^([0-9][0-9]?[0-9]?)\.([0-9][0-9]?[0-9]?)\.([0-9][0-9]?[0-9]?)\.([0-9][0-9]?[0-9]?)$} $host temp a b c d] && ($a > 0 && $a < 255 && $b < 255 && $c < 255 && $d < 255))} {
   regsub -all {[0-9]} $host "?" host
   set maskhost 0
  };set type [string index $type 1]
 }
 if {[regexp -- {^[0-4]$} $type]} {set nick "*"}
 if {[regexp -- {^[2479]$} $type]} {set ident "*"}
 if {[regexp -- {^[1368]$} $type]} {set ident "*[string trimleft $ident ~]"}
 if {[regexp -- {^[3489]$} $type]} {if {$maskhost} {scan [maskhost $host] {%[^@]@%s} temp host}}
 if {[string length $ident] > ${ident_max-length}} {
  set ident "*[string range $ident [expr [string length $ident]-${ident_max-length}] end]"
 }
 if {[string length $host] > ${host_max-length}} {
  set host "*[string range $host [expr [string length $host]-${host_max-length}] end]"
 }; return [format "%s!%s@%s" $nick $ident $host]
}

proc mc:dnsb:chanflag {channel flag} {
 if {![validchan $channel]} {return -code error "no such channel record"}
 set list [channel info $channel]
 for {set i 0} {![regexp -- {^[0-9]*:[0-9]*$} [lindex $list $i]]} {incr i} {}
 for {} {[regexp -- {^[0-9]*:[0-9]*$} [lindex $list $i]]} {incr i} {}
 set list [lrange $list $i end]
 foreach info [string tolower $list] {
  if {[string range $info 1 end] != [string tolower $flag]} {continue}
  if {[string index $info 0] == "-"} {
   return 0
  } elseif {[string index $info 0] == "+"} {return 1} else {return 2}
 };return -1
}

## SVS v2.0
if {(![info exists mc_dnsb(svs:enabled)]) ||
    (![regexp -- {^(0|1)$} $mc_dnsb(svs:enabled)])} {set mc_dnsb(svs:enabled) 0}
if {(![info exists mc_dnsb(svs:check)]) ||
    ([regexp -- {[^0-9]} $mc_dnsb(svs:check)])} {set mc_dnsb(svs:check) 0}
if {![info exists mc_dnsb(svs:notify)]} {set mc_dnsb(svs:notify) $owner}
if {(![info exists mc_dnsb(svs:stableonly)]) ||
    (![regexp -- {^(0|1)$} $mc_dnsb(svs:stableonly)])} {set mc_dnsb(svs:stableonly) 0}
foreach bind [binds mc:dnsb:svs:time] {
 unbind [lindex $bind 0] [lindex $bind 1] [lindex $bind 2] [lindex $bind 4]
}
foreach command [info commands mc:dnsb:svs:time] {rename $command ""}
if {$mc_dnsb(svs:enabled)} {
 if {($mc_dnsb(svs:check) > "23") || ($mc_dnsb(svs:check) < "0")} {set mc_dnsb(svs:check) 00}
 if {[string length $mc_dnsb(svs:check)] == "1"} {set mc_dnsb(svs:check) 0$mc_dnsb(svs:check)}
 bind time - "00 $mc_dnsb(svs:check) *" mc:dnsb:svs:time
 proc mc:dnsb:svs:time {{args ""}} {
  global mc_dnsb
  if {[catch {socket -async $mc_dnsb(svs:server) $mc_dnsb(svs:port)} sid]} {;\
   putlog "SVS Error\[$mc_dnsb(svs:script)/$mc_dnsb(svs:version)\]:  $sid"
   return 1
  }
  fconfigure $sid -blocking 0 -buffering line
  set tout [after 60000 "mc:dnsb:svs:interface $sid timeout"]
  fileevent $sid readable "mc:dnsb:svs:interface $sid $tout"
  puts $sid "GET $mc_dnsb(svs:get)?$mc_dnsb(svs:query) HTTP/1.0\
           \nHost: $mc_dnsb(svs:server)\n"
  flush $sid
 }
}
proc mc:dnsb:svs:interface {sid tout} {
 global mc_dnsb
 if {$tout == "timeout"} {
  putlog "SVS Warning\[$mc_dnsb(svs:script)/$mc_dnsb(svs:version)\]:  SVS Server timed out."
  close $sid
  return 0
 }; after cancel $tout
 set temp 0
 while {![eof $sid]} {
  gets $sid get
  if {$temp < "2"} {
   if {$get == ""} {incr temp; if {$temp == "1"} {set temp 2}}
   continue
  }; if {$get == ""} {continue}
  switch -- [lindex $get 0] {
   003 {
    set reply [lrange $get 1 end]
    if {[lindex $reply 0] != $mc_dnsb(svs:script)} {
     putlog "SVS Error\[$mc_dnsb(svs:script)/$mc_dnsb(svs:version)\]:  SVS Server sent wrong info, got [lindex $reply 0]"
     break   
    }
    if {$mc_dnsb(svs:stableonly)} {
     set temp [string range $mc_dnsb(svs:version) 0 8]999
    } else {set temp [string range $mc_dnsb(svs:version) 0 11]}
    if {[lindex $reply 1] > $temp} {
     set note [lindex $reply 5]
     regsub -- %0 $note [lindex $reply 0] note
     regsub -- %1 $note [lindex $reply 1] note
     regsub -- %2 $note [lindex $reply 2] note
     regsub -- %3 $note [lindex $reply 3] note
     regsub -- %4 $note [lindex $reply 4] note
     regsub -- %version $note $mc_dnsb(version) note
     foreach to [split $mc_dnsb(svs:notify) ",; "] {
      if {$to == ""} {continue}
      regsub -- %nick $note $to outnote
      if {[string match *$outnote* [set unotes [notes $to -[notes $to]]]]} {
       set temp 0
       foreach unote $unotes {
        if {$outnote == [lindex $unote 2]} {set temp 1; break}
       }; if {$temp} {continue}
      }
      switch -- [sendnote SVS $to $outnote] {
       0 {
        if {![validuser $notify]} {set x "invalid user"} else {set x "unknown error"}
        putlog "SVS Error\[$mc_dnsb(svs:script)/$mc_dnsb(svs:version)\]:  Trying to send note to $to, $x."
       }
       3 {putlog "SVS Error\[$mc_dnsb(svs:script)/$mc_dnsb(svs:version)\]:  Trying to send note to $to, notebox too full!"}
      }
     }
    }
   }
  }
 }; close $sid
}
## ^

putlog "$mc_dnsb(script) $mc_dnsb(version) by MC_8 loaded."
