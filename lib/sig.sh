# sig.sh - Debugger Signal handling routines
#
#   Copyright (C) 2008 Rocky Bernstein rocky@gnu.org
#
#   zshdb is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   zshdb is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with zshdb; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

function _Dbg_debug_trap_handler {
    typeset -i _Dbg_debugged_exit_code=$?
    _Dbg_old_set_opts=$-

    # Place to save values of $1, $2, etc.
    typeset -a _Dbg_arg
    _Dbg_arg=($@)

    # Turn off line and variable trace listing if were not in our own debug
    # mode, and set our own PS4 for debugging inside the debugger
    (( !_Dbg_debug_debugger )) && set +x +v +u

    # if in step mode, decrement counter
    if ((_Dbg_step_ignore >= 0)) ; then 
	((_Dbg_step_ignore--))
	_Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"
    fi

    if ((_Dbg_skip_ignore > 0)) ; then
	((_Dbg_skip_ignore--))
	_Dbg_write_journal "_Dbg_step_ignore=$_Dbg_skip_ignore"
    fi

    # Determine if we stop or not. 

    # next, check if step mode and no. of steps is up
    if ((_Dbg_step_ignore == 0)); then
	_Dbg_stop_reason='after being stepped'
	
	# If we don't have to stop we might consider skipping 
	_Dbg_set_debugger_entry
	
	save_callstack 1
	_Dbg_print_location
	# _Dbg_process_commands
	_Dbg_set_to_return_from_debugger 1
	return $_Dbg_rc
    else
	save_callstack 1
    fi

   print_callstack
}
