## Process this file with automake to produce Makefile.in -*-Makefile-*-.
#$Id: Makefile.am,v 1.1 2008/06/01 00:49:16 rockyb Exp $

TESTS = test-alias.sh        \
	test-break.sh        \
	test-columns.sh      \
	test-dbg-opts.sh     \
	test-filecache.sh    \
	test-fns.sh          \
	test-frame.sh        \
	test-journal.sh      \
	test-io.sh           \
	test-pre.sh          \
	test-run.sh          \
	test-save-restore.sh \
	test-sort.sh
check_DATA = shunit2

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

EXTRA_DIST = $(TESTS) $(check_DATA) \
	test-alias.sh.in            \
	test-break.sh.in            \
	test-columns.sh.in          \
	test-dbg-opts.sh.in         \
	test-filecache.sh.in        \
	test-fns.sh.in              \
	test-frame.sh.in            \
	test-journal.sh.in          \
	test-io.sh.in               \
	test-pre.sh.in              \
	test-run.sh.in              \
	test-save-restore.sh.in     \
	test-sort.sh.in
