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

# Last search pattern used.
typeset _Dbg_last_search_pat

# current line to be listed
typeset -i _Dbg_listline=-1

_Dbg_list() {
    typeset filename
    if (( $# > 0 )) ; then
	filename=$1
    else
	filename=$_Dbg_frame_last_filename
    fi

    if [[ $2 = '.' ]]; then
	_Dbg_listline=$Dbg_frame_last_lineno
    elif [[ -n $2 ]] ; then
      _Dbg_listline=$2
    else
	_Dbg_listline=$_Dbg_frame_last_lineno
    fi
    (( _Dbg_listline==0 )) && ((_Dbg_listline++))

    typeset -i cnt
    cnt=${3:-$_Dbg_listsize}
    typeset -i n
    n=$((_Dbg_listline+cnt-1))

    _Dbg_readin_if_new "$filename"

    typeset -i max_line
    max_line=$(_Dbg_get_maxline $filename)
    if (( $? != 0 )) ; then
	_Dbg_errmsg "internal error getting number of lines in $filename"
	return 1
    fi

    if (( _Dbg_listline > max_line )) ; then
      _Dbg_errmsg \
	"Line number $_Dbg_listline out of range;" \
      "$filename has $max_line lines."
      return 1
    fi

    typeset source_line
    typeset frame_fullfile
    frame_fullfile=${_Dbg_file2canonic[$_Dbg_frame_last_filename]}
    
    for ((  ; (( _Dbg_listline <= n && _Dbg_listline <= max_line )) \
            ; _Dbg_listline++ )) ; do
     typeset prefix='    '
     _Dbg_get_source_line $_Dbg_listline $filename

       (( _Dbg_listline == _Dbg_frame_last_lineno )) \
         && [[ $fullname == $frame_fullfile ]] &&  prefix=' => '
      _Dbg_printf "%3d:%s%s" $_Dbg_listline "$prefix" "$source_line"
    done
    (( _Dbg_listline > max_line && _Dbg_listline-- ))
    return 0
}

_Dbg_list_typeset_attr() {
    typeset -a columize_list=( $(_Dbg_get_typeset_attr $*) )
    typeset -i rc=$?
    (( $rc != 0 )) && return $rc
    _Dbg_list_columns columnize_list
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
