# -*- shell-script -*-
#
#   Copyright (C) 2008-2009, 2011, 2014, 2016 Rocky Bernstein <rocky@gnu.org>
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

#================ VARIABLE INITIALIZATIONS ====================#

[[ -z ${.sh.type._Dbg_brkpt_t} ]] || return

typeset -a _Dbg_keep
_Dbg_keep=('keep' 'del')

# Note: we loop over possibly sparse arrays with _Dbg_brkpt_max by adding one
# and testing for an entry. Could add yet another array to list only
# used indices.

# Breakpoint data structures
typeset -T _Dbg_brkpt_t=(
    filename=''
    typeset -i lineno=-1
    typeset -i enable=1
    typeset -i onetime=0
    typeset -i hits=0
    condition=''
)

_Dbg_brkpt_t -a _Dbg_brkpt

# Number of breakpoints.
typeset -i _Dbg_brkpt_count=0

# Needed because we can't figure out what the max index is and arrays
# can be sparse.
typeset -i  _Dbg_brkpt_max=0

# Can't easily get this to work so we'll fall back to parallel arrays
# which is what's done in zsh. Sigh. On the plus side, it helps keeping
# zshdb and kshdb in sync.
## typeset -T _Dbg_file2brkpt_t=(
##     typeset -a line_nums=()
##     typeset -a brkpt_nums=()
## )

## _Dbg_file2brkpt_t -A _Dbg_file2brkpt

# Maps a resolved filename to a list of beakpoint line numbers in that file
typeset -A _Dbg_brkpt_file2linenos

# Maps a resolved filename to a list of breakpoint entries.
typeset -A _Dbg_brkpt_file2brkpt


#========================= FUNCTIONS   ============================#

function _Dbg_save_breakpoints {
  typeset -p _Dbg_brkpt              >> $_Dbg_statefile
  typeset -p _Dbg_brkpt_file2linenos >> $_Dbg_statefile
# typeset -p _Dbg_file2brkpt          >> $_Dbg_statefile
  typeset -p _Dbg_brkpt_file2brkpt   >> $_Dbg_statefile
  typeset -p _Dbg_brkpt_max          >> $_Dbg_statefile
}

# Start out with general break/watchpoint functions first...

# Enable/disable breakpoint or watchpoint by entry numbers.
function _Dbg_enable_disable {
  if (($# == 0)) ; then
    _Dbg_errmsg 'Expecting a list of breakpoint/watchpoint numbers. Got none.'
    return 1
  fi
  typeset -i on=$1
  typeset en_dis=$2
  shift; shift

  if [[ $1 == 'display' ]] ; then
    shift
    typeset to_go="$@"
    typeset i
    for i in $to_go ; do
      if [[ $i == [0-9]* ]] ; then
	  _Dbg_enable_disable_display $on $en_dis $i
      else
	  _Dbg_errmsg "Invalid entry number skipped: $i"
      fi
    done
    return 0
  elif [[ $1 == 'action' ]] ; then
    shift
    typeset to_go="$@"
    typeset i
    for i in $to_go ; do
      if [[ $i == [0-9]* ]] ; then
	  _Dbg_enable_disable_action $on $en_dis $i
      else
	  _Dbg_errmsg "Invalid entry number skipped: $i"
      fi
    done
    return 0
  fi

  typeset to_go="$@"
  typeset i
  for i in $to_go ; do
      if [[ $i == [0-9]* ]] ; then
          _Dbg_enable_disable_brkpt $on $en_dis $i
      # elsif # Check for watch-pat
      #   _Dbg_enable_disable_watch $on $en_dis ${del:0:${#del}-1}
      else
	  _Dbg_errmsg "Invalid entry number skipped: $i"
      fi
  done
  return 0
}

# Print a message regarding how many times we've encounterd
# breakpoint number $1 if the number of times is greater than 0.
# Uses global array _Dbg_brkpt_counts.
function _Dbg_print_brkpt_count {
  typeset -i _Dbg_i; _Dbg_i=$1
  if (( _Dbg_brkpt[_Dbg_i].hits != 0 )) ; then
      if (( _Dbg_brkpt[_Dbg_i].hits == 1 )) ; then
	  _Dbg_printf '    breakpoint already hit 1 time'
      else
	  _Dbg_printf "    breakpoint already hit %d times" ${_Dbg_brkpt[$_Dbg_i].hits}
      fi
  fi
}

# Clear all breakpoints.
function _Dbg_clear_all_brkpt {
  # _Dbg_write_journal_eval "_Dbg_file2brkpt=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_file2linenos=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_file2brkpt=()"
  _Dbg_write_journal_eval "_Dbg_brkpt=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_count=0"
}

# Internal routine to a set breakpoint unconditonally.

_Dbg_set_brkpt() {
    (( $# < 3 || $# > 4 )) && return 1
    typeset source_file="$1"
    typeset -i lineno=$2
    typeset -i is_temp=$3
    typeset    condition=${4:-1}

    # Increment brkpt_max here because we are 1-origin
    ((_Dbg_brkpt_max++))
    ((_Dbg_brkpt_count++))

    _Dbg_brkpt[$_Dbg_brkpt_max].lineno=$lineno
    _Dbg_brkpt[$_Dbg_brkpt_max].filename="$source_file"
    _Dbg_brkpt[$_Dbg_brkpt_max].condition="$condition"
    _Dbg_brkpt[$_Dbg_brkpt_max].onetime=$is_temp
    _Dbg_brkpt[$_Dbg_brkpt_max].enable=1
    _Dbg_brkpt[$_Dbg_brkpt_max].hits=0

    typeset dq_source_file=$(_Dbg_esc_dq "$source_file")
    typeset dq_condition=$(_Dbg_esc_dq "$condition")
    _Dbg_write_journal "_Dbg_brkpt[$_Dbg_brkpt_max].lineno=$lineno"
    _Dbg_write_journal "_Dbg_brkpt[$_Dbg_brkpt_max].filename=\"$dq_source_file\""
    _Dbg_write_journal "_Dbg_brkpt[$_Dbg_brkpt_max].condition=\"$dq_condition\""
    _Dbg_write_journal "_Dbg_brkpt[$_Dbg_brkpt_max].onetime=$is_temp"
    _Dbg_write_journal "_Dbg_brkpt[$_Dbg_brkpt_max].hits=0"
    _Dbg_write_journal "_Dbg_brkpt[$_Dbg_brkpt_max].enable=1"

    # Add line number with a leading and trailing space. Delimiting the
    # number with space helps do a string search for the line number.
#     _Dbg_file2brkpt[$source_file].line_nums+=($lineno)
#     _Dbg_file2brkpt[$source_file].brkpt_nums+=($_Dbg_brkpt_max)
    _Dbg_brkpt_file2linenos[$source_file]+=" $lineno "
    _Dbg_brkpt_file2brkpt[$source_file]+=" $_Dbg_brkpt_max "

    source_file=$(_Dbg_adjust_filename "$source_file")
    if (( is_temp == 0 )) ; then
	_Dbg_msg "Breakpoint $_Dbg_brkpt_max set in file ${source_file}, line $lineno."
    else
	_Dbg_msg "One-time breakpoint $_Dbg_brkpt_max set in file ${source_file}, line $lineno."
    fi
    _Dbg_write_journal "_Dbg_brkpt_max=$_Dbg_brkpt_max"
    return 0
}

# Internal routine to unset the actual breakpoint arrays.
# 0 is returned if successful
function _Dbg_unset_brkpt_arrays {
    (( $# != 1 )) && return 1
    typeset -i del=$1
    _Dbg_write_journal_eval "_Dbg_brkpt[$del].lineno=0"
    _Dbg_write_journal_eval "_Dbg_brkpt[$del].hits=0"
    _Dbg_write_journal_eval "_Dbg_brkpt[$del].filename=''"
    _Dbg_write_journal_eval "_Dbg_brkpt[$del].enable=0"
    _Dbg_write_journal_eval "_Dbg_brkpt[$del].condition=0"
    _Dbg_write_journal_eval "_Dbg_brkpt[$del].onetime=0"
    ((_Dbg_brkpt_count--))
    return 0
}

# Internal routine to delete the first breakpoint found by file/line.
# The number of breakpoints (0 or 1) is returned.
function _Dbg_unset_brkpt {
    (( $# != 2 )) && return 0
    typeset    filename="$1"
    typeset -i lineno=$2
    typeset    fullname
    fullname=$(_Dbg_expand_filename "$filename")

    [[ -z ${_Dbg_brkpt_file2linenos[$fullname]} ]] && return 0
    # FIXME: combine with _hook_breakpoint_hit
    typeset -a linenos
    linenos=(${_Dbg_brkpt_file2linenos[$fullname]})
    typeset -a brkpt_nos
    brkpt_nos=(${_Dbg_brkpt_file2brkpt[$fullname]})
    typeset -i _Dbg_i
    for ((_Dbg_i=0; _Dbg_i < ${#linenos[@]}; _Dbg_i++)); do
	if (( linenos[_Dbg_i] == lineno )) ; then
	    # Got a match, find breakpoint entry number
	    typeset -i brkpt_num
	    (( brkpt_num = brkpt_nos[_Dbg_i] ))
	    _Dbg_unset_brkpt_arrays $brkpt_num
	    unset linenos[_Dbg_i]
	    _Dbg_brkpt_file2linenos[$fullname]=${linenos[@]}
	    return 1
	fi
    done
    _Dbg_msg "No breakpoint found at $filename:$lineno"
    return 0
}

# Routine to a delete breakpoint by entry number: $1.
# Returns whether or not anything was deleted.
function _Dbg_delete_brkpt_entry {
    (( $# == 0 )) && return 0
    typeset -r  del="$1"
    typeset -i  found=0

    typeset    try
    for try in ${!_Dbg_brkpt[*]} ; do
	if (( try == del )) ; then
	    found=1
	    break
	elif (( try > del )) ; then
	    break # Not found
	fi
    done
    if (( found == 0 )) ; then
	_Dbg_errmsg "No breakpoint number $del."
	return 1
    fi
    typeset    source_file=${_Dbg_brkpt[$del].filename}
    typeset -i lineno=${_Dbg_brkpt[$del].lineno}
    typeset -i try
    typeset -a new_lineno_val
    typeset -a new_brkpt_nos
    typeset -i i=-1
    brkpt_nos=(${_Dbg_brkpt_file2brkpt[$source_file]})
    for try in ${_Dbg_brkpt_file2linenos[$source_file]} ; do
	((i++))
	if (( brkpt_nos[i] == del )) ; then
	    if (( try != lineno )) ; then
		_Dbg_errmsg 'internal brkpt structure inconsistency'
		return 1
	    fi
	    _Dbg_unset_brkpt_arrays $del
	else
	    new_lineno_val+=$try
	    new_brkpt_nos+=${brkpt_nos[$i]}
	fi
    done
    if (( found > 0 )) ; then
	if (( ${#new_lineno_val[@]} == 0 )) ; then
	    _Dbg_write_journal_eval "unset '_Dbg_brkpt_file2linenos[$source_file]'"
	    _Dbg_write_journal_eval "unset '_Dbg_brkpt_file2brkpt[$source_file]'"
	else
	    _Dbg_write_journal_eval "_Dbg_brkpt_file2linenos[$source_file]=${new_lineno_val}"
	    _Dbg_write_journal_eval "_Dbg_brkpt_file2brkpt[$source_file]=${new_brkpt_nos}"
	fi
	unset _Dbg_brkpt[$del]
	return 0
    fi
    return 1
}

# Enable/disable breakpoint(s) by entry numbers.
function _Dbg_enable_disable_brkpt {
  (($# != 3)) && return 1
  typeset -i on=$1
  typeset en_dis=$2
  typeset -i i=$3
  if [[ -n "${_Dbg_brkpt[$i].filename}" ]] ; then
    if [[ ${_Dbg_brkpt[$i].enable} == $on ]] ; then
      _Dbg_errmsg "Breakpoint entry $i already ${en_dis}, so nothing done."
      return 1
    else
      _Dbg_write_journal_eval "_Dbg_brkpt[$i].enable=$on"
      _Dbg_msg "Breakpoint entry $i $en_dis."
      return 0
    fi
  else
    _Dbg_errmsg "Breakpoint entry $i doesn't exist, so nothing done."
    return 1
  fi
}
