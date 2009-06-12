TESTS = \
	test-bug-args      \
	test-bugIFS        \
	test-bug-errexit   \
	test-frame         \
	test-next          \
	test-restart	   \
	test-skip	   \
	test-step

check_DATA = check-common.sh

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

TESTS_ENVIRONMENT = \
  srcdir="$(abs_srcdir)" \
  builddir="$(abs_builddir)"

EXTRA_DIST = $(TESTS) $(check_DATA) \
	check-common.sh.in

CLEANFILES = *.check

test: check
test-integration: check
