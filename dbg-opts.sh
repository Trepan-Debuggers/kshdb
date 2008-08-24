# -*- shell-script -*-
# dbg-opts.sh - kshdb command options processing. The bane of programming.
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

typeset    _Dbg_tmpdir=/tmp
typeset -i _Dbg_opt_linetrace=0
typeset -i o_no_quit=0 

# Use gdb-style annotate?
typeset -i _Dbg_annotate=0

function _Dbg_usage_long {
  printf "usage:
    ${_Dbg_pname} [OPTIONS] <script_file>

Runs bash <script_file> under a debugger.

options: 
    -A | --annotate  LEVEL  set annotation level.
    -B | --basename         basename only on source listings. 
                            (Needed in regression tests)
    -h | --help             print this help
    -n | --nx |--no-init    Don't run initialization files
    -c cmd | --eval-command cmd  Run this passed argument as a script
    -q | --quiet     Quiet. Do not print introductory and quiet messages.
    -L libdir | --library libdir
                            set directory location of library helper file: $_Dbg_main
                            The default directory is: $_Dbg_libdir
    -T tmpdir | --tempdir   set directory location for temporary files: $_Dbg_tmpdir
    -t tty | --tty tty | --terminal tty
                            set debugger terminal
    -x command | --command cmdfile
                            execute debugger commands from cmdfile
    -X | --trace            set line tracing
    -V | --version          show version number and no-warranty and exit.

Long options may be abbreviated, e.g. --lib is okay for --library.
" 1>&2
}

_Dbg_usage_short() {
  printf "_Dbg_usage:
    ${_Dbg_pname} [OPTIONS] <script_file>

Runs script_file under a debugger.

options: 
    -A LEVEL     set annotation level.
    -B           basename only on source listings. (Needed in regression tests)
    -h           print this help
    -n           Don't run initialization files
    -c command   Run this passed command as a script
    -q           Quiet. Do not print introductory and quiet messages.
    -L libdir | --library libdir   
                 set directory location of library helper file: $_Dbg_main
                 the default directory is: $_Dbg_libdir
    -T tmpdir    set directory location for temporary files: $_Dbg_tmpdir
    -t tty       set debugger terminal
    -x cmdfile   execute debugger commands from cmdfile
    -X           set line tracing
    -Y           set line tracing with variable expansion
    -V           show version number and no-warranty and exit.
" 1>&2
}

# Process using short or long options, depending on the availability
# of getopt
TEMP=`getopt -o testing t 2>/dev/null`
if ((_Dbg_try_getopt && 0 == $? )) ; then
  # Process using long options
  # Note that we use `"$@"' to let each command-line parameter expand to a 
  # separate word. The quotes around `$@' are essential!
  # We need TEMP as the `eval set --' would nuke the return value of getopt.
  TEMP=`getopt -o A:Bc:hL:nqt:T::x:XYV \
--long annotate:,basename,command:,debugger,exec-command,help,library:,no-init,quiet,tempdir:,terminal:,trace,tty,version \
     -n 'kshdb' -- "$@"`

  if [ $? != 0 ] ; then 
    echo "Use --help for option help. Terminating..." >&2 ; 
    exit 1 ; 
  fi
  
  # Note the quotes around `$TEMP': they are essential!
  eval set -- "$TEMP"
  
  while true ; do
    case $1 in
      -A|--annotate) _Dbg_annotate="$2"; shift ;;
      -B|--basename) _Dbg_basename_only=1 ;;
      -c|--eval-command) _Dbg_cmd="$2"; shift ;;
      --debugger) ;;  # This option is for compatibility with bash --debugger
      -h|--help) _Dbg_usage_long; exit 100 ;;
      -L|--library) shift ;;  # Handled previously
      -n|--nx|--no-init) _Dbg_no_init=1 ;;
      -q|--quiet) _Dbg_quiet=1 ;;
      -T|--tempdir) _Dbg_tmpdir=$2; shift ;;
      -t|--terminal|--tty) 
	if ! $(touch $2 >/dev/null 2>/dev/null); then 
	  echo "${_Dbg_pname}: Can't access $2 for writing."
	elif [[ ! -w $2 ]] ; then
	  echo "${_Dbg_pname}: terminal $2 needs to be writable."
	else
	  _Dbg_tty=$2 ;
	fi
	shift
	;;
      -x|--command) DBG_INPUT="$DBG_INPUT $2"; shift ;;  
      -X|--trace) _Dbg_opt_linetrace=1 ;;  
      # -Y|--vtrace) _Dbg_opt_linetrace=1 ; _Dbg_opt_linetrace_expand=1 ;;  
      -V|--version) show_version=1 ;;
      --) shift ; break ;;
      *) 
	echo "Use --help for option help. Terminating..."
	exit 2 ;;
    esac
    shift
  done
else 
  # Process using short options
  while getopts :A:Bc:hL:nqt:T:x:XYV opt; do
    case $opt in
      A) _Dbg_annotate=1 ;;
      B) _Dbg_basename_only=1 ;;
      c) _Dbg_cmd="$OPTARG" ;;
      h) _Dbg_usage_short; exit 100 ;;
      n) _Dbg_no_init=1 ;;
      q) _Dbg_quiet=1 ;;
      L)  ;; # Handled previously
      T) _Dbg_tmpdir=$OPTARG ;;
      t) 
	if ! $(touch $OPTARG >/dev/null 2>/dev/null); then 
	  echo "${_Dbg_pname}: Can't access $OPTARG for writing."
	elif [[ ! -w $OPTARG ]] ; then
	  echo "${_Dbg_pname}: terminal $OPTARG needs to be writable."
	else
	  _Dbg_tty=$OPTARG
	fi
	;;
      V) show_version=1 ;;
      x) DBG_INPUT="$OPTARG" ;;
      X) _Dbg_opt_linetrace=1 ;;  
      # Y) _Dbg_opt_linetrace=1 ; _Dbg_opt_linetrace_expand=1 ;;  
      *) 
	if ((_Dbg_basename_only == 1)) ; then
	  echo "${_Dbg_pname}: unrecognized option -- $OPTARG"
	else
	  echo "$0: unrecognized option -- $OPTARG"
	fi
	echo "Use -h for option help. Terminating..."
	exit 2 
	;;
    esac
  done
  shift $(($OPTIND - 1))
fi
