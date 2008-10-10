# -*- shell-script -*-
# Eval and Print commands.
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

# temp file for internal eval'd commands
typeset _Dbg_evalfile=$(_Dbg_tempname eval)

_Dbg_help_add eval \
'eval CMD -- Run eval on CMD.

CMD is a string sent to special shell builtin eval.  .sh.level is set
beforehand based on the current stack position to get the scope set
properly.

See also print.'

_Dbg_do_eval() {
    
   typeset -i old_level=.sh.level
   typeset -i new_level
   ((new_level=${#_Dbg_frame_stack[@]} - 1 - $_Dbg_stack_pos))

   # FIXME: is this needed. Is it effective? 
   # Should it be moved after setting .sh? 
   print ". ${_Dbg_libdir}/lib/set-d-vars.sh" > $_Dbg_evalfile

   print "(( .sh.level =  new_level ))" >> $_Dbg_evalfile
   print "$@" >> $_Dbg_evalfile
   print '_Dbg_rc=$?' >> $_Dbg_evalfile
   typeset -i _Dbg_rc
   print "(( .sh.level = $old_level ))" >> $_Dbg_evalfile

   if [[ -n $_Dbg_tty  ]] ; then
     _Dbg_set_dol_q $_Dbg_debugged_exit_code
     . $_Dbg_evalfile >>$_Dbg_tty
   else
       _Dbg_set_dol_q $_Dbg_debugged_exit_code
       . $_Dbg_evalfile
   fi
  # We've reset some variables like IFS and PS4 to make eval look
  # like they were before debugger entry - so reset them now.
  _Dbg_set_debugger_internal
  return $_Dbg_rc
}

_Dbg_alias_add 'e' 'eval'

# The arguments in the last "print" command.
typeset _Dbg_last_print_args=''

_Dbg_help_add print \
'print EXPRESSION -- Print EXPRESSION.

EXPRESSION is a string like you would put in a print statement.
See also eval.'

_Dbg_do_print() {
  typeset _Dbg_expr=${@:-"$_Dbg_last_print_args"}
  typeset dq_expr
  dq_expr=$(_Dbg_esc_dq "$_Dbg_expr")
  _Dbg_do_eval _Dbg_msg "$_Dbg_expr"
}

_Dbg_alias_add 'p' 'print'
