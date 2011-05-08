# -*- shell-script -*-
# complete.sh - gdb-like command completion handling
#
#   Copyright (C) 2006, 2011 Rocky Bernstein <rocky@gnu.org>
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

typeset -a _Dbg_matches; _Dbg_matches=()

compgen_opt_words() {
    typeset -a result=()
    typeset -a words
    words=( $1 )
    typeset find
    find=$2
    typeset try
    for try in ${words[@]} ; do 
	if [[ $try =~ "^$find" ]] ; then 
	    result+=( $try )
	fi
    done
    COMPREPLY=( "${result[@]}" )
}

# Print a list of completions in global variable _Dbg_matches 
# for 'subcmd' that start with 'text'.
# We get the list of completions from _Dbg._*subcmd*_cmds.
# If no completion, we return the empty list.
_Dbg_subcmd_complete() {
    subcmd=$1
    text=$2
    _Dbg_matches=()
    typeset list=''
    if [[ $subcmd == 'set' ]] ; then 
	# Newer style
	list=${!_Dbg_command_help_set[@]}
    elif [[ $subcmd == 'show' ]] ; then 
	# Newer style
	list=${!_Dbg_command_help_show[@]}
    else
	# FIXME: Older style - eventually update these.
	cmd="list=\$_Dbg_${subcmd}_cmds"
	eval $cmd
    fi
    typeset -i last=0
    for word in $list ; do
        # See if $word contains $text at the beginning. We use the string
        # strip operatior '#' and check that some part of $word was stripped 
        if [[ ${word#$text} != $word ]] ; then 
            _Dbg_matches[$last]="$subcmd $word"
            ((last++))
        fi
    done
    # return _Dbg_matches
}

### FIXME: figure out corresponding ksh equivalent
# if enable -f ${_Dbg_libdir}/builtin/readc readc 2>/dev/null ; then
#     _Dbg_set_read_completion=1
#     # Turn on programmable completion
#     shopt -s progcomp
#     set -o emacs
#     bind 'set show-all-if-ambiguous on'
#     # bind 'set completion-ignore-case on'
#     # COMP_WORDBREAKS=${COMP_WORDBREAKS//:}
#     #bind 'TAB:dynamic-complete-history'
#     bind 'TAB:menu-complete'
#     _Dbg_set_read_completion=1
# fi

function _Dbg_complete_num_range {
    COMPREPLY=()
    typeset -i _Dbg_i
    typeset -i j=0
    for ((_Dbg_i=$1; _Dbg_i<=$2; _Dbg_i++)) ; do
	((COMPREPLY[j]+=_Dbg_i))
	((j++))
    done
}

_Dbg_complete_level0() {
    # echo "level 0 called with comp_line: $COMP_LINE , comp_point: $COMP_POINT"
    if (( COMP_POINT >  0)) ; then 
	typeset commands="${!_Dbg_command_help[@]}"
	compgen_opt_words "$commands" "$COMP_LINE"
	COMPREPLY=( $() )
    else
	COMPREPLY=( ${!_Dbg_command_help[@]} )
    fi
}

_Dbg_complete_level_0_init() {
    complete -D -F _Dbg_complete_level0
}

# Demo it
if [[ $0 == ${.sh.file##*/} ]] ; then
    typeset -a COMPREPLY
    compgen_opt_words "aa aab ac b a" "aa"
    typeset -p COMPREPLY
    PS4='(${.sh.file}:${LINENO}): ${.sh.fun} - [${.sh.subshell}] 
'

    compgen_opt_words "d dd e f" "d"
    typeset -p COMPREPLY
fi

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
