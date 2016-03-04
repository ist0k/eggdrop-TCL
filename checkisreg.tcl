# $Id: checkisreg.tcl,v1.0 13/07/2014 12:13:51pm GMT +12 (NZST) IRCSpeed Exp $

# SYNTAX (on PartyLine/DCC/CTCP/TELnet): .chanset #channel -/+checkisauth
# ----------
# PUBCMD:
# !checkisreg on|off
# ----------
# MSGCMD:
# /msg botnick checkisreg #channel on|off

# ---------- SETTINGS ----------
# Set your global trigger (default: !)
set checkisregtrig "!"

# Set global access flags to enable/disable authcheck (default: o)
set isregglobflags o

# Set channel access flags to enable/disable authcheck (default: o)
set isregchanflags o

# Set here the string used to match registered/authenticated user's
set verifieduser "*is a registered nick*"

# ----- NO EDIT -----
# You may have to change the RAW numeric below to match your IRCd.
bind raw - 307 check_isreg
bind join - * join_checkisreg
bind pub - ${checkisregtrig}checkisreg authcheck:pub
bind msg - checkisreg authcheck:msg

proc isregTrigger {} {
  global checkisregtrig
  return $checkisregtrig
}

setudef flag checkisauth

proc join_checkisreg {nick uhost hand chan arg} {
  if {![channel get $chan checkisauth]} {return}
  if {![isbotnick $nick] && ![validuser [nick2hand $nick]]} {
    putserv "WHOIS $nick"
  }
}

proc check_isreg {from keyword args} {
  global verifieduser
  if {![string match $verifieduser $args]} {return}
  set nick [lindex [split $args] 1]
   foreach chan [channels] {
    if {![onchan $nick $chan] && ![channel get $chan checkisauth] && [validuser [nick2hand $nick]] && [isop $nick $chan] && [isvoice $nick $chan]} {return}
    putquick "MODE $chan +v $nick"
  }
}

proc authcheck:pub {nick uhost hand chan arg} {
  global isregglobflags isregchanflags
  if {[matchattr [nick2hand $nick] $isregglobflags|$isregchanflags $chan]} {
    if {[lindex [split $arg] 0] == ""} {putquick "PRIVMSG $chan :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [isregTrigger]checkisreg on|off"; return}

    if {[lindex [split $arg] 0] == "on"} {
      if {[channel get $chan checkisauth]} {putquick "PRIVMSG $chan :\037ERROR\037: This setting is already enabled."; return}
      channel set $chan +checkisauth
      puthelp "PRIVMSG $chan :Enabled Automatic Register Checking for $chan"
      return 0
    }

    if {[lindex [split $arg] 0] == "off"} {
      if {![channel get $chan checkisauth]} {putquick "PRIVMSG $chan :\037ERROR\037: This setting is already disabled."; return}
      channel set $chan -checkisauth
      puthelp "PRIVMSG $chan :Disabled Automatic Register Checking for $chan"
      return 0
    }
  }
}

proc authcheck:msg {nick uhost hand arg} {
  global botnick isregglobflags isregchanflags
  set chan [strlwr [lindex [split $arg] 0]]
  if {[matchattr [nick2hand $nick] $isregglobflags|$isregchanflags $chan]} {
    if {[lindex [split $arg] 0] == ""} {putquick "NOTICE $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: /msg $botnick checkisreg #channel on|off"; return}
    if {([lindex [split $arg] 1] == "") && ([string match "*#*" $arg])} {putquick "NOTICE $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: /msg $botnick checkisreg $chan on|off"; return}

    if {[lindex [split $arg] 1] == "on"} {
      if {[channel get $chan checkisauth]} {putquick "NOTICE $nick :\037ERROR\037: This setting is already enabled."; return}
      channel set $chan +checkisauth
      putquick "NOTICE $nick :Enabled Automatic Register Checking for $chan"
      return 0
    }

    if {[lindex [split $arg] 1] == "off"} {
      if {![channel get $chan checkisauth]} {putquick "NOTICE $nick :\037ERROR\037: This setting is already disabled."; return}
      channel set $chan -checkisauth
      putquick "NOTICE $nick :Disabled Automatic Register Checking for $chan"
      return 0
    }
  }
}

putlog ".:LOADED:. checkisreg.tcl,v1.0 - istok @ IRCSpeed"
