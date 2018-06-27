[![Travis Build Status](https://travis-ci.org/rocky/kshdb.svg?branch=master)](https://travis-ci.org/rocky/kshdb)

Introduction
============

This is a port and my `bash` debugger [bashdb](http://bashdb.sf.net) and
`zsh` debugger [zshdb](http://github.com/rocky/zshdb).

The command syntax generally follows that of the GNU debugger `gdb`.

However this debugger depends on a number of bug fixes and of debugging
support features that are neither part of the POSIX 1003.1 standard
and only in ksh93v- releases. In particular, there are fixes to a
number of the `.sh` variables like `.sh.level` and `.sh.file`, and
[fixes to for handling IO redirection](https://github.com/att/ast/issues/582).

Setup
=====

See the [wiki](https://github.com/rocky/kshdb/wiki/How-to-install) for
how to install this code.

What's here, what's not and why not
===================================

What's missing falls into two categories:

  * Stuff that might be ported in a straightforward way from `bashdb` or `zshdb`
  * Stuff that needs additional `ksh` support

Writing documentation is important, but an extensive guide will have
to wait. For now one can consult the reference guide that comes with
bashdb: http://bashdb.sf.net/bashdb.html There is some minimal help to
get a list of commands and some help for each.

What's not here yet in detail
-----------------------------

This can be done with or without support from ksh, albeit faster with
help from ksh.

* Setting `$0`
* lots of other stuff including...
  * display expressions, signal handling,
  * debugger commands:
     * debug - recursive debugging
     * file  - sets file name for the current source
     * handle - specify debugger signal handling
     * history - rerun a debugger command from its history
     * signal - send a signal to the process
     * tty - set output device for debugger output
     * watch - Set or clear a watch expression.

None of this is rocket science. Should be pretty straight-forward to add.

_I use a project's ratings to help be determine the priority I should give to it.
You'll see that this project's rating is far behind [zshdb's](http://github.com/rocky/zshdb)_


What may need more work and support from ksh
--------------------------------------------

stopping points that are valid for a `breakpoint` command
