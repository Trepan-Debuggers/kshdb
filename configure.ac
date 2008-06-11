dnl Configure script for Korn Shell debugger
define(OK_KSH_VERS, 93)
define(relstatus, 0.01cvs)
AC_INIT([kshdb],[OK_BASH_VERS-relstatus],[bashdb-devel@lists.sourceforge.net])
AM_MAINTAINER_MODE
AC_DEFINE([PACKAGE], [bashdb], [Bash Debugger])
AC_DEFINE([VERSION], [OK_KSH_VERS-relstatus], [version string])
AM_INIT_AUTOMAKE([no-define])

## --with ksh can be used to tell the kshdb script and the regression
## test which ksh to run. It can be omitted too in which case we'll
## look for a ksh binary.
AC_ARG_WITH(ksh, AC_HELP_STRING([--with-ksh], 
		  [location of ksh OK_KSH_VERS program]), KSH_PROG=$withval)

if test "$KSH_PROG" = "yes" || test "$KSH_PROG" = "no" || test -z "$KSH_PROG"
then
  AC_PATH_PROG(KSH_PROG, ksh93, no)
fi

if test "$KSH_PROG" = no; then
  AC_MSG_ERROR([I didn't find the ksh executable.\
  You might want to use the --with-ksh option.])
fi

AC_CONFIG_FILES([Makefile test/Makefile test/unit/Makefile])

AC_CONFIG_FILES([test/unit/test-fns.sh], [chmod +x test/unit/test-fns.sh])
AC_CONFIG_FILES([test/unit/test-io.sh], [chmod +x test/unit/test-io.sh])
AC_CONFIG_FILES([test/unit/test-pre.sh], [chmod +x test/unit/test-pre.sh])

AC_OUTPUT
