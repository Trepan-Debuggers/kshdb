set trace-commands on
# Test break, watch, watche, step, next, continue and stack handling
#
###  Try a simple display...
display $x
break 23
break 25
cont
cont
###  Try disabling display ...
disable display 0
info display
step
cont
###  Try enabling display ...
enable display 0
info display
###  Try display to show again status ...
display
cont 28
info display
cont
###  Try undisplay to delete ...
undisplay
undisplay 0
info display
step
step
###  quitting...
quit
