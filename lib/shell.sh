# -*- shell-script -*-
# shell.sh - helper routines for 'shell' debugger command
#
#   Copyright (C) 2011 Rocky Bernstein <rocky@gnu.org>
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

_Dbg_shell_temp_profile=$(_Dbg_tempname profile)

_Dbg_shell_append_typesets() {
    typeset -a _Dbg_words 
    typeset -a _Dbg_excluded
    _Dbg_excluded=([_]=1 [namespace]=1 ['']=1 ['{']=1 ['}']=1)
    typeset +p | while read -A _Dbg_words ; do 
	if [[ typeset != ${_Dbg_words[0]} ]] ; then
	    [[ -n ${_Dbg_excluded[${_Dbg_words[0]}]} ]] && continue
	    if [[ ${_Dbg_words[0]} =~ ^[A-Za-z_][A-Za-z_0-9]* ]] ; then
		((0 == _Dbg_set_debug)) && \
		    [[ ${_Dbg_words[0]} =~ ^_Dbg_ ]] && continue
		echo $(typeset -p ${_Dbg_words[0]} 2>/dev/null)
		continue
	    fi
	fi
	typeset -i _Dbg_i
	for ((_Dbg_i=1; _Dbg_i<${#_Dbg_words[@]}; _Dbg_i++)); do
	    _Dbg_var_name=${_Dbg_words[_Dbg_i]%%=*}
	    ((0 == _Dbg_set_debug)) && \
		[[ $_Dbg_var_name =~ ^_Dbg_ ]] && continue
	    _Dbg_flags=${_Dbg_words[_Dbg_i]}
	    case ${_Dbg_flags:0:2} in 
		'-x' )
		    # Skip exported varables
		    break
		    ;;
		'-n' )
                    break
		    ;;
		'-r' )
		    # handle read-only variables
		    echo "typeset -p ${_Dbg_var_name} &>/dev/null || $(typeset -p ${_Dbg_var_name})"
		    ;;
		-* )
		    continue
		    ;;
		* )
		    if [[ ${_Dbg_var_name} =~ ^[A-Za-z_][A-Za-z_0-9]+ ]] ; then
			# echo handling ${_Dbg_var_name} >&2
			[[ -n ${_Dbg_excluded[${_Dbg_var_name}]} ]] && break
			echo $(typeset -p ${_Dbg_var_name} 2>/dev/null) 
		    fi
		    ;;
	    esac
	done
    done >>$_Dbg_shell_temp_profile 
}

_Dbg_shell_append_fn_typesets() {
    typeset -a words 
    typeset +pf | while read -A words ; do 
	fn_name=${words[0]%%'('*}
	((0 == _Dbg_set_debug)) && [[ $fn_name =~ ^_Dbg_ ]] && continue	
	typeset -pf ${fn_name}  >>$_Dbg_shell_temp_profile
    done 
}

_Dbg_shell_new_shell_profile() {
    typeset -i _Dbg_o_vars; _Dbg_o_vars=${1:-1}
    typeset -i _Dbg_o_fns;  _Dbg_o_fns=${2:-1}

    echo '# debugger shell profile' > $_Dbg_shell_temp_profile

    ((_Dbg_o_vars)) && _Dbg_shell_append_typesets

    # Add where file to allow us to restore info and
    # Routine use can call to mark which variables should persist
    typeset -p _Dbg_restore_info >> $_Dbg_shell_temp_profile
    echo "source ${_Dbg_libdir}/data/shell.sh" >> $_Dbg_shell_temp_profile

    ((_Dbg_o_fns))  && _Dbg_shell_append_fn_typesets

}
