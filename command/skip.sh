# -*- shell-script -*-
# stepping.cmd - gdb-like "skip" debugger commands
#
#   Copyright (C) 2008, 2009, 2010, 2011 Rocky Bernstein <rocky@gnu.org>
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

_Dbg_help_add skip \
"skip [COUNT]

Skip (don't run) the next COUNT command(s).

If COUNT is given, stepping occurs that many times before
stopping. Otherwise COUNT is one. COUNT an be an arithmetic
expression. See also \"next\" and \"step\"."

# Return 0 if we should skip. Nonzero if there was an error.
# $1 is an optional additional count.
_Dbg_do_skip() {

  _Dbg_not_running && return 1

  typeset count=${1:-1}

  if [[ $count == [0-9]* ]] ; then
    _Dbg_skip_ignore=${count:-1}
    ((_Dbg_skip_ignore--)) # Remove one from the skip caused by this return
  else
    _Dbg_errmsg "Argument ($count) should be a number or nothing."
    _Dbg_skip_ignore=0
    return 3
  fi
  # We're cool. Do the skip.
  _Dbg_write_journal "_Dbg_skip_ignore=$_Dbg_skip_ignore"

  # Set to do a stepping stop after skipping
  _Dbg_step_ignore=0
  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"
  return 0
}

_Dbg_help_add 'step' \
"step [COUNT]

Single step a statement COUNT times.

If COUNT is given, stepping occurs that many times before
stopping. Otherwise COUNT is one. COUNT an be an arithmetic
expression.

In contrast to \"next\", functions and source\'d files are stepped
into.

See also \"next\", \"skip\", \"step-\" \"step+\", and \"set force\"."

_Dbg_help_add 'step+' \
"step+ -- Single step a statement ensuring a different line after the step.

In contrast to \"step\", we ensure that the file and line position is
different from the last one just stopped at.

See also \"step-\" and \"set force\"."

_Dbg_help_add 'step-' \
"step- -- Single step a statement without the \`step force' setting.

Set step force may have been set on. step- ensures we turn that off for
this command.

See also \"step\" and \"set force\"."
