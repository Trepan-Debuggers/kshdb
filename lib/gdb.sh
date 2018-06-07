# -*- shell-script -*-
# routines that seem tailored more to the gdb-style of doing things.
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
#   along with This program; see the file COPYING.  If not, write to
#   the Free Software Foundation, 59 Temple Place, Suite 330, Boston,
#   MA 02111 USA.

# Print location in gdb-style format: file:line
# So happens this is how it's stored in global _Dbg_frame_stack which
# is where we get the information from
function _Dbg_print_location {
    if (($# > 1)); then
      _Dbg_errmsg "got $# parameters, but need 0 or 1."
      return 2
    fi
    typeset -i pos=${1:-$_Dbg_stack_pos}
    typeset -n frame=_Dbg_frame_stack[pos]
    typeset filename=${frame.filename}
    _Dbg_readin "${filename}"
    typeset fun=${frame.fun}
    ((_Dbg_set_basename)) && filename=${filename##*/}
    _Dbg_msg "(${filename}:${frame.lineno}):"
}

function _Dbg_print_command {
    typeset msg
    if [[ -n $_Dbg_set_highlight ]] ; then
	msg=$(echo ${.sh.command} | python ${_Dbg_libdir}/lib/term-highlight.py)
    else
	msg=${.sh.command}
    fi
   _Dbg_msg "$msg"
}

function _Dbg_print_location_and_command {
    _Dbg_print_location $@
    # typeset -i .old_level=.sh.level
    # typeset -i new_level
    # ((new_level=${#_Dbg_frame_stack[@]} - 1 - $_Dbg_stack_pos))
    # (( .sh.level =  new_level ))
   _Dbg_print_command
   # (( .sh.level = ${.old_level} ))
}

# Print position $1 of stack frame (from global _Dbg_frame_stack)
# Prefix the entry with $2 if that's set.
_Dbg_print_frame() {
    typeset -i pos=${1:-$_Dbg_stack_pos}
    typeset prefix=${2:-''}

    [[ -z ${_Dbg_frame_stack[pos].filename} ]] && return 1

    _Dbg_frame_lineno $pos
    typeset -i ln=$?
    typeset _Dbg_frame_filename=''; _Dbg_frame_file $pos
    typeset loc=''
    typeset fun; fun=${_Dbg_frame_stack[pos].fun}
    # if [[ -n  $fun && \
    # 	  $fun != _Dbg_frame_stack[pos].filename ]] ; then
    # 	loc="${_Dbg_frame_stack[pos].fun} from "
    # fi
    _Dbg_msg "$prefix ${loc}file \`${_Dbg_frame_filename}' at line ${ln}"
}
