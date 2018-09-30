# -*- shell-script -*-
# hook.sh - Debugger trap hook
#
#
#   Copyright (C) 2002-2004, 2006-2011, 2018
#   Rocky Bernstein <rocky@gnu.org>
#
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation; either version 2, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; see the file COPYING.  If not, write to
#   the Free Software Foundation, 59 Temple Place, Suite 330, Boston,
#   MA 02111 USA.

typeset _Dbg_RESTART_COMMAND=''

# This is set to 1 if you want to debug debugger routines, i.e. routines
# which start _Dbg_. But you better should know what you are doing
# if you do this or else you may get into a recursive loop.
typeset -i _Dbg_debug_debugger=0

typeset -i _Dbg_set_debug=0       # 1 if we are debug the debugger
typeset    _Dbg_stop_reason=''    # The reason we are in the debugger.

# Set to 0 to clear "trap DEBUG" after entry
typeset -i _Dbg_restore_debug_trap=1

# Are we inside the middle of a "skip" command? If so this gets copied
# to _Dbg_continue_rc which controls the return code from the trap.
typeset -i _Dbg_inside_skip=0

# If _Dbg_continue_rc is not less than 0, continue execution of the
# program. As specified by the shopt extdebug option. See extdebug of
# "The Shopt Builtin" in the bash info guide. The information
# summarized is:
#
# - A return code 2 is special and means return from a function or
#   "source" command immediately
#
# - A nonzero return indicate the next statement should not be run.
#   Typically we use 1 for that value.
# - A set return code 0 continues execution.
typeset -i _Dbg_continue_rc=-1

typeset -i _Dbg_set_debug=0       # 1 if we are debugging the debugger
typeset    _Dbg_stop_reason=''    # The reason we are in the debugger.

typeset -i _Dbg_QUIT_LEVELS=0     # Number of nested shells we have to exit

# Return code that debugged program reports
typeset -i _Dbg_program_exit_code=0

# This is the main hook routine that gets called before every statement.
# It's the function called via trap DEBUG.
function _Dbg_trap_handler {

    # Save old set options before destroying them
    _Dbg_old_set_opts=$-

    # Turn off line and variable trace listing.
    ((!_Dbg_set_debug)) && set +x
    set +v +u +e

    _Dbg_set_debugger_entry 'create_unsetopt'
    typeset -i _Dbg_debugged_exit_code=$1
    shift

    # Place to save values of $1, $2, etc.
    typeset -a _Dbg_arg
    _Dbg_arg=($@)

    typeset -i _Dbg_skipping_fn
    ((_Dbg_skipping_fn =
	    (_Dbg_return_level >= 0 &&
	     .sh.level > _Dbg_return_level) ))
    # echo "${#funcfiletrace[@]} vs $_Dbg_return_level ; $_Dbg_skipping_fn"

    # if in step mode, decrement counter
    if ((_Dbg_step_ignore > 0)) ; then
	if ((! _Dbg_skipping_fn )) ; then
	    ((_Dbg_step_ignore--))
	    _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"
	    # Can't return here because we may want to stop for another
	    # reason.
	fi
    fi

    if ((_Dbg_skip_ignore > 0)) ; then
	if ((! _Dbg_skipping_fn )) ; then
	    ((_Dbg_skip_ignore--))
	    _Dbg_write_journal "_Dbg_skip_ignore=$_Dbg_skip_ignore"
	    _Dbg_set_to_return_from_debugger 2
	    return 2 # 2 indicates skip statement.
	fi
    fi

    # Determine if we stop or not.

    # Check breakpoints.
    if ((_Dbg_brkpt_count > 0)) ; then
	_Dbg_frame_save_frames 1
	if _Dbg_hook_breakpoint_hit ; then
	    if ((_Dbg_step_force)) ; then
		typeset _Dbg_frame_previous_file="$_Dbg_frame_last_filename"
		typeset -i _Dbg_frame_previous_lineno="$_Dbg_frame_last_lineno"
	    fi
	    (( _Dbg_brkpt[_Dbg_brkpt_num].hits++ ))
	    _Dbg_msg "Breakpoint $_Dbg_brkpt_num hit."
	    if (( _Dbg_brkpt[_Dbg_brkpt_num].onetime == 1 )) ; then
		_Dbg_stop_reason='at a breakpoint that has since been deleted'
		_Dbg_delete_brkpt_entry $_Dbg_brkpt_num
	    else
		_Dbg_stop_reason="at breakpoint $_Dbg_brkpt_num"
	    fi
	    _Dbg_hook_enter_debugger "$_Dbg_stop_reason"
	    return $?
	fi
    fi

    # Check if step mode and number of steps to ignore.
    if ((_Dbg_step_ignore == 0 && ! _Dbg_skipping_fn )); then

	if ((_Dbg_step_force)) ; then
	    typeset _Dbg_frame_previous_file="$_Dbg_frame_last_file"
	    typeset -i _Dbg_frame_previous_lineno="$_Dbg_frame_last_lineno"
	    ((_Dbg_brkpt_count == 0)) && _Dbg_frame_save_frames 1
	    if ((_Dbg_frame_previous_lineno == _Dbg_frame_last_lineno)) && \
		[ "$_Dbg_frame_previous_file" = "$_Dbg_frame_last_file" ] ; then
		_Dbg_set_to_return_from_debugger 1
		return $_Dbg_rc
	    fi
	else
	    _Dbg_frame_save_frames 1
	fi

	_Dbg_hook_enter_debugger 'after being stepped'
	return $?

    fi
    if ((_Dbg_set_linetrace)) ; then
	if ((_Dbg_linetrace_delay)) ; then
	    sleep $_Dbg_linetrace_delay
	fi

	_Dbg_frame_save_frames 1
	_Dbg_print_location_and_command
    fi
    _Dbg_set_to_return_from_debugger
    return 0
}

# Return 0 if we are at a breakpoint position or 1 if not.
# Sets _Dbg_brkpt_num to the breakpoint number found.
function _Dbg_hook_breakpoint_hit {
    typeset full_filename=${_Dbg_frame_last_filename}
    typeset lineno=${_Dbg_frame_last_lineno}
    # FIXME: combine with _Dbg_unset_brkpt
    typeset -a linenos
    [[ -z "$full_filename" ]] && return 1
    linenos=(${_Dbg_brkpt_file2linenos[$full_filename]})
    typeset -a brkpt_nos
    brkpt_nos=(${_Dbg_brkpt_file2brkpt[$full_filename]})
    typeset -i _Dbg_i
    for ((_Dbg_i=0; _Dbg_i < ${#linenos[@]}; _Dbg_i++)); do
	if (( linenos[_Dbg_i] == lineno )) ; then
	    # Got a match, but is the breakpoint enabled and condition met?
 	    (( _Dbg_brkpt_num = brkpt_nos[_Dbg_i] ))
 	    if ((_Dbg_brkpt[_Dbg_brkpt_num].enable )) ; then
 		return 0
 	    fi
 	fi
    done
    return 1
}

# Go into the command loop
_Dbg_hook_enter_debugger() {
    _Dbg_stop_reason="$1"
    _Dbg_print_location_and_command
    _Dbg_process_commands
    _Dbg_set_to_return_from_debugger $?
    return $_Dbg_rc # _Dbg_rc set to $? by above
}

# Cleanup routine: erase temp files before exiting.
_Dbg_cleanup() {
    [[ -f $_Dbg_evalfile ]] && rm -f $_Dbg_evalfile 2>/dev/null
    _Dbg_erase_journals
    _Dbg_restore_user_vars
}

# Somehow we can't put this in _Dbg_cleanup and have it work.
# I am not sure why.
_Dbg_cleanup2() {
    [[ -f "$_Dbg_evalfile" ]] && rm -f "$_Dbg_evalfile" 2>/dev/null
    _Dbg_erase_journals
    trap - EXIT
}
