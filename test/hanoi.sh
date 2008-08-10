#!/bin/bash
# $Id: hanoi.sh.in,v 1.7 2006/12/10 18:08:50 rockyb Exp $
# Towers of Hanoi
# We've added calls to set line tracing if the 1st argument is "trace"

init() {
  # We want to test _Dbg_set_trace inside a call
  if (( $tracing )) ; then
    _Dbg_linetrace_on
  fi
}

function hanoi { 
  typeset -i n=$1
  # Mul
  # _Dbg_set_trace
  typeset -r a=$2
  typeset -r b=$3
  typeset -r c=$4
  if (( n > 0 )) ; then
    (( n-- ))
    hanoi $n $a $c $b
    ((disc_num=max-n))
    echo "Move disk $n on $a to $b"
    if (( n > 0 )) ; then
       hanoi $n $c $b $a
    fi
  fi
}

typeset -i max=3
typeset -i tracing=0
if [[ "$1" = 'trace' ]] ; then
  if [[ -n $2 ]] ; then
      builddir=$2
  elif [[ -z $builddir ]] ; then
      builddir=`pwd`
  fi
  tracing=1
  source ${builddir}/bashdb-trace -q -L ../ -B  -x settrace.cmd
fi
init
hanoi $max "a" "b" "c"
if (( $tracing )) ; then
  _Dbg_linetrace_off
  KSHDB_QUIT_ON_QUIT=1
fi
