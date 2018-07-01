# -*- shell-script -*-
# gdb-like "up" debugger command
#
#   Copyright (C) 2010-2011, 2018 Rocky Bernstein
#   <rocky@gnu.org>
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

if [[ $0 == ${.sh.file##*/} ]] ; then
    src_dir=${.sh.file%/*}
    top_dir=${src_dir}/..
    for lib_file in help alias ; do source $top_dir/lib/${lib_file}.sh; done
fi

# Move default values up $1 or one in the stack.
_Dbg_help_add up \
'**up** [*count*]

Move the current frame up in the stack trace (to an older frame). 0 is
the most recent frame.

If **count** is omitted, use 1.

See also:
---------

**down** and **frame**.' 1

_Dbg_do_up() {
    _Dbg_not_running && return 1
    typeset -i count=${1:-1}
    _Dbg_frame_adjust $count +1
    typeset -i rc=$?
    ((0 == rc)) && _Dbg_last_cmd='up'
    _Dbg_print_location
    return $rc
}

_Dbg_alias_add 'u' 'up'

# Demo it.
if [[ $0 == ${.sh.file##*/} ]] ; then
    source $top_dir/lib/complete.sh
    source $top_dir/command/help.sh
    _Dbg_libdir=$top_dir/lib
    source $_Dbg_libdir/msg.sh

    _Dbg_args='up'
    _Dbg_do_help up
fi
