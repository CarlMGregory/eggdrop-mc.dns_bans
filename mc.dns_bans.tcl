##
# DNS Bans v1.3.1
#  by MC_8 - Carl M. Gregory <mc8@purehype.net>
#  This script will only run on eggdrop 1.6.14 or greater.
#  This script requires the DNS Module.
#
#    R.I.P. Mom, To always be remembered; Nancy Marie Gregory.
#
# My Website - http://mc.purehype.net/
# Have a bug?  http://mc.purehype.net/bugzilla/
##

##
# This script will DNS channel users hostname/ip and evaluate to see if there in
# the banlist, regardless of ip or hostname banning.
# Example:  Say you ban 24.72.12.*, and someone enters the channel with a
#           hostname of poached.eggheads.org.  poached.eggheads.org's DNS entry
#           is 24.72.12.134, so the user would be considered banned and treated
#           as such.  Same in reverse (ban *.eggheads.org would ban
#           24.72.12.134).
##

##
# Commands (dcc)
##
# chanset <channel> <+/->mc.dns_bans
#   This will enable (+) or disable (-) the script for the specified channel.
#   Default, disabled (-).
#
# chanset <channel> <+/->mc.dns_bans.exempt.op
#   This will enable (+) or disable (-) physical op exemption for this script in
#   the specified channel.
#   Default, disabled (-).
#
# chanset <channel> <+/->mc.dns_bans.exempt.voice
#   This will enable (+) or disable (-) physical voice exemption for this script
#   in the specified channel.
#   Default, disabled (-).
#
# chanset <channel> mc.dns_bans.exempt.flags [attr]
#   This will exempt those fitting the flag attributes.  For a proper listing of
#   the flag attribute structure, see '.help match' in dcc console with your bot
#   (same attr system).  Leave attr blank to exempt no one.
#   Default, attr is blank (exempt no one).
#
# chanset <channel> <+/->mc.dns_bans.enforcebans
#   If this is enabled (+), the script will ban those matching a dns'd ban.
#   This is just like eggdrop's core +/-enforcebans, actually that one is looked
#   at as well.  But Postino requested such a flag so he can disable enforcebans
#   but enable mc.dns_bans.enforcebans.  mc.dns_bans.enforcebans only works for
#   this script, unlike core enforcebans.  Keep in mind, if
#   mc.dns_bans.enforcebans is disabled, but enforcebans is enabled -- it will
#   enforce bans.  The script works under an mc.dns_bans.enforcebans or
#   enforcebans clause.
#   Default, disabled (-).
##

##
# Configuration
##
#

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
set mc_dnsb(:config:banmask) 2

## SVS Client (Script Version Service) v4.0.4 ##
# Once a day, the SVS Client will connect to MC_8's SVS Server to determine if
# there is a newer version of this script available.  If a newer version is
# found, the script will be auto updated.

# [0=no/1=yes] Do you want to enable auto updating?  If you chose to disable
# auto updating, it will not automatically update the script upon finding a
# newer version.
set mc_dnsb(:config:svs:enable) 1

#
##

##
# Done with configurations, do not edit past here unless you know TCL.
##
#

#Script:dnsb

## SVS insert (pre code)
catch {unset temp}
set mc_dnsb(info:vars) ""
foreach {temp(name) temp(value)} [array get mc_dnsb :config:*] {
  lappend mc_dnsb(info:vars) [list $temp(name) $temp(value)]
}
set mc_dnsb(info:loc) [info script]
array set mc_dnsb [list \
  script                 "DNS Bans" \
  version                "v1.3.1" \
  svs:script             "dnsbans" \
  svs:version            "001003001000" \
  svs:client_version     "v4.0.4" \
  svs:client_svs_version "004000004000" \
  svs:server             "mc.svs.purehype.net" \
  svs:port               "80" \
  svs:get                "/index.tcl"]
set mc_dnsb(svs:query)    "svs=$mc_dnsb(svs:script)&"
append mc_dnsb(svs:query) "version=$mc_dnsb(svs:version)&"
append mc_dnsb(svs:query) \
  "svs_version=$mc_dnsb(svs:client_svs_version)"

if {![info exists numversion] ||
    ([string range $numversion 0 4] < "10614") ||
    (([string range $numversion 0 4] == "10614") &&
     ([string range $numversion 5 6] != "00"))} {
  set temp(tag) "$mc_dnsb(script) $mc_dnsb(version)"
  putloglev o * \
    "$temp(tag) by MC_8 will only work on eggdrop 1.6.14 (stable) or greater."
  putloglev o * "$temp(tag) will not work with eggdrop $version."
  putloglev o * "$temp(tag) not loaded."
  return 1
}
## ^

set temp(loaded) 0
foreach temp(module) [modules] {
  if {[lindex $temp(module) 0] == "dns"} {set temp(loaded) 1; break}
}
if {!$temp(loaded)} {
  if {[catch {loadmodule dns}]} {
    set temp(tag) "$mc_dnsb(script) $mc_dnsb(version)"
    putloglev o * "$temp(tag) by MC_8 requires the DNS module."
    putloglev o * "$temp(tag) Could not auto load the DNS module, error:"
    foreach temp(line) [split $errorInfo \n] {
      putloglev o * "$temp(tag)    $temp(line)"
    }
    putloglev o * "$temp(tag) not loaded."
    return 1
  }
}

setudef flag mc.dns_bans
setudef flag mc.dns_bans.exempt.op
setudef flag mc.dns_bans.exempt.voice
setudef str  mc.dns_bans.exempt.flags
setudef flag mc.dns_bans.enforcebans

# Error system, v3.2
proc mc:dnsb:errchk {command args} {
  if {![info exists ::lastCommand]} {set ::lastCommand [list]}
  set ::lastCommand \
    "[list [list [clock seconds] $command $args]] $::lastCommand"
  set ::lastCommand [lrange $::lastCommand 0 4]
  if {![catch {eval $command $args} return]} {return $return}
  if {$::errorCode != "mc.ecs.done"} {
    set temp(lastbind) [expr {[info exists ::lastbind]?$::lastbind:"-NULL-"}]
    set temp(eversion) [expr {[info exists ::version]?$::version:"-NULL-"}]
    putloglev o * "************************************"
    putloglev o * "(ECS 3.2) Error found in TCL script."
    putloglev o * "  --------------"
    putloglev o * "  Script name   : $::mc_dnsb(script)"
    putloglev o * "  Script version: $::mc_dnsb(version)"
    putloglev o * "  Egg. Version  : $temp(eversion)"
    putloglev o * "  TCL Version   : [info tclversion] ([info patchlevel])"
    putloglev o * "  --------------"
    putloglev o * "  Last Bind     : $temp(lastbind)"
    putloglev o * "  Last Commands :"
    foreach line $::lastCommand {
      foreach {time command arg} $line break
      putloglev o * "    ${time}- $command $arg"
    }
    putloglev o * "  Error stack   :"
    foreach line [split $::errorInfo \n] {
      putloglev o * "    $line"
    }
    putloglev o * "  --------------"
    putloglev o * "  Submit this bug to http://mc.purehype.net/bugzilla/ . If"
    putloglev o * "  you are experiencing problems with bugzilla, contact MC_8"
    putloglev o * "  via email at mc8@purehype.net. Please include all"
    putloglev o * "  information shown here, in this ECS report."
    putloglev o * "************************************"
  }
  return -errorcode mc.ecs.done -code error
}
# ^

bind join - * mc:dnsb:join
proc mc:dnsb:join {nick uhost handle channel} {
  return [mc:dnsb:errchk mc:dnsb:join_ $nick $uhost $handle $channel]
}
proc mc:dnsb:join_ {nick uhost handle channel} {
  if {![channel get $channel mc.dns_bans] ||
      [isbotnick $nick] ||
      [matchban $nick!$uhost $channel] ||
      [mc:dnsb:matchchanban $nick!$uhost $channel]} {return 0}
  set cache(exempt:flags) [channel get $channel mc.dns_bans.exempt.flags]
  if {($cache(exempt:flags) != "") &&
       [matchattr $handle $cache(exempt:flags) $channel]} {return 0}

  regexp -- (.*)@(.*) $uhost dummy ident host
  dnslookup [list $host] mc:dnsb:dnsreturn \
    [list $host $nick $ident $handle $channel]
}

bind mode - "% +o" mc:dnsb:mode:plso
proc mc:dnsb:mode:plso {nick uhost handle channel mc victim} {
  return [mc:dnsb:errchk mc:dnsb:mode:plso_ $nick $uhost $handle $channel $mc \
    $victim]
}
proc mc:dnsb:mode:plso_ {nick uhost handle channel mc victim} {
  if {![isbotnick $victim] ||
      ![validchan $channel] ||
      ![channel get $channel mc.dns_bans]} {return 0}

  set cache(exempt:op) [channel get $channel mc.dns_bans.exempt.op]
  set cache(exempt:voice) [channel get $channel mc.dns_bans.exempt.voice]
  set cache(exempt:flags) [channel get $channel mc.dns_bans.exempt.flags]

  set list [list]
  foreach nick [chanlist $channel] {
    if {[isbotnick $nick] ||
        ($cache(exempt:op) && [isop $nick $channel]) ||
        ($cache(exempt:voice) && [isvoice $nick $channel])} {continue}
    set uhost [getchanhost $nick]
    set handle [nick2hand $nick]

    if {(($cache(exempt:flags) != "") &&
         [matchattr $handle $cache(exempt:flags) $channel]) ||
        [matchban $nick!$uhost $channel] ||
        [mc:dnsb:matchchanban $nick!$uhost $channel]} {continue}

    lappend list $nick $uhost $handle
  }

  foreach {nick uhost handle} $list {
    regexp -- (.*)@(.*) $uhost dummy ident host
    dnslookup [list $host] mc:dnsb:dnsreturn \
      [list $host $nick $ident $handle $channel]
  }
  return 0
}

bind mode - "% +b" mc:dnsb:mode
proc mc:dnsb:mode {nick uhost handle channel mc {victim ""}} {
  return [mc:dnsb:errchk mc:dnsb:mode_ $nick $uhost $handle $channel \
    $mc $victim]
}
proc mc:dnsb:mode_ {nick uhost handle channel mc victim} {
  if {![channel get $channel mc.dns_bans]} {return 0}
  global mc_dnsb

  set cache(exempt:op) [channel get $channel mc.dns_bans.exempt.op]
  set cache(exempt:voice) [channel get $channel mc.dns_bans.exempt.voice]
  set cache(exempt:flags) [channel get $channel mc.dns_bans.exempt.flags]

  foreach nick [chanlist $channel] {
    if {[isbotnick $nick] ||
        ($cache(exempt:op) && [isop $nick $channel]) ||
        ($cache(exempt:voice) && [isvoice $nick $channel])} {continue}
    set uhost [getchanhost $nick]
    set handle [nick2hand $nick]

    if {(($cache(exempt:flags) != "") &&
         [matchattr $handle $cache(exempt:flags) $channel]) ||
        [matchban $nick!$uhost $channel] ||
        [mc:dnsb:matchchanban $nick!$uhost $channel] ||
        [string match $victim $nick!$uhost]} {continue}

    if {[regexp -- (.*)@(.*) [getchanhost $nick $channel] dummy ident host]} {
      dnslookup [list $host] mc:dnsb:dnsreturn \
        [list $host $nick $ident $handle $channel $victim]
    }
  }; return 1
}

proc mc:dnsb:dnsreturn \
  {ip host status eval nick ident handle channel {addition ""}} {
  return [mc:dnsb:errchk mc:dnsb:dnsreturn_ $ip $host $status $eval $nick \
    $ident $handle $channel $addition]
}
proc mc:dnsb:dnsreturn_ \
  {ip host status eval nick ident handle channel addition} {
  global mc_dnsb botnick
  if {!$status ||
      ![onchan $nick $channel] ||
      ![isop $botnick $channel] ||
      ![channel get $channel mc.dns_bans] ||
      ([channel get $channel mc.dns_bans.exempt.op] && [isop $nick $channel]) ||
      ([channel get $channel mc.dns_bans.exempt.voice] &&
       [isvoice $nick $channel]) ||
      (([set cache(e) [channel get $channel mc.dns_bans.exempt.flags]] != "") &&
       [matchattr $handle $cache(e) $channel]) ||
      [matchban $nick!$ident@$eval $channel] ||
      [mc:dnsb:matchchanban $nick!$ident@$eval $channel]} {return 0}

  if {$ip == $eval} {
    set host_resolved $host
    set host_origional $ip
  } else {
    set host_resolved $ip
    set host_origional $host
  }

  set nuhost_ [string tolower $nick!$ident@$host_resolved]
  if {![matchban $nuhost_ $channel] &&
      ![mc:dnsb:matchchanban $nuhost_ $channel] &&
      ![string match [string tolower $addition] $nuhost_]} {return 0}

  set banmask [mc:dnsb:maskhostbytype $nick!$ident@$host_origional \
    $mc_dnsb(:config:banmask)]

  set cache(exempt:op) [channel get $channel mc.dns_bans.exempt.op]
  set cache(exempt:voice) [channel get $channel mc.dns_bans.exempt.voice]
  set cache(exempt:flags) [channel get $channel mc.dns_bans.exempt.flags]

  set list [list]
  foreach nick [chanlist $channel] {
    if {[isbotnick $nick] ||
        ($cache(exempt:op) && [isop $nick $channel]) ||
        ($cache(exempt:voice) && [isvoice $nick $channel])} {continue}
    set uhost [getchanhost $nick]
    set handle [nick2hand $nick]
    set nuhost_ [string tolower $nick!$uhost]

    if {(($cache(exempt:flags) != "") &&
         [matchattr $handle $cache(exempt:flags) $channel]) ||
        ![string match $banmask $nuhost_]} {continue}
    lappend list $nick
  }

  if {[channel get $channel dynamicbans]} {
    if {[llength $list]} {putserv "MODE $channel +b $banmask"}
  } else {putserv "MODE $channel +b $banmask"}

  if {[channel get $channel enforcebans] ||
      [channel get $channel mc.dns_bans.enforcebans]} {
    foreach nick $list {
      set handle [nick2hand $nick]
      if {([channel get $channel dontkickops] &&
           [matchattr $handle o|o $channel]) ||
          [matchattr $handle f|f $channel]} {continue}
      putserv "KICK $channel $nick :banned"
    }
  }
}


## More Tools quick procs.
## -- http://mc.purehype.net/script_info.tcl?script=moretools

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
  # Were not going to use 2list here, don't want to evoke a 'too many nested
  # calls to Tcl_EvalObj' error since '2list' uses on this proc.
  if {[catch {llength $check_args} llength]} {
    set check_args [split $check_args]
    set llength $check_args
  }

  if {($llength < $check_min) ||
      (($llength != "end") && ($llength > $check_max))} {
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
#       v2.1
proc mc:dnsb:maskhostbytype {{args ""}} {
  mc:dnsb:badargs $args 1 2 "nick!ident@host.domain ?type?"
  mc:dnsb:unlist $args nuhost type

  set type [expr {($type == "")?5:$type}]
  if {![regexp -- {^1?[0-9]$} $type]} {
    set valid "0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 {or 19}"
    error "bad type \"$type\": must be [join $valid ", "]"
  }

  # Define the maximum length the ircd allows for an ident.  Standard is 9,
  # however I made it to a variable incase someone wants to change it up.
  set ident_max-length 9

  # Define the maximum length the ircd allows for a hostname/ ip.  Standard is
  # 63, however I made it to a variable incase someone wants to change it up.
  set host_max-length 63

  if {![regexp -- {^(.*[^!])!((.*)@(.*))$} $nuhost -> nick uhost ident host]} {
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

  # Previous version used regexp instead of these string matches.  String match
  # in this case is ~3 microseconds faster.
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

## End of More Tools quick procs.

proc mc:dnsb:matchchanban {nuhost channel} {
  set nuhost [string tolower $nuhost]
  foreach ban [chanbans $channel] {
    foreach {banmask by age} $ban break
    if {[string match [string tolower $banmask] $nuhost]} {return 1}
  }; return 0
}

## SVS insert (post code)
if {![info exists mc_dnsb(:config:svs:enable)] ||
    ![string match {[01]} $mc_dnsb(:config:svs:enable)]} {
  set mc_dnsb(:config:svs:enable) 0
}

bind time - "00 00 *" mc:dnsb:do_svs
proc mc:dnsb:do_svs {{args ""}} {
  global mc_dnsb
  set query $mc_dnsb(svs:query)
  if {$args == ""} {append query "&log=0"}
  if {[catch {connect $mc_dnsb(svs:server) $mc_dnsb(svs:port)} ind]} {
    set temp(1) "SVS problem connecting to $mc_dnsb(svs:server)"
    set temp(2) "on port $mc_dnsb(svs:port)"
    putloglev d * "$mc_dnsb(script): $temp(1) $temp(2):  $ind"
    return 0
  }
  putdcc $ind "GET $mc_dnsb(svs:get)?$query HTTP/1.0\n"
  putdcc $ind "Host: $mc_dnsb(svs:server):$mc_dnsb(svs:port)\n\n"
  control $ind mc:dnsb:svs_talk
}

proc mc:dnsb:svs_talk {index text} {
  global mc_dnsb
  set header [list svs header $index]
  set memory [list svs memory $index]
  if {$text == ""} {
    catch {unset mc_dnsb($header)}
    catch {unset mc_dnsb($memory)}
    return 1
  }
  set text [split $text]
  set rfc [lindex $text 0]
  set text [join [lrange $text 1 end]]
  if {![info exist mc_dnsb($header)]} {
    if {$rfc == "002"} {
      # Done with http header and useless information.
      if {!$mc_dnsb(:config:svs:enable)} {
        catch {unset mc_dnsb($header)}
        catch {unset mc_dnsb($memory)}
        return 1
      }
      set mc_dnsb($header) 1
    }
    return 0
  }
  switch -- $rfc {

    001 {return 0}
    002 {return 0}
    003 {return 0}

    010 {
      if {$text != $mc_dnsb(svs:script)} {
        set temp(1) "wanted $mc_dnsb(svs:script), got $temp(text:0)"
        putloglev d * "$mc_dnsb(script): SVS Error: $temp(1)"
        catch {unset mc_dnsb($header)}
        catch {unset mc_dnsb($memory)}
        return 1
      }
      return 0
    }

    011 {return 0}
    012 {return 0}
    013 {return 0}
    014 {return 0}
    017 {return 0}

    004 {
      if {[info exists mc_dnsb($memory)]} {
        set file $mc_dnsb(info:loc)~new
        set temp(vars) $mc_dnsb(info:vars)
        set io [open $file w]
        for {set i 0} {$i <= [llength $mc_dnsb($memory)]} {incr i} {
          set line [lindex $mc_dnsb($memory) $i]
          set regexp {^[; ]*set mc_dnsb\((:config:[^)]*)\) *(.?)}
          if {[regexp -- $regexp $line -> name type]} {
            set continue 0
            foreach item $temp(vars) {
              set item_name [lindex $item 0]
              set item_value [lindex $item 1]
              if {$name != $item_name} {continue}
              set index [lsearch -exact $temp(vars) $item]
              set temp(vars) [lreplace $temp(vars) $index $index]
              puts $io [list set mc_dnsb($name) $item_value]
              if {$type == "\{"} {
                while {1} {
                  if {[regexp -- {\}(?:[; ][; ]*(.*))?} $line -> extra]} {
                    if {$extra != ""} {
                      puts $io $extra
                    }
                    break
                  }
                  incr i
                  set line [lindex $mc_dnsb($memory) $i]
                }
                puts $io ""
              } elseif {$type == "\""} {
                regsub -- {"} $line "" line
                while {1} {
                  if {[regexp -- {[^\\]"(?:[; ][; ]*(.*))?} $line -> extra] ||
                      [regexp -- {^"(?:[; ][; ]*(.*))?} $line -> extra]} {
                    if {$extra != ""} {
                      puts $io $extra
                    }
                    break
                  }
                  incr i
                  set line [lindex $mc_dnsb($memory) $i]
                }
                puts $io ""
              }
              set continue 1
              break
            }
            if {$continue} {continue}
          }
          puts $io $line
        }
        close $io
        set file $mc_dnsb(info:loc)
        putloglev o * "$mc_dnsb(script): Auto update testing new script..."
        if {[catch {uplevel "source $file~new"} error]} {
          file delete -force -- $file~new
          putloglev o * "$mc_dnsb(script): Auto update failed: $error"
          putloglev o * $::errorInfo
          putloglev o * "$mc_dnsb(script): Auto update loading previous script."
          uplevel "source $file"
        } else {
          file rename -force -- $file~new $file
          putloglev o * "$mc_dnsb(script): Auto update test good, reloading."
          uplevel "source $file"
        }
      }

      catch {unset mc_dnsb($header)}
      catch {unset mc_dnsb($memory)}
      return 1
    }

    200 {
      set temp(host) [lindex $text 1]
      set temp(port) [lindex $text 2]
      set temp(get)  [lindex $text 3]
      set temp(cache) "$temp(host) at $temp(port)"
      putloglev d * \
        "$mc_dnsb(script): SVS is being redirected to $temp(cache)."
      utimer 5 [list mc:dnsb:do_svs_ $temp(host) $temp(port) $temp(get)]
      catch {unset mc_dnsb($header)}
      catch {unset mc_dnsb($memory)}
      return 1
    }

    300 {
      lappend mc_dnsb($memory) $text
      return 0
    }

  }
}
catch {unset index}
if {![info exists mc_loaded]} {set mc_loaded(scripts) ""}
set index [lsearch -exact $mc_loaded(scripts) mc_dnsb]
lreplace mc_loaded(scripts) $index $index mc_dnsb
## ^

putloglev o * "$mc_dnsb(script) $mc_dnsb(version) by MC_8 loaded."

##
# History  ( <Fixed by> - [Found by] - <Info> )
##
# v1.3.1 (04.04.04)
#  MC_8 - AntiProxy - Script would not dns ban those with caps in there
#                     banmask.
#
# v1.3 (08.17.03)
#  MC_8 - Jojo /  - Script now does it's own kick enforcement bassed off
#         Mike      enforcebans and mc.dns_bans.enforcebans chanset.
#                   Bugzilla Bug 207
#                   Bugzilla Bug 312
#  MC_8 - Postino - Added mc.dns_bans.enforcebans chanset.
#                   Bugzilla Bug 203
#  MC_8 -         - Did a little clean up code here and there.
#  MC_8 -         - Upgraded `maskhostbytype`. v2.0 -> v2.1
#  MC_8 -         - If a user that joins is already banned, no need to run the
#                   dnslookup.
#  MC_8 -         - Upon bot joinning, having it wait for raw 315 to obtain
#                   proper channel list.
#  MC_8 -         - Upgraded ECS.  v3.0 -> v3.2
#  MC_8 -         - Upgraded SVS Client.  v3.0.1 -> v4.0.4
#  MC_8 -         - Removed `chanflag` proc, using eggdrop's 'channel get'
#                   function instead.
#  MC_8 -         - Removed `exempt:op`, `exempt:voice` and `exempt:flag`.
#                   Created dcc 'chanset' (on the fly) configuration options
#                   instead.
#  MC_8 -         - Changed channel flag from mc.dnsbans to mc.dns_bans.
#
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
#  MC_8 - Randy  - Fixed '[mc:dnsb:join]: list element in braces followed by
#                  "b133d" instead of space'.
#                  Bugzilla bug: 57
#  MC_8 -        - Fixed 'Tcl error [mc:dnsb:dnsreturn]: can't read
#                  "mc_dnsb(isban)": no such variable'.
#                  Bugzilla bug: 43
#  MC_8 -        - Upgraded `chanflag` proc.  v1.0 -> v2.0
#  MC_8 -        - Removed the time binding.  I don't think we need this; if
#                  someone adds a ban on the fly, I'm pretty sure there going to
#                  enter the correct ban.  The time binding only checked
#                  excessive situations that rarely happened, and took up cpu
#                  time in doing so.
#  MC_8 -        - Re coded join/ mode/ dnsreturn proc, more efficient/ faster.
#  MC_8 -        - Added `exempt:op` and `exempt:voice` settings.
#  MC_8 -        - Changed how it detects the dns module, more efficient.
#  MC_8 - Niklas - Fixed 'invalid command name "mc:dnbs:time"', bot crash.
#                  Bugzilla bug: 40
#
# v1.1 (11.14.01)
#  MC_8 - - Upgraded SVS Client.  v1.2 -> v2.0.
#  MC_8 - - Added a time bind.  If I cannot detect .+ban's over a sharenet then
#           I'll just scan the channel once every 10 min's.
#  MC_8 - - Added mc.dnsbans channel flag.
#  MC_8 - - Removed unused replace, findip, filt, unfilt and findchanuser proc.
#  MC_8 - - Updated the masktype and chanflag proc.
#  MC_8 - - Rewrote the procs a bit to make it run a little more efficient.
#
# v1.0 (03.17.01)
#  MC_8 - KatzEye - Fixed, `Tcl error [mc:dnsb:dnsreturn]: invalid command name
#                   "???"`.
#  MC_8 -         - Initial Release.
##
