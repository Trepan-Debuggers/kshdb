# -*- shell-script -*-
# step.sh - gdb-like "step" and "skip" debugger commands
#
#   Copyright (C) 2008-2011, 2019 Rocky Bernstein <rocky@gnu.org>
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

# Number of statements to skip before entering the debugger if greater than 0
typeset -i _Dbg_skip_ignore=0

# 1 if we need to ensure we stop on a different line?
typeset -i _Dbg_step_force=0

# if positive, the frame level we want to stop at next
typeset -i _Dbg_return_level=-1

# The default behavior of "set different".
typeset -i _Dbg_set_different=0

_Dbg_help_add 'step' \
"**step** [*count*]

Single step a statement *count* times.

If *count* is given, stepping occurs that many times before
stopping. Otherwise *count* is one. *count* an be an arithmetic
expression.

In contrast to \"next\", functions and source\'d files are stepped
into.

See also:
---------

**next**, **skip**, **step-** **step+**, and **set different**."

_Dbg_help_add 'step+' \
"**step+**

Single step a statement ensuring a different line after the step.

In contrast to **step**, we ensure that the file and line position is
different from the last one just stopped at.

See also:
---------

**step-** and **set different**."

_Dbg_help_add 'step-' \
"**step-**

Single step a statement without the \`step force' setting.

Set step force may have been set on. step- ensures we turn that off for
this command.

See also:
---------

**step** and **set different**." 0

# Step command
# $1 is command step+, step-, or step
# $2 is an optional additional count.
_Dbg_do_step() {

  _Dbg_not_running && return 1

  _Dbg_last_cmd="$1"
  _Dbg_last_next_step_cmd="$1"; shift
  _Dbg_last_next_step_args="$@"

  typeset count=${1:-1}

  case "$_Dbg_last_next_step_cmd" in
      'step+' ) _Dbg_step_force=1 ;;
      'step-' ) _Dbg_step_force=0 ;;
      'step'  ) _Dbg_step_force=$_Dbg_set_different ;;
      * ) ;;
  esac

  if [[ $count == [0-9]* ]] ; then
      _Dbg_step_ignore=${count:-1}
  else
      _Dbg_errmsg "Argument ($count) should be a number or nothing."
      _Dbg_step_ignore=-1
      return 0
  fi

  _Dbg_write_journal_eval "_Dbg_return_level=-1"
  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"
  _Dbg_write_journal "_Dbg_step_force=$_Dbg_step_force"
  return 1
}

_Dbg_alias_add 's' step
_Dbg_alias_add 's+' 'step+'
_Dbg_alias_add 's-' 'step-'
