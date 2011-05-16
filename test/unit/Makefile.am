## Process this file with automake to produce Makefile.in -*-Makefile-*-.

TESTS = $(wildcard test-*.sh)
TESTS_SOURCES = $(notdir $(TESTS:=.in))

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

EXTRA_DIST = helper.sh $(TESTS) shunit2 $(TEST_SOURCES)

check: $(TESTS)
test-unit: check

MOSTLYCLEANFILES = *.orig *.rej
