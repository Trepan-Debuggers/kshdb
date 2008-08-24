# -*- shell-script -*-
#   Copyright (C) 2008 Rocky Bernstein  rocky@gnu.org
#
#   kshdb is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   kshd is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with kshdb; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

# Stuff common to kshdb and dbg-trace. Include the rest of options
# processing. Also includes things which have to come before other includes
. ${_Dbg_libdir}/dbg-pre.sh

# All debugger lib code has to come before debugger command code.
typeset file

for file in ${_Dbg_libdir}/lib/*.sh ; do 
    source $file
done

for file in ${_Dbg_libdir}/command/*.sh ; do 
    source $file
done

# Have we already specified where to read debugger input from?  
#
# Note: index 0 is only set by the debugger. It is not used otherwise for
# I/O like those indices >= _Dbg_INPUT_START_DESC are.
if [ -n "$DBG_INPUT" ] ; then 
  _Dbg_input=($DBG_INPUT)
  _Dbg_do_source ${_Dbg_input[0]}
  _Dbg_no_init=1
fi

# Run the user's debugger startup file
if [[ -z $DBG_RESTART_FILE && -r ~/.kshdbrc ]] ; then
  _Dbg_do_source ~/.kshdbrc
fi
