set trace-commands on
# Test that "skip" skips the function call
skip
where 1
# Test "skip" with a count
skip 2
where 1
quit
