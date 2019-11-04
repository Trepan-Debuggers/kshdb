# -*- shell-script -*-
# Set up to Debug into another script...
#
#   Copyright (C) 2019 Rocky Bernstein <rocky@gnu.org>
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

_Dbg_help_add debug \
"debug [*script*]

Set up *script* for debugging.

If *script* is not given, take the script name from the command that
is about to be executed. Note that when the nested debug finished, you
are still where you were prior to entering the debugger.
" 1

# TODO: would work better if instead of using $source_line below
# which might have several statements, we could just pick up the next
# single statement.
_Dbg_do_debug() {

    # _Dbg_shell_new_shell_profile

    typeset script_cmd=${@:-$_Dbg_last_ksh_command}
    if (( $# == 0 )) ; then
        script_cmd=$_Dbg_last_ksh_command
    fi

    # We need to expand variables that might be in $script_cmd.
    # set_Dbg_nested_debug_cmd is set up to to be eval'd below.
    typeset set_Dbg_debug_cmd="typeset _Dbg_debug_cmd=\"$script_cmd\"";

    export SHELL=${_Dbg_shell}

    eval "$_seteglob"
    # Add appropriate ksh debugging options
    if (( ! _Dbg_script )) ; then
	set_Dbg_debug_cmd="typeset _Dbg_debug_cmd=\"$SHELL --init-file ${_Dbg_shell_temp_profile} --debugger $script_cmd\"";
    elif [[ $_Dbg_orig_0/// == *kshdb/// ]] ; then
	# Running "kshdb", so prepend "ksh kshdb .."
	set_Dbg_debug_cmd="typeset _Dbg_debug_cmd=\"$SHELL $_Dbg_orig_0 -q -L $_Dbg_libdir $script_cmd\"";
    fi
    eval "$_resteglob"
    eval $set_Dbg_debug_cmd

    if (( _Dbg_set_basename )) ; then
	_Dbg_msg "Debugging new script with $script_cmd"
    else
	_Dbg_msg "Debugging new script with $_Dbg_debug_cmd"
    fi
    ((_Dbg_DEBUGGER_LEVEL++))
    ((_Dbg_QUIT_LEVELS++))
    $_Dbg_debug_cmd
    ((_Dbg_QUIT_LEVELS--))
    ((_Dbg_DEBUGGER_LEVEL--))
    # _Dbg_restore_from_nested_shell
}
