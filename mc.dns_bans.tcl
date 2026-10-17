##
# DNS Bans v1.0 by MC_8 - Carl M. Gregory <gregory@worldinter.net>
#
# If you have any questions/comments/idea's, please email me!
# ( Include the script name and version in the title, if you do email me. )
#
# My SVS Website - http://mc.purehype.net/
##

##
# This script will DNS channel users hostname/ip and evaluate to see if there
# in the banlist.  Example:  Say you ban 24.72.12.*, and someone enters the
# channel with a hostname of poached.eggheads.org.  poached.eggheads.org's
# DNS entry is 24.72.12.134, so the user would be considered ban'd and treated
# as such.  Same in reverse (ban 24.72.12.* would ban poached.eggheads.org).
##

##
# History
##
# v1.0 (03.17.01)
#  MC_8 - KatzEye - Fixed, `Tcl error [mc:dnsb:dnsreturn]: invalid command name "???"`.
#  MC_8 - Inital Release, in beta coding
##

##
# Settings
##

# What flaged users should never be reverse looked up to be banned by this script?
# In other words, what flaged users are exempt from bans?  Set this to "-|-" to
# have no one exempt.
#  Flag syntax is:  <global>|<channel>
set mc_dnsb(ign) "mnto|mnto"

# If a user is found to match a ban, reversed in DNS (ip <> host), what
# banmask would you like the script to ban?
#
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
#     You can also specify a type of 10 to 19 which correspond to masks 0 to 9, but
#     instead of using a * wildcard to replace portions of the host.domain, it uses ?
#     wildcards to replace the numbers in the address.
set mc_dnsb(banmask) 13

## MC SVS (Script Version Server) v1.2 ##
# Do you want the bot to connection to MC_8's SVS to see if there are newer versions
# of this script avilable?  It will only tell you -- It's up to you to get the newest
# version (I decided not to auto update the code, there may be new features in the
# newest script that may require your attention).
# 0=no/1=yes
set mc_dnsb(svs:enabled) 1

# Once a day the script will check with the SVS -- this specifies when
# that should happen.  The setting should be the hour (military).
# examples:
#  set mc_dnsb(svs:check) 0  ;#This is at Midnight
#  set mc_dnsb(svs:check) 5  ;#This is at 5am
#  set mc_dnsb(svs:check) 13  ;#This is at 1pm
#  set mc_dnsb(svs:check) 23  ;#This is at 11pm
set mc_dnsb(svs:check) 3

# Upon finding a newer version, who do you want to notify via note?
# Only the admin of the bot should really be worried about these notes,
# there the ones that keep everything up to par on the bots.
# Seperate each user with a " " (space).
set mc_dnsb(svs:notify) "MC_8"

# Do you want even beta version notified to whomever you have set?  Or just
# stable releases of the script?
#  0 = Tell me about all version, even beta versions.
#  1 = Just tell me about new stable versions.
set mc_dnsb(svs:stableonly) 0



## Coding starts here, please do not proceed in editing past this point.

set mc_dnsb(version) v1.0
set mc_dnsb(svs:script) "dnsbans 001000000000"
set mc_dnsb(svs:server) "mc.purehype.net 8085"

if {$numversion < "1050100"} {
 putlog "DNS Bans $mc_dnsb(version) by MC_8 is for eggdrop 1.5.1+ only."
 putlog "DNS Bans $mc_dnsb(version) will not work with eggdrop $version."
 putlog "DNS Bans $mc_dnsb(version) not loaded."
 return 1
};set temp 0
foreach mod [modules] {if {[lindex $mod 0] == "dns"} {set temp 1;break}}
if {!$temp} {
 if {[catch {loadmodule dns} error]} {
  putlog "DNS Bans $mc_dnsb(version) by MC_8 requires the DNS module."
  putlog "DNS Bans $mc_dnsb(version) did not find the DNS module loaded and failed when trying to auto load it."
  putlog "When trying to load DNS module:"
  putlog " $error"
  putlog "DNS Bans $mc_dnsb(version) not loaded."
  return 1
 }
}

bind join - * mc:dnsb:join
proc mc:dnsb:join {nick uhost hand chan} {
 global mc_dnsb botnick
 if {([matchattr $hand $mc_dnsb(ign) $chan]) &&
     ($mc_dnsb(ign) != "-|-")} {return 0}
 if {$nick == $botnick} {
  foreach nick [chanlist $chan] {
   set uhost [getchanhost $nick $chan]
   set host [string range $uhost [expr [string first @ $uhost]+1] e]
   set ident [string range $uhost 0 [expr [string first @ $uhost]-1]]
   set hand [nick2hand $nick]
   dnslookup $host mc:dnsb:dnsreturn $host [mc:dnsb:filt $nick] $ident [mc:dnsb:filt $hand] [mc:dnsb:filt $chan] 0
  }
 } {
  set host [string range $uhost [expr [string first @ $uhost]+1] e]
  set ident [string range $uhost 0 [expr [string first @ $uhost]-1]]
  dnslookup $host mc:dnsb:dnsreturn $host [mc:dnsb:filt $nick] $ident [mc:dnsb:filt $hand] [mc:dnsb:filt $chan] 0
 }
}

bind mode - "% +b" mc:dnsb:mode
proc mc:dnsb:mode {nick uhost hand chan mc {victim ""}} {
 global mc_dnsb botnick
 if {[info exists mc_dnsb(!ign:$victim:$chan)]} {
  unset mc_dnsb(!ign:$victim:$chan)
  return 0
 }
 set nick [chanlist $chan]
 foreach foundnick $nick {
  set hand [nick2hand $foundnick $chan]
  if {([matchattr $hand $mc_dnsb(ign) $chan]) &&
      ($mc_dnsb(ign) != "-|-") || ($foundnick == $botnick)} {continue}
  set uhost [getchanhost $foundnick $chan]
  set host [string range $uhost [expr [string first @ $uhost]+1] e]
  set ident [string range $uhost 0 [expr [string first @ $uhost]-1]]
  set band "$victim $nick 00"
  dnslookup $host mc:dnsb:dnsreturn $host [mc:dnsb:filt $foundnick] $ident [mc:dnsb:filt $hand] [mc:dnsb:filt $chan] "{$band}"
 }
}

proc mc:dnsb:dnsreturn {ip host status eval nick ident hand chan band} {
 global mc_dnsb
 if {(!$status) || (![onchan $nick $chan])} {return 0}
 if {$ip == $eval} {
  set nuhost $nick!$ident@$host
  set banhost $nick!$ident@$ip
 } {
  set nuhost $nick!$ident@$ip
  set banhost $nick!$ident@$host
 }
 if {[isban $nuhost]} {
  set ban [mc:dnsb:masktype $banhost $mc_dnsb(banmask)]
  set banlist [banlist]
 } elseif {[isban $nuhost $chan]} {
  set ban [mc:dnsb:masktype $banhost $mc_dnsb(banmask)]
  set banlist [banlist $chan]
 } else {
  set isban 0
  foreach temp_ban "[chanbans $chan] {$band}" {
   if {![string match [lindex $temp_ban 0] $nuhost]} {continue}
   set ban [mc:dnsb:masktype $banhost $mc_dnsb(banmask)]
   if {[string match *!*@* [lindex $temp_ban 1]]} {
    set setby [string range [lindex $temp_ban 1] 0 [expr [string first ! [lindex $temp_ban 1]]-1]]
   } {set setby [string range [lindex $temp_ban 1] 0 e]}
   set banlist "";set isban 1;break
  };if {!$isban} {return 0}
 }
 putserv "MODE $chan +b $ban"
 if {[mc:dnsb:chanflagison $chan enforcebans]} {
  foreach banentry $banlist {
   if {[string match [lindex $banentry 0] $nuhost]} {
    putserv "KICK $chan $nick :[lindex $banentry 5]: [lindex $banentry 1]"
    break
   }
  };putserv "KICK $chan $nick :$setby: [lindex $band 0]"
 };set mc_dnsb(!ign:$ban:$chan) 1;utimer 10 "catch {unset mc_dnsb(!ign:[mc:dnsb:filt $ban:$chan])}"
}

## Masktype Procedure by MC_8
##
## ^h mc:dnsb -> mc:????
proc mc:dnsb:masktype {uhost type} {
 if {![string match "*!*@*.*" $uhost]} {
  set nick [lindex [split $uhost "!"] 0]
  if {$nick == ""} {
   set uhost [string range $uhost [expr [string first ! $uhost]+1] e]
   foreach chan [channels] {
    set nick [lindex [mc:dnsbans:findchanuser *$uhost* $chan] 0]
    if {$nick != ""} {break}
   }
   if {$nick == ""} {set uhost $nick!} {set uhost "$nick![gethost $nick]"}
  }
  if {$uhost == "$nick!" || $nothing} {set type "return_nothing"}
 }
 switch -exact $type {
  0 {set ban "*[string range $uhost [string first ! $uhost] e]"}
  1 {set ban "*!*[string trimleft [string range $uhost [expr [string first ! $uhost]+1] e] "~"]"}
  2 {set ban "*!*[string range $uhost [string first @ $uhost] e]"}
  3 {
   set ident [string range $uhost [expr [string first ! $uhost]+1] [expr [string last @ $uhost]-1]]
   set ban "*!*[string trimleft $ident "~"][string range [maskhost $uhost] [string first @ [maskhost $uhost]] e]"
  }
  4 {set ban "*!*[string range [maskhost $uhost] [string last "@" [maskhost $uhost]] e]"}
  5 {set ban $uhost}
  6 {
   set nick [string range $uhost 0 [expr [string first "!" $uhost]-1]]
   set ident [string range $uhost [expr [string first "!" $uhost]+1] [expr [string last "@" $uhost]-1]]
   set ban "$nick!*[string trimleft $ident "~"][string range $uhost [string last "@" $uhost] e]"
  }
  7 {
   set nick [string range $uhost 0 [expr [string first "!" $uhost]-1]]
   set ban "$nick!*[string range $uhost [string last "@" $uhost] e]"
  }
  8 {
   set nick [string range $uhost 0 [expr [string first "!" $uhost]-1]]
   set ident [string range $uhost [expr [string first "!" $uhost]+1] [expr [string last "@" $uhost]-1]]
   set ban "$nick!*[string trimleft $ident "~"][string range [maskhost $uhost] [string last "@" [maskhost $uhost]] e]"
  }
  9 {
   set nick [string range $uhost 0 [expr [string first "!" $uhost]-1]]
   set ban "$nick!*[string range [maskhost $uhost] [string last "@" [maskhost $uhost]] e]"
  }
  10 {
   set host [string range $uhost [string last "@" $uhost] e]
   if {[mc:dnsbans:findip [string range $host 1 e]] == "0"} {
    set host [mc:dnsbans:replace $host "1 ? 2 ? 3 ? 4 ? 5 ? 6 ? 7 ? 8 ? 9 ? 0 ?"]
    set ident [string range $uhost [expr [string first "!" $uhost]+1] [expr [string last "@" $uhost]-1]]
    set ban "*!$ident$host"
   } {set ban [mc:dnsb:masktype $uhost 0]}
  }
  11 {
   set host [string range $uhost [string last "@" $uhost] e]
   if {[mc:dnsbans:findip [string range $host 1 e]] == "0"} {
    set host [mc:dnsbans:replace $host "1 ? 2 ? 3 ? 4 ? 5 ? 6 ? 7 ? 8 ? 9 ? 0 ?"]
    set ident [string range $uhost [expr [string first "!" $uhost]+1] [expr [string last "@" $uhost]-1]]
    set ban "*!*[string trimleft $ident "~"]$host"
   } {set ban [mc:dnsb:masktype $uhost 1]}
  }
  12 {
   set host [string range $uhost [string last "@" $uhost] e]
   if {[mc:dnsbans:findip [string range $host 1 e]] == "0"} {
    set host [mc:dnsbans:replace $host "1 ? 2 ? 3 ? 4 ? 5 ? 6 ? 7 ? 8 ? 9 ? 0 ?"]
    set ban "*!*$host"
   } {set ban [mc:dnsb:masktype $uhost 2]}
  }
  13 {
   set host [string range $uhost [string last "@" $uhost] e]
   if {[mc:dnsbans:findip [string range $host 1 e]] == "0"} {set ban [mc:dnsb:masktype $uhost 11]} {set ban [mc:dnsb:masktype $uhost 3]}
  }
  14 {
   set host [string range $uhost [string last "@" $uhost] e]
   if {[mc:dnsbans:findip [string range $host 1 e]] == "0"} {set ban [mc:dnsb:masktype $uhost 12]} {set ban [mc:dnsb:masktype $uhost 4]}
  }
  15 {
   set host [string range $uhost [string last "@" $uhost] e]
   if {[mc:dnsbans:findip [string range $host 1 e]] == "0"} {
    set host [mc:dnsbans:replace $host "1 ? 2 ? 3 ? 4 ? 5 ? 6 ? 7 ? 8 ? 9 ? 0 ?"]
    set rest [string range $uhost 0 [expr [string last "@" $uhost]-1]]
    set ban $rest$host
   } {set ban [mc:dnsb:masktype $uhost 5]}
  }
  16 {
   set host [string range $uhost [string last "@" $uhost] e]
   if {[mc:dnsbans:findip [string range $host 1 e]] == "0"} {
    set host [mc:dnsbans:replace $host "1 ? 2 ? 3 ? 4 ? 5 ? 6 ? 7 ? 8 ? 9 ? 0 ?"]
    set rest "[string range $uhost 0 [expr [string first "!" $uhost]-1]]!*[string trimleft [string range $uhost [expr [string first "!" $uhost]+1] [expr [string last "@" $uhost]-1]] "~"]"
    set ban $rest$host
   } {set ban [mc:dnsb:masktype $uhost 6]}
  }
  17 {
   set host [string range $uhost [string last "@" $uhost] e]
   if {[mc:dnsbans:findip [string range $host 1 e]] == "0"} {
    set host [mc:dnsbans:replace $host "1 ? 2 ? 3 ? 4 ? 5 ? 6 ? 7 ? 8 ? 9 ? 0 ?"]
    set rest "[string range $uhost 0 [expr [string first "!" $uhost]-1]]!*"
    set ban $rest$host 
   } {set ban [mc:dnsb:masktype $uhost 7]}
  }
  18 {
   set host [string range $uhost [string last "@" $uhost] e]
   if {[mc:dnsbans:findip [string range $host 1 e]] == "0"} {set ban [mc:dnsb:masktype $uhost 16]} {set ban [mc:dnsb:masktype $uhost 8]}
  }
  19 {
   set host [string range $uhost [string last "@" $uhost] e]
   if {[mc:dnsbans:findip [string range $host 1 e]] == "0"} {set ban [mc:dnsb:masktype $uhost 17]} {set ban [mc:dnsb:masktype $uhost 9]}
  }
  return_nothing {set ban ""}
  default {set ban "*!*[string range $uhost [string first "@" $uhost] e]"}
 }
 set _nick [lindex [split $ban !] 0]
 set _ident [string range $ban [expr [string first ! $ban]+1] [expr [string last @ $ban]-1]]
 set _host [string range $ban [expr [string last @ $ban]+1] e]
 if {$_ident != [set temp [string range $_ident [expr [string length $_ident]-9] e]]} {
  set _ident *[string trimleft $temp *]
 }
 if {$_host != [set temp [string range $_host [expr [string length $_host]-63] e]]} {
  set _host *[string trimleft $temp *]
 } ; return $_nick!$_ident@$_host
}
proc mc:dnsbans:replace {string subs} {
 if {[llength $subs] == "1"} {set subs [lindex $subs 0]}
 for {set i 0} {[lindex $subs $i] != ""} {incr i 2} {
  regsub -all -- [lindex $subs $i] $string [lindex $subs [expr $i+1]] string
 } ; return $string
}
proc mc:dnsbans:findchanuser {hostmask channel} {
 if {![validchan $channel]} {return -code error "no such channel record"} ; set buffer ""
 set hostmask [string tolower $hostmask]
 foreach user [chanlist $channel] {
  if {[string match $hostmask [string tolower $user![getchanhost $user $channel]]]} {
   set buffer "$buffer $user"
  }
 } ; return [join [split $buffer] " "]
}
proc mc:dnsbans:findip {args} {
 catch {unset mc_found_ip}
 if {![string match *.*.*.* $args]} {return 0}
 foreach arg $args {
  if {[string match *.*.*.* $arg]} {
   set mc_testa [split $arg "."] ; set i 0
   while {[llength $mc_testa] != $i} {
    set mc_test [lrange $mc_testa $i end]
    if {[string length [lindex $mc_test 1]]<4 && [string length [lindex $mc_test 2]]<4} {
     if {[lindex $mc_test 1] < 256 && [lindex $mc_test 2] < 256 && [lindex $mc_test 1] >= 0 && [lindex $mc_test 2] >= 0} {
      set first "abcdefghi"
      if {[string index [lindex $mc_test 0] [expr [string length [lindex $mc_test 0]] - 1]] <= 9 && [string index [lindex $mc_test 0] [expr [string length [lindex $mc_test 0]] - 1]] >= 0} {
       set first [string range [lindex $mc_test 0] [expr [string length [lindex $mc_test 0]] - 1] end]
       if {[string index [lindex $mc_test 0] [expr [string length [lindex $mc_test 0]] - 2]] <= 9 && [string index [lindex $mc_test 0] [expr [string length [lindex $mc_test 0]] - 2]] >= 0} {
        set first [string range [lindex $mc_test 0] [expr [string length [lindex $mc_test 0]] - 2] end]
        if {[string index [lindex $mc_test 0] [expr [string length [lindex $mc_test 0]] - 3]] <= 9 && [string index [lindex $mc_test 0] [expr [string length [lindex $mc_test 0]] - 3]] >= 0} {
         set first [string range [lindex $mc_test 0] [expr [string length [lindex $mc_test 0]] - 3] end]
        }
       }
      }
      set second [lindex $mc_test 1] ; set third [lindex $mc_test 2] ; set fourth "abcdefghi"
      if {[string index [lindex $mc_test 3] 0] <= 9 && [string index [lindex $mc_test 3] 0] >= 0} {
       set fourth [string index [lindex $mc_test 3] 0]
       if {[string index [lindex $mc_test 3] 1] <= 9 && [string index [lindex $mc_test 3] 1] >= 0} {
        set fourth $fourth[string index [lindex $mc_test 3] 1]
        if {[string index [lindex $mc_test 3] 2] <= 9 && [string index [lindex $mc_test 3] 2] >= 0} {
         set fourth $fourth[string index [lindex $mc_test 3] 2]
        }
       }
      }
      if {($first < 256) && ($second < 256) && ($third < 256) &&
          ($fourth < 256) && ($first > 0) && ($second > 0) &&
          ($third > 0) && ($fourth > 0) && ([string index $first 0] > 0) &&
          ([string index $second 0] > 0) && ([string index $third 0] > 0) &&
          ([string index $fourth 0] > 0)} {
       if {[info exists mc_found_ip]} {
        set mc_found_ip "$mc_found_ip $first.$second.$third.$fourth"
       } {set mc_found_ip $first.$second.$third.$fourth}
      }
     }
    } ; incr i +1
   }
  }
 } ; if {[info exists mc_found_ip]} {return $mc_found_ip} {return 0}
}
## ^^

proc mc:dnsb:filt {data} {
 regsub -all -- \\\\ $data \\\\\\\\ data ; regsub -all -- \\\[ $data \\\\\[ data ; regsub -all -- \\\] $data \\\\\] data
 regsub -all -- \\\} $data \\\\\} data ; regsub -all -- \\\{ $data \\\\\{ data ; regsub -all -- \\\" $data \\\\\" data ; return $data
}

proc mc:dnsb:unfilt {data} {
 regsub -all -- \\\\\\\\ $data \\ data
 regsub -all -- \\\\\\\[ $data \[ data
 regsub -all -- \\\\\\\] $data \] data
 regsub -all -- \\\\\} $data \} data
 regsub -all -- \\\\\{ $data \{ data
 regsub -all -- \\\\\" $data \" data
 return $data
}

proc mc:dnsb:chanflagison {chan flag} {
 set chan [string tolower $chan]
 foreach info [channel info $chan] {
  if {[string tolower [string range $info 1 e]] == [string tolower $flag]} {
   if {[string index $info 0] == "-"} {
    return 0
   } elseif {[string index $info 0] == "+"} {
    return 1
   } else {return 0}
  }
 };return 0
}

if {$mc_dnsb(svs:enabled)} {
 if {($mc_dnsb(svs:check) > "23") || ($mc_dnsb(svs:check) < "0")} {set mc_dnsb(svs:check) 00}
 if {[string length $mc_dnsb(svs:check)] == "1"} {set mc_dnsb(svs:check) 0$mc_dnsb(svs:check)}
 if {$mc_dnsb(svs:stableonly)} {
  set mc_dnsb(svs:script) [string range $mc_dnsb(svs:script) 0 [expr [string length $mc_dnsb(svs:script)]-4]]999
 }
 catch {unbind time - "00 $mc_dnsb(svs:oldcheck) * * *" mc:dnsb:svs:time}
 set mc_dnsb(svs:oldcheck) $mc_dnsb(svs:check)
 bind time - "00 $mc_dnsb(svs:check) * * *" mc:dnsb:svs:time
 proc mc:dnsb:svs:time {min hour day month year} {
  global mc_dnsb
  catch {control [connect [lindex $mc_dnsb(svs:server) 0] [lindex $mc_dnsb(svs:server) 1]] mc:dnsb:svs:interface}
 }
}
proc mc:dnsb:svs:interface {idx args} {
 global mc_dnsb;set args [join $args]
 switch -- [lindex $args 0] {
  "" {return 1}
  000 {putdcc $idx q}
  002 {putdcc $idx [lindex $mc_dnsb(svs:script) 0]}
  003 {
   set args [lrange $args 1 e]
   if {[lindex $args 0] != [lindex $mc_dnsb(svs:script) 0]} {return 0}
   putdcc $idx q
   if {[lindex $args 1] > [lindex $mc_dnsb(svs:script) 1]} {
    set note [mc:dnsb:svs:replace [lindex $args 7] "%0 {[lindex $args 0]} %1 {[lindex $args 1]} %2 {[lindex $args 2]}"]
    set note [mc:dnsb:svs:replace $note "%3 {[lindex $args 3]} %4 {[lindex $args 4]} %5 {[lindex $args 5]}"]
    set note [mc:dnsb:svs:replace $note "%6 {[lindex $args 6]} %8 {[lindex $args 8]} %version {$mc_dnsb(version)}"]
    set note [mc:dnsb:svs:replace $note "%9 {[lindex $args 9]} %10 {[lindex $args 10]} %11 {[lindex $args 11]}"]
    set note [mc:dnsb:svs:replace $note "%12 {[lindex $args 12]} %13 {[lindex $args 13]} %14 {[lindex $args 14]}"]
    set note [mc:dnsb:svs:replace $note "%15 {[lindex $args 15]} %16 {[lindex $args 16]} %17 {[lindex $args 17]}"]
    set note [mc:dnsb:svs:replace $note "%18 {[lindex $args 18]} %19 {[lindex $args 19]} %20 {[lindex $args 20]}"]
    foreach notify [join [split $mc_dnsb(svs:notify) ",;"]] {
     set outnote [mc:dnsb:svs:replace $note "%nick {$notify}"]
     if {[string match "*$outnote*" "[notes $notify -[notes $notify]]"]} {
      set cont 0
      foreach unote [notes $notify -[notes $notify]] {
       if {$outnote == [lindex $unote 2]} {set cont 1;break}
      };if {$cont} {continue}
     }
     switch -- [sendnote SVS $notify $outnote] {
      0 {putlog "MC SVS for [lindex $mc_dnsb(svs:script) 0] had some errors updating $notify on current version of script; unknown reason!"}
      3 {putlog "MC SVS for [lindex $mc_dnsb(svs:script) 0] had some errors updating $notify on current version of script; notebox too full!"}
     }
    }
   }
  }
 };return 0
}
proc mc:dnsb:svs:replace {string subs} {
 if {[llength $subs] == "1"} {set subs [lindex $subs 0]}
 for {set i 0} {[lindex $subs $i] != ""} {incr i 2} {
  regsub -all -- [lindex $subs $i] $string [lindex $subs [expr $i+1]] string
 } ; return $string
}

putlog "DNS Bans $mc_dnsb(version) by MC_8 loaded."