# -*- shell-script -*-
# "info breakpoints" debugger command
#
#   Copyright (C) 2010-2011, 2018 Rocky Bernstein <rocky@gnu.org>
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

_Dbg_help_add_sub info breakpoints \
"info breakpoints

Show status of user-settable breakpoints. If no breakpoint numbers are
given, the show all breakpoints. Otherwise only those breakpoints
listed are shown and the order given. If VERBOSE is given, more
information provided about each breakpoint.

The \"Disp\" column contains one of \"keep\", \"del\", the disposition of
the breakpoint after it gets hit.

The \"enb\" column indicates whether the breakpoint is enabled.

The \"Where\" column indicates where the breakpoint is located.
Info whether use short filenames

See also \"break\", \"enable\", and \"disable\"." 1

# list breakpoints and break condition.
# If $1 is given just list those associated for that line.
_Dbg_do_info_breakpoints() {
  if (( $# != 0  )) ; then
      typeset brkpt_num="$1"
      if [[ $brkpt_num != [0-9]* ]] ; then
	  _Dbg_errmsg "Bad breakpoint number $brkpt_num."
      elif [[ -z ${_Dbg_brkpt_file[$brkpt_num]} ]] ; then
	  _Dbg_errmsg "Breakpoint entry $brkpt_num is not set."
      else
	  typeset -r -i i=$brkpt_num
	  typeset source_file=${_Dbg_brkpt_file[$i]}
	  source_file=$(_Dbg_adjust_filename "$source_file")
	  _Dbg_msg "Num Type       Disp Enb What"
	  _Dbg_printf "%-3d breakpoint %-4s %-3s %s:%s" $i \
	      ${_Dbg_keep[${_Dbg_brkpt_onetime[$i]}]} \
	      ${_Dbg_yn[${_Dbg_brkpt[$i].enable}]} \
	      "$source_file" ${_Dbg_brkpt[$i].lineno}
	  if [[ ${_Dbg_brkpt[$i].condition} != '1' ]] ; then
	      _Dbg_printf "\tstop only if %s" "${_Dbg_brkpt[$i].condition}"
	  fi
	  _Dbg_print_brkpt_count $i
      fi
      return 0
  fi

  if (( _Dbg_brkpt_count > 0 )); then
      typeset -i i

      _Dbg_msg "Num Type       Disp Enb What"
      for (( i=1; i <= _Dbg_brkpt_max; i++ )) ; do
	  typeset source_file=${_Dbg_brkpt[$i].filename}
	  if (( _Dbg_brkpt[$i].lineno > 0 )) ; then
	      source_file=$(_Dbg_adjust_filename "$source_file")
	      _Dbg_printf "%-3d breakpoint %-4s %-3s %s:%s" $i \
		  ${_Dbg_keep[${_Dbg_brkpt_onetime[$i]}]} \
		  ${_Dbg_yn[${_Dbg_brkpt[$i].enable}]} \
		  "$source_file" ${_Dbg_brkpt[$i].lineno}
	      if [[ ${_Dbg_brkpt[$i].condition} != '1' ]] ; then
		  _Dbg_printf "\tstop only if %s" "${_Dbg_brkpt[$i].condition}"
	      fi
	      if (( _Dbg_brkpt[$i].hits != 0 )) ; then
		  _Dbg_print_brkpt_count $i
	      fi
	  fi
      done
      return 0
  else
      _Dbg_msg 'No breakpoints have been set.'
      return 1
  fi
}
