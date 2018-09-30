# -*- shell-script -*-
# dbg-processor.sh - Top-level debugger commands
#
#   Copyright (C) 2008-2011, 2014, 2018
#   Rocky Bernstein <rocky@gnu.org>
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

# Are we inside the middle of a "skip" command?
typeset -i  _Dbg_inside_skip=0

# Hooks that get run on each command loop
typeset -A _Dbg_cmdloop_hooks
_Dbg_cmdloop_hooks['display']='_Dbg_eval_all_display'

typeset _Dbg_prompt_str='$_Dbg_debugger_name<${_Dbg_less}1${_Dbg_greater}> '

# The canonical name of last command run.
typeset _Dbg_last_cmd=''

typeset last_next_step_cmd='s' # Default is step.

typeset _Dbg_last_print=''     # expression on last print command
typeset _Dbg_last_printe=''    # expression on last print expression command

# A list of debugger command input-file descriptors.
# Duplicate standard input
typeset -i _Dbg_fdi ; exec {_Dbg_fdi}<&0

# Save descriptor number
typeset -i _Dbg_fd_last=0

# keep a list of source'd command files. If the entry is "" then we are
# interactive.
typeset -a _Dbg_cmdfile; _Dbg_cmdfile=('')

# A list of debugger command input-file descriptors.
typeset -a _Dbg_fd=( $_Dbg_fdi )

# ===================== FUNCTIONS =======================================

# The main debugger command reading loop.
#
# Note: We have to be careful here in naming "local" variables. In contrast
# to other places in the debugger, because of the read/eval loop, they are
# in fact seen by those using the debugger. So in contrast to other "local"s
# in the debugger, we prefer to preface these with _Dbg_.
function _Dbg_process_commands {

  # initial debugger input source from kshdb arguments
  if [[ ! -z "$_Dbg_tty_in" ]] && [[  -r "$_Dbg_tty_in" ]]
  then
    exec {_Dbg_fdi}<$_Dbg_tty_in
    _Dbg_fd[++_Dbg_fd_last]=$_Dbg_fdi
    _Dbg_cmdfile+=("$_Dbg_tty_in")
  fi

  _Dbg_inside_skip=0
  _Dbg_continue_rc=-1  # Don't continue execution unless told to do so.
  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"

  # Nuke any prior step-ignore counts
  _Dbg_write_journal_eval "_Dbg_step_ignore=-1"

  # Evaluate all the display expressions
  typeset -l key

  # Evaluate all hooks
  for hook in ${_Dbg_cmdloop_hooks[@]} ; do
      ${hook}
  done

  # Loop over all pending open input file descriptors
  while (( _Dbg_fd_last >= 0 )) ; do

    # Set up prompt to show shell and subshell levels.
    typeset _Dbg_greater=''
    typeset _Dbg_less=''
    typeset result  # Used by copies to return a value.

    if _Dbg_copies '>' $_Dbg_DEBUGGER_LEVEL ; then
	_Dbg_greater=$result
	_Dbg_copies '<' $_Dbg_DEBUGGER_LEVEL
      	_Dbg_less=$result
    fi

    _Dbg_copies ')' ${.sh.subshell}
    if  (( $? == 0 )); then
      	_Dbg_greater="${result}${_Dbg_greater}"
	_Dbg_copies '(' ${.sh.subshell}
      	_Dbg_less="${_Dbg_less}${result}"
    fi

    typeset _Dbg_prompt="${_Dbg_debugger_name}${_Dbg_less}1${_Dbg_greater} "
    _Dbg_preloop
    typeset _Dbg_cmd
    typeset args
    while read "_Dbg_cmd?$_Dbg_prompt" args <&${_Dbg_fd[_Dbg_fd_last]}
    do
    	_Dbg_onecmd "$_Dbg_cmd" "$args"
        rc=$?
        # _Dbg_postcmd
        (( rc > 0 && rc != 255 )) && return $rc
    done
    unset _Dbg_fd[_Dbg_fd_last]
    ((_Dbg_fd_last--))
  done  # Loop over all open pending file descriptors

  # EOF hit. Same as quit without arguments
  _Dbg_msg "That's all folks..." # Cause <cr> since EOF may not have put in.
  _Dbg_do_quit

}

# Run a debugger command "annotating" the output
_Dbg_annotation() {
  typeset label="$1"
  shift
  _Dbg_do_print "$label"
  $*
  _Dbg_do_print  ''
}

# Run a single command
# Parameters: _Dbg_cmd and args
#
_Dbg_onecmd() {
    typeset full_cmd; full_cmd=$@
    typeset _Dbg_orig_cmd="$1"
    typeset expanded_alias; _Dbg_alias_expand "$_Dbg_orig_cmd"
    typeset _Dbg_cmd="$expanded_alias"
    typeset _Dbg_args=$args
    eval "set -- \"$2\""

     # Set default next, step or skip command
     if [[ -z $_Dbg_cmd ]]; then
	_Dbg_cmd=$_Dbg_last_next_step_cmd
	# FIXME: remove $args
	args=$_Dbg_last_next_step_args
	_Dbg_args=$_Dbg_last_next_step_args
	full_cmd="$_Dbg_cmd $_Dbg_args"
     fi

     # If "set trace-commands" is "on", echo the the command
     if [[  $_Dbg_set_trace_commands == 'on' ]]  ; then
	 _Dbg_msg "+$_Dbg_cmd $args"
     fi

     typeset -i _Dbg_redo=1
     while (( _Dbg_redo )) ; do

	 _Dbg_redo=0

	 [[ -z $_Dbg_cmd ]] && _Dbg_cmd=$_Dbg_last_cmd
	 if [[ -n $_Dbg_cmd ]] ; then
	     typeset -i found=0
	     if [[ -n ${_Dbg_debugger_commands[$_Dbg_cmd]} ]] ; then
		 found=1
	     else
		 # Look for a unique abbreviation
		 typeset -i count=0
		 typeset list; list="${!_Dbg_debugger_commands[@]}"
		 for try in $list ; do
		     if [[ $try =~ ^$_Dbg_cmd ]] ; then
			 _Dbg_cmd=$try
			 ((count++))
		     fi
		 done
		 ((found=(count==1)))
	     fi
	     if ((found)); then
		 ${_Dbg_debugger_commands[$_Dbg_cmd]} $_Dbg_args
		 IFS=$_Dbg_space_IFS;
		 # eval "_Dbg_prompt=$_Dbg_prompt_str"
		 ((_Dbg_continue_rc >= 0)) && return $_Dbg_continue_rc
		 continue
	     fi
	 fi

	 case $_Dbg_cmd in
	     # Comment line
	     [#]* )
		 # _Dbg_remove_history_item
		 _Dbg_last_cmd="#"
		 ;;

	     alias )
		 _Dbg_do_alias $@
		 ;;

	     # Set breakpoint on a line
	     break )
		 _Dbg_do_break $args
		 _Dbg_last_cmd="break"
		 ;;

# 	# Delete all breakpoints by line number.
# 	clear )
# 	  _Dbg_do_clear_brkpt $args
# 	  _Dbg_last_cmd='clear'
# 	  ;;

	     # Continue
	     continue )

		 _Dbg_last_cmd='continue'
		 if _Dbg_do_continue $@ ; then
		     # _Dbg_write_journal_eval \
		     #  "_Dbg_old_set_opts=\"$_Dbg_old_set_opts -o functrace\""
		     return 1
		 fi
		 ;;

	     # single-step ignoring functions
	     'next+' | 'next-' | 'next' )
		 _Dbg_do_next "$_Dbg_cmd" $@
		 return $?
		 ;;

	     # skip N times (default 1)
	     sk | ski | skip )
		 _Dbg_last_cmd='skip'
		 _Dbg_do_skip $@ && return 2
		 ;;

	     # Command to show debugger settings
	     show )
		 _Dbg_do_show $args
		 _Dbg_last_cmd='show'
		 ;;


	     # single-step
	     'step+' | 'step-' | 'step' )
		 _Dbg_do_step "$_Dbg_cmd" $@
		 return $?
		 ;;

	     # Trace a function
	     trace )
		 _Dbg_do_trace_fn $args
		 ;;

	     # 	# Remove a function trace
	     # 	unt | untr | untra | untrac | untrace )
	     # 	  _Dbg_do_untrace_fn $args
	     # 	  ;;

	     backtrace )
		 _Dbg_do_backtrace $@
		 ;;

	     '' )
		 # Redo last_cmd
		 if [[ -n $_Dbg_last_cmd ]] ; then
		     _Dbg_cmd=$_Dbg_last_cmd
		     _Dbg_redo=1
		 fi
		 ;;

	     * )
		 if (( _Dbg_set_autoeval )) ; then
		     ! _Dbg_do_eval $_Dbg_cmd $args && return 255
		 else
		     _Dbg_undefined_cmd $_Dbg_cmd
		     # _Dbg_remove_history_item
		     # typeset -a last_history=(`history 1`)
		     # history -d ${last_history[0]}
		     return 255
		 fi
	     ;;
	 esac
     done # while (( $_Dbg_redo ))

     return 0
}

_Dbg_preloop() {
    if ((_Dbg_set_annotate)) ; then
	_Dbg_annotation 'breakpoints' _Dbg_do_info breakpoints
	# _Dbg_annotation 'locals'      _Dbg_do_backtrace 3
	_Dbg_annotation 'stack'       _Dbg_do_backtrace 3
    fi
}

_Dbg_postcmd() {
    if ((_Dbg_set_annotate)) ; then
	case $_Dbg_last_cmd in
            break | tbreak | disable | enable | condition | clear | delete )
		_Dbg_annotation 'breakpoints' _Dbg_do_info breakpoints
		;;
	    up | down | frame )
		_Dbg_annotation 'stack' _Dbg_do_backtrace 3
		;;
	    * )
	esac
    fi
}
