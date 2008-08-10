# dbg-sig.inc - Bourne Again Shell Debugger Signal handling routines
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

# ==================== VARIABLES =======================================

# The "set" options in effect ($-) before debugger was invoked.
typeset _Dbg_old_setopts

# Place to save debugged program's exit handler, if any.
typeset _Dbg_old_EXIT_handler=''  

typeset KSHDB_RESTART_COMMAND=''
typeset -i KSHDB_QUIT_ON_QUIT=0

# Return code that debugged program reports
typeset -i _Dbg_program_exit_code=0

# This is set to 1 if you want to debug debugger routines, i.e. routines
# which start _Dbg_. But you better should know what you are doing
# if you do this or else you may get into a recursive loop.
typeset -i _Dbg_debug_debugger=0

############################################################
## Signal arrays: These are indexed by the signal number. ##
############################################################

# Should we print that a signal was intercepted? 
# Each entry is "print" or "noprint" or null.
typeset -a _Dbg_sig_print=()

# Should we reentry the debugger command loop on receiving the signal? 
# Each entry is "stop" or "nostop" or null.
typeset -a _Dbg_sig_stop=()

# Should we show a traceback on receiving the signal? 
# Each entry is "stack" or "nostack" or null.
typeset -a _Dbg_sig_show_stack=()

# Should pass the signal to the user program?? 
# Each entry is the trap handler with some variables substituted.
typeset -a _Dbg_sig_passthrough=()

# Should pass the signal to the user program?? 
# Each entry is the trap handler with some variables substituted.
typeset -i _Dbg_return_level=0

# Place to save values of $1, $2, etc.
typeset -a _Dbg_arg=()

# ===================== FUNCTIONS =======================================

# We come here after before statement is run. This is the function named
# in trap SIGDEBUG.

# Note: We have to be careful here in naming "local" variables. In contrast
# to other places in the debugger, because of the read/eval loop, they are
# in fact seen by those using the debugger. So in contrast to other "local"s
# in the debugger, we prefer to preface these with _Dbg_.

function _Dbg_debug_trap_handler {

  integer .level=.sh.level .max=.sh.level-1
  print  -r "command ${.sh.command}"
  while((--.level>=0))
  do
      typeset file=${.sh.file}
      ((.sh.level = .level))
      _Dbg_print_frame '##' "$((.max-.level))" "$0" "$file" "${.sh.lineno}" "$@"
      file=${.sh.file}
  done
  print -- '++++'
  _Dbg_set_to_return_from_debugger 1
  return 0
  


  typeset -i _Dbg_rc=0

  _Dbg_ksh_command="${0} $@"

  ### The below is also copied below in _Dbg_sig_handler...
  ### Should put common stuff into a function.

  # Consider putting the following line(s) in a routine.
  # Ditto for the restore environment
  typeset -i _Dbg_debugged_exit_code=$?
  _Dbg_old_set_opts=$-

  # Turn off line and variable trace listing if were not in our own debug
  # mode, and set our own PS4 for debugging inside the debugger
  ## FIXME:
  ## (( !_Dbg_debug_debugger )) && set +x +v +u

  # If we are in our own routines -- these start with _kshdb -- then
  # return.
  ## FIXME:
  ## if [[ ${.sh.fun} == _Dbg_* ]] && ((  !_Dbg_debug_debugger )); then
  ##  _Dbg_set_to_return_from_debugger 0
  ##  return 0
  ## fi

  _Dbg_set_debugger_entry 2

  # Save values of $1 $2 $3 when debugged program was stopped
  # We use the loop below rather than _Dbg_set_args="(@)" because
  # we want to preserve embedded blanks in the arguments.
  typeset -i _Dbg_n=${#@}
  typeset -i _Dbg_i
  typeset -i _Dbg_arg_max=${#_Dbg_arg[@]}

  # If there has been a shift since the last time we entered,
  # it is possible that _Dbg_arg will contain too many values.
  # So remove those that have disappeared.
  for (( _Dbg_i=_Dbg_arg_max; _Dbg_i > _Dbg_n ; _Dbg_i-- )) ; do
      unset _Dbg_arg[$_Dbg_i]
  done
 
  # Populate _Dbg_args with $1, $2, etc.
  for (( _Dbg_i=1 ; _Dbg_n > 0; _Dbg_n-- )) ; do
    _Dbg_arg[$_Dbg_i]=$1
    ((_Dbg_i++))
    shift
  done
  unset _Dbg_arg[0]       # Get rid of line number; makes array count
                          # correct; also listing all _Dbg_arg works
                          # like $*.

  # Read in the journal to pick up variable settings that might have
  # been left from a subshell.
  ## _Dbg_source_journal

  if (( $KSHDB_QUIT_LEVELS > 0 )) ; then
    _Dbg_do_quit $_Dbg_debugged_exit_code
  fi

  # if in step mode, decrement counter
  if ((_Dbg_steps >= 0)) ; then 
    ((_Dbg_steps--))
    _Dbg_write_journal "_Dbg_steps=$_Dbg_steps"
  fi

  # look for watchpoints.
  typeset -i _Dbg_i
  for (( _Dbg_i=0; _Dbg_i < _Dbg_watch_max ; _Dbg_i++ )) ; do
    if [ -n "${_Dbg_watch_exp[$_Dbg_i]}" ] \
      && [[ ${_Dbg_watch_enable[_Dbg_i]} != 0 ]] ; then
      typeset new_val=`_Dbg_get_watch_exp_eval $_Dbg_i`
      typeset old_val=${_Dbg_watch_val[$_Dbg_i]}
      if [[ $old_val != $new_val ]] ; then
	((_Dbg_watch_count[_Dbg_i]++))
	_Dbg_msg "Watchpoint $_Dbg_i: ${_Dbg_watch_exp[$_Dbg_i]} changed:"
	_Dbg_msg "  old value: '$old_val'"
	_Dbg_msg "  new value: '$new_val'"
	_Dbg_print_source_line
	_Dbg_watch_val[$_Dbg_i]=$new_val
	_Dbg_cmdloop
	_Dbg_set_to_return_from_debugger 1
	return $_Dbg_rc
      fi
    fi
  done

  # Run applicable action statement
  typeset entries=`_Dbg_get_assoc_array_entry "_Dbg_action_$_cur_filevar" $_curline`
  if [[ $entries != "" ]]  ; then
    typeset -i _Dbg_i
    for _Dbg_i in $entries ; do
      if [[ ${_Dbg_action_enable[_Dbg_i]} != 0 ]] ; then
	. ${_Dbg_libdir}/dbg-set-d-vars.inc
	eval "${_Dbg_action_stmt[$_Dbg_i]}"
      fi
    done
  fi

  # check if breakpoint reached
  typeset -r entries=`_Dbg_get_assoc_array_entry "_Dbg_brkpt_$_cur_filevar" $_curline`
  if [[ $entries != "" ]]  ; then
    typeset -i _Dbg_i
    for _Dbg_i in $entries ; do
      if [[ ${_Dbg_brkpt_enable[_Dbg_i]:0} != 0 ]] ; then
	typeset -i cond
	. ${_Dbg_libdir}/dbg-set-d-vars.inc
	eval let cond=${_Dbg_brkpt_cond[$_Dbg_i]:0}
	if [[ $cond != 0 ]] ; then
	  ((_Dbg_brkpt_count[_Dbg_i]++))
	  if [[ ${_Dbg_brkpt_onetime[_Dbg_i]:0} == 1 ]] ; then
	    _Dbg_stop_reason='at a breakpoint that has since been deleted'
	    _Dbg_delete_brkpt_entry $_Dbg_i
	  else
	    _Dbg_stop_reason='at breakpoint'
	    _Dbg_currentbp=$_Dbg_i
	    _Dbg_msg \
              "Breakpoint $_Dbg_i hit (${_Dbg_brkpt_count[$_Dbg_i]} times)."
	  fi
	  # We're sneaky and check commands_end because start could 
	  # legitimately be 0.
	  if (( ${_Dbg_brkpt_commands_end[$_Dbg_i]} )) ; then
	      # Run any commands associated with this breakpoint
	      _Dbg_bp_commands $_Dbg_i
	  fi
	  _Dbg_print_source_line
	  _Dbg_cmdloop		# enter debugger
	  _Dbg_set_to_return_from_debugger 1
	  return $_Dbg_rc
	fi
      fi

    done
  fi

  # next, check if step mode and no. of steps is up
  if ((_Dbg_steps == 0)); then
    _Dbg_stop_reason='after being stepped'
    _Dbg_print_source_line
    # _Dbg_msg "Stopped at line $_curline"
    _Dbg_cmdloop		# enter debugger
    _Dbg_set_to_return_from_debugger 1
    return $_Dbg_rc
  elif (( ${#FUNCNAME[@]} == _Dbg_return_level )) ; then
    # here because a trap RETURN
    _Dbg_stop_reason='on a return'
    _Dbg_return_level=0
    _Dbg_print_source_line
    _Dbg_cmdloop		# enter debugger
    _Dbg_set_to_return_from_debugger 1
    return $_Dbg_rc
  elif (( -1 == _Dbg_return_level )) ; then
    # here because we are fielding a signal.
    _Dbg_stop_reason='on fielding signal'
    _Dbg_print_source_line
    _Dbg_cmdloop		# enter debugger
    _Dbg_set_to_return_from_debugger 1
    return $_Dbg_rc
  else
    if ((_Dbg_linetrace==1)) ; then 
      if ((_Dbg_linetrace_delay)) ; then
	  sleep $_Dbg_linetrace_delay
      fi
      _Dbg_print_linetrace
    fi
  fi
  _Dbg_set_to_return_from_debugger 1
  # return $_Dbg_inside_skip
}

# Cleanup routine: erase temp files before exiting.
function _Dbg_cleanup {
  rm $_Dbg_evalfile 2>/dev/null
  _Dbg_erase_journals
  _Dbg_restore_user_vars
}

# Somehow we can't put this in _Dbg_cleanup and have it work.
# I am not sure why.
function _Dbg_cleanup2 {
  _Dbg_erase_journals
  trap - EXIT
}

# The real way to leave this program.
function _Dbg_do_quit {
  typeset -i return_code=${1:-$_Dbg_program_exit_code}

  typeset -i desired_quit_levels=${2:-0}

  if (( desired_quit_levels == 0 \
    || desired_quit_levels > .sh.subshell+1)) ; then
    ((desired_quit_levels=.sh.subshell+1))
  fi

  ((KSHDB_QUIT_LEVELS+=desired_quit_levels))

  # Reduce the number of recorded levels that we need to leave by
  # if KSHDB_QUIT_LEVELS is greater than 0.
  ((KSHDB_QUIT_LEVELS--))

  ## write this to the next level up can read it.
  _Dbg_write_journal "KSHDB_QUIT_LEVELS=$KSHDB_QUIT_LEVELS"

  # Reset signal handlers to their default but only if 
  # we are not in a subshell.
  if (( .sh.subshell == 0 )) ; then

    # If we were told to restart from deep down, restart instead of quit.
    if [ -n "$KSHDB_RESTART_COMMAND" ] ; then 
      _Dbg_erase_journals
      _Dbg_save_state
      exec $KSHDB_RESTART_COMMAND
    fi

    _Dbg_cleanup

    # Save history file
    if (( $_Dbg_history_save )) ; then
	history -w $_Dbg_histfile
    fi

    trap - DEBUG
    # This is a hack we need. I am not sure why.
    trap "_Dbg_cleanup2" EXIT
  fi

  # And just when you thought we'd never get around to it...
  exit $return_code
}

# Save value of handler variable _Dbg_old_$sig
function _Dbg_save_handler {
  typeset -r sig=$1
  typeset old_handler='#unset#';
  if [[ `trap -p $sig` ]] ; then 
    old_handler=`trap -p $sig`
  fi
  if [[ $old_handler != '#unset#' ]] ; then
    typeset -a old_hand_a
    old_hand_a=($old_handler)
    old_handler=`_Dbg_subst_handler_var ${old_hand_a[2]}`
    typeset -r decl_cmd="typeset -r _Dbg_old_${sig}_handler='$old_handler'"
    eval $decl_cmd
  fi
  
}

# Adjust handler variables to take into account the fact that when we
# call the handler we will have added another call before the user's
# handler.
function _Dbg_subst_handler_var {
  typeset -i i
  typeset result=''
  for arg in $* ; do 
    case $arg in 
    '$LINENO' )
	arg='${BASH_LINENO[0]}'
	;;
    '${BASH_SOURCE[0]}' )
	arg='${BASH_SOURCE[1]}'
	;;
    '${FUNCNAME[0]}' )
	arg='${FUNCNAME[1]}'
	;;
    '${BASH_LINENO[0]}' )
	arg='${BASH_LINENO[1]}'
	;;
    esac
    if [[ $result == '' ]] ; then
      result=$arg 
    else
      result="$result $arg"
    fi
  done
  echo $result
}

# Debugger exit handler. Don't really exit - but go back the debugger 
# command loop
function _Dbg_exit_handler {

  # Consider putting the following line(s) in a routine.
  # Ditto for the restore environment
  typeset -i _Dbg_debugged_exit_code=$?

  # Turn off line and variable trace listing; allow unset parameter expansion.
  set +x +v +u

  if [[ ${_Dbg_sig_print[0]} == "print" ]] ; then 
    # Note: use the same message that gdb does for this.
    _Dbg_msg "Program received signal EXIT (0)..."
    if [[ ${_Dbg_sig_show_stack[0]} == "showstack" ]] ; then 
      _Dbg_do_stack_trace 0
    fi
  fi

  if [[ $_Dbg_old_EXIT_handler != '' ]] ; then
    eval $_Dbg_old_EXIT_handler
  fi

  # If we've set the QUIT signal handler not to stop, or we've in the
  # middle of leaving so many (subshell) levels or we have set to
  # leave quietly on termination, then do it!

  if [[ ${_Dbg_sig_stop[0]} != "stop" ]] \
    || (( KSHDB_QUIT_LEVELS != 0 )) \
    || (( KSHDB_QUIT_ON_QUIT )) ; then 
    _Dbg_do_quit
    # We don't return from here.
  fi

  # We've tested for all the quitting conditions above.
  # Even though this is an exit handler, don't exit!

  typeset term_msg="normally"
  if [[ $_Dbg_debugged_exit_code != 0 ]] ; then 
    term_msg="with code $_Dbg_debugged_exit_code"
  fi

  # If we tried to exit from inside a subshell, we only want to enter
  # the command loop if don't have any pending subshells. 
  if (( .sh.subshell == 0 )) ; then 
    _Dbg_msg \
      "Debugged program terminated $term_msg. Use q to quit or R to restart."

    _Dbg_running=0
    while [[ 1 ]] ; do
      _Dbg_cmdloop
    done
  fi
}

# Generic signal handler for kshdb. We consult global array
# _Dbg_sig_* for how to handle this signal.

# Since the command loop may be called we need to be careful about
# using variable names that would be exposed to the user. 
function _Dbg_sig_handler {

  # Consider putting the following line(s) in a routine.
  # Ditto for the restore environment
  typeset -i _Dbg_debugged_exit_code=$?
  _Dbg_old_set_opts=$-
  
  # Turn off line and variable trace listing; allow unset parameter expansion.
  set +x +v +u

  typeset -i _Dbg_rc=0

  # This is the signal number. E.g. 15 is SIGTERM
  typeset -r -i _Dbg_signum=$1   

  if [[ ${_Dbg_sig_print[$_Dbg_signum]} == "print" ]] || \
     [[ ${_Dbg_sig_stop[$_Dbg_signum]} == "stop" ]] ; then
    typeset -r name=`_Dbg_signum2name $_Dbg_signum`
    # Note: use the same message that gdb does for this.
    _Dbg_msg "Program received signal $name ($_Dbg_signum)..."
    if [[ ${_Dbg_sig_show_stack[$_Dbg_signum]} == "showstack" ]] ; then 
      typeset -i n=${#FUNCNAME[@]}
      _Dbg_do_stack_trace 0 $n 0
    fi
  fi
  if [[ ${_Dbg_sig_stop[$_Dbg_signum]} == "stop" ]] ; then

    ### The below duplicates what is above in _Dbg_debug_trap handler
    ### Should put common stuff into a function.
    
    shift  # signum

    _Dbg_bash_command=$1
    shift

    # Save values of $1 $2 $3 when debugged program was stopped
    # We use the loop below rather than _Dbg_set_args="(@)" because
    # we want to preserve embedded blanks in the arguments.
    typeset -i _Dbg_n=${#@}
    typeset -i _Dbg_i=1
    for (( ; _Dbg_n > 0; _Dbg_n-- )) ; do
      _Dbg_arg[$_Dbg_i]=$1
      ((_Dbg_i++))
      shift
    done
    unset _Dbg_arg[0]       # Get rid of line number; makes array count
    # correct; also listing all _Dbg_arg works
    # like $*.

    _Dbg_set_debugger_entry
    _Dbg_cmdloop		# enter debugger
    _Dbg_set_to_return_from_debugger 1
    return $_Dbg_rc

  elif (( _Dbg_sig_old_handler[_Dbg_signum] )) ; then
    eval ${_Dbg_sig_old_handler[$_Dbg_signum]}
  fi
  _Dbg_set_to_return_from_debugger 1
  return $_Dbg_debugged_exit_code
}

function _Dbg_err_handler {
  if [[ $_Dbg_old_ERR_handler != '' ]] ; then
    eval $_Dbg_old_ERR_handler
  fi
  _Dbg_msg "Error occured at ${BASH_SOURCE[1]}:${BASH_LINENO[1]}"
  _Dbg_cmdloop
}

# Echo the name for a given signal number $1. The resulting name
# is in _Dbg_return
function _Dbg_signum2name {
  typeset -i -r signum=$1;
  kill -l $signum 2>/dev/null
  return $?
}

# Return the signal number for a given signal name $1. The resulting number
# is in _Dbg_return
function _Dbg_name2signum {
  typeset -r signame=$1;
  kill -l $signame 2>/dev/null
  return $?
}

# Process debugger "handle" command. 
function _Dbg_do_handle {
  typeset sig=$1
  typeset cmd=$2
  typeset -i signum
  if [[ -z $sig ]] ; then
    _Dbg_msg "Missing signal name or signal number."
    return 1
  fi

  eval "$_seteglob"
  if [[ $sig == $int_pat ]]; then
    eval "$_resteglob"
    signame=`_Dbg_signum2name $sig`
    if (( $? != 0 )) ; then
      _Dbg_msg "Bad signal number: $sig"
      return 1
    fi
    signum=sig
  else
    eval "$_resteglob"
    typeset signum;
    signum=`_Dbg_name2signum $sig`
    if (( $? != 0 )) ; then
      _Dbg_msg "Bad signal name: $sig"
      return 1
    fi
  fi

  case $cmd in
    nop | nopr | nopri | noprin | noprint )
      _Dbg_sig_print[signum]='noprint'
      # noprint implies nostop
      _Dbg_sig_stop[signum]='stop'
      ;;

    nosta | nostac | nostack )
      _Dbg_sig_show_stack[signum]='nostack'
      ;;

    nosto | nostop  )
      _Dbg_sig_stop[signum]='nostop'
      ;;

    p | pr | pri | prin | print )
      _Dbg_sig_print[signum]='print'
      ;;

    sta | stac | stack )
      _Dbg_sig_show_stack[signum]='showstack'
      ;;

    sto | stop )
      _Dbg_sig_stop[signum]='stop'
      # stop keyword implies print
      _Dbg_sig_print[signum]='print'
      ;;
    * )
      if (( !cmd )) ; then 
	_Dbg_msg \
         "Need to give a command: stop, nostop, stack, nostack, print, noprint"
      else
	_Dbg_msg "Invalid handler command $cmd"
      fi
      ;;
  esac
}

# Process debugger "signal" command. 
function _Dbg_do_signal {
  typeset sig=$1
  typeset -i signum
  if [[ -z $sig ]] ; then
    _Dbg_msg "Missing signal name or signal number."
    return 1
  fi

  eval "$_seteglob"
  if [[ $sig == $int_pat ]]; then
    eval "$_resteglob"
    signame=`_Dbg_signum2name $sig`
    if (( $? != 0 )) ; then
      _Dbg_msg "Bad signal number: $sig"
      return 1
    fi
    signum=sig
  else
    eval "$_resteglob"
    typeset signum;
    signum=`_Dbg_name2signum $sig`
    if (( $? != 0 )) ; then
      _Dbg_msg "Bad signal name: $sig"
      return 1
    fi
  fi
  kill -$signum $$
}

function _Dbg_subexit_handler {
  # Read in the journal to pick up variable settings that might have
  # been left from a subshell.
  if [[ ${FUNCNAME[1]} == _Dbg_* ]] && (( !_Dbg_debug_debugger )); then
    return 0
  fi
  _Dbg_source_journal
  if (( $KSHDB_QUIT_LEVELS > 0 )) ; then
    __Dbg_do_quit $_Dbg_debugged_exit_code
  fi
}

# Set up generic trap handler. Arguments are: 
# NAME print showstack stop passthrough
_Dbg_init_trap() {
  typeset -r name=$1
  typeset -i -r signum=`_Dbg_name2signum $name`

  _Dbg_sig_print[$signum]=$2;
  _Dbg_sig_show_stack[$signum]=$3;
  _Dbg_sig_stop[$signum]=$4;

  # Work out passthrough later...
  # if [[ $5 == "pass*" ]] ; then
  #  get existing trap from env.
  #  _Dbg_sig_show_passthrough[$signum]=....;
  #

  if (( signum == 0 )) ; then
    trap '_Dbg_exit_handler "${.sh.command}"' EXIT
  else
    typeset trap_cmd="trap '_Dbg_sig_handler $signum \"\${.sh.command}\" \"\$@\"' $name"
    eval $trap_cmd
  fi
}

## _Dbg_init_trap EXIT   "noprint" "nostack" "stop" 
# _Dbg_init_trap ILL    "print" "showstack" "stop" 
# _Dbg_init_trap INT    "print" "showstack" "stop" 
# _Dbg_init_trap QUIT   "print" "showstack" "stop" 
# _Dbg_init_trap TERM   "print" "showstack" "stop" 
# _Dbg_init_trap TRAP   "print" "showstack" "stop" 

# This is put at the so we have something at the end to stop at 
# when we debug this. By stopping at the end all of the above functions
# and variables can be tested.
typeset -r _Dbg_sig_ver=\
'$Id: dbg-sig.inc,v 1.22 2007/11/12 12:00:52 rockyb Exp $'

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; End: ***
