set trace-commands on
set basename on
# Make sure autostep is off for next text
set different off
show different
next
where 1
n
where 1
# Test that next+ skips multiple statements
next+
where 1
# Same thing - but should stop at 2nd statement in line
next 
where 1
next
where 1
# Now check with set different on
set different on
show different
next
where 1
# Override different
next-
where 1
n-
where 1
# A null command should use the last next

where 1

next 
where 1
# Try a null command the other way
n+
where 1

where 1
quit



