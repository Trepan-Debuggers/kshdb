# -*- shell-script -*-
# condition.sh - gdb-like "condition" debugger command
#
#   Copyright (C) 2009, 2018 Rocky Bernstein  rocky@gnu.org
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

_Dbg_help_add condition \
"**condition** *bp_number* *condition*

Break only if *condition* is true in breakpoint number *bp_number*.

*bp_number* is a breakpoint number. *condition* is a zsh expression
which must evaluate to *True* before the breakpoint is honored.  If
*condition* is absent, any existing condition is removed; i.e., the
breakpoint is made unconditional.

Examples:
---------

   condition 5 x > 10  # Breakpoint 5 now has condition x > 10
   condition 5         # Remove above condition

See also:
---------

*break*, *tbreak*.
" 1

# Set a condition for a given breakpoint $1 is a breakpoint number
# $2 is a condition. If not given, set "unconditional" or 1.
# returns 0 if success or 1 if fail.
function _Dbg_do_condition {

  if (( $# < 1 )) ; then
    _Dbg_errmsg 'condition: Argument required (breakpoint number).'
    return 1
  fi

  typeset -r n=$1
  shift
  typeset condition="$@"
  if [[ $n != [0-9]* ]]; then
    _Dbg_errmsg "condition: Bad breakpoint number: $n"
    return 2
  fi

  if [[ -z ${_Dbg_brkpt[$n].filename} ]] ; then
    _Dbg_errmsg "condition: Breakpoint entry $n is not set. Condition not changed."
    return 3
  fi

  if [[ -z $condition ]] ; then
    condition=1
    _Dbg_msg "Breakpoint $n now unconditional."
  fi
  _Dbg_brkpt[$n].condition="$condition"
  return 0
}
