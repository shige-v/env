MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

include $(MAKEFILE_DIR)/header.mk
# ===================================================================================================================================

DUT_NAME       ?= ns31a
CONFIG         ?= 
COVERAGE       ?= OFF
ASSERTION      ?= OFF

# Simulator
USE_SIM        ?= XLM
# TB top module
TB_TOP         ?= sim_top
# Seed
SEED            ?= 1
# Verbosity Level
VERBOSE         ?= UVM_LOW
#
MAX_QUIT_COUNT  ?= 100
# Timeout
TIMEOUT         ?= 1000000     # ns

INT_RAM_INIT           ?= ON
INT_RAM_INIT_BYTE_CODE ?= 0

# Additional option for user
EXT_BUILD_OPT   ?=
EXT_RUN_OPT     ?=

# Logs
BUILD_LOG      ?= $(REPORT_DIR)/$(TESTNAME)/build.log

REPORT_DIR     ?= reports/$(CONFIG)
SUMMARY_FILE   ?= $(REPORT_DIR)/sim_result.csv
RUN_LOG        ?= $(REPORT_DIR)/$(TESTNAME)/sim.log

XPROP          ?= off

#
DUT_ELF         ?= $(notdir $(realpath $(SW_PATH)/$(PATTERN)/$(DUT_NAME))).riscv
DUT_ELF_PATH    ?= $(SW_PATH)/$(PATTERN)/$(DUT_NAME)/$(DUT_ELF)
DUT_SREC        ?= $(notdir $(realpath $(SW_PATH)/$(PATTERN)/$(DUT_NAME))).riscv.srec
DUT_SREC_PATH   ?= $(SW_PATH)/$(PATTERN)/$(DUT_NAME)/$(DUT_SREC)

#
MAKE_OPTS       ?= $(SW_PATH)/$(PATTERN)/make_opts

#
NAME            ?= $(or $(subst /,_,$(subst ./,,$(basename $(PATTERN)))),none)

#
TESTNAME        ?= $(NAME)_$(TEST)_$(SEED)

#
USE_AXI_VIP     ?= 0
USE_APB_VIP     ?= 0
USE_JTAG_VIP    ?= 0
USE_AHB_VIP     ?= 0

# - TBs
VERIF_DOTF      ?= ../tb/tb.f                          # ... Umm
elfldr          = ../tb/env/dpi/elfloader.cpp
elfldr_exists   = $(wildcard $(elfldr))
VERIF_FILES     += $(elfldr_exists)

# UVM test file (uvm_test)
UVM_TEST_FILE ?=

# ===================================================================================================================================
-include $(MAKE_OPTS)

# Build Options
## common
COM_BUILD_OPT  = +vpi -top $(TB_TOP)
COM_BUILD_OPT += $(EXT_BUILD_OPT)
COM_BUILD_OPT += +define+D_USE_$(USE_SIM)
COM_BUILD_OPT += +define+UVM_NO_DEPRECATED
COM_BUILD_OPT += $(VERIF_C_FILES)

# Runtime Options
COM_RUN_OPT  = +ntb_random_seed=$(SEED)
COM_RUN_OPT += $(EXT_RUN_OPT)
# - UVM
COM_RUN_OPT += +UVM_NO_RELNOTES
COM_RUN_OPT += +UVM_TESTNAME=$(TEST)
COM_RUN_OPT += +UVM_VERBOSITY=$(VERBOSE)
COM_RUN_OPT += +UVM_TIMEOUT=$(strip $(TIMEOUT)),YES
COM_RUN_OPT += $(if $(filter-out $(MAX_QUIT_COUNT),0), +UVM_MAX_QUIT_COUNT=$(MAX_QUIT_COUNT))
# - User Options
COM_RUN_OPT += $(if $(filter-out $(WAVE), none), +WAVE=$(WAVE))

# --- ELF
ifneq ("","$(wildcard $(DUT_ELF_PATH))")
COM_RUN_OPT += +$(DUT_NAME)-elf=$(DUT_ELF_PATH)
else
ifneq ("","$(wildcard $(DUT_SREC_PATH))")
COM_RUN_OPT += +$(DUT_NAME)-srec=$(DUT_SREC_PATH)
endif
endif

ifeq ($(findstring 1, $(USE_AXI_VIP) $(USE_APB_VIP) $(USE_AHB_VIP) $(USE_JTAG_VIP)), 1)
USE_CDN_VIP = 1
else
USE_CDN_VIP = 0
endif

# simulator dependend settings.
include $(MAKEFILE_DIR)/svtb.$(call tolower, $(USE_SIM)).mk
$(V)SIMBUILD_LOGFILT ?= | $(MAKEFILE_DIR)/$(call tolower, $(USE_SIM))_logfilt.sh

# Components
VERIF_FILES += -F ${SIM_CMN_DIR}/tb/nsi_pkg.f

ifneq (0, $(USE_CDN_VIP))
COM_BUILD_OPT += +define+DENALI_UVM
COM_BUILD_OPT += +incdir+$(DENALI)/ddvapi/sv
COM_BUILD_OPT += +incdir+../config/$(CONFIG)
VERIF_FILES   += $(DENALI)/ddvapi/sv/denaliMem.sv
endif

ifneq (0, $(USE_AXI_VIP))
VERIF_FILES   += -F ${SIM_CMN_DIR}/tb/vip/axi4/files.f
endif

ifneq (0, $(USE_APB_VIP))
VERIF_FILES   += -F ${SIM_CMN_DIR}/tb/vip/apb/files.f
endif

ifneq (0, $(USE_AHB_VIP))
VERIF_FILES   += -F ${SIM_CMN_DIR}/tb/vip/ahb5/files.f
endif

ifneq (0, $(USE_JTAG_VIP))
VERIF_FILES   += -F ${SIM_CMN_DIR}/tb/vip/jtag/files.f
endif

# Simulator Option
BUILD_OPT := $(COM_BUILD_OPT) $($(USE_SIM)_BUILD_OPT)
RUN_OPT   := $(COM_RUN_OPT)   $($(USE_SIM)_RUN_OPT)

#
BUILD_FILES = \
	$(addprefix -F ,$(RTL_DOTF))   $(VERIF_FILES) \
	$(addprefix -F ,$(VERIF_DOTF)) $(UVM_TEST_FILE)

# for parallel execution
LOCKFILE       = $(SUMMARY_FILE).lock
LOCKFD         = 99

# ===================================================================================================================================

all: run

build: FORCE
	@$(MAKE) -s simbuild_prep
	@$(MAKE) -s simbuild
	@$(MAKE) -s simbuild_post
run: build FORCE        ## run RTL simulation.
	@$(MAKE) -s simrun_prep
	@$(MAKE) -s simrun
	@$(MAKE) -s simrun_post 

#
simbuild_prep: FORCE
	@rm    -rf $(REPORT_DIR)/$(TESTNAME)
	@mkdir -p  $(REPORT_DIR)/$(TESTNAME)
	@if [ -f "$(UVM_TEST_FILE)" ]; then \
	  pattern_dir=$(SW_PATH)/$(PATTERN); \
	  for file in $$(sed -ne '/^\/\/ input files:/,/^\/\/$$/{s/\/\/ - \(.*\)/\1/pg}' $(UVM_TEST_FILE)); do \
	    filepath=$${pattern_dir}/$${file}; \
	    echo "input file: $${filepath}"; \
	    if [ -f "$${filepath}" ]; then \
	      cp -p $${filepath} $(CURDIR); \
	    fi; \
	  done; \
	  for file in $$(sed -ne '/^\/\/ output files:/,/^\/\/$$/{s/\/\/ - \(.*\)/\1/pg}' $(UVM_TEST_FILE)); do \
	    if [ -f "$${file}" ]; then \
	      rm $${file}; \
	    fi; \
	  done; \
	fi

simbuild_post: FORCE

#
simbuild: FORCE
	@echo "== simbuild CONFIG=$(CONFIG)"
	@touch $@.succeeded
	-@($(BUILD_CMD) $(BUILD_OPT) -l $(BUILD_LOG) $(BUILD_FILES) || rm -rf $@.succeeded) 2>&1 $(SIMBUILD_LOGFILT)
	@test -e $@.succeeded || \
	( \
		simresult="$${simresult:=xFAIL}"; \
		echo "----"; \
		echo "$${simresult}" | tee $(PWD)/simresult; \
	    exec $(LOCKFD)>$(LOCKFILE); trap "flock -xn $(LOCKFD) && rm -f $(LOCKFILE)" EXIT; flock -x $(LOCKFD); \
		touch  $(SUMMARY_FILE); \
		set -C; \
		( \
			( \
				   echo "TESTNAME,DATE,RESULT" \
				&& echo "$(TESTNAME),$(shell date +%Y/%m/%d_%H:%M:%S),$${simresult}" \
				&& (grep -E -v "^$(TESTNAME)" $(SUMMARY_FILE) | tail -n +2) 2> /dev/null \
			) | sort -t , -k 1,2 \
		) > $(SUMMARY_FILE)__ && mv $(SUMMARY_FILE)__ $(SUMMARY_FILE); \
		flock -u $(LOCKFD); flock -xn $(LOCKFD) && rm -f $(LOCKFILE); rm -f $(LOCKFILE); \
		exit 1 \
	)
	@rm -rf $@.succeeded

#
simrun: FORCE
	@echo "== simrun CONFIG=$(CONFIG)"
	-$(RUN_CMD) $(RUN_OPT) -l $(RUN_LOG)
	@simresult=`(grep -E '^\[SIM_RESULT\] (PASS|FAIL)ED' $(RUN_LOG) | sed -r 's/^\[SIM_RESULT\] (PASS|FAIL)ED.*/\1/g') 2> /dev/null`; \
	( \
		simresult="$${simresult:=xFAIL}"; \
		echo "----"; \
		echo "$${simresult}" | tee $(PWD)/simresult; \
	    exec $(LOCKFD)>$(LOCKFILE); trap "flock -xn $(LOCKFD) && rm -f $(LOCKFILE)" EXIT; flock -x $(LOCKFD); \
		touch  $(SUMMARY_FILE); \
		set -C; \
		( \
			( \
				   echo "TESTNAME,DATE,RESULT" \
				&& echo "$(TESTNAME),$(shell date +%Y/%m/%d_%H:%M:%S),$${simresult}" \
				&& (grep -E -v "^$(TESTNAME)" $(SUMMARY_FILE) | tail -n +2) 2> /dev/null \
			) | sort -t , -k 1,2 \
		) > $(SUMMARY_FILE)__ && mv $(SUMMARY_FILE)__ $(SUMMARY_FILE); \
		flock -u $(LOCKFD); flock -xn $(LOCKFD) && rm -f $(LOCKFILE); rm -f $(LOCKFILE); \
	)

simrun_prep: FORCE

simrun_post: FORCE
	@if [ -f "$(DUT_NAME)_trace.log" ]; then mv $(DUT_NAME)_trace.log $(REPORT_DIR)/$(TESTNAME); fi
	@if [ -d waves.shm               ]; then mv waves.shm             $(REPORT_DIR)/$(TESTNAME); fi
	@if [ -f novas.fsdb              ]; then mv novas.fsdb            $(REPORT_DIR)/$(TESTNAME); fi
	@if [ -f "$(UVM_TEST_FILE)"      ]; then \
	  for file in $$(sed -ne '/^\/\/ output files:/,/^\/\/$$/{s/\/\/ - \(.*\)/\1/pg}' $(UVM_TEST_FILE)); do \
	    echo "output file: $${file}"; \
	    if [ -f "$${file}" ]; then \
	      mv $${file} $(REPORT_DIR)/$(TESTNAME); \
	    fi; \
	  done; \
	fi

summary:
	@( \
	  r=$(SUMMARY_FILE); \
	  echo ""; \
	  echo "## Summary : config=$(CONFIG)";\
	  echo ""; \
	  if [ -f $$r ]; then  \
	    ( \
	      head -n 1 $$r && \
	      echo "--,--,--" && \
	      tail -n +2 $$r \
	  	) | column -s, -t -o ' | '; \
	  	echo ""; \
	  	__pass=$$(cat $$r | tail -n +2 | grep    "PASS" | wc -l); \
		__fail=$$(cat $$r | tail -n +2 | grep -v "PASS" | wc -l); \
	  	echo "PASS=$$__pass FAIL=$$__fail"; \
	  else \
	    echo "$$r not fuond."; \
	  fi; \
	  echo "" \
	)


$(BUILD_LOG) $(RUN_LOG): FORCE
	-@rm    -rf $(dir $@)
	-@mkdir -p  $(dir $@)

#
    clean-files += simbuild.succeeded simresult
distclean-files +=

    clean-dirs  +=
distclean-dirs  += $(REPORT_DIR)

# ===================================================================================================================================
include $(MAKEFILE_DIR)/footer.mk
