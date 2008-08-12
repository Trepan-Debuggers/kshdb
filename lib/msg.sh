# -*- shell-script -*-
# dbg-fns.inc - Debugger Utility Functions
#
#   Copyright (C) 2008 Rocky Bernstein rocky@gnu.org
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

function _Dbg_errmsg {
    typeset -r prefix='**'
    _Dbg_msg "$prefix $@"
}

function _Dbg_errmsg_no_cr {
    typeset -r prefix='**'
    _Dbg_msg_no_cr "$prefix $@"
}

function _Dbg_msg {
    print -- "$@" 
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

