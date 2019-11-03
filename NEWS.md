2019-11-09 Version 1.0.0 - Day of the Dead
------------------------------------------

First 1.0.0 release (semantic versioning now possibile)

- automated light/dark background detection from term-background.sh
- ReStructuredText formatting of set/show subcommands
- add "set/show style"
- Go over docs
- Add readthedocs docs https://kshdb.readthedocs.io/en/latest/
- Tolerance for spaces in path names
- Issue #5 fix

2018-06-21 Version 0.07
----------------------

- Need ksh93v- for file I/O fixes
- Start RsT formatting on help documentation
- Use more modern autoconf
- Fix bugs around pr command
- Add --no-highlight option.
- remove emacs code - use realgud (available from MELPA) if you want Emacs support
- Doc grammar fixes
- indicate which breakpoint(s) are deleted and set; this helps frontends like realgud


2011-5-18 Version 0.06
----------------------

- Add Syntax coloring if pygmentize is installed
- Add gdb-like commands:
  *  "info args"
  *  "info functions"
  *  "condition"
  *  "complete"
- Remove hard-wiring of "info", "set", and "show" commands.
- Expand help text for various commands
- Debugger commands can be the smallest unique prefix
- Fix bugs in 'trace', 'untrace' and 'shell' commands
- "set debugging" is not "set debug" to match gdb
- Unit tests are faster and have less white space but more useful information

2011-3-15 Version 0.05 - Ron Frankel
------------------------------------

- Add an easy way to evaluate the current source line or expression inside
  the source line (debugger commands "eval" and "eval?")
- ability to go into a nested shell but keeping existing variables and
  functions set. (debugger command "shell")
- show hit counts in breakpoint display
- Add debugger "display" command
- Add debugger set/show autolist
- Make sure we can debug files with a space in the directory path.
- Many cleanups and some small bugfixes
- Remove emacs code. Use emacs-dbgr from github instead.

2009-10-27 Version 0.04 - Halala ngosuku lokuzalwa
---------------------------------------------------

- Better tolerance for files with embedded blanks. Make sure to quote
  parameters in argument passing.

- Add "set force", "step+", and "step-", "next+", and "next-" commands.

- Preface more variable names with _Dbg_.

- "restart" command fixed slightly.

- Remove Emacs compile warnings

2009-07-14 Version 0.03
-----------------------

- Add "condition" command
- Add "kill" command
- More OSX friendly
- Add manual page and "--help" usage corrections

2009-06-12 Version 0.02
-----------------------

- Add "enable", "disable", and "examine" debugger commands.
- Add "set inferior-tty" and --tty option.
- Bug fix to find scripts in . that don't start with . or / to run.

2008-11-17 Version 0.01
------------------------

First public release.
