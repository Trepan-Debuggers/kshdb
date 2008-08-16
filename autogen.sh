#!/bin/ksh
autoreconf -i && \
autoconf && {
  print "Running configure with $@"
  ./configure $@
}
