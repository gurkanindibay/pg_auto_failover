#!/bin/bash
export TERM=linux
export TERMINFO=/etc/terminfo
sudo iotop
citus_indent --check
black --check .
/app/pg_auto_failover/ci/banned.h.sh
make -j5 CFLAGS=-Werror
#PATH=`pg_config --bindir`:$PATH make test
