#!/usr/bin/ksh93t
# Are we using a debugger-enabled ksh? If not let's stop right here.
if [[ -z "$.sh.level}" ]] ; then 
  echo "Sorry, your ksh just isn't modern enough." 2>&1
  exit 2
fi

_Dbg_libdir='.'
. ${_Dbg_libdir}/dbg-main.sh

# Note that this is called via zshdb rather than "zsh --debugger" or zshdb-trace
_Dbg_script=1

# TEMPORARY: Save me typing in testing.
if (( ${#_Dbg_script_args[@]} > 0 )) ; then
    _Dbg_script_file="$_Dbg_script_args[1]"
else
    # _Dbg_script_file=./testing.sh
    _Dbg_script_file=./file2.sh
    _Dbg_script_args=($_Dbg_script_file)
fi

  _Dbg_step_ignore=2
trap '_Dbg_debug_trap_handler "$@"' DEBUG
. ${_Dbg_script_args[@]}
_Dbg_msg "Program terminated."
 # _Dbg_msg "Program terminated. Type 's' or 'R' to restart."
