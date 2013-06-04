# -*- shell-script -*-
#   Copyright (C) 2008, 2009, 2010 Rocky Bernstein rocky@gnu.org
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

#================ VARIABLE INITIALIZATIONS ====================#

# Where are we in stack? This can be changed by "up", "down" or "frame"
# commands.

[[ -z ${.sh.type.Frame_t} ]] || return

typeset -T Frame_t=(
	filename=''
	# integer lineno=0
	lineno=0
	fun=''
	to_file_line()
	{
	    print -r "file \`${_.filename}' at line ${_.lineno}"
	}
)

typeset -i _Dbg_stack_pos=0


# Save the last-entered frame for to determine stopping when
# "set force" or step+ is in effect.
typeset _Dbg_frame_last_filename=''
typeset -i _Dbg_frame_last_lineno=0

# Note: this code is a bit more convoluted than it need be because of
# bugs as recent as ksh93t 2008-07-24. These will no doubt be fixed and
# then this code should be redone.

Frame_t -a _Dbg_frame_stack  #=() causes a problem
_Dbg_frame_stack=()

_Dbg_frame_adjust() {
  (($# != 2)) && return -- -1

  typeset -i count=$1
  typeset -i signum=$2

  typeset -i retval
  _Dbg_frame_int_setup $count || return 2

  typeset -i pos
  if (( signum==0 )) ; then
    if (( count < 0 )) ; then
      ((pos=${#_Dbg_frame_stack[@]}+count))
    else
      ((pos=count))
    fi
  else
    ((pos=_Dbg_stack_pos+(count*signum)))
  fi

  if (( pos < 0 )) ; then
    _Dbg_errmsg 'Would be beyond bottom-most (most recent) entry.'
    return 1
  elif (( pos >= ${#_Dbg_frame_stack[@]} )) ; then
    _Dbg_errmsg 'Would be beyond top-most (least recent) entry.'
    return 1
  fi

  _Dbg_frame_last_filename="${_Dbg_frame_stack[$pos].filename}"
  _Dbg_frame_last_lineno=${_Dbg_frame_stack[$pos].lineno}
  (( _Dbg_stack_pos = pos ))
  return 0
}

# Return the frame file for stack $1 or _Dbg_stack_pos if $1
# is omitted. If $2 is given, it indicates if we want the basename
# only. Otherwise the $_Dbg_set_basename setting is used.
# 0 is returned if no error, nonzero means some sort of error.
_Dbg_frame_file() {
    (($# > 1)) && return 2
    # FIXME check to see that $1 doesn't run off the end.
    typeset -i pos=${1:-$_Dbg_stack_pos}
    typeset -n frame=_Dbg_frame_stack[pos]
    _Dbg_frame_filename=${frame.filename}
    (( _Dbg_set_basename )) && _Dbg_frame_filename=${_Dbg_frame_filename##*/}
    return 0
}

# Tests for a signed integer parameter and set global retval
# if everything is okay. Retval is set to 1 on error
_Dbg_frame_int_setup() {

  if (( ! _Dbg_running )) ; then
    _Dbg_errmsg "No stack."
    return 1
  else
#     setopt EXTENDED_GLOB
#     if [[ $1 != '' && $1 != ([-+]|)([0-9])## ]] ; then
#       _Dbg_msg "Bad integer parameter: $1"
#       # Reset EXTENDED_GLOB
#       return 1
#     fi
#     # Reset EXTENDED_GLOB
    return 0
  fi
}

_Dbg_frame_lineno() {
    (($# > 1)) && return -1
    # FIXME check to see that $1 doesn't run off the end.
    typeset -i pos=${1:-$_Dbg_stack_pos}
    typeset -n frame=_Dbg_frame_stack[pos]
    _Dbg_frame_lineno=${frame.lineno}
    return ${frame.lineno}
}

# Save stack frames in array _Dbg_frame_stack ignoring the
# first (most recent) $1 of these.
_Dbg_frame_save_frames() {
    integer start=${1:-0}
    integer .level=.sh.level-$start .max=.sh.level
    typeset -a .files=()
    typeset -a .linenos=()
    typeset -a .fns=()
    # Frame_t -a ._Dbg_frame_stack gives SEGV
    while((--.level>=0)); do
	((.sh.level = .level))
	.fun+=("${.sh.fun}")
	.files+=("${.sh.file}")
	.linenos+=(${.sh.lineno})  # optimization bug unless done this way
	.fns+=($0)
    done
    ((.sh.level=.max))
    # Reorganize into an array of frame structures
    integer _Dbg_i
    for ((_Dbg_i=0; _Dbg_i<.max-start; _Dbg_i++)) ; do
	_Dbg_frame_stack[_Dbg_i].filename=${.files[_Dbg_i]}
	_Dbg_frame_stack[_Dbg_i].lineno=${.linenos[_Dbg_i]}
	_Dbg_frame_stack[_Dbg_i].fun=${.fns[_Dbg_i]}
    done
    for ((_Dbg_i=${#_Dbg_frame_stack[@]}-1; _Dbg_i>=.max-start; _Dbg_i--)); do
	unset _Dbg_frame_stack[$_Dbg_i]
    done
    # Set stack position to the most recent entry.
    _Dbg_stack_pos=0
    _Dbg_frame_last_filename="${_Dbg_frame_stack[0].filename}"
    _Dbg_frame_last_lineno="${_Dbg_frame_stack[0].lineno}"
    _Dbg_listline=-1
}
