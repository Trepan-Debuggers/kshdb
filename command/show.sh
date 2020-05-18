# -*- shell-script -*-
# show.sh - Show debugger settings
#
#   Copyright (C) 2008-2011, 2018-2020 Rocky Bernstein <rocky@gnu.org>
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

# Sets whether or not to display command to be executed in debugger prompt.
# If yes, always show. If auto, show only if the same line is to be run
# but the command is different.
typeset _Dbg_show_command="auto"

typeset -A _Dbg_debugger_show_commands
typeset -A _Dbg_command_help_show

# subcommands whose current values are not shown in a "show" list .
# These are things like alias, warranty, or copying.
# They are available if asked for explicitly, e.g. "show copying"
typeset -A _Dbg_show_nolist

_Dbg_help_add show ''  # Help routine is elsewhere

# Load in "show" subcommands
for _Dbg_file in ${_Dbg_libdir}/command/show_sub/*.sh ; do
    source "$_Dbg_file"
done

# Command completion for a condition command
_Dbg_complete_show() {
    _Dbg_complete_subcmd show
}

_Dbg_do_show() {
    _Dbg_help_show $@
    return $?
}

_Dbg_help_show() {

    if (( $# == 0 )) ; then
	typeset -a list; list=("${!_Dbg_debugger_show_commands[@]}")
        typeset subcmd
        for subcmd in ${list[@]}; do
            _Dbg_help_show $subcmd 1
        done
        return 0
    fi

    typeset show_cmd=$1
    typeset label=$2

    if [[ -n "${_Dbg_debugger_show_commands[$show_cmd]}" ]] ; then
        if [[ -z $label ]] ; then
            ${_Dbg_debugger_show_commands[$show_cmd]} $label
            return $?
        else
            label=$(printf "show %-12s-- " $subcmd)
        fi
    fi

    case $show_cmd in
        al | ali | alia | alias | aliase | aliases )
            _Dbg_msg \
                "${label}Show list of aliases currently in effect."
            ;;
        # ar | arg | args )
        #     [[ -n $label ]] && label='args:     '
        #     _Dbg_msg \
        #         "${label}Argument list to give script when debugged program starts is:\n" \
        #         "      \"${_Dbg_script_args[@]}\"."
        #     ;;
        an | ann | anno | annot | annota | annotat | annotate )
            _Dbg_msg \
                "${label}Show annotation_level"
            ;;
        autoe | autoev | autoeva | autoeval )
            _Dbg_msg \
                "${label}Evaluate unrecognized commands is" $(_Dbg_onoff $_Dbg_set_autoeval)
            ;;
        autol | autoli | autolis | autolist )
            _Dbg_msg \
                "${label}Auto run a 'list' command is" $(_Dbg_onoff $_Dbg_set_autolist)
            ;;
        b | ba | bas | base | basen | basena | basenam | basename )
            _Dbg_msg \
                "${label}Show if we are are to show short or long filenames."
            ;;
        com | comm | comma | comman | command | commands )
            _Dbg_msg \
                "${label}Show the history of commands you typed."
            ;;
        con | conf | confi | confir | confirm )
            _Dbg_msg \
                "${label}confirm dangerous operations" $(_Dbg_onoff $_Dbg_set_confirm)
            ;;
        cop | copy| copyi | copyin | copying )
            _Dbg_msg \
                "${label}Conditions for redistributing copies of debugger."
            ;;
        dir|dire|direc|direct|directo|director|directori|directorie|directories)
	    if [[ -n $label ]]; then
		_Dbg_msg \
                    "${label}Show the search path for finding source files."
	    else
		typeset list=${_Dbg_dir[0]}
		typeset -i n=${#_Dbg_dir[@]}
		typeset -i i
		for (( i=1 ; i < n; i++ )) ; do
                    list="${list}:${_Dbg_dir[i]}"
		done
		_Dbg_msg "Source directories searched: $list"
	    fi
            ;;
        d|de|deb|debu|debug|debugg|debugger|debuggi|debuggin|debugging )
            _Dbg_msg \
                "${label}Show if we are set to debug the debugger."
            ;;
        editing )
            _Dbg_msg \
                "${label}Show editing of command lines and edit style."
            ;;
        force | diff | differ | different )
            _Dbg_msg \
                "${label}Show stepping forces a new line is" $(_Dbg_onoff $_Dbg_set_different)
            ;;
        highlight )
            _Dbg_msg \
                "${label}Show if we syntax highlight source listings."
            ;;
        history )
            _Dbg_msg \
                "${label}Show if we are recording command history."
            return 0
            ;;
        lin | line | linet | linetr | linetra | linetrac | linetrace )
            _Dbg_msg \
                "${label}Show whether to trace lines before execution."
            ;;
        lis | list | lists | listsi | listsiz | listsize )
            _Dbg_msg \
                "${label}Number of source lines ${_Dbg_debugger_name} will list by default is" \
                "$_Dbg_set_listsize."
            ;;

        lo | log | logg | loggi | loggin | logging )
            shift
            _Dbg_do_show_logging $*
            ;;
        p | pr | pro | prom | promp | prompt )
	    # Note this is different fom "help show prompt" output
            _Dbg_msg \
                "${label}Show ${_Dbg_debugger_name}'s command prompt."
            ;;
        sho|show|showc|showco|showcom|showcomm|showcomma|showcomman|showcommand )
            [[ -n $label ]] && label='showcommand: '
            _Dbg_msg \
                "${label}Show commands in debugger prompt is" \
                "$_Dbg_set_show_command."
            return 0
            ;;
        st | sty | styl | style )
            _Dbg_msg_nocr \
                "${label}Set pygments highlighting style is "
            if [[ -z $_Dbg_set_style ]] ; then
                _Dbg_msg 'off.'
            else
		_Dbg_msg "${_Dbg_set_style}"
            fi
            ;;
        t|tr|tra|trac|trace|trace-|tracec|trace-co|trace-com|trace-comm|trace-comma|trace-comman|trace-command|trace-commands )
            [[ -n $label ]] && label='trace-commands: '
            _Dbg_msg \
                'show trace-commands -- Show if we are echoing debugger commands'
            ;;
        v | ve | ver | vers | versi | versio | version )
            _Dbg_do_show_version
            ;;
        wa | war | warr | warra | warran | warrant | warranty )
            _Dbg_msg \
                "${label}Various kinds of warranty you do not have."
            ;;
        wi | wid | width )
            _Dbg_msg \
                "${label}Line width is $_Dbg_set_linewidth."
            ;;
	args | prompt )
	    # not done yet
	    ;;
        * )
            _Dbg_msg \
                "Undefined show command: \"$show_cmd\".  Try \"help show\"."
    esac
}
