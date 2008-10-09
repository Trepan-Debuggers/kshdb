# -*- shell-script -*-
# fns.sh - Debugger Utility Functions
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

typeset -a _Dbg_yn
_Dbg_yn=("n" "y")         

# Return $2 copies of $1. If successful, $? is 0 and the return value
# is in result.  Otherwise $? is 1 and result ''
function _Dbg_copies { 
    result=''
    (( $# < 2 )) && return 1
    typeset -r string="$1"
    typeset -i count=$2 || return 2;
    (( count > 0 )) || return 3
    result=$(printf "%${count}s" ' ') || return 3
    result=${result// /$string}
    return 0
}

# _Dbg_defined returns 0 if $1 is a defined variable or 1 otherwise. 
function _Dbg_defined {
  (set | grep "^$1=")2>&1 >/dev/null 
  if [[ $? != 0 ]] ; then 
    return 1
  else
    return 0
  fi
}

# Add escapes to a string $1 so that when it is read back using
# eval echo "$1" it is the same as echo $1.
function _Dbg_esc_dq {
  echo $1 | sed -e 's/[`$\"]/\\\0/g' 
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
    ((!_Dbg_debug_debugger)) && cmd+=' | grep -v ^_Dbg_'
    eval $cmd
}

# Add escapes to a string $1 so that when it is read back via "$1"
# it is the same as $1.
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

# _get_function echoes a list of all of the functions.
# if $1 is nonzero, system functions, i.e. those whose name starts with
# an underscore (_), are included in the search.
# FIXME add parameter search pattern.
function _Dbg_get_functions {
    typeset -i include_system=${1:-0}
    typeset    pat=${2:-*}
    typeset  line
    typeset -a ret_fns=()
    typeset -i invert=0;
    if [[ $pat == !* ]] ; then 
	# Remove leading !
	pat=#{$pat#!}
	invert=1
    fi	
    echo 'Not done yet'
    return 0
    typeset -p +f | while read line ; do
	fn=${line% #*}
	[[ $fn == _* ]] && (( ! $include_system )) && continue
	if [[ $fn == $pat ]] ; then 
	     [[ $invert == 0 ]] && ret_fns[-1]=$fn
	else
	     [[ $invert != 0 ]] && ret_fns[-1]=$fn
	fi
    done
    echo ${ret_fns[@]}
}

# Common routine for setup of commands that take a single
# linespec argument. We assume the following variables 
# which we store into:
#  filename, line_number, full_filename

_Dbg_linespec_setup() {
    (($# != 1)) && return 2
    typeset linespec=$1
    typeset -a word
    word=($(_Dbg_parse_linespec "$linespec"))
    if [[ ${#word[@]} == 0 ]] ; then
	_Dbg_errmsg "Invalid line specification: $linespec"
	return 1
    fi
    
    filename=${word[2]}
    typeset -i is_function=${word[1]}
    line_number=${word[0]}
    full_filename=$(_Dbg_is_file $filename)
    
    if (( is_function )) ; then
	if [[ -z $full_filename ]] ; then 
	    _Dbg_readin "$filename"
	    full_filename=$(_Dbg_is_file $filename)
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
      echo "$linespec 0 ${_Dbg_frame_last_filename}"
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
      if _Dbg_is_function $linespec ${_Dbg_debug_debugger} ; then 
	typeset -a word==( $(typeset -p +f $linespec) )
	typeset -r fn=${word[1]%\(\)}
	echo "${word[3]} 1 ${word[4]}"
      else
	echo ''
      fi
      ;;
   esac
}

# Add escapes to a string $1 so that when it is read back via "$1"
# it is the same as $1.
function _Dbg_onoff {
  typeset onoff='off.'
  (( $1 != 0 )) && onoff='on.'
  echo $onoff
}
