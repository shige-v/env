MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

include $(MAKEFILE_DIR)/header.mk
# ===================================================================================================================================

SUBDIRS  = $(notdir $(realpath $(filter-out $(wildcard $(IGNORE_TESTDIRS)), $(wildcard $(TESTDIRS)))))
RULES   += run all distclean clean

# for invernal use
__TARGET=all
__VERBOSE=1
__DEPTH=0

$(RULES): %: %_local

$(SUBDIRS):
	@if [ -d $@ ]; then \
	  if [ "${__VERBOSE}" == "1" ]; then for i in $$(seq 1 ${__DEPTH}); do echo -n '>'; done && echo " $@ - ${__TARGET}"; fi; \
	  (cd $@ && $(MAKE) ${__TARGET}); \
	  if [ "${__VERBOSE}" == "1" ]; then for i in $$(seq 1 ${__DEPTH}); do echo -n '<'; done && echo " $@ - ${__TARGET}"; fi; \
	fi
.PHONY: $(SUBDIRS)

%_local:
	@if [ "$(SUBDIRS)" != "" ]; then $(MAKE) $(SUBDIRS) __TARGET=$* __DEPTH=$$(expr ${__DEPTH} + 1) __VERBOSE=1; fi;

%_local_s:
	@if [ "$(SUBDIRS)" != "" ]; then $(MAKE) $(SUBDIRS) __TARGET=$* __DEPTH=$$(expr ${__DEPTH} + 1) __VERBOSE=0; fi;

#
    clean-files += *~
distclean-files +=

    clean-dirs  += 
distclean-dirs  +=

# ===================================================================================================================================
include $(MAKEFILE_DIR)/footer.mk
