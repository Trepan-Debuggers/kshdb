# -*- shell-script -*-
# info.sh - gdb-like "info" debugger commands
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008, 2009,
#   2010, 2011 Rocky Bernstein <rocky@gnu.org>
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

typeset -A _Dbg_debugger_info_commands

_Dbg_help_add info '' 1 

typeset -a _Dbg_info_subcmds
_Dbg_info_subcmds=( breakpoints display files line program source stack variables )

# Load in "info" subcommands
for _Dbg_file in ${_Dbg_libdir}/command/info_sub/*.sh ; do 
    source $_Dbg_file
done

# Command completion
_Dbg_complete_info() {
    _Dbg_complete_subcmd info
}

_Dbg_do_info() {
      
  if (($# > 0)) ; then
      typeset subcmd=$1
      shift
      
      if [[ -n ${_Dbg_debugger_info_commands[$subcmd]} ]] ; then
	  ${_Dbg_debugger_info_commands[$subcmd]} $label "$@"
	  return $?
      else
	  # Look for a unique abbreviation
	  typeset -i count=0
	  typeset list; list="${!_Dbg_debugger_info_commands[@]}"
	  for try in $list ; do 
	      if [[ $try =~ ^$subcmd ]] ; then
		  subcmd=$try
		  ((count++))
	      fi
	  done
	  ((found=(count==1)))
      fi
      if ((found)); then
	  ${_Dbg_debugger_info_commands[$subcmd]} $label "$@"
	  return $?
      fi
  
      case $subcmd in 
# 	  a | ar | arg | args )
#               _Dbg_do_info_args 3 
# 	      return 0
# 	      ;;
	  #       h | ha | han | hand | handl | handle | \
	  #           si | sig | sign | signa | signal | signals )
	  #         _Dbg_info_signals
	  #         return
	  # 	;;
	  so | sou | sourc | source )
	      _Dbg_do_info_source
	      return 0
	      ;;
	  
	  st | sta | stac | stack )
	      _Dbg_do_backtrace 1 $@
	      return 0
	      ;;
	  
	  #       te | ter | term | termi | termin | termina | terminal | tt | tty )
	  # 	_Dbg_msg "tty: $_Dbg_tty"
	  # 	return;
	  # 	;;
	  
	  *)
	      _Dbg_errmsg "Unknown info subcommand: $subcmd"
	      return 1
      esac
  else
      msg=_Dbg_msg
  fi
  typeset -a subcmds; subcmds=("${!_Dbg_debugger_info_commands[@]}")
  $msg "Info subcommands are:"
  _Dbg_list_columns subcmds
  return 1
}

_Dbg_alias_add i info
