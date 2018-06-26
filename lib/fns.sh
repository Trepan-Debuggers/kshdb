# -*- shell-script -*-
# fns.sh - Debugger Utility Functions
#
#   Copyright (C) 2008-2009, 2011-2012, 2018 Rocky Bernstein rocky@gnu.org
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

typeset -a _Dbg_yn
_Dbg_yn=("n" "y")

# Return $2 copies of $1. If successful, $? is 0 and the return value
# is in result.  Otherwise $? is 1 and result ''
_Dbg_copies() {
    result=''
    (( $# < 2 )) && return 1
    typeset string="$1"
    typeset -i count=$2 || return 2;
    (( count > 0 )) || return 3
    result=$(printf "%${count}s" ' ') || return 3
    result=${result// /$string}
    return 0
}

# _Dbg_defined returns 0 if $1 is a defined variable or 1 otherwise.
function _Dbg_defined {
    typeset -l xx
    xx=$(typeset -p "$1" 2>&1 /dev/null)
    if [[ -z $xx ]] ; then
	return 1
    else
	return 0
    fi
}

# Add escapes to a string $1 so that when it is read back using
# eval echo "$1" it is the same as echo $1.
function _Dbg_esc_dq {
    printf "%q" $1
}

# _Dbg_get_typeset_attr echoes a list of all of the functions matching
# optional pattern if $1 is nonzero, include debugger functions,
# i.e. those whose name starts with an underscore (_Dbg), are included in
# the search.
# A grep pattern can be specified to filter function names. If the
# pattern starts with ! we report patterns that don't match.
_Dbg_get_typeset_attr() {
    (( $# == 0 )) && return 1
    typeset attr="$1"; shift
    typeset pat=''
    (( $# > 0 )) && { pat=$1 ; shift; }
    (( $# != 0 )) && return 1

    typeset cmd="typeset $attr"
    if [[ -n $pat ]] ; then
	if [[ ${pat[0]} == '!' ]] ; then
	    cmd+=" | grep -v ${pat[1,-1]}"
	else
	    cmd+=" | grep $pat"
	fi
    fi
    ((!_Dbg_set_debug)) && cmd+=' | grep -v ^_Dbg_'
    eval $cmd
}

# We go through the array indirection below because bash (but not ksh)
# gives syntax errors when this is put in place.
typeset -a _Dbg_eval_re;
_Dbg_eval_re=(
    '^[ \t]*(if|elif)[ \t]+([^;]*)((;[ \t]*then?)?|$)'
    '^[ \t]*return[ \t]+(.*)$'
    '^[ \t]*while[ \t]+([^;]*)((;[ \t]*do?)?|$)'
    '^[ \t]*[A-Za-z_][A-Za-z_0-9[]*]?[-+]?=(.*$)'
)

# Removes "[el]if" .. "; then" or "while" .. "; do" or "return .."
# leaving resumably the expression part.  This function is called by
# the eval?  command where we want to evaluate the expression part in
# a source line of code
_Dbg_eval_extract_condition()
{
    orig="$1"
    if [[ $orig =~ ${_Dbg_eval_re[0]} ]] ; then
	extracted=${.sh.match[2]}
    elif [[ $orig =~ ${_Dbg_eval_re[1]} ]] ; then
	extracted="echo ${.sh.match[1]}"
    elif [[ $orig =~ ${_Dbg_eval_re[2]} ]] ; then
	extracted=${.sh.match[1]}
    elif [[ $orig =~ ${_Dbg_eval_re[3]} ]] ; then
	extracted="echo ${.sh.match[1]}"
    else
	extracted=$orig
    fi
}

# Print "on" or "off" depending on whether $1 is true (0) or false
# (nonzero).
function _Dbg_onoff {
  typeset onoff='off.'
  (( $1 != 0 )) && onoff='on.'
  echo $onoff
}

# Set $? to $1 if supplied or the saved entry value of $?.
function _Dbg_set_dol_q {
  (( $# == 0 )) && return $_Dbg_debugged_exit_code
  return $1
}

# Split $2 using $1 as the split character.  We accomplish this by
# temporarily resetting the variable IFS (input field separator).
#
# Example:
# typeset -a a=($(_Dbg_split ":" "file:line"))
# a[0] will have file and a{1] will have line.

function _Dbg_split {
  typeset old_IFS=$IFS
  typeset new_ifs=${1:-' '}
  shift
  typeset -r text=$*
  typeset -a array
  IFS="$new_ifs"
  array=( $text )
  echo ${array[@]}
  IFS=$old_IFS
}

# _Dbg_is_function returns 0 if $1 is a defined function or nonzero otherwise.
# if $2 is nonzero, system functions, i.e. those whose name starts with
# an underscore (_), are included in the search.
function _Dbg_is_function {
    typeset needed_fn=$1
    [[ -z $needed_fn ]] && return 1
    typeset -i include_system=${2:-0}
    [[ ${needed_fn:0:1} == '_' ]] && ((include_system)) && {
	return 0
    }
    typeset -pf $needed_fn 2>&1 >/dev/null
    return $?
}

# _get_function echoes returns list of all of functions in array
# variable ret_fns.
# if $1 is nonzero, system functions, i.e. those whose name starts with
# an underscore (_), are included in the search.
# FIXME add parameter search pattern.
_Dbg_get_functions() {
    typeset -i include_system=${1:-0}
    typeset    pat=${2:-.*}
    typeset -i invert=0;

    if [[ $pat == !* ]] ; then
	# Remove leading !
	pat=#{$pat#!}
	invert=1
    fi

    typeset +p +f | while read line ; do
	fn=${line% #*}
	[[ $fn == _* ]] && (( ! include_system )) && continue
	if [[ $fn =~ $pat ]] ; then
	     [[ $invert == 0 ]] && ret_fns+=("$line")
	else
	     [[ $invert != 0 ]] && ret_fns+=("$line")
	fi
    done
}

# Common routine for setup of commands that take a single
# linespec argument. We assume the following variables
# which we store into:
#  filename, line_number, full_filename

_Dbg_linespec_setup() {
    (($# != 1)) && return 2
    typeset linespec=$1
    typeset -a word
    eval "word=($(_Dbg_parse_linespec $linespec))"
    if [[ ${#word[@]} == 0 ]] ; then
	_Dbg_errmsg "Invalid line specification: $linespec"
	return 1
    fi

    filename="${word[2]}"
    typeset -i is_function=${word[1]}
    line_number=${word[0]}
    full_filename=$(_Dbg_is_file "$filename")

    if (( is_function )) ; then
	if [[ -z $full_filename ]] ; then
	    _Dbg_readin "$filename"
	    full_filename=$(_Dbg_is_file "$filename")
	fi
    fi
}

# Parse linespec in $1 which should be one of
#   int
#   file:line
#   function-num
# Return triple (line,  is-function?, filename,)
# We return the filename last since that can have embedded blanks.
function _Dbg_parse_linespec {
    typeset linespec=$1
    case "$linespec" in

	# line number only - use filename from last adjust_frame
	[0-9]* )
	    echo "$linespec 0 \"${_Dbg_frame_last_filename}\""
	    ;;

	# file:line
	[^:][^:]*[:][0-9]* )
	    # Split the POSIX way
	    typeset line_word=${linespec##*:}
	    typeset file_word=${linespec%${line_word}}
	    file_word=${file_word%?}
	    echo "$line_word 0 $file_word"
	    ;;

	# Function name or error
	* )
	    if _Dbg_is_function $linespec ${_Dbg_set_debug} ; then
		typeset -a word==( $(typeset +p +f $linespec) )
		typeset -r fn=${word[0]}
		echo "${word[2]} 1 ${word[3]}"
	    else
		echo ''
	    fi
	    ;;
    esac
}

# Demo it
if [[ ${0##*/} == ${.sh.file##*/} ]] ; then
    typeset -a ret_fns
    _Dbg_get_functions
    typeset -p ret_fns
    _Dbg_get_functions 1
    typeset -p ret_fns
    _Dbg_parse_linespec _Dbg_parse_linespec
fi
