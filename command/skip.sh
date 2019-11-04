# -*- shell-script -*-
# skip.sh - gdb-like "skip" debugger command
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

_Dbg_help_add skip \
"**skip** [*count*]

Skip (don't run) the next *count* command(s).

If *count* is given, stepping occurs that many times before
stopping. Otherwise *count* is one. *count* can be an arithmetic
expression.

Note that skipping doesn't change the value of \$?. This has
consequences in some compound statements that test on \$?. For example
in:

   if grep foo bar.txt ; then
      echo not skipped
   fi

Skipping the *if* statement will, in effect, skip running the *grep*
command. Since the return code is 0 when skipped, the *if* body is
entered. Similarly the same thing can  happen in a *while* statement
test.

See also:
---------

**continue**, **next**, and **step**.
"

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

  # Set to do a stepping stop after skipping. Note: skip != step.
  _Dbg_step_ignore=0
  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"

  return 0
}
