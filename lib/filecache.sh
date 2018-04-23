# -*- shell-script -*-
# filecache.sh - cache file information
#
#   Copyright (C) 2008-2011, 2013-2014 Rocky Bernstein
#   <rocky@gnu.org>
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
#   You should have received a copy of the GNU General Public License along
#   with this program; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

[[ -z ${.sh.type.Fileinfo_t} ]] || return

# Keys are the canonic expanded filename. _Dbg_filenames[filename] is
# name of variable which contains text.
typeset -T Fileinfo_t=(
    size=-1
    typeset -a text=()
    typeset -a marked_text=()
    integer mtime=-1
)

# Maps a name into its canonic form which can then be looked up in filenames
typeset -A _Dbg_file2canonic

function _Dbg_readfile # var file
{
    nameref var=$1
    typeset old_IFS="$IFS"
    set -f
    IFS=$'\n\n' var=( $(< $2))
    set +f
    IFS="$old_IFS"
}

Fileinfo_t -A _Dbg_filenames
_Dbg_filecache_reset() {
    _Dbg_filenames=()
}
_Dbg_filecache_reset

# Check that line $2 is not greater than the number of lines in
# file $1
_Dbg_check_line() {
    (( $# != 2 )) && return 1
    typeset -i line_number=$1
    typeset filename="$2"
    typeset -i max_line
    max_line=$(_Dbg_get_maxline "$filename")
    if (( $? != 0 )) ; then
	_Dbg_errmsg "internal error getting number of lines in $filename"
	return 1
    fi

    if (( line_number >  max_line )) ; then
	(( _Dbg_set_basename )) && filename=${filename##*/}
	_Dbg_errmsg "Line $line_number is too large." \
	    "File $filename has only $max_line lines."
	return 1
    fi
    return 0
}

# Error message for file not read in
function _Dbg_file_not_read_in {
    typeset -r filename=$(_Dbg_adjust_filename "$1")
    _Dbg_errmsg "File \"$filename\" not found in read-in files."
    _Dbg_errmsg "See 'info files' for a list of known files and"
    _Dbg_errmsg "'load' to read in a file."
}

# Print the maximum line of filename $1. $1 is expected to be
# read in already and therefore stored in _Dbg_file2canonic.
function _Dbg_get_maxline {
    (( $# != 1 )) && return 1
    typeset fullname=${_Dbg_file2canonic["$1"]}
    (( $? != 0 )) && return 1
    typeset -i max_line
    # For some reason this doesn't work:
    # ((max_line=_Dbg_filenames[$fullname].size-1))
    # set -x
    (( max_line=${#_Dbg_filenames[$fullname].text[@]}+1 ))
    # set +x
    print $max_line
    return $?
}

# Return text for source line for line $1 of filename $2 in variable
# $_Dbg_source_line.

# If $2 is omitted, use _Dbg_frame_filename, if $1 is omitted use
# _Dbg_frame_last_lineno. The return value is put in _Dbg_source_line.
_Dbg_get_source_line() {
    typeset -i lineno
    if (( $# == 0 )); then
	lineno=$_Dbg_frame_last_lineno
    else
	lineno=$1
	shift
    fi
    typeset filename
    if (( $# == 0 )) ; then
	filename="$_Dbg_frame_last_filename"
    else
	filename="$1"
    fi
  _Dbg_readin_if_new "$filename"
  fullname=${_Dbg_file2canonic[$filename]}
  if [[ -n $_Dbg_set_highlight ]] ; then
      nameref text=_Dbg_filenames[$fullname].marked_text
  else
      nameref text=_Dbg_filenames[$fullname].text
  fi
  _Dbg_source_line=${text[$lineno-1]}
}

# _Dbg_is_file echoes the full filename if $1 is a filename found in files
# '' is echo'd if no file found. Return 0 (in $?) if found, 1 if not.
function _Dbg_is_file {
    if (( $# == 0 )) ; then
	_Dbg_errmsg "Internal debug error _Dbg_is_file(): null file to find"
	echo ''
	return 1
    fi
    typeset find_file="$1"

    if [[ -z $find_file ]] ; then
	_Dbg_errmsg "Internal debug error _Dbg_is_file(): file argument null"
	echo ''
	return 1
    fi

    if [[ ${find_file:0:1} == '/' ]] ; then
	# Absolute file name
	if [[ -n ${_Dbg_filenames[$find_file]} ]] ; then
	    print -- "$find_file"
	    return 0
	fi
    elif [[ ${find_file:0:1} == '.' ]] ; then
	# Relative file name
	try_find_file=$(_Dbg_expand_filename ${_Dbg_init_cwd}/$find_file)
	# FIXME: turn into common subroutine
	if [[ -n ${_Dbg_filenames[$try_find_file]} ]] ; then
	    print -- "$try_find_file"
	    return 0
	fi
    else
	# Resolve file using _Dbg_dir
	typeset -i n=${#_Dbg_dir[@]}
	typeset -i _Dbg_i
	for (( _Dbg_i=0 ; _Dbg_i < n; _Dbg_i++ )) ; do
	    typeset basename="${_Dbg_dir[_Dbg_i]}"
	    if [[  $basename == '\$cdir' ]] ; then
		basename=$_Dbg_cdir
	    elif [[ $basename == '\$cwd' ]] ; then
		basename=$(pwd)
	    fi
	    try_find_file="$basename/$find_file"
	    if [[ -f "$try_find_file" ]] ; then
		print -- "$try_find_file"
		return 0
	    fi
	done
    fi
    echo ''
    return 1
}

# Read $1 into _Dbg_source_*n* array where *n* is an entry in
# _Dbg_filenames.  Variable _Dbg_seen[canonic-name] will be set to
# note the file has been read and the filename will be saved in array
# _Dbg_filenames

function _Dbg_readin {
    typeset filename
    if (($# != 0)) ; then
	filename="$1"
    else
	_Dbg_frame_file
	filename="$_Dbg_frame_filename"
    fi

    if [[ -z $filename ]] || [[ $filename == $_Dbg_bogus_file ]] ; then
	# FIXME
	return 2
    else
	typeset fullname="$(_Dbg_resolve_expand_filename "$filename")"
	if [[ ! -r "$fullname" ]] ; then
	    return 1
	fi
    fi

    nameref text=_Dbg_filenames[$fullname].text
    _Dbg_readfile text "$fullname"
    if [[ -n $_Dbg_set_highlight ]] ; then
	highlight_cmd="${_Dbg_libdir}/lib/term-highlight.py $fullname"
	tempfile=$($highlight_cmd 2>/dev/null)
	nameref text=_Dbg_filenames[$fullname].marked_text
	_Dbg_readfile text "$tempfile"
    fi
    _Dbg_file2canonic[$filename]="$fullname"
    _Dbg_file2canonic[$fullname]="$fullname"
    _Dbg_filenames[$fullname].size=${#text[@]}+1
    _Dbg_filenames[$fullname].text=text
    return 0
}

# Read in file $1 unless it has already been read in.
# 0 is returned if everything went ok.
_Dbg_readin_if_new() {
    (( $# != 1 )) && return 1
    typeset filename="$1"
    typeset fullname=${_Dbg_file2canonic["$filename"]}
    if [[ -z $fullname ]] ; then
	_Dbg_readin "$filename"
	typeset -i rc=$?
	(( rc != 0 )) && return $rc
	fullname=_Dbg_file2canonic["$filename"]
	[[ -z $fullname ]] && return 1
    fi
    return 0
}
