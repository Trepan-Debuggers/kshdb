# -*- shell-script -*-
# "set different" debugger command
#
#   Copyright (C) 2011, 2019 Rocky Bernstein <rocky@gnu.org>
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

_Dbg_help_add_sub set different \
'**set different** [**off**|**on**]

Set consecutive stops must be on different file/line positions.
If no argument is given, different is set "off".

One of the challenges of debugging is getting the granualarity of
stepping comfortable. By setting different "on" you can set a more
coarse-level of stepping which often still is small enough that you
will not miss anything important.

Note that the **step** and **next** debugger commands have **+** and
**-** suffixes if you wan to override this setting on a per-command
basis.

See also:
---------

**show different**' 1

_Dbg_do_set_different() {
    _Dbg_set_onoff "$1" 'different'
    return $?
}
