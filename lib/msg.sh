# -*- shell-script -*-
#
#   Copyright (C) 2008, 2009 Rocky Bernstein rocky@gnu.org
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

# Called when a dangerous action is about to be done to make sure it's
# okay. `prompt' is printed, and "yes", or "no" is solicited.  The
# user response is returned in variable $_Dbg_response and $? is set
# to 0.  _Dbg_response is set to 'error' and $? set to 1 on an error.
# 
_Dbg_confirm() {
    if (( $# < 1 || $# > 2 )) ; then
	_Dbg_response='error'
	return 0
    fi
    typeset _Dbg_confirm_prompt=$1
    typeset _Dbg_confirm_default=${2:-'no'}
    typeset -l _Dbg_response
    while read "_Dbg_response?$_Dbg_confirm_prompt" args <&${_Dbg_fd[_Dbg_fd_last]}
    do
	case "$_Dbg_response" in
	    'y' | 'yes' | 'yeah' | 'ya' | 'ja' | 'si' | 'oui' | 'ok' | 'okay' )
		_Dbg_response='y'
		return 0
		;;
	    'n' | 'no' | 'nope' | 'nyet' | 'nein' | 'non' )
		_Dbg_response='n'
		return 0
		;;
	    *)
		if [[ $_Dbg_response =~ ^[ \t]*$ ]] ; then
		    _Dbg_response=$_Dbg_confirm_default
		    return 0
		else
		    _Dbg_msg "I don't understand \"$_Dbg_response\"."
		    _Dbg_msg "Please try again entering 'yes' or 'no'."
		fi
		;;
	esac

    done
}

function _Dbg_errmsg {
    typeset -r prefix='**'
    _Dbg_msg "$prefix $@"
}

function _Dbg_errmsg_no_cr {
    typeset -r prefix='**'
    _Dbg_msg_no_cr "$prefix $@"
}

function _Dbg_msg {
    print -r -- "$@" 
}

function _Dbg_msg_nocr {
    echo -n $@
}

# print message to output device
function _Dbg_printf {
  typeset format=$1
  shift
  if (( _Dbg_logging )) ; then
    printf "$format" "$@" >>$_Dbg_logfid
  fi
  if (( ! _Dbg_logging_redirect )) ; then
    if [[ -n $_Dbg_tty ]] ; then
      printf "$format" "$@" >>$_Dbg_tty
    else
      printf "$format" "$@"
    fi
  fi
  _Dbg_msg ''
}

# print message to output device without a carriage return at the end
function _Dbg_printf_nocr {
  typeset format=$1
  shift 
  if (( _Dbg_logging )) ; then
    printf "$format" "$@" >>$_Dbg_logfid
  fi
  if (( ! $_Dbg_logging_redirect )) ; then
    if [[ -n $_Dbg_tty ]] ; then 
      printf "$format" "$@" >>$_Dbg_tty
    else
      printf "$format" "$@"
    fi
  fi
}

# Common funnel for "Undefined command" message
_Dbg_undefined_cmd() {
    if (( $# == 2 )) ; then
	_Dbg_msg "Undefined $1 subcommand \"$2\". Try \"help $1\"."
    else
	_Dbg_msg "Undefined command \"$1\". Try \"help\"."
    fi
}
