# -*- shell-script -*-
# Print location in gdb-style format: file:line
# So happens this is how it's stored in global _Dbg_frame_stack which
# is where we get the information from
function _Dbg_print_location {
    typeset -i pos=${1:-$_Dbg_stack_pos}
    typeset -n frame=_Dbg_frame_stack[pos]
    typeset filename=${frame.filename}
    typeset fn=${frame.fn}
    ((_Dbg_basename_only)) && filename=${filename##*/}
    _Dbg_msg "(${filename}:${frame.lineno}):"
}
