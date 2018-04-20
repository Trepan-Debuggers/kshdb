#!/bin/ksh
# Had bug in not handling when errexit was set.
# We'll also test set -u.
set -o errexit
### FIXME: a bug in ksh prevents this, I think.
# set -u
print one
