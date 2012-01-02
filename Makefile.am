#   Copyright (C) 2008, 2011 Rocky Bernstein <rocky@gnu.org>
#
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation; either version 2, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; see the file COPYING.  If not, write to
#   the Free Software Foundation, 59 Temple Place, Suite 330, Boston,
#   MA 02111 USA.

AUTOMAKE_OPTIONS = dist-bzip2

SUBDIRS = command data init lib doc test

pkgdata_DATA =       \
	dbg-main.sh  \
	dbg-trace.sh \
	getopts_long.sh

# Set up the install target. Can't figure out how to use @PACKAGE@
bin_SCRIPTS = kshdb

MOSTLYCLEANFILES = *.orig *.rej

EXTRA_DIST = $(pkgdata_DATA) THANKS

#: Same as "check" - integration tests. 
test: check

#: Unit testing
check-unit: test-unit

test-unit:
	cd test/unit && make check

test-integration:
	cd test/integration && make check

MAINTAINERCLEANFILES = ChangeLog

if MAINTAINER_MODE

ChangeLog:
	git log --pretty --numstat --summary | $(GIT2CL) > $@

ACLOCAL_AMFLAGS=-I .

endif
