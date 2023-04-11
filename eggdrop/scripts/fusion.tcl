# -------------------------------------------
# Fusion (DCC/Pub/BotNet) - For Eggdrop 1.3.x
# -------------------------------------------
# 
# Author: Andrew
# Date  : 05/10/98
# IRCNET: AndrewX
#
# Any comments & suggestions welcomed.
#
# This program is at it's very early stages, it only supports a limited set of
# commands for the moment. Once I get the time (god knows we all need it) I
# wish to implement more public, and dcc/net commands too. Respect goes out to
# those writers who spend their time and effort into making bot's worthwhile
# to use. 
#
# Update(2001): Errrmmm not sure whether I can be bothered to continue this..
#
# Adios! -AndrewX
#
######## VARIABLE DECLARATIONS

set pub-chr "."
set whois-fields "URL EMAIL ICQ GREETDCC"
set chan-notice-list { "#peace" }
set chan-reject-list { "#webbernet" "#eu-opers" "#us-opers" "#cifnet" "#help" "#irchelp" "#ircnet" }
set chan-rules "Quite simple, behave or be kick/banned. This channel is not a playground for assholes."
set fn-ver "1.01b"

######## DEFAULT VARIABLES

set def-echo-status 0
set def-strip-flags "+crag"
set def-chanmode "+nt dont-idle-kick"
set def-choptions "+clearbans +enforcebans +dynamicbans +userbans -autoop +bitch -greet +protectops
                   -statuslog +stopnethack -revenge -secret +shared -autovoice +cycle -seen"
set def-flood-chan "15:10"
set def-flood-deop "5:10"
set def-flood-kick "5:10"
set def-flood-ctcp "4:60"
set def-flood-join "5:30"

######## BINDS/UNBINDS

unbind dcc o|- msg *dcc:msg
unbind dcc o|- say *dcc:say
bind dcc n|n msg *dcc:msg
bind dcc n|n say *dcc:say

if {![info exists dcc-disable]} {set dcc-disable 0}
if {![info exists tcl-status]} {set tcl-status 0}
if {![info exists set-status]} {set set-status 0}
if {![info exists set-status]} {set sim-status 0}
if {![info exists use-seen]} {set use-seen 0}
if {![info exists use-pub]} {set use-pub 0}
if {![info exists join-not]} {set join-not 0}
if {![info exists user-info]} {set user-info 0}

if {!${set-status}} {unbind dcc n set *dcc:set}
if {!${tcl-status}} {unbind dcc n tcl *dcc:tcl}
if {!${sim-status}} {unbind dcc n simul *dcc:simul}

if {${dcc-disable} == 1} {
   set answer-ctcp 0
   bind msg o|o access msg:chat-request
}

if {${join-not} == 1} {
   bind join * * join:chan-info
}

if {${use-pub} == 1} {
   unbind pub -|- seen *pub:seen
   bind pub n|n ${pub-chr}chadd public:chadd
   bind pub n|n ${pub-chr}cycle public:cycle
   bind pub o|o ${pub-chr}op public:op
   bind pub o|o ${pub-chr}dop public:dop
   bind pub o|o ${pub-chr}sban public:showbans
   bind pub o|o ${pub-chr}uban public:unban
   bind pub o|o ${pub-chr}bk public:bankick
   bind pub o|o ${pub-chr}ban public:ban
   bind pub o|o ${pub-chr}bankick public:bankick
   bind pub o|o ${pub-chr}k public:kick
   bind pub o|o ${pub-chr}kick public:kick
   bind pub o|o ${pub-chr}m public:mode
   bind pub o|o ${pub-chr}mode public:mode
   bind pub o|o ${pub-chr}voice public:voice
   bind pub o|o ${pub-chr}devoice public:devoice
   bind pub f|f ${pub-chr}t public:topic
   bind pub f|f ${pub-chr}topic public:topic
   bind pub -|- ${pub-chr}ver public:ver
   bind pub -|- ${pub-chr}seen *pub:seen
}

if {${aj-on} == 1} {
   bind kick - * kick:autorejoin
}

unbind msg - whois *msg:whois
unbind msg - hello *msg:hello
unbind msg - help *msg:help
unbind msg - status *msg:status
unbind msg - die *msg:die
unbind msg - jump *msg:jump
unbind msg - memory *msg:memory
unbind msg - rehash *msg:rehash
unbind msg - reset *msg:reset

######## Background Tasks

if {![info exists idle.check]} {
   set idle.check 0
   utimer [expr [rand 5] + 1] [subst {sub:ai-privmsg}]
}

######## MSG: DCC CHAT Login

proc msg:chat-request {nick uhost hand password} {
   set dcc-userport 6668
   if {${password}=="xxxxxx"} {
#      if {![matchattr [nick2hand ${nick} ${chan}] op]} {
        putcmdlog "\002FN\002> Opening connection for: ${hand} (${nick}!${uhost})\r"
        listen ${dcc-userport} {users}
        putserv "PRIVMSG ${nick} :\001DCC CHAT chat [myip] ${dcc-userport}\001"
#      }
   } else {
      putcmdlog "(${nick}!${uhost}) !${hand}! failed LOGIN (invalid password)\r"
   }
   unset dcc-userport
}

######## JOIN: Channel rules

proc join:chan-info {nick uhost hand chan} { 
    global chan-notice-list chan-rules
    foreach x ${chan-notice-list} {
      if {(${chan} == ${x}) && (![matchattr ${hand} f ${x}])} {
        putserv "NOTICE ${nick} :Welcome ${nick}. \002${chan}\002 rules: ${chan-rules}"
      }
    }
}

######## KICK: Auto-rejoin ban

proc kick:autorejoin {nick uhost hand chan kuser null} {
   global aj-delay
   utimer ${aj-delay} [subst {ban:autorejoin ${uhost} {$kuser} ${chan}}]
}

proc ban:autorejoin {uhost nick chan} {
    global aj-delay aj-bantime
    if {[onchan ${nick} ${chan}]} {
	 if {![matchattr [nick2hand ${nick} ${chan}] f]} {
          set banmask [sub:check-host ${uhost} ${nick} ${chan} 1]
          putserv "MODE ${chan} +b ${banmask}"
          putserv "KICK ${chan} ${nick} :\002Banned\002 (${chan}): Auto-rejoin. Temporary ban \[${aj-bantime} min(s)\]"
          if {![expr [lsearch -glob [utimers] "*MODE $chan -b ${banmask}*"] + 1]} {
             utimer [expr 60 * ${aj-bantime}] [subst {putserv "MODE $chan -b ${banmask}"}]
          }
       }
    }
}

######### PUBLIC: .op <nicks>

proc public:op {nick host hand chan nickstr} {
    if {[string range ${nickstr} 0 end] == ""} {
        putserv "MODE ${chan} +o ${nick}"
	return 0
    }
    if {[lindex ${nickstr} 0] == "?"} {
      puthelp "NOTICE ${nick} :\002HELP\002> Usage: .op (nick/s) -+- Note: max 3 nicks, or void to +o yourself."
      return 0
    }
    if {![botisop ${chan}]} {
	puthelp "NOTICE ${nick} :\002FN\002> ${nick}: I'm not an OP in ${chan}."
	return 0
    }
    putserv "MODE ${chan} +ooo [string range ${nickstr} 0 end]"
}

######### PUBLIC: .dop <nicks>

proc public:dop {nick host hand chan nickstr} {
    if {[string range ${nickstr} 0 end] == ""} {
       putserv "MODE ${chan} -o ${nick}"
	 return 0
    }
    if {[lindex ${nickstr} 0] == "?"} {
       puthelp "NOTICE ${nick} :\002HELP\002> Usage: .dop (nick/s) -+- Note: max 3 nicks, or void to -o yourself."
       return 0
    }
    if {![botisop ${chan}]} {
	 puthelp "NOTICE ${nick} :\002FN\002> ${nick}: I'm not an op in ${chan}."
	 return 0
    }
    putserv "MODE ${chan} -ooo [string range ${nickstr} 0 end]"
}

######### PUBLIC: .voice <nicks>

proc public:voice {nick host hand chan nickstr} {
    if {[string range ${nickstr} 0 end] == ""} {
        putserv "MODE ${chan} +v ${nick}"
	return 0
    }
    if {[lindex ${nickstr} 0] == "?"} {
      puthelp "NOTICE ${nick} :\002HELP\002> Usage: .voice (nick/s) -+- Note: max 3 nicks, or void to +v yourself."
      return 0
    }
    if {![botisop ${chan}]} {
	puthelp "NOTICE ${nick} :\002FN\002> ${nick}: I'm not an op in ${chan}."
	return 0
    }
    putserv "MODE ${chan} +vvv [string range ${nickstr} 0 end]"
}

######### PUBLIC: .devoice <nicks>

proc public:devoice {nick host hand chan nickstr} {
    if {[string range ${nickstr} 0 end] == ""} {
        putserv "MODE ${chan} -v ${nick}"
	return 0
    }
    if {[lindex ${nickstr} 0] == "?"} {
      puthelp "NOTICE ${nick} :\002HELP\002> Usage: .devoice (nick/s) -+- Note: max 3 nicks, or void to -v yourself."
	return 0
    }
    if {![botisop ${chan}]} {
	puthelp "NOTICE ${nick} :\002FN\002> ${nick}: I'm not an op in ${chan}."
	return 0
    }
    putserv "MODE ${chan} -vvv [string range ${nickstr} 0 end]"
}

######### PUBLIC: .sban <Channel>

proc public:showbans {nick hand uhost chan arg} {
  if {${arg} != ""} {
     set channel [string range ${arg} 0 end]
  } else {
     set channel ${chan}
  }
  if {![validchan ${channel}]} {
     puthelp "NOTICE $nick :\002FN\002> ${nick}: ${channel} does not exist on channel record."
     return 0
  }
  if {[chanbans ${channel}] == ""} {
     putserv "NOTICE ${nick} :\002FN\002> No Bans exist for channel $channel.\n"
     return 0
  }
  putserv "PRIVMSG ${nick} :\002FN\002> \002Bans\002 for channel $channel:\n"
  set y 1
  foreach x [chanbans ${channel}] {
    putserv "PRIVMSG ${nick} :\002FN\002> ${y}. [lindex ${x} 0]"
    incr y
  }
}

######### PUBLIC: .unban

proc public:unban {nick hand uhost chan arg} {
  if {[lindex ${arg} 1] != ""} {
    set channel [lindex ${arg} 1]
  } else {
    set channel ${chan}
  }
  if {![validchan ${channel}]} {
     puthelp "NOTICE ${nick} :\002FN\002> ${nick}: ${channel} does not exist on channel record."
     return 0
  }
  if {[chanbans ${channel}] == ""} {
     putserv "MOITCE ${nick} :\002FN\002> No Bans exist for channel ${channel}.\n"
     return 0
  }
  set y 1
  if {[string toupper [lindex ${arg} 0]]=="ALL"} {
    foreach x [chanbans ${channel}] {
       putserv "MODE ${channel} -b [lindex ${x} 0]"
    }
  } else {
    foreach x [chanbans ${channel}] {
      if {${y} == [lindex ${arg} 0]} {
         putserv "MODE ${channel} -b [lindex ${x} 0]"
         return 0
      }
    incr y
    }
  }
}

######### PUBLIC: .ban <Banmask>

proc public:ban {nick host hand chan arg} {
    if {${arg} == ""} {
       puthelp "NOTICE ${nick} :\002HELP\002> Usage: .ban \[banmask\]"
       return 0
    }
    putserv "MODE ${chan} +b [lrange ${arg} 0 end]"
}

######### PUBLIC: .bk <Nick> <Channel> <Reason>

proc public:bankick {nick host hand chan arg} {
    if {${arg} == ""} {
       puthelp "NOTICE ${nick} :\002HELP\002> Usage: .bk \[nick]\ (#chan) (reason) -+- Note: #chan/reason are optional."
       return 0
    }
    if {![validchan [lindex ${arg} 1]]} {
       set channel ${chan}
       set reason [lrange ${arg} 1 end]
    } else {
       set channel [lindex ${arg} 1]
       set reason [lrange ${arg} 2 end] 
    }
    if {![onchan [lindex ${arg} 0] ${channel}]} {
	 puthelp "NOTICE ${nick} :\002FN\002> ${nick}: [lindex ${arg} 0] is not here in ${channel}."
	 return 0
    }
    set banmask [sub:check-host ${host} [lindex ${arg} 0] ${chan} 0]
    if {${reason} == ""} {
	 set reason "[lindex ${arg} 0] \[${banmask}\]"
    }
    putserv "MODE ${channel} -o+b [lindex ${arg} 0] ${banmask}"
    putserv "KICK ${channel} [lindex ${arg} 0] :\002Banned\002 (${channel}): ${reason}"
}

######### PUBLIC: .k <Nick> <Channel> <Reason>

proc public:kick {nick host hand chan arg} {
    if {${arg} == ""} {
	 puthelp "NOTICE ${nick} :\002HELP\002> Usage: .k \[nick]\ (#chan) (reason) -+- Note: #chan/reason are optional."
	 return 0
    }
    if {![validchan [lindex ${arg} 1]]} {
       set channel ${chan}
       set reason [lrange ${arg} 1 end]
    } else {
       set channel [lindex ${arg} 1]
       set reason [lrange ${arg} 2 end] 
    }
    if {![onchan [lindex ${arg} 0] ${channel}]} {
	 puthelp "NOTICE ${nick} :\002FN\002> ${nick}: [lindex ${arg} 0] is not here in ${channel}."
	 return 0
    }
    if {${reason} == ""} {
	 set reason "Lame."
    }
    putserv "KICK ${channel} [lindex ${arg} 0] :\002Kicked\002 (${channel}): ${reason}"
}

######## PUBLIC: .chadd (channel

proc public:chadd {nick host hand chan arg} {
   if {[lindex ${arg} 0] == ""} {
       puthelp "NOTICE ${nick} :\002HELP\002> Usage: .chadd \[#chan]\"
       return 0
   }
   puthelp "NOTICE ${nick} :\002FN\002> Now joining channel [lindex ${arg} 0]."
   sub:chan-rec [lindex ${arg} 0]
}

######## PUBLIC: .cycle

proc public:cycle {nick host hand chan arg} {
    set channel [lindex ${arg} 0]
    if {${arg} == ""} {
       putserv "PART ${chan}"
    }
    if {${arg} != ""} {
       putserv "PART ${channel}"
    }
}
	 
######## PUBLIC: .topic <Chan topic>

proc public:topic {nick host hand chan topic} {
    if {[string index ${topic} 0]!=""} {
       putserv "TOPIC ${chan} :[string range ${topic} 0 end]"
    } else {
       putserv "TOPIC ${chan} :"
    }
}

######## PUBLIC: .mode <Chan modes>

proc public:mode {nick host hand chan modes} {
    if {[lrange $modes 0 end] != ""} {
        putserv "MODE $chan $modes"
    }	
}	

######## PUBLIC: .ver

proc public:ver {nick host hand chan arg} {
    global fn-ver
    puthelp "NOTICE ${nick} : .--- - - - -- - -"
    puthelp "NOTICE ${nick} :/ Running \002F\002u\002s\002io\002N\002 v${fn-ver} by \037Andrew\037 \[venom@dial.pipex.com\]"
    puthelp "NOTICE ${nick} :`---------------------- - - - -- - -"
}

######## DCC: net <Action>

bind dcc n|n net dcc:botnet
proc dcc:botnet {han idx args} {
set args [lindex $args 0]
set option [lindex $args 0]
 switch -exact ${option} {
   "" {
     putdcc $idx "\002FN\002> NET: No option specified. Type .net =h for help.\r"
     return 0     
   }
   "=h" {
     putdcc $idx "\002FN\002> Botnet command list\r"
     putdcc $idx "\002FN\002> -------------------------------------------- ---- -- - - -\r"
     putdcc $idx "\002FN\002> .net =j \[#chan\]         Join botnet to a channel.\r"
     putdcc $idx "\002FN\002> .net =p \[#chan\]         Part botnet from a channel.\r"
     putdcc $idx "\002FN\002> .net =t \[#chan\] \[msg\]   Sends a botnet message to a channel.\r"
     putdcc $idx "\002FN\002> .net =m \[#chan\] \[mode\]  Sets botnet channel modes for channel.\r"
     putdcc $idx "\002FN\002> .net =c \[#chan\] \[opts\]  Sets botnet channel options for channel.\r"
     putdcc $idx "\002FN\002> .net =b \[servr\]         Bounces botnet to another server.\r"
     putdcc $idx "\002FN\002> .net =r                 Initiate a botnet rehash.\r"
     putdcc $idx "\002FN\002> .net =s                 Initiate a botnet save.\r"
     putdcc $idx "\002FN\002> .net =h                 Display this help screen.\r"
     putdcc $idx "\002FN\002> -------------------------------------------- ---- -- - - -\r"
     putdcc $idx "\002FN\002> For botnet stats information, type .netstat =h (future rev. -Andrew)\r"
     return 0     
   }
   "=j" {
     if {[lindex ${args} 1]==""} {
        putdcc ${idx} "\002FN\002> NET: No channel specified. Type .net =h for help.\r"
     } else { 
        putlog "\002FN\002> NET: Now joining botnet to channel: [lindex ${args} 1]\r"
        sub:chan-rec [lindex ${args} 1]
     }
   }
   "=p" {
     if {[lindex ${args} 1]==""} {
        putdcc ${idx} "\002FN\002> NET: No channel specified. Type .net =h for help.\r"
     } else { 
        putlog "\002FN\002> NET: Now parting botnet from channel: [lindex ${args} 1]\r"
        channel remove [lindex ${args} 1]
     }
   }
   "=t" {
     if {([lindex ${args} 1]=="") || ([lindex ${args} 2]=="")} {
        putdcc ${idx} "\002FN\002> NET: No channel/message specified. Type .net =h for help.\r"
     } else { 
        putlog "\002FN\002> NET: Sending message to [lindex ${args} 1]: [lrange ${args} 2 end]"
        putserv "PRIVMSG [lindex $args 1] :[lrange $args 2 end]"
     }
   }
   "=m" {
     if {([lindex ${args} 1]=="") || ([lindex ${args} 2]=="")} {
        putdcc ${idx} "\002FN\002> NET: No channel/settings specified. Type .net =h for help.\r"
     } else { 
        putlog "\002FN\002> NET: Setting channel mode for [lindex ${args} 1] to: [lrange ${args} 2 end]"
        channel set [lindex ${args} 1] chanmode [lrange ${args} 2 end]
     }
   }
   "=c" {
     if {([lindex ${args} 1]=="") || ([lindex ${args} 2]=="")} {
        putdcc ${idx} "\002FN\002> NET: No channel/settings specified. Type .net =h for help.\r"
     } else { 
        putlog "\002FN\002> NET: Setting channel options for [lindex ${args} 1] to: [lrange ${args} 2 end]"
        channel set [lindex ${args} 1] [lrange ${args} 2 end]
     }
   }
   "=b" {
     if {[lindex ${args} 1]==""} {
        putdcc ${idx} "\002FN\002> NET: No server specified. Type .net =h for help.\r"
     } else { 
        putlog "\002FN\002> NET: Now jumping botnet to server: [lindex ${args} 1] [lindex ${args} 2]\r"
        jump [lindex ${args} 1] [lindex ${args} 2]
     }
   }
   "=r" {
     putlog "\002FN\002> NET: Initiating a botnet rehash.\r"
     rehash
   }
   "=s" {
     putlog "\002FN\002> NET: Initiating a botnet save.\r"
     save
   }
 }
 putallbots "net ${args}"
 return 0
}

######## BOT: Actions

bind bot - net bot:botnet
proc bot:botnet {bot cmd args} {
set args [lindex ${args} 0]
set option [lindex ${args} 0]
 switch -exact ${option} {
   "=j" {
     sub:chan-rec [lindex ${args} 1]
     putlog "\002FN\002> NET: Join request for channel: [lindex ${args} 1] from ${bot}.\r"
   }
   "=p" {
     channel remove [lindex ${args} 1]
     putlog "\002FN\002> NET: Part request for channel: [lindex ${args} 1] from ${bot}.\r"
   }
   "=t" {
     putserv "PRIVMSG [lindex ${args} 1] :[lrange ${args} 2 end]"
     putlog "\002FN\002> NET: Say request from ${bot}.\r"
   }
   "=m" {
     channel set [lindex ${args} 1] chanmode [lrange ${args} 2 end]
     putlog "\002FN\002> NET: Setting channel mode: [lrange ${args} 2 end] for [lindex ${args} 1]\r"
   }
   "=c" {
     channel set [lindex ${args} 1] [lrange ${args} 2 end]
     putlog "\002FN\002> NET: Setting channel option(s): [lrange ${args} 2 end] for [lindex ${args} 1]\r"
   }
   "=b" {
     jump [lindex ${args} 1] [lindex ${args} 2]
     putlog "\002FN\002> NET: Jumping to server: [lindex ${args} 1] [lindex ${args} 2]\r"
   }
   "=r" {
     putlog "\002FN\002> NET: Rehash request from ${bot}.\r"
     rehash
   }
   "=s" {
     putlog "\002FN\002> NET: Save request from ${bot}.\r"
     save
   }
 }
 return 0
}

######## DCC: cycle <Channel>

bind dcc n|n cycle dcc:cycle
proc dcc:cycle {han idx chan} {
    if {[lindex ${chan} 0] == ""} {
       putdcc ${idx} "\002FN\002> Syntax: .cycle \[#chan\]\r"
       return 0
    }
    putdcc ${idx} "\002FN\002> Cycling channel: [lindex ${chan} 0].\r"
    putserv "PART [lindex ${chan} 0]"
}

######## DCC: chadd [#chan] (go)

bind dcc n|n chadd dcc:chadd
proc dcc:chadd {han idx arg} {
   if {[lindex ${arg} 0] == ""} {
       putdcc ${idx} "\002FN\002> Syntax: .chadd \[#chan\]\r"
       return 0
   }
   putdcc ${idx} "\002FN\002> Joining channel: [lindex ${arg} 0].\r"
   sub:chan-rec [lindex ${arg} 0]
}

######## DCC: chrem [#chan]

bind dcc n|n chrem dcc:chrem
proc dcc:chrem {han idx chan} {
   if {[lindex ${chan} 0] == ""} {
      putdcc ${idx} "\002FN\002> Syntax: .chrem \[#chan\]\r"
      return 0
   }
   channel remove [lindex ${chan} 0]
   putdcc $idx "\002FN\002> Leaving channel: [lindex ${chan} 0].\r"
   putserv "PART [lindex ${chan} 0]"
}

######### On-join greet, info display

bind chon - * dcc:show_info
proc dcc:show_info {handle idx} {
   global user-info def-echo-status def-strip-flags fn-ver
   putdcc ${idx} " "
   putdcc ${idx} " .------ - - -\r"
   putdcc ${idx} "/ + Fusion v${fn-ver} +\r"
   putdcc ${idx} "`---------------- - - -// AndrewX\r"
   putdcc ${idx} " "
   echo ${idx} ${def-echo-status}
   strip ${idx} ${def-strip-flags}
   if {${user-info} == 1} {
      dcc:userinfo ${handle} ${idx}
   }
}

proc dcc:userinfo {handle idx} {
   set greet [getuser ${handle} xtra GREETDCC]
   set url [getuser ${handle} xtra URL]
   set email [getuser ${handle} xtra EMAIL]
   set icq [getuser ${handle} xtra ICQ]
   if {![string length ${greet}] >= "1"} {
      putdcc ${idx} "You have no greet message set.   (Syntax: .greet \[greet msg\]   )\r"
   }
   if {![string length ${url}] >= "1"} {
      putdcc ${idx} "You have no url address set.     (Syntax: .url   \[www.your.url\])\r"
   }	
   if {![string length ${email}] >= "1"} {
      putdcc ${idx} "You have no e-mail address set.  (Syntax: .email \[u@h\]         )\r"
   }	
   if {![string length ${icq}] >= "1"} {
      putdcc ${idx} "You have no icq number set.      (Syntax: .icq   \[icq-uin\]     )\r"
   }	
   if {[string length ${greet}] >= "1" && [string length ${url}] >= "1" &&
       [string length ${email}] >= "1" && [string length ${icq}] >= "1"} {
       putdcc ${idx} "You have all user information setup.\r"
       dccputchan 0 ".:\[\002${handle}\002\]:. ${greet}\r"
   }
   return 0
}

bind dcc - greet dcc:setgreet
proc dcc:setgreet {handle idx text} {
   set greetmsg [lrange ${text} 0 end]
   if {${greetmsg} == ""} {
      putdcc ${idx} "\002FN\002> Syntax: .greet \[on-join greet message\]\r"
      return 0
   }
   setuser ${handle} xtra GREETDCC ${greetmsg}
   putdcc ${idx} "\002FN\002> ${handle}: Your greet message is now set to: ${greetmsg}\r"
   putcmdlog "#$handle# greet ${greetmsg}"
}

bind dcc - url dcc:seturl
proc dcc:seturl {handle idx text} {
   set url [lrange ${text} 0 end]
   if {${url} == ""} {
      putdcc ${idx} "\002FN\002> Syntax: .url \[www.your.url\]\r"
      return 0
   }
   setuser ${handle} xtra URL ${url}
   putdcc ${idx} "\002FN\002> ${handle}: Your url address is now set to: ${url}\r"
   putcmdlog "#$handle# url ${url}"
}

bind dcc - email dcc:setemail
proc dcc:setemail {handle idx text} {
   set email [lrange ${text} 0 end]
   if {${email} == ""} {
      putdcc ${idx} "\002FN\002> Syntax: email \[u@h\]\r"
      return 0
   }
   setuser ${handle} xtra EMAIL ${email}
   putdcc ${idx} "\002FN\002> ${handle}: .Your e-mail address is now set to: ${email}\r"
   putcmdlog "#$handle# email ${email}"
}

bind dcc - icq dcc:seticq
proc dcc:seticq {handle idx text} {
   set icquin [lrange ${text} 0 end]
   if {${icquin} == ""} {
      putdcc ${idx} "\002FN\002> Syntax: .icq \[icq-uin\]\r"
      return 0
   }
   setuser ${handle} xtra ICQ ${icquin}
   putdcc ${idx} "\002FN\002> ${handle}: Your icq number is now set to: ${icquin}\r"
   putcmdlog "#$handle# icq ${icquin}"
}

bind dcc - broadcast dcc:broadcast
proc dcc:broadcast {hand idx message} {
  if {${message} == ""} {
     putdcc ${idx} "\002FN\002> Syntax: .broadcast \[message\]\r"
     return 0
  }
  dccbroadcast "\[\002Announcement\002\] ${hand}: ${message}"
  return 1
}

######### Log and display all TCL commands (if enabled)

bind filt n ".tcl*" filt:tcl_log
proc filt:tcl_log {idx cmd} {
   global tcl-status owner
   set user [idx2hand ${idx}]
   if {!${tcl-status}} {
     putdcc ${idx} "\002FN\002> ${user}: .tcl commands are disabled.\r"
   } else {
     if {[string toupper ${user}] != [string toupper ${owner}]} {
       putdcc ${idx} "\002FN\002> ${user}: You are not authorised. Current authorised owners: ${owner}.\r"
     } else {
	 putcmdlog "\002FN\002> #${user}# ${cmd}"
       return ${cmd}
     }
   }
}

bind filt n ".set*" filt:set_log
proc filt:set_log {idx cmd} {
   global set-status owner
   set user [idx2hand ${idx}]
   if {!${set-status}} {
     putdcc ${idx} "\002FN\002> ${user}: .set commands are disabled.\r"
   } else {
     if {[string toupper ${user}] != [string toupper ${owner}]} {
       putdcc ${idx} "\002FN\002> ${user}: You are not authorised. Current authorised owners: ${owner}.\r"
     } else {
       return ${cmd}
     }
   }
}

######### Permanent owner protection

bind dcc m "-user" dcc:unuser
proc dcc:unuser {han idx user} {
   global owner botnick
   if {${user} == ""} {
       putdcc ${idx} "\002FN\002> Syntax: -user \[handle\]\r"
       return 0
   }
   if {![validuser ${user}]} {
       putdcc ${idx} "\002FN\002> -Failed- ${han}: ${user} not found on userfile.\r"
       return 0
   }
   if {[string toupper ${user}] == [string toupper ${owner}] && [string toupper ${han}] != [string toupper ${owner}]} {
       putdcc ${idx} "\002FN\002> -Failed- ${han}: ${owner} is a permanent owner of this bot.\r"
	 sendnote ${botnick} ${owner} "\002FN\002> User: ${han} attempted to delete your record."
   } else {
       deluser ${user}
	 putdcc ${idx} "\002FN\002> Removed user: ${user}.\r"
   }
}

bind dcc m "chnick" dcc:chnick
proc dcc:chnick {han idx user} {
   global owner botnick
   if {[lindex ${user} 0] == "" || [lindex ${user} 1] == ""} {
       putdcc ${idx} "\002FN\002> Syntax: chnick \[old-handle\] \[new-handle\]\r"
       return 0
   }
   if {![validuser [lindex $user 0]]} {
       putdcc ${idx} "\002FN\002> -Failed- ${han}: [lindex $user 0] not found on userfile.\r"
	 return 0
   }
   if {[validuser [lindex $user 1]]} {
       putdcc ${idx} "\002FN\002> -Failed- ${han}: [lindex $user 1] already exists.\r"
       return 0
   }
   if {[string toupper [lindex ${user} 0]] == [string toupper ${owner}] ||
       [string toupper [lindex ${user} 1]] == [string toupper ${owner}]} {
       putdcc ${idx} "\002FN\002> -Failed- ${han}: ${owner} is a permanent owner of this bot.\r"
	 sendnote ${botnick} ${owner} "\002FN\002> User: ${han} attempted a nick change on you."
   } else {
       chnick [lindex $user 0] [lindex $user 1]
	 putdcc ${idx} "\002FN\002> Changed nick: [lindex ${user} 0] -> [lindex $user 1].\r"
   }
}

######## FUNCTIONS

proc sub:ai-privmsg {} {
   putserv "PRIVMSG /null :*A*"
   timer [expr [rand 5] + 1] sub:ai-privmsg
}

proc sub:check-host {host nick chan ident} {
   if {!${ident}} {
      append nickhost ${nick} "!" [string tolower [getchanhost ${nick} ${chan}]]
      set hmask [maskhost ${nickhost}]
      if {[string first @ ${hmask}]<12} {
         set hmask "*!*[string range ${hmask} 2 [string length ${hmask}]]"
      }
   } else {
      scan [string tolower [getchanhost ${nick} ${chan}]] "%\[^@]@%s" host host
      set hmask "*!*@${host}"
   }
   return ${hmask}
}

proc sub:chan-rec {channel} {
   global def-chanmode def-choptions def-flood-chan def-flood-deop def-flood-kick def-flood-ctcp def-flood-join 
   if {![validchan ${channel}]} {
      channel add ${channel} ${def-choptions}
      channel set ${channel} chanmode ${def-chanmode}
      channel set ${channel} flood-chan ${def-flood-chan}
      channel set ${channel} flood-deop ${def-flood-deop}
      channel set ${channel} flood-kick ${def-flood-kick}
      channel set ${channel} flood-ctcp ${def-flood-ctcp}
      channel set ${channel} flood-join ${def-flood-join}
   }
}

######## FLOOD Protection
## Future.

######## INVITES Auto user
## Future.

######## VOICE User privaledges
## Future.

######## USER Levels, and authorised owner privaledges
## Future.

######## BOTNET Stats, and further botnet commands
## Future.

######## SCRIPT LOAD CONFIRMATION

if {$numversion <= 1029999} {
    putlog "+ Error loading script, for Eggdrop 1.3.x only lamah's."
}
putlog "Tcl loaded: Fusion v${fn-ver}. -AndrewX (andrew@daftpunk.org)"
