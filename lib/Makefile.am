pkgdatadir = ${datadir}/@PACKAGE@/lib
shell_files := $(wildcard *.sh) 
pkgdata_DATA = $(shell_files) term-highlight.py

install-data-hook: 
	chmod +x $(DESTDIR)$(pkgdatadir)/term-highlight.py

EXTRA_DIST = $(pkgdata_DATA)
MOSTLYCLEANFILES = *.orig *.rej
