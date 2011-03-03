TESTS = \
	test-break         \
	test-bug-args      \
	test-bugIFS        \
	test-bug-errexit   \
	test-condition     \
	test-delete        \
	test-display       \
	test-enable        \
	test-examine       \
	test-frame         \
	test-list          \
	test-next          \
	test-restart	   \
	test-setshow	   \
	test-skip	   \
	test-step          \
	test-subshell1	   

check_DATA = check-common.sh

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

TESTS_ENVIRONMENT = \
  srcdir="$(abs_srcdir)" \
  builddir="$(abs_builddir)"

SOURCES=$(patsubst %,%.in, $(TESTS))
EXTRA_DIST = $(TESTS) $(check_DATA) $(SOURCES) \
	check-common.sh.in

CLEANFILES = *.check

test: check
test-integration: check
