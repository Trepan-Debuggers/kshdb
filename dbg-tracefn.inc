# -*- shell-script -*-
PS4='(${.sh.file}:${LINENO}): ${.sh.fun} - [${.sh.subshell}]
+ '

# Wrap "set -x .. set +x" around a call to function $1.
# The wrapped function becomes the new function and the original
# function is called old_$1.
function trace_fn {
    typeset -r fn=$1
    cmd=$(typeset -pf $fn | sed -e 's/^typeset /old_/')
    (($debug)) && echo $cmd 
    eval "$cmd"
    cmd="function $1 { 
    set -x; 
    old_$fn \$*; 
    }
"
    (($debug)) && echo $cmd 
    eval "$cmd"
}

function untrace_fn {
    typeset -r fn=$1
    cmd=$(typeset -pf old_$fn | sed -e "s/^typeset old_$fn/$fn/")
    eval "$cmd"
}
