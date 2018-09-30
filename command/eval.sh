# -*- shell-script -*-
# Eval and Print commands.
#
#   Copyright (C) 2008, 2011, 2018 Rocky Bernstein <rocky@gnu.org>
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

# temp file for internal eval'd commands
typeset _Dbg_evalfile=$(_Dbg_tempname eval)

_Dbg_help_add eval \
'eval CMD
eval
eval?

In the first form CMD is a string CMD is a string sent to special
shell builtin eval.

In the second form, use evaluate the current source line text.

Often when one is stopped at the line of the first part of an "if",
"elif", "case", "return", "while" compound statement or an assignment
statement, one wants to eval is just the expression portion.  For
this, use eval?. Actually, any alias that ends in ? which is aliased
to eval will do thie same thing.

In any form .sh.level is set beforehand based on the current stack
position to get the scope set properly.

See also "print" and "set autoeval".' 1

typeset -i _Dbg_show_eval_rc; _Dbg_show_eval_rc=1

_Dbg_do_eval() {

    typeset -i old_level=.sh.level
    typeset -i new_level
    ((new_level=${#_Dbg_frame_stack[@]} - 1 - _Dbg_stack_pos))

    # FIXME: is this needed. Is it effective?
    # Should it be moved after setting .sh?
    print ". ${_Dbg_libdir}/lib/set-d-vars.sh" > "$_Dbg_evalfile"

    print "(( .sh.level = $new_level ))" >> "$_Dbg_evalfile"
    print "typeset -i _Dbg_rc" >> "$_Dbg_evalfile"
    if (( $# == 0 )) ; then
	# FIXME: add parameter to get unhighlighted line, or
	# always save a copy of that in _Dbg_sget_source_line
	typeset source_line
	source_line=${.sh.command}

	# Were we called via ? as the suffix?
	typeset suffix
	suffix=${_Dbg_orig_cmd:${#_Dbg_orig_cmd}-1:1}
	if [[ '?' == "$suffix" ]] ; then
	    typeset extracted
	    _Dbg_eval_extract_condition "$source_line"
	    source_line="$extracted"
	fi

	print "$source_line" >> "$_Dbg_evalfile"
	_Dbg_msg "eval: ${source_line}"
    else
	print "$@" >> $_Dbg_evalfile
    fi
    print '_Dbg_rc=$?' >> "$_Dbg_evalfile"
    print "(( .sh.level = $old_level ))" >> "$_Dbg_evalfile"

    if [[ -n $_Dbg_tty  ]] ; then
	_Dbg_set_dol_q $_Dbg_debugged_exit_code
	. "$_Dbg_evalfile" >>$_Dbg_tty
    else
	_Dbg_set_dol_q $_Dbg_debugged_exit_code
	# Warning: in ksh93u+ (and others before?) the following line will SEGV
	. "$_Dbg_evalfile"
    fi
    (( _Dbg_show_eval_rc )) && _Dbg_msg "\$? is $_Dbg_rc"
    # We've reset some variables like IFS and PS4 to make eval look
    # like they were before debugger entry - so reset them now.
    _Dbg_set_debugger_internal
    _Dbg_last_cmd='eval'
    return $_Dbg_rc
}

_Dbg_alias_add 'ev' 'eval'
_Dbg_alias_add 'ev?' 'eval'
_Dbg_alias_add 'eval?' 'eval'


# The arguments in the last "print" command.
typeset _Dbg_last_print_args=''

_Dbg_help_add print \
'print EXPRESSION -- Print EXPRESSION.

EXPRESSION is a string like you would put in a print statement.
See also eval.' 1

# NOTE: because this funciton uses _Dbg_arg. it CANNOT be declared as a fucntion,
# i.e. function _Dbg_doprint()
_Dbg_do_print() {
    typeset _Dbg_expr=${@:-"$_Dbg_last_print_args"}
    typeset dq_expr; dq_expr=$(_Dbg_esc_dq "$_Dbg_expr")
    typeset -i _Dbg_show_eval_rc=0
    _Dbg_do_eval _Dbg_msg "$_Dbg_expr"
    typeset -i rc=$?
    _Dbg_last_print_args="$dq_expr"
    return $rc
}

_Dbg_alias_add 'p' 'print'
