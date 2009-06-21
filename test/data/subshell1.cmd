set trace-commands on
### Test step inside multi-statement line...
p "SUBSHELL: ${.sh.subshell}"
step 
step
step 
### Should now be inside a subshell...
p "SUBSHELL: ${.sh.subshell}"
print "Test unconditional quit..."
quit

