[![Packaging status](https://repology.org/badge/vertical-allrepos/kshdb.svg)](https://repology.org/project/kshdb/versions)

Introduction
============

This is a port and my `bash` debugger, [bashdb](http://bashdb.sf.net), and
`zsh` debugger, [zshdb](http://github.com/rocky/zshdb).

The command syntax generally follows that of the GNU debugger `gdb`.

However this debugger depends on a number of bug fixes and of debugging
support features that are neither part of the POSIX 1003.1 standard
and only in later ksh93v- releases. In particular, there are fixes to a
number of the `.sh` variables like `.sh.level` and `.sh.file`, and
[fixes to for handling IO redirection](https://github.com/att/ast/issues/582).


To see if there is recent-enough version for your favorite distirbution, see the repology.org [list](https://repology.org/project/ksh/versions).

Source code to later ksh releases can be found in the [github att/ast](https://github.com/att/ast) repository.


Installation
============

See the [wiki](https://github.com/rocky/kshdb/wiki/How-to-install) for
how to install this code.

Debugger documentation
======================

There is extensive command documentation inside the debugger itself.

However see the [wiki](https://github.com/rocky/kshdb/wiki) and [documentation](http://kshdb.readthedocs.io/en/latest/)
for more information on this debugger.


What's here, what's not and why not
===================================

What's missing falls into two categories:

  * Stuff that might be ported in a straightforward way from `bashdb` or `zshdb`
  * Stuff that needs additional `ksh` support

What's not here yet in detail
-----------------------------

This can be done with or without support from `ksh`, albeit faster with
help from `ksh`.

* Setting `$0`
* lots of other stuff including...
  * display expressions, signal handling,
  * command completion
  * debugger commands:
     * file  - sets file name for the current source
     * handle - specify debugger signal handling
     * history - rerun a debugger command from its history
     * signal - send a signal to the process
     * tty - set output device for debugger output
     * watch - Set or clear a watch expression.

None of this is rocket science; most of it should be pretty straight-forward to add.

_I use a project's ratings to help be determine the priority I should give to it.
You'll see that this project's rating is far behind [zshdb's](http://github.com/rocky/zshdb)_


What may need more work and support from ksh
--------------------------------------------

* command completion
* stopping points that are valid for a `breakpoint` command
