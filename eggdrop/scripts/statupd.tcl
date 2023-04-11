# -AndrewX

set statlist { "chat" }
set time-interval 1440
set statday 0
set statmonth [exec date +%m]
set statyear [exec date +%Y]

foreach i [timers] {
  if {[join [lrange [split ${i}] 1 1]] == "stat_update"} {
   killtimer [lrange [split ${i}] 2 2]]
  }
}

timer ${time-interval} stat_update

proc stat_update {} {
   global time-interval statlist statday statmonth statyear
   timer ${time-interval} stat_update
   set statday [expr [exec date +%d] - 1]
   foreach x ${statlist} {
     exec ./ircstats logs/#${x}.$statmonth.$statday.$statyear.log ${x}.cfg
     exec rm logs/#${x}.$statmonth.$statday.$statyear.log
   }
   putlog "Updating statistics (${time-interval} minute interval)."
}

putlog "Tcl loaded: IRCStats auto-update. -AndrewX (andrew@daftpunk.org)"

