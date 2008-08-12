SUBDIRS = command emacs lib test

pkgdata_DATA =      \
	dbg-pre.sh  \
	dbg-io.sh \
	dbg-main.sh

# Set up the install target 
bin_SCRIPTS = kshdb

EXTRA_DIST = $(pkgdata_DATA)

# cvs2cl
MAINTAINERCLEANFILES = ChangeLog

test: check

# Unit testing
check-unit: test-unit

test-unit:
	cd test/unit && make check

phony = check test-unit check-unit

if MAINTAINER_MODE

CL = ChangeLog
ChangeLog:
	git log --pretty --numstat --summary | $(GIT2CL)

ACLOCAL_AMFLAGS=-I .

endif

.PHONY: $(CL) test


