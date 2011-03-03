pkgdatadir        = ${datadir}/@PACKAGE@/lib
pkgdata_DATA =      	\
	action.sh       \
	alias.sh        \
	break.sh        \
	columnize.sh    \
	dbg-call.sh  	\
	display.sh  	\
	filecache.sh    \
	file.sh         \
	fns.sh          \
	frame.sh        \
	gdb.sh  	\
	help.sh  	\
	hook.sh		\
	info.sh		\
	journal.sh  	\
	list.sh  	\
	msg.sh    	\
	processor.sh   	\
	run.sh    	\
	save-restore.sh	\
	set-d-vars.sh   \
	sort.sh         \
	term-highlight.py \
	tty.sh

install-data-hook: 
	chmod +x $(DESTDIR)$(pkgdatadir)/term-highlight.py

EXTRA_DIST = $(pkgdata_DATA)
MOSTLYCLEANFILES = *.orig *.rej
