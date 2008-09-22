# -*- shell-script -*-
# list.sh - Bourne Again Shell Debugger list/search commands
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

_Dbg_list_typeset_attr() {
    typeset -a list
    list=( $(_Dbg_get_typeset_attr $*) )
    typeset -i rc=$?
    (( $rc != 0 )) && return $rc
    _Dbg_list_columns
}

_Dbg_list_columns() {
    typeset colsep='  '
    (($# == 0)) && return 1
    typeset to_do="$1"; shift
    (($# > 0 )) && { colsep="$1"; shift; }
    if (($# > 0 )) ; then 
	msg=_Dbg_errmsg
	shift
    else
	msg=_Dbg_msg
    fi
    (($# != 0)) && return 1
    typeset -a columnized=(); columnize $to_do $_Dbg_linewidth "$colsep"
    typeset -i i
    for ((i=0; i<${#columnized[@]}; i++)) ; do 
	$msg "  ${columnized[i]}"
    done

}
