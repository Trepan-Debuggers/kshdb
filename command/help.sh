# -*- shell-script -*-
# help.sh - gdb-like "help" debugger command
#
#   Copyright (C) 2008, 2010 Rocky Bernstein rocky@gnu.org
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

_Dbg_help_add help \
'help	-- Print list of commands.' 1

_Dbg_do_help() {
  if ((0==$#)) ; then
      _Dbg_msg 'Available commands:'
      typeset -a commands=("${!_Dbg_command_help[@]}")
      _Dbg_list_columns commands 
      _Dbg_msg ''
      _Dbg_msg 'Readline command line editing (emacs/vi mode) is available.'
      _Dbg_msg 'Type "help" followed by command name for full documentation.'
      return 0
   else
      typeset dbg_cmd="$1"
      if [[ -n ${_Dbg_command_help[$dbg_cmd]} ]] ; then
 	  _Dbg_msg "${_Dbg_command_help[$dbg_cmd]}"
      else
	  _Dbg_alias_expand $dbg_cmd
	  typeset dbg_cmd="$expanded_alias"
	  if [[ -n ${_Dbg_command_help[$dbg_cmd]} ]] ; then
 	      _Dbg_msg "${_Dbg_command_help[$dbg_cmd]}"
	  else
	      case $dbg_cmd in 
	      i | in | inf | info )
		_Dbg_info_help $2
                ;;
	      sh | sho | show )
		_Dbg_help_show $2
                ;;
	      se | set )
	        _Dbg_help_set $2
                ;;
	     * )
  	        _Dbg_errmsg "Undefined command: \"$dbg_cmd\".  Try \"help\"."
  	         return 1 ;;
	     esac
	  fi
      fi
      aliases_found=''
      _Dbg_alias_find_aliased "$dbg_cmd"
      if [[ -n $aliases_found ]] ; then
	  _Dbg_msg ''
	  _Dbg_msg "Aliases for $dbg_cmd: $aliases_found"
      fi
      return 0
  fi
}

_Dbg_alias_add '?' help
_Dbg_alias_add 'h' help

 # Demo it.
if [[ $0 == ${.sh.file##*/} ]] ; then
    for file in sort columnize list msg ; do source ../lib/${file}.sh; done
    _Dbg_do_help
    echo '---'
    _Dbg_args='help'
    _Dbg_do_help help
 fi
