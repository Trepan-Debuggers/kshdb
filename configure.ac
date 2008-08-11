dnl Configure script for Korn Shell debugger
AC_INIT([kshdb],[0.01git],[rocky@gnu.org])
AM_PATH_LISPDIR
AM_MAINTAINER_MODE
AM_INIT_AUTOMAKE([no-define])

AC_CONFIG_SRCDIR(kshdb.in)
if test x$srcdir = x ; then
  srcdir=$ac_pwd
fi

## --with-ksh can be used to tell the kshdb script and the regression
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

dnl We use a diff in regression testing
AC_PATH_PROG(DIFF, diff, no)
DIFF_OPTS=

if test "$DIFF" = no ; then
   AC_PATH_PROG(DIFF, cmp, no)
else 
   dnl Try for GNU diff options.
  # MSDOG output uses \r\n rather than \n in tests
  for diff_opt in -w --unified ; do 
    if $DIFF $diff_opt . . > /dev/null 2>&1; then
      AC_MSG_RESULT([adding $diff_opt to diff in regression tests])
      DIFF_OPTS="$DIFF_OPTS $diff_opt"
    fi
  done
fi

AM_MISSING_PROG(GIT2CL, git2cl, $missing_dir)
AC_PROG_LN_S
AC_PATH_PROG(RM, rm, true)

AC_PATH_PROG(EMACS, emacs, no)
if test x$EMACS = xno ; then
  emacs_lisp=no
else 
  $EMACS -batch -q -no-site-file -eval \
  '(if (not (and (= emacs-major-version 21) (<= emacs-minor-version 3))) (error "This gud is for Emacs 21.0 to 21.3."))'
  if test $? -ne 0 ; then
    emacs_lisp=no
  fi
fi

AM_CONDITIONAL(INSTALL_EMACS_LISP, test "x$lispdir" != "x")

AC_CONFIG_FILES([Makefile 
	command/Makefile \
	emacs/Makefile \
	emacs/kshdb-test.el \
	lib/Makefile \
	test/Makefile test/unit/Makefile])

AC_CONFIG_FILES([kshdb], [chmod +x kshdb])
AC_CONFIG_FILES([test/unit/test-alias.sh], [chmod +x test/unit/test-alias.sh])
AC_CONFIG_FILES([test/unit/test-fns.sh],   [chmod +x test/unit/test-fns.sh])
AC_CONFIG_FILES([test/unit/test-io.sh],    [chmod +x test/unit/test-io.sh])
AC_CONFIG_FILES([test/unit/test-pre.sh],   [chmod +x test/unit/test-pre.sh])
AC_CONFIG_FILES([test/unit/test-run.sh],   [chmod +x test/unit/test-run.sh])

AC_OUTPUT
