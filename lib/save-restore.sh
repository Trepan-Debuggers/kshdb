# -*- shell-script -*-
#  Save and restore user settings
#
#   Copyright (C) 2008, 2011 Rocky Bernstein <rocky@gnu.org>
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

# Does things debugger entry of after an eval to set some debugger
# internal settings
_Dbg_set_debugger_internal() {
  IFS="$_Dbg_space_IFS";
  PS4='(${.sh.file}:${.sh.lineno}:[${.sh.subshell}]): ${.sh.fun}
'
  HISTFILE=$_Dbg_histfile
  HISTSIZE=$_Dbg_history_length
}

typeset _Dbg_old_histfile
typeset _Dbg_old_histsize

function _Dbg_restore_user_vars {
  IFS="$_Dbg_space_IFS";
  set -$_Dbg_old_set_opts
  IFS="$_Dbg_old_IFS";
  PS4="$_Dbg_old_PS4"
  HISTFILE=$_Dbg_old_histfile
  HISTSIZE=$_Dbg_old_histsize
}

# Do things for debugger entry. Set some global debugger variables
# Remove trapping ourselves.
# We assume that we are nested two calls deep from the point of debug
# or signal fault. If this isn't the constant 2, then consider adding
# a parameter to this routine.
_Dbg_set_debugger_entry() {

    _Dbg_rc=0
    _Dbg_return_rc=0
    _Dbg_old_IFS="$IFS"
    _Dbg_old_PS4="$PS4"
    _Dbg_old_histfile=$HISTFILE
    _Dbg_set_debugger_internal
    _Dbg_source_journal
    if (( _Dbg_QUIT_LEVELS > 0 )) ; then
	_Dbg_do_quit $_Dbg_debugged_exit_code
    fi
}

function _Dbg_set_to_return_from_debugger {
  _Dbg_rc=$?

  _Dbg_brkpt_num=0
  _Dbg_stop_reason=''
#   if (( $1 != 0 )) ; then
#     _Dbg_last_ksh_command="$_Dbg_ksh_command"
#     _Dbg_last_frame_lineno="$_Dbg_frame_lineno"
#     _Dbg_last_source_file="${.sh.file}"
#   else
#     _Dbg_last_frame_lineno==${KSH_LINENO[1]}
#     _Dbg_last_source_file=${KSH_SOURCE[2]:-$_Dbg_bogus_file}
#     _Dbg_last_ksh_command="**unsaved _kshdb command**"
#   fi

  _Dbg_restore_user_vars
}

_Dbg_save_state() {
  _Dbg_statefile=$(_Dbg_tempname statefile)
  echo '' > $_Dbg_statefile
  _Dbg_save_breakpoints
  _Dbg_save_actions
  _Dbg_save_watchpoints
  _Dbg_save_display
  _Dbg_save_Dbg_set
  echo "unset DBG_RESTART_FILE" >> $_Dbg_statefile
  echo "rm $_Dbg_statefile" >> $_Dbg_statefile
  export DBG_RESTART_FILE="$_Dbg_statefile"
  _Dbg_write_journal "export DBG_RESTART_FILE=\"$_Dbg_statefile\""
}

_Dbg_save_Dbg_set() {
  declare -p _Dbg_set_basename     >> $_Dbg_statefile
  declare -p _Dbg_debug_debugger   >> $_Dbg_statefile
  declare -p _Dbg_edit             >> $_Dbg_statefile
  declare -p _Dbg_set_listsize     >> $_Dbg_statefile
  declare -p _Dbg_prompt_str       >> $_Dbg_statefile
  declare -p _Dbg_set_show_command >> $_Dbg_statefile
}

_Dbg_restore_state() {
  typeset statefile=$1
  . $1
}

# Things we do when coming back from a nested shell.
# "shell", and "debug" create nested shells.
_Dbg_restore_from_nested_shell() {
    rm -f $_Dbg_shell_temp_profile 2>&1 >/dev/null
    if [[ -r $_Dbg_restore_info ]] ; then
	. $_Dbg_restore_info
	rm $_Dbg_restore_info
    fi
}
