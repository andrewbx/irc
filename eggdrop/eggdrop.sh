#!/home/nightowl/egg/eggdrop

#---------------------------------------------------------
# Add static channels to the list here. -Andrew
# Updated for 1.4.x [23/02/2000]

set chanlist { "#chat" "#muzik" }
set homepath "/home/nightowl/egg"
set nick "Night0wl"
set altnick "N|ght0wl"
set realname "To \002party\002 until I \002drop\002..."
set username "nightowl"
set hellopasswd "xxxxxx"
set my-hostname "localhost"
set my-ip "127.0.0.1"
#---------------------------------------------------------

set admin "\002Andrew\002 \[email: andrew@localhost\]"
set network "IRCNET"
set timezone "GMT"
set offset 0
set env(TZ) "${timezone} ${offset}"
#addlang "english"

set max-logs 180
set max-logsize 0
set quick-logs 0
logfile kjs * "${homepath}/logs/${nick}_kjs.log"
logfile mcbo * "${homepath}/logs/${nick}_mcbo.log"
set log-time 1
set keep-all-logs 0
set switch-logfiles-at 360
set quiet-save 1
set console "mcobs"

set userfile "${nick}.users"
set sort-users 0
set help-path "${homepath}/help/"
set temp-path "/tmp"
set motd "motd"
set telnet-banner "telnet-banner"

#set botnet-nick "${nick}"
set protect-telnet 0
set dcc-sanitycheck 0
set ident-timeout 40
listen 12300 bots
listen 12400 users
set require-p 0
set open-telnets 0
set stealth-telnets 1
set use-telnet-banner 1
set connect-timeout 30
set dcc-flood-thr 12
set telnet-flood 5:60
set paranoid-telnet-flood 1
set resolve-timeout 15

#set firewall "proxy:178"
#set firewall "!sun-barr.ebay:3666"
#set nat-ip "127.0.0.1"
#set reserved-port 9076

set ignore-time 25
set debug-output 0
set hourly-updates 00
set owner "Andrew"
set notify-newusers "${owner}"
set must-be-owner 0
set default-flags "hp"
#set whois-fields "url birthday"

set remote-boots 2
set share-unlinks 1
set die-on-sighup 0
set die-on-sigterm 0
set max-dcc 50
set dcc-portrange 1024:65535
set enable-simul 0
set allow-dk-cmds 1

set mod-path "${homepath}/modules/"

loadmodule channels
set chanfile "${nick}.chans"
set ban-time 360
set exempt-time 0
set invite-time 0
set force-expire 0
set share-greet 1
set use-info 1

set global-flood-chan 15:10
set global-flood-deop 5:10
set global-flood-kick 5:10
set global-flood-join 5:30
set global-flood-ctcp 4:60
set global-chanmode "nt"

set global-chanset {
        +clearbans      +enforcebans
        +dynamicbans    +userbans
        -autoop         +bitch
        -greet          +protectops
        -statuslog      +stopnethack
        -revenge        -secret
        -autovoice      +cycle
        +dontkickops    -wasoptest
        -inactive       -protectfriends
        +shared         -seen
	+userexempts	+dynamicexempts
	+userinvites	+dynamicinvites
}

foreach x ${chanlist} {
   channel add ${x} {
      chanmode "+${global-chanmode}"
      idle-kick 0
      need-op { gain_entrance op ${x} }
      need-invite { gain_entrance invite ${x} }
      need-key { gain_entrance key ${x} }
      need-unban { gain_entrance unban ${x} }
      need-limit { gain_entrance limit ${x} }
      flood-chan ${global-flood-chan}
      flood-deop ${global-flood-deop}
      flood-kick ${global-flood-kick}
      flood-join ${global-flood-join}
      flood-ctcp ${global-flood-ctcp}
   }
   channel set ${x} +clearbans +enforcebans +dynamicbans +userbans -autoop +bitch -greet +protectops
   channel set ${x} -statuslog +stopnethack -revenge -secret -autovoice +cycle +dontkickops -wasoptest
   channel set ${x} -inactive -protectfriends +shared -seen +userexempts +dynamicexempts +userinvites +dynamicinvites
}

loadmodule server
set net-type 1
set init-server { putserv "MODE ${botnick} +iw-s" }
set servers {
   Uni-Erlangen.DE:6669
   irc.stealth.net:5558
}  

set keep-nick 1
set use-ison 1
set strict-host 0
set quiet-reject 1
set lowercase-ctcp 0
set answer-ctcp 1
set flood-msg 3:30
set flood-ctcp 3:30
set never-give-up 1
set strict-servernames 0
set default-port 6667
set server-cycle-wait 60
set server-timeout 20
set servlimit 0
set check-stoned 1
set use-console-r 0
set debug-output 0
set serverror-quit 1
set max-queue-msg 300
set trigger-on-ignore 0
set double-mode 0
set double-server 0
set double-help 0
#set use-silence 1
#set check-mode_r 1

#loadmodule bitchx

loadmodule ctcp
set ctcp-version "ircII 4.4G+ScrollZ v1.8i4/Public (5.3.99)+Cdcc v1.8+AcidMods v2.0 - \002F\002usio\002N\002/S\002Z\002 0.5b (24/04/99) -Andrew"
set ctcp-finger "FusioN"
set ctcp-userinfo "FusioN"
set ctcp-mode 1

loadmodule irc
set bounce-bans 1
set bounce-modes 0
set kick-bogus-bans 0
set bounce-bogus-bans 0
set max-bans 20
set max-modes 30
set allow-desync 0
set kick-method 4
set learn-users 0
set kick-bogus 0
set ban-bogus 0
set kick-fun 0
set ban-fun 0
set no-chanrec-info 1
set wait-split 300
set wait-info 60
set bounce-exempts 0
set bounce-invites 0
set max-exempts 0
set max-invites 0
set bounce-bogus-exempts 0
set kick-bogus-exempts 0
set bounce-bogus-invites 0
set kick-bogus-invites 0
set use-exempts 1
set use-invites 1
set prevent-mixing 1
set kick-method 4
set modes-per-line 3
set mode-buf-length 200
set use-354 0
set rfc-compliant 1
set no-chanrec-info 0
set revenge-mode 1
unbind msg - hello *msg:hello
bind msg - ${hellopasswd} *msg:hello

loadmodule transfer
set max-dloads 3
set dcc-block 0
set copy-to-tmp 1
set xfer-timeout 120

loadmodule share
set allow-resync 0
set resync-time 900
set private-owner 0
set private-global 0 
set private-user 0
#set private-globals "mnot"

#loadmodule filesys
#set files-path "${homepath}/files"
#set incoming-path "${homepath}/files/incoming"
#set upload-to-pwd 0
#set filedb-path ""
#set max-file-users 15
#set max-filesize 1024

loadmodule notes
set notefile "${nick}.notes"
set max-notes 50
set note-life 60
set allow-fwd 1
set notify-users 1
set notify-onjoin 1

loadmodule console
set console-autosave 1
set force-channel 0
set info-party 0

checkmodule blowfish

#loadmodule seen
#loadmodule assoc
#loadmodule wire

source "${homepath}/scripts/fusion-init.tcl"
