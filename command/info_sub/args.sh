# -*- shell-script -*-
# gdb-like "info args" debugger command
#
#   Copyright (C) 2011 Rocky Bernstein <rocky@gnu.org>
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

# Print info args. Like GDB's "info args"
# $1 is an additional offset correction - this routine is called from two
# different places and one routine has one more additional call on top.
# This code assumes the's debugger version of
# bash where FUNCNAME is an array, not a variable.

if [[ ${0##*/} == ${.sh.file##*/} ]] ; then
    src_dir=${.sh.file%/*}
    top_dir=${src_dir}/../..
    source ${top_dir}/lib/help.sh
fi

_Dbg_help_add_sub info args \
"info args [FRAME-NUM]

Show argument variables of the current stack frame.

The default value is 0, the most recent frame.

See also \"backtrace\"." 1

_Dbg_do_info_args() {

    typeset -i frame_start=${1:-0}
    
    # if (($#)) && [[ $frame_start != [+-]?[0-9]* ]]; then
    # 	_Dbg_errmsg "Bad integer parameter: $frame_start"
    # 	return 1
    # fi
    
    (( frame_start > .sh.level )) && return 1
    ( 
	## FIXME: magic number 6 is the number of internal calls
	## inside the debugger. 
	((.sh.level-=($frame_start+6)))
	typeset -i arg_count; arg_count=$#
	if (($# == 0)) ; then
	    _Dbg_msg "Argument count is 0 for this call."
	else
	    typeset -i j; j=0
	    for val in "$@" ; do 
		((j++))
		msg=$(printf "\$%d = %q" j "$val")
		_Dbg_msg $msg
	    done
	fi
    )
    return 0
}

# Demo it
if [[ ${0##*/} == ${.sh.file##*/} ]] ; then
    # FIXME: put some of this into a mock
    _Dbg_libdir=${top_dir}
    for _Dbg_file in pre ; do 
	source ${top_dir}/init/${_Dbg_file}.sh
    done
    for _Dbg_file in frame msg file journal save-restore alias ; do 
	source ${top_dir}/lib/${_Dbg_file}.sh
    done
    source ${top_dir}/command/help.sh
    # _Dbg_args='info'
    # _Dbg_do_help info args
    # _Dbg_do_info_args
fi
