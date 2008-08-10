# -*- shell-script -*-
# Things related to file handling.
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

# Directory search patch for unqualified file names
typeset -a _Dbg_dir=('\$cdir' '\$cwd' )

# Directory in which the script is located
[[ -z _Dbg_cdir ]] && typeset -r _Dbg_cdir=${_Dbg_source_file%/*}

# SCRIPT_LINES contains the text of files that are known to be debugged.
# The index is the expanded file name. Each entry is an array of lines.
typeset -A SCRIPT_LINES

typeset -a _Dbg_filenames          # names of all source files read

typeset -a _Dbg_override_filenames # name translations given via the debugger
                                   # "file" command.

# Filename that's used when no source file is around. In particular
# if bash --debugger -c 'string' was used to invoke us.
[[ -z $_Dbg_bogus_file ]] && typeset -r _Dbg_bogus_file='*BOGUS*'

typeset _cur_filevar      # source file mangled so it can be used in a variable
typeset -i _curline       # current line number of debugged program

# See if we have compiled the readarray builtin. This speeds up reading
# files into a bash array.
typeset -i _Dbg_have_readarray=0

# if [[ -r $_Dbg_libdir/builtin/readarray ]] ; then
#   if enable -f $_Dbg_libdir/builtin/readarray  readarray >/dev/null 2>&1 ; then
#     _Dbg_have_readarray=1
#   fi
# fi

# ===================== FUNCTIONS =======================================

# _Dbg_is_file echoes the full filename if $1 is a filename found in files
# '' is echo'd if no file found.
function _Dbg_is_file {
  typeset find_file=$1
  if [[ -z $find_file ]] ; then
    _Dbg_msg "Internal debug error: null file to find"
    echo ''
    return
  fi

  if [[ ${find_file:0:1} == '/' ]] ; then 
    # Absolute file name
    for try_file in ${_Dbg_filenames[@]} ; do 
      if [[ $try_file == $find_file ]] ; then
	echo "$try_file"
	return
      fi
    done
  elif [[ ${find_file:0:1} == '.' ]] ; then
    # Relative file name
    find_file=$(_Dbg_expand_filename ${_Dbg_init_cwd}/$find_file)
    for try_file in ${_Dbg_filenames[@]} ; do 
      if [[ $try_file == $find_file ]] ; then
	echo "$try_file"
	return
      fi
    done
  else
    # Resolve file using _Dbg_dir
    for try_file in ${_Dbg_filenames[@]} ; do 
      typeset pathname
      typeset -i n=${#_Dbg_dir[@]}
      typeset -i i
      for (( i=0 ; i < n; i++ )) ; do
	typeset basename="${_Dbg_dir[i]}"
	if [[  $basename = '\$cdir' ]] ; then
	  basename=$_Dbg_cdir
	elif [[ $basename = '\$cwd' ]] ; then
	  basename=$(pwd)
	fi
	if [[ "$basename/$find_file" == $try_file ]] ; then
	  echo "$try_file"
	  return
	fi
      done
    done
  fi
  echo ""
}

# $1 contains the name you want to glob. return 1 if exists and is
# readible or 0 if not. 
# The result will be in variable $filename which is assumed to be 
# local'd by the caller
function _Dbg_glob_filename {
  typeset cmd="filename=`expr $1`"
  eval $cmd
}

# Either fill out or strip filename as determined by "basename_only"
# and annotate settings
function _Dbg_adjust_filename {
  typeset -r filename="$1"
  if (( _Dbg_annotate == 1 )) ; then
    echo $(_Dbg_expand_filename $filename)
  elif ((_Dbg_basename_only)) ; then
    echo ${filename##*/}
  else
    echo $filename
  fi
}

# # Return the maximum line in $1
# _Dbg_get_maxline() {
#   # set -x
#   typeset -r filename=$1
#   typeset -r filevar=`_Dbg_file2var $filename`
#   typeset is_read=`_Dbg_get_assoc_scalar_entry "_Dbg_read_" $filevar`
#   [ $is_read ] || _Dbg_readin $filename 
#   echo `_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $filevar`
#   # set +x
# }

# # Check that line $2 is not greater than the number of lines in 
# # file $1
# _Dbg_check_line() {
#   typeset -ir line_number=$1
#   typeset filename=$2
#   typeset -i max_line=`_Dbg_get_maxline $filename`
#   if (( $line_number >  max_line )) ; then 
#     (( _Dbg_basename_only )) && filename=${filename##*/}
#     _Dbg_msg "Line $line_number is too large." \
#       "File $filename has only $max_line lines."
#     return 1
#   fi
#   return 0
# }

# # Create temporary file based on $1
# # file $1
# _Dbg_tempname() {
#   echo "$_Dbg_tmpdir/kshdb$1$$"
# }

# append a command into journal file and then run the command.
 _Dbg_write_journal_eval() {
   _Dbg_write_journal "$@" 
   eval "$*"
}

# # append a command into journal file and then run the command.
# _Dbg_write_journal_var() {
#   typeset var_name=$1
#   typeset val
#   typeset val_cmd="$val=\${$var_name}"
#   eval $val_cmd
#   _Dbg_write_journal "${var_name}=${val}" 
# }

# _Dbg_write_journal_avar() {
#   typeset decl_str=$(declare -p $1)
#   typeset -a decl_a
#   decl_a=($decl_str)
#   typeset -a decl_a2
#   decl_a2=${decl_a[@]:2}
#   _Dbg_write_journal ${decl_a2[@]}
# }

# Append a command into journal file. But we only need to do
# if we are in a subshell.
_Dbg_write_journal() {
  if (( .sh.subshell != 0 )) ; then
    echo "$@" >> ${_Dbg_journal} 2>/dev/null
  fi
  # return $?
}

# # Remove all journal files.
# _Dbg_erase_journals() {
#   rm ${_Dbg_journal} 2>/dev/null
# }

# # read in or "source" in journal file which will set variables.
# _Dbg_source_journal() {

#   if [ -r $_Dbg_journal ] ; then 
#     . $_Dbg_journal
#     (( BASH_SUBSHELL == 0 )) && _Dbg_erase_journals
#   fi
# }

# Read $1 into _source_$1 array.  Variable _Dbg_read_$1 will be set
# to 1 to note that the file has been read and the filename will be saved
# in array _Dbg_filenames

function _Dbg_readin {
  # set -x
  typeset filename=${1:-$.sh.file}

  typeset -i line_count=0
  typeset filevar
  typeset source_array
  typeset -ir NOT_SMALLFILE=1000

  if [[ -z filename ]] || [[ filename == _Dbg_bogus_file ]] ; then 
    typeset cmd="SCRIPT_LINES[$_Dbg_bogus_file]=\"$KSH_EXECUTION_STRING\""
    eval $cmd
  else 
    typeset -r fullname=$(_Dbg_expand_filename $filename)
    if [[ -r $fullname ]] ; then
      typeset -r progress_prefix="Reading $filename"
      # No readarray. Do things the long way.
      typeset -i i
      for (( i=1; 1 ; i++ )) ; do 
	  typeset source_entry="SCRIPT_LINES[$fullname][$i]"
	  typeset readline_cmd="read -r $source_entry; rc=\$?";
	  typeset -i rc=1
	  if (( i % 1000 == 0 )) ; then
	    if (( i==NOT_SMALLFILE )) ; then
	      if wc -l < /dev/null >/dev/null 2>&1 ; then 
		line_count=`wc -l < "${fullname}"`
	      else
		_Dbg_msg_nocr "${progress_prefix} "
	      fi
	    fi
	    if (( line_count == 0 )) ; then
	      _Dbg_msg_nocr "${i}... "
	    else
	      _Dbg_progess_show "${progress_prefix}" ${line_count} ${i}
	    fi
	  fi
	  eval $readline_cmd
	  if [[ $rc != 0 ]]  ; then 
	    break;
	  fi
      done  < $fullname
      # The last read in the loop above failed. So we've actually 
      # read one more than the number of lines.
      typeset -r remove_last_index_cmd="unset $source_entry"
      eval $remove_last_index_cmd
      (( line_count != 0 )) && _Dbg_progess_done
    else
	return
    fi
  fi

  typeset -r line_count_cmd="line_count=\${#$source_entry[@]}"
  eval $line_count_cmd

  (( line_count >= NOT_SMALLFILE )) && _Dbg_msg "done."

  ## _Dbg_maxline_[$fullname]=$line_count
  
  # Add $filename to list of all filenames
  _Dbg_filenames[${#_Dbg_filenames[@]}]=$fullname;
  # set +x
}

# This is put at the so we have something at the end when we debug this.
[[ -z _Dbg_file_ver ]] && typeset -r _Dbg_file_ver=\
'$Id: dbg-file.inc,v 1.6 2008/06/02 02:37:26 rockyb Exp $'
