# -*- shell-script -*-
# alias.sh - gdb-like "alias" debugger command
#
#   Copyright (C) 2008, 2016 Rocky Bernstein rocky@gnu.org
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

_Dbg_help_add alias \
'**alias** *alias-name* *debugger-command*

Make *alias-name* be an alias for *debugger-command*.

Examples:
---------

    alias cat list   # "cat prog.py" is the same as "list prog.py"
    alias s   step   # "s" is now an alias for "step".
                     # The above example is done by default.

See also:
---------

**unalias** and **show alias**.
'

_Dbg_do_alias() {
  if (($# != 2)) ; then
      _Dbg_errmsg "Got $# parameters, but need 2."
  fi
  _Dbg_alias_add $1 $2
}

_Dbg_help_add unalias \
'unalias NAME

Remove debugger command alias NAME.

Use "show aliases" to get a list the aliases in effect.'

_Dbg_do_unalias() {
  if (($# != 1)) ; then
      _Dbg_errmsg "Got $# parameters, but need 1."
  fi
  _Dbg_alias_remove $1
}
