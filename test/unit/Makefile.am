## Process this file with automake to produce Makefile.in -*-Makefile-*-.

COMBINED_TESTS= \
	test-alias.sh           \
	test-break.sh           \
	test-cmd-complete.sh    \
	test-columns.sh         \
	test-dbg-opts.sh        \
	test-eval.sh            \
	test-examine.sh         \
	test-file.sh            \
	test-filecache.sh       \
	test-frame.sh           \
	test-journal.sh         \
	test-lib-complete.sh    \
	test-msg.sh             \
	test-pre.sh             \
	test-run.sh             \
	test-save-restore.sh    \
	test-tty.sh

TESTS = \
	test-fns.sh \
	test-setshow.sh \
	test-sort.sh

TEST = $(*.sh.in)

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

EXTRA_DIST = helper.sh $(COMBINED_TESTS) $(TESTS) shunit2 $(TEST)

check: combined-tests check-am
test: check
test-unit: check

combined-tests: $(COMBINED_TESTS)
	$(SH_PROG) $(abs_srcdir)/shunit2 $(COMBINED_TESTS)

MOSTLYCLEANFILES = *.orig *.rej
