# -*- shell-script -*-
#================ VARIABLE INITIALIZATIONS ====================#

# Where are we in stack? This can be changed by "up", "down" or "frame"
# commands.

typeset -i _Dbg_stack_pos=1

typeset -T Frame_t=(
	filename=''
	integer lineno=0
	fn=''
	to_file_line()
	{
	    print -r "file \`${_.filename}' at line ${_.lineno}"
	}
)

Frame_t -a _Dbg_frame_stack  #=() causes a problem
_Dbg_frame_stack=()
save_callstack() {
    integer start=${1:-0}
    integer .level=.sh.level-$start .max=.sh.level
    typeset -a .files=()
    typeset -a .linenos=()
    typeset -a .fns=()
    # Frame_t -a ._Dbg_frame_stack gives segv
    while((--.level>=0)); do
	((.sh.level = .level))
	.files+=("${.sh.file}")
	.linenos+=(${.sh.lineno})
	.fns+=$0
    done
    ((.sh.level = .max))
    # Reorganize into an array of frame structures
    integer i
    for ((i=0; i<.max-start; i++)) ; do 
	_Dbg_frame_stack[i].filename=${.files[i]}
	_Dbg_frame_stack[i].lineno=${.linenos[i]}
	_Dbg_frame_stack[i].fn=${.fns[$i]}
    done
 }
print_callstack() {
    integer i
    for ((i=0; i<${#_Dbg_frame_stack[@]}; i++)) ; do 
	print -r -- ${_Dbg_frame_stack[$i].to_file_line}
    done
    print ======
}

