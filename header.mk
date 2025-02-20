# Do not use make's built-in rules and variables
MAKEFLAGS += -rR
# Do not print "Entering directory ...."
MAKEFLAGS += --no-print-directory

# Avoid funny character set dependencies
unexport LC_ALL
LC_COLLATE=C
LC_NUMERIC=C
export LC_COLLATE LC_NUMERIC

# Shell
SHELL = /bin/bash

#
V ?=
$(V)quiet = quiet_

#
toupper = $(shell echo $(1) | tr '[:lower:]' '[:upper:]')
tolower = $(shell echo $(1) | tr '[:upper:]' '[:lower:]')

#
if-success = $(shell { $(1); } > /dev/null 2>&1 && echo "$(2)" || echo "$(3)")

PHONY += help
help:               ## display this help screen
	@for i in $(MAKEFILE_LIST); do \
	  grep -E '^[a-zA-Z% \._-]+:.*?## .*$$' $$i | \
		awk 'BEGIN {FS = ":.*?## "}; {printf " \033[36m%-20s\033[0m %s\n", $$1, $$2}'; \
	done | sort

# -------
ifeq ($(origin NSI_SIM_CMN_DIR), undefined)
  $(error Environment 'NSI_SIM_CMN_DIR' undefned, Please source 'common/setup.sh' in your script)
endif
