set trace-commands on
# Make sure autostep is off for next text
set different off
show different
# Test that step+ skips multiple statements
step+
set different on 
show different
# Same thing - skip loop
step 
# Override different
step-
s-
# A null command should use the last step

step 
# Try a null command the other way
s+

quit



