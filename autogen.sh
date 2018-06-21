#!/usr/bin/env ksh
autoreconf -i && \
autoconf && {
  print "Running configure with --enable-maintainer-mode $@"
  ./configure --enable-maintainer-mode $@
}
