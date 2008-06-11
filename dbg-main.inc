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

typeset -r _Dbg_main_ver=\
'$Id: dbg-main.inc.in,v 1.6 2008/01/03 02:52:08 rockyb Exp $'

# Are we using a debugger-enabled ksh? If not let's stop right here.
if [[ -z "$.sh.file}" ]] ; then 
  echo "Sorry, your ksh just isn't modern enough." 2>&1
  exit 2
fi

typeset _Dbg

# $_Dbg.libdir could have been set by kshdb script.
# If not, set if "bash --debugger"
prefix=/usr/local  # cygwin gets PKGDATADIR wrong
[ -z $_Dbg_libdir ] && typeset _Dbg_libdir=${prefix}/share/kshdb

# Note: "init" comes first and "cmds" has to come after "io". Otherwise 
# these are sorted alphabetically.
# typeset -r _Dbg_includes='init brk complete edit file fns help hist info log io 
# cmds commands list stack set show sig'
typeset -r _Dbg_includes='init fns file io sig'

for file in $_Dbg_includes ; do 
  source ${_Dbg_libdir}/dbg-${file}.inc
done

if [[ ${_Dbg_libdir:0:1} == '.' ]] ; then
    _Dbg_libdir=$(_Dbg_expand_filename ${_Dbg_init_cwd}/${_Dbg_libdir})
fi

[ -n "$KSHDB_RESTART_FILE" ] \
   && [ -r "$KSHDB_RESTART_FILE" ] &&  source $KSHDB_RESTART_FILE

trap '_Dbg_debug_trap_handler 0 ".${.sh.command}" "$@"' DEBUG
# echo '*** we were here***'  # uncomment to test that we were run.

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "ksh") ***
#;;; End: ***
