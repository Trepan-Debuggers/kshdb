# -*- shell-script -*-
#
#   Copyright (C) 2008 Rocky Bernstein rocky@gnu.org
#
#   kshdb is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   kshdb is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with kshdb; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

# Wrap "set -x .. set +x" around a call to function $1.
# Normally we also save and restrore any trap DEBUG functions. However
# If $2 is 0 we will won't.
# The wrapped function becomes the new function and the original
# function is called old_$1.
# $? is 0 if successful.

_Dbg_help_add trace \
'trace *function*	- Wrap *function* in set -x'

function _Dbg_do_trace_fn {
    if (($# == 0)) ; then
	_Dbg_errmsg "trace_fn: missing function name."
	return 2
    fi
    typeset fn=$1
    typeset -i clear_debug_trap=${2:-1}
    _Dbg_is_function "$fn" 1 || {
	_Dbg_errmsg "trace_fn: function \"$fn\" is not a function."
	return 3
    }
    cmd=old_$(typeset -f -- "$fn") || {
	return 4
    }
    ((_Dbg_set_debug)) && print "$cmd"
    typeset save_clear_debug_trap_cmd=''
    typeset restore_trap_cmd=''
    if (( clear_debug_trap )) ; then
	save_clear_trap_cmd='typeset old_handler=$(trap -p DEBUG); trap - DEBUG'
	restore_trap_cmd='eval $old_handler'
    fi
    eval "$cmd" || return 5
    cmd="${fn}() { 
    $save_clear_trap_cmd;
    typeset -i old_set_x=is_traced;
    set -x;
    old_$fn \"\$@\";
    typeset -i rc=\$?;
    (( old_set_x == 0 )) && set +x; # still messes up of fn did: set -x
    $restore_trap_cmd;
    return \$rc
    }
"
    ((_Dbg_debug_debugger)) && echo "$cmd"
    eval "$cmd" || return 6
    return 0
}

_Dbg_help_add untrace \
'untrace *function*	untrace previosly traced *function*'

# Undo wrapping fn
# $? is 0 if successful.
function _Dbg_do_untrace_fn {
    typeset fn=$1
    if [[ -z $fn ]] ; then
	_Dbg_errmsg "untrace_fn: missing or invalid function name."
	return 2
    fi
    _Dbg_is_function "$fn" || {
	_Dbg_errmsg "untrace_fn: function \"$fn\" is not a function."
	return 3
    }
    _Dbg_is_function "old_$fn" || {
	_Dbg_errmsg "untrace_fn: old function old_$fn not seen - nothing done."
	return 4
    }
    cmd=$(typeset -f -- "old_$fn") || return 5
    cmd=${cmd#old_}
    ((_Dbg_debug_debugger)) && echo $cmd 
    eval "$cmd" || return 6
    return 0
}
